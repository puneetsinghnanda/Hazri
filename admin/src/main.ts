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

interface Person {
  profileId: string;
  name: string;
  cityId: string;
  email: string | null;
  emailVerified: boolean;
  phone: string | null;
  createdAt: string | null;
  lastSeenDay: string | null;
  groups: string[];
}

/** "new_delhi" -> "New Delhi": the app's city ids are its English names. */
const cityLabel = (id: string) => id.replace(/_/g, ' ').replace(/\b\w/g, (c) => c.toUpperCase());

function personRow(p: Person): string {
  const email = p.email
    ? `${esc(p.email)} ${p.emailVerified ? '<span title="Confirmed">✓</span>' : '<span class="muted">(not confirmed)</span>'}`
    : '<span class="muted">—</span>';
  return `<tr><td>${esc(p.name)}</td><td>${esc(cityLabel(p.cityId))}</td><td>${email}</td><td>${esc(p.phone ?? '—')}</td>
    <td>${esc((p.createdAt ?? '').slice(0, 10))}</td><td>${esc(p.lastSeenDay ?? '—')}</td><td>${p.groups.map(esc).join(', ') || '<span class="muted">—</span>'}</td></tr>`;
}

/** Everyone who made a profile, newest first, 50 at a time (owner, 2026-11-19). */
async function everyone(): Promise<void> {
  const out = document.getElementById('everyone')!;
  let after: string | null = null;
  let shown = 0;
  const load = async () => {
    const page: { total: number; people: Person[]; next: string | null } = await api(
      'GET',
      `/people/all${after ? `?after=${encodeURIComponent(after)}` : ''}`,
    );
    shown += page.people.length;
    document.getElementById('count')!.textContent = `${shown.toLocaleString('en-IN')} of ${page.total.toLocaleString('en-IN')}`;
    document.getElementById('rows')!.insertAdjacentHTML('beforeend', page.people.map(personRow).join(''));
    after = page.next;
    const more = document.getElementById('more') as HTMLButtonElement;
    more.hidden = after === null;
  };
  out.innerHTML = `<div class="row" style="justify-content:space-between"><h3>Everyone registered</h3><span id="count" class="muted"></span></div>
    <table><thead><tr><th>Name</th><th>City</th><th>Email</th><th>Phone</th><th>Joined</th><th>Last opened</th><th>Groups</th></tr></thead><tbody id="rows"></tbody></table>
    <button id="more" class="quiet" hidden>Load 50 more</button>`;
  document.getElementById('more')!.onclick = () => load().catch(fail);
  await load();
}

async function people(): Promise<void> {
  html(`<h2>People</h2><div class="card"><div class="row"><label><span>Email</span><input id="email" type="email" size="32"></label><button id="find">Look up</button></div><div id="person"></div></div>
    <div class="card" id="everyone"><p class="muted">Loading…</p></div>`);
  void everyone().catch(fail);
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

// ------------------------------------------------------------ announcements

/** 02-notifications AN1-AN8 (owner, 2026-11-19): a message to every profile. */
const LANGS = [
  ['pa', 'Punjabi'],
  ['hi', 'Hindi'],
  ['en', 'English'],
] as const;
type Lang = (typeof LANGS)[number][0];
type Texts = Record<Lang, string>;
const MAX = { title: 65, body: 180, message: 5000 } as const;

interface Announcement {
  id: string;
  title: Texts;
  body: Texts;
  message: Texts;
  createdAt: string;
  sent: number;
  failed: number;
  optedOut: number;
  opened: number;
  byLang: Record<Lang, number>;
  testTo: string | null;
}

/** The app's formatting (AnnouncementText): **bold**, *italic*, [text](https://...), "- " bullets. */
function inline(s: string): string {
  return esc(s)
    .replace(/\[([^\]]+)\]\((https?:\/\/[^)\s]+)\)/g, (_m, t, u) => `<a href="${u}" target="_blank" rel="noopener">${t}</a>`)
    .replace(/\*\*([^*]+)\*\*/g, '<b>$1</b>')
    .replace(/\*([^*]+)\*/g, '<i>$1</i>');
}

