# Интегратсияҳо: Telegram, WhatsApp, Instagram, Facebook

**Ҳолат:** UI (Super Admin) ва сервер (`functions/`) навишта шудаанд, вале **санҷида нашудаанд** (дар муҳити таҳия Node/интернет набуд). Пеш аз ваъда ба мизоҷ — дар аккаунтҳои тестӣ санҷед.

## Чӣ кор мекунад
Паёми нав аз канали пайваст -> сервер -> дар воронкаи ширкат **мизоҷи нав** (stage-и аввал, `source` = канал) + паём ҳамчун ёддошт. Паёми такрорӣ (retry) такроран илова намешавад. Ҷавоб додан аз барнома (outbox) ҳанӯз нест — фақат қабули лид.

## Талабот
1. Firebase лоиҳа дар тарифи **Blaze** (Cloud Functions).
2. `cd functions && npm i && npm run build`
3. Сирҳои Meta (барои WhatsApp/Instagram/Facebook):
   ```
   firebase functions:secrets:set META_APP_SECRET     # App Secret аз Meta for Developers
   firebase functions:secrets:set META_VERIFY_TOKEN   # ягон сатри тасодуфии худатон
   ```
4. `firebase deploy --only functions,firestore:rules`
5. Агар URL-и функсияҳо аз `https://us-central1-<project>.cloudfunctions.net` фарқ кунад, `PUBLIC_BASE_URL`-ро ҳамчун env танзим кунед.

## Telegram (осонтарин)
1. Дар Telegram аз `@BotFather` бот созед, токенро гиред.
2. Дар барнома: Танзимот -> Ширкатҳо -> «Настроить компанию» -> Telegram -> токенро гузоред -> «Подключить».
   Сервер токенро месанҷад, webhook-ро худаш танзим мекунад (бо секрети тасодуфӣ) ва токенро танҳо дар `integrationSecrets` нигоҳ медорад.

## WhatsApp / Instagram / Facebook (Meta)
Ин қисм аз Telegram мураккабтар аст ва аз ҷониби Meta талаботи ҷудогона дорад:
- Аккаунти **Meta Business** ва барномаи **Meta for Developers**; WhatsApp Cloud API (Phone Number ID), Instagram — аккаунти **Professional**, ба саҳифаи Facebook пайваст; Facebook — Page.
- Барои паёмҳои мизоҷони воқеӣ (на танҳо тестӣ) Meta одатан **App Review** ва тасдиқи бизнесро талаб мекунад (ҳафтаҳо).
- Webhook callback URL: `https://us-central1-<project>.cloudfunctions.net/metaWebhook`, Verify token = `META_VERIFY_TOKEN`. Обуна: `messages` (WhatsApp), `messages` (Instagram), `messages` (Page).
- Дар барнома: Phone Number ID / IG Account ID / Page ID + **access token-и дароз** (System User token) -> «Подключить». Сервер тавассути Graph API мавҷудияти ID ва токенро месанҷад.
- Ҳар ID ба як ширкат пайваст мешавад (`integrationIndex`); пайвасти як аккаунт ба ду ширкат рад мешавад.

## Амният
- Токенҳо ба Firestore-и клиент намераванд; `integrationSecrets`, `integrationIndex`, `processedMessages` — дар rules барои клиент пурра манъ (`allow read, write: if false`).
- `connectTelegram` / `connectMeta` — танҳо Super Admin (дар сервер санҷида мешавад, на дар UI).
- Вебҳукҳо: Telegram — header-и секрет; Meta — имзои HMAC SHA-256 бо `META_APP_SECRET`.

## Маҳдудиятҳо / иҷро нашуд
Ҷавоб ба паём, расм/файл/овоз (фақат матн), таърихи пурраи мукотиба, нусхаи тоза кардани токен/узвиятҳои канал, мониторинги хатоҳои webhook, тамдиди токен.
