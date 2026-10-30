// Draws the Google Play listing images, in three styles, into store/play/:
//
//   a/  Airy      light lavender, huge two-line headline, a tilted phone with
//                 the slide's card lifted out of it
//   b/  Bold      white, an all-caps headline with one word ringed, a dashed
//                 path to the sun-arc mark, chips floating round the phone
//   c/  Saffron   a saffron sky, a pinned sticker, a headline at the top or
//                 the bottom, the phone tilted off the edge
//
//   each: screenshot-1.png ... screenshot-8.png   1080 x 1920
//         feature-graphic.png                     1024 x 500
//   and   icon-512.png                            512 x 512, shared
//
//   node tools/store/build.js
//
// Each screenshot is a current design screen (design/html/, rendered at 3x).
// Uses the Playwright and Chromium that come with the environment and the
// fonts on the machine and in assets/; nothing is fetched.
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');

const root = path.resolve(__dirname, '..', '..');
const out = path.join(root, 'store', 'play');
const cfg = JSON.parse(fs.readFileSync(path.join(__dirname, 'slides.json'), 'utf8'));
const file = (...p) => 'file://' + path.join(root, ...p);

// tokens.json
const NAVY = '#262C63', INK = '#1B1D3A', KESRI = '#D9730D', KESRI2 = '#F2A24E', SAGE = '#2E7A57';

// The app mark on its 40 x 40 grid (make_icons.py, AppMark).
const mark = (size, arc, sun) => `<svg width="${size}" height="${size}" viewBox="0 0 40 40">
  <path d="M4 27 A16 16 0 0 1 36 27" fill="none" stroke="${arc}" stroke-width="2.6"/>
  <path d="M12 27 A8 8 0 0 1 28 27 Z" fill="${sun}"/>
  <path d="M6 31.5 H34" stroke="${arc}" stroke-width="2.6" stroke-linecap="round"/></svg>`;

const css = `
@font-face { font-family: Playfair; src: url(${file('assets/fonts/PlayfairDisplay-Bold.ttf')}); font-weight: 700; }
* { box-sizing: border-box; margin: 0; }
body { font-family: Inter, system-ui, sans-serif; -webkit-font-smoothing: antialiased; }
.stage { position: relative; overflow: hidden; }
.disp { font-family: 'Inter Display', Inter, sans-serif; }
.phone { position: absolute; border-radius: 9% / 4.2%; }
.phone .scr { width: 100%; display: block; border-radius: 7.6% / 3.5%; }
.pop { position: absolute; background-repeat: no-repeat; }
.chip { position: absolute; display: flex; align-items: center; gap: 14px; white-space: nowrap;
  background: #fff; color: ${INK}; border-radius: 999px; font-weight: 600; }
.dot { width: 20px; height: 20px; border-radius: 50%; }
`;

// One screen at 3x, as a data URL, and the helpers that place it.
let ss = {};
const phone = (n, w, x, y, frame, extra = '') =>
  `<div class="phone" style="width:${w}px;left:${x}px;top:${y}px;padding:${w * 0.026}px;${frame};${extra}">
     <img class="scr" src="${ss[n]}"></div>`;
// A card cut out of the screen, `scale` times its size in dp.
const pop = (n, [x, y, w, h], scale, left, top, extra = '') =>
  `<div class="pop" style="left:${left}px;top:${top}px;width:${w * scale}px;height:${h * scale}px;
     background-image:url(${ss[n]});background-size:${390 * scale}px ${844 * scale}px;
     background-position:${-x * scale}px ${-y * scale}px;border-radius:${14 * scale}px;${extra}"></div>`;
const keyed = (s, wrap) => s.title.replace(s.key, wrap(s.key));

