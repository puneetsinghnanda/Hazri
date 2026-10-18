function el(tag, cls, parent, style) {
  const e = document.createElement(tag);
  if (cls) e.className = cls;
  if (style) Object.assign(e.style, style);
  if (parent) parent.appendChild(e);
  return e;
}
function img(src, parent, l) {
  const i = el('img', '', parent, l ? { left: l.cx + 'px', top: l.cy + 'px', width: l.cw + 'px', height: l.ch + 'px' } : null);
  i.src = src; i.alt = ''; i.decoding = 'async'; i.draggable = false;
  return i;
}
function addLayers(s, parent, prefix, clipTo) {
  const out = {};
  const box = clipTo ? el('div', 'clip', parent, { left: 0, top: 0, width: '390px', height: clipTo + 'px' }) : parent;
  for (const l of s.layers) out[l.name] = img(`img/${prefix || s.id}-${l.name}.webp`, box, l);
  return out;
}
const NAV_TOP = 760;   // the bottom bar of a tab screen starts here
function addRings(rings, parent) {
  const svg = document.createElementNS(NS, 'svg');
  svg.setAttribute('class', 'rings'); svg.setAttribute('width', 390); svg.setAttribute('height', 844);
  parent.appendChild(svg);
  return rings.map(r => {
    const c = document.createElementNS(NS, 'circle');
    const len = 2 * Math.PI * r.r;
    Object.entries({ cx: r.cx, cy: r.cy, r: r.r, fill: 'none', stroke: r.color, 'stroke-width': r.sw, 'stroke-linecap': 'round',
      'stroke-dasharray': `${len} ${len}`, 'stroke-dashoffset': len * (1 - r.frac), transform: `rotate(-90 ${r.cx} ${r.cy})` })
      .forEach(([k, v]) => c.setAttribute(k, v));
    svg.appendChild(c);
    return { el: c, len, frac: r.frac, ring: r };
  });
}
function addCounter(c, parent, fmt) {
  const d = el('div', 'counter', parent, { top: c.y + 'px', fontFamily: c.font, fontSize: c.size + 'px', fontWeight: c.weight, color: c.color, lineHeight: c.lh });
  if (c.align === 'center') { d.style.left = (c.x + c.w / 2) + 'px'; d.style.transform = 'translateX(-50%)'; }
  else if (c.align === 'right') { d.style.right = (390 - c.x - c.w) + 'px'; }
  else d.style.left = c.x + 'px';
  d.textContent = c.text;
  return d;
}
const num = new Intl.NumberFormat('en-US');
function countTo(tl, node, to, at, dur, format) {
  const o = { v: 0 };
  tl.fromTo(o, { v: 0 }, { v: to, duration: dur, ease: 'power2.out', onUpdate: () => node.textContent = format ? format(o.v) : num.format(Math.round(o.v)) }, at);
}
function ringFill(tl, r, at, dur) {
  tl.fromTo(r.el, { attr: { 'stroke-dashoffset': r.len } }, { attr: { 'stroke-dashoffset': r.len * (1 - r.frac) }, duration: dur || 1.2, ease: 'power2.out' }, at);
}
const pop = (tl, els, at, stagger) => tl.fromTo(els, { autoAlpha: 0, scale: .6 }, { autoAlpha: 1, scale: 1, duration: .45, ease: 'back.out(2.2)', stagger: stagger || .1 }, at);
const rise = (tl, els, at, stagger, y) => tl.fromTo(els, { autoAlpha: 0, y: y || 22 }, { autoAlpha: 1, y: 0, duration: .55, ease: 'power3.out', stagger: stagger || .08 }, at);

