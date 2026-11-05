// Scenes for sci_polar_sun (spec: ../specs/sci_polar_sun.json). Every on-screen word comes from the beat's fields;
// data numbers come from SPEC.v (formatted) or D (fixture series). Axis tick values are the only literals.
// Timings inside a scene are beat seconds (u) and follow the spec's captions.
Object.assign(SCENES, {
  // The Moon spins almost upright, like a top; sunlight arrives from the side and grazes the south pole.
  spin(g, u, b) {
    const { C, text, disc, ring, line, es, ex, seg, pop, rgba, lerp } = K;
    const mx = 960, my = 450, r = 250, tilt = 3 * Math.PI / 180;         // tilt exaggerated: "Not to scale"
    // Sun glow far left and horizontal rays marching in
    const sg = g.createRadialGradient(-140, my, 20, -140, my, 520);
    sg.addColorStop(0, rgba(C.accent, .95)); sg.addColorStop(.25, rgba(C.accent, .35)); sg.addColorStop(1, rgba(C.accent, 0));
    g.fillStyle = sg; g.fillRect(0, 0, 700, 1080);
    for (let i = 0; i < 7; i++) {
      const y = my - r + 30 + i * ((2 * r - 60) / 6), p = es(u, .2 + i * .08, 1.4 + i * .08);
      const x0 = 150, x1 = mx - Math.sqrt(Math.max(0, r * r - (y - my) ** 2)) - 14;
      g.save(); g.setLineDash([26, 18]); g.lineDashOffset = -u * 90;
      line(x0, y, x0 + (x1 - x0) * p, y, { color: rgba(C.accent, .8), width: 3 }); g.restore();
    }
    text(b.light, 190, my - r - 10, { size: 32, weight: 600, color: C.accent, alpha: ex(seg(u, .6, 1.6)) });
    // Moon: lit from the left, longitude lines sweeping round = the spin
    const mg = g.createRadialGradient(mx - r * .55, my - r * .1, r * .1, mx, my, r * 1.05);
    mg.addColorStop(0, '#B9B5B0'); mg.addColorStop(.55, C.regolith); mg.addColorStop(1, '#2A2927');
    disc(mx, my, r, mg);
    g.save(); g.beginPath(); g.arc(mx, my, r, 0, Math.PI * 2); g.clip();
    g.translate(mx, my); g.rotate(tilt);
    for (let i = 0; i < 6; i++) {
      const ph = ((u * .25 + i / 6) % 1) * Math.PI;
      g.beginPath(); g.ellipse(0, 0, Math.abs(Math.cos(ph)) * r, r, 0, 0, Math.PI * 2);
      g.strokeStyle = rgba(C.ivory, .12); g.lineWidth = 2; g.stroke();
    }
    g.restore();
    // spin axis, almost straight up, with a spin arrow at the top
    const ap = es(u, .8, 2.0), dx = Math.sin(tilt) * (r + 120), dy = Math.cos(tilt) * (r + 120);
    line(mx - dx * ap, my - dy * ap, mx + dx * ap, my + dy * ap, { color: C.ivory, width: 3, dash: [10, 10] });
    ring(mx - dx * .92, my - dy * .92, 46, C.ivory, { a0: Math.PI * .15, a1: Math.PI * (.15 + 1.4 * ap), width: 3 });
    text(b.axis, mx + 70, my - r - 70, { size: 32, weight: 600, alpha: ex(seg(u, 1.6, 2.6)) });
    // a spinning top beside it (caption 1), then it bows out
    const tk = pop(u, .6, 1.6) * (1 - es(u, 4.2, 4.8));
    if (tk > 0) {
      const tx = 1500, ty = 470, s = 1.6 * tk, wob = Math.sin(u * 2.2) * .05;
      g.save(); g.translate(tx, ty + 120); g.rotate(wob); g.scale(s, s); g.translate(0, -120);
      g.beginPath(); g.moveTo(-70, 0); g.quadraticCurveTo(0, -36, 70, 0); g.lineTo(0, 110); g.closePath();
      g.fillStyle = C.signal; g.fill();
      g.save(); g.clip();
      for (let i = -3; i < 6; i++) { const x = ((i * 30 + u * 160) % 270) - 135; g.fillStyle = rgba(C.ivory, .28); g.fillRect(x, -40, 12, 160); }
      g.restore();
      g.fillStyle = C.ivory; g.fillRect(-5, -64, 10, 50);
      g.restore();
      text(b.top, tx, ty + 210, { size: 32, weight: 600, align: 'center', alpha: tk });
    }
    // caption 2: the grazing ray finds the south pole
    const gp = es(u, 4.5, 5.6), pk = pop(u, 5.4, 6.3);
    line(150, my + r - 2, lerp(150, mx, gp), my + r - 2, { color: C.accent, width: 6, glow: 22 });
    disc(mx, my + r, 14 * pk, C.accent, { glow: 26 });
    ring(mx, my + r, 14 + 40 * seg(u, 5.4, 6.6), C.accent, { width: 3, alpha: 1 - seg(u, 5.4, 6.6) });
    text(b.pole, mx + 34, my + r + 46, { size: 32, weight: 600, color: C.accent, alpha: ex(seg(u, 5.4, 6.2)) });
    // caption 3: seen from the pole, the Sun rolls around the edge of the sky
    const ik = pop(u, 8.5, 9.4), ix = 1560, iy = 360, ir = 150;
    if (ik > 0) {
      g.save(); g.translate(ix, iy); g.scale(ik, ik); g.translate(-ix, -iy);
      K.panel(ix - 220, iy - 210, 440, 480);
      ring(ix, iy, ir, C.muted, { width: 3, dash: [8, 8] });
      disc(ix, iy, 9, C.ivory);
      const a = -Math.PI / 2 + (u - 8.5) * 1.1;
      disc(ix + Math.cos(a) * ir, iy + Math.sin(a) * ir, 22, C.accent, { glow: 30 });
      K.wrap(b.circle, 380, 28, 600).forEach((l, i) => text(l, ix, iy + ir + 60 + i * 36, { size: 28, weight: 600, align: 'center' }));
      g.restore();
    }
  },

  // Two years of the Sun's height at the pole, from JPL Horizons, drawn day by day.
  season(g, u, b) {
    const { C, text, line, poly, disc, es, ex, seg, pop, rgba, lerp } = K;
    const x0 = 300, x1 = 1560, yTop = 200, yBot = 750, lo = -2, hi = 2;
    const Y = v => lerp(yBot, yTop, (v - lo) / (hi - lo));
    const rows = D.elevation, n = rows.length, X = i => lerp(x0, x1, i / (n - 1));
    const ak = ex(seg(u, 0, .8));
    g.save(); g.globalAlpha *= ak;
    g.fillStyle = rgba(C.navy, .55); g.fillRect(x0, Y(0), x1 - x0, yBot - Y(0));        // below the horizon
    for (let v = lo; v <= hi; v++) {
      if (v) line(x0, Y(v), x1, Y(v), { color: rgba(C.ivory, .1), width: 2 });
      text((v > 0 ? '+' : v < 0 ? '−' : '') + Math.abs(v) + '°', x0 - 24, Y(v) + 11, { size: 28, color: C.muted, align: 'right', mono: true });
    }
    text(b.y_title, x0, yTop - 40, { size: 30, weight: 600, color: C.muted });
    rows.forEach((r, i) => {                                                               // January and July, from the fixture dates
      if (/-0[17]-01$/.test(r[0])) {
        const d = new Date(r[0] + 'T00:00Z');
        text(d.toLocaleString('en-GB', { month: 'short', timeZone: 'UTC' }) + ' ' + r[0].slice(0, 4), X(i), yBot + 44, { size: 26, color: C.muted, align: 'center' });
        line(X(i), yBot, X(i), yBot + 12, { color: C.muted, width: 2 });
      }
    });
    g.restore();
    line(x0, Y(0), x1, Y(0), { color: C.ivory, width: 3, p: es(u, .2, 1.0) });
    text(b.horizon, x1 + 18, Y(0) + 10, { size: 28, weight: 600, alpha: ex(seg(u, .8, 1.4)) });
    // the curve, with a little Sun riding its head
    const p = es(u, .6, 4.6), pts = rows.map((r, i) => [X(i), Y(r[1])]);
    poly(pts, p, { color: C.accent, width: 5, glow: 14 });
    const k = (n - 1) * p, i0 = Math.floor(k), f = k - i0, a = pts[i0], c = pts[Math.min(n - 1, i0 + 1)];
    if (p > 0 && p < 1) disc(lerp(a[0], c[0], f), lerp(a[1], c[1], f), 16, C.accent, { glow: 30 });
    // caption 2: highest and lowest, labelled from the fixture
    const iHi = rows.reduce((m, r, i) => (r[1] > rows[m][1] ? i : m), 0);
    const iLo = rows.slice(0, 365).reduce((m, r, i) => (r[1] < rows[m][1] ? i : m), 0);
    for (const [i, label, high, t0] of [[iHi, b.high, true, 5.0], [iLo, b.low, false, 5.5]]) {
      const mk = pop(u, t0, t0 + .9);
      if (mk <= 0) continue;
      disc(X(i), Y(rows[i][1]), 11 * mk, C.ivory);
      if (high) text(label, Math.min(X(i), x1 - 250), Y(rows[i][1]) - 30, { size: 30, weight: 700, align: 'center', alpha: Math.min(1, mk) });
      else text(label, X(i) + 30, Y(rows[i][1]) + 10, { size: 30, weight: 700, alpha: Math.min(1, mk) });   // beside the dip, clear of the axis
    }
    // caption 3: a thumb held at arm's length, drawn to the same scale (about two degrees wide)
    const tk = pop(u, 8.8, 9.8);
    if (tk > 0) {
      const tx = 1800, w = 74, top = Y(2), bot = Y(0);
      g.save(); g.translate(tx, bot); g.scale(1, tk); g.translate(-tx, -bot);
      K.rrect(tx - w / 2, top, w, bot - top + 60, 37, rgba(C.ivory, .9), null);              // the thumb
      K.rrect(tx - w / 2 + 14, top + 12, w - 28, 46, 18, rgba(C.navy, .25), null);           // its nail
      g.restore();
      line(tx - 70, Y(2), tx - 70, Y(0), { color: C.accent, width: 3, alpha: Math.min(1, tk) });
      K.wrap(b.thumb, 230, 26, 600).forEach((l, i) => text(l, tx, top - 70 + i * 32, { size: 26, weight: 600, align: 'center', alpha: Math.min(1, tk) }));
    }
  },

  // A tall crater rim catches the low Sun while the floor stays in shadow (LRO LOLA illumination study).
  rim(g, u, b) {
    const { C, text, line, poly, disc, es, ex, seg, pop, rgba, lerp } = K;
    const prof = [[0, 640], [300, 600], [560, 470], [760, 330], [820, 322], [900, 360], [1060, 610], [1200, 720], [1340, 720],
      [1480, 610], [1640, 470], [1760, 452], [1920, 470]];
    const ground = () => { g.beginPath(); g.moveTo(0, 1080); prof.forEach(([x, y]) => g.lineTo(x, y)); g.lineTo(1920, 1080); g.closePath(); };
    const sunY = 300, k0 = es(u, 0, 1.0), slope = .026;
    g.save(); g.globalAlpha *= k0;
    ground();
    const tg = g.createLinearGradient(0, 300, 0, 900); tg.addColorStop(0, C.regolith); tg.addColorStop(1, '#1A1A1A');
    g.fillStyle = tg; g.fill();
    g.save(); ground(); g.clip();                                                         // the rim's shadow over the bowl
    g.beginPath(); g.moveTo(820, 322); g.lineTo(1920, 322 + 1100 * slope); g.lineTo(1920, 1080); g.lineTo(900, 1080); g.closePath();
    g.fillStyle = rgba(C.space, .7); g.fill(); g.restore();
    g.restore();
    disc(40, sunY, 70, C.accent, { glow: 80, alpha: k0 });
    for (let i = 0; i < 6; i++) {
      const y = sunY - 50 + i * 16, p = es(u, .4 + i * .07, 1.6 + i * .07);
      line(110, y, lerp(110, 800, p), y + (800 - 110) * slope * p, { color: rgba(C.accent, .7), width: 3 });
    }
    text(b.ray, 140, sunY - 80, { size: 30, weight: 600, color: C.accent, alpha: ex(seg(u, .9, 1.7)) });
    const gk = ex(seg(u, 1.6, 2.6)) * (.85 + .15 * Math.sin(u * 3));
    poly([[700, 370], [760, 330], [820, 322], [870, 340]], 1, { color: C.accent, width: 9, glow: 34, alpha: gk });
    const lk = pop(u, 2.2, 3.1);
    line(790, 312, 790, 312 - 110 * Math.min(1, lk), { color: C.ivory, width: 2 });
    text(b.rim, 810, 215, { size: 34, weight: 700, alpha: Math.min(1, lk) });
    // caption 2: the floor stays dark; the sunny run against the longest darkness, to the same scale
    text(b.floor, 1270, 690, { size: 32, weight: 700, color: C.muted, align: 'center', alpha: ex(seg(u, 5.0, 5.8)) });
    const bk = ex(seg(u, 5.6, 6.4));
    if (bk > 0) {
      const lit = +SPEC.v.sunlit_days, dark = +SPEC.v.dark_days, bx = 1100, bw = 700, by = 410;
      const wl = bw * lit / (lit + dark) * es(u, 5.8, 7.4), wd = bw * dark / (lit + dark);
      K.panel(bx - 40, by - 72, bw + 80, 124, bk);
      g.save(); g.globalAlpha *= bk;
      K.rrect(bx, by, Math.max(1, wl), 26, 13, C.accent, null);
      const dk = pop(u, 7.4, 8.2);
      K.rrect(bx + bw - Math.max(6, wd), by - 6 * dk, Math.max(6, wd), 26 + 12 * dk, 3, C.ivory, null);
      text(b.bar_lit, bx, by - 22, { size: 26, weight: 600, color: C.accent });
      text(b.bar_dark, bx + bw, by - 22, { size: 26, weight: 600, align: 'right', alpha: Math.min(1, dk) });
      g.restore();
    }
  },
});
