// Scenes for sci_cold_traps (spec: ../specs/sci_cold_traps.json). Words from the beat's fields; temperatures from D.
Object.assign(SCENES, {
  // A polar crater: the low Sun lights the rim; the floor never sees it.
  shadow(g, u, b) {
    const { C, text, line, poly, disc, es, ex, seg, rgba, lerp } = K;
    const prof = [[0, 520], [300, 470], [560, 400], [700, 420], [860, 640], [1060, 720], [1260, 720], [1420, 600], [1560, 430], [1700, 410], [1920, 440]];
    const ground = () => { g.beginPath(); g.moveTo(0, 1080); prof.forEach(([x, y]) => g.lineTo(x, y)); g.lineTo(1920, 1080); g.closePath(); };
    const k0 = es(u, 0, 1.0), sweep = Math.sin(u * .5) * 10;                 // the Sun rolls along the horizon
    ground(); const tg = g.createLinearGradient(0, 400, 0, 900); tg.addColorStop(0, C.regolith); tg.addColorStop(1, '#161616'); g.fillStyle = tg; g.fill();
    g.save(); ground(); g.clip();
    g.beginPath(); g.moveTo(700, 420); g.lineTo(1920, 420 + 1220 * .02); g.lineTo(1920, 1080); g.lineTo(760, 1080); g.closePath();
    g.fillStyle = rgba(C.space, .78); g.fill(); g.restore();
    disc(60, 360 + sweep, 60, C.accent, { glow: 80, alpha: k0 });
    for (let i = 0; i < 6; i++) line(120, 330 + sweep + i * 12, lerp(120, 1560, es(u, .4 + i * .08, 1.8 + i * .08)), 330 + sweep + i * 12 + 1440 * .02, { color: rgba(C.accent, .55), width: 3 });
    poly([[560, 400], [700, 420]], 1, { color: C.accent, width: 8, glow: 24, alpha: ex(seg(u, 1.6, 2.4)) });
    poly([[1560, 430], [1700, 410], [1800, 415]], 1, { color: C.accent, width: 8, glow: 24, alpha: ex(seg(u, 1.8, 2.6)) });
    text(b.sun, 60, 270, { size: 30, weight: 700, color: C.accent, align: 'center', alpha: ex(seg(u, .4, 1.2)) });
    text(b.rim, 1660, 360, { size: 30, weight: 700, color: C.accent, align: 'center', alpha: ex(seg(u, 2.2, 3.0)) });
    text(b.floor, 1160, 690, { size: 34, weight: 800, align: 'center', alpha: ex(seg(u, 4.6, 5.4)) });
    // frost glints on the dark floor
    for (let i = 0; i < 14; i++) disc(900 + (i * 97) % 460, 700 + (i * 37) % 16, 3, C.ivory, { alpha: ex(seg(u, 5.4, 6.4)) * (.4 + .6 * Math.sin(u * 3 + i) ** 2) });
  },

  // A thermometer falls past both published temperatures; ice stays frozen.
  thermo(g, u, b) {
    const { C, text, line, disc, es, ex, seg, pop, rgba, lerp } = K;
    const lo = -260, hi = 20, x = 640, yTop = 190, yBot = 780, Y = v => lerp(yBot, yTop, (v - lo) / (hi - lo));
    K.rrect(x - 36, yTop - 20, 72, yBot - yTop + 40, 36, rgba(C.ivory, .08), rgba(C.ivory, .6));
    const temp = lerp(hi, D.c, es(u, .4, 8.8));
    K.rrect(x - 20, Y(temp), 40, yBot - Y(temp) + 10, 20, C.amara, null);
    disc(x, yBot + 30, 52, C.amara, { glow: 20 });
    for (const v of [0, -100, -200]) {
      line(x + 44, Y(v), x + 70, Y(v), { color: C.muted, width: 2 });
      text((v < 0 ? '−' : '') + Math.abs(v) + ' °C', x + 84, Y(v) + 10, { size: 26, color: C.muted, mono: true });
    }
    for (const [v, label, t0] of [[D.floor_c, b.a, .4], [D.c, b.b, 4.8]]) {
      const k = pop(u, t0, t0 + .9);
      if (k <= 0) continue;
      line(x + 40, Y(v), 1000, Y(v), { color: C.ivory, width: 2, dash: [8, 8], alpha: Math.min(1, k) });
      text(label, 1020, Y(v) + 12, { size: 34, weight: 700, alpha: Math.min(1, k) });
    }
    // ice crystal that stays put
    const ik = pop(u, 9.2, 10.1);
    if (ik > 0) {
      g.save(); g.translate(1500, 330); g.scale(ik, ik); g.rotate(u * .2);
      for (let i = 0; i < 6; i++) { g.rotate(Math.PI / 3); line(0, 0, 0, -70, { color: C.ivory, width: 6 }); line(0, -40, 18, -56, { color: C.ivory, width: 4 }); line(0, -40, -18, -56, { color: C.ivory, width: 4 }); }
      g.restore();
      text(b.ice, 1500, 460, { size: 32, weight: 700, align: 'center', alpha: Math.min(1, ik) });
    }
  },
});
