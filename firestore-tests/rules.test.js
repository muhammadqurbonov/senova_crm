// Тестҳои Firestore Rules. Иҷро: cd firestore-tests && npm i && npm test  (Firebase CLI + Java лозим)
import { test, before, after, beforeEach } from 'node:test';
import fs from 'node:fs';
import { initializeTestEnvironment, assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, updateDoc, deleteDoc, collection, query, where, getDocs } from 'firebase/firestore';

let env;
before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-senova',
    firestore: { rules: fs.readFileSync('../firestore.rules', 'utf8') },
  });
});
after(async () => env.cleanup());

const user = (uid, org, role, extra = {}) => ({ name: uid, email: `${uid}@x.tj`, login: uid, orgId: org, role, isSuperAdmin: false, active: true, ...extra });

beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'organizations/A'), { name: 'A', status: 'active' });
    await setDoc(doc(db, 'organizations/B'), { name: 'B', status: 'active' });
    await setDoc(doc(db, 'organizations/S'), { name: 'Suspended', status: 'suspended' });
    await setDoc(doc(db, 'users/adminA'), user('adminA', 'A', 'admin'));
    await setDoc(doc(db, 'users/mgrA'), user('mgrA', 'A', 'manager'));
    await setDoc(doc(db, 'users/mgrA2'), user('mgrA2', 'A', 'manager'));
    await setDoc(doc(db, 'users/viewerA'), user('viewerA', 'A', 'viewer'));
    await setDoc(doc(db, 'users/offA'), user('offA', 'A', 'manager', { active: false }));
    await setDoc(doc(db, 'users/adminB'), user('adminB', 'B', 'admin'));
    await setDoc(doc(db, 'users/mgrS'), user('mgrS', 'S', 'manager'));
    await setDoc(doc(db, 'users/root'), user('root', 'A', 'admin', { isSuperAdmin: true }));
    await setDoc(doc(db, 'customers/cA'), { orgId: 'A', name: 'Ali', phone: '1', stageId: 'lid_nav', managerId: null });
    await setDoc(doc(db, 'customers/cA2'), { orgId: 'A', name: 'Vali', phone: '2', stageId: 'lid_nav', managerId: 'mgrA2' });
    await setDoc(doc(db, 'customers/cB'), { orgId: 'B', name: 'Bob', phone: '3', stageId: 'lid_nav', managerId: null });
    await setDoc(doc(db, 'properties/pA'), { orgId: 'A', title_tj: 'x', price: 1 });
    await setDoc(doc(db, 'properties/pB'), { orgId: 'B', title_tj: 'y', price: 1 });
  });
});

const as = (uid) => env.authenticatedContext(uid).firestore();

// ── Изолятсияи ширкатҳо ──
test('A cannot read B customer', async () => assertFails(getDoc(doc(as('mgrA'), 'customers/cB'))));
test('A can read own customer', async () => assertSucceeds(getDoc(doc(as('mgrA'), 'customers/cA'))));
test('A query for B orgId is denied', async () =>
  assertFails(getDocs(query(collection(as('mgrA'), 'customers'), where('orgId', '==', 'B')))));
test('A cannot create customer in B', async () =>
  assertFails(setDoc(doc(as('mgrA'), 'customers/new'), { orgId: 'B', name: 'x', phone: '1', stageId: 's', managerId: null })));
test('A cannot move customer to B (orgId immutable)', async () =>
  assertFails(updateDoc(doc(as('mgrA'), 'customers/cA'), { orgId: 'B' })));
test('A admin cannot delete B customer', async () => assertFails(deleteDoc(doc(as('adminA'), 'customers/cB'))));
test('deal cannot reference customer of another org', async () =>
  assertFails(setDoc(doc(as('mgrA'), 'deals/d1'), { orgId: 'A', customerId: 'cB', propertyId: 'pA', amount: 1, status: 'open' })));
test('deal with own customer and property succeeds', async () =>
  assertSucceeds(setDoc(doc(as('mgrA'), 'deals/d2'), { orgId: 'A', customerId: 'cA', propertyId: 'pA', amount: 1, status: 'open' })));
test('unauthenticated cannot read customers', async () =>
  assertFails(getDoc(doc(env.unauthenticatedContext().firestore(), 'customers/cA'))));

// ── Super Admin ──
test('super admin cannot read another org customer', async () => assertFails(getDoc(doc(as('root'), 'customers/cB'))));
test('super admin can list organizations', async () => assertSucceeds(getDocs(collection(as('root'), 'organizations'))));
test('regular admin cannot list organizations', async () => assertFails(getDocs(collection(as('adminA'), 'organizations'))));
test('nobody can set isSuperAdmin on own profile', async () =>
  assertFails(updateDoc(doc(as('mgrA'), 'users/mgrA'), { isSuperAdmin: true })));

