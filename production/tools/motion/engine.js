// Claude Motion house engine for Last Light Academy science explainers (M1-63).
// One frame = a pure function of time t (Tweenkit's contract: window.ready + renderAt(t)), so any frame can be
// rendered alone and in any order. build.py inlines this file, the clip's scene file and the resolved spec.
// Globals in: SPEC (resolved spec), D (series from fixtures), STYLE (palette and fonts). Scenes in: SCENES[name](g, u, b).
(() => {
  const W = 1920, H = 1080, C = STYLE.colour;
  const cv = document.getElementById('c'); cv.width = W; cv.height = H;
  const g = cv.getContext('2d');

  // ---- timing ----
  const clamp = (v, a = 0, b = 1) => Math.min(b, Math.max(a, v));
  const lerp = (a, b, k) => a + (b - a) * k;
  const seg = (u, a, b) => clamp((u - a) / (b - a));                  // linear 0..1 between a and b
  const E = k => (k < .5 ? 4 * k * k * k : 1 - Math.pow(-2 * k + 2, 3) / 2); // ease in-out
  const ex = k => (k >= 1 ? 1 : 1 - Math.pow(2, -10 * k));             // ease out, quick settle
  const es = (u, a, b) => E(seg(u, a, b));
  const spr = k => (k <= 0 ? 0 : k >= 1 ? 1 : 1 - Math.exp(-6 * k) * Math.cos(9 * k)); // springy pop-in, overshoots ~12%
  const pop = (u, a, b) => spr(seg(u, a, b));
  function rng(seed) { let s = seed >>> 0; return () => ((s = (s * 1664525 + 1013904223) >>> 0) / 4294967296); }

  // ---- drawing kit ----
  const FONT = STYLE.font, MONO = STYLE.mono;
  function rgba(hex, a = 1) {
    const n = parseInt(hex.slice(1, 7), 16);
    const base = hex.length > 7 ? parseInt(hex.slice(7, 9), 16) / 255 : 1;
    return `rgba(${n >> 16},${(n >> 8) & 255},${n & 255},${a * base})`;
  }
  function text(str, x, y, o = {}) {
    g.save();
    g.globalAlpha *= o.alpha ?? 1;
    g.font = `${o.weight || 500} ${o.size || 40}px ${o.mono ? MONO : FONT}`;
    g.fillStyle = o.color || C.ivory;
    g.textAlign = o.align || 'left'; g.textBaseline = o.base || 'alphabetic';
    if (o.spacing) g.letterSpacing = o.spacing + 'px';
    g.fillText(str, x, y);
    const w = g.measureText(str).width; g.restore(); return w;
  }
  function wrapRaw(str, maxW) {
    const out = []; let line = '';
    for (const w of str.split(' ')) {
      const t = line ? line + ' ' + w : w;
      if (g.measureText(t).width > maxW && line) { out.push(line); line = w; } else line = t;
    }
    if (line) out.push(line); return out;
  }
  function wrap(str, maxW, size, weight = 600) {   // balanced: lines of similar length, never one lonely word
    g.font = `${weight} ${size}px ${FONT}`;
    const n = wrapRaw(str, maxW).length;
    let w = maxW;
    while (n > 1 && w > 240 && wrapRaw(str, w - 24).length === n) w -= 24;
    return wrapRaw(str, w);
  }
  function poly(pts, p = 1, o = {}) {           // draw a polyline up to progress p (0..1 of its points)
    if (pts.length < 2 || p <= 0) return;
    const n = (pts.length - 1) * clamp(p), whole = Math.floor(n);
    g.save(); g.beginPath(); g.moveTo(pts[0][0], pts[0][1]);
    for (let i = 1; i <= whole; i++) g.lineTo(pts[i][0], pts[i][1]);
    if (whole < pts.length - 1) {
      const a = pts[whole], b = pts[whole + 1], f = n - whole;
      g.lineTo(lerp(a[0], b[0], f), lerp(a[1], b[1], f));
    }
    g.strokeStyle = o.color || C.ivory; g.lineWidth = o.width || 4; g.lineJoin = 'round'; g.lineCap = 'round';
    if (o.dash) g.setLineDash(o.dash);
    if (o.glow) { g.shadowColor = o.color; g.shadowBlur = o.glow; }
    g.globalAlpha *= o.alpha ?? 1; g.stroke(); g.restore();
  }
  function line(x1, y1, x2, y2, o = {}) { poly([[x1, y1], [x2, y2]], o.p ?? 1, o); }
  function arrow(x1, y1, x2, y2, o = {}) {
    const p = o.p ?? 1, x = lerp(x1, x2, p), y = lerp(y1, y2, p), a = Math.atan2(y2 - y1, x2 - x1), s = o.head || 18;
    line(x1, y1, x, y, o);
    if (p <= 0) return;
    g.save(); g.globalAlpha *= o.alpha ?? 1; g.fillStyle = o.color || C.ivory; g.beginPath();
    g.moveTo(x, y); g.lineTo(x - s * Math.cos(a - .45), y - s * Math.sin(a - .45));
    g.lineTo(x - s * Math.cos(a + .45), y - s * Math.sin(a + .45)); g.closePath(); g.fill(); g.restore();
  }
  function disc(x, y, r, color, o = {}) {
    g.save(); g.globalAlpha *= o.alpha ?? 1; g.beginPath(); g.arc(x, y, r, 0, Math.PI * 2);
    if (o.glow) { g.shadowColor = color; g.shadowBlur = o.glow; }
    g.fillStyle = color; g.fill(); g.restore();
  }
  function ring(x, y, r, color, o = {}) {
    g.save(); g.globalAlpha *= o.alpha ?? 1; g.beginPath(); g.arc(x, y, r, o.a0 ?? 0, o.a1 ?? Math.PI * 2);
    g.strokeStyle = color; g.lineWidth = o.width || 3; if (o.dash) g.setLineDash(o.dash); g.stroke(); g.restore();
  }
  function rrect(x, y, w, h, r, fill, edge) {
    g.beginPath(); g.roundRect(x, y, w, h, r);
    if (fill) { g.fillStyle = fill; g.fill(); }
    if (edge) { g.strokeStyle = edge; g.lineWidth = 2; g.stroke(); }
  }
  function panel(x, y, w, h, alpha = 1) {          // the game's glass panel (ui_design.json colour.glass / glass_edge)
    g.save(); g.globalAlpha *= alpha; rrect(x, y, w, h, 24, C.glass, C.glass_edge); g.restore();
  }

  // ---- house frame: background, honest-label chip, captions, progress ----
  const stars = (() => { const r = rng(7), s = []; for (let i = 0; i < 260; i++) s.push([r() * W, r() * H, r() * 1.6 + .3, r()]); return s; })();
  function background(t) {
    const grd = g.createLinearGradient(0, 0, 0, H);
    grd.addColorStop(0, C.ink); grd.addColorStop(1, '#0B1222');
    g.fillStyle = grd; g.fillRect(0, 0, W, H);
    for (const [x, y, r, k] of stars) disc(x, y, r, C.ivory, { alpha: .18 + .22 * (.5 + .5 * Math.sin(t * .6 + k * 9)) });
  }
  const LABELS = { measured: ['MEASURED', C.good], model: ['MODEL', C.amara], diagram: ['DIAGRAM', C.muted] };
  function chip(b, alpha) {
    if (!b.label) return;
    const [word, col] = LABELS[b.label];
    g.save(); g.globalAlpha *= alpha;
    g.font = `700 24px ${FONT}`; g.letterSpacing = '3px'; const w1 = g.measureText(word).width;
    g.font = `500 24px ${FONT}`; g.letterSpacing = '0px'; const w2 = b.credit ? g.measureText(b.credit).width + 28 : 0;
    rrect(64, 56, w1 + w2 + 64, 52, 26, C.glass, C.glass_edge);
    disc(92, 82, 7, col);
    text(word, 112, 91, { size: 24, weight: 700, color: col, spacing: 3 });
    if (b.credit) text(b.credit, 112 + w1 + 28, 91, { size: 24, weight: 500, color: C.muted });
    g.restore();
  }
  function captions(t) {
    for (const [a, b, str] of SPEC.captions) {
      if (t < a || t > b) continue;
      const k = Math.min(es(t, a, a + .25), 1 - es(t, b - .25, b));   // fades stay inside the caption's own time, so two never overlap
      const lines = wrap(str, 1480, 46);
      const h = lines.length * 62 + 44, y = H - 72 - h;
      g.save(); g.globalAlpha = k;
      const wMax = Math.max(...lines.map(l => { g.font = `600 46px ${FONT}`; return g.measureText(l).width; }));
      rrect(W / 2 - wMax / 2 - 44, y, wMax + 88, h, 22, C.scrim, null);
      lines.forEach((l, i) => text(l, W / 2, y + 66 + i * 62 + (1 - ex(seg(t, a, a + .4))) * 10, { size: 46, weight: 600, align: 'center' }));
      g.restore();
    }
  }
  function progress(t) {
    g.fillStyle = rgba(C.ivory, .08); g.fillRect(0, H - 6, W, 6);
    g.fillStyle = rgba(C.accent, .55); g.fillRect(0, H - 6, W * t / SPEC.length_s, 6);
  }

  const XF = .6; // crossfade between beats, seconds
  function drawBeat(b, t, alpha) {
    if (alpha <= 0) return;
    g.save(); g.globalAlpha = alpha;
    SCENES[b.scene](g, t - b.from, b, t);
    g.restore();
    chip(b, alpha);
  }
  window.renderAt = t => {
    g.setTransform(1, 0, 0, 1, 0, 0); g.globalAlpha = 1;
    background(t);
    const beats = SPEC.beats;
    for (let i = 0; i < beats.length; i++) {
      const b = beats[i];
      if (t < b.from - XF / 2 || t >= b.to + XF / 2) continue;
      const fadeIn = i === 0 ? 1 : es(t, b.from - XF / 2, b.from + XF / 2);
      const fadeOut = i === beats.length - 1 ? 1 - es(t, b.to - .5, b.to) : 1 - es(t, b.to - XF / 2, b.to + XF / 2);
      drawBeat(b, t, Math.min(fadeIn, fadeOut));
    }
    captions(t); progress(t);
  };
  window.K = { W, H, C, g, clamp, lerp, seg, E, ex, es, spr, pop, rng, rgba, text, wrap, poly, line, arrow, disc, ring, rrect, panel };

  // Shared opening and closing beats; a clip's scene file adds its own with Object.assign(SCENES, {...}).
  window.SCENES = {
    title(g, u) {
      const k = ex(seg(u, .1, 1.1));
      text('SCIENCE EXPLAINER', W / 2, 430, { size: 28, weight: 700, color: C.accent, align: 'center', spacing: 8, alpha: k });
      const lines = wrap(SPEC.title, 1640, 88, 700);
      lines.forEach((l, i) => text(l, W / 2, 540 + i * 104 + (1 - k) * 24, { size: 88, weight: 700, align: 'center', alpha: k }));
      line(W / 2 - 220, 596 + (lines.length - 1) * 104, W / 2 + 220, 596 + (lines.length - 1) * 104, { color: C.accent, width: 4, p: es(u, .5, 1.6) });
    },
    card(g, u, b) {   // a short statement card (where the data stops); fields: card, sub
      const k = pop(u, .1, 1.0);
      g.save(); g.translate(W / 2, 440); g.scale(k, k); g.translate(-W / 2, -440);
      panel(W / 2 - 540, 320, 1080, 250);
      wrap(b.card, 960, 44, 700).forEach((l, i) => text(l, W / 2, 420 + i * 54, { size: 44, weight: 700, align: 'center', color: C.accent }));
      wrap(b.sub || '', 960, 30, 600).forEach((l, i) => text(l, W / 2, 500 + i * 38, { size: 30, weight: 600, align: 'center', alpha: ex(seg(u, .6, 1.4)) * Math.min(1, k) }));
      g.restore();
    },
    takeaway(g, u, b) {
      const k = ex(seg(u, .1, 1));
      const lines = wrap(b.text || SPEC.ends_on, 1240, 60, 600), h = lines.length * 80 + 170, y = 430 - h / 2;
      panel(W / 2 - 700, y + (1 - k) * 30, 1400, h, k);
      text('WHAT IT MEANS FOR YOU', W / 2, y + 86, { size: 28, weight: 700, color: C.accent, align: 'center', spacing: 6, alpha: k });
      lines.forEach((l, i) => text(l, W / 2, y + 170 + i * 80, { size: 60, weight: 600, align: 'center', alpha: ex(seg(u, .4 + i * .25, 1.4 + i * .25)) }));
    },
  };
  // Optional images (spec "images": real NASA renders such as a LOLA hillshade), preloaded before the first frame.
  // A missing file rejects, which Playwright reports as a page error, so the render fails instead of drawing blanks.
  window.IMG = {};
  const loads = Object.entries(SPEC.images || {}).map(([k, src]) => new Promise((ok, bad) => {
    const im = new Image(); im.onload = () => { IMG[k] = im; ok(); }; im.onerror = () => bad(new Error('image ' + k + ' did not load: ' + src)); im.src = src;
  }));
  window.addEventListener('load', () => { Promise.all(loads).then(() => { window.ready = { W, H, FPS: SPEC.fps, duration: SPEC.length_s }; }); });
})();
