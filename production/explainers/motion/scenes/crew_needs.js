// Scenes for sci_crew_needs (spec: ../specs/sci_crew_needs.json). Words from the beat's fields; data from D (NASA BVAD).
(() => {
  // a friendly, faceless crew silhouette
  function person(x, y, s, col, alpha = 1) {
    const { g, disc } = K;
    g.save(); g.globalAlpha *= alpha; g.translate(x, y); g.scale(s, s);
    disc(0, -150, 46, col);
    K.rrect(-62, -96, 124, 170, 52, col, null);
    g.restore();
  }
  const ITEMS = () => [["o2", K.C.amara], ["water", K.C.water], ["food", K.C.accent]];

  Object.assign(SCENES, {
    // One person, one day: oxygen, water and food in, carbon dioxide out, each bar scaled to its mass.
    day(g, u, b) {
      const { C, text, line, disc, ex, seg, pop, es, rgba } = K;
      const k = pop(u, .2, 1.1);
      person(470, 560, 1.5 * k, C.ivory, Math.min(1, k));
      text(b.who, 470, 760, { size: 32, weight: 700, align: 'center', alpha: ex(seg(u, .6, 1.4)) });
      const max = D.water, starts = { o2: 4.8, water: 8.6, food: 9.4 };
      ITEMS().forEach(([key, col], i) => {
        const t0 = starts[key], y = 300 + i * 170, kk = pop(u, t0, t0 + .9);
        if (kk <= 0) return;
        const w = 620 * D[key] / max * Math.min(1, es(u, t0, t0 + 1.4));
        text(b[key + '_l'], 900, y - 26, { size: 32, weight: 700, color: col, alpha: Math.min(1, kk) });
        K.rrect(900, y, Math.max(16, w), 54, 27, col, null);
        text(b[key + '_v'], 900 + Math.max(16, w) + 24, y + 40, { size: 40, weight: 800, alpha: ex(seg(u, t0 + .6, t0 + 1.3)) });
        // a dotted flow into the person
        g.save(); g.setLineDash([6, 14]); g.lineDashOffset = u * 40;
        line(880, y + 27, 600, 470, { color: rgba(col, .5), width: 4, alpha: Math.min(1, kk) }); g.restore();
      });
      // carbon dioxide puffs out to the left
      const ck = ex(seg(u, 12.4, 13.2));
      if (ck > 0) {
        for (let i = 0; i < 6; i++) {
          const p = ((u - 12.4) * .5 + i / 6) % 1;
          disc(380 - p * 240, 420 - p * 120 + Math.sin(i * 2 + u) * 12, 18 + p * 22, rgba(C.muted, .55 * (1 - p)), { alpha: ck });
        }
        text(b.co2_l, 170, 250, { size: 30, weight: 700, color: C.muted, alpha: ck });
        text(b.co2_v, 170, 296, { size: 40, weight: 800, alpha: ck });
      }
    },

    // A crew of four: the same daily need, four times over; lose any one and the crew cannot stay.
    crew(g, u, b) {
      const { C, text, ex, seg, pop, es } = K;
      const miss = es(u, 4.4, 5.4);
      for (let i = 0; i < 4; i++) {
        const k = pop(u, .2 + i * .25, 1.1 + i * .25), x = 360 + i * 400;
        person(x, 470, 1.1 * k, C.ivory, Math.min(1, k) * (1 - .55 * miss));
        ITEMS().forEach(([key, col], j) => {
          const full = 190 * D[key] / D.water * Math.min(1, es(u, .8 + i * .25, 1.8 + i * .25));
          const h = key === 'water' ? full * (1 - miss) : full;
          K.rrect(x - 84 + j * 60, 800 - h, 48, Math.max(6, h), 10, key === 'water' && miss > .5 ? C.danger : col, null);
        });
      }
      const bk = pop(u, 1.6, 2.6);
      if (bk > 0) {
        K.panel(760, 170, 400, 96, Math.min(1, bk));
        text(b.times, 960, 236, { size: 44, weight: 800, align: 'center', color: C.accent, alpha: Math.min(1, bk) });
      }
      text(b.missing, 960, 866, { size: 36, weight: 700, align: 'center', color: C.danger, alpha: ex(seg(u, 4.8, 5.6)) });
    },

    // Where the numbers stop: planning values, simpler game units.
    limits(g, u, b) {
      const { C, text, ex, seg, pop, wrap } = K;
      const k = pop(u, .1, 1.0);
      g.save(); g.translate(960, 440); g.scale(k, k); g.translate(-960, -440);
      K.panel(460, 320, 1000, 240);
      wrap(b.card, 880, 44, 700).forEach((l, i) => text(l, 960, 420 + i * 54, { size: 44, weight: 700, align: 'center', color: C.accent }));
      text(b.sub, 960, 512, { size: 30, weight: 600, align: 'center', alpha: ex(seg(u, .6, 1.4)) * Math.min(1, k) });
      g.restore();
    },
  });
})();
