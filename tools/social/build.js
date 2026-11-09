// Draws Hazri's Instagram posts into social/out/, with a caption for each in
// social/out/captions.md.
//
//   node tools/social/build.js                      7 days from today
//   node tools/social/build.js --from 2026-11-09 --days 30
//   node tools/social/build.js --samples            one of each, into social/samples/
//
// What a run makes (feed posts 1080 x 1350, stories 1080 x 1920):
//   every day           Today's Vichar, the same line the app shows that day
//                       (VicharCycle: days since 1970 modulo the count),
//                       alternating dawn and night so the grid has a rhythm
//   the eve of an event every calendar event the app reminds about by
//                       default, with the first lines of its hazri.me story
//   Tuesdays            a Gurmat Quiz carousel: the question, then the answer
//   Fridays             a saakhi, its cover and subtitle
//   always              two brand posts: privacy, and what is in the app
//
// Every pankti and meaning is read from content.db by export.py; nothing
// Gurbani-related is typed here (CLAUDE.md rule 3). No image shows a Guru's
// face: the only pictures are the saakhi covers, which already follow SK2.
// Uses the environment's Playwright and Chromium and the fonts in
// assets/fonts/; nothing is fetched.
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');

const root = path.resolve(__dirname, '..', '..');
const args = process.argv.slice(2);
const arg = (k, d) => { const i = args.indexOf(k); return i >= 0 ? args[i + 1] : d; };
const samples = args.includes('--samples');
const out = path.join(root, 'social', samples ? 'samples' : 'out');

const data = JSON.parse(execFileSync('python3', [path.join(__dirname, 'export.py')],
  { encoding: 'utf8', maxBuffer: 64 << 20 }));

// tokens.json
const T = {
  navy: '#262C63', ink: '#1B1D3A', ink2: '#4D5070', muted: '#85879F', bg: '#F4F3F8',
  kesri: '#D9730D', kesriSoft: '#FBE8D2', kesriInk: '#9A4F00', sage: '#2E7A57',
  sageSoft: '#DCEFE5', night: '#0C0F24', nightCard: '#161A37', amber: '#F2A24E',
  amberInk: '#FFC27E', field: '#080B1C', lavender: '#E9E4F7', lavenderInk: '#4B3F86',
};

const esc = (s) => String(s ?? '').replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
const font = (fam, file, w) => `@font-face{font-family:'${fam}';font-weight:${w};
  src:url('file://${path.join(root, 'assets', 'fonts', file)}')}`;
const dataUrl = (p) => `data:image/webp;base64,${fs.readFileSync(path.join(root, p)).toString('base64')}`;

// The app mark on its 40 x 40 grid (make_icons.py, AppMark).
const mark = (size, arc, sun) => `<svg width="${size}" height="${size}" viewBox="0 0 40 40">
  <path d="M4 27 A16 16 0 0 1 36 27" fill="none" stroke="${arc}" stroke-width="2.6"/>
  <path d="M12 27 A8 8 0 0 1 28 27 Z" fill="${sun}"/>
  <path d="M6 31.5 H34" stroke="${arc}" stroke-width="2.6" stroke-linecap="round"/></svg>`;

const css = `
${font('Gurbani', 'NotoSerifGurmukhi-SemiBold.ttf', 600)}
${font('Gurbani', 'NotoSerifGurmukhi-Regular.ttf', 400)}
${font('Pa', 'BalooPaaji2-Medium.ttf', 500)}
${font('Pa', 'BalooPaaji2-SemiBold.ttf', 600)}
${font('Pa', 'BalooPaaji2-Bold.ttf', 700)}
${font('Serif', 'PlayfairDisplay-SemiBold.ttf', 600)}
${font('Serif', 'PlayfairDisplay-Bold.ttf', 700)}
* { box-sizing: border-box; margin: 0; }
body { font-family: Inter, system-ui, sans-serif; -webkit-font-smoothing: antialiased; }
.stage { position: relative; overflow: hidden; display: flex; flex-direction: column; padding: 84px 84px 64px; }
.disp { font-family: 'Inter Display', Inter, sans-serif; }
.gur { font-family: 'Gurbani', serif; }
.pa { font-family: 'Pa', 'Gurbani', sans-serif; }
.serif { font-family: 'Serif', 'Gurbani', serif; }
.pill { display: inline-flex; align-items: center; gap: 14px; border-radius: 999px; padding: 14px 28px;
  font-size: 28px; font-weight: 600; letter-spacing: .02em; }
.grow { flex: 1; }
.foot { display: flex; align-items: center; gap: 18px; font-size: 30px; font-weight: 600; }
.foot .url { margin-left: auto; font-weight: 500; opacity: .75; }
`;

