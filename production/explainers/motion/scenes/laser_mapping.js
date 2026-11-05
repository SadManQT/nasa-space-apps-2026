// Scenes for sci_laser_mapping (spec: ../specs/sci_laser_mapping.json). Words from the beat's fields; the map is the real
// LOLA hillshade of the Aurora ridge (production/terrain/preview/, M1-34), shown as measured; the slope beat is a diagram.
(() => {
  const prof = x => 640 + Math.sin(x * .006) * 60 + Math.sin(x * .017 + 1) * 28 + Math.sin(x * .041) * 10;   // a rolling surface

  Object.assign(SCENES, {
    // The orbiter fires laser pulses; each echo's travel time becomes a height point on the ground.
    pulse(g, u, b) {
      const { C, text, line, disc, ring, ex, seg, pop, rgba } = K;
      g.beginPath(); g.moveTo(0, 1080); for (let x = 0; x <= 1920; x += 10) g.lineTo(x, prof(x)); g.lineTo(1920, 1080); g.closePath();
      g.fillStyle = C.regolith; g.fill();
      const sx = 200 + (u * 110) % 1600, sy = 180;                              // the orbiter crosses the sky
      K.rrect(sx - 40, sy - 18, 80, 36, 8, C.ivory, null); K.rrect(sx - 110, sy - 8, 60, 16, 3, C.water, null); K.rrect(sx + 50, sy - 8, 60, 16, 3, C.water, null);
      text(b.lro, sx, sy - 40, { size: 28, weight: 700, align: 'center', alpha: ex(seg(u, .2, 1.0)) });
      // pulses: down, a bright spot, back up; each leaves a height dot behind
      for (let i = 0; i < 24; i++) {
        const t0 = .6 + i * .42, p = (u - t0) / .9;
        if (p < 0) continue;
        const px = 200 + (t0 * 110) % 1600, gy = prof(px);
        if (p < 1) {
          const y = p < .5 ? sy + (gy - sy) * p * 2 : gy - (gy - sy) * (p - .5) * 2;
          line(px, sy + 20, px, y, { color: rgba(C.danger, .8), width: 3 });
          if (Math.abs(p - .5) < .08) disc(px, gy, 10, C.danger, { glow: 24 });
        }
        if (p > .5) disc(px, gy - 6, 6, C.accent, { glow: 10, alpha: Math.min(1, (p - .5) * 4) });
      }
      const ek = pop(u, 5.0, 5.9);
      if (ek > 0) { K.panel(1180, 300, 640, 96, Math.min(1, ek)); text(b.echo, 1500, 362, { size: 32, weight: 800, align: 'center', alpha: Math.min(1, ek) }); }
    },

    // The real hillshade, revealed as a grid of height points that turns into the measured map.
    map(g, u, b) {
      const { C, text, ex, seg, es, rgba } = K;
      const im = IMG.ridge, size = 620, x0 = 220, y0 = 150;
      const reveal = es(u, .4, 4.0);
      // dots first (a coarse sampling grid), then the full map fades in through them
      g.save(); g.globalAlpha *= reveal; g.drawImage(im, x0, y0, size, size); g.restore();
      const dk = 1 - es(u, 3.0, 4.4);
      if (dk > 0) for (let i = 0; i < 24; i++) for (let j = 0; j < 24; j++) K.disc(x0 + 13 + i * 25.4, y0 + 13 + j * 25.4, 3, C.accent, { alpha: dk * ex(seg(u, (i + j) * .02, (i + j) * .02 + .3)) });
      K.rrect(x0 - 4, y0 - 4, size + 8, size + 8, 12, null, rgba(C.ivory, .5));
      text(b.grid, x0 + size + 60, 300, { size: 34, weight: 800, color: C.accent, alpha: ex(seg(u, .6, 1.4)) });
      text(b.here, x0 + size + 60, 420, { size: 32, weight: 700, alpha: ex(seg(u, 5.2, 6.0)) });
      // a soft ring where the station sits (the map's centre is the Aurora site)
      K.ring(x0 + size / 2, y0 + size / 2, 26 + 4 * Math.sin(u * 3), C.accent, { width: 3, alpha: ex(seg(u, 5.4, 6.2)) });
    },

    // Slope from two neighbouring heights: rise over run; a road keeps every step gentle.
    slope(g, u, b) {
      const { C, text, line, disc, es, ex, seg, pop, rgba } = K;
      g.beginPath(); g.moveTo(0, 1080); for (let x = 0; x <= 1920; x += 10) g.lineTo(x, prof(x) - 60); g.lineTo(1920, 1080); g.closePath(); g.fillStyle = rgba(C.regolith, .8); g.fill();
      const pts = []; for (let i = 0; i < 16; i++) { const x = 160 + i * 106; pts.push([x, prof(x) - 66]); }
      pts.forEach(([x, y], i) => disc(x, y, 8, C.accent, { alpha: ex(seg(u, .2 + i * .05, .6 + i * .05)) }));
      let k = 0; for (let i = 1; i < pts.length - 1; i++) if (Math.abs(pts[i + 1][1] - pts[i][1]) > Math.abs(pts[k + 1][1] - pts[k][1])) k = i;   // the steepest step
      const [ax, ay] = pts[k], [bx, by] = pts[k + 1], tk = pop(u, 1.2, 2.0);
      if (tk > 0) {
        const m = Math.min(1, tk);
        line(ax, ay, bx, ay, { color: C.ivory, width: 3, alpha: m }); line(bx, ay, bx, by, { color: C.ivory, width: 3, alpha: m });
        line(ax, ay, bx, by, { color: C.caution, width: 5, alpha: m });
        text(b.run, (ax + bx) / 2, Math.max(ay, by) + 44, { size: 32, weight: 800, align: 'center', alpha: m });
        text(b.rise, bx + 18, (ay + by) / 2 + 10, { size: 32, weight: 800, alpha: m });
      }
      K.poly(pts, es(u, 4.0, 7.4), { color: C.good, width: 6, glow: 10 });
      const rk = pop(u, 4.4, 5.2);
      if (rk > 0) { K.panel(560, 190, 800, 100, Math.min(1, rk)); text(b.road, 960, 254, { size: 32, weight: 800, align: 'center', color: C.good, alpha: Math.min(1, rk) }); }
    },
  });
})();
