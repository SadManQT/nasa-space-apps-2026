// Scenes for sci_moonquakes (spec: ../specs/sci_moonquakes.json). Words from the beat's fields; quakes from D (Apollo PSE).
Object.assign(SCENES, {
  // A seismometer trace across the Apollo years: one burst per shallow moonquake, height by magnitude.
  seismo(g, u, b) {
    const { C, text, line, disc, es, ex, seg, pop, rgba, lerp } = K;
    const qs = D.quakes, t0 = Date.parse(qs[0].date), t1 = Date.parse(qs[qs.length - 1].date);
    const x0 = 220, x1 = 1700, y = 520, X = d => lerp(x0, x1, (Date.parse(d) - t0) / (t1 - t0));
    const p = es(u, .6, 9.0), head = lerp(x0, x1, p);
    // the trace: a quiet hum, with a decaying burst at each quake already passed
    g.save(); g.beginPath(); g.moveTo(x0, y);
    for (let x = x0; x <= head; x += 2) {
      let a = Math.sin(x * .9) * 2 + Math.sin(x * .37 + u * 3) * 2;
      for (const q of qs) { const dx = x - X(q.date); if (dx >= 0 && dx < 40) a += Math.sin(dx * 1.7) * q.magnitude * 38 * Math.exp(-dx / 10); }
      g.lineTo(x, y + a);
    }
    g.strokeStyle = C.caution; g.lineWidth = 3; g.stroke(); g.restore();
    disc(head, y, 8, C.caution, { glow: 16, alpha: p < 1 ? 1 : 0 });
    line(x0, y + 170, x1, y + 170, { color: C.muted, width: 2, alpha: ex(seg(u, 0, .8)) });
    for (let yr = +qs[0].date.slice(0, 4); yr <= +qs[qs.length - 1].date.slice(0, 4); yr++) {
      const xx = X(yr + '-07-01'); if (xx < x0 || xx > x1) continue;
      text(String(yr), xx, y + 210, { size: 26, color: C.muted, align: 'center', mono: true, alpha: ex(seg(u, 0, .8)) });
    }
    text(b.trace, x0, 250, { size: 30, weight: 600, color: C.muted, alpha: ex(seg(u, .2, 1.0)) });
    // the tally and the strongest event
    const passed = qs.filter(q => X(q.date) <= head).length;
    K.panel(1240, 200, 460, 110, ex(seg(u, 4.6, 5.4)));
    text(b.count_l.replace(/^\d+/, String(passed)), 1470, 270, { size: 40, weight: 800, align: 'center', alpha: ex(seg(u, 4.6, 5.4)) });
    const top = qs.reduce((m, q) => (q.magnitude > m.magnitude ? q : m), qs[0]), mk = pop(u, 9.4, 10.3);
    if (mk > 0) {
      K.ring(X(top.date), y, 30 + 20 * Math.min(1, mk), C.ivory, { width: 3 });
      text(b.max_l, X(top.date), y - 170, { size: 32, weight: 700, align: 'center', alpha: Math.min(1, mk) });
    }
  },

  // A shelf in a quake: loose things fall, latched things stay.
  shelf(g, u, b) {
    const { C, text, line, disc, es, ex, seg, rgba } = K;
    const shake = Math.sin(u * 28) * 14 * es(u, .6, 1.0) * (1 - es(u, 6.0, 7.0));
    for (const [cx, label, latched] of [[620, b.loose, false], [1300, b.latched, true]]) {
      g.save(); g.translate(cx + shake, 0);
      K.rrect(-260, 300, 520, 20, 6, C.regolith, null);                   // the shelf
      K.rrect(-260, 540, 520, 20, 6, C.regolith, null);
      for (let i = 0; i < 3; i++) {
        const fall = latched ? 0 : Math.max(0, (u - 1.2 - i * .5)) ** 2 * 180, x = -170 + i * 170;
        const y = Math.min(300 - 70 + fall, 690), rot = latched ? 0 : Math.min(1.2, fall / 300) * (i % 2 ? 1 : -1);
        g.save(); g.translate(x, y + 35); g.rotate(rot);
        K.rrect(-50, -35, 100, 70, 10, [C.water, C.accent, C.amara][i], rgba(C.ivory, .5));
        g.restore();
        if (latched) line(x - 60, 270, x + 60, 270, { color: C.good, width: 6 });
      }
      g.restore();
      text(label, cx, 860, { size: 36, weight: 800, align: 'center', color: latched ? C.good : C.danger, alpha: ex(seg(u, 1.0, 1.8)) });
    }
  },
});
