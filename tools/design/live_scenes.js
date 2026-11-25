/* The live sangat scenes (designs 125-129, owner 2026-11-18), embedded by
 * tools/design/build_phase2.py into the screens that show them.
 *
 * An element with data-scene="globe|ikonkar|jot" gets a canvas drawn here.
 * Every scene loops seamlessly every 30 s and breathes every 6 s. A design
 * file is a still in the canvas, so this draws the frame at 8 s and only
 * animates when the page is opened on its own (?play).
 *
 * The globe is the app's own: the coastlines and borders of
 * tools/geo/countries-110m.json (Natural Earth 1:110m), passed in as MAP.
 * ੴ and ਵਾਹਿਗੁਰੂ are drawn from text the generator passes in; in the app they
 * come from content.db and the ARB files, never typed into Dart.
 */
(() => {
const MAP = __MAP__;
const LOOP = 30, BREATH = 6, TAU = Math.PI * 2, D2R = Math.PI / 180;
const wrap = (v, m) => ((v % m) + m) % m;
const breathAt = t => 0.5 - 0.5 * Math.cos(TAU * t / BREATH);
const rng = seed => () => { seed = (seed * 1664525 + 1013904223) % 4294967296; return seed / 4294967296; };
const CITIES = [[31.63,74.87],[30.90,75.85],[31.33,75.58],[30.73,76.78],[28.61,77.21],[19.08,72.88],[43.73,-79.76],[49.19,-122.85],
  [51.05,-114.07],[51.51,-0.38],[52.48,-1.90],[40.70,-73.82],[39.14,-121.62],[47.61,-122.33],[-37.81,144.96],[-33.87,151.21],
  [-36.85,174.76],[25.20,55.27],[1.35,103.82],[-1.29,36.82],[41.90,12.50],[52.52,13.40]];

function glow(ctx, x, y, r, stops){
  const g = ctx.createRadialGradient(x, y, 0, x, y, r);
  stops.forEach(([o, c]) => g.addColorStop(o, c));
  ctx.fillStyle = g; ctx.beginPath(); ctx.arc(x, y, r, 0, TAU); ctx.fill();
}
function word(ctx, x, y, size, alpha, sweep, text){
  ctx.save();
  ctx.font = `700 ${size}px 'Noto Serif Gurmukhi', serif`; ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
  ctx.globalAlpha = alpha; ctx.shadowColor = 'rgba(255,190,90,.9)'; ctx.shadowBlur = size * 0.6;
  const m = Math.min(.87, Math.max(.13, sweep)), g = ctx.createLinearGradient(x - size * 2.2, 0, x + size * 2.2, 0);
  g.addColorStop(0, '#B8741F'); g.addColorStop(m - .12, '#E7A94A'); g.addColorStop(m, '#FFF3D0');
  g.addColorStop(m + .12, '#E7A94A'); g.addColorStop(1, '#B8741F');
  ctx.fillStyle = g; ctx.fillText(text, x, y); ctx.restore();
}

// Naam Simran: the world turning, a thread of light from every city in view
// up to ਵਾਹਿਗੁਰੂ, a spark climbing each on every breath; your city orange.
function globe(ctx, W, H, t, o){
  const p = t / LOOP, b = breathAt(t);
  const cx = W * o.cx, cy = H * o.cy, R = W * o.r, lx = W / 2, ly = H * o.ly, ws = W * (o.ws || 0);
  let g = ctx.createRadialGradient(W / 2, cy, 10, W / 2, H * 0.5, Math.max(W, H));
  g.addColorStop(0, '#1C2366'); g.addColorStop(0.5, '#0C1038'); g.addColorStop(1, '#03040F');
  ctx.fillStyle = g; ctx.fillRect(0, 0, W, H);
  const rs = rng(23);
  for (let i = 0; i < (W * H) / 900; i++){
    const x = rs() * W, y = rs() * H, f = 1 + (rs() * 3 | 0), ph = rs();
    ctx.globalAlpha = (0.3 + 0.7 * (0.5 + 0.5 * Math.sin(TAU * (p * f + ph)))) * (0.35 + rs() * 0.65);
    ctx.fillStyle = '#DDE6FF'; ctx.beginPath(); ctx.arc(x, y, 0.4 + rs(), 0, TAU); ctx.fill();
  }
  ctx.globalAlpha = 1;
  const rot = -TAU * p + 0.4, tilt = 0.38;
  const proj = (lat, lon) => {
    const la = lat * D2R, lo = lon * D2R + rot;
    const x = Math.cos(la) * Math.sin(lo), z0 = Math.cos(la) * Math.cos(lo), y0 = Math.sin(la);
    return [cx + R * x, cy - R * (y0 * Math.cos(tilt) - z0 * Math.sin(tilt)), y0 * Math.sin(tilt) + z0 * Math.cos(tilt)];
  };
  ctx.globalCompositeOperation = 'lighter';
  glow(ctx, cx, cy, R * 1.3, [[0.74, 'rgba(90,140,255,0)'], [0.78, 'rgba(110,160,255,.32)'], [1, 'rgba(60,90,220,0)']]);
  ctx.globalCompositeOperation = 'source-over';
  g = ctx.createRadialGradient(cx - R * 0.35, cy - R * 0.45, R * 0.1, cx, cy, R);
  g.addColorStop(0, '#24439A'); g.addColorStop(1, '#0A1440');
  ctx.fillStyle = g; ctx.beginPath(); ctx.arc(cx, cy, R, 0, TAU); ctx.fill();
  ctx.strokeStyle = 'rgba(170,205,255,.75)'; ctx.lineWidth = Math.max(0.5, R / 170); ctx.lineJoin = 'round'; ctx.beginPath();
  for (const arc of MAP){
    let pen = false;
    for (const [lon, lat] of arc){
      const [x, y, z] = proj(lat, lon);
      if (z < 0){ pen = false; continue; }
      pen ? ctx.lineTo(x, y) : ctx.moveTo(x, y); pen = true;
    }
  }
  ctx.stroke();
  ctx.strokeStyle = 'rgba(150,190,255,.5)'; ctx.lineWidth = 1; ctx.beginPath(); ctx.arc(cx, cy, R, 0, TAU); ctx.stroke();
  ctx.globalCompositeOperation = 'lighter';
  glow(ctx, lx, ly, Math.max(ws, 10) * 2.6 + 18 * b, [[0, 'rgba(255,230,170,.7)'], [1, 'rgba(255,160,60,0)']]);
  CITIES.forEach(([lat, lon], i) => {
    const [x, y, z] = proj(lat, lon);
    if (z < 0.08) return;
    const vis = Math.min(1, z * 2.4), c1 = [x + (x - cx) * 0.25, (y + ly) / 2 - 20], c2 = [lx, ly + Math.max(ws, 10) * 1.6];
    const at = u => [(1-u)**3*x + 3*(1-u)**2*u*c1[0] + 3*(1-u)*u*u*c2[0] + u**3*lx,
                     (1-u)**3*y + 3*(1-u)**2*u*c1[1] + 3*(1-u)*u*u*c2[1] + u**3*ly];
    ctx.strokeStyle = `rgba(255,200,120,${0.13 * vis})`; ctx.lineWidth = 1; ctx.beginPath();
    for (let u = 0; u <= 1.001; u += 0.06){ const [px, py] = at(u); u === 0 ? ctx.moveTo(px, py) : ctx.lineTo(px, py); }
    ctx.stroke();
    const u = wrap(t / BREATH + i * 0.137, 1), [px, py] = at(u);
    glow(ctx, px, py, 4.5, [[0, `rgba(255,232,185,${vis * Math.sin(Math.PI * u)})`], [1, 'rgba(255,180,80,0)']]);
    if (i === 0){
      const k = 0.5 + 0.5 * Math.sin(TAU * t / 1.6);
      glow(ctx, x, y, 8 + 4 * k, [[0, `rgba(255,190,90,${vis})`], [1, 'rgba(242,162,78,0)']]);
    } else glow(ctx, x, y, 4 + 2 * b, [[0, `rgba(110,255,170,${0.95 * vis})`], [1, 'rgba(40,200,120,0)']]);
  });
  ctx.globalCompositeOperation = 'source-over';
  if (ws) word(ctx, lx, ly, ws, 0.78 + 0.22 * b, wrap(t / BREATH, 1) * 1.4 - 0.2, o.text);
}

// Mool Mantar: ੴ among the stars; thirteen stars join into a circle round
// it through the first half of the loop and let go through the second.
function ikonkar(ctx, W, H, t, o){
  const p = t / LOOP, b = breathAt(t), cx = W / 2, cy = H * (o.cy || 0.5), M = Math.min(W, H) * 0.4;
  let g = ctx.createRadialGradient(cx, cy, 5, cx, cy, Math.max(W, H) * 0.8);
  g.addColorStop(0, '#2A2052'); g.addColorStop(0.6, '#0D0C2A'); g.addColorStop(1, '#05040F');
  ctx.fillStyle = g; ctx.fillRect(0, 0, W, H);
  const r = rng(77);
  for (let i = 0; i < (W * H) / 600; i++){
    const tw = 0.5 + 0.5 * Math.sin(TAU * (p * (1 + (r() * 3 | 0)) + r()));
    ctx.fillStyle = `rgba(255,240,215,${0.15 + 0.6 * tw * r()})`; ctx.beginPath(); ctx.arc(r() * W, r() * H, 0.4 + r(), 0, TAU); ctx.fill();
  }
  const n = 13, joined = Math.sin(Math.PI * p) * n;
  ctx.globalCompositeOperation = 'lighter';
  const pts = Array.from({ length: n }, (_, i) => {
    const a = -Math.PI / 2 + TAU * i / n;
    return [cx + Math.cos(a) * M * (1 + 0.04 * b), cy + Math.sin(a) * M * (1 + 0.04 * b)];
  });
  ctx.strokeStyle = 'rgba(255,214,150,.45)'; ctx.lineWidth = 1;
  for (let i = 0; i < n; i++){
    const f = Math.min(1, Math.max(0, joined - i)); if (!f) continue;
    const [x1, y1] = pts[i], [x2, y2] = pts[(i + 1) % n];
    ctx.beginPath(); ctx.moveTo(x1, y1); ctx.lineTo(x1 + (x2 - x1) * f, y1 + (y2 - y1) * f); ctx.stroke();
  }
  pts.forEach(([x, y], i) => glow(ctx, x, y, 5 + 2 * b, [[0, `rgba(255,232,190,${0.6 + 0.4 * (i < joined)})`], [1, 'rgba(255,170,80,0)']]));
  glow(ctx, cx, cy, M * 0.9, [[0, `rgba(255,200,110,${0.25 + 0.15 * b})`], [1, 'rgba(255,140,40,0)']]);
  ctx.globalCompositeOperation = 'source-over';
  word(ctx, cx, cy + M * 0.05, M * 0.95, 0.85 + 0.15 * b, wrap(t / BREATH, 1) * 1.4 - 0.2, o.text);
}

// Chaupai Sahib: the jot in the shield; a diya's flame under a dome of light
// whose meridians turn round it, sparks rising inside.
function jot(ctx, W, H, t, o){
  const p = t / LOOP, b = breathAt(t), cx = W / 2, by = H * (o.by || 0.8);
  let g = ctx.createRadialGradient(cx, by, 10, cx, by, Math.max(W, H));
  g.addColorStop(0, '#3A1606'); g.addColorStop(0.5, '#170A12'); g.addColorStop(1, '#07050E');
  ctx.fillStyle = g; ctx.fillRect(0, 0, W, H);
  const R = Math.min(W * 0.42, H * 0.62);
  ctx.globalCompositeOperation = 'lighter';
  glow(ctx, cx, by - R * 0.25, R * 1.2, [[0, 'rgba(255,170,70,.32)'], [1, 'rgba(255,120,30,0)']]);
  for (let k = 0; k < 9; k++){
    const ph = wrap(k / 9 + p, 1), sx = Math.cos(TAU * ph) * R;
    if (Math.sin(TAU * ph) < 0) continue;
    ctx.strokeStyle = `rgba(255,214,140,${0.08 + 0.3 * Math.sin(TAU * ph)})`; ctx.lineWidth = 1;
    ctx.beginPath(); ctx.ellipse(cx, by, Math.abs(sx), R, 0, Math.PI, TAU); ctx.stroke();
  }
  for (let k = 1; k < 4; k++){
    const rr = R * Math.cos(k * 0.38), yy = by - R * Math.sin(k * 0.38);
    ctx.strokeStyle = 'rgba(255,214,140,.14)'; ctx.beginPath(); ctx.ellipse(cx, yy, rr, rr * 0.16, 0, 0, TAU); ctx.stroke();
  }
  ctx.strokeStyle = `rgba(255,224,160,${0.45 + 0.3 * b})`; ctx.lineWidth = 1.6; ctx.beginPath(); ctx.arc(cx, by, R, Math.PI, TAU); ctx.stroke();
  const r = rng(8);
  for (let i = 0; i < 40; i++){
    const x = cx + (r() - 0.5) * R * 1.2, y = by - wrap(r() + p * (1 + (r() * 2 | 0)), 1) * R;
    ctx.fillStyle = `rgba(255,200,120,${0.25 + r() * 0.5})`; ctx.beginPath(); ctx.arc(x, y, 0.6 + r(), 0, TAU); ctx.fill();
  }
  const fl = 1 + 0.06 * Math.sin(TAU * t * 1.7) + 0.04 * Math.sin(TAU * t * 2.9), fh = R * 0.42 * fl * (0.92 + 0.12 * b), fw = R * 0.12;
  glow(ctx, cx, by - fh * 0.55, fh * 1.1, [[0, 'rgba(255,220,140,.75)'], [1, 'rgba(255,140,40,0)']]);
  ctx.globalCompositeOperation = 'source-over';
  const fg = ctx.createLinearGradient(0, by - fh - 10, 0, by - 6);
  fg.addColorStop(0, '#FFF6D8'); fg.addColorStop(0.5, '#FFC860'); fg.addColorStop(1, '#E8652A');
  const tip = cx + Math.sin(TAU * t * 1.3) * 2;
  ctx.fillStyle = fg; ctx.beginPath(); ctx.moveTo(tip, by - fh - 8);
  ctx.bezierCurveTo(cx + fw * 1.3, by - fh * 0.45, cx + fw, by - 6, cx, by - 6);
  ctx.bezierCurveTo(cx - fw, by - 6, cx - fw * 1.3, by - fh * 0.45, tip, by - fh - 8); ctx.fill();
  ctx.fillStyle = '#9C5A1E'; ctx.beginPath(); ctx.ellipse(cx, by, R * 0.36, R * 0.11, 0, 0, Math.PI); ctx.fill();
  ctx.fillStyle = '#D99A3E'; ctx.beginPath(); ctx.ellipse(cx, by, R * 0.36, R * 0.05, 0, 0, TAU); ctx.fill();
}

const SCENES = { globe, ikonkar, jot };
const play = /[?&]play\b/.test(location.search) && !matchMedia('(prefers-reduced-motion: reduce)').matches;
const all = [...document.querySelectorAll('[data-scene]')].map(el => {
  const cv = document.createElement('canvas');
  cv.style.cssText = 'position:absolute;inset:0;width:100%;height:100%;display:block';
  el.prepend(cv);
  return { el, cv, ctx: cv.getContext('2d'), draw: SCENES[el.dataset.scene], o: JSON.parse(el.dataset.o || '{}') };
});
const frame = t => all.forEach(s => {
  const w = s.el.clientWidth, h = s.el.clientHeight;
  if (s.cv.width !== w * 2){ s.cv.width = w * 2; s.cv.height = h * 2; }
  s.ctx.setTransform(2, 0, 0, 2, 0, 0); s.draw(s.ctx, w, h, t, s.o);
});
const t0 = performance.now();
const tick = now => { frame(wrap((now - t0) / 1000 + 8, LOOP)); if (play) requestAnimationFrame(tick); };
(document.fonts ? document.fonts.ready : Promise.resolve()).then(() => requestAnimationFrame(tick));
frame(8);
})();