/* ---------- The globe, drawn the way the app draws it ---------- */
const PEOPLE = [[31.63,74.87,'you'],[31.33,75.58,'here'],[30.90,75.85,'here'],[30.73,76.78,'live'],[31.52,74.36,'here'],[28.61,77.21,'here'],[28.46,77.03,'live'],[29.39,76.97,'here'],[32.73,74.86,'here'],[19.08,72.88,'here'],[12.97,77.59,'live'],[22.57,88.36,'here'],[26.85,80.95,'here'],[51.51,-0.38,'here'],[52.48,-1.90,'live'],[53.80,-1.55,'here'],[55.86,-4.25,'here'],[45.46,9.19,'here'],[52.37,4.90,'here'],[48.86,2.35,'live'],[50.11,8.68,'here'],[25.20,55.27,'here'],[24.47,54.37,'live'],[-1.29,36.82,'here'],[1.35,103.82,'here'],[13.76,100.50,'live'],[3.14,101.69,'here'],[-31.95,115.86,'here'],[-37.81,144.96,'live'],[-33.87,151.21,'here'],[35.68,139.69,'here'],[43.65,-79.38,'here'],[49.28,-123.12,'live'],[37.34,-121.89,'here'],[40.71,-74.01,'here'],[34.05,-118.24,'here'],[41.88,-87.63,'live']];
const DOT = { you: '#F2A24E', live: '#3DBE7B', here: '#5B8DEF' };
const globe = { lon: 52, t0: 0, threads: 1, dots: 1, blink: 0, active: false, canvas: null };
function drawGlobe() {
  const g = byId.simran.globe, cv = globe.canvas, ctx = cv.getContext('2d');
  const dpr = cv.width / 390;
  ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
  ctx.clearRect(0, 0, 390, 844);
  const R = g.r, CX = g.cx, CY = g.cy, k = R / 150;
  const p0 = 22 * Math.PI / 180, sp0 = Math.sin(p0), cp0 = Math.cos(p0), L0 = globe.lon;
  const proj = (lat, lon) => {
    const p = lat * Math.PI / 180, l = (lon - L0) * Math.PI / 180;
    const sp = Math.sin(p), cp = Math.cos(p), cl = Math.cos(l);
    if (sp0 * sp + cp0 * cp * cl <= 0.02) return null;
    return [CX + R * cp * Math.sin(l), CY - R * (cp0 * sp - sp0 * cp * cl)];
  };
  // Glow and sea
  let grd = ctx.createRadialGradient(CX, CY, 0, CX, CY, 200 * k);
  grd.addColorStop(.72, 'rgba(111,195,211,.22)'); grd.addColorStop(1, 'rgba(111,195,211,0)');
  ctx.fillStyle = grd; ctx.beginPath(); ctx.arc(CX, CY, 200 * k, 0, 7); ctx.fill();
  grd = ctx.createRadialGradient(CX, CY, 0, CX, CY, R);
  grd.addColorStop(0, '#071232'); grd.addColorStop(.72, '#071232'); grd.addColorStop(1, '#0A1F52');
  ctx.fillStyle = grd; ctx.beginPath(); ctx.arc(CX, CY, R, 0, 7); ctx.fill();
  const runs = (pts) => {
    let open = false;
    for (const p of pts) {
      if (!p) { open = false; continue; }
      if (!open) { ctx.moveTo(p[0], p[1]); open = true; } else ctx.lineTo(p[0], p[1]);
    }
  };
  // Graticule
  ctx.beginPath();
  for (let lon = -180; lon < 180; lon += 30) { const pts = []; for (let lat = -90; lat <= 90; lat += 3) pts.push(proj(lat, lon)); runs(pts); }
  for (let lat = -60; lat <= 60; lat += 30) { const pts = []; for (let lon = -180; lon <= 180; lon += 3) pts.push(proj(lat, lon)); runs(pts); }
  ctx.strokeStyle = 'rgba(47,78,150,.6)'; ctx.lineWidth = .7 * k; ctx.stroke();
  // Coasts
  ctx.beginPath();
  for (const ring of WORLD) runs(ring.map(([lon, lat]) => proj(lat, lon)));
  ctx.strokeStyle = 'rgba(143,212,255,.8)'; ctx.lineWidth = .9 * k; ctx.lineJoin = 'round'; ctx.stroke();
  // Threads from your dot, drawn out as the scene opens
  const pts = PEOPLE.map(([lat, lon, kind]) => ({ p: proj(lat, lon), kind }));
  const me = pts[0].p;
  if (me && globe.threads > 0) {
    ctx.beginPath();
    for (const q of pts.slice(1)) {
      if (!q.p) continue;
      const [x2, y2] = q.p, [x1, y1] = me;
      const mx = (x1 + x2) / 2, my = (y1 + y2) / 2, dx = x2 - x1, dy = y2 - y1;
      const cx = mx - dy * .14, cy = my + dx * .14, t = globe.threads;
      ctx.moveTo(x1, y1);
      for (let i = 1; i <= 24; i++) {
        const u = t * i / 24, a = (1 - u) * (1 - u), b = 2 * (1 - u) * u, c = u * u;
        ctx.lineTo(a * x1 + b * cx + c * x2, a * y1 + b * cy + c * y2);
      }
    }
    ctx.strokeStyle = 'rgba(242,162,78,.32)'; ctx.lineWidth = .7 * k; ctx.stroke();
  }
  // Rim
  ctx.beginPath(); ctx.arc(CX, CY, 149.5 * k, 0, 7); ctx.strokeStyle = 'rgba(127,196,255,.85)'; ctx.lineWidth = 2 * k; ctx.stroke();
  // Dots
  pts.forEach((q, i) => {
    if (!q.p) return;
    const show = Math.min(1, Math.max(0, globe.dots * PEOPLE.length - i * .6));
    if (show <= 0) return;
    const [x, y] = q.p;
    ctx.globalAlpha = show;
    if (q.kind === 'you') {
      const b = .55 + .45 * Math.sin(globe.blink);
      ctx.fillStyle = `rgba(111,195,211,${.18 * b})`; ctx.beginPath(); ctx.arc(x, y, 12 * k, 0, 7); ctx.fill();
      ctx.fillStyle = `rgba(111,195,211,${.28 * b})`; ctx.beginPath(); ctx.arc(x, y, 7.5 * k, 0, 7); ctx.fill();
      ctx.fillStyle = DOT.you; ctx.beginPath(); ctx.arc(x, y, 4.6 * k, 0, 7); ctx.fill();
    } else {
      const r = (q.kind === 'live' ? 3.4 : 2.8) * k;
      ctx.fillStyle = DOT[q.kind]; ctx.globalAlpha = show * .22; ctx.beginPath(); ctx.arc(x, y, r * 2.2, 0, 7); ctx.fill();
      ctx.globalAlpha = show; ctx.beginPath(); ctx.arc(x, y, r, 0, 7); ctx.fill();
    }
  });
  ctx.globalAlpha = 1;
}
// The globe turns from where the app centres it (India, the UK and Africa in
// view), a little each second it is on screen, so your dot never leaves.
function globeAt(t) {
  if (!reduce) { globe.lon = 52 - (t - globe.t0) * 4; globe.blink = t * 3.2; }
  drawGlobe();
}
function spin() {
  if (globe.active && !globe.rec) globeAt(gsap.globalTimeline.time());
  requestAnimationFrame(spin);
}

