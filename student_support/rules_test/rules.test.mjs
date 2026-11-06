import { readFileSync } from 'node:fs';
import {
  initializeTestEnvironment, assertSucceeds, assertFails,
} from '@firebase/rules-unit-testing';
import {
  doc, setDoc, getDoc, getDocs, deleteDoc, updateDoc, writeBatch, runTransaction, collection, Timestamp,
} from 'firebase/firestore';
import { ref, uploadBytes, getBytes, deleteObject } from 'firebase/storage';

// Security-rule tests for firestore.rules. Run from student_support/:
//   cd rules_test && npm install && npm test
// `npm test` starts the Firestore emulator (demo project, nothing is
// deployed) and runs this file against it.
const rulesPath = new URL('../firestore.rules', import.meta.url);
const rules = readFileSync(rulesPath, 'utf8');
const storageRules = readFileSync(new URL('../storage.rules', import.meta.url), 'utf8');
const env = await initializeTestEnvironment({
  projectId: 'demo-campussupport',
  firestore: { rules },
  storage: { rules: storageRules, host: '127.0.0.1', port: 9199 },
});

const now = () => Timestamp.now();
const studentCtx = env.authenticatedContext('stu', { email: 'stu@alustudent.com', email_verified: true });
const staffCtx = env.authenticatedContext('stf', { email: 'stf@alueducation.com', email_verified: true });
const unverifiedCtx = env.authenticatedContext('unv', { email: 'unv@alustudent.com', email_verified: false });
const outsiderCtx = env.authenticatedContext('out', { email: 'out@gmail.com', email_verified: true });
const student = studentCtx.firestore();
const other = env.authenticatedContext('oth', { email: 'oth@alustudent.com', email_verified: true }).firestore();
const staff = staffCtx.firestore();
const unverified = unverifiedCtx.firestore();
const outsider = outsiderCtx.firestore();

const incident = (reporterId) => ({
  title: 'Leaking tap', description: 'Water everywhere', category: 'water',
  location: 'Leadership Centre · Room 2', sector: 'leadership_centre', urgency: 'high', status: 'submitted', reporterId,
  reporterName: 'Stu', images: [], searchKeywords: ['leaking', 'tap'],
  upvoteCount: 0, createdAt: now(), updatedAt: now(),
});
const history = (from, to, uid, name) => ({ fromStatus: from, toStatus: to, byUid: uid, byName: name, at: now() });

await env.withSecurityRulesDisabled(async (ctx) => {
  const db = ctx.firestore();
  await setDoc(doc(db, 'users/stf'), { name: 'Staff', email: 'stf@alueducation.com', role: 'staff', reportsSubmitted: 0, createdAt: now() });
  await setDoc(doc(db, 'users/stu'), { name: 'Stu', email: 'stu@alustudent.com', role: 'student', reportsSubmitted: 0, createdAt: now() });
  await setDoc(doc(db, 'incidents/theirs'), incident('oth'));
});

let pass = 0, fail = 0;
async function check(name, p) {
  try { await p; console.log('  ok  ', name); pass++; }
  catch (e) { console.log('  FAIL', name, '-', e.message); fail++; }
}

// 1. History
{
  const b = writeBatch(student);
  const ref = doc(collection(student, 'incidents'));
  b.set(ref, incident('stu'));
  b.set(doc(collection(student, `incidents/${ref.id}/history`)), history('', 'submitted', 'stu', 'Stu'));
  await check('student creates report + first history in one batch', assertSucceeds(b.commit()));
}
await check('student cannot add "" history to someone else\'s report (old loophole)',
  assertFails(setDoc(doc(student, 'incidents/theirs/history/h1'), history('', 'submitted', 'stu', 'Stu'))));
await check('student cannot add a status-change history entry',
  assertFails(setDoc(doc(student, 'incidents/theirs/history/h2'), history('submitted', 'resolved', 'stu', 'Stu'))));
await check('history cannot be written in someone else\'s name',
  assertFails(setDoc(doc(staff, 'incidents/theirs/history/h3'), history('submitted', 'in_review', 'stu', 'Stu'))));

// 1b. Sectors
{
  const { sector, ...noSector } = incident('stu');
  await check('report without a sector is rejected',
    assertFails(setDoc(doc(collection(student, 'incidents')), noSector)));
  await check('report with an unknown sector is rejected',
    assertFails(setDoc(doc(collection(student, 'incidents')), { ...incident('stu'), sector: 'library' })));
}

// 1c. Drafts
const draft = () => ({
  title: 'Broken', description: '', category: 'water', sector: 'social_commons',
  locationDetail: '', urgency: 'medium', localImagePaths: [], updatedAt: now(),
});
await check('student saves their own draft',
  assertSucceeds(setDoc(doc(student, 'users/stu/drafts/current'), draft())));