// A laurel: leaves either side of two short lines.
const laurel = (l1, l2, colour) => {
  const leaves = (flip) => {
    let d = '';
    for (let i = 0; i < 7; i++) {
      // Up the left side of a circle, from the bottom; the right is a mirror.
      const deg = 115 + i * 22, a = deg * Math.PI / 180, cx = 78 + 56 * Math.cos(a), cy = 75 + 60 * Math.sin(a);
      d += `<ellipse cx="${cx}" cy="${cy}" rx="8" ry="15" transform="rotate(${deg + 35} ${cx} ${cy})" fill="${colour}"/>`;
    }
    return `<svg width="120" height="150" viewBox="0 0 120 150" style="${flip ? 'transform:scaleX(-1)' : ''}">${d}</svg>`;
  };
  return `<div style="display:flex;align-items:center;gap:0">${leaves(false)}
    <div style="text-align:center;min-width:170px;font-weight:800;line-height:1.1">
      <div style="font-size:40px">${l1}</div><div style="font-size:30px;font-weight:600;opacity:.75">${l2}</div></div>${leaves(true)}</div>`;
};

// ---- a: Airy ---------------------------------------------------------------
const frameA = `background:linear-gradient(145deg,#4A54A8 0%,${NAVY} 30%,#12153A 70%,#3B4390 100%);
  box-shadow:0 60px 120px rgba(38,44,99,.35), inset 0 0 0 3px rgba(255,255,255,.25)`;
function slideA(s, i) {
  const night = s.tone === 'night';
  const bg = night
    ? `radial-gradient(70% 40% at 80% 10%, rgba(108,203,156,.25), transparent 70%), linear-gradient(180deg,#161A37,#0C0F24)`
    : `radial-gradient(60% 35% at 92% 4%, rgba(242,162,78,.35), transparent 70%), radial-gradient(70% 40% at 0% 100%, rgba(38,44,99,.12), transparent 70%), linear-gradient(180deg,#F1EEF9,#FFFFFF)`;
  const ink = night ? '#fff' : INK;
  const tilt = i % 2 ? 'rotate(4deg)' : 'rotate(-4deg)';
  const pw = 700, px = i % 2 ? 300 : 80;
  let body = phone(s.screen, pw, px, 640, frameA, `transform:${tilt}`);
  if (s.pop) body += pop(s.screen, s.pop, 2.5, i % 2 ? 40 : 1080 - s.pop[2] * 2.5 - 40, 1020,
    `box-shadow:0 40px 90px rgba(27,29,58,.30);outline:6px solid #fff;transform:rotate(${i % 2 ? -3 : 3}deg)`);
  if (s.pop2 && !s.laurels) body += pop(s.screen, s.pop2, 2.4, 1080 - s.pop2[2] * 2.4 - 60, 1300,
    `box-shadow:0 40px 90px rgba(27,29,58,.30);outline:6px solid #fff;transform:rotate(2deg)`);
  if (s.chips && night) body += s.chips.map((c, k) => `<div class="chip" style="left:${[80, 620, 120][k]}px;top:${[820, 1080, 1460][k]}px;padding:18px 32px;font-size:34px;box-shadow:0 20px 50px rgba(0,0,0,.4)">
    <span class="dot" style="background:${['#F2A24E', '#5BD38D', '#6FA8FF'][k]}"></span>${c}</div>`).join('');
  if (s.laurels) body += `<div style="position:absolute;left:0;right:0;bottom:46px;display:flex;justify-content:center;gap:30px;color:${INK}">
    ${s.laurels.map(([a, b]) => `<div style="background:#fff;border-radius:40px;padding:6px 18px;box-shadow:0 20px 50px rgba(38,44,99,.15)">${laurel(a, b, KESRI)}</div>`).join('')}</div>`;
  return `<div class="stage" style="width:1080px;height:1920px;background:${bg};color:${ink}">
    <div style="position:absolute;left:84px;right:84px;top:110px">
      <div class="disp" style="font-size:58px;font-weight:600;color:${night ? KESRI2 : KESRI}">${s.kicker}</div>
      <h1 class="disp" style="font-size:132px;line-height:.98;font-weight:900;letter-spacing:-.025em;margin-top:10px;text-wrap:balance">${s.title}</h1>
      <p style="font-size:38px;line-height:1.35;margin-top:26px;opacity:.72;max-width:860px">${s.sub}</p>
    </div>${body}</div>`;
}

