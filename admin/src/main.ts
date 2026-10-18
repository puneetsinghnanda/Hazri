// The Hazri admin website (docs/features/11-admin.md). English only; one user.
import { initializeApp } from 'firebase/app';
import { getAuth, GoogleAuthProvider, onAuthStateChanged, signInWithPopup, signOut, User } from 'firebase/auth';
import { api, ApiError, Bani, Group, Template } from './api';

initializeApp({
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY as string,
  appId: import.meta.env.VITE_FIREBASE_APP_ID as string,
  authDomain: 'hazri-dfcc1.firebaseapp.com',
  projectId: 'hazri-dfcc1',
});
const auth = getAuth();

const app = document.getElementById('app')!;
const nav = document.getElementById('nav')!;
const who = document.getElementById('who')!;

/** 11-admin §6. */
const NOT_ALLOWED = 'This account cannot use Hazri admin.';

function esc(s: unknown): string {
  return String(s ?? '').replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[c]!);
}

function html(s: string): void {
  app.innerHTML = s;
}

function fail(e: unknown): void {
  if (e instanceof ApiError && e.code === 'NOT_ADMIN') {
    html(`<div class="card"><p class="error">${NOT_ALLOWED}</p><button id="out" class="quiet">Sign out</button></div>`);
    document.getElementById('out')!.onclick = () => signOut(auth);
    return;
  }
  const msg = e instanceof ApiError ? `${e.code}: ${e.message} ${Object.values(e.fields).join(' ')}` : String(e);
  const box = document.createElement('p');
  box.className = 'error';
  box.textContent = msg;
  app.prepend(box);
}

function signedOut(): void {
  nav.hidden = true;
  who.textContent = '';
  html(`<div class="card"><p>Sign in with the admin Google account.</p><button id="in">Sign in with Google</button></div>`);
  document.getElementById('in')!.onclick = () => signInWithPopup(auth, new GoogleAuthProvider()).catch(fail);
}

// ---------------------------------------------------------------- dashboard

interface Dashboard {
  day: string;
  openedToday: number;
  totalProfiles: number;
  newProfilesPerDay: { day: string; count: number }[];
  activeCustomGroups: number;
  builtInGroups: Group[];
  sangatPaathToday: number;
  openReports: number;
}

async function dashboard(): Promise<void> {
  html('<p class="muted">Counting…</p>');
  const d = await api<Dashboard>('GET', '/dashboard');
  const max = Math.max(1, ...d.newProfilesPerDay.map((p) => p.count));
  html(`
    <div class="row" style="justify-content:space-between"><h2>Today, ${esc(d.day)} (IST)</h2><button id="refresh" class="quiet">Refresh</button></div>
    <div class="figs">
      ${fig(d.openedToday, 'Opened the app today')}
      ${fig(d.totalProfiles, 'Total profiles')}
      ${fig(d.activeCustomGroups, 'Active custom groups')}
      ${fig(d.sangatPaathToday, 'Sangat paath today')}
      ${fig(d.openReports, 'Open reports')}
    </div>
    <div class="card"><h3>New profiles per day, last 30 days</h3>
      <div class="bars">${d.newProfilesPerDay.map((p) => `<div title="${esc(p.day)}: ${p.count}" style="height:${(p.count / max) * 100}%"></div>`).join('')}</div>
    </div>
    <div class="card"><h3>Built-in groups</h3>${groupTable(d.builtInGroups)}</div>`);
  document.getElementById('refresh')!.onclick = () => dashboard().catch(fail);
}

const fig = (n: number, label: string) => `<div class="card fig"><b>${n.toLocaleString('en-IN')}</b><span>${esc(label)}</span></div>`;

function goalText(g: Group): string {
  const c = g.currentGoal;
  if (!c) return '<span class="muted">No goal running</span>';
  const what = c.type === 'SIMRAN' ? 'minutes of Naam Simran' : esc(banis.find((b) => b.id === c.baniId)?.nameEn ?? c.baniId);
  return `${c.total.toLocaleString('en-IN')} of ${c.target.toLocaleString('en-IN')} ${what} · ${c.pct}% · ${esc(c.startDay)} → ${esc(c.endDay)}`;
}

function groupTable(groups: Group[], actions = false): string {
  if (groups.length === 0) return '<p class="muted">None yet.</p>';
  return `<table><tr><th>Name</th><th>Status</th><th>Members</th><th>Current goal</th>${actions ? '<th></th>' : ''}</tr>
    ${groups
      .map(
        (g) => `<tr><td>${esc(g.names?.en ?? g.name)}</td><td>${esc(g.status)}</td><td>${g.memberCount}</td><td>${goalText(g)}</td>
        ${actions ? `<td><a href="#/groups/${esc(g.groupId)}">Open</a></td>` : ''}</tr>`,
      )
      .join('')}</table>`;
}

// ----------------------------------------------------------- built-in groups

let banis: Bani[] = [];

async function loadBanis(): Promise<Bani[]> {
  if (banis.length === 0) banis = (await api<{ banis: Bani[] }>('GET', '/banis')).banis;
  return banis;
}

