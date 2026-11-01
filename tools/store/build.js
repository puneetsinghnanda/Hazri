// Draws the Google Play listing images into store/play/ (style B, "Bold",
// chosen by the owner on 2026-11-01 from three): white, an all-caps headline
// with one word ringed, a dashed path to the sun-arc mark, chips round the
// phone, and the slide's card lifted out of the screen.
//
//   screenshot-1.png ... screenshot-8.png   1080 x 1920, phone screenshots
//   feature-graphic.png                     1024 x 500
//   icon-512.png                            512 x 512, the launcher mark
//
//   node tools/store/build.js
//
// Each screenshot is a current design screen (design/html/, rendered at 3x).
// Uses the Playwright and Chromium that come with the environment and the
// fonts on the machine; nothing is fetched.
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');

const root = path.resolve(__dirname, '..', '..');
const out = path.join(root, 'store', 'play');
const cfg = JSON.parse(fs.readFileSync(path.join(__dirname, 'slides.json'), 'utf8'));
const file = (...p) => 'file://' + path.join(root, ...p);

// tokens.json
const NAVY = '#262C63', INK = '#1B1D3A', KESRI = '#D9730D', SAGE = '#2E7A57';

// The app mark on its 40 x 40 grid (make_icons.py, AppMark).
const mark = (size, arc, sun) => `<svg width="${size}" height="${size}" viewBox="0 0 40 40">
  <path d="M4 27 A16 16 0 0 1 36 27" fill="none" stroke="${arc}" stroke-width="2.6"/>
  <path d="M12 27 A8 8 0 0 1 28 27 Z" fill="${sun}"/>
  <path d="M6 31.5 H34" stroke="${arc}" stroke-width="2.6" stroke-linecap="round"/></svg>`;

const css = `
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

const frameB = `background:#0B0C14;box-shadow:0 50px 110px rgba(0,0,0,.28), inset 0 0 0 4px #2a2c36`;
const ring = (w) => `<span style="position:relative;display:inline-block;padding:0 .12em">${w}
  <svg viewBox="0 0 100 40" preserveAspectRatio="none" style="position:absolute;left:-7%;top:-16%;width:114%;height:132%;overflow:visible">
    <ellipse cx="50" cy="20" rx="49" ry="19" fill="none" stroke="${INK}" stroke-width="1.6" vector-effect="non-scaling-stroke" style="stroke-width:7px" transform="rotate(-2 50 20)"/></svg></span>`;
