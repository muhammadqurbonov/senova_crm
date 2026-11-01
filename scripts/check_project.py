#!/usr/bin/env python3
"""Санҷиши статикии лоиҳа (бе Flutter SDK): калидҳои тарҷума, import-ҳо, AppColors, баланси қавсҳо."""
import re, os, sys
root = os.path.join(os.path.dirname(__file__), '..', 'lib')
files = [os.path.join(d, f) for d, _, fs in os.walk(root) for f in fs if f.endswith('.dart')]
errors = []

# 1. translations
sys.path.insert(0, os.path.dirname(__file__))
import gen_strings
T = gen_strings.T
used = set()
for p in files:
    s = open(p, encoding='utf-8').read()
    for m in re.finditer(r"tr\('([^'$]+)'", s):
        used.add(m.group(1))
dynamic = ['role_admin','role_manager','role_viewer','pstatus_available','pstatus_reserved','pstatus_sold',
           'filter_all','filter_open','filter_closed','filter_rejected','deal_open','deal_closed','deal_closed_won','deal_rejected',
           'nav_dashboard','nav_customers','nav_properties','nav_deals','nav_tasks','nav_settings',
           'tab_stages','tab_employees','tab_audit','tab_organizations','org_status_active','org_status_suspended','activate','suspend']
dynamic += [f'err_{x}' for x in ['invalid_credentials','profile_missing','account_disabled','generic','network','permission_denied','email_in_use','weak_password','too_many_requests','login_taken']]
used.update(dynamic)
for k in sorted(used):
    if k not in T: errors.append(f'MISSING translation key: {k}')
for k, v in T.items():
    for i, x in enumerate(v):
        if not x.strip(): errors.append(f'EMPTY {k}[{i}]')
    ph = [set(re.findall(r'\{(\w+)\}', x)) for x in v]
    if not (ph[0] == ph[1] == ph[2]): errors.append(f'PLACEHOLDER mismatch: {k}')
unused = [k for k in T if k not in used and not k.startswith('audit.')]
# audit actions used in code
acts = set()
for p in files:
    s = open(p, encoding='utf-8').read()
    for m in re.finditer(r"\.log\([^,]+,\s*(?:'([^']+)'|[^,]+\?\s*'([^']+)'\s*:\s*'([^']+)')", s):
        acts.update(x for x in m.groups() if x)
    for m in re.finditer(r"'((?:customer|property|deal|task|stage|employee|org)\.[a-z]+)'", s):
        acts.add(m.group(1))
for a in sorted(acts):
    if f'audit.{a}' not in T: errors.append(f'MISSING audit translation: audit.{a}')

# 2. imports
for p in files:
    s = open(p, encoding='utf-8').read()
    for m in re.finditer(r"import '(\.[^']+)'", s):
        t = os.path.normpath(os.path.join(os.path.dirname(p), m.group(1)))
        if not os.path.exists(t): errors.append(f'BAD import in {os.path.relpath(p, root)}: {m.group(1)}')

# 3. AppColors members
colors = open(os.path.join(root, 'core/theme/app_colors.dart'), encoding='utf-8').read()
defined = set(re.findall(r'static (?:const )?\w+ (\w+)\b', colors)) | set(re.findall(r'static \w+ (\w+)\(', colors))
for p in files:
    s = open(p, encoding='utf-8').read()
    for m in re.finditer(r'AppColors\.(\w+)', s):
        if m.group(1) not in defined: errors.append(f'UNKNOWN AppColors.{m.group(1)} in {os.path.relpath(p, root)}')
    if re.search(r'AppColors\.(gold|goldLight|goldDark|textOnGold)', s): errors.append(f'OLD gold colour in {p}')
    if re.search(r'imkon|Imkon|IMKON', s): errors.append(f'OLD brand name in {os.path.relpath(p, root)}')

# 4. bracket balance (strings/comments stripped)
def strip(s):
    s = re.sub(r"//[^\n]*", '', s)
    s = re.sub(r"'(?:\\.|[^'\\\n])*'", "''", s)
    s = re.sub(r'"(?:\\.|[^"\\\n])*"', '""', s)
    return s
for p in files:
    s = strip(open(p, encoding='utf-8').read())
    for a, b in ['()', '[]', '{}']:
        if s.count(a) != s.count(b): errors.append(f'UNBALANCED {a}{b} in {os.path.relpath(p, root)}: {s.count(a)} vs {s.count(b)}')

# 5. every tr() call with const prefix on same Text (const Text(context.tr(...)) is invalid)
for p in files:
    for n, line in enumerate(open(p, encoding='utf-8').read().split('\n'), 1):
        if re.search(r'const\s+(Text|InputDecoration|Tab)\([^;]*\btr\(', line):
            errors.append(f'const + tr() at {os.path.relpath(p, root)}:{n}: {line.strip()[:90]}')

print(f'files={len(files)} keys_in_dict={len(T)} keys_used={len(used)} unused_keys={unused}')
print('\n'.join(errors) if errors else 'ALL CHECKS PASSED')
sys.exit(1 if errors else 0)
