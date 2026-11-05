// Scenes for sci_solar_power (spec: ../specs/sci_solar_power.json). Words from the beat's fields; sizes from SPEC.v.
(() => {
  // the battery as a water tank; level 0..1, with optional spill
  function tank(x, y, w, h, level, spill, u, b) {
    const { C, g, text, disc, rgba } = K;
    K.rrect(x, y, w, h, 28, rgba(C.ivory, .06), rgba(C.ivory, .55));
    g.save(); g.beginPath(); g.roundRect(x + 6, y + 6, w - 12, h - 12, 22); g.clip();
    const top = y + h - 6 - (h - 12) * level;
    g.fillStyle = C.water; g.beginPath(); g.moveTo(x, top);
    for (let i = 0; i <= 40; i++) g.lineTo(x + i * w / 40, top + Math.sin(i * .6 + u * 3) * 6);
    g.lineTo(x + w, y + h); g.lineTo(x, y + h); g.closePath(); g.fill();
    g.restore();
    if (spill > 0) for (let i = 0; i < 9; i++) {
      const p = ((u * .9 + i / 9) % 1);
      disc(x + w + 10 + p * 60, y + 10 + p * p * 260, 9, C.water, { alpha: spill * (1 - p) });
    }
    text(b.tank, x + w / 2, y + h + 50, { size: 34, weight: 700, align: 'center' });
  }
  function pipe(x1, y1, x2, y2, flow, u, col) {
    const { g, line, rgba } = K;
    line(x1, y1, x2, y2, { color: rgba(K.C.ivory, .18), width: 18 });
    if (flow <= 0) return;
    g.save(); g.setLineDash([18, 22]); g.lineDashOffset = -u * 120;
    line(x1, y1, x2, y2, { color: col, width: 10, alpha: flow }); g.restore();
  }

  Object.assign(SCENES, {
    // Low Sun, so the panel stands tall on a mast and turns to face it.
    array(g, u, b) {
      const { C, text, line, disc, es, ex, seg, pop, rgba } = K;
      const gy = 760;
      g.fillStyle = rgba(C.regolith, .55); g.fillRect(0, gy, 1920, 320);
      line(0, gy, 1920, gy, { color: C.muted, width: 3 });
      disc(110, gy - 40, 70, C.accent, { glow: 90 });
      text(b.sun, 110, gy - 140, { size: 30, weight: 700, color: C.accent, align: 'center', alpha: ex(seg(u, .4, 1.2)) });
      for (let i = 0; i < 5; i++) line(200, gy - 70 + i * 12, 1130, gy - 330 + i * 60, { color: rgba(C.accent, .35), width: 3, p: es(u, .3 + i * .1, 1.4 + i * .1) });
      // mast drawn to scale: the mast's length and the blanket's raised lower edge from the fixture (NASA/TM-20210011743)
      const mast = +SPEC.v.mast, blanket = +SPEC.v.blanket, px = 34, mx = 1180, top = gy - mast * px;
      const mk = es(u, .6, 2.0);
      line(mx, gy, mx, gy - (gy - top) * mk, { color: C.ivory, width: 10 });
      line(mx - 150, top, mx + 150, top, { color: C.ivory, width: 6, p: es(u, 1.8, 2.4) });
      const turn = .55 + .45 * Math.cos(u * .5), bk = es(u, 2.2, 3.4);
      for (const side of [-1, 1]) {
        const w = 120 * turn, x = mx + side * 80 - w / 2, h = ((gy - blanket * px) - (top + 8)) * bk;   // hangs from the arm down to its raised lower edge
        K.rrect(x, top + 8, w, h, 4, C.water, rgba(C.ivory, .7));
        g.save(); g.globalAlpha *= .35; for (let r = 1; r < 8; r++) line(x, top + 8 + h * r / 8, x + w, top + 8 + h * r / 8, { color: C.ivory, width: 1 }); g.restore();
      }
      const lk = pop(u, 4.8, 5.7);
      if (lk > 0) {
        text(b.mast_l, mx - 200, top + 40, { size: 32, weight: 700, align: 'right', alpha: Math.min(1, lk) });
        text(b.blanket_l, mx - 200, top + 90, { size: 32, weight: 700, color: C.water, align: 'right', alpha: Math.min(1, lk) });
      }
    },

    // Sunlight fills the tank, the base drains it, and a full tank spills.
    tank(g, u, b) {
      const { C, text, es, ex, seg } = K;
      const level = Math.min(1, .25 + .75 * es(u, .6, 4.4)), spill = ex(seg(u, 4.4, 5.2));
      pipe(300, 300, 760, 420, 1, u, C.accent);
      pipe(1160, 620, 1620, 700, 1, u, C.water);
      text(b.in_l, 300, 260, { size: 30, weight: 700, color: C.accent, alpha: ex(seg(u, .3, 1.0)) });
      text(b.out_l, 1620, 760, { size: 30, weight: 700, color: C.water, align: 'right', alpha: ex(seg(u, .8, 1.5)) });
      tank(760, 260, 400, 440, level, spill, u, b);
      text(b.spill, 1210, 300, { size: 32, weight: 700, color: C.caution, alpha: spill });
    },

    // No sunlight: nothing flows in, the tank drains, and the base goes dark.
    dark(g, u, b) {
      const { C, text, disc, es, ex, seg, rgba } = K;
      const level = 1 - es(u, .6, 6.4);
      pipe(300, 300, 760, 420, 1 - es(u, .2, 1.0), u, C.accent);
      pipe(1160, 620, 1620, 700, level > .03 ? 1 : 0, u, C.water);
      text(b.dark, 300, 260, { size: 30, weight: 700, color: C.muted, alpha: ex(seg(u, .4, 1.2)) });
      tank(760, 260, 400, 440, level, 0, u, b);
      // the base: three lit windows that go dark when the tank is empty
      const lit = level > .03 ? 1 : 1 - es(u, 6.2, 6.8);
      K.rrect(1560, 560, 280, 130, 20, rgba(C.ivory, .12), rgba(C.ivory, .4));
      for (let i = 0; i < 3; i++) disc(1620 + i * 80, 625, 22, C.accent, { glow: 24 * lit, alpha: .15 + .85 * lit });
      text(b.empty, 1700, 790, { size: 30, weight: 700, color: C.danger, align: 'center', alpha: ex(seg(u, 6.4, 7.2)) });
    },
  });
})();