// ---- b: Bold ---------------------------------------------------------------
const frameB = `background:#0B0C14;box-shadow:0 50px 110px rgba(0,0,0,.28), inset 0 0 0 4px #2a2c36`;
const ring = (w) => `<span style="position:relative;display:inline-block;padding:0 .12em">${w}
  <svg viewBox="0 0 100 40" preserveAspectRatio="none" style="position:absolute;left:-7%;top:-16%;width:114%;height:132%;overflow:visible">
    <ellipse cx="50" cy="20" rx="49" ry="19" fill="none" stroke="${INK}" stroke-width="1.6" vector-effect="non-scaling-stroke" style="stroke-width:7px" transform="rotate(-2 50 20)"/></svg></span>`;
function slideB(s, i) {
  const caps = s.title.toUpperCase().replace(s.key.toUpperCase(), ring(s.key.toUpperCase()));
  const pw = 640, px = (1080 - pw) / 2, py = 880;
  let body = '';
  if (s.covers) body += s.covers.map((c, k) => `<img src="data:image/webp;base64,${fs.readFileSync(path.join(root, 'assets', 'saakhi', c, 'cover.webp')).toString('base64')}" style="position:absolute;width:330px;border-radius:36px;
    left:${[40, 375, 710][k]}px;top:${[760, 720, 770][k]}px;transform:rotate(${[-8, 2, 9][k]}deg);box-shadow:0 30px 70px rgba(0,0,0,.25);border:8px solid #fff">`).join('');
  body += phone(s.screen, pw, px, s.covers ? 1080 : py, frameB);
  const chips = s.chips || [];
  body += chips.map((c, k) => `<div class="chip" style="left:${[50, 700, 90][k]}px;top:${[1100, 1340, 1580][k]}px;padding:20px 34px;font-size:36px;
    box-shadow:0 18px 50px rgba(27,29,58,.16);transform:rotate(${[-4, 3, -2][k]}deg)">
    <span class="dot" style="background:${s.tone === 'night' ? ['#F2A24E', '#5BD38D', '#6FA8FF'][k] : [KESRI, SAGE, NAVY][k]}"></span>${c}</div>`).join('');
  if (s.pop && !s.covers) body += pop(s.screen, s.pop, 2.2, (1080 - s.pop[2] * 2.2) / 2, 1560,
    `box-shadow:0 30px 80px rgba(27,29,58,.25);outline:5px solid #fff;transform:rotate(-2deg)`);
  // The dashed path from the headline to the mark.
  const trail = `<svg width="1080" height="260" style="position:absolute;left:0;top:600px" viewBox="0 0 1080 260">
    <path d="M60 200 C 300 60, 560 260, 840 110" fill="none" stroke="${INK}" stroke-width="6" stroke-dasharray="4 22" stroke-linecap="round"/></svg>
    <div style="position:absolute;left:850px;top:630px;background:#fff;border-radius:50%;padding:16px;box-shadow:0 14px 40px rgba(27,29,58,.18)">${mark(96, NAVY, KESRI)}</div>`;
  return `<div class="stage" style="width:1080px;height:1920px;background:radial-gradient(90% 60% at 50% 40%, #FFFFFF, #ECEDF2);color:${INK}">
    <div style="position:absolute;left:0;right:0;top:70px;display:flex;justify-content:center;align-items:center;gap:16px">
      ${mark(64, NAVY, KESRI)}<span style="font-size:48px;font-weight:700">Hazri</span></div>
    <h1 class="disp" style="position:absolute;left:50px;right:50px;top:190px;text-align:center;font-size:${s.title.length > 16 ? 112 : 136}px;line-height:1;font-weight:900;letter-spacing:-.02em;text-wrap:balance">${caps}</h1>
    ${trail}${body}
    <p style="position:absolute;left:110px;right:110px;top:${s.title.length > 16 ? 440 : 480}px;text-align:center;font-size:38px;line-height:1.35;color:#3a3d5c;text-wrap:balance">${s.sub}</p>
  </div>`;
}

