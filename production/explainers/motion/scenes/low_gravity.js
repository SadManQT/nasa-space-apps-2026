// Scenes for sci_low_gravity (spec: ../specs/sci_low_gravity.json). Diagrams only: the ratio is the textbook one-sixth.
(() => {
  const G = 1 / 6;   // Moon/Earth surface gravity, about one-sixth
  function figure(x, y, col, alpha = 1) {
    const { g, disc } = K;
    g.save(); g.globalAlpha *= alpha; disc(x, y - 120, 26, col); K.rrect(x - 30, y - 90, 60, 90, 24, col, null); g.restore();
  }
  Object.assign(SCENES, {
    // Same push, two worlds: the Moon jump goes higher and lasts longer.
    jump(g, u, b) {
      const { C, text, line, ex, seg } = K;
      const gy = 760, v = 1;                                                   // same take-off speed on both
      for (const [x, label, grav, col] of [[620, b.earth, 1, C.water], [1300, b.moon, G, C.ivory]]) {
        line(x - 220, gy, x + 220, gy, { color: C.muted, width: 3 });
        const T = 2 * v / grav * .45, t = (u % (T + .4));                       // flight time scales with 1/g
        const h = t < T ? (v * t - .5 * grav * t * t / .45) * 260 : 0;
        figure(x, gy - Math.max(0, h), col);
        text(label, x, gy + 60, { size: 36, weight: 800, align: 'center', color: col, alpha: ex(seg(u, .2, 1.0)) });
      }
    },
    // Dust kicked up by a boot: clean ballistic arcs, nothing hangs in the air.
    dust(g, u, b) {
      const { C, text, disc, line, ex, seg, rgba, rng } = K;
      const gy = 760, R = rng(9), cyc = u % 2.2;
      line(200, gy, 1720, gy, { color: C.muted, width: 3 });
      K.rrect(900, gy - 60, 120, 60, 20, C.ivory, null);
      for (let i = 0; i < 60; i++) {
        const a = -Math.PI / 2 + (R() - .5) * 2.2, s = 280 + R() * 420;
        const x = 960 + Math.cos(a) * s * cyc, y = gy - 60 - (-Math.sin(a) * s * cyc - .5 * 260 * cyc * cyc);
        if (y > gy) continue;
        disc(x, y, 4, rgba(C.regolith, 1), { alpha: .9 });
      }
      text(b.dust, 960, 240, { size: 40, weight: 800, align: 'center', alpha: ex(seg(u, .6, 1.4)) });
    },
    // Two rovers brake from the same speed: the Moon one needs more room.
    brake(g, u, b) {
      const { C, text, line, es, ex, seg, lerp } = K;
      for (const [y, label, grav, col] of [[420, b.earth, 1, C.water], [700, b.moon, G, C.ivory]]) {
        line(200, y + 20, 1720, y + 20, { color: C.muted, width: 2 });
        const stop = 300 + 150 / grav,                                           // stopping distance ~ v²/(2μg): six times longer at one-sixth g
         x = lerp(240, Math.min(stop, 1640), es(u, .4, 4.4));
        K.rrect(x - 70, y - 40, 140, 50, 12, col, null);
        line(300, y + 50, Math.min(stop, 1640), y + 50, { color: col, width: 4, alpha: ex(seg(u, 4.4, 5.0)) });
        text(label, 200, y - 60, { size: 32, weight: 800, color: col, alpha: ex(seg(u, .2, 1.0)) });
      }
      text(b.stop, 960, 880, { size: 30, weight: 700, align: 'center', color: C.muted, alpha: ex(seg(u, 4.6, 5.4)) });
    },
  });
})();
