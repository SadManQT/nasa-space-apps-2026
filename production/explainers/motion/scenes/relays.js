// Scenes for sci_relays (spec: ../specs/sci_relays.json). Words from the beat's fields; height from SPEC.v. Diagrams, not to scale.
(() => {
  const ground = (g, C) => {
    g.beginPath(); g.moveTo(0, 1080);
    for (let x = 0; x <= 1920; x += 40) g.lineTo(x, 760 + Math.pow((x - 960) / 960, 2) * 120);   // the Moon's surface curving away
    g.lineTo(1920, 1080); g.closePath(); g.fillStyle = C.regolith; g.fill();
  };
  Object.assign(SCENES, {
    // The base's straight radio line runs into the horizon; Earth is below it.
    blocked(g, u, b) {
      const { C, text, line, disc, ex, seg, es, pop } = K;
      ground(g, C);
      K.rrect(260, 740, 120, 50, 10, C.ivory, null); text(b.base, 320, 720, { size: 30, weight: 700, align: 'center', alpha: ex(seg(u, .2, 1.0)) });
      disc(1780, 980, 60, C.water, { glow: 20, alpha: ex(seg(u, .4, 1.2)) });   // Earth, under the curve of the horizon
      text(b.earth, 1780, 880, { size: 30, weight: 700, align: 'center', color: C.water, alpha: ex(seg(u, .4, 1.2)) });
      const p = es(u, 1.0, 3.4), hx = 1300, hy = 760 + Math.pow((hx - 960) / 960, 2) * 120;
      line(320, 740, 320 + (hx - 320) * p, 740 + (hy - 740) * p, { color: C.amara, width: 5, dash: [14, 10] });
      const bk = pop(u, 3.4, 4.2);
      if (bk > 0) { K.ring(hx, hy, 30, C.danger, { width: 5, alpha: Math.min(1, bk) }); text(b.blocked, hx, hy - 60, { size: 32, weight: 800, color: C.danger, align: 'center', alpha: Math.min(1, bk) }); }
    },
    // A relay on a tall peak sees the base and Earth; repeaters carry the signal along the road.
    relay(g, u, b) {
      const { C, text, line, disc, ex, seg, es, pop, rgba } = K;
      ground(g, C);
      const px = 1100, peak = 360;
      g.beginPath(); g.moveTo(820, 800); g.lineTo(px, peak); g.lineTo(1380, 800); g.closePath(); g.fillStyle = '#8A8682'; g.fill();
      K.rrect(260, 740, 120, 50, 10, C.ivory, null);
      disc(1780, 980, 60, C.water, { glow: 20 });
      const rk = pop(u, .3, 1.2);
      g.save(); g.translate(px, peak); g.scale(rk, rk); K.g.fillStyle = C.ivory; K.g.fillRect(-4, -80, 8, 80); K.g.beginPath(); K.g.ellipse(0, -92, 34, 14, -.4, 0, Math.PI * 2); K.g.fill(); g.restore();
      text(b.relay, px, peak - 130, { size: 32, weight: 800, align: 'center', alpha: Math.min(1, rk) });
      line(320, 740, px, peak - 80, { color: C.amara, width: 4, dash: [14, 10], p: es(u, 1.0, 2.6) });
      line(px, peak - 80, 1760, 940, { color: C.water, width: 4, dash: [14, 10], p: es(u, 2.4, 4.0) });
      const hk = pop(u, 5.4, 6.2);
      if (hk > 0) { line(px + 120, 800, px + 120, peak - 80, { color: C.accent, width: 3, alpha: Math.min(1, hk) }); text(b.height, px + 140, (800 + peak) / 2, { size: 32, weight: 800, color: C.accent, alpha: Math.min(1, hk) }); }
      // repeaters hop the signal along a road (caption 4)
      const rr = ex(seg(u, 9.8, 10.6));
      for (let i = 0; i < 4; i++) {
        const x = 420 + i * 120, y = 760 + Math.pow((x - 960) / 960, 2) * 120 - 10;
        disc(x, y - 30, 10, C.amara, { glow: 16, alpha: rr * (.5 + .5 * Math.sin(u * 4 - i)) });
        line(x, y, x, y - 30, { color: C.ivory, width: 3, alpha: rr });
      }
      text(b.road, 600, 640, { size: 30, weight: 700, align: 'center', color: C.amara, alpha: rr });
    },
  });
})();
