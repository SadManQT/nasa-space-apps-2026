// Scenes for sci_rover_slopes (spec: ../specs/sci_rover_slopes.json). Words from the beat's fields; the limit from D.
(() => {
  function rover(x, y, ang, slip, u) {
    const { g, disc, C, rgba } = K;
    g.save(); g.translate(x, y); g.rotate(-ang);
    K.rrect(-90, -70, 180, 50, 12, C.ivory, null);
    K.rrect(-40, -110, 60, 40, 8, C.water, null);
    for (const wx of [-60, 0, 60]) {
      disc(wx, -14, 22, '#2A2A2A'); g.save(); g.translate(wx, -14); g.rotate(u * (slip ? 14 : 5));
      g.fillStyle = rgba(C.ivory, .6); g.fillRect(-3, -20, 6, 40); g.restore();
    }
    if (slip) for (let i = 0; i < 8; i++) disc(-90 - i * 14, -6 - (i % 3) * 6, 5 - i * .4, rgba(C.regolith, .9));
    g.restore();
  }

  Object.assign(SCENES, {
    // The ramp tilts up; past the design limit the wheels spin and the rover slides back.
    climb(g, u, b) {
      const { C, text, line, ring, es, ex, seg, lerp } = K;
      const limit = D.slope, deg = lerp(5, limit + 8, es(u, .4, 12.0)), a = deg * Math.PI / 180, slip = deg > limit;
      const x0 = 300, y0 = 800, L = 1300, ex1 = x0 + Math.cos(a) * L, ey1 = y0 - Math.sin(a) * L;
      g.beginPath(); g.moveTo(x0, y0); g.lineTo(ex1, ey1); g.lineTo(ex1, y0); g.closePath(); g.fillStyle = K.rgba(C.regolith, .7); g.fill();
      line(x0, y0, ex1, ey1, { color: slip ? C.danger : C.good, width: 6 });
      const along = slip ? .45 - ((u * .2) % .12) : lerp(.15, .55, es(u, .4, 9.0));
      rover(x0 + Math.cos(a) * L * along, y0 - Math.sin(a) * L * along, a, slip, u);
      ring(x0, y0, 160, C.ivory, { a0: -a, a1: 0, width: 3 });
      text(Math.round(deg) + '°', x0 + 190, y0 - 30, { size: 48, weight: 800, mono: true, color: slip ? C.danger : C.good });
      text(slip ? b.slip : b.ok, 1500, 240, { size: 40, weight: 800, align: 'center', color: slip ? C.danger : C.good, alpha: ex(seg(u, 1.0, 1.8)) });
    },

    // Top-down: the straight steep line versus the longer gentle route.
    route(g, u, b) {
      const { C, text, poly, disc, es, ex, seg, rgba } = K;
      // contour rings of a hill between the two points
      for (let i = 0; i < 6; i++) { K.g.beginPath(); K.g.ellipse(960, 470, 120 + i * 60, 80 + i * 40, 0, 0, Math.PI * 2); K.g.strokeStyle = rgba(C.muted, .35); K.g.lineWidth = 2; K.g.stroke(); }
      const A = [320, 470], B = [1600, 470];
      disc(A[0], A[1], 16, C.ivory); disc(B[0], B[1], 16, C.ivory);
      poly([A, [960, 470], B], es(u, .4, 2.0), { color: C.danger, width: 6, dash: [16, 12] });
      text(b.steep, 960, 440, { size: 30, weight: 700, color: C.danger, align: 'center', alpha: ex(seg(u, 1.2, 2.0)) });
      const arc = []; for (let i = 0; i <= 40; i++) { const t = i / 40; arc.push([320 + 1280 * t, 470 + Math.sin(t * Math.PI) * 330]); }
      poly(arc, es(u, 4.6, 7.4), { color: C.good, width: 7, glow: 12 });
      text(b.gentle, 960, 850, { size: 32, weight: 800, color: C.good, align: 'center', alpha: ex(seg(u, 5.4, 6.2)) });
    },
  });
})();
