# Миграция ва бозгашт

Тағйироти схема **аддитивӣ** аст: пеш аз rules ҳеҷ миграцияи ҳатмӣ лозим нест.

1. Backup: `gcloud firestore export gs://<bucket>/backup-$(date +%F)` (ё Console -> Import/Export).
2. Rules-ро дар лоиҳаи staging санҷед (`firestore-tests`).
3. `scripts/migrate_login_index.js --dry-run`, баъд воқеӣ — `orgId`/`uid` ба loginIndex илова мекунад (идемпотент, нест намекунад).
4. Rules-ро дар production deploy кунед. Агар чизе вайрон шавад: `firebase deploy --only firestore:rules` бо версияи қаблӣ (Console -> Rules -> History).
5. Баъд аз миграция сатри `// LEGACY`-ро дар `loginIndex` нест кунед.

Забон: корбарони кӯҳна `language: 'tj'` доранд, вале UI аз `uiLang` мехонад — пешфарз ҳама русӣ мебинанд, то худашон забонро интихоб кунанд.
Бозгашт ба барномаи кӯҳна: маълумот мувофиқ мемонад (майдонҳои нав эътибор надоранд).
