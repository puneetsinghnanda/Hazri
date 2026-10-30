// Draws the Google Play listing images into store/play/:
//
//   screenshot-1.png ... screenshot-8.png   1080 x 1920, phone screenshots
//   feature-graphic.png                     1024 x 500
//   icon-512.png                            512 x 512 (from make_icons.py's mark)
//
//   node tools/store/build.js
//
// Each screenshot is a current design screen (design/html/, rendered at 3x)
// in a phone, under a headline from slides.json. Uses the Playwright and
// Chromium that come with the environment; nothing is fetched.
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');

const root = path.resolve(__dirname, '..', '..');
const out = path.join(root, 'store', 'play');
const cfg = JSON.parse(fs.readFileSync(path.join(__dirname, 'slides.json'), 'utf8'));
const font = (f) => 'file://' + path.join(root, 'assets', 'fonts', f);

// tokens.json, light and dark.
const NAVY = '#262C63', INK = '#1B1D3A', MIDNIGHT = '#0C0F24', KESRI = '#D9730D', KESRI2 = '#F2A24E';

const css = `
@font-face { font-family: Playfair; src: url(${font('PlayfairDisplay-SemiBold.ttf')}); font-weight: 600; }
@font-face { font-family: Playfair; src: url(${font('PlayfairDisplay-Bold.ttf')}); font-weight: 700; }
* { box-sizing: border-box; margin: 0; }
body { font-family: Inter, system-ui, sans-serif; -webkit-font-smoothing: antialiased; }
.stage { position: relative; overflow: hidden; color: #fff;
  background: radial-gradient(120% 60% at 50% 102%, rgba(242,162,78,.42), rgba(242,162,78,0) 60%),
              linear-gradient(180deg, ${NAVY} 0%, ${INK} 100%); }
.stage.night { background: radial-gradient(90% 45% at 50% 100%, rgba(108,203,156,.20), rgba(108,203,156,0) 60%),
              linear-gradient(180deg, #161A37 0%, ${MIDNIGHT} 100%); }
/* The mark's arc and sun, drawn faintly behind the headline. */
.arc { position: absolute; border: 6px solid rgba(255,255,255,.07); border-bottom: 0;
  border-radius: 50% 50% 0 0 / 100% 100% 0 0; }
.sun { position: absolute; background: ${KESRI2}; border-radius: 999px 999px 0 0; opacity: .9; }
h1 { font-family: Playfair; font-weight: 700; letter-spacing: -.005em; text-wrap: balance; }
.sub { color: rgba(255,255,255,.78); text-wrap: balance; }
.chips { display: flex; gap: 14px; justify-content: center; flex-wrap: wrap; }
.chip { border: 2px solid rgba(242,162,78,.75); color: #FFE2C2; border-radius: 999px;
  padding: 10px 24px; font-size: 30px; font-weight: 600; background: rgba(242,162,78,.10); }
.phone { position: absolute; background: #05060f; padding: 16px; border-radius: 86px;
  box-shadow: 0 40px 90px rgba(0,0,0,.45), 0 0 0 3px rgba(255,255,255,.10); }
.phone img { display: block; width: 100%; border-radius: 70px; }
`;

function shot(ss, i) {
  const s = cfg.slides[i];
  const chips = s.chips ? `<div class="chips" style="margin-top:34px">${s.chips.map((c) => `<span class="chip">${c}</span>`).join('')}</div>` : '';
  const top = s.chips ? 520 : 380;
  const w = 1080, phoneW = Math.round((1920 - top - 40 - 32) * 390 / 844) + 32;
  return `<div class="stage ${s.tone || ''}" style="width:1080px;height:1920px">
    <div class="arc" style="width:900px;height:450px;left:90px;top:40px"></div>
    <div style="position:absolute;left:80px;right:80px;top:96px;text-align:center">
      <h1 style="font-size:76px;line-height:1.08">${s.title}</h1>
      <p class="sub" style="font-size:36px;line-height:1.35;margin-top:22px">${s.sub}</p>
      ${chips}
    </div>
    <div class="phone" style="width:${phoneW}px;left:${(w - phoneW) / 2}px;top:${top}px">
      <img src="${ss[s.screen]}"></div>
  </div>`;
}

function feature(ss) {
  const f = cfg.feature;
  const phones = f.screens.map((n, k) => {
    const w = [250, 280, 250][k], x = [520, 650, 790][k], y = [96, 52, 110][k], r = [-8, 0, 8][k];
    return `<div class="phone" style="width:${w}px;left:${x}px;top:${y}px;padding:9px;border-radius:44px;transform:rotate(${r}deg);z-index:${k === 1 ? 3 : 1}">
      <img src="${ss[n]}" style="border-radius:36px"></div>`;
  }).join('');
  return `<div class="stage" style="width:1024px;height:500px">
    <div class="arc" style="width:520px;height:260px;left:40px;top:150px"></div>
    <div style="position:absolute;left:84px;top:150px;width:440px">
      <div style="display:flex;align-items:center;gap:22px">
        <div style="position:relative;width:96px;height:64px">
          <div style="position:absolute;left:0;top:0;width:96px;height:48px;border:7px solid #fff;border-bottom:0;border-radius:48px 48px 0 0"></div>
          <div class="sun" style="left:28px;top:20px;width:40px;height:20px;background:${KESRI}"></div>
          <div style="position:absolute;left:-6px;right:-6px;top:41px;height:7px;background:#fff;border-radius:4px"></div>
        </div>
        <h1 style="font-size:96px;line-height:1">${f.title}</h1>
      </div>
      <p class="sub" style="font-size:30px;line-height:1.3;margin-top:26px">${f.sub}</p>
    </div>
    ${phones}
  </div>`;
}

(async () => {
  const browser = await chromium.launch();
  const names = new Set([...cfg.slides.map((s) => s.screen), ...cfg.feature.screens]);
  const raw = await browser.newPage({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 3 });
  const ss = {};
  for (const n of names) {
    await raw.goto('file://' + path.join(root, 'design', 'html', n + '.html'));
    await raw.waitForTimeout(700); // the globe and the fonts settle
    ss[n] = 'data:image/png;base64,' + (await raw.screenshot()).toString('base64');
  }

  const page = await browser.newPage({ deviceScaleFactor: 1 });
  const render = async (html, w, h, file) => {
    await page.setViewportSize({ width: w, height: h });
    await page.setContent(`<!doctype html><style>${css}</style>${html}`);
    await page.evaluate(() => document.fonts.ready);
    await page.waitForTimeout(200);
    await page.screenshot({ path: path.join(out, file) });
    console.log(file);
  };
  fs.mkdirSync(out, { recursive: true });
  for (let i = 0; i < cfg.slides.length; i++) await render(shot(ss, i), 1080, 1920, `screenshot-${i + 1}.png`);
  await render(feature(ss), 1024, 500, 'feature-graphic.png');
  await browser.close();

  // The icon is the launcher's own mark, drawn by the same code at 512.
  execFileSync('python3', ['-c', `
import sys; sys.path.insert(0, ${JSON.stringify(path.join(root, 'tools', 'content_pipeline'))})
from make_icons import draw_mark, BG, NAVY, KESRI
draw_mark(512, inset=0.66, background=BG, arc_colour=NAVY, sun_colour=KESRI).convert('RGB').save(${JSON.stringify(path.join(out, 'icon-512.png'))})
`]);
  console.log('icon-512.png');
})();
