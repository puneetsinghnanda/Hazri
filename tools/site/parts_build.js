/* ---------- Building each screen and its moment ---------- */
const BUILD = {
  today(s, root) {
    img('img/today-base.webp', root).className = 'base';
    const L = addLayers(s, root, null, NAV_TOP);
    const [ring] = addRings(s.rings, root);
    const streak = addCounter(s.counters[0], root);
    const tl = gsap.timeline({ paused: true });
    rise(tl, L.hazri, .25, 0, -18);
    pop(tl, [0, 1, 2, 3, 4, 5, 6].map(i => L['dot' + i]), .7, .11);
    countTo(tl, streak, 12, .7, 1.1);
    ringFill(tl, ring, 1.3);
    rise(tl, L.vichar, 1.9, 0, 30);
    return tl;
  },
  reader(s, root) {
    img('img/reader-base.webp', root).className = 'base';
    const textTop = 84, playerTop = s.bar.y - 50;
    const band = el('div', 'band', root, { left: '14px', width: '362px', background: s.hl });
    const clip = el('div', 'clip', root, { left: 0, top: textTop + 'px', width: '390px', height: (playerTop - textTop) + 'px' });
    const L = s.layers[0];
    img('img/reader-lines.webp', clip, { cx: L.cx, cy: L.cy - textTop, cw: L.cw, ch: L.ch });
    const barBg = el('div', '', root, { position: 'absolute', left: s.bar.x + 'px', top: s.bar.y + 'px', height: '4px', borderRadius: '2px', background: s.bar.color, width: (s.bar.w * s.bar.from) + 'px' });
    const knob = el('div', '', root, { position: 'absolute', top: (s.bar.y - 5) + 'px', width: '14px', height: '14px', marginLeft: '-7px', borderRadius: '7px', background: s.bar.color, left: (s.bar.x + s.bar.w * s.bar.from) + 'px' });
    const time = addCounter(s.counters[0], root);
    const lines = s.lines;
    const at = i => ({ top: lines[i].y + 'px', height: lines[i].h + 'px' });
    const tl = gsap.timeline({ paused: true });
    tl.set(band, { ...at(2), autoAlpha: 0 }, 0);
    tl.to(band, { autoAlpha: 1, duration: .3 }, .2);
    [3, 4, 5, 6].forEach((i, n) => tl.to(band, { ...at(i), duration: .55, ease: 'power2.inOut' }, .9 + n * 1.15));
    const sec = { v: 108 }, end = 108 + 34;
    tl.fromTo(sec, { v: 108 }, { v: end, duration: 5.2, ease: 'none', onUpdate() {
      const v = Math.round(sec.v); time.textContent = `${Math.floor(v / 60)}:${String(v % 60).padStart(2, '0')} / 19:04`;
      const f = v / (19 * 60 + 4); barBg.style.width = (s.bar.w * f) + 'px'; knob.style.left = (s.bar.x + s.bar.w * f) + 'px';
    } }, 0);
    return tl;
  },
  simran(s, root) {
    img('img/simran-base.webp', root).className = 'base';
    const cv = el('canvas', 'globe', root);
    cv.width = 390 * 2; cv.height = 844 * 2;
    globe.canvas = cv;
    const live = addCounter(s.counters[0], root);
    const tl = gsap.timeline({ paused: true, onStart: () => { globe.active = true } });
    tl.fromTo(globe, { dots: 0, threads: 0 }, { dots: 1, duration: 1.4, ease: 'power1.out' }, .1);
    tl.to(globe, { threads: 1, duration: 1.6, ease: 'power2.inOut' }, 1.1);
    countTo(tl, live, 48, .3, 1.6);
    return tl;
  },
  sangat(s, root) {
    img('img/sangat-base.webp', root).className = 'base';
    const L = addLayers(s, root);
    const rings = addRings(s.rings, root);
    const tl = gsap.timeline({ paused: true });
    const cards = [0, 1, 2, 3].map(i => L['group' + i]);
    tl.set(rings.map(r => r.el), { autoAlpha: 0 }, 0);
    rise(tl, cards, .2, .14, 18);
    rings.forEach((r, i) => { tl.set(r.el, { autoAlpha: 1 }, .45 + i * .14); ringFill(tl, r, .45 + i * .14, 1.1); });
    tl.fromTo([0, 1, 2].map(i => L['join' + i]), { autoAlpha: 0, x: 40 }, { autoAlpha: 1, x: 0, duration: .55, ease: 'power3.out', stagger: .12 }, 1.5);
    return tl;
  },
  group(s, root) {
    img('img/group-base.webp', root).className = 'base';
    const L = addLayers(s, root);
    const [ring] = addRings(s.rings, root);
    const mins = addCounter(s.counters[0], root), pct = addCounter(s.counters[1], root);
    const sit = s.layers.find(l => l.name === 'sit');
    const ripple = el('div', 'ripple', root, { left: (sit.x + sit.w / 2 - 30) + 'px', top: (sit.y + sit.h / 2 - 30) + 'px', width: '60px', height: '60px' });
    const tl = gsap.timeline({ paused: true });
    ringFill(tl, ring, .3, 1.8);
    countTo(tl, mins, 212480, .3, 1.8);
    countTo(tl, pct, 42, .3, 1.8, v => Math.round(v) + '%');
    rise(tl, [0, 1, 2].map(i => L['stat' + i]), 1.1, .1);
    rise(tl, L.sit, 1.5);
    tl.to(L.sit, { scale: .97, duration: .14, yoyo: true, repeat: 1, ease: 'power1.inOut' }, 3.0);
    tl.fromTo(ripple, { autoAlpha: .9, scale: .3 }, { autoAlpha: 0, scale: 3.2, duration: .9, ease: 'power2.out' }, 3.0);
    return tl;
  },
  diary(s, root) {
    img('img/diary-base.webp', root).className = 'base';
    const L = addLayers(s, root);
    const now = addCounter(s.counters[0], root), longest = addCounter(s.counters[1], root);
    const tl = gsap.timeline({ paused: true });
    countTo(tl, longest, 30, .2, 1.2);
    pop(tl, [0, 1, 2, 3, 4, 5, 6].map(i => L['day' + i]), .5, .16);
    countTo(tl, now, 12, .5, 1.6);
    return tl;
  },
  badge(s, root) {
    // Behind the sheet is Today, finished.
    const t = byId.today;
    img('img/today-base.webp', root).className = 'base';
    addLayers(t, root, 'today', NAV_TOP);
    addRings(t.rings, root);
    addCounter(t.counters[0], root);
    const scrim = el('div', 'scrim', root);
    const sheetL = s.layers.find(l => l.name === 'sheet');
    const sheet = el('div', '', root, { position: 'absolute', left: 0, top: 0, width: '390px', height: '844px' });
    img('img/badge-sheet.webp', sheet, sheetL);
    const parts = {};
    s.layers.filter(l => l.name !== 'sheet').forEach(l => parts[l.name] = img(`img/badge-${l.name}.webp`, sheet, l));
    const tl = gsap.timeline({ paused: true });
    tl.fromTo(scrim, { autoAlpha: 0 }, { autoAlpha: 1, duration: .5 }, .3);
    tl.fromTo(sheet, { y: 844 - sheetL.y }, { y: 0, duration: .7, ease: 'power3.out' }, .45);
    tl.fromTo(parts.medal, { autoAlpha: 0, scale: .2, rotation: -120 }, { autoAlpha: 1, scale: 1, rotation: 0, duration: .9, ease: 'back.out(1.8)' }, 1.0);
    pop(tl, [0, 1, 2, 3].map(i => parts['earned' + i]), 1.5, .12);
    tl.to(parts.earned3, { scale: 1.25, duration: .25, yoyo: true, repeat: 1, ease: 'power1.inOut' }, 2.3);
    return tl;
  },
};

