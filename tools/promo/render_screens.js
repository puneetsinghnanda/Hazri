const { chromium } = require('playwright');
const path = require('path');
const names = process.argv.slice(3);
const out = process.argv[2];
(async () => {
  const b = await chromium.launch();
  const p = await b.newPage({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 4 });
  for (const n of names) {
    await p.goto('file://' + path.resolve(__dirname, '../../design/html', n + '.html'));
    await p.evaluate(() => document.fonts.ready);
    await p.waitForTimeout(900);
    const el = await p.$('.app') ;
    await (el || p).screenshot({ path: path.join(out, n + '.png') });
    console.log(n);
  }
  await b.close();
})();