// ── Роллар ──
test('viewer cannot create customer', async () =>
  assertFails(setDoc(doc(as('viewerA'), 'customers/v'), { orgId: 'A', name: 'x', phone: '1', stageId: 's', managerId: null })));
test('manager cannot delete customer', async () => assertFails(deleteDoc(doc(as('mgrA'), 'customers/cA'))));
test('admin can delete customer', async () => assertSucceeds(deleteDoc(doc(as('adminA'), 'customers/cA'))));
test('manager cannot change own role', async () => assertFails(updateDoc(doc(as('mgrA'), 'users/mgrA'), { role: 'admin' })));
test('admin can change manager role', async () => assertSucceeds(updateDoc(doc(as('adminA'), 'users/mgrA'), { role: 'viewer' })));
test('admin cannot change orgId of employee', async () => assertFails(updateDoc(doc(as('adminA'), 'users/mgrA'), { orgId: 'B' })));
test('user can change own uiLang', async () => assertSucceeds(updateDoc(doc(as('mgrA'), 'users/mgrA'), { uiLang: 'tj' })));
test('user cannot set invalid uiLang', async () => assertFails(updateDoc(doc(as('mgrA'), 'users/mgrA'), { uiLang: 'xx' })));
test('inactive user is denied everywhere', async () => assertFails(getDoc(doc(as('offA'), 'customers/cA'))));

// ── Claim ──
test('manager can claim unclaimed lead for self', async () =>
  assertSucceeds(updateDoc(doc(as('mgrA'), 'customers/cA'), { managerId: 'mgrA', managerName: 'x' })));
test('manager cannot steal a claimed lead', async () =>
  assertFails(updateDoc(doc(as('mgrA'), 'customers/cA2'), { managerId: 'mgrA', managerName: 'x' })));
test('manager cannot assign lead to someone else', async () =>
  assertFails(updateDoc(doc(as('mgrA'), 'customers/cA'), { managerId: 'mgrA2' })));

// ── Ширкати боздошташуда ──
test('suspended org cannot write', async () => {
  await env.withSecurityRulesDisabled(async (ctx) => setDoc(doc(ctx.firestore(), 'properties/pS'), { orgId: 'S', price: 1 }));
  return assertFails(updateDoc(doc(as('mgrS'), 'properties/pS'), { price: 2 }));
});

// ── loginIndex / auditLogs ──
test('loginIndex get is public, list is denied', async () => {
  await env.withSecurityRulesDisabled(async (ctx) => setDoc(doc(ctx.firestore(), 'loginIndex/ali'), { email: 'a@x.tj', orgId: 'A', uid: 'mgrA' }));
  await assertSucceeds(getDoc(doc(env.unauthenticatedContext().firestore(), 'loginIndex/ali')));
  await assertFails(getDocs(collection(env.unauthenticatedContext().firestore(), 'loginIndex')));
});
test('loginIndex cannot be overwritten', async () => {
  await env.withSecurityRulesDisabled(async (ctx) => setDoc(doc(ctx.firestore(), 'loginIndex/ali'), { email: 'a@x.tj', orgId: 'A', uid: 'mgrA' }));
  await assertFails(setDoc(doc(as('adminB'), 'loginIndex/ali'), { email: 'evil@x.tj', orgId: 'B', uid: 'adminB' }));
});
test('audit log: create ok, update/delete denied', async () => {
  const ref = doc(as('adminA'), 'auditLogs/l1');
  await assertSucceeds(setDoc(ref, { orgId: 'A', actorUid: 'adminA', actorName: 'a', action: 'x', targetType: '', targetId: '', details: '', createdAt: new Date() }));
  await assertFails(updateDoc(ref, { action: 'y' }));
  await assertFails(deleteDoc(ref));
});
test('audit log: manager cannot read', async () => {
  await env.withSecurityRulesDisabled(async (ctx) => setDoc(doc(ctx.firestore(), 'auditLogs/l2'), { orgId: 'A', actorUid: 'x', action: 'x' }));
  return assertFails(getDoc(doc(as('mgrA'), 'auditLogs/l2')));
});

// ── Интегратсияҳо: клиент ба сирр дастрасӣ надорад ──
test('integration secrets are never readable or writable by clients', async () => {
  await env.withSecurityRulesDisabled(async (ctx) => setDoc(doc(ctx.firestore(), 'integrationSecrets/A_telegram'), { botToken: 'x' }));
  await assertFails(getDoc(doc(as('root'), 'integrationSecrets/A_telegram')));
  await assertFails(getDoc(doc(as('adminA'), 'integrationSecrets/A_telegram')));
  await assertFails(setDoc(doc(as('root'), 'integrationSecrets/B_telegram'), { botToken: 'y' }));
});
test('super admin can update organization config; org admin cannot', async () => {
  await assertSucceeds(updateDoc(doc(as('root'), 'organizations/A'), { industry: 'clinic', modules: ['deals'] }));
  await assertFails(updateDoc(doc(as('adminA'), 'organizations/A'), { industry: 'clinic' }));
});