/** The value of the Bani list that means a Naam Simran goal, counted in minutes (08-sangat SG-1). */
const SIMRAN = 'SIMRAN';

function templateForm(t: Template | null, names: Group['names']): string {
  const opts = [
    ...banis.map((b) => `<option value="${esc(b.id)}" ${t?.type === 'BANI' && t.baniId === b.id ? 'selected' : ''}>${esc(b.nameEn)}</option>`),
    `<option value="${SIMRAN}" ${t?.type === 'SIMRAN' ? 'selected' : ''}>Naam Simran</option>`,
  ].join('');
  return `
    <div class="row">
      <label><span>Name (English)</span><input id="en" maxlength="64" value="${esc(names?.en)}"></label>
      <label><span>Name (Punjabi)</span><input id="pa" maxlength="64" value="${esc(names?.pa)}"></label>
      <label><span>Name (Hindi)</span><input id="hi" maxlength="64" value="${esc(names?.hi)}"></label>
    </div>
    <div class="row">
      <label><span>Bani</span><select id="bani">${opts}</select></label>
      <label><span>Target (1–1,000,000): paath, or minutes for Naam Simran</span><input id="target" type="number" min="1" max="1000000" value="${t?.target ?? 1000}"></label>
      <label><span>Length in days (1–365)</span><input id="length" type="number" min="1" max="365" value="${t?.lengthDays ?? 30}"></label>
    </div>`;
}

function readForm(): { names: { en: string; pa: string; hi: string }; goalTemplate: Template } {
  const v = (id: string) => (document.getElementById(id) as HTMLInputElement).value.trim();
  const simran = v('bani') === SIMRAN;
  return {
    names: { en: v('en'), pa: v('pa'), hi: v('hi') },
    goalTemplate: {
      type: simran ? 'SIMRAN' : 'BANI',
      baniId: simran ? null : v('bani'),
      simranMinutes: null,
      target: Number(v('target')),
      lengthDays: Number(v('length')),
    },
  };
}

async function groups(): Promise<void> {
  html('<p class="muted">Loading…</p>');
  await loadBanis();
  const list = (await api<{ groups: Group[] }>('GET', '/groups?kind=BUILT_IN')).groups;
  html(`<h2>Built-in groups</h2><div class="card">${groupTable(list, true)}</div>
    <div class="card"><h3>Create a built-in group</h3>${templateForm(null, null)}<button id="create">Create</button>
    <p class="muted">Creating does not start it: open it and press Start.</p></div>`);
  document.getElementById('create')!.onclick = async () => {
    try {
      const r = await api<{ group: Group }>('POST', '/groups/built-in', readForm());
      location.hash = `#/groups/${r.group.groupId}`;
    } catch (e) {
      fail(e);
    }
  };
}

async function group(id: string): Promise<void> {
  html('<p class="muted">Loading…</p>');
  await loadBanis();
  const g = (await api<{ group: Group }>('GET', `/groups/${encodeURIComponent(id)}`)).group;
  const history = (await api<{ goals: Record<string, unknown>[] }>('GET', `/groups/${encodeURIComponent(id)}/history`)).goals;
  const builtIn = g.kind === 'BUILT_IN';
  html(`
    <p><a href="#/${builtIn ? 'groups' : 'reports'}">← Back</a></p>
    <h2>${esc(g.names?.en ?? g.name)}</h2>
    <div class="card">
      <p>${esc(g.kind)} · ${esc(g.status)} · ${g.memberCount} members${g.creatorKey ? ` · creator ${esc(g.creatorKey)}` : ''}</p>
      <p>${goalText(g)}</p>
      <div class="row">
        ${builtIn && !g.currentGoal ? '<button id="start">Start</button>' : ''}
        ${g.status === 'DISABLED' ? '<button id="enable" class="quiet">Enable</button>' : '<button id="disable" class="quiet">Disable</button>'}
        <button id="delete" class="danger">Delete…</button>
      </div>
    </div>
    ${
      builtIn
        ? `<div class="card"><h3>Edit names and the goal template</h3>${templateForm(g.goalTemplate, g.names)}
           <button id="save">Save</button><p class="muted">Saving changes the running goal's target and length at once. A new bani starts with the next goal.</p></div>`
        : ''
    }
    <div class="card"><h3>History</h3>${
      history.length === 0
        ? '<p class="muted">No past goals.</p>'
        : `<table><tr><th>Dates</th><th>Total</th><th>Target</th><th>Status</th><th>Members</th></tr>${history
            .map((h) => `<tr><td>${esc(h.startDay)} → ${esc(h.endDay)}</td><td>${esc(h.total)}</td><td>${esc(h.target)}</td><td>${esc(h.status)}</td><td>${esc(h.memberCount ?? '')}</td></tr>`)
            .join('')}</table>`
    }</div>`);
  const on = (bid: string, fn: () => Promise<unknown>) => {
    const b = document.getElementById(bid);
    if (b) b.onclick = () => fn().then(() => group(id)).catch(fail);
  };
  on('start', () => api('POST', `/groups/${id}/start`));
  on('enable', () => api('PATCH', `/groups/${id}`, { status: 'ACTIVE' }));
  on('disable', () => api('PATCH', `/groups/${id}`, { status: 'DISABLED' }));
  on('save', () => api('PATCH', `/groups/${id}`, readForm()));
  const del = document.getElementById('delete')!;
  del.onclick = async () => {
    const name = g.names?.en ?? g.name ?? '';
    const typed = prompt(`Type the group's name to delete it and everything in it:\n${name}`);
    if (typed === null) return;
    try {
      await api('DELETE', `/groups/${id}`, { confirmName: typed });
      location.hash = builtIn ? '#/groups' : '#/reports';
    } catch (e) {
      fail(e);
    }
  };
}

