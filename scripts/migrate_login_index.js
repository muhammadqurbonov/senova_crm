/**
 * Миграцияи якбораи loginIndex: ба ҳар ҳуҷҷат orgId ва uid илова мекунад (аз users/).
 * Ба ҷуз ин, ҳуқуқи нест кардани логинҳои кӯҳна аз rules хориҷ карда мешавад.
 *
 * Истифода (Node 18+, firebase-admin, serviceAccount.json — НАБОЯД дар репозиторий/Flutter бошад):
 *   npm i firebase-admin
 *   GOOGLE_APPLICATION_CREDENTIALS=./serviceAccount.json node scripts/migrate_login_index.js --dry-run
 *   GOOGLE_APPLICATION_CREDENTIALS=./serviceAccount.json node scripts/migrate_login_index.js
 * Скрипт идемпотент аст ва ҳеҷ чизро нест намекунад.
 */
const admin = require('firebase-admin');
admin.initializeApp();
const db = admin.firestore();
const dry = process.argv.includes('--dry-run');

(async () => {
  const users = await db.collection('users').get();
  let updated = 0, skipped = 0, missing = 0;
  for (const u of users.docs) {
    const d = u.data();
    if (!d.login) { skipped++; continue; }
    const ref = db.collection('loginIndex').doc(String(d.login).toLowerCase());
    const snap = await ref.get();
    if (!snap.exists) { missing++; console.warn('no loginIndex for', d.login); continue; }
    const cur = snap.data();
    if (cur.orgId === d.orgId && cur.uid === u.id) { skipped++; continue; }
    console.log(dry ? '[dry-run] would update' : 'update', d.login);
    if (!dry) await ref.set({ ...cur, orgId: d.orgId, uid: u.id }, { merge: true });
    updated++;
  }
  console.log({ updated, skipped, missing, dry });
})().catch((e) => { console.error(e); process.exit(1); });