function formatted(text: string): string {
  return text
    .split(/\n\s*\n/)
    .filter((p) => p.trim())
    .map((p) => {
      const lines = p.split('\n');
      if (lines.every((l) => /^\s*- /.test(l))) return `<ul>${lines.map((l) => `<li>${inline(l.replace(/^\s*- /, ''))}</li>`).join('')}</ul>`;
      return `<p>${lines.map(inline).join('<br>')}</p>`;
    })
    .join('');
}

const firstOf = (t: Texts) => t.en || t.pa || t.hi;

async function announcements(): Promise<void> {
  const draft: Record<'title' | 'body' | 'message', Texts> = {
    title: { pa: '', hi: '', en: '' },
    body: { pa: '', hi: '', en: '' },
    message: { pa: '', hi: '', en: '' },
  };
  let lang: Lang = 'pa';
  html(`<h2>Announcements</h2>
    <div class="card">
      <p class="muted" style="margin-top:0">Sent at once to everyone with a profile who has Announcements on, each in their app's language.
        A language left empty gets the English, or whichever one is written.</p>
      <div id="audience" class="muted">Counting who it reaches…</div>
      <div class="tabs" id="tabs">${LANGS.map(([k, n]) => `<button data-lang="${k}" class="tab">${n}</button>`).join('')}</div>
      <div class="editor">
        <div>
          <label><span>Title <em id="c-title"></em></span><input id="f-title" maxlength="${MAX.title}" style="width:100%"></label>
          <label><span>Notification text — what shows in the notification <em id="c-body"></em></span>
            <textarea id="f-body" rows="3" maxlength="${MAX.body}"></textarea></label>
          <label><span>Full message — opens in the app when tapped (optional) <em id="c-message"></em></span></label>
          <div class="toolbar">
            <button type="button" class="quiet" data-fmt="bold" title="Bold"><b>B</b></button>
            <button type="button" class="quiet" data-fmt="italic" title="Italic"><i>I</i></button>
            <button type="button" class="quiet" data-fmt="bullet" title="Bullet list">• List</button>
            <button type="button" class="quiet" data-fmt="link" title="Link">Link</button>
          </div>
          <textarea id="f-message" rows="12" maxlength="${MAX.message}"></textarea>
          <p class="muted small">A blank line starts a new paragraph. Lines starting "- " are a list.</p>
        </div>
        <div>
          <span class="muted small">Notification</span>
          <div class="notif"><div class="notif-app">Hazri · now</div><b id="p-title"></b><div id="p-body"></div></div>
          <span class="muted small">In the app</span>
          <div class="phone"><h3 id="p-mtitle"></h3><div id="p-message"></div></div>
        </div>
      </div>
      <div class="testbox">
        <b>Send a test first</b>
        <p class="muted small" style="margin:2px 0 8px">Only to the profile with this email, in the language of the open tab, even if its Announcements switch is off.
          The phone needs the new app, opened once with that profile.</p>
        <div class="row"><label style="margin:0"><span>Email of the profile</span><input id="testemail" type="email" size="30"></label>
          <button id="sendtest" class="quiet">Send test in <span id="testlang">Punjabi</span></button><span id="testnote" class="muted"></span></div>
      </div>
      <div class="row" style="margin-top:12px"><button id="send">Send to everyone</button><span id="sendnote" class="muted"></span></div>
    </div>
    <div class="card"><h3>Sent</h3><div id="history"><p class="muted">Loading…</p></div></div>`);

  const field = (k: 'title' | 'body' | 'message') => document.getElementById(`f-${k}`) as HTMLInputElement | HTMLTextAreaElement;
  let reach = 0;

  const preview = () => {
    for (const k of ['title', 'body', 'message'] as const) {
      const n = draft[k][lang].length;
      document.getElementById(`c-${k}`)!.textContent = `${n} / ${MAX[k]}`;
    }
    const pick = (t: Texts) => t[lang].trim() || t.en.trim() || t.pa.trim() || t.hi.trim();
    document.getElementById('p-title')!.textContent = pick(draft.title) || 'Title';
    document.getElementById('p-body')!.textContent = pick(draft.body) || 'Notification text';
    document.getElementById('p-mtitle')!.textContent = pick(draft.title) || 'Title';
    document.getElementById('p-message')!.innerHTML = formatted(pick(draft.message) || pick(draft.body));
    document.getElementById('testlang')!.textContent = LANGS.find(([k]) => k === lang)![1];
    LANGS.forEach(([k]) => {
      const b = document.querySelector(`[data-lang="${k}"]`)!;
      b.classList.toggle('on', k === lang);
      b.classList.toggle('filled', !!(draft.title[k] || draft.body[k]));
    });
  };

  const show = (l: Lang) => {
    lang = l;
    for (const k of ['title', 'body', 'message'] as const) field(k).value = draft[k][lang];
    preview();
  };
  for (const k of ['title', 'body', 'message'] as const) {
    field(k).addEventListener('input', () => {
      draft[k][lang] = field(k).value;
      preview();
    });
  }
  document.getElementById('tabs')!.onclick = (e) => {
    const l = (e.target as HTMLElement).closest('[data-lang]')?.getAttribute('data-lang') as Lang | undefined;
    if (l) show(l);
  };

  const ta = field('message') as HTMLTextAreaElement;
  document.querySelector('.toolbar')!.addEventListener('click', (e) => {
    const fmt = (e.target as HTMLElement).closest('[data-fmt]')?.getAttribute('data-fmt');
    if (!fmt) return;
    const [a, b] = [ta.selectionStart, ta.selectionEnd];
    const sel = ta.value.slice(a, b);
    let out: string;
    let caret: [number, number];
    if (fmt === 'bold' || fmt === 'italic') {
      const m = fmt === 'bold' ? '**' : '*';
      const t = sel || (fmt === 'bold' ? 'bold text' : 'italic text');
      out = `${m}${t}${m}`;
      caret = [a + m.length, a + m.length + t.length];
    } else if (fmt === 'bullet') {
      const lines = (sel || 'item').split('\n').map((l) => (l.startsWith('- ') ? l : `- ${l}`));
      const lead = a > 0 && ta.value[a - 1] !== '\n' ? '\n' : '';
      out = lead + lines.join('\n');
      caret = [a + out.length, a + out.length];
    } else {
      const url = prompt('Link address (https://…)', 'https://');
      if (!url || !/^https?:\/\/\S+$/.test(url)) return;
      const t = sel || 'link text';
      out = `[${t}](${url})`;
      caret = [a + 1, a + 1 + t.length];
    }
    ta.setRangeText(out, a, b, 'end');
    ta.setSelectionRange(caret[0], caret[1]);
    ta.focus();
    draft.message[lang] = ta.value;
    preview();
  });

  show('pa');

  const loadAudience = async () => {
    const a: { reach: number; optedOut: number; byLang: Record<Lang, number> } = await api('GET', '/announcements/audience');
    reach = a.reach;
    document.getElementById('audience')!.innerHTML = `Reaches <b>${a.reach.toLocaleString('en-IN')}</b> people now —
      Punjabi ${a.byLang.pa}, Hindi ${a.byLang.hi}, English ${a.byLang.en}. ${a.optedOut} have turned announcements off.`;
  };

  const loadHistory = async () => {
    const { announcements: list }: { announcements: Announcement[] } = await api('GET', '/announcements');
    const out = document.getElementById('history')!;
    if (!list.length) {
      out.innerHTML = '<p class="muted">Nothing sent yet.</p>';
      return;
    }
    out.innerHTML = `<table><thead><tr><th>Sent</th><th>Title</th><th>Delivered</th><th>Failed</th><th>Opened</th><th></th></tr></thead><tbody>${list
      .map(
        (a) => `<tr><td>${esc(new Date(a.createdAt).toLocaleString('en-IN', { dateStyle: 'medium', timeStyle: 'short' }))}</td>
        <td>${a.testTo ? `<span class="pill">Test to ${esc(a.testTo)}</span> ` : ''}<b>${esc(firstOf(a.title))}</b><div class="muted small">${esc(firstOf(a.body))}</div></td>
        <td>${a.sent}</td><td>${a.failed}</td><td>${a.opened}${a.sent ? ` <span class="muted">(${Math.round((a.opened / a.sent) * 100)}%)</span>` : ''}</td>
        <td><button class="quiet" data-opens="${esc(a.id)}">Who opened</button></td></tr>
        <tr hidden id="opens-${esc(a.id)}"><td colspan="6"></td></tr>`,
      )
      .join('')}</tbody></table>`;
    out.querySelectorAll<HTMLButtonElement>('[data-opens]').forEach((btn) => {
      btn.onclick = async () => {
        const id = btn.dataset.opens!;
        const row = document.getElementById(`opens-${id}`)!;
        if (!row.hidden) return void (row.hidden = true);
        row.hidden = false;
        const cell = row.firstElementChild!;
        cell.innerHTML = '<span class="muted">Loading…</span>';
        try {
          const { opens }: { opens: { name: string; cityId: string | null; at: string }[] } = await api('GET', `/announcements/${encodeURIComponent(id)}/opens`);
          cell.innerHTML = opens.length
            ? `<table><thead><tr><th>Name</th><th>City</th><th>Opened</th></tr></thead><tbody>${opens
                .map((o) => `<tr><td>${esc(o.name)}</td><td>${esc(o.cityId ? cityLabel(o.cityId) : '—')}</td>
                  <td>${esc(new Date(o.at).toLocaleString('en-IN', { dateStyle: 'medium', timeStyle: 'short' }))}</td></tr>`)
                .join('')}</tbody></table>`
            : '<span class="muted">Nobody has opened it yet.</span>';
        } catch (e) {
          cell.innerHTML = '';
          fail(e);
        }
      };
    });
  };

  const testEmail = document.getElementById('testemail') as HTMLInputElement;
  try {
    testEmail.value = localStorage.getItem('announceTestEmail') ?? '';
  } catch {
    /* no storage: type it each time */
  }
  document.getElementById('sendtest')!.onclick = async () => {
    const email = testEmail.value.trim();
    const pick = (t: Texts) => t[lang].trim() || t.en.trim() || t.pa.trim() || t.hi.trim();
    if (!email) return alert('Enter the email of the profile to send the test to.');
    if (!pick(draft.title) || !pick(draft.body)) return alert('Write a title and the notification text first.');
    try {
      localStorage.setItem('announceTestEmail', email);
    } catch {
      /* not kept */
    }
    const btn = document.getElementById('sendtest') as HTMLButtonElement;
    const note = document.getElementById('testnote')!;
    btn.disabled = true;
    note.textContent = 'Sending…';
    try {
      const { announcement: a }: { announcement: Announcement } = await api('POST', '/announcements', { ...draft, testEmail: email, testLang: lang });
      note.textContent = a.sent ? `Sent to ${a.sent} phone${a.sent > 1 ? 's' : ''}. The message stays in the editor.` : 'FCM refused it: that phone no longer has the app.';
      await loadHistory();
    } catch (e) {
      note.textContent = e instanceof ApiError ? e.message : String(e);
    } finally {
      btn.disabled = false;
    }
  };

  document.getElementById('send')!.onclick = async () => {
    const empty = (t: Texts) => LANGS.every(([k]) => !t[k].trim());
    if (empty(draft.title) || empty(draft.body)) return alert('Write a title and the notification text in at least one language.');
    const missing = LANGS.filter(([k]) => !draft.title[k].trim() || !draft.body[k].trim()).map(([, n]) => n);
    const note = missing.length ? `\n\n${missing.join(' and ')} is not written; those phones get the English (or the other language).` : '';
    if (!confirm(`Send "${firstOf(draft.title)}" to ${reach.toLocaleString('en-IN')} people now? It cannot be taken back.${note}`)) return;
    const btn = document.getElementById('send') as HTMLButtonElement;
    btn.disabled = true;
    document.getElementById('sendnote')!.textContent = 'Sending…';
    try {
      const { announcement: a }: { announcement: Announcement } = await api('POST', '/announcements', draft);
      document.getElementById('sendnote')!.textContent = `Sent to ${a.sent}${a.failed ? `, ${a.failed} failed (uninstalled phones, now removed)` : ''}.`;
      for (const k of ['title', 'body', 'message'] as const) draft[k] = { pa: '', hi: '', en: '' };
      show(lang);
      await Promise.all([loadHistory(), loadAudience()]);
    } catch (e) {
      document.getElementById('sendnote')!.textContent = '';
      fail(e);
    } finally {
      btn.disabled = false;
    }
  };

  await Promise.all([loadAudience(), loadHistory()]);
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
    else if (hash.startsWith('#/announcements')) await announcements();
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
