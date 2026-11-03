/**
 * Senova CRM — сервери интегратсияҳо (қабули лид аз Telegram / WhatsApp / Instagram / Facebook).
 *
 * ДИҚҚАТ: ин код навишта шуд, вале дар муҳити таҳия НЕ компил ва НЕ санҷида шудааст.
 * Пеш аз истифода: npm i, npm run build, санҷиш дар emulator ва бо аккаунтҳои тестӣ.
 *
 * Принсипҳо:
 *  - токенҳо танҳо дар integrationSecrets/* (rules: клиент дастрасӣ надорад);
 *  - connect* танҳо барои Super Admin (санҷиши users/{uid}.isSuperAdmin дар сервер);
 *  - вебҳукҳо имзо/секрет месанҷанд ва паёмҳои такрориро (dedup) намегузаранд;
 *  - ҳар канал танҳо ба ширкати худ лид менависад (integrationIndex).
 */
import { onCall, onRequest, HttpsError } from 'firebase-functions/v2/https';
import { defineSecret } from 'firebase-functions/params';
import * as admin from 'firebase-admin';
import * as crypto from 'crypto';

admin.initializeApp();
const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;

const META_APP_SECRET = defineSecret('META_APP_SECRET');
const META_VERIFY_TOKEN = defineSecret('META_VERIFY_TOKEN');

const CHANNELS = ['whatsapp', 'instagram', 'facebook'];

function baseUrl(): string {
  return process.env.PUBLIC_BASE_URL || `https://us-central1-${process.env.GCLOUD_PROJECT}.cloudfunctions.net`;
}

async function assertSuperAdmin(uid: string | undefined): Promise<void> {
  if (!uid) throw new HttpsError('unauthenticated', 'Sign in required.');
  const snap = await db.collection('users').doc(uid).get();
  const d = snap.data();
  if (!d || d.isSuperAdmin !== true || d.active === false) {
    throw new HttpsError('permission-denied', 'Super admin only.');
  }
}

function safeEqual(a: string, b: string): boolean {
  const x = Buffer.from(a);
  const y = Buffer.from(b);
  return x.length === y.length && crypto.timingSafeEqual(x, y);
}

async function firstStageKey(orgId: string): Promise<string> {
  const q = await db.collection('pipelineStages').where('orgId', '==', orgId).orderBy('order', 'asc').limit(1).get();
  if (q.empty) return 'lid_nav';
  const doc = q.docs[0];
  const key = doc.data().key as string | undefined;
  const prefix = `${orgId}_`;
  return key ?? (doc.id.startsWith(prefix) ? doc.id.substring(prefix.length) : doc.id);
}

