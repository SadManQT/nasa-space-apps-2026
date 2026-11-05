// Scenes for sci_water_evidence (spec: ../specs/sci_water_evidence.json). Words from the beat's fields; data from SPEC.v and D.
Object.assign(SCENES, {
  // LCROSS: a spent stage hits a dark crater, a plume rises, a shepherd spacecraft flies through it.
  impact(g, u, b) {
    const { C, text, line, disc, es, ex, seg, pop, rgba, lerp, rng } = K;
    const gy = 720, hx = 1000;
    g.beginPath(); g.moveTo(0, gy - 40); g.quadraticCurveTo(hx, gy + 160, 1920, gy - 40); g.lineTo(1920, 1080); g.lineTo(0, 1080); g.closePath();
    g.fillStyle = '#1E1E1E'; g.fill();
    // the stage falls (0.4-3.0 s), hits, and the plume blooms
    const fall = es(u, .4, 3.0), sx = lerp(1700, hx, fall), sy = lerp(120, gy + 30, fall * fall);
    if (u < 3.0) {
      g.save(); g.translate(sx, sy); g.rotate(-.9);
      K.rrect(-18, -60, 36, 120, 10, C.ivory, null); g.restore();
      text(b.stage, sx + 40, sy - 40, { size: 28, weight: 700, alpha: ex(seg(u, .6, 1.4)) * (1 - seg(u, 2.6, 3.0)) });
    }
    const pk = ex(seg(u, 3.0, 5.0)), R = rng(5);
    for (let i = 0; i < 160 && pk > 0; i++) {
      const a = -Math.PI / 2 + (R() - .5) * 1.5, sp = 200 + R() * 520, t = Math.max(0, u - 3.0);
      const x = hx + Math.cos(a) * sp * Math.min(t, 3) * .55, y = gy + 40 + Math.sin(a) * sp * Math.min(t, 3) * .55 + 30 * Math.min(t, 3) ** 2;
      const ice = i % 6 === 0;
      disc(x, y, ice ? 5 : 3.5, ice ? C.amara : rgba(C.muted, .8), { alpha: pk * Math.max(0, 1 - t / 9), glow: ice ? 10 : 0 });
    }
    text(b.plume, hx, 330, { size: 32, weight: 700, align: 'center', alpha: ex(seg(u, 4.0, 4.8)) * (1 - seg(u, 9.0, 9.6)) });
    // the shepherding spacecraft crosses the plume (caption 2)
    const fk = es(u, 5.0, 9.0);
    if (u > 5.0) {
      const x = lerp(-80, 2000, fk), y = 360 + fk * 60;
      K.rrect(x - 30, y - 16, 60, 32, 6, C.ivory, null); K.rrect(x - 90, y - 8, 50, 16, 3, C.water, null); K.rrect(x + 40, y - 8, 50, 16, 3, C.water, null);
    }
    const rk = pop(u, 9.4, 10.3);
    if (rk > 0) { K.panel(hx - 330, 140, 660, 110, Math.min(1, rk)); text(b.result, hx, 212, { size: 42, weight: 800, align: 'center', color: C.amara, alpha: Math.min(1, rk) }); }
  },

  // The M3 map: only a few cold-trap cells light up with surface ice (a share, not a map of real places).
  map(g, u, b) {
    const { C, text, disc, ring, ex, seg, pop, rgba, rng } = K;
    const cx = 760, cy = 470, R0 = 300, cells = [], R = rng(21);
    for (let i = 0; i < 400; i++) { const r = Math.sqrt(R()) * R0, a = R() * Math.PI * 2; cells.push([cx + Math.cos(a) * r, cy + Math.sin(a) * r]); }
    const iceN = Math.round(cells.length * D.m3 / 100), mk = ex(seg(u, .4, 1.4));
    ring(cx, cy, R0 + 24, C.muted, { width: 2, dash: [8, 8], alpha: mk });
    cells.forEach(([x, y], i) => {
      const isIce = i < iceN, lit = isIce ? ex(seg(u, 4.8 + i * .2, 5.4 + i * .2)) : 0;
      disc(x, y, 9, rgba(C.regolith, .9), { alpha: mk });
      if (lit > 0) { disc(x, y, 12, C.amara, { glow: 22, alpha: lit }); ring(x, y, 12 + 26 * seg(u, 4.8 + i * .2, 6 + i * .2), C.amara, { width: 2, alpha: 1 - seg(u, 4.8 + i * .2, 6 + i * .2) }); }
    });
    text(b.map, cx, cy + R0 + 80, { size: 30, weight: 700, align: 'center', color: C.muted, alpha: mk });
    const lk = pop(u, 5.2, 6.1);
    if (lk > 0) { K.panel(1180, 380, 600, 120, Math.min(1, lk)); text(b.ice, 1480, 456, { size: 38, weight: 800, align: 'center', color: C.amara, alpha: Math.min(1, lk) }); }
  },
});
