// Scenes for sci_earth_position (spec: ../specs/sci_earth_position.json). Words from the beat's fields; data from D.
Object.assign(SCENES, {
  // Earth's height above the pole horizon through April 2046 (JPL Horizons, six-hourly), with the hidden stretch shaded.
  sky(g, u, b) {
    const { C, text, line, poly, disc, es, ex, seg, pop, rgba, lerp } = K;
    const rows = D.earth, n = rows.length, x0 = 300, x1 = 1600, yTop = 210, yBot = 740, lo = -8, hi = 8;
    const X = i => lerp(x0, x1, i / (n - 1)), Y = v => lerp(yBot, yTop, (v - lo) / (hi - lo));
    const at = iso => rows.findIndex(r => r[0] >= iso);
    // opening: Earth sits low over a horizon line, gently rocking (u 0-4.4)
    const intro = 1 - es(u, 4.2, 5.2);
    if (intro > 0) {
      g.save(); g.globalAlpha *= intro;
      const gy = 640; line(120, gy, 1800, gy, { color: C.muted, width: 3 });
      g.fillStyle = rgba(C.regolith, .5); g.fillRect(120, gy, 1680, 200);
      const ey = gy - 70 - Math.sin(u * .9) * 40;
      disc(960, ey, 62, C.water, { glow: 40 });
      g.save(); g.beginPath(); g.arc(960, ey, 62, 0, Math.PI * 2); g.clip();
      g.fillStyle = rgba(C.good, .85); g.beginPath(); g.ellipse(940, ey - 12, 26, 18, .5, 0, Math.PI * 2); g.ellipse(982, ey + 22, 18, 26, -.3, 0, Math.PI * 2); g.fill();
      g.fillStyle = rgba(C.ivory, .5); g.beginPath(); g.ellipse(965, ey - 40, 30, 8, .2, 0, Math.PI * 2); g.fill(); g.restore();
      text(b.earth, 960, ey - 92, { size: 34, weight: 700, align: 'center', alpha: ex(seg(u, .4, 1.2)) });
      text(b.horizon, 1700, gy - 18, { size: 28, weight: 600, color: C.muted, align: 'right' });
      g.restore();
    }
    // the chart (u 4.6 on)
    const ck = ex(seg(u, 4.6, 5.4));
    if (ck <= 0) return;
    g.save(); g.globalAlpha *= ck;
    const s = at(D.crossings[1][0]), r = at(D.crossings[2][0]);
    const hk = es(u, 9.2, 10.2);
    g.fillStyle = rgba(C.navy, .7); g.fillRect(X(s), yTop, (X(r) - X(s)) * hk, yBot - yTop);
    for (let v = lo; v <= hi; v += 4) {
      if (v) line(x0, Y(v), x1, Y(v), { color: rgba(C.ivory, .1), width: 2 });
      text((v > 0 ? '+' : v < 0 ? '−' : '') + Math.abs(v) + '°', x0 - 24, Y(v) + 10, { size: 26, color: C.muted, align: 'right', mono: true });
    }
    line(x0, Y(0), x1, Y(0), { color: C.ivory, width: 3 });
    text(b.horizon, x1 + 16, Y(0) + 10, { size: 26, weight: 600 });
    text(b.y_title, x0, yTop - 36, { size: 30, weight: 600, color: C.muted });
    rows.forEach((row, i) => {
      if (/-04-(01|08|15|22|29)T00:00Z$/.test(row[0])) {
        const d = new Date(row[0]);
        text(d.getUTCDate() + ' ' + d.toLocaleString('en-GB', { month: 'short', timeZone: 'UTC' }), X(i), yBot + 42, { size: 24, color: C.muted, align: 'center' });
      }
    });
    g.restore();
    const p = es(u, 5.0, 9.0), pts = rows.map((row, i) => [X(i), Y(row[1])]);
    poly(pts, p, { color: C.water, width: 5, glow: 14 });
    const k = (n - 1) * p, i0 = Math.floor(k), f = k - i0, a = pts[i0], c = pts[Math.min(n - 1, i0 + 1)];
    if (p > 0 && p < 1) disc(lerp(a[0], c[0], f), lerp(a[1], c[1], f), 16, C.water, { glow: 26 });
    const lk = pop(u, 9.6, 10.5);
    if (lk > 0) text(b.hidden, (X(s) + X(r)) / 2, yTop + 50, { size: 30, weight: 700, align: 'center', alpha: Math.min(1, lk) });
  },

  // The best peak near the pole: sunlight and Earth-in-view shares (JPL IPN 42-176).
  peaks(g, u, b) {
    const { C, text, line, ring, disc, es, ex, seg, pop, rgba } = K;
    const prof = [[0, 760], [260, 700], [520, 610], [700, 420], [760, 330], [820, 420], [1000, 600], [1300, 660], [1600, 700], [1920, 690]];
    g.save(); g.globalAlpha *= es(u, 0, .8);
    g.beginPath(); g.moveTo(0, 1080); prof.forEach(([x, y]) => g.lineTo(x, y)); g.lineTo(1920, 1080); g.closePath();
    const tg = g.createLinearGradient(0, 330, 0, 900); tg.addColorStop(0, C.regolith); tg.addColorStop(1, '#1C1C1C'); g.fillStyle = tg; g.fill();
    g.restore();
    // relay dish on the summit, beaming to a small Earth
    const dk = pop(u, .6, 1.5);
    g.save(); g.translate(760, 330); g.scale(dk, dk);
    g.fillStyle = C.ivory; g.fillRect(-4, -70, 8, 70);
    g.beginPath(); g.ellipse(0, -84, 40, 16, -.5, 0, Math.PI * 2); g.fill(); g.restore();
    disc(260, 220, 46, C.water, { glow: 30, alpha: Math.min(1, dk) });
    g.save(); g.setLineDash([14, 12]); g.lineDashOffset = -u * 60;
    line(740, 250, 300, 225, { color: rgba(C.water, .85), width: 4, p: es(u, 1.2, 2.2) }); g.restore();
    text(b.peak, 760, 190, { size: 30, weight: 700, align: 'center', alpha: ex(seg(u, 1.2, 2.0)) });
    // two rings that fill to the published shares
    for (const [cx, v, label, val, col, t0] of [[1250, SPEC.v.sun_pct, b.sun, b.sun_v, C.accent, 4.6], [1600, SPEC.v.dte, b.link, b.link_v, C.water, .4]]) {
      const kk = es(u, t0, t0 + 1.6), share = +v / 100;
      ring(cx, 360, 110, rgba(C.ivory, .12), { width: 22, alpha: ex(seg(u, t0 - .4, t0)) });
      ring(cx, 360, 110, col, { width: 22, a0: -Math.PI / 2, a1: -Math.PI / 2 + Math.PI * 2 * share * kk });
      text(val, cx, 376, { size: 48, weight: 800, align: 'center', alpha: ex(seg(u, t0 + .8, t0 + 1.6)) });
      text(label, cx, 520, { size: 30, weight: 700, align: 'center', color: col, alpha: ex(seg(u, t0, t0 + .8)) });
    }
  },

  // The shift-4 cutoff is a drill: Earth was already below the horizon all night.
  drill(g, u, b) {
    const { C, text, ex, seg, pop, wrap } = K;
    const k = pop(u, .1, 1.0), m = Math.min(1, k);
    g.save(); g.translate(960, 440); g.scale(k, k); g.translate(-960, -440);
    K.panel(460, 320, 1000, 240);
    wrap(b.card, 880, 46, 700).forEach((l, i) => text(l, 960, 420 + i * 56, { size: 46, weight: 700, align: 'center', color: C.accent }));
    text(b.sub, 960, 512, { size: 30, weight: 600, align: 'center', alpha: ex(seg(u, .6, 1.4)) * m });
    g.restore();
  },
});