// ---- c: Saffron ------------------------------------------------------------
const frameC = `background:#141633;box-shadow:0 60px 120px rgba(120,52,0,.35), inset 0 0 0 4px rgba(255,255,255,.14)`;
const sticker = (t, x, y, r) => `<div class="chip" style="left:${x}px;top:${y}px;padding:20px 36px 20px 22px;font-size:40px;transform:rotate(${r}deg);
  box-shadow:0 20px 50px rgba(120,52,0,.25)"><span style="background:${INK};border-radius:50%;padding:8px;display:flex">${mark(40, '#fff', KESRI2)}</span>${t}</div>`;
function slideC(s, i) {
  const night = s.tone === 'night';
  const bg = night
    ? `radial-gradient(60% 40% at 20% 0%, rgba(242,162,78,.35), transparent 70%), linear-gradient(180deg,#262C63,#0C0F24)`
    : `radial-gradient(40% 18% at 20% 16%, rgba(255,255,255,.55), transparent 70%), radial-gradient(45% 20% at 85% 60%, rgba(255,255,255,.35), transparent 70%), linear-gradient(170deg,#FFE7C7 0%,#F7B76A 45%,#E98A2B 100%)`;
  const ink = night ? '#fff' : INK;
  const top = i % 2 === 0;           // headline at the top, phone below; or the other way
  const head = `<div style="position:absolute;left:80px;right:80px;${top ? 'top:250px' : 'bottom:130px'}">
      <h1 class="disp" style="font-size:128px;line-height:1;font-weight:800;letter-spacing:-.025em;text-wrap:balance">${keyed(s, (w) => `<span style="color:${night ? KESRI2 : top ? '#B5520A' : '#FFFFFF'}">${w}</span>`)}</h1>
      <p style="font-size:38px;line-height:1.35;margin-top:22px;opacity:.8;max-width:880px">${s.sub}</p></div>`;
  const pw = top ? 680 : 630, rot = top ? 7 : -7;
  let body = phone(s.screen, pw, top ? 300 : 110, top ? 880 : -140, frameC, `transform:rotate(${rot}deg)`);
  if (s.pop) body += pop(s.screen, s.pop, 2.45, Math.max(40, 1080 - s.pop[2] * 2.45 - (top ? 260 : 40)), top ? 1160 : 620,
    `box-shadow:0 40px 90px rgba(120,52,0,.35);transform:rotate(${top ? -3 : 3}deg)`);
  if (s.chips && night) body += s.chips.map((c, k) => `<div class="chip" style="left:${[60, 640, 600][k]}px;top:${[300, 520, 760][k]}px;padding:18px 32px;font-size:34px">
    <span class="dot" style="background:${['#F2A24E', '#5BD38D', '#6FA8FF'][k]}"></span>${c}</div>`).join('');
  const st = sticker(s.sticker, top ? 80 : 80, top ? 110 : 1330, top ? -4 : -3);
  return `<div class="stage" style="width:1080px;height:1920px;background:${bg};color:${ink}">${body}${head}${st}</div>`;
}