const foot = (ink, sun, extra = '') => `<div class="foot" style="color:${ink}">
  ${mark(64, ink, sun)}<span class="disp" style="font-size:38px;font-weight:700;letter-spacing:-.01em">Hazri</span>
  <span class="url">${extra || 'hazri.me'}</span></div>`;

const dateFmt = (iso, opt) => new Date(iso + 'T00:00:00Z').toLocaleDateString('en-GB', { timeZone: 'UTC', ...opt });
const addDays = (iso, n) => { const d = new Date(iso + 'T00:00:00Z'); d.setUTCDate(d.getUTCDate() + n); return d.toISOString().slice(0, 10); };
const daysSince1970 = (iso) => Math.round(Date.parse(iso + 'T00:00:00Z') / 864e5);
const H = { feed: 1350, story: 1920 };

// ---------------------------------------------------------------- Vichar
function vichar(v, iso, size) {
  const night = daysSince1970(iso) % 2 === 1;
  const bg = night
    ? `radial-gradient(120% 70% at 50% 0%, #2A2F6B 0%, ${T.night} 62%)`
    : `linear-gradient(180deg, #FDE3C2 0%, #FFF6EC 46%, #FFFFFF 100%)`;
  const ink = night ? '#EDECF6' : T.ink, ink2 = night ? '#B9BAD3' : T.ink2;
  const acc = night ? T.amber : T.kesri;
  const long = v.gurmukhi.length > 70;
  const big = size === 'story' ? (long ? 70 : 88) : (long ? 62 : 80);
  return `<div class="stage" style="width:1080px;height:${H[size]}px;background:${bg};color:${ink}">
    <div style="display:flex;align-items:center;gap:18px">
      <span class="pill pa" style="background:${night ? 'rgba(242,162,78,.16)' : '#fff'};color:${night ? T.amberInk : T.kesriInk};font-size:32px">ਅੱਜ ਦਾ ਵਿਚਾਰ</span>
      <span style="font-size:28px;color:${ink2};font-weight:500">${esc(dateFmt(iso, { weekday: 'long', day: 'numeric', month: 'long' }))}</span>
    </div>
    <div class="grow" style="display:flex;flex-direction:column;justify-content:center">
      <div class="gur" style="font-size:72px;color:${acc};text-align:center;margin-bottom:36px">ੴ</div>
      <div class="gur" style="font-size:${big}px;line-height:1.5;font-weight:600;text-align:center">${esc(v.gurmukhi)}</div>
      <div style="width:120px;height:6px;border-radius:3px;background:${acc};margin:52px auto"></div>
      <div class="pa" style="font-size:40px;line-height:1.55;text-align:center;color:${ink};font-weight:500">${esc(v.meaning_pa)}</div>
      <div style="font-size:30px;line-height:1.5;text-align:center;color:${ink2};margin-top:28px">${esc(v.meaning_en)}</div>
    </div>
    ${foot(ink, acc, 'A line a day, in the Hazri app')}
  </div>`;
}