await check('student reads their own draft',
  assertSucceeds(getDoc(doc(student, 'users/stu/drafts/current'))));
await check('another user cannot read the draft',
  assertFails(getDoc(doc(other, 'users/stu/drafts/current'))));
await check('another user cannot write the draft',
  assertFails(setDoc(doc(other, 'users/stu/drafts/current'), draft())));
await check('draft with unknown fields is rejected',
  assertFails(setDoc(doc(student, 'users/stu/drafts/current'), { ...draft(), status: 'resolved' })));
await check('student deletes their own draft',
  assertSucceeds(deleteDoc(doc(student, 'users/stu/drafts/current'))));

// 2. Votes
const vote = (db, uid, delta) => runTransaction(db, async (tx) => {
  const inc = doc(db, 'incidents/theirs');
  const snap = await tx.get(inc);
  const v = doc(db, `incidents/theirs/votes/${uid}`);
  if (delta > 0) tx.set(v, { uid, at: now() }); else tx.delete(v);
  tx.update(inc, { upvoteCount: snap.data().upvoteCount + delta });
});
await check('student votes: vote doc + count +1', assertSucceeds(vote(student, 'stu', 1)));
await check('count +1 without a new vote doc is rejected',
  assertFails(updateDoc(doc(student, 'incidents/theirs'), { upvoteCount: 5 })));
await check('count +2 in one go is rejected', assertFails(runTransaction(student, async (tx) => {
  const inc = doc(student, 'incidents/theirs');
  const snap = await tx.get(inc);
  tx.update(inc, { upvoteCount: snap.data().upvoteCount + 2 });
})));
await check('student unvotes: delete vote + count -1', assertSucceeds(vote(student, 'stu', -1)));

// 3. Assign
await check('verified staff assign a report to themselves',
  assertSucceeds(updateDoc(doc(staff, 'incidents/theirs'), { assignedTo: 'stf', assignedToName: 'Staff', updatedAt: now() })));
await check('staff cannot assign to someone else',
  assertFails(updateDoc(doc(staff, 'incidents/theirs'), { assignedTo: 'x', assignedToName: 'X', updatedAt: now() })));
await check('students cannot assign',
  assertFails(updateDoc(doc(student, 'incidents/theirs'), { assignedTo: 'stu', assignedToName: 'Stu', updatedAt: now() })));

// 4. Staff status change + history (unchanged behaviour still works)
{
  const b = writeBatch(staff);
  b.update(doc(staff, 'incidents/theirs'), { status: 'in_review', updatedAt: now() });
  b.set(doc(collection(staff, 'incidents/theirs/history')), history('submitted', 'in_review', 'stf', 'Staff'));
  await check('staff move submitted -> in_review with history', assertSucceeds(b.commit()));
}
await check('staff cannot skip to resolved',
  assertFails(updateDoc(doc(staff, 'incidents/theirs'), { status: 'resolved', updatedAt: now() })));
await check('notification from staff',
  assertSucceeds(setDoc(doc(staff, 'notifications/n1'), { userId: 'oth', message: 'Your report "Leaking tap" is now In Review.', incidentId: 'theirs', read: false, at: now() })));

// 5. Only verified ALU accounts get in
await check('an unverified ALU account cannot read reports',
  assertFails(getDoc(doc(unverified, 'incidents/theirs'))));
await check('an unverified ALU account cannot file a report',
  assertFails(setDoc(doc(collection(unverified, 'incidents')), incident('unv'))));
await check('an outside account cannot read reports, even when verified',
  assertFails(getDoc(doc(outsider, 'incidents/theirs'))));
await check('an outside account cannot file a report',
  assertFails(setDoc(doc(collection(outsider, 'incidents')), incident('out'))));
await check('an unverified user cannot read someone else\'s profile',
  assertFails(getDoc(doc(unverified, 'users/stu'))));
await check('an unverified user can create their own profile',
  assertSucceeds(setDoc(doc(unverified, 'users/unv'), { name: 'Unv', email: 'unv@alustudent.com', role: 'student', reportsSubmitted: 0, createdAt: now() })));
await check('unverified staff cannot change a status',
  assertFails(updateDoc(doc(env.authenticatedContext('stf', { email: 'stf@alueducation.com', email_verified: false }).firestore(), 'incidents/theirs'), { status: 'in_progress', updatedAt: now() })));

// 6. Anonymous reports
await check('an anonymous report with the placeholder name is accepted',
  assertSucceeds(setDoc(doc(student, 'incidents/anon'), { ...incident('stu'), anonymous: true, reporterName: 'Anonymous student' })));
