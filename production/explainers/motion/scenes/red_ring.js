// Scenes for sci_red_ring (spec: ../specs/sci_red_ring.json). Words from the beat's fields; minutes from SPEC.v.
Object.assign(SCENES, {
  // Sun, Earth and Moon line up; the Moon slides into Earth's shadow cone.
  line_up(g, u, b) {
    const { C, text, disc, ex, seg, es, rgba, lerp } = K;
    disc(160, 460, 120, C.accent, { glow: 90, alpha: ex(seg(u, 0, .8)) });
    text(b.sun, 160, 640, { size: 30, weight: 700, color: C.accent, align: 'center', alpha: ex(seg(u, .2, 1.0)) });
    disc(980, 460, 70, C.water, { glow: 20, alpha: ex(seg(u, .4, 1.2)) });
    text(b.earth, 980, 580, { size: 30, weight: 700, align: 'center', alpha: ex(seg(u, .6, 1.4)) });
    // the shadow cone behind Earth
    const sk = ex(seg(u, 4.6, 5.6));
    g.save(); g.globalAlpha *= sk; g.beginPath(); g.moveTo(980, 390); g.lineTo(1800, 430); g.lineTo(1800, 490); g.lineTo(980, 530); g.closePath();
    const sg = g.createLinearGradient(980, 0, 1800, 0); sg.addColorStop(0, rgba(C.ink, .9)); sg.addColorStop(1, rgba(C.danger, .25)); g.fillStyle = sg; g.fill(); g.restore();
    text(b.shadow, 1400, 360, { size: 30, weight: 700, align: 'center', alpha: sk });
    const mx = lerp(1700, 1500, es(u, 1.0, 10.0)), inShadow = es(u, 6.0, 9.0);
    disc(mx, 460, 34, `rgb(${Math.round(lerp(200, 150, inShadow))},${Math.round(lerp(196, 70, inShadow))},${Math.round(lerp(190, 60, inShadow))})`);
    text(b.moon, mx, 540, { size: 30, weight: 700, align: 'center', alpha: ex(seg(u, .8, 1.6)) });
  },

  // Standing on the Moon: Earth slides over the Sun and a thin red ring of sunlight bends through its air.
  view(g, u, b) {
    const { C, text, disc, ring, es, ex, seg, pop, rgba, lerp } = K;
    const cx = 700, cy = 430, ex0 = lerp(cx - 560, cx, es(u, .4, 4.2));
    const SUN = 64, EARTH = 236;   // from the Moon, Earth looks about 3.7 times as wide as the Sun
    const cover = 1 - Math.min(1, Math.max(0, Math.abs(ex0 - cx) - (EARTH - SUN)) / (2 * SUN));
    disc(cx, cy, SUN, C.accent, { glow: 90 * (1 - cover) + 6, alpha: 1 });
    disc(ex0, cy, EARTH, '#0A0D16');                                         // Earth's night side
    ring(ex0, cy, EARTH, rgba(C.water, .55), { width: 3 });                 // its faint edge, so the eye can follow it
    const rk = ex(seg(u, 4.8, 6.4));
    if (rk > 0) { ring(ex0, cy, EARTH + 2, C.danger, { width: 8, alpha: rk }); ring(ex0, cy, EARTH + 8, rgba(C.caution, .5), { width: 4, alpha: rk }); K.g.save(); K.g.shadowColor = C.danger; K.g.shadowBlur = 40 * rk; ring(ex0, cy, EARTH + 4, C.danger, { width: 3, alpha: rk }); K.g.restore(); }
    text(b.view, cx, 700, { size: 30, weight: 700, color: C.muted, align: 'center', alpha: ex(seg(u, .2, 1.0)) });
    const tk = pop(u, 9.6, 10.5);
    if (tk > 0) { K.panel(1180, 220, 560, 100, Math.min(1, tk)); text(b.total_l, 1460, 284, { size: 36, weight: 800, align: 'center', alpha: Math.min(1, tk) }); }
    // a solar-power meter falling to almost nothing as Earth covers the Sun
    const level = 1 - .96 * cover, mk = ex(seg(u, 1.0, 1.8));
    K.rrect(1260, 420, 400, 40, 20, rgba(C.ivory, .12), null);
    K.rrect(1260, 420, Math.max(8, 400 * level), 40, 20, C.accent, null);
    text(b.power, 1260, 400, { size: 28, weight: 700, color: C.accent, alpha: mk });
  },
});