// ---------------------------------------------------------------- Calendar
const KIND = {
  prakash: { bg: '#FBE3C6', band: T.kesri, ink: T.kesriInk, label: 'Prakash Purab' },
  gurgaddi: { bg: '#FBE3C6', band: T.kesri, ink: T.kesriInk, label: 'Gurgaddi Purab' },
  'joti-jot': { bg: T.lavender, band: '#5B4FA0', ink: T.lavenderInk, label: 'Joti Jot Purab' },
  shaheedi: { bg: '#E7E8F3', band: T.navy, ink: T.navy, label: 'Shaheedi Purab' },
};
function calendar(e, story, size) {
  const k = KIND[e.kind] || { bg: T.sageSoft, band: T.sage, ink: T.sage, label: 'Sikh calendar' };
  const name = e.name_en.split(' – ');
  const desc = story ? story.desc : '';
  return `<div class="stage" style="width:1080px;height:${H[size]}px;background:${k.bg};color:${T.ink}">
    <div style="display:flex;align-items:center;gap:18px">
      <span class="pill" style="background:#fff;color:${k.ink}">SIKH CALENDAR</span>
      <span style="font-size:28px;color:${T.ink2};font-weight:500">${esc(e.ns_label || '')}</span>
    </div>
    <div class="grow" style="display:flex;flex-direction:column;justify-content:center">
      <div style="background:#fff;border-radius:44px;overflow:hidden;box-shadow:0 30px 80px rgba(27,29,58,.16)">
        <div style="background:${k.band};color:#fff;padding:30px 56px;display:flex;justify-content:space-between;font-size:34px;font-weight:700;letter-spacing:.12em">
          <span>${esc(dateFmt(e.date, { month: 'long' }).toUpperCase())}</span><span>${esc(dateFmt(e.date, { year: 'numeric' }))}</span></div>
        <div style="padding:30px 56px 56px">
          <div style="display:flex;align-items:baseline;gap:28px">
            <div class="disp" style="font-size:220px;font-weight:700;line-height:1;color:${k.band}">${dateFmt(e.date, { day: 'numeric' })}</div>
            <div style="font-size:40px;font-weight:600;color:${T.ink2}">${esc(dateFmt(e.date, { weekday: 'long' }))}</div>
          </div>
          <div style="font-size:30px;font-weight:700;letter-spacing:.08em;color:${k.ink};margin-top:24px">${esc((name[1] ? name[0] : k.label).toUpperCase())}</div>
          <div class="serif" style="font-size:${size === 'story' ? 68 : 60}px;line-height:1.15;font-weight:700;margin-top:12px">${esc(name[1] || name[0])}</div>
          ${e.name_pa ? `<div class="pa" style="font-size:40px;font-weight:600;color:${T.ink2};margin-top:14px">${esc(e.name_pa)}</div>` : ''}
          ${desc ? `<div style="font-size:30px;line-height:1.5;color:${T.ink2};margin-top:28px">${esc(desc)}</div>` : ''}
        </div>
      </div>
    </div>
    ${foot(T.ink, T.kesri, story ? 'Read the story on hazri.me' : 'A reminder the evening before, in Hazri')}
  </div>`;
}

// ---------------------------------------------------------------- Quiz
function quiz(q, reveal, size) {
  const opts = ['A', 'B', 'C', 'D'].map((L) => [L, q['option_' + L.toLowerCase()]]);
  const row = ([L, t]) => {
    const right = reveal && L === q.answer, dim = reveal && !right;
    return `<div style="display:flex;align-items:center;gap:26px;padding:26px 30px;border-radius:28px;font-size:34px;font-weight:500;
      background:${right ? T.sage : '#fff'};color:${right ? '#fff' : T.ink};opacity:${dim ? .45 : 1};
      box-shadow:0 10px 30px rgba(27,29,58,.08)">
      <span style="flex:none;width:60px;height:60px;border-radius:50%;display:grid;place-items:center;font-weight:700;
        background:${right ? 'rgba(255,255,255,.22)' : T.sageSoft};color:${right ? '#fff' : T.sage}">${right ? '✓' : L}</span>${esc(t)}</div>`;
  };
  return `<div class="stage" style="width:1080px;height:${H[size]}px;background:linear-gradient(180deg,${T.sageSoft},#F7FBF8);color:${T.ink}">
    <div style="display:flex;align-items:center;gap:18px">
      <span class="pill" style="background:${T.sage};color:#fff">GURMAT QUIZ</span>
      <span style="font-size:28px;color:${T.ink2};font-weight:600">${esc(q.topic)}</span>
      <span style="margin-left:auto;font-size:28px;color:${T.sage};font-weight:700">${reveal ? '2 / 2' : '1 / 2'}</span>
    </div>
    <div class="grow" style="display:flex;flex-direction:column;justify-content:center;gap:22px">
      <div class="serif" style="font-size:${q.question.length > 90 ? 52 : 62}px;line-height:1.2;font-weight:700;margin-bottom:26px">${esc(q.question)}</div>
      ${opts.map(row).join('')}
      ${reveal
        ? `<div style="font-size:30px;line-height:1.5;color:${T.ink2};margin-top:18px">${esc(q.explanation)}</div>`
        : `<div style="font-size:32px;font-weight:600;color:${T.sage};margin-top:22px">Answer in the comments, then swipe →</div>`}
    </div>
    ${foot(T.ink, T.kesri, reveal ? 'Five questions a day in Hazri' : 'hazri.me')}
  </div>`;
}

