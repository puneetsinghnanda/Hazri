// node frames.js <outdir> <dsf> <fps> <start> <end> [times...]
const { chromium } = require('playwright');
const [out, dsf, fps, a, b, ...times] = process.argv.slice(2);
(async () => {
  const br = await chromium.launch();
  const p = await br.newPage({ viewport: { width: 1920, height: 1080 }, deviceScaleFactor: +dsf });
  await p.goto('file://' + __dirname + '/stage.html');
  await p.evaluate(() => document.fonts.ready);
  await p.evaluate(() => { const c = document.getElementById('bg'); c.width = 1920 * devicePixelRatio; c.height = 1080 * devicePixelRatio; });
  const list = times.length ? times.map(Number) : [];
  if (!list.length) for (let f = +a; f < +b; f++) list.push(f / +fps);
  for (const t of list) {
    await p.evaluate(t => window.render(t), t);
    await p.evaluate(() => new Promise(r => requestAnimationFrame(() => requestAnimationFrame(r))));
    const f = Math.round(t * +fps);
    await p.screenshot({ path: `${out}/f${String(f).padStart(5, '0')}.jpg`, type: 'jpeg', quality: 94 });
  }
  await br.close();
})();
