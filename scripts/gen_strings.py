#!/usr/bin/env python3
"""Генератори lib/core/l10n/app_strings.dart аз луғати ягона (ru / tj / en).
Истифода:  python3 scripts/gen_strings.py
"""
import os

T = {
# key: (ru, tj, en)
'nav_dashboard': ('Дашборд', 'Дашборд', 'Dashboard'),
'nav_customers': ('Клиенты', 'Мизоҷон', 'Customers'),
'nav_properties': ('Объекты', 'Мулкҳо', 'Properties'),
'nav_deals': ('Сделки', 'Сделкаҳо', 'Deals'),
'nav_tasks': ('Задачи', 'Супоришҳо', 'Tasks'),
'nav_settings': ('Настройки', 'Танзимот', 'Settings'),
'logout': ('Выйти', 'Баромадан', 'Sign out'),
'language': ('Язык', 'Забон', 'Language'),

'brand_tagline': ('Клиенты, объекты и сделки — всё в одном месте.', 'Мизоҷон, мулкҳо ва сделкаҳо — ҳама дар як ҷо.', 'Customers, properties and deals — all in one place.'),
'welcome': ('Добро пожаловать', 'Хуш омадед', 'Welcome'),
'login_title': ('Вход в систему', 'Ворид шудан ба система', 'Sign in to your account'),
'login': ('Логин', 'Логин', 'Login'),
'password': ('Пароль', 'Парол', 'Password'),
'sign_in': ('Войти', 'Ворид шудан', 'Sign in'),
'forgot_password': ('Забыли пароль?', 'Парол фаромӯш шуд?', 'Forgot password?'),
'enter_login_first': ('Сначала введите логин', 'Аввал логинро ворид кунед', 'Enter your login first'),
'reset_sent_generic': ('Если такой логин существует, письмо для восстановления пароля отправлено на его email.', 'Агар чунин логин вуҷуд дошта бошад, email-и барқарорсозии парол ба почтаи он фиристода шуд.', 'If this login exists, a password reset email has been sent to its address.'),

'err_invalid_credentials': ('Неверный логин или пароль', 'Логин ё парол нодуруст аст', 'Incorrect login or password'),
'err_profile_missing': ('Профиль сотрудника не найден. Обратитесь к администратору.', 'Профили корманд ёфт нашуд. Бо администратор тамос гиред.', 'Employee profile not found. Contact your administrator.'),
'err_account_disabled': ('Учётная запись отключена. Обратитесь к администратору.', 'Ҳисоб ғайрифаъол карда шудааст. Бо администратор тамос гиред.', 'This account is disabled. Contact your administrator.'),
'err_generic': ('Произошла ошибка. Попробуйте ещё раз.', 'Хатогӣ рух дод. Аз нав кӯшиш кунед.', 'Something went wrong. Please try again.'),
'err_network': ('Нет соединения с сервером. Проверьте интернет.', 'Бо сервер пайваст нашуд. Интернетро санҷед.', 'Cannot reach the server. Check your connection.'),
'err_permission_denied': ('Недостаточно прав для этого действия.', 'Барои ин амал ҳуқуқ нест.', 'You do not have permission for this action.'),
'err_email_in_use': ('Этот email уже используется.', 'Ин email аллакай истифода мешавад.', 'This email is already in use.'),
'err_weak_password': ('Слишком простой пароль.', 'Парол хеле осон аст.', 'The password is too weak.'),
'err_too_many_requests': ('Слишком много попыток. Повторите позже.', 'Кӯшишҳо аз ҳад зиёд. Баъдтар такрор кунед.', 'Too many attempts. Try again later.'),
'err_login_taken': ('Этот логин уже занят.', 'Ин логин банд аст.', 'This login is already taken.'),
'err_name_or_phone': ('Укажите имя или телефон.', 'Ном ё телефонро ворид кунед.', 'Enter a name or a phone number.'),
'err_deal_fields': ('Выберите объект и укажите сумму больше нуля.', 'Мулкро интихоб кунед ва маблағи аз сифр зиёдро ворид намоед.', 'Select a property and enter an amount above zero.'),
'err_property_fields': ('Укажите название и цену больше нуля.', 'Унвон ва нархи аз сифр зиёдро ворид кунед.', 'Enter a title and a price above zero.'),
'err_task_title': ('Укажите заголовок задачи.', 'Сарлавҳаи супоришро ворид кунед.', 'Enter a task title.'),
'err_system_stage': ('Системные стадии («Стал клиентом», «Отказ») удалять нельзя.', 'Stage-ҳои системавиро («Мизоҷ шуд», «Рад кард») нест кардан мумкин нест.', 'System stages (Won, Lost) cannot be deleted.'),
'err_stage_key': ('Ключ: только a–z, 0–9 и _, от 2 до 40 символов.', 'Калид: танҳо a–z, 0–9 ва _, аз 2 то 40 аломат.', 'Key: only a–z, 0–9 and _, 2 to 40 characters.'),
'err_stage_fields': ('Укажите хотя бы одно название, порядок (число) и цвет в формате #RRGGBB.', 'Ақалан як ном, тартиб (рақам) ва рангро дар формати #RRGGBB ворид кунед.', 'Enter at least one name, an order (number) and a colour as #RRGGBB.'),
'err_stage_exists': ('Стадия с таким ключом уже есть.', 'Stage бо чунин калид аллакай ҳаст.', 'A stage with this key already exists.'),
'err_fill_fields': ('Заполните все поля корректно (логин: a–z, 0–9, . _ -; пароль — не короче 8 символов).', 'Ҳамаи майдонҳоро дуруст пур кунед (логин: a–z, 0–9, . _ -; парол — на кам аз 8 аломат).', 'Fill in all fields correctly (login: a–z, 0–9, . _ -; password at least 8 characters).'),

'cancel': ('Отмена', 'Бекор', 'Cancel'),
'delete': ('Удалить', 'Нест кардан', 'Delete'),
'delete_title': ('Удалить?', 'Нест кардан?', 'Delete?'),
'delete_body': ('«{name}» будет удалено полностью. Это действие нельзя отменить.', '«{name}» пурра нест карда мешавад. Ин амал бозгашт надорад.', '"{name}" will be permanently deleted. This cannot be undone.'),
'add': ('Добавить', 'Илова', 'Add'),
'create': ('Создать', 'Сохтан', 'Create'),
'save': ('Сохранить', 'Захира', 'Save'),
'edit': ('Редактировать', 'Таҳрир', 'Edit'),
'choose': ('Выбрать', 'Интихоб', 'Choose'),
'active': ('Активен', 'Фаъол', 'Active'),
'status': ('Статус', 'Ҳолат', 'Status'),
'name': ('Имя', 'Ном', 'Name'),
'phone': ('Телефон', 'Телефон', 'Phone'),
'source': ('Источник', 'Манбаъ', 'Source'),
'manager': ('Менеджер', 'Менеҷер', 'Manager'),
'not_claimed': ('Пока не взят в работу', 'Ҳанӯз гирифта нашудааст', 'Not claimed yet'),
'stage': ('Стадия', 'Стадия', 'Stage'),
'currency': ('сомони', 'сомонӣ', 'TJS'),
'no_stage': ('Без стадии', 'Бе stage', 'No stage'),
'no_stages': ('Стадий воронки пока нет', 'Ягон stage-и воронка нест', 'No pipeline stages yet'),

'org_suspended_title': ('Доступ приостановлен', 'Дастрасӣ боздошта шудааст', 'Access suspended'),
'org_suspended_body': ('Работа компании «{name}» временно приостановлена. Данные сохранены. Обратитесь к администратору платформы.', 'Фаъолияти ширкати «{name}» муваққатан боздошта шудааст. Маълумот нигоҳ дошта шудааст. Бо администратори платформа тамос гиред.', 'The account of "{name}" is temporarily suspended. Your data is safe. Contact the platform administrator.'),

'dashboard_title': ('Аналитика и отчёты', 'Аналитика ва отчётҳо', 'Analytics and reports'),
'stat_total_leads': ('Все лиды', 'Ҳамаи лидҳо', 'All leads'),
'stat_in_progress': ('В работе', 'Дар кор', 'In progress'),
'stat_won': ('Стали клиентами', 'Мизоҷ шуданд', 'Won'),
'stat_conversion': ('Конверсия', 'Конверсия', 'Conversion'),
'stat_open_deals': ('Открытые сделки', 'Сделкаҳои кушода', 'Open deals'),
'stat_pipeline_value': ('Сумма в воронке (не доход)', 'Маблағ дар воронка (на даромад)', 'Pipeline value (not revenue)'),
'stat_won_value': ('Сумма закрытых сделок', 'Маблағи сделкаҳои пӯшида', 'Closed deals value'),
'stat_overdue_tasks': ('Просроченные задачи', 'Супоришҳои мӯҳлаташ гузашта', 'Overdue tasks'),
'leads_by_stage': ('Лиды по стадиям', 'Лидҳо аз рӯи stage', 'Leads by stage'),

'kanban_title': ('Воронка: клиенты', 'Воронка: Мизоҷон', 'Pipeline: customers'),
'search_customers': ('Поиск по имени или телефону', 'Ҷустуҷӯ аз рӯи ном ё телефон', 'Search by name or phone'),
'only_mine': ('Только мои', 'Танҳо аз они ман', 'Only mine'),
'new_customer_manual': ('Новый клиент (вручную)', 'Мизоҷи нав (дастӣ)', 'New customer (manual)'),
'claim': ('Взять', 'Гирифтан', 'Claim'),
'claim_failed': ('Клиента уже взял другой менеджер.', 'Мизоҷро менеҷери дигар гирифтааст.', 'Another manager has already claimed this customer.'),

'tab_notes': ('Заметки', 'Ёддошт', 'Notes'),
'write_note': ('Напишите заметку...', 'Ёддошт нависед...', 'Write a note...'),
'no_notes': ('Заметок пока нет', 'Ҳанӯз ёддошт нест', 'No notes yet'),
'no_deals': ('Сделок пока нет', 'Ҳанӯз сделка нест', 'No deals yet'),
'new_deal': ('Новая сделка', 'Сделкаи нав', 'New deal'),
'deal_open': ('Открыта', 'Кушода', 'Open'),
'deal_closed': ('Закрыта', 'Пӯшида', 'Closed'),
'deal_closed_won': ('Закрыта (стал клиентом)', 'Пӯшида (Мизоҷ шуд)', 'Closed (won)'),
'deal_rejected': ('Отклонена', 'Рад шуд', 'Rejected'),
'close_deal': ('Закрыть', 'Пӯшидан', 'Close'),
'reject_deal': ('Отклонить', 'Рад кардан', 'Reject'),
'deal_already_finished': ('Сделка уже закрыта или отклонена.', 'Сделка аллакай пӯшида ё рад шудааст.', 'This deal is already closed or rejected.'),
'property': ('Объект', 'Мулк', 'Property'),
'amount': ('Сумма (сомони)', 'Маблағ (сомонӣ)', 'Amount (TJS)'),
'payment_type': ('Тип оплаты', 'Намуди пардохт', 'Payment type'),
'payment_full': ('Полная', 'Пурра', 'Full'),
'payment_installment': ('Рассрочка', 'Қист', 'Installment'),

'properties_title': ('Объекты', 'Мулкҳо', 'Properties'),
'search_properties': ('Поиск по названию или району', 'Ҷустуҷӯ аз рӯи унвон ё ноҳия', 'Search by title or district'),
'no_properties': ('Объектов пока нет', 'Ҳанӯз мулк нест', 'No properties yet'),
'new_property': ('Новый объект', 'Мулки нав', 'New property'),
'title_tj': ('Название (таджикский)', 'Унвон (тоҷикӣ)', 'Title (Tajik)'),
'title_ru': ('Название (русский)', 'Унвон (русӣ)', 'Title (Russian)'),
'price': ('Цена (сомони)', 'Нарх (сомонӣ)', 'Price (TJS)'),
'rooms': ('Количество комнат', 'Шумораи хонаҳо', 'Number of rooms'),
'area': ('Площадь (м²)', 'Масоҳат (м²)', 'Area (m²)'),
'district': ('Район', 'Ноҳия', 'District'),
'rooms_short': ('{n} комн.', '{n} хона', '{n} rooms'),
'sqm': ('м²', 'м²', 'm²'),
'pstatus_available': ('Свободен', 'Холӣ', 'Available'),
'pstatus_reserved': ('Забронирован', 'Захира шуда', 'Reserved'),
'pstatus_sold': ('Продан', 'Фурӯхта шуд', 'Sold'),

'deals_title': ('Сделки', 'Сделкаҳо', 'Deals'),
'filter_all': ('Все', 'Ҳама', 'All'),
'filter_open': ('Открытые', 'Кушода', 'Open'),
'filter_closed': ('Закрытые', 'Пӯшида', 'Closed'),
'filter_rejected': ('Отклонённые', 'Рад шуда', 'Rejected'),

'tasks_title': ('Мои задачи', 'Супоришҳои ман', 'My tasks'),
'no_tasks': ('Задач пока нет', 'Ҳанӯз супориш нест', 'No tasks yet'),
'new_task': ('Новая задача', 'Супориши нав', 'New task'),
'task_title': ('Заголовок', 'Сарлавҳа', 'Title'),
'customer_optional': ('Клиент (необязательно)', 'Мизоҷ (ихтиёрӣ)', 'Customer (optional)'),
'no_deadline': ('Срок не выбран', 'Мӯҳлат интихоб нашуд', 'No deadline selected'),

'settings_title': ('Настройки', 'Танзимот', 'Settings'),
'no_access': ('Нет доступа к настройкам.', 'Ба танзимот дастрасӣ нест.', 'You have no access to settings.'),
'tab_stages': ('Стадии воронки', 'Stage-ҳои воронка', 'Pipeline stages'),
'tab_employees': ('Сотрудники', 'Кормандон', 'Employees'),
'tab_audit': ('Журнал действий', 'Журнали амалҳо', 'Audit log'),
'tab_organizations': ('Компании', 'Ширкатҳо', 'Organizations'),
'new_stage': ('Новая стадия', 'Stage-и нав', 'New stage'),
'stage_key': ('Ключ (латиница, без пробелов)', 'Калид (лотинӣ, бе фосила)', 'Key (latin, no spaces)'),
'name_ru': ('Название (русский)', 'Ном (русӣ)', 'Name (Russian)'),
'name_tj': ('Название (таджикский)', 'Ном (тоҷикӣ)', 'Name (Tajik)'),
'name_en': ('Название (английский)', 'Ном (англисӣ)', 'Name (English)'),
'order': ('Порядок', 'Тартиб', 'Order'),
'color_hex': ('Цвет (#RRGGBB)', 'Ранг (#RRGGBB)', 'Colour (#RRGGBB)'),
'stage_type': ('Тип стадии', 'Намуди stage', 'Stage type'),
'stage_type_open': ('Обычная', 'Оддӣ', 'Regular'),
'stage_type_won': ('Успешная (стал клиентом)', 'Муваффақ (мизоҷ шуд)', 'Won'),
'stage_type_lost': ('Неуспешная (отказ)', 'Номуваффақ (рад)', 'Lost'),
'new_employee': ('Новый сотрудник', 'Корманди нав', 'New employee'),
'no_employees': ('Сотрудников нет', 'Корманд нест', 'No employees'),
'role': ('Роль', 'Нақш', 'Role'),
'role_admin': ('Администратор', 'Администратор', 'Admin'),
'role_manager': ('Менеджер', 'Менеҷер', 'Manager'),
'role_viewer': ('Только просмотр', 'Танҳо дидан', 'Read-only'),
'login_hint': ('a–z, 0–9, . _ - (3–30 символов)', 'a–z, 0–9, . _ - (3–30 аломат)', 'a–z, 0–9, . _ - (3–30 characters)'),
'employee_email': ('Реальный email сотрудника', 'Email-и воқеии корманд', 'Employee real email'),
'real_email': ('Реальный email', 'Email-и воқеӣ', 'Real email'),
'password_min': ('Пароль (не менее {n} символов)', 'Парол (на кам аз {n} аломат)', 'Password (at least {n} characters)'),
'no_audit': ('Записей пока нет', 'Ҳанӯз сабт нест', 'No entries yet'),
'new_org': ('Новая компания', 'Ширкати нав', 'New organization'),
'no_orgs': ('Компаний пока нет', 'Ҳанӯз ширкат нест', 'No organizations yet'),
'plan': ('Тариф', 'Тариф', 'Plan'),
'org_status_active': ('Активна', 'Фаъол', 'Active'),
'org_status_suspended': ('Приостановлена', 'Боздошта шуд', 'Suspended'),
'activate': ('Активировать', 'Фаъол кардан', 'Activate'),
'suspend': ('Приостановить', 'Боздоштан', 'Suspend'),
'org_name': ('Название компании', 'Номи ширкат', 'Company name'),
'first_admin': ('Первый администратор', 'Аввалин администратор', 'First administrator'),

'audit.customer.delete': ('Удалён клиент', 'Мизоҷ нест карда шуд', 'Customer deleted'),
'audit.property.delete': ('Удалён объект', 'Мулк нест карда шуд', 'Property deleted'),
'audit.deal.delete': ('Удалена сделка', 'Сделка нест карда шуд', 'Deal deleted'),
'audit.deal.close': ('Сделка закрыта', 'Сделка пӯшида шуд', 'Deal closed'),
'audit.deal.reject': ('Сделка отклонена', 'Сделка рад карда шуд', 'Deal rejected'),
'audit.task.delete': ('Удалена задача', 'Супориш нест карда шуд', 'Task deleted'),
'audit.stage.create': ('Создана стадия', 'Stage сохта шуд', 'Stage created'),
'audit.stage.update': ('Изменена стадия', 'Stage таҳрир шуд', 'Stage updated'),
'audit.stage.delete': ('Удалена стадия', 'Stage нест карда шуд', 'Stage deleted'),
'audit.employee.create': ('Создан сотрудник', 'Корманд сохта шуд', 'Employee created'),
'audit.employee.role': ('Изменена роль сотрудника', 'Нақши корманд тағйир ёфт', 'Employee role changed'),
'audit.employee.activate': ('Сотрудник активирован', 'Корманд фаъол карда шуд', 'Employee activated'),
'audit.employee.deactivate': ('Сотрудник отключён', 'Корманд ғайрифаъол карда шуд', 'Employee deactivated'),
'audit.employee.delete': ('Удалён сотрудник', 'Корманд нест карда шуд', 'Employee deleted'),
'audit.org.create': ('Создана компания', 'Ширкат сохта шуд', 'Organization created'),
'audit.org.suspend': ('Компания приостановлена', 'Ширкат боздошта шуд', 'Organization suspended'),
'audit.org.activate': ('Компания активирована', 'Ширкат фаъол карда шуд', 'Organization activated'),
'audit.org.delete': ('Компания удалена', 'Ширкат нест карда шуд', 'Organization deleted'),
'audit.org.config': ('Изменены настройки компании', 'Танзимоти ширкат тағйир ёфт', 'Organization settings changed'),
'try_demo': ('Посмотреть демо (без входа)', 'Дидани демо (бе вуруд)', 'View demo (no sign-in)'),
'demo_title': ('Демо-режим', 'Ҳолати демо', 'Demo mode'),
'demo_pick_industry': ('Выберите отрасль, чтобы посмотреть систему в работе', 'Соҳаро интихоб кунед, то системаро дар кор бибинед', 'Pick an industry to see the system in action'),
'demo_banner': ('Демо-режим: только просмотр, данные вымышленные.', 'Ҳолати демо: танҳо дидан, маълумот хаёлӣ.', 'Demo mode: view only, sample data.'),
'demo_exit': ('Выйти из демо', 'Баромадан аз демо', 'Exit demo'),
'demo_switch': ('Сменить отрасль', 'Иваз кардани соҳа', 'Switch industry'),
'demo_manager': ('Демо-менеджер', 'Менеҷери демо', 'Demo manager'),
'or_divider': ('или', 'ё', 'or'),
'edit_org': ('Настроить компанию', 'Танзими ширкат', 'Configure organization'),
'industry': ('Отрасль', 'Соҳа', 'Industry'),
'modules': ('Модули', 'Модулҳо', 'Modules'),
'module_items': ('Каталог (услуги, товары, объекты)', 'Феҳрист (хизмат, мол, объект)', 'Catalog (services, products, properties)'),
'module_deals': ('Сделки', 'Сделкаҳо', 'Deals'),
'module_tasks': ('Задачи', 'Супоришҳо', 'Tasks'),
'custom_names': ('Свои названия разделов (необязательно)', 'Номҳои ихтиёрии бахшҳо (ихтиёрӣ)', 'Custom section names (optional)'),
'custom_name_customers': ('Как называть клиентов', 'Мизоҷонро чӣ ном гузорем', 'What to call customers'),
'custom_name_items': ('Как называть каталог', 'Феҳристро чӣ ном гузорем', 'What to call the catalog'),
'custom_name_deals': ('Как называть сделки', 'Сделкаҳоро чӣ ном гузорем', 'What to call deals'),
'custom_fields': ('Дополнительные поля', 'Майдонҳои иловагӣ', 'Custom fields'),
'fields_customer': ('Поля клиента', 'Майдонҳои мизоҷ', 'Customer fields'),
'fields_item': ('Поля каталога', 'Майдонҳои феҳрист', 'Catalog fields'),
'add_field': ('Добавить поле', 'Илова кардани майдон', 'Add field'),
'field_label': ('Название поля', 'Номи майдон', 'Field label'),
'field_type': ('Тип поля', 'Намуди майдон', 'Field type'),
'type_text': ('Текст', 'Матн', 'Text'),
'type_number': ('Число', 'Рақам', 'Number'),
'type_select': ('Список', 'Рӯйхат', 'Select'),
'type_bool': ('Да/нет', 'Ҳа/не', 'Yes/No'),
'type_date': ('Дата', 'Сана', 'Date'),
'field_options': ('Варианты через запятую', 'Вариантҳо бо вергул', 'Options, comma separated'),
'field_required': ('Обязательное', 'Ҳатмӣ', 'Required'),
'no_fields': ('Дополнительных полей нет', 'Майдони иловагӣ нест', 'No custom fields'),
'err_custom_fields': ('Заполните обязательные поля и проверьте числа.', 'Майдонҳои ҳатмиро пур кунед ва рақамҳоро санҷед.', 'Fill the required fields and check numbers.'),
'err_field_label': ('Укажите название поля (для списка — варианты).', 'Номи майдонро нависед (барои рӯйхат — вариантҳо).', 'Enter a field label (options for a select).'),
'org_saved': ('Настройки сохранены', 'Танзимот захира шуд', 'Settings saved'),
'edit_customer': ('Редактировать клиента', 'Таҳрири мизоҷ', 'Edit customer'),
'integrations': ('Интеграции', 'Интегратсияҳо', 'Integrations'),
'tab_integrations': ('Интеграции', 'Интегратсияҳо', 'Integrations'),
'int_telegram': ('Telegram', 'Telegram', 'Telegram'),
'int_whatsapp': ('WhatsApp', 'WhatsApp', 'WhatsApp'),
'int_instagram': ('Instagram', 'Instagram', 'Instagram'),
'int_facebook': ('Facebook', 'Facebook', 'Facebook'),
'int_connect': ('Подключить', 'Пайваст кардан', 'Connect'),
'int_status_connected': ('Подключено', 'Пайваст аст', 'Connected'),
'int_status_not_connected': ('Не подключено', 'Пайваст нест', 'Not connected'),
'int_telegram_token': ('Токен бота (от @BotFather)', 'Токени бот (аз @BotFather)', 'Bot token (from @BotFather)'),
'int_wa_phone_id': ('WhatsApp Phone Number ID', 'WhatsApp Phone Number ID', 'WhatsApp Phone Number ID'),
'int_ig_id': ('Instagram Business Account ID', 'Instagram Business Account ID', 'Instagram Business Account ID'),
'int_fb_page_id': ('Facebook Page ID', 'Facebook Page ID', 'Facebook Page ID'),
'int_access_token': ('Access token (хранится только на сервере)', 'Access token (танҳо дар сервер нигоҳ дошта мешавад)', 'Access token (stored server-side only)'),
'int_connected_ok': ('Канал подключён', 'Канал пайваст шуд', 'Channel connected'),
'int_note_server': ('Токены передаются на сервер (Cloud Functions) и не сохраняются в приложении. Для работы нужен развёрнутый сервер — см. docs/INTEGRATIONS.md.', 'Токенҳо ба сервер (Cloud Functions) фиристода мешаванд ва дар барнома нигоҳ дошта намешаванд. Барои кор сервери насбшуда лозим аст — қ. docs/INTEGRATIONS.md.', 'Tokens are sent to the server (Cloud Functions) and never stored in the app. A deployed server is required — see docs/INTEGRATIONS.md.'),
'int_admin_hint': ('Каналы подключает администратор платформы. Новые обращения из подключённых каналов появляются в воронке автоматически.', 'Каналҳоро администратори платформа пайваст мекунад. Муроҷиатҳои нав аз каналҳои пайваст худкор ба воронка меафтанд.', 'The platform administrator connects channels. New messages from connected channels appear in the pipeline automatically.'),
'err_functions_unavailable': ('Сервер интеграций недоступен или не развёрнут.', 'Сервери интегратсияҳо дастрас нест ё насб нашудааст.', 'The integrations server is unavailable or not deployed.'),
'yes': ('Да', 'Ҳа', 'Yes'),
'no': ('Нет', 'Не', 'No'),
'plan_label': ('Тариф', 'Тариф', 'Plan'),
}

