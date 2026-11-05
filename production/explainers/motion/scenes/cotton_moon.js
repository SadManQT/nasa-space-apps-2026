// Scenes for sci_cotton_moon (spec: ../specs/sci_cotton_moon.json). Canon: plants never have faces.
Object.assign(SCENES, {
  // The lander, a sealed can, and a seed that sprouts into a seedling: sprouted yes, flowered no.
  can(g, u, b) {
    const { C, text, line, disc, es, ex, seg, pop, rgba } = K;
    const gy = 800;
    g.fillStyle = rgba(C.regolith, .5); g.fillRect(0, gy, 1920, 280); line(0, gy, 1920, gy, { color: C.muted, width: 3 });
    // lander on the left
    const lk = pop(u, .2, 1.1), lm = Math.min(1, lk);
    g.save(); g.globalAlpha *= lm;
    K.rrect(220, 600, 260, 140, 14, '#C8A24A', null);
    for (const x of [230, 470]) line(x, 740, x - 40 * Math.sign(x - 350), gy, { color: C.ivory, width: 6 });
    K.rrect(180, 610, 40, 110, 6, C.water, null); K.rrect(480, 610, 40, 110, 6, C.water, null);
    g.restore();
    text(b.lander, 350, 560, { size: 28, weight: 700, align: 'center', alpha: ex(seg(u, .6, 1.4)) });
    // the sealed can, zoomed big on the right
    const ck = pop(u, 4.6, 5.6), cm = Math.min(1, ck), cx = 1220, cy = 470;
    if (ck > 0) {
      g.save(); g.translate(cx, cy); g.scale(ck, ck);
      K.rrect(-220, -260, 440, 520, 60, rgba(C.ivory, .07), rgba(C.ivory, .65));
      K.rrect(-200, 140, 400, 100, 20, '#5A4632', null);                      // soil
      const gr = es(u, 5.6, 12.0), h = 20 + 230 * gr, sway = Math.sin(u * 1.3) * 4;
      if (gr < .05) disc(0, 140, 12, '#E8E0CC');
      else {
        line(0, 140, sway, 140 - h, { color: C.good, width: 8 });
        for (const side of [-1, 1]) { g.save(); g.translate(sway, 140 - h); g.rotate(side * .6); g.beginPath(); g.ellipse(side * 30, 0, 36, 16, 0, 0, Math.PI * 2); g.fillStyle = C.good; g.fill(); g.restore(); }
      }
      g.restore();
      text(b.can, cx, cy + 320, { size: 30, weight: 700, align: 'center', alpha: cm });
      K.line(470, 640, cx - 220, cy, { color: rgba(C.ivory, .25), width: 2, dash: [8, 8], alpha: cm });
    }
    const yk = pop(u, 9.4, 10.2), nk = pop(u, 14.2, 15.0);
    if (yk > 0) text(b.yes, 1600, 300, { size: 40, weight: 800, color: C.good, alpha: Math.min(1, yk) });
    if (nk > 0) text(b.no, 1600, 370, { size: 40, weight: 800, color: C.danger, alpha: Math.min(1, nk) });
  },
});
