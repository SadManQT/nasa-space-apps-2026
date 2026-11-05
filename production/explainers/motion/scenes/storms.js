// Scenes for sci_storms_2012_2017 (spec: ../specs/sci_storms_2012_2017.json). Words from the beat's fields; data from D.
Object.assign(SCENES, {
  // The July 2012 CME sweeps past Earth's position and hits STEREO-A, further along Earth's orbit.
  miss(g, u, b) {
    const { C, text, disc, ring, ex, seg, es, rgba } = K;
    const sx = 960, sy = 470, R = 330;
    ring(sx, sy, R, rgba(C.muted, .5), { width: 2, dash: [10, 10] });
    disc(sx, sy, 60, C.accent, { glow: 70 }); text(b.sun, sx, sy + 100, { size: 28, weight: 700, color: C.accent, align: 'center' });
    const ea = Math.PI * .5, sa = Math.PI * .5 - 2.1;                         // Earth below; STEREO-A ahead of it on the orbit
    const exy = [sx + Math.cos(ea) * R, sy + Math.sin(ea) * R], sxy = [sx + Math.cos(sa) * R, sy + Math.sin(sa) * R];
    disc(exy[0], exy[1], 26, C.water, { glow: 14 }); text(b.earth, exy[0], exy[1] + 60, { size: 28, weight: 700, align: 'center' });
    K.rrect(sxy[0] - 20, sxy[1] - 12, 40, 24, 5, C.ivory, null); text(b.stereo, sxy[0] + 40, sxy[1] - 24, { size: 28, weight: 700 });
    // the CME as an expanding wedge towards STEREO-A
    const p = es(u, .6, 6.0), r = 60 + (R + 40 - 60) * p;
    g.save(); g.globalAlpha *= .55; g.beginPath(); g.moveTo(sx, sy); g.arc(sx, sy, r, sa - .45, sa + .45); g.closePath();
    const cg = g.createRadialGradient(sx, sy, 40, sx, sy, r); cg.addColorStop(0, rgba(C.caution, 0)); cg.addColorStop(1, rgba(C.caution, .9)); g.fillStyle = cg; g.fill(); g.restore();
    text(b.cme, sx + 420, sy - 300, { size: 32, weight: 800, color: C.caution, alpha: ex(seg(u, 1.0, 1.8)) });
    if (p > .95) ring(sxy[0], sxy[1], 30 + 30 * seg(u, 6.0, 7.0), C.caution, { width: 4, alpha: 1 - seg(u, 6.0, 7.0) });
  },

  // Two real proton curves on one log axis: STEREO-A in 2012 and GOES-13 at Earth in 2017 (hourly means, hours since start).
  compare(g, u, b) {
    const { C, text, line, poly, ex, seg, es, rgba, lerp } = K;
    const x0 = 300, x1 = 1400, yTop = 200, yBot = 720, lo = -3, hi = 4;
    const Y = v => yBot - (Math.log10(Math.max(v, 1e-3)) - lo) / (hi - lo) * (yBot - yTop);
    const n = Math.min(D.stereo.length, D.goes.length), X = i => lerp(x0, x1, i / (n - 1));
    const ak = ex(seg(u, 0, .8));
    g.save(); g.globalAlpha *= ak;
    for (let e = lo; e <= hi; e++) { line(x0, Y(10 ** e), x1, Y(10 ** e), { color: rgba(C.ivory, .08), width: 2 }); text(e >= 0 ? (10 ** e).toLocaleString('en-US') : String(10 ** e), x0 - 18, Y(10 ** e) + 9, { size: 22, color: C.muted, align: 'right', mono: true }); }
    text(b.y, x0, yTop - 36, { size: 28, weight: 600, color: C.muted });
    g.restore();
    const s = D.stereo.slice(0, n).map((r, i) => [X(i), Y(r[1])]), gq = D.goes.slice(0, n).map((r, i) => [X(i), Y(r[1])]);
    poly(s, es(u, .4, 4.8), { color: C.amara, width: 5, glow: 12 });
    poly(gq, es(u, 5.2, 9.6), { color: C.caution, width: 5, glow: 12 });
    text(b.a, x1 + 16, s[s.length - 1][1], { size: 26, weight: 700, color: C.amara, alpha: ex(seg(u, 4.4, 5.2)) });
    text(b.b, x1 + 16, gq[gq.length - 1][1] + 30, { size: 26, weight: 700, color: C.caution, alpha: ex(seg(u, 9.2, 10.0)) });
  },
});
