// Scenes for sci_plant_growth (spec: ../specs/sci_plant_growth.json). Words from the beat's fields; days from D.
// Canon: plants never have faces. They are drawn as stems, leaves, flowers, pods and seeds only.
(() => {
  // one Brassica plant at growth g (0 seed .. 1 seeds ripe)
  function plant(x, y, s, gr, u, col = K.C.good) {
    const { g, disc, line, rgba, C } = K;
    g.save(); g.translate(x, y); g.scale(s, s);
    if (gr < .08) { disc(0, -6, 10, '#8A6A3A'); g.restore(); return; }
    const h = 40 + 260 * Math.min(1, gr / .45), sway = Math.sin(u * 1.4 + x) * 4;
    line(0, 0, sway, -h, { color: col, width: 8 });
    const leaves = Math.min(4, Math.floor(gr * 10));
    for (let i = 0; i < leaves; i++) {
      const yy = -h * (.25 + i * .17), side = i % 2 ? 1 : -1;
      g.save(); g.translate(sway * (yy / -h), yy); g.rotate(side * .7);
      g.beginPath(); g.ellipse(side * 34, 0, 38, 14, 0, 0, Math.PI * 2); g.fillStyle = col; g.fill(); g.restore();
    }
    if (gr > .35 && gr < .8) for (let i = 0; i < 5; i++) {                  // a cluster of four-petal yellow flowers
      const a = i / 5 * Math.PI * 2, fx = sway + Math.cos(a) * 22, fy = -h - 10 + Math.sin(a) * 12;
      for (let p = 0; p < 4; p++) disc(fx + Math.cos(p * Math.PI / 2) * 7, fy + Math.sin(p * Math.PI / 2) * 7, 6, C.accent);
    }
    if (gr >= .7) for (let i = 0; i < 4; i++) {                             // slender pods
      g.save(); g.translate(sway + (i - 1.5) * 16, -h + 6); g.rotate((i - 1.5) * .25);
      K.rrect(-4, -46, 8, 46, 4, gr > .95 ? '#B49A5A' : rgba(C.good, .9), null); g.restore();
    }
    g.restore();
  }

  Object.assign(SCENES, {
    // Seed to seeds on a day ruler: flowers, pollen carried between two plants, ripe pods.
    cycle(g, u, b) {
      const { C, text, line, disc, es, ex, seg, pop, rgba, lerp } = K;
      const days = D.harvest, x0 = 420, x1 = 1700, ry = 770, X = d => lerp(x0, x1, d / days);
      const keys = [[.4, 0], [5.0, D.flower], [9.0, D.pollinate[0]], [13.4, D.pollinate[1]], [16.6, days]];   // beat seconds -> plant day
      let day = days;
      for (let i = 1; i < keys.length; i++) if (u < keys[i][0]) { const [a0, d0] = keys[i - 1], [a1, d1] = keys[i]; day = lerp(d0, d1, es(u, a0, a1)); break; }
      if (u < keys[0][0]) day = 0;
      line(x0, ry, x1, ry, { color: C.muted, width: 3 });
      for (let d = 0; d <= days; d += 10) { line(X(d), ry, X(d), ry + 12, { color: C.muted, width: 2 }); text(String(d), X(d), ry + 44, { size: 26, color: C.muted, align: 'center', mono: true }); }
      text(b.days, x0 - 36, ry + 44, { size: 28, weight: 600, color: C.muted, align: 'right' });
      disc(X(day), ry, 12, C.accent, { glow: 20 });
      const gr = day / days;
      plant(760, 700, 1.4, gr, u); plant(1160, 700, 1.4, gr, u, '#5DBE6C');
      // milestones on the ruler
      for (const [d, label, t0] of [[0, b.seed, .4], [D.flower, b.flowers, 5.0], [days, b.seeds, 13.8]]) {
        const k = ex(seg(u, t0, t0 + .8));
        if (k > 0) { line(X(d), ry - 30, X(d), ry, { color: C.ivory, width: 2, alpha: k }); text(label, X(d), ry - 44, { size: 28, weight: 700, align: 'center', alpha: k }); }
      }
      // pollen hopping from one plant's flowers to the other's during the pollination window
      const [p0, p1] = D.pollinate, pk = day >= p0 && day <= p1 + 2 ? ex(seg(u, 9.0, 9.6)) : 0;
      if (pk > 0) {
        for (let i = 0; i < 7; i++) {
          const q = ((u * .6 + i / 7) % 1), x = lerp(780, 1140, q), y = 700 - 330 - Math.sin(q * Math.PI) * 110;
          disc(x, y, 7, C.accent, { glow: 12, alpha: pk });
        }
        text(b.pollen, 960, 175, { size: 32, weight: 700, align: 'center', color: C.accent, alpha: pk });
        line(X(p0), ry + 2, X(p1), ry + 2, { color: C.accent, width: 8, alpha: pk });
      }
    },

    // In orbit: Mir's seed-to-seed run, hand pollination, and ISS greens under lamps.
    space(g, u, b) {
      const { C, text, disc, line, ex, seg, pop, rgba } = K;
      [[540, b.mir, .3, C.accent], [1380, b.iss, 8.6, C.amara]].forEach(([cx, label, t0, lamp]) => {
        const k = pop(u, t0, t0 + 1.0), m = Math.min(1, k);
        if (k <= 0) return;
        g.save(); g.translate(cx, 470); g.scale(k, k); g.translate(-cx, -470);
        K.rrect(cx - 300, 230, 600, 440, 40, C.glass, C.glass_edge);
        K.rrect(cx - 240, 260, 480, 26, 13, lamp, null);                    // the grow lamp
        g.save(); g.globalAlpha *= .12; g.fillStyle = lamp; g.beginPath(); g.moveTo(cx - 240, 286); g.lineTo(cx + 240, 286); g.lineTo(cx + 280, 640); g.lineTo(cx - 280, 640); g.closePath(); g.fill(); g.restore();
        for (let i = 0; i < 3; i++) plant(cx - 150 + i * 150, 630, .9, .65, u + i);
        g.restore();
        K.wrap(label, 560, 32, 700).forEach((l, i) => text(l, cx, 740 + i * 40, { size: 32, weight: 700, align: 'center', alpha: m }));
      });
      // a small brush carrying pollen between Mir's flowers (caption 2)
      const hk = ex(seg(u, 5.2, 6.0)) * (1 - ex(seg(u, 8.4, 9.0)));
      if (hk > 0) {
        const q = (Math.sin(u * 2) + 1) / 2, x = 390 + q * 300, y = 360 - Math.sin(q * Math.PI) * 40;
        line(x, y, x + 50, y - 60, { color: C.ivory, width: 6, alpha: hk });
        disc(x, y, 12, C.accent, { glow: 16, alpha: hk });
        text(b.hand, 540, 205, { size: 30, weight: 700, align: 'center', color: C.accent, alpha: hk });
      }
    },

    // Where the evidence stops: orbit, not the Moon.
    limits(g, u, b) {
      const { C, text, ex, seg, pop, wrap } = K;
      const k = pop(u, .1, 1.0);
      g.save(); g.translate(960, 440); g.scale(k, k); g.translate(-960, -440);
      K.panel(420, 320, 1080, 250);
      wrap(b.card, 960, 44, 700).forEach((l, i) => text(l, 960, 420 + i * 54, { size: 44, weight: 700, align: 'center', color: C.accent }));
      wrap(b.sub, 960, 30, 600).forEach((l, i) => text(l, 960, 500 + i * 38, { size: 30, weight: 600, align: 'center', alpha: ex(seg(u, .6, 1.4)) * Math.min(1, k) }));
      g.restore();
    },
  });
})();
