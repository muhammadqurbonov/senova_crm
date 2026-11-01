# Senova CRM — бастаи тағйирот (overlay) барои лоиҳаи Flutter + Firebase-и мавҷуда

Ин бастаро **болои лоиҳаи худатон** нусха кунед. Ҳеҷ кітобхонаи нав лозим нест — `pubspec.yaml` тағйир намеёбад.

## 1. Насб (5 дақиқа)
1. Лоиҳаи кӯҳнаро нусха (backup / git commit) кунед.
2. Папкаи `lib/` аз ин баста ҷои `lib/`-и шумо гузошта шавад (файлҳои кӯҳна иваз мешаванд).
   - `services/pipeline_stage_service.dart`, `models/*`, `features/*` ва ғайра **иваз** мешаванд.
   - `features/settings/settings_screen.dart` дигар `confirmDelete`-ро содир намекунад — он ба `core/widgets/common.dart` рафт (ҳамаи импортҳо аллакай навшуданд).
   - Файлҳои кӯҳнаи `core/widgets/responsive_scaffold.dart` ва `core/theme/*` иваз мешаванд.
3. Андозаи `firebase_options.dart` тағйир наёфтааст (лоиҳаи Firebase `imkon-crm` ном дорад — номи лоиҳаи Firebase-ро тағйир додан лозим нест, фақат номи намоишӣ тағйир ёфт).
4. `firestore.rules` ва `firestore.indexes.json`-ро ба ҷои файлҳои худ гузоред ва **пеш аз истеҳсолот** санҷед (қадами 3).
5. Дар `test/senova_test.dart` сатри `YOUR_PACKAGE_NAME`-ро ба номи пакети худ (`name:` дар pubspec.yaml) иваз кунед.

```
flutter clean && flutter pub get
flutter analyze
flutter test
flutter run -d chrome
```

## 2. Номи барнома дар платформаҳо (дастӣ — ин файлҳо дар баста нестанд)
| Куҷо | Чӣ иваз шавад |
|---|---|
| `web/index.html` | `<title>`, `apple-mobile-web-app-title` -> `Senova CRM` |
| `web/manifest.json` | `name`, `short_name` -> `Senova CRM`, `theme_color` -> `#2F80ED`, `background_color` -> `#0A1220` |
| `android/app/src/main/AndroidManifest.xml` | `android:label="Senova CRM"` |
| `ios/Runner/Info.plist` | `CFBundleDisplayName`, `CFBundleName` |
| Нишонаи барнома | `flutter_launcher_icons` ё дастӣ (нишонаи нав дар баста нест) |

Номи пакет (`name:` дар pubspec.yaml) ва `applicationId`-ро иваз накунед, агар барнома аллакай нашр шуда бошад.

## 3. Firestore: rules, индекс, санҷиш
```
firebase deploy --only firestore:indexes   # индекси auditLogs (orgId + createdAt)
cd firestore-tests && npm i && npm test    # тестҳои rules бо emulator (Java + Firebase CLI лозим)
firebase deploy --only firestore:rules
```
**Тартиби бехатар:** аввал rules-ро дар лоиҳаи тестӣ/staging санҷед. Rules нав вуруд, claim, сохтани корманд ва ширкатро санҷидаанд — ҳамаи ин сенарияҳоро дастӣ як бор гузаред.

## 4. Super Admin
`isSuperAdmin: true`-ро танҳо дар Firebase Console (ё бо Admin SDK) ба ҳуҷҷати `users/{uid}`-и худ гузоред. Rules ба ҳеҷ клиент иҷозат намедиҳанд, ки ин майдонро гузорад.

## 5. Миграцияи loginIndex (тавсия мешавад)
`node scripts/migrate_login_index.js --dry-run`, баъд бе `--dry-run`. Баъд аз он дар `firestore.rules` сатри `// LEGACY`-ро нест кунед. Қ. `docs/MIGRATION.md`.

## 6. Забон
Пешфарз — русӣ. Тоҷикӣ ва англисӣ дар менюи забон (боло дар мобилӣ / поёни sidebar дар веб ва дар экрани вуруд). Интихоб дар `users/{uid}.uiLang` нигоҳ дошта мешавад.
Луғат: `scripts/gen_strings.py` -> `python3 scripts/gen_strings.py` -> `lib/core/l10n/app_strings.dart`.
Забони нави иловагӣ: ба `T` дар скрипт сутуни нав илова кунед ва `kLanguages`-ро дар `constants.dart` тағйир диҳед.
Эзоҳ: widget-ҳои стандартии Material (масалан, календар) бе `flutter_localizations` англисӣ мемонанд; барои онҳо ба pubspec `flutter_localizations: {sdk: flutter}` илова карда, ба MaterialApp `localizationsDelegates` ва `locale` диҳед.