// ---- feature graphics --------------------------------------------------------
function featureA() {
  const [a, b, c] = cfg.feature.screens;
  return `<div class="stage" style="width:1024px;height:500px;color:${INK};background:radial-gradient(50% 70% at 95% 0%, rgba(242,162,78,.35), transparent 70%), linear-gradient(180deg,#F1EEF9,#FFFFFF)">
    <div style="position:absolute;left:70px;top:130px;width:470px">
      <div style="display:flex;align-items:center;gap:18px">${mark(96, NAVY, KESRI)}<h1 class="disp" style="font-size:104px;font-weight:900;letter-spacing:-.03em">${cfg.feature.title}</h1></div>
      <p style="font-size:32px;line-height:1.3;margin-top:18px;opacity:.75">${cfg.feature.sub}</p></div>
    ${phone(a, 230, 560, 120, frameA, 'transform:rotate(-8deg)')}${phone(c, 230, 800, 130, frameA, 'transform:rotate(8deg)')}${phone(b, 250, 675, 60, frameA, 'z-index:2')}</div>`;
}
function featureB() {
  const [, b] = cfg.feature.screens;
  return `<div class="stage" style="width:1024px;height:500px;color:${INK};background:radial-gradient(90% 90% at 50% 40%, #FFFFFF, #ECEDF2)">
    <div style="position:absolute;left:70px;top:120px;width:640px">
      <h1 class="disp" style="font-size:150px;line-height:1;font-weight:900;letter-spacing:-.02em">${ring('HAZRI')}</h1>
      <p style="font-size:34px;line-height:1.3;margin-top:30px;color:#3a3d5c">${cfg.feature.sub}</p></div>
    <svg width="400" height="200" style="position:absolute;left:520px;top:30px" viewBox="0 0 400 200"><path d="M10 170 C 120 40, 220 200, 330 60" fill="none" stroke="${INK}" stroke-width="5" stroke-dasharray="3 18" stroke-linecap="round"/></svg>
    ${phone(b, 270, 690, 70, frameB)}</div>`;
}
function featureC() {
  const [a, , c] = cfg.feature.screens;
  return `<div class="stage" style="width:1024px;height:500px;color:${INK};background:radial-gradient(30% 40% at 25% 20%, rgba(255,255,255,.5), transparent 70%), linear-gradient(170deg,#FFE7C7 0%,#F7B76A 50%,#E98A2B 100%)">
    <div style="position:absolute;left:70px;top:140px;width:520px">
      <h1 class="disp" style="font-size:112px;line-height:1;font-weight:800;letter-spacing:-.03em">${cfg.feature.title}</h1>
      <p style="font-size:34px;line-height:1.3;margin-top:18px;opacity:.85">${cfg.feature.sub}</p></div>
    ${sticker('No ads, no login', 70, 50, -3)}
    ${phone(a, 250, 600, 90, frameC, 'transform:rotate(-7deg)')}${phone(c, 250, 790, 40, frameC, 'transform:rotate(7deg)')}</div>`;
}

(async () => {
  const browser = await chromium.launch();
  const names = new Set([...cfg.slides.map((s) => s.screen), ...cfg.feature.screens]);
  const raw = await browser.newPage({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 3 });
  for (const n of names) {
    await raw.goto(file('design', 'html', n + '.html'));
    await raw.waitForTimeout(700); // the globe and the fonts settle
    ss[n] = 'data:image/png;base64,' + (await raw.screenshot()).toString('base64');
  }

  const page = await browser.newPage({ deviceScaleFactor: 1 });
  const render = async (html, w, h, rel) => {
    await page.setViewportSize({ width: w, height: h });
    await page.setContent(`<!doctype html><style>${css}</style>${html}`, { waitUntil: 'load' });
    await page.evaluate(() => document.fonts.ready);
    await page.waitForTimeout(150);
    await page.screenshot({ path: path.join(out, rel) });
    console.log(rel);
  };
  const styles = { a: [slideA, featureA], b: [slideB, featureB], c: [slideC, featureC] };
  for (const [dir, [slide, feature]] of Object.entries(styles)) {
    fs.mkdirSync(path.join(out, dir), { recursive: true });
    for (let i = 0; i < cfg.slides.length; i++) await render(slide(cfg.slides[i], i), 1080, 1920, `${dir}/screenshot-${i + 1}.png`);
    await render(feature(), 1024, 500, `${dir}/feature-graphic.png`);
  }
  await browser.close();

  // The icon is the launcher's own mark, drawn by the same code at 512.
  execFileSync('python3', ['-c', `
import sys; sys.path.insert(0, ${JSON.stringify(path.join(root, 'tools', 'content_pipeline'))})
from make_icons import draw_mark, BG, NAVY, KESRI
draw_mark(512, inset=0.66, background=BG, arc_colour=NAVY, sun_colour=KESRI).convert('RGB').save(${JSON.stringify(path.join(out, 'icon-512.png'))})
`]);
  console.log('icon-512.png');
})();