/** Лидро пайдо мекунад ё месозад ва паёмро ҳамчун ёддошт илова мекунад. Идемпотент (аз рӯи messageId). */
async function upsertLead(p: {
  orgId: string; channel: string; externalId: string; messageId: string;
  name: string; phone?: string; text: string;
}): Promise<void> {
  const dedupId = `${p.orgId}_${p.channel}_${p.messageId}`.replace(/\//g, '_');
  try {
    await db.collection('processedMessages').doc(dedupId).create({ at: FieldValue.serverTimestamp() });
  } catch {
    return; // аллакай коркард шудааст
  }

  const field = `externalIds.${p.channel}`;
  const found = await db.collection('customers').where('orgId', '==', p.orgId).where(field, '==', p.externalId).limit(1).get();
  let customerId: string;
  if (found.empty) {
    const ref = await db.collection('customers').add({
      orgId: p.orgId,
      name: p.name,
      phone: p.phone ?? '',
      source: p.channel,
      stageId: await firstStageKey(p.orgId),
      managerId: null,
      tags: [],
      custom: {},
      externalIds: { [p.channel]: p.externalId },
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
    customerId = ref.id;
  } else {
    customerId = found.docs[0].id;
    await found.docs[0].ref.update({ updatedAt: FieldValue.serverTimestamp() });
  }
  await db.collection('notes').add({
    orgId: p.orgId,
    customerId,
    type: 'message',
    text: p.text.substring(0, 2000),
    authorName: p.channel,
    createdAt: FieldValue.serverTimestamp(),
  });
}

async function setIntegrationStatus(orgId: string, channel: string, label: string): Promise<void> {
  await db.collection('organizations').doc(orgId).update({
    [`integrations.${channel}`]: { status: 'connected', label, connectedAt: FieldValue.serverTimestamp() },
  });
}

// ───────────────────────── Telegram ─────────────────────────

export const connectTelegram = onCall(async (req) => {
  await assertSuperAdmin(req.auth?.uid);
  const orgId = String(req.data?.orgId ?? '');
  const botToken = String(req.data?.botToken ?? '').trim();
  if (!orgId || !/^\d+:[\w-]{20,}$/.test(botToken)) throw new HttpsError('invalid-argument', 'Invalid bot token.');
  if (!(await db.collection('organizations').doc(orgId).get()).exists) throw new HttpsError('not-found', 'Organization not found.');

  const me: any = await (await fetch(`https://api.telegram.org/bot${botToken}/getMe`)).json();
  if (!me.ok) throw new HttpsError('invalid-argument', 'Telegram rejected the token.');

  const secret = crypto.randomBytes(24).toString('hex');
  const hook: any = await (await fetch(`https://api.telegram.org/bot${botToken}/setWebhook`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({
      url: `${baseUrl()}/telegramWebhook/${orgId}`,
      secret_token: secret,
      allowed_updates: ['message'],
    }),
  })).json();
  if (!hook.ok) throw new HttpsError('internal', 'Could not set the Telegram webhook.');

  await db.collection('integrationSecrets').doc(`${orgId}_telegram`).set({ botToken, webhookSecret: secret });
  await setIntegrationStatus(orgId, 'telegram', `@${me.result?.username ?? ''}`);
  return { ok: true };
});

export const telegramWebhook = onRequest(async (req, res) => {
  try {
    const orgId = req.path.split('/').filter(Boolean)[0];
    if (!orgId || req.method !== 'POST') { res.status(404).send('not found'); return; }
    const sec = (await db.collection('integrationSecrets').doc(`${orgId}_telegram`).get()).data();
    const header = String(req.get('x-telegram-bot-api-secret-token') ?? '');
    if (!sec || !safeEqual(header, String(sec.webhookSecret))) { res.status(403).send('forbidden'); return; }

    const m = req.body?.message;
    if (m?.text && m.chat?.id) {
      const from = m.from ?? {};
      const name = [from.first_name, from.last_name].filter(Boolean).join(' ') || from.username || `Telegram ${m.chat.id}`;
      await upsertLead({
        orgId, channel: 'telegram', externalId: String(m.chat.id),
        messageId: String(req.body.update_id ?? m.message_id), name, text: String(m.text),
      });
    }
    res.status(200).send('ok');
  } catch (e) {
    console.error('telegramWebhook', e);
    res.status(200).send('ok'); // Telegram набояд беохир такрор кунад
  }
});

// ───────────────────────── Meta: WhatsApp / Instagram / Facebook ─────────────────────────

export const connectMeta = onCall(async (req) => {
  await assertSuperAdmin(req.auth?.uid);
  const orgId = String(req.data?.orgId ?? '');
  const channel = String(req.data?.channel ?? '');
  const externalId = String(req.data?.externalId ?? '').trim();
  const accessToken = String(req.data?.accessToken ?? '').trim();
  if (!orgId || !CHANNELS.includes(channel) || !/^\d{5,25}$/.test(externalId) || accessToken.length < 20) {
    throw new HttpsError('invalid-argument', 'Invalid parameters.');
  }
  if (!(await db.collection('organizations').doc(orgId).get()).exists) throw new HttpsError('not-found', 'Organization not found.');

  const r: any = await (await fetch(`https://graph.facebook.com/v21.0/${externalId}?access_token=${encodeURIComponent(accessToken)}`)).json();
  if (r.error) throw new HttpsError('invalid-argument', 'Meta rejected the ID or token.');

  const indexId = `${channel}_${externalId}`;
  const existing = (await db.collection('integrationIndex').doc(indexId).get()).data();
  if (existing && existing.orgId !== orgId) throw new HttpsError('already-exists', 'This account is already linked to another organization.');

  await db.collection('integrationIndex').doc(indexId).set({ orgId, channel });
  await db.collection('integrationSecrets').doc(`${orgId}_${channel}`).set({ accessToken, externalId });
  await setIntegrationStatus(orgId, channel, String(r.name ?? r.verified_name ?? externalId));
  return { ok: true };
});

export const metaWebhook = onRequest({ secrets: [META_APP_SECRET, META_VERIFY_TOKEN] }, async (req, res) => {
  try {
    if (req.method === 'GET') {
      const ok = req.query['hub.mode'] === 'subscribe' && safeEqual(String(req.query['hub.verify_token'] ?? ''), META_VERIFY_TOKEN.value());
      if (ok) { res.status(200).send(String(req.query['hub.challenge'])); } else { res.status(403).send('forbidden'); }
      return;
    }
    if (req.method !== 'POST') { res.status(405).send('method not allowed'); return; }

    const expected = 'sha256=' + crypto.createHmac('sha256', META_APP_SECRET.value()).update(req.rawBody).digest('hex');
    if (!safeEqual(String(req.get('x-hub-signature-256') ?? ''), expected)) { res.status(403).send('bad signature'); return; }

    const body: any = req.body;
    const tasks: Promise<void>[] = [];
    const route = async (channel: string, externalId: string, fn: (orgId: string) => Promise<void>) => {
      const idx = (await db.collection('integrationIndex').doc(`${channel}_${externalId}`).get()).data();
      if (idx?.orgId) await fn(String(idx.orgId));
    };

    for (const entry of body?.entry ?? []) {
      if (body.object === 'whatsapp_business_account') {
        for (const change of entry.changes ?? []) {
          const v = change.value ?? {};
          const phoneId = String(v.metadata?.phone_number_id ?? '');
          for (const msg of v.messages ?? []) {
            const profile = (v.contacts ?? []).find((c: any) => c.wa_id === msg.from)?.profile?.name;
            tasks.push(route('whatsapp', phoneId, (orgId) => upsertLead({
              orgId, channel: 'whatsapp', externalId: String(msg.from), messageId: String(msg.id),
              name: profile ?? `+${msg.from}`, phone: `+${msg.from}`, text: msg.text?.body ?? `[${msg.type}]`,
            })));
          }
        }
      } else if (body.object === 'instagram' || body.object === 'page') {
        const channel = body.object === 'instagram' ? 'instagram' : 'facebook';
        for (const ev of entry.messaging ?? []) {
          if (!ev.message || ev.message.is_echo) continue;
          tasks.push(route(channel, String(entry.id), (orgId) => upsertLead({
            orgId, channel, externalId: String(ev.sender?.id), messageId: String(ev.message.mid),
            name: `${channel} ${ev.sender?.id}`, text: ev.message.text ?? '[attachment]',
          })));
        }
      }
    }
    await Promise.all(tasks);
    res.status(200).send('ok');
  } catch (e) {
    console.error('metaWebhook', e);
    res.status(200).send('ok');
  }
});