// ---------------------------------------------------------------- Saakhi
function saakhi(s, size) {
  return `<div class="stage" style="width:1080px;height:${H[size]}px;background:${T.night};color:#EDECF6;padding:0">
    <img src="${dataUrl(s.cover)}" style="position:absolute;left:0;top:0;width:1080px;height:${size === 'story' ? 1920 : 1919}px;object-fit:cover;object-position:top">
    <div style="position:absolute;left:0;right:0;bottom:0;height:${size === 'story' ? 760 : 620}px;background:linear-gradient(180deg,rgba(12,15,36,0),rgba(12,15,36,.92) 45%,${T.night})"></div>
    <div style="position:absolute;left:84px;right:84px;bottom:64px">
      <span class="pill" style="background:${T.amber};color:#1C1206">SAAKHI · ਸਾਖੀ</span>
      <div class="serif" style="font-size:64px;font-weight:700;margin-top:26px;line-height:1.15">${esc(s.subtitle.en)}</div>
      <div class="pa" style="font-size:40px;font-weight:600;color:${T.amberInk};margin-top:10px">${esc(s.subtitle.pa)}</div>
      <div style="font-size:30px;color:#B9BAD3;margin:22px 0 40px">Read and listen with your children, in Punjabi or English.</div>
      ${foot('#EDECF6', T.amber, 'Free in the Hazri app')}
    </div>
  </div>`;
}

// ---------------------------------------------------------------- Brand
function privacy() {
  const line = (t, c) => `<div style="display:flex;align-items:center;gap:30px;font-size:58px;font-weight:700">
    <span style="width:22px;height:22px;border-radius:50%;background:${c}"></span>${t}</div>`;
  return `<div class="stage" style="width:1080px;height:1350px;background:${T.navy};color:#fff">
    <span class="pill" style="background:rgba(255,255,255,.12);color:#fff;align-self:flex-start">YOUR PAATH IS YOURS</span>
    <div class="grow" style="display:flex;flex-direction:column;justify-content:center;gap:34px">
      ${line('No ads.', T.amber)}${line('No tracking.', T.amber)}${line('No password.', T.amber)}
      <div style="height:6px;width:120px;border-radius:3px;background:${T.amber};margin:20px 0"></div>
      <div class="serif" style="font-size:62px;line-height:1.2;font-weight:700">Read, listen and keep your diary, even offline.</div>
      <div style="font-size:32px;line-height:1.5;color:#C9CBE6">Nitnem, Simran and your Diary live on your phone. The sangat is there when you choose to join it.</div>
    </div>
    ${foot('#fff', T.amber)}
  </div>`;
}
function features() {
  const tile = (bg, ink, title, sub) => `<div style="background:${bg};border-radius:36px;padding:38px 40px;display:flex;flex-direction:column;justify-content:flex-end">
    <div class="disp" style="font-size:44px;font-weight:700;color:${ink}">${title}</div>
    <div style="font-size:27px;line-height:1.4;color:${T.ink2};margin-top:10px">${sub}</div></div>`;
  return `<div class="stage" style="width:1080px;height:1350px;background:${T.bg};color:${T.ink}">
    <div class="serif" style="font-size:72px;font-weight:700;line-height:1.1">A day with Hazri</div>
    <div style="font-size:32px;color:${T.ink2};margin-top:14px">Everything for your daily paath, in one quiet app.</div>
    <div class="grow" style="display:grid;grid-template-columns:1fr 1fr;grid-template-rows:1fr 1fr 1fr;gap:26px;margin:46px 0">
      ${tile('#FBE3C6', T.kesriInk, 'Nitnem', 'Nine banis with recitation, line by line.')}
      ${tile(T.sageSoft, T.sage, 'Goals', 'Your paath through the day, with a reminder at each.')}
      ${tile(T.lavender, T.lavenderInk, 'Diary', 'Every day you sat, and your streak.')}
      ${tile('#E7E8F3', T.navy, 'Simran', 'Sit with the sangat around the world.')}
      ${tile('#FDEFD9', T.kesriInk, 'Saakhis', 'Stories to read and hear with children.')}
      ${tile('#E2F1F3', '#1F7A8C', 'Gurmat Quiz', 'Five questions a day.')}
    </div>
    ${foot(T.ink, T.kesri, 'Free on Google Play')}
  </div>`;
}