def esc(s):
    return s.replace('\\', '\\\\').replace("'", "\\'").replace('$', '\\$')



# ───────────── Шаблонҳои соҳаҳо ─────────────
SK = ['lid_nav', 'tamos', 'nishondihi', 'muzokira', 'mizoj_shud', 'rad_kard']
SC = ['#63A4FF', '#8FA3BF', '#2F80ED', '#F5A524', '#22C55E', '#EF5350']
ST = ['open', 'open', 'open', 'open', 'won', 'lost']

def stages(names):  # names: 6 x (ru, tj, en)
    return [(SK[i], names[i][0], names[i][1], names[i][2], SC[i], ST[i]) for i in range(6)]

LOST = ('Отказ', 'Рад кард', 'Declined')
INDUSTRIES = {
 'real_estate': dict(icon='apartment_outlined', name=('Недвижимость', 'Амволи ғайриманқул', 'Real estate'),
   stages=stages([('Новый лид','Лид нав','New lead'),('Контакт установлен','Тамос гирифта шуд','Contacted'),('Показ объекта','Нишондиҳии мулк','Viewing'),('Переговоры','Музокира','Negotiation'),('Стал клиентом','Мизоҷ шуд','Won'),('Отказ','Рад кард','Lost')]),
   items=[('Хонаи 3-ҳуҷрагӣ, Сино','3-комнатная квартира, Сино',850000),('Хонаи 2-ҳуҷрагӣ, Фирдавсӣ','2-комнатная квартира, Фирдавси',560000),('Қитъаи замин, Варзоб','Участок, Варзоб',320000),('Офис дар маркази шаҳр','Офис в центре',1200000)],
   nouns=None),
 'clinic': dict(icon='local_hospital_outlined', name=('Клиника', 'Клиника', 'Clinic'),
   stages=stages([('Новая заявка','Дархости нав','New request'),('Первичный контакт','Тамоси аввалин','First contact'),('Запись на приём','Сабти қабул','Appointment booked'),('Лечение','Табобат','In treatment'),('Завершено','Анҷом ёфт','Completed'),LOST]),
   items=[('Муоинаи умумӣ','Консультация терапевта',250),('Тозакунии дандон','Чистка зубов',400),('Таҳлили хун','Анализ крови',120),('УЗИ','УЗИ-диагностика',300)],
   nouns=dict(c=('Пациенты','Беморон','Patients'), cn=('Новый пациент','Бемори нав','New patient'),
     i=('Услуги','Хизматрасониҳо','Services'), inew=('Новая услуга','Хизматрасонии нав','New service'), ione=('Услуга','Хизматрасонӣ','Service'),
     isr=('Поиск услуги','Ҷустуҷӯи хизматрасонӣ','Search services'), ino=('Услуг пока нет','Ҳанӯз хизматрасонӣ нест','No services yet'),
     d=('Приёмы','Қабулҳо','Appointments'), dn=('Новый приём','Қабули нав','New appointment'), dno=('Приёмов пока нет','Ҳанӯз қабул нест','No appointments yet'))),
 'construction': dict(icon='construction_outlined', name=('Строительство', 'Сохтмон', 'Construction'),
   stages=stages([('Новая заявка','Дархости нав','New request'),('Замер и осмотр','Ченкунӣ ва муоина','Survey'),('Смета','Смета','Estimate'),('Договор и работы','Шартнома ва корҳо','Contract & works'),('Объект сдан','Объект супорида шуд','Delivered'),LOST]),
   items=[('Таъмири хона','Ремонт квартиры под ключ',45000),('Сохтмони хонаи шахсӣ','Строительство частного дома',380000),('Бомпӯшӣ','Кровельные работы',28000)],
   nouns=dict(c=('Клиенты','Мизоҷон','Clients'), cn=('Новый клиент','Мизоҷи нав','New client'),
     i=('Проекты','Лоиҳаҳо','Projects'), inew=('Новый проект','Лоиҳаи нав','New project'), ione=('Проект','Лоиҳа','Project'),
     isr=('Поиск проекта','Ҷустуҷӯи лоиҳа','Search projects'), ino=('Проектов пока нет','Ҳанӯз лоиҳа нест','No projects yet'),
     d=('Договоры','Шартномаҳо','Contracts'), dn=('Новый договор','Шартномаи нав','New contract'), dno=('Договоров пока нет','Ҳанӯз шартнома нест','No contracts yet'))),
 'auto': dict(icon='directions_car_outlined', name=('Автосалон', 'Автосалон', 'Car dealership'),
   stages=stages([('Новая заявка','Дархости нав','New enquiry'),('Контакт','Тамос','Contacted'),('Тест-драйв','Тест-драйв','Test drive'),('Переговоры','Музокира','Negotiation'),('Продано','Фурӯхта шуд','Sold'),LOST]),
   items=[('Toyota Camry 2021','Toyota Camry 2021',210000),('Hyundai Sonata 2019','Hyundai Sonata 2019',145000),('Chevrolet Cobalt 2022','Chevrolet Cobalt 2022',98000)],
   nouns=dict(c=('Клиенты','Мизоҷон','Customers'), cn=('Новый клиент','Мизоҷи нав','New customer'),
     i=('Автомобили','Мошинҳо','Vehicles'), inew=('Новый автомобиль','Мошини нав','New vehicle'), ione=('Автомобиль','Мошин','Vehicle'),
     isr=('Поиск автомобиля','Ҷустуҷӯи мошин','Search vehicles'), ino=('Автомобилей пока нет','Ҳанӯз мошин нест','No vehicles yet'),
     d=('Продажи','Фурӯшҳо','Sales'), dn=('Новая продажа','Фурӯши нав','New sale'), dno=('Продаж пока нет','Ҳанӯз фурӯш нест','No sales yet'))),
 'education': dict(icon='school_outlined', name=('Образование', 'Таълим', 'Education'),
   stages=stages([('Новая заявка','Дархости нав','New enquiry'),('Консультация','Машварат','Consultation'),('Пробный урок','Дарси озмоишӣ','Trial lesson'),('Оплата','Пардохт','Payment'),('Учится','Таҳсил мекунад','Enrolled'),LOST]),
   items=[('Курси забони англисӣ','Курс английского языка',900),('Курси барномасозӣ','Курс программирования',2400),('Омодагӣ ба имтиҳон','Подготовка к экзаменам',1200)],
   nouns=dict(c=('Студенты','Донишҷӯён','Students'), cn=('Новый студент','Донишҷӯи нав','New student'),
     i=('Курсы','Курсҳо','Courses'), inew=('Новый курс','Курси нав','New course'), ione=('Курс','Курс','Course'),
     isr=('Поиск курса','Ҷустуҷӯи курс','Search courses'), ino=('Курсов пока нет','Ҳанӯз курс нест','No courses yet'),
     d=('Записи на курс','Сабти номҳо','Enrollments'), dn=('Новая запись','Сабти номи нав','New enrollment'), dno=('Записей пока нет','Ҳанӯз сабти ном нест','No enrollments yet'))),
 'retail': dict(icon='storefront_outlined', name=('Магазин / торговля', 'Мағоза / тиҷорат', 'Retail'),
   stages=stages([('Новый лид','Лиди нав','New lead'),('Контакт','Тамос','Contacted'),('Предложение','Пешниҳод','Offer'),('Заказ','Фармоиш','Order placed'),('Оплачено','Пардохт шуд','Paid'),LOST]),
   items=[('Яхдони Samsung','Холодильник Samsung',5200),('Телевизори LG 55"','Телевизор LG 55"',4300),('Мошини ҷомашӯӣ','Стиральная машина',3100)],
   nouns=dict(c=('Клиенты','Мизоҷон','Customers'), cn=('Новый клиент','Мизоҷи нав','New customer'),
     i=('Товары','Молҳо','Products'), inew=('Новый товар','Моли нав','New product'), ione=('Товар','Мол','Product'),
     isr=('Поиск товара','Ҷустуҷӯи мол','Search products'), ino=('Товаров пока нет','Ҳанӯз мол нест','No products yet'),
     d=('Заказы','Фармоишҳо','Orders'), dn=('Новый заказ','Фармоиши нав','New order'), dno=('Заказов пока нет','Ҳанӯз фармоиш нест','No orders yet'))),
 'travel': dict(icon='flight_takeoff_outlined', name=('Турагентство', 'Агентии сайёҳӣ', 'Travel agency'),
   stages=stages([('Новая заявка','Дархости нав','New enquiry'),('Подбор тура','Интихоби сафар','Tour selection'),('Предложение','Пешниҳод','Quote'),('Бронь','Брон','Booked'),('Оплачено','Пардохт шуд','Paid'),LOST]),
   items=[('Дубай, 7 шабу рӯз','Дубай, 7 ночей',9800),('Туркия, Анталия','Турция, Анталья',7600),('Истироҳат дар Иссиқкӯл','Иссык-Куль, отдых',3400)],
   nouns=dict(c=('Клиенты','Мизоҷон','Customers'), cn=('Новый клиент','Мизоҷи нав','New customer'),
     i=('Туры','Сафарҳо','Tours'), inew=('Новый тур','Сафари нав','New tour'), ione=('Тур','Сафар','Tour'),
     isr=('Поиск тура','Ҷустуҷӯи сафар','Search tours'), ino=('Туров пока нет','Ҳанӯз сафар нест','No tours yet'),
     d=('Бронирования','Бронҳо','Bookings'), dn=('Новая бронь','Брони нав','New booking'), dno=('Броней пока нет','Ҳанӯз брон нест','No bookings yet'))),
 'generic': dict(icon='category_outlined', name=('Другая отрасль (универсально)', 'Соҳаи дигар (универсалӣ)', 'Other industry (universal)'),
   stages=stages([('Новый лид','Лиди нав','New lead'),('Контакт','Тамос','Contacted'),('Предложение','Пешниҳод','Proposal'),('Переговоры','Музокира','Negotiation'),('Успешно','Муваффақ','Won'),LOST]),
   items=[('Хизмати асосӣ','Основная услуга',1000),('Пакети васеъ','Расширенный пакет',2500),('Машварат','Консультация',300)],
   nouns=dict(c=('Клиенты','Мизоҷон','Customers'), cn=('Новый клиент','Мизоҷи нав','New customer'),
     i=('Каталог','Феҳрист','Catalog'), inew=('Новая позиция','Позицияи нав','New item'), ione=('Позиция','Позиция','Item'),
     isr=('Поиск по каталогу','Ҷустуҷӯ дар феҳрист','Search catalog'), ino=('Каталог пуст','Феҳрист холӣ аст','Catalog is empty'),
     d=('Сделки','Сделкаҳо','Deals'), dn=('Новая сделка','Сделкаи нав','New deal'), dno=('Сделок пока нет','Ҳанӯз сделка нест','No deals yet'))),
}

