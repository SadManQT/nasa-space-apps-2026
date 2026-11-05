// Scenes for sci_impact_flashes (spec: ../specs/sci_impact_flashes.json). Words from the beat's fields; counts from SPEC.v.
(() => {
  function moon(cx, cy, r, u) {
    const { g, disc, rgba, C } = K;
    disc(cx, cy, r, '#2B2C30');
    g.save(); g.beginPath(); g.arc(cx, cy, r, 0, Math.PI * 2); g.clip();
    const lit = g.createLinearGradient(cx + r * .2, 0, cx + r, 0); lit.addColorStop(0, rgba(C.ivory, 0)); lit.addColorStop(1, rgba(C.ivory, .8));
    g.fillStyle = lit; g.fillRect(cx, cy - r, r, 2 * r);                      // a thin sunlit crescent; the rest is the dark side
    g.restore();
  }
  function scope(x, y, ang, label, alpha = 1) {
    const { g, C, text } = K;
    g.save(); g.globalAlpha *= alpha; g.translate(x, y); g.rotate(ang);
    K.rrect(-14, -110, 28, 120, 8, C.ivory, null); K.rrect(-26, -130, 52, 30, 8, C.ivory, null); g.restore();
    K.line(x - 40, y + 40, x, y, { color: C.muted, width: 4, alpha }); K.line(x + 40, y + 40, x, y, { color: C.muted, width: 4, alpha });
    if (label) text(label, x, y + 84, { size: 28, weight: 700, align: 'center', alpha });
  }
  // flash times in beat seconds, and their spots on the dark side
  const FLASHES = [[3.2, -.3, .1], [5.6, -.5, -.3], [7.1, -.1, .4], [9.0, -.6, .2], [11.2, -.2, -.5], [12.4, -.45, .45]];

  Object.assign(SCENES, {
    // Two telescopes watch the dark side; a few brief flashes; the tally of confirmed flashes.
    watch(g, u, b) {
      const { C, text, disc, ring, ex, seg, pop } = K;
      const cx = 1100, cy = 420, r = 260;
      moon(cx, cy, r, u);
      text(b.dark, cx - 60, cy + r + 60, { size: 30, weight: 700, color: C.muted, align: 'center', alpha: ex(seg(u, .4, 1.2)) });
      scope(300, 760, .5, b.scope, ex(seg(u, .2, 1.0))); scope(470, 780, .45, null, ex(seg(u, .4, 1.2)));
      for (const [t0, dx, dy] of FLASHES) {
        const f = seg(u, t0, t0 + .5);
        if (f <= 0 || f >= 1) continue;
        const x = cx + dx * r, y = cy + dy * r;
        disc(x, y, 6 + 26 * (1 - f), C.ivory, { glow: 40, alpha: 1 - f });
        ring(x, y, 10 + 60 * f, C.accent, { width: 3, alpha: 1 - f });
        if (t0 === 3.2) text(b.flash, x, y - 60, { size: 40, weight: 800, align: 'center', color: C.accent, alpha: 1 - f });
      }
      const ck = pop(u, 9.4, 10.3);
      if (ck > 0) { K.panel(1180, 760, 620, 100, Math.min(1, ck)); text(b.count_l, 1490, 824, { size: 38, weight: 800, align: 'center', alpha: Math.min(1, ck) }); }
    },

    // The two-telescope rule: a flash both see is kept; one only one sees is thrown out.
    check(g, u, b) {
      const { C, text, disc, line, ex, seg, pop, rgba } = K;
      for (const [cx, label] of [[560, b.a], [1360, b.b]]) {
        K.rrect(cx - 280, 200, 560, 400, 24, rgba(C.ivory, .04), rgba(C.ivory, .4));
        text(label, cx, 650, { size: 32, weight: 700, align: 'center' });
      }
      // case 1: a real flash in both views at the same moment; case 2: a speck in A only
      const fake = seg(u, .8, 1.4), real = seg(u, 5.4, 6.0);   // caption 1: a glitch; caption 2: the agreed flash
      for (const cx of [560, 1360]) if (real > 0 && real < 1) disc(cx - 60, 360, 8 + 24 * (1 - real), C.ivory, { glow: 30, alpha: 1 - real });
      if (fake > 0 && fake < 1) disc(640, 470, 6 + 18 * (1 - fake), C.ivory, { glow: 24, alpha: 1 - fake });
      const fk = pop(u, 1.6, 2.4), rk = pop(u, 6.2, 7.0);
      if (rk > 0) { line(560 - 60, 360, 1360 - 60, 360, { color: C.good, width: 4, dash: [10, 10], alpha: Math.min(1, rk) }); text(b.real, 960, 760, { size: 38, weight: 800, align: 'center', color: C.good, alpha: Math.min(1, rk) }); }
      if (fk > 0) { const fa = Math.min(1, fk) * (1 - ex(seg(u, 5.0, 5.4))); K.ring(640, 470, 40, C.danger, { width: 5, alpha: fa }); line(610, 440, 670, 500, { color: C.danger, width: 5, alpha: fa }); text(b.fake, 960, 760, { size: 38, weight: 800, align: 'center', color: C.danger, alpha: Math.min(1, fk) * (1 - ex(seg(u, 5.0, 5.4))) }); }
    },
  });
})();