// ---------------------------------------------------------------- Plan
const tags = '#Sikh #Sikhi #Gurbani #Waheguru #Nitnem #Hazri';
function plan(from, days) {
  const posts = [];
  const nV = data.vichar.length;
  const remind = data.events.filter((e) => e.default_remind);
  const quizPool = data.quiz.filter((q) => q.difficulty !== 'hard');
  for (let i = 0; i < days; i++) {
    const iso = addDays(from, i), dow = new Date(iso + 'T00:00:00Z').getUTCDay(), n = daysSince1970(iso);
    const v = data.vichar[n % nV];
    posts.push({ iso, kind: 'vichar', pages: [(s) => vichar(v, iso, s)], story: true,
      caption: `ਅੱਜ ਦਾ ਵਿਚਾਰ · Today's Vichar\n\n${v.gurmukhi}\n\n${v.meaning_pa}\n\n${v.meaning_en}\n\nA line from Sri Guru Granth Sahib Ji every day, in the Hazri app.\n\n${tags}` });
    for (const e of remind.filter((e) => e.date === addDays(iso, 1))) {
      const st = data.stories[e.name_en];
      posts.push({ iso, kind: `calendar-${e.id}`, pages: [(s) => calendar(e, st, s)], story: true,
        caption: `Tomorrow, ${dateFmt(e.date, { weekday: 'long', day: 'numeric', month: 'long' })}: ${e.name_en}${e.name_pa ? `\n${e.name_pa}` : ''}\n\n${st ? st.desc + `\n\nRead the story: hazri.me/gurpurab/${st.slug}` : ''}\n\nHazri reminds you of every Gurpurab the evening before.\n\n${tags} #Gurpurab`.replace(/\n{3,}/g, '\n\n') });
    }
    if (dow === 2) {
      const w = Math.floor(n / 7), q = quizPool[(w * 37) % quizPool.length];
      posts.push({ iso, kind: 'quiz', pages: [(s) => quiz(q, false, s), (s) => quiz(q, true, s)],
        caption: `Gurmat Quiz · ${q.topic}\n\n${q.question}\n\nAnswer in the comments, then swipe for the answer. Five new questions every day in Hazri.\n\n${tags} #SikhHistory #GurmatQuiz` });
    }
    if (dow === 5) {
      const s = data.saakhi[Math.floor(n / 7) % data.saakhi.length];
      posts.push({ iso, kind: `saakhi-${s.id}`, pages: [(z) => saakhi(s, z)], story: true,
        caption: `${s.title.en} · ${s.title.pa}\n${s.subtitle.en}\n\nA saakhi to read and listen to with your children, narrated in Punjabi, free in the Hazri app.\n\n${tags} #Saakhi #SikhKids` });
    }
  }
  posts.push({ iso: 'brand', kind: 'privacy', pages: [() => privacy()],
    caption: `No ads. No tracking. No password.\n\nHazri keeps your Nitnem, Simran and Diary on your own phone, and works offline.\n\n${tags} #Privacy` });
  posts.push({ iso: 'brand', kind: 'a-day-with-hazri', pages: [() => features()],
    caption: `A day with Hazri: Nitnem with recitation, goals through the day, a diary of every day you sat, Simran with the sangat, saakhis and the Gurmat Quiz.\n\nFree on Google Play.\n\n${tags}` });
  return posts;
}

function samplePlan() {
  const today = arg('--from', new Date().toISOString().slice(0, 10));
  const all = plan(today, 60);
  const pick = (re, k = 0) => all.filter((p) => re.test(p.kind))[k];
  return [pick(/^vichar$/), pick(/^vichar$/, 1), pick(/^calendar/), pick(/^quiz$/), pick(/^saakhi/),
    ...all.filter((p) => p.iso === 'brand')].filter(Boolean);
}

(async () => {
  const posts = samples ? samplePlan()
    : plan(arg('--from', new Date().toISOString().slice(0, 10)), Number(arg('--days', 7)));
  fs.rmSync(out, { recursive: true, force: true });
  fs.mkdirSync(out, { recursive: true });
  const browser = await chromium.launch();
  const page = await browser.newPage({ deviceScaleFactor: 1 });
  const shot = async (html, w, h, file) => {
    await page.setViewportSize({ width: w, height: h });
    await page.setContent(`<!doctype html><meta charset="utf-8"><style>${css}</style><body>${html}</body>`, { waitUntil: 'load' });
    await page.evaluate(() => document.fonts.ready);
    await page.screenshot({ path: path.join(out, file), clip: { x: 0, y: 0, width: w, height: h } });
  };
  let md = '# Instagram posts\n\nDrawn by `node tools/social/build.js`. Post the feed images in order; a carousel is its numbered files.\n';
  for (const p of posts) {
    const base = `${p.iso}-${p.kind}`;
    const files = [];
    for (let i = 0; i < p.pages.length; i++) {
      const f = `${base}${p.pages.length > 1 ? `-${i + 1}` : ''}.png`;
      await shot(p.pages[i]('feed'), 1080, 1350, f); files.push(f);
    }
    if (p.story) { const f = `${base}-story.png`; await shot(p.pages[0]('story'), 1080, 1920, f); files.push(f); }
    md += `\n## ${base}\n\n${files.map((f) => `- \`${f}\``).join('\n')}\n\n\`\`\`\n${p.caption}\n\`\`\`\n`;
    console.log(files.join('  '));
  }
  fs.writeFileSync(path.join(out, 'captions.md'), md);
  await browser.close();
})();
