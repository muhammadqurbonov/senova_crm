# Нақша (баъд аз ин баста)
1. **Фаза 1б** — `flutter analyze/test`, rules-тестҳо дар emulator, ислоҳи хатоҳо.
2. **Фаза 2** — custom fields (typed + кӯтоҳ), якчанд pipeline, саҳифабандии курсорӣ, ҷустуҷӯи индексшуда, фильтрҳои сана, saved views, ёддоштҳои система ҳангоми тағйири stage.
3. **Фаза 3** — Cloud Functions (TypeScript): callable `resolveLogin`, журнали server-side, ҳисоби usage/лимитҳо, taklif-и корманд (invite), custom claims барои Super Admin.
4. **Фаза 4** — тарифҳо ва пардохт (провайдери мувофиқ ба Тоҷикистон), webhook бо тасдиқи imzo, CSV import (dry-run) / export, backup + restore-drill, Crashlytics.
5. **Фаза 5** — модули дуюм (аввал бо мизоҷи воқеӣ тасдиқ шавад).
6. **Фаза 6** — WhatsApp/Telegram (API-ҳои расмӣ), автоматизатсия (idempotent), reminder бо Cloud Scheduler.