// ------------------------------------------------------------------ reports

interface Report {
  reportId: string;
  groupId: string;
  groupName: string | null;
  groupKind: string | null;
  groupStatus: string | null;
  reportsForGroup: number;
  reason: string;
  note: string | null;
  status: string;
  createdAt: string | null;
}

async function reports(): Promise<void> {
  html('<p class="muted">Loading…</p>');
  const list = (await api<{ reports: Report[] }>('GET', '/reports')).reports;
  html(`<h2>Reports</h2><div class="card">${
    list.length === 0
      ? '<p class="muted">No reports.</p>'
      : `<table><tr><th>Group</th><th>Reason</th><th>Reports</th><th>When</th><th>Status</th><th></th></tr>${list
          .map(
            (r) => `<tr><td><a href="#/groups/${esc(r.groupId)}">${esc(r.groupName ?? r.groupId)}</a><br><span class="muted">${esc(r.groupKind)} · ${esc(r.groupStatus)} · ${esc(r.groupId)}</span></td>
            <td>${esc(r.reason)}${r.note ? `<br><span class="muted">${esc(r.note)}</span>` : ''}</td><td>${r.reportsForGroup}</td>
            <td>${esc(r.createdAt?.slice(0, 16).replace('T', ' '))}</td><td>${esc(r.status)}</td>
            <td>${r.status === 'OPEN' ? `<button class="quiet" data-dismiss="${esc(r.reportId)}">Dismiss</button>` : ''}</td></tr>`,
          )
          .join('')}</table>`
  }</div>`);
  app.querySelectorAll<HTMLButtonElement>('[data-dismiss]').forEach((b) => {
    b.onclick = () => api('PATCH', `/reports/${b.dataset.dismiss}`, { status: 'DISMISSED' }).then(reports).catch(fail);
  });
}

// ------------------------------------------------------------------- people

async function people(): Promise<void> {
  html(`<h2>People</h2><div class="card"><div class="row"><label><span>Email</span><input id="email" type="email" size="32"></label><button id="find">Look up</button></div><div id="person"></div></div>`);
  document.getElementById('find')!.onclick = async () => {
    const email = (document.getElementById('email') as HTMLInputElement).value.trim();
    const out = document.getElementById('person')!;
    try {
      const p = (await api<{ person: Record<string, unknown> }>('GET', `/people?email=${encodeURIComponent(email)}`)).person;
      out.innerHTML = `<table>${['name', 'email', 'cityId', 'emailVerified', 'createdAt', 'lastSeenDay', 'activeCustomGroups', 'groupLimit']
        .map((k) => `<tr><th>${k}</th><td>${esc(p[k])}</td></tr>`)
        .join('')}</table>
        <div class="row"><label><span>Set group limit (5–100)</span><input id="limit" type="number" min="5" max="100" value="${esc(p.groupLimit)}"></label><button id="setlimit">Set</button></div>`;
      document.getElementById('setlimit')!.onclick = async () => {
        const limit = Number((document.getElementById('limit') as HTMLInputElement).value);
        try {
          await api('PUT', `/people/${encodeURIComponent(String(p.profileId))}/group-limit`, { limit });
          document.getElementById('find')!.click();
        } catch (e) {
          fail(e);
        }
      };
    } catch (e) {
      out.innerHTML = '';
      fail(e);
    }
  };
}

// ------------------------------------------------------------------- routing

async function route(): Promise<void> {
  const hash = location.hash || '#/dashboard';
  nav.querySelectorAll('a').forEach((a) => a.classList.toggle('on', hash.startsWith(a.getAttribute('href')!)));
  const m = hash.match(/^#\/groups\/(.+)$/);
  try {
    if (m) await group(decodeURIComponent(m[1]));
    else if (hash.startsWith('#/groups')) await groups();
    else if (hash.startsWith('#/reports')) await reports();
    else if (hash.startsWith('#/people')) await people();
    else await dashboard();
  } catch (e) {
    fail(e);
  }
}

onAuthStateChanged(auth, (user: User | null) => {
  if (!user) return signedOut();
  nav.hidden = false;
  who.innerHTML = `${esc(user.email)} · <a href="#" id="signout">Sign out</a>`;
  document.getElementById('signout')!.onclick = (e) => {
    e.preventDefault();
    void signOut(auth);
  };
  void route();
});
window.addEventListener('hashchange', () => void route());
