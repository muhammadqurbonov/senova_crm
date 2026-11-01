# Схемаи Firestore (воқеӣ + тағйирот)

| Collection | ID | Майдонҳои муҳим | Дастрасӣ (rules) |
|---|---|---|---|
| organizations | auto | name, plan, **status** (active/suspended — нав), createdAt | хондан: аъзо/superadmin; навиштан: superadmin |
| users | uid Auth | name,email,login,orgId,role(admin/manager/**viewer**),isSuperAdmin,language,**active**,**uiLang** | қ. rules: худи корбар фақат uiLang/fcmToken; admin фақат role/active |
| loginIndex | login | email, **orgId, uid** (нав) | get: ҳама; list: ҳеҷ кас; update: ҳеҷ кас |
| pipelineStages | `${orgId}_${key}` | orgId, **key**, name_tj/ru/**en**, order, color, **type** (open/won/lost) | хондан: аъзо; навиштан: admin |
| customers | auto | orgId,name,phone,source,stageId (**key**),managerId,managerName,tags | хондан: аъзо; навиштан: admin/manager; claim бо қоида; нест: admin |
| deals | auto | orgId,customerId,propertyId,amount,paymentType,status(open/closed/rejected) | истинодҳо ба ҳамон ширкат санҷида мешаванд |
| tasks | auto | orgId,customerId,customerName,title,dueDate,done,assignedTo | навиштан: ҷавобгар/admin |
| notes | auto | orgId,customerId,text,authorName | create; update манъ |
| properties | auto | orgId,title_tj/ru,price,rooms,area,district,status | |
| **auditLogs** (нав) | auto | orgId,actorUid,actorName,action,targetType,targetId,details,createdAt | create; update/delete манъ; хондан: admin |

Индексҳо: `auditLogs(orgId ASC, createdAt DESC)`. Дигар query-ҳо танҳо баробарӣ доранд — индекси таркибӣ лозим нест.

**Мутобиқат:** ҳеҷ майдони кӯҳна нест нашуд. Майдонҳои нав ихтиёрианд (`active` нест => true, `status` нест => active, `key` нест => аз ID-и ҳуҷҷат).
