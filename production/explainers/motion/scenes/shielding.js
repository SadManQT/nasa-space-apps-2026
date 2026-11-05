// Scenes for sci_shielding (spec: ../specs/sci_shielding.json). Words from the beat's fields; doses from D (Clowdsley 2021 model).
Object.assign(SCENES, {
  // Fast protons slow down in a water wall; the thicker the wall, the fewer get through.
  stop(g, u, b) {
    const { C, text, disc, line, es, ex, seg, pop, rgba, rng } = K;
    const layers = 1 + Math.floor(es(u, 8.6, 11.6) * 3.999);            // a thicker wall builds during caption 3
    const wx = 900, lw = 70;
    for (let i = 0; i < layers; i++) {
      const k = pop(u, i === 0 ? .4 : 8.6 + (i - 1) * 1, i === 0 ? 1.3 : 9.5 + (i - 1) * 1);
      K.rrect(wx + i * (lw + 8), 230 + (1 - Math.min(1, k)) * 40, lw, 520, 14, rgba(C.water, .55 + .1 * i), rgba(C.ivory, .5));
    }
    text(b.wall, wx + (layers * (lw + 8)) / 2, 800, { size: 32, weight: 700, color: C.water, align: 'center', alpha: ex(seg(u, .6, 1.4)) });
    text(b.protons, 200, 200, { size: 32, weight: 700, color: C.caution, alpha: ex(seg(u, .3, 1.1)) });
    // particles: each has its own depth; each layer it crosses lowers its chance to continue
    const R = rng(11), N = 46, depthCap = layers * (lw + 8);
    let through = 0, sent = 0;
    for (let i = 0; i < N; i++) {
      const y = 260 + R() * 460, survive = R(), t0 = .6 + i * .22, p = (u - t0) / 2.2;
      if (p <= 0) continue;
      sent++;
      const stopAt = survive < .5 ** layers ? 2000 : (wx + depthCap * survive);  // stopped somewhere inside the wall
      const x = Math.min(120 + p * 1500, stopAt);
      const stopped = x >= stopAt - 1 && stopAt < 2000;
      if (!stopped && x > wx + depthCap) through++;
      const a = stopped ? Math.max(0, 1 - (p - (stopAt - 120) / 1500) * 3) : 1;
      if (a <= 0 || x > 1880) continue;
      line(x - 50, y, x, y, { color: rgba(C.caution, .35 * a), width: 6 });
      disc(x, y, 9, C.caution, { glow: 14, alpha: a });
    }
    text(b.through, 1500, 200, { size: 32, weight: 700, alpha: ex(seg(u, 9.2, 10.0)) });
  },

  // Model dose behind 5, 7, 10 and 15 g/cm² in the August 1972 storm: thicker walls, lower dose, never zero.
  chart(g, u, b) {
    const { C, text, line, es, ex, seg, pop, rgba } = K;
    const keys = Object.keys(D.dose).sort((a, c) => +a - +c), max = Math.max(...keys.map(k => D.dose[k]));
    const x0 = 420, x1 = 1500, yTop = 200, yBot = 720, bw = 150;
    const Y = v => yBot - v / (max * 1.1) * (yBot - yTop);
    const ak = ex(seg(u, 0, .8));
    g.save(); g.globalAlpha *= ak;
    line(x0, yBot, x1, yBot, { color: C.muted, width: 3 });
    for (const v of [50, 100, 150, 200]) {
      line(x0, Y(v), x1, Y(v), { color: rgba(C.ivory, .1), width: 2 });
      text(String(v), x0 - 20, Y(v) + 10, { size: 26, color: C.muted, align: 'right', mono: true });
    }
    text(b.y_title, x0, yTop - 40, { size: 30, weight: 600, color: C.muted });
    text(b.x_title + ' (' + b.unit + ')', (x0 + x1) / 2, yBot + 96, { size: 28, weight: 600, color: C.muted, align: 'center' });
    g.restore();
    keys.forEach((k, i) => {
      const x = x0 + 80 + i * ((x1 - x0 - 160) / (keys.length - 1)) - bw / 2, gk = pop(u, 1.0 + i * .5, 2.0 + i * .5);
      const top = yBot - (yBot - Y(D.dose[k])) * Math.min(1.06, gk);
      K.rrect(x, Math.min(top, yBot - 2), bw, Math.max(2, yBot - top), 12, i === 0 ? C.danger : i === keys.length - 1 ? C.good : C.caution, null);
      text(k + ' ' + b.unit, x + bw / 2, yBot + 44, { size: 28, weight: 700, align: 'center', alpha: ak });
      text(String(Math.round(D.dose[k])), x + bw / 2, top - 18, { size: 34, weight: 800, align: 'center', alpha: ex(seg(u, 1.6 + i * .5, 2.4 + i * .5)) });
    });
    // never zero: a floor line under the shortest bar
    const zk = ex(seg(u, 9.8, 10.8));
    if (zk > 0) {
      const lo = Math.min(...keys.map(k => D.dose[k]));
      line(x0, Y(lo), x1, Y(lo), { color: C.ivory, width: 2, dash: [8, 8], alpha: zk });
      text(b.zero, x1 + 16, Y(lo) + 10, { size: 30, weight: 700, alpha: zk });
    }
  },

  // Shield, hurry, stay: the three habits that keep a storm dose low.
  alara(g, u, b) {
    const { C, text, pop, ex, seg } = K;
    [b.a, b.b, b.c].forEach((label, i) => {
      const k = pop(u, .3 + i * .7, 1.2 + i * .7), x = 420 + i * 540;
      g.save(); g.translate(x, 440); g.scale(k, k);
      K.rrect(-200, -150, 400, 300, 28, C.glass, C.glass_edge);
      K.rrect(-60, -110, 120, 120, 60, [C.water, C.caution, C.good][i], null);
      text(String(i + 1), 0, -30, { size: 64, weight: 800, align: 'center', color: C.ink });
      text(label, 0, 90, { size: 40, weight: 800, align: 'center' });
      g.restore();
    });
  },
});