function slide(s, i) {
  const caps = s.title.toUpperCase().replace(s.key.toUpperCase(), ring(s.key.toUpperCase()));
  const pw = 640, px = (1080 - pw) / 2, py = 880;
  let body = '';
  if (s.covers) body += s.covers.map((c, k) => `<img src="data:image/webp;base64,${fs.readFileSync(path.join(root, 'assets', 'saakhi', c, 'cover.webp')).toString('base64')}" style="position:absolute;width:330px;border-radius:36px;
    left:${[40, 375, 710][k]}px;top:${[760, 720, 770][k]}px;transform:rotate(${[-8, 2, 9][k]}deg);box-shadow:0 30px 70px rgba(0,0,0,.25);border:8px solid #fff">`).join('');
  body += phone(s.screen, pw, px, s.covers ? 1080 : py, frameB);
  const chips = s.chips || [];
  body += chips.map((c, k) => `<div class="chip" style="left:${[50, 700, 90][k]}px;top:${[1060, 1290, 1470][k]}px;padding:20px 34px;font-size:36px;
    box-shadow:0 18px 50px rgba(27,29,58,.16);transform:rotate(${[-4, 3, -2][k]}deg)">
    <span class="dot" style="background:${s.tone === 'night' ? ['#F2A24E', '#5BD38D', '#6FA8FF'][k] : [KESRI, SAGE, NAVY][k]}"></span>${c}</div>`).join('');
  if (s.pop && !s.covers) body += pop(s.screen, s.pop, 2.2, (1080 - s.pop[2] * 2.2) / 2, 1620,
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

// ---- feature graphics --------------------------------------------------------
function feature() {
  const [, b] = cfg.feature.screens;
  return `<div class="stage" style="width:1024px;height:500px;color:${INK};background:radial-gradient(90% 90% at 50% 40%, #FFFFFF, #ECEDF2)">
    <div style="position:absolute;left:70px;top:120px;width:640px">
      <h1 class="disp" style="font-size:150px;line-height:1;font-weight:900;letter-spacing:-.02em">${ring('HAZRI')}</h1>
      <p style="font-size:34px;line-height:1.3;margin-top:30px;color:#3a3d5c">${cfg.feature.sub}</p></div>
    <svg width="400" height="200" style="position:absolute;left:520px;top:30px" viewBox="0 0 400 200"><path d="M10 170 C 120 40, 220 200, 330 60" fill="none" stroke="${INK}" stroke-width="5" stroke-dasharray="3 18" stroke-linecap="round"/></svg>
    ${phone(b, 270, 690, 70, frameB)}</div>`;
}
// ---- the developer page ------------------------------------------------------
// Play Console -> Settings -> Developer page. The developer is Puneet Singh
// Nanda, for every app, so the monogram is the one that outlives Hazri; the
// mark is the one that matches it while it is the only app.
function devMonogram() {
  return `<div class="stage" style="width:512px;height:512px;background:${NAVY};display:flex;align-items:center;justify-content:center">
    <div style="position:absolute;left:0;right:0;bottom:0;height:46%;background:radial-gradient(60% 90% at 50% 100%, rgba(242,162,78,.55), transparent 70%)"></div>
    <div style="position:relative;text-align:center;color:#fff">
      <div class="disp" style="font-size:176px;font-weight:900;letter-spacing:-.03em;line-height:1">PSN</div>
      <div style="height:16px;width:300px;margin:26px auto 0;border-radius:8px;background:${KESRI}"></div>
    </div></div>`;
}
function devMark() {
  return `<div class="stage" style="width:512px;height:512px;background:${NAVY};display:flex;align-items:center;justify-content:center">
    <div style="position:absolute;left:0;right:0;bottom:0;height:50%;background:radial-gradient(60% 90% at 50% 100%, rgba(242,162,78,.45), transparent 70%)"></div>
    <div style="position:relative">${mark(340, '#fff', KESRI)}</div></div>`;
}
// The header: 4096 x 2304, drawn at a quarter and scaled up by the page.
function devHeader() {
  const [a, b, c] = cfg.feature.screens;
  return `<div class="stage" style="width:1024px;height:576px;color:${INK};background:radial-gradient(90% 90% at 50% 40%, #FFFFFF, #ECEDF2)">
    <div style="position:absolute;left:80px;top:170px;width:470px">
      <div style="display:flex;align-items:center;gap:14px">${mark(60, NAVY, KESRI)}<span style="font-size:40px;font-weight:700">Hazri</span></div>
      <h1 class="disp" style="font-size:62px;line-height:1.02;font-weight:900;letter-spacing:-.02em;margin-top:22px">NITNEM, SIMRAN AND ${ring('SANGAT')}</h1>
      <p style="font-size:24px;margin-top:22px;color:#3a3d5c">Every day, on your phone.<br>No ads, no login.</p></div>
    ${phone(a, 230, 560, 150, frameB, 'transform:rotate(-8deg)')}${phone(c, 230, 790, 160, frameB, 'transform:rotate(8deg)')}${phone(b, 250, 670, 90, frameB, 'z-index:2')}</div>`;
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
  fs.mkdirSync(out, { recursive: true });
  for (let i = 0; i < cfg.slides.length; i++) await render(slide(cfg.slides[i], i), 1080, 1920, `screenshot-${i + 1}.png`);
  await render(feature(), 1024, 500, 'feature-graphic.png');
  fs.mkdirSync(path.join(out, 'developer'), { recursive: true });
  await render(devMonogram(), 512, 512, 'developer/icon-monogram.png');
  await render(devMark(), 512, 512, 'developer/icon-mark.png');
  // Play takes at most 1 MB here, so a JPEG, drawn at 4x for 4096 x 2304.
  const big = await browser.newPage({ viewport: { width: 1024, height: 576 }, deviceScaleFactor: 4 });
  await big.setContent(`<!doctype html><style>${css}</style>${devHeader()}`, { waitUntil: 'load' });
  await big.evaluate(() => document.fonts.ready);
  await big.screenshot({ path: path.join(out, 'developer', 'header.jpg'), type: 'jpeg', quality: 86 });
  console.log('developer/header.jpg');
  await browser.close();

  // The icon is the launcher's own mark, drawn by the same code at 512.
  execFileSync('python3', ['-c', `
import sys; sys.path.insert(0, ${JSON.stringify(path.join(root, 'tools', 'content_pipeline'))})
from make_icons import draw_mark, BG, NAVY, KESRI
draw_mark(512, inset=0.66, background=BG, arc_colour=NAVY, sun_colour=KESRI).convert('RGB').save(${JSON.stringify(path.join(out, 'icon-512.png'))})
`]);
  console.log('icon-512.png');
})();