def overrides(n):
    """Калидҳои тарҷумаро аз исмҳои соҳа месозад: lang-index -> {key: text}."""
    out = []
    for i in range(3):
        c = n['c'][i]
        kan = ('Воронка: ' + c.lower()) if i == 0 else (('Воронка: ' + c) if i == 1 else ('Pipeline: ' + c.lower()))
        man = [' (вручную)', ' (дастӣ)', ' (manual)'][i]
        out.append({
            'nav_customers': c, 'nav_properties': n['i'][i], 'nav_deals': n['d'][i],
            'kanban_title': kan, 'properties_title': n['i'][i], 'deals_title': n['d'][i],
            'new_customer_manual': n['cn'][i] + man, 'new_property': n['inew'][i], 'new_deal': n['dn'][i],
            'search_properties': n['isr'][i], 'no_properties': n['ino'][i], 'no_deals': n['dno'][i], 'property': n['ione'][i],
        })
    return out

def gen_industries():
    L = ["// ЭЗОҲ: ин файл аз scripts/gen_strings.py сохта мешавад. Дастӣ таҳрир накунед.",
         "import 'package:flutter/material.dart';",
         "import 'industries.dart';", "",
         "const List<String> kIndustryOrder = [" + ", ".join(f"'{k}'" for k in INDUSTRIES) + "];", "",
         "const Map<String, IndustryPreset> kIndustries = {"]
    for k, d in INDUSTRIES.items():
        L.append(f"  '{k}': IndustryPreset(")
        L.append(f"    id: '{k}', icon: Icons.{d['icon']},")
        L.append(f"    ru: '{esc(d['name'][0])}', tj: '{esc(d['name'][1])}', en: '{esc(d['name'][2])}',")
        L.append("    stages: [")
        for (key, ru, tj, en, col, typ) in d['stages']:
            L.append(f"      StageTpl('{key}', '{esc(ru)}', '{esc(tj)}', '{esc(en)}', '{col}', '{typ}'),")
        L.append("    ],")
        L.append("    demoItems: [")
        for (tj, ru, price) in d['items']:
            L.append(f"      DemoItem('{esc(tj)}', '{esc(ru)}', {price}),")
        L.append("    ],")
        L.append("    overrides: {")
        if d['nouns']:
            ov = overrides(d['nouns'])
            for li, lang in enumerate(['ru', 'tj', 'en']):
                L.append(f"      '{lang}': {{")
                for kk, vv in ov[li].items():
                    L.append(f"        '{kk}': '{esc(vv)}',")
                L.append("      },")
        L.append("    },")
        L.append("  ),")
    L.append("};")
    path = os.path.join(os.path.dirname(__file__), '..', 'lib', 'core', 'industries_data.dart')
    with open(path, 'w', encoding='utf-8') as f:
        f.write("\n".join(L) + "\n")
    print(f"generated {len(INDUSTRIES)} industries -> {os.path.normpath(path)}")


def main():
    out = ["// ЭЗОҲ: ин файл аз scripts/gen_strings.py сохта мешавад. Дастӣ таҳрир накунед.",
           "// Забонҳо: ru (пешфарз), tj, en.", "",
           "const Map<String, Map<String, String>> kStrings = {"]
    for i, lang in enumerate(['ru', 'tj', 'en']):
        out.append(f"  '{lang}': {{")
        for k, v in T.items():
            out.append(f"    '{k}': '{esc(v[i])}',")
        out.append("  },")
    out.append("};")
    path = os.path.join(os.path.dirname(__file__), '..', 'lib', 'core', 'l10n', 'app_strings.dart')
    with open(path, 'w', encoding='utf-8') as f:
        f.write("\n".join(out) + "\n")
    print(f"generated {len(T)} keys x 3 languages -> {os.path.normpath(path)}")
    gen_industries()

if __name__ == '__main__':
    main()