await check('an anonymous report cannot store a real name',
  assertFails(setDoc(doc(collection(student, 'incidents')), { ...incident('stu'), anonymous: true })));
await check('anonymous must be true or false',
  assertFails(setDoc(doc(collection(student, 'incidents')), { ...incident('stu'), anonymous: 'yes' })));

// 7. Flags
const flag = (uid) => ({ uid, at: now() });
await check('a member flags a report once in their own name',
  assertSucceeds(setDoc(doc(student, 'incidents/theirs/flags/stu'), flag('stu'))));
await check('a flag cannot be written in someone else\'s name',
  assertFails(setDoc(doc(student, 'incidents/theirs/flags/x'), flag('x'))));
await check('a reporter cannot flag their own report',
  assertFails(setDoc(doc(other, 'incidents/theirs/flags/oth'), flag('oth'))));
await check('a flag cannot be changed',
  assertFails(setDoc(doc(student, 'incidents/theirs/flags/stu'), { uid: 'stu', at: now(), extra: 1 })));
await check('a user can see their own flag',
  assertSucceeds(getDoc(doc(student, 'incidents/theirs/flags/stu'))));
await check('other students cannot list who flagged',
  assertFails(getDocs(collection(other, 'incidents/theirs/flags'))));
await check('staff can list flags',
  assertSucceeds(getDocs(collection(staff, 'incidents/theirs/flags'))));

// 8. Deleting a report removes its sub-collections, and only then
await env.withSecurityRulesDisabled(async (ctx) => {
  const db = ctx.firestore();
  await setDoc(doc(db, 'incidents/del'), incident('stu'));
  await setDoc(doc(db, 'incidents/del/history/h1'), history('', 'submitted', 'stu', 'Stu'));
  await setDoc(doc(db, 'incidents/del/votes/oth'), { uid: 'oth', at: now() });
  await setDoc(doc(db, 'incidents/del/flags/oth'), flag('oth'));
  await setDoc(doc(db, 'incidents/del2'), incident('stu'));
  await setDoc(doc(db, 'incidents/del2/history/h1'), history('', 'submitted', 'stu', 'Stu'));
  await setDoc(doc(db, 'incidents/del2/votes/oth'), { uid: 'oth', at: now() });
});
await check('a history entry still cannot be deleted alone',
  assertFails(deleteDoc(doc(staff, 'incidents/del/history/h1'))));
await check('someone else\'s vote cannot be deleted alone',
  assertFails(deleteDoc(doc(student, 'incidents/del/votes/oth'))));
{
  const b = writeBatch(staff);
  for (const p of ['history/h1', 'votes/oth', 'flags/oth']) b.delete(doc(staff, `incidents/del/${p}`));
  b.delete(doc(staff, 'incidents/del'));
  await check('staff delete a report with its history, votes and flags in one batch', assertSucceeds(b.commit()));
}
{
  const b = writeBatch(student);
  for (const p of ['history/h1', 'votes/oth']) b.delete(doc(student, `incidents/del2/${p}`));
  b.delete(doc(student, 'incidents/del2'));
  await check('an owner deletes a Submitted report with its history and votes', assertSucceeds(b.commit()));
}

// 9. Storage rules
const image = new Uint8Array([255, 216, 255, 217]);
const jpeg = { contentType: 'image/jpeg' };
const photo = (ctx, path) => ref(ctx.storage(), path);
await check('a verified student uploads to their own folder',
  assertSucceeds(uploadBytes(photo(studentCtx, 'incidents/stu/a.jpg'), image, jpeg)));
await check('a verified member reads a photo',
  assertSucceeds(getBytes(photo(staffCtx, 'incidents/stu/a.jpg'))));
await check('nobody uploads into another user\'s folder',
  assertFails(uploadBytes(photo(studentCtx, 'incidents/oth/a.jpg'), image, jpeg)));
await check('an unverified account cannot upload',
  assertFails(uploadBytes(photo(unverifiedCtx, 'incidents/unv/a.jpg'), image, jpeg)));
await check('an outside account cannot read photos',
  assertFails(getBytes(photo(outsiderCtx, 'incidents/stu/a.jpg'))));
await check('non-image uploads are rejected',
  assertFails(uploadBytes(photo(studentCtx, 'incidents/stu/a.pdf'), image, { contentType: 'application/pdf' })));
await check('files of 5 MB or more are rejected',
  assertFails(uploadBytes(photo(studentCtx, 'incidents/stu/big.jpg'), new Uint8Array(5 * 1024 * 1024), jpeg)));
await check('staff can delete a student\'s photo',
  assertSucceeds(deleteObject(photo(staffCtx, 'incidents/stu/a.jpg'))));

await env.cleanup();
console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
