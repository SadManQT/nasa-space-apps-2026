// Scenes for sci_proton_flux_chart (spec: ../specs/sci_proton_flux_chart.json). Every on-screen word comes from the
// beat's fields; data comes from D (fixture series and derived values). Axis tick values are the only literals.
// Timings inside a scene are beat seconds (u) and follow the spec's captions.
(() => {
  const LOG_LO = -1, LOG_HI = 4;                                             // 0.1 .. 10,000 pfu
  const fmtTick = v => (v < 1 ? v.toString() : v.toLocaleString('en-US'));
  const hoursSince = (iso, t0) => (Date.parse(iso) - Date.parse(t0)) / 3.6e6;

  function sun(x, y, r, u, alpha = 1) {
    const { C, disc, line, rgba } = K;
    for (let i = 0; i < 14; i++) {                                           // slow-turning corona spikes
      const a = i / 14 * Math.PI * 2 + u * .25, l = r * (1.35 + .15 * Math.sin(u * 2 + i));
      line(x + Math.cos(a) * r * 1.05, y + Math.sin(a) * r * 1.05, x + Math.cos(a) * l, y + Math.sin(a) * l, { color: rgba(C.accent, .55), width: 6, alpha });
    }
    disc(x, y, r, C.accent, { glow: 70, alpha });
  }
  function earth(x, y, r, alpha = 1) {
    const { C, g, disc, rgba } = K;
    const eg = g.createRadialGradient(x - r * .5, y - r * .3, r * .1, x, y, r);
    eg.addColorStop(0, '#5DB7E8'); eg.addColorStop(.6, C.water); eg.addColorStop(1, '#0E2C46');
    disc(x, y, r, eg, { alpha });
    g.save(); g.globalAlpha *= alpha * .5; g.strokeStyle = C.ivory; g.lineWidth = 6; g.lineCap = 'round';
    for (const [a0, a1, rr] of [[3.6, 4.4, .55], [.2, 1.0, .7], [2.0, 2.6, .35]]) { g.beginPath(); g.arc(x, y, r * rr, a0, a1); g.stroke(); }
    g.restore();
  }
  function satellite(x, y, s = 1, alpha = 1) {
    const { C, g } = K;
    g.save(); g.globalAlpha *= alpha; g.translate(x, y); g.scale(s, s);
    g.fillStyle = C.water; g.fillRect(-92, -12, 60, 24); g.fillRect(32, -12, 60, 24);
    g.strokeStyle = C.ivory; g.lineWidth = 2; g.strokeRect(-92, -12, 60, 24); g.strokeRect(32, -12, 60, 24);
    g.fillStyle = C.ivory; g.fillRect(-26, -20, 52, 40);
    g.fillStyle = C.signal; g.fillRect(-26, -6, 10, 12);                     // the detector, facing the Sun
    g.restore();
  }

  Object.assign(SCENES, {
    // A weather satellite near Earth counts fast protons from the Sun.
    detector(g, u, b) {
      const { C, text, disc, ring, ex, seg, pop, lerp, rgba, wrap } = K;
      const k = ex(seg(u, 0, .8));
      sun(150, 470, 110, u, k);
      text(b.sun, 150, 660, { size: 32, weight: 600, color: C.accent, align: 'center', alpha: k });
      const ex0 = 1380, ey = 500;
      ring(ex0, ey, 320, C.muted, { width: 2, dash: [10, 12], alpha: .6 * k });
      earth(ex0, ey, 120, k);
      text(b.earth, ex0, ey + 180, { size: 32, weight: 600, align: 'center', alpha: k });
      const a = Math.PI + .25 - u * .03, sx = ex0 + Math.cos(a) * 320, sy = ey + Math.sin(a) * 320;
      const sk = pop(u, .3, 1.3);
      satellite(sx, sy, sk, Math.min(1, sk));
      wrap(b.sat, 420, 30, 600).forEach((l, i) => text(l, sx, sy - 82 + i * 36 - 36, { size: 30, weight: 600, align: 'center', alpha: ex(seg(u, 1.0, 1.8)) }));
      // protons: little glowing balls with trails, each one counted as it hits the detector
      const N = 36; let hits = 0;
      for (let i = 0; i < N; i++) {
        const t0 = .8 + i * .17, p = (u - t0) / 1.3;
        if (p >= 1) { hits++; continue; }
        if (p <= 0) continue;
        const wig = Math.sin(i * 7.3 + p * 6) * 26 * (1 - p);
        const x = lerp(270, sx - 30, p), y = lerp(470 + ((i * 37) % 120) - 60, sy, p) + wig;
        K.line(x - 46, y, x, y, { color: rgba(C.caution, .35), width: 6 });
        disc(x, y, 9, C.caution, { glow: 16 });
      }
      for (let i = 0; i < N; i++) {                                          // a ripple at each hit
        const tHit = .8 + i * .17 + 1.3, q = seg(u, tHit, tHit + .5);
        if (q > 0 && q < 1) ring(sx - 22, sy, 14 + 40 * q, C.caution, { width: 3, alpha: 1 - q });
      }
      // the tally: a bar that fills, never a made-up number
      const bk = ex(seg(u, 1.6, 2.4)), bx = sx - 170, by = sy + 110;
      if (bk > 0) {
        K.panel(bx - 24, by - 56, 388, 104, bk);
        g.save(); g.globalAlpha *= bk;
        text(b.count, bx, by - 16, { size: 26, weight: 600, color: C.muted });
        K.rrect(bx, by, 340, 22, 11, rgba(C.ivory, .12), null);
        K.rrect(bx, by, Math.max(22, 340 * hits / N), 22, 11, C.caution, null);
        g.restore();
      }
    },

    // A normal axis hides the quiet day; a log axis shows the quiet day and the storm together.
    logscale(g, u, b) {
      const { C, text, line, ring, es, ex, seg, pop, lerp, rgba } = K;
      const x0 = 520, x1 = 1400, yTop = 190, yBot = 760;
      const quiet = D.flux[0][1], storm = Math.max(...D.flux.map(r => r[1]));
      const m = es(u, 4.6, 6.6);                                             // 0 = normal scale, 1 = log scale
      const linY = v => yBot - v / 1500 * (yBot - yTop);
      const logY = v => yBot - (Math.log10(v) - LOG_LO) / (LOG_HI - LOG_LO) * (yBot - yTop);
      const Y = v => lerp(linY(v), logY(v), m);
      const ak = ex(seg(u, 0, .8));
      g.save(); g.globalAlpha *= ak;
      line(x0, yTop - 20, x0, yBot, { color: C.muted, width: 3 }); line(x0, yBot, x1, yBot, { color: C.muted, width: 3 });
      for (const v of [500, 1000, 1500]) {
        line(x0, linY(v), x1, linY(v), { color: rgba(C.ivory, .1 * (1 - m)), width: 2 });
        text(fmtTick(v), x0 - 20, linY(v) + 10, { size: 28, color: C.muted, align: 'right', mono: true, alpha: 1 - m });
      }
      text('0', x0 - 20, yBot + 10, { size: 28, color: C.muted, align: 'right', mono: true, alpha: 1 - m });
      for (let e = LOG_LO; e <= LOG_HI; e++) {
        const v = 10 ** e;
        line(x0, logY(v), x1, logY(v), { color: rgba(C.ivory, .1 * m), width: 2 });
        text(fmtTick(v), x0 - 20, logY(v) + 10, { size: 28, color: C.muted, align: 'right', mono: true, alpha: m });
      }
      text(b.linear, x0, yTop - 50, { size: 32, weight: 700, alpha: 1 - m });
      text(b.log, x0, yTop - 50, { size: 32, weight: 700, color: C.accent, alpha: m });
      g.restore();
      // the two bars grow with a bounce
      const grow = pop(u, .6, 1.8);
      for (const [x, v, label, col] of [[780, quiet, b.quiet, C.good], [1150, storm, b.storm, C.danger]]) {
        const top = lerp(yBot, Y(v), Math.min(1.05, grow));
        K.rrect(x - 70, Math.min(top, yBot - 3), 140, Math.max(3, yBot - top), 10, col, null);
        text(label, x, yBot + 50, { size: 32, weight: 700, align: 'center', color: col, alpha: Math.min(1, grow) });
      }
      // "where did it go?" until the log scale lifts the quiet day into view
      const lk = ex(seg(u, 2.0, 2.8)) * (1 - es(u, 5.4, 6.2));
      if (lk > 0) {
        ring(780, yBot - 40, 56 + 6 * Math.sin(u * 5), C.good, { width: 4, dash: [10, 8], alpha: lk });
        text(b.lost, 780, yBot - 122, { size: 30, weight: 700, align: 'center', alpha: lk });
      }
      // ×10 hops up the log axis
      for (let e = LOG_LO; e < LOG_HI; e++) {
        const hk = pop(u, 6.8 + (e - LOG_LO) * .25, 7.5 + (e - LOG_LO) * .25);
        if (hk <= 0) continue;
        const ya = logY(10 ** e), yb = logY(10 ** (e + 1)), xm = x1 + 40;
        g.save(); g.globalAlpha *= Math.min(1, hk); g.beginPath(); g.arc(xm, (ya + yb) / 2, (ya - yb) / 2, Math.PI / 2, -Math.PI / 2, true);
        g.strokeStyle = C.accent; g.lineWidth = 3; g.stroke(); g.restore();
      }
    },

    // The real 48 hours: the X8.2 flare, the storm line, seventy minutes of warning, then the climb.
    chart(g, u, b) {
      const { C, text, line, poly, disc, ring, es, ex, seg, pop, lerp, rgba, clamp } = K;
      const x0 = 300, x1 = 1600, yTop = 180, yBot = 740, T0 = D.flux[0][0];
      const X = h => x0 + h / 48 * (x1 - x0);
      const Y = v => yBot - (Math.log10(Math.max(v, .1)) - LOG_LO) / (LOG_HI - LOG_LO) * (yBot - yTop);
      const flareH = hoursSince(D.flare_at, T0), crossH = hoursSince(D.cross_at, T0);
      const ak = ex(seg(u, 0, .8));
      g.save(); g.globalAlpha *= ak;
      for (let e = LOG_LO; e <= LOG_HI; e++) {
        line(x0, Y(10 ** e), x1, Y(10 ** e), { color: rgba(C.ivory, .1), width: 2 });
        text(fmtTick(10 ** e), x0 - 20, Y(10 ** e) + 10, { size: 26, color: C.muted, align: 'right', mono: true });
      }
      text(b.y_title, x0, yTop - 40, { size: 30, weight: 600, color: C.muted });
      for (let h = 0; h <= 48; h += 12) {                                    // time labels from the fixture's own clock
        const d = new Date(Date.parse(T0) + h * 3.6e6);
        const day = d.toLocaleString('en-GB', { day: 'numeric', month: 'short', timeZone: 'UTC' });
        const hm = d.toISOString().slice(11, 16);
        text(day, X(h), yBot + 42, { size: 26, color: C.muted, align: 'center' });
        text(hm + ' UTC', X(h), yBot + 74, { size: 22, color: C.muted, align: 'center' });
        line(X(h), yBot, X(h), yBot + 10, { color: C.muted, width: 2 });
      }
      g.restore();
      // the cursor walks the clock: to the flare, to the storm line, waits, then the climb
      const hc = u < 4.2 ? lerp(0, flareH, es(u, .4, 3.8)) : u < 7.4 ? lerp(flareH, crossH, es(u, 4.2, 7.0)) : lerp(crossH, 48, es(u, 11.4, 14.6));
      const pts = D.flux.map((r, i) => [X(i + .5), Y(r[1])]);                // hourly means, at the middle of each hour
      const p = clamp((hc - .5) / 47);
      poly(pts, p, { color: C.caution, width: 5, glow: 14 });
      const n = (pts.length - 1) * p, i0 = Math.floor(n), f = n - i0, a = pts[i0], c = pts[Math.min(pts.length - 1, i0 + 1)];
      if (hc > .5 && hc < 47.9) disc(lerp(a[0], c[0], f), lerp(a[1], c[1], f), 13, C.caution, { glow: 26 });
      // the flare: a burst on the clock
      const fk = pop(u, 3.4, 4.3);
      if (fk > 0) {
        line(X(flareH), yBot, X(flareH), yTop + 40, { color: C.accent, width: 3, dash: [8, 8], alpha: Math.min(1, fk) });
        for (let i = 0; i < 10; i++) {
          const ang = i / 10 * Math.PI * 2, r0 = 26 * fk, r1 = (44 + 8 * Math.sin(u * 6 + i)) * fk;
          line(X(flareH) + Math.cos(ang) * r0, yTop + 40 + Math.sin(ang) * r0, X(flareH) + Math.cos(ang) * r1, yTop + 40 + Math.sin(ang) * r1, { color: C.accent, width: 5 });
        }
        disc(X(flareH), yTop + 40, 20 * fk, C.accent, { glow: 30 });
        text(b.flare, X(flareH) + 66, yTop + 52, { size: 30, weight: 700, color: C.accent, alpha: Math.min(1, fk) });
      }
      // the storm line at 10 pfu
      const lk = es(u, 4.2, 5.2);
      line(x0, Y(10), x1, Y(10), { color: C.danger, width: 3, dash: [16, 10], p: lk });
      text(b.level, x1 - 8, Y(10) - 16, { size: 28, weight: 700, color: C.danger, align: 'right', alpha: ex(seg(u, 4.8, 5.6)) });
      const ck = pop(u, 7.0, 7.8);
      if (ck > 0) {
        disc(X(crossH), Y(10), 12 * ck, C.ivory);
        ring(X(crossH), Y(10), 12 + 50 * seg(u, 7.0, 8.2), C.ivory, { width: 3, alpha: 1 - seg(u, 7.0, 8.2) });
      }
      // seventy minutes: the gap between the flare and the storm line
      const gk = ex(seg(u, 8.2, 9.0)) * (1 - es(u, 11.2, 11.8));
      if (gk > 0) {
        const ya = Y(.1) - 36;
        line(X(flareH), ya, X(crossH), ya, { color: C.ivory, width: 4, alpha: gk });
        line(X(flareH), ya - 12, X(flareH), ya + 12, { color: C.ivory, width: 4, alpha: gk });
        line(X(crossH), ya - 12, X(crossH), ya + 12, { color: C.ivory, width: 4, alpha: gk });
        K.panel(X(flareH) - 20, ya - 110, 300, 64, gk);
        text(b.lead, X(flareH) + 130, ya - 66, { size: 32, weight: 700, align: 'center', alpha: gk });
      }
      // the climb: label the curve and the highest reading
      const l10 = ex(seg(u, 12.0, 12.8));
      text(b.l10, X(26), Y(150), { size: 30, weight: 700, color: C.caution, alpha: l10 });
      const pk = es(u, 13.2, 14.2);
      line(x0, Y(D.peak_pfu), x1, Y(D.peak_pfu), { color: C.ivory, width: 2, dash: [6, 8], p: pk });
      text(b.peak, x1 - 8, Y(D.peak_pfu) - 14, { size: 28, weight: 700, align: 'right', alpha: ex(seg(u, 13.6, 14.4)) });
    },

    // Counted near Earth; the Moon has no air or magnetic shield, so the storm reaches its ground.
    boundary(g, u, b) {
      const { C, text, disc, ex, seg, pop, lerp, rgba, wrap } = K;
      const k = pop(u, 0, .9), m = Math.min(1, k);
      earth(520, 430, 120 * k, m);
      satellite(720, 300, .8 * k, m);
      wrap(b.earth, 420, 32, 700).forEach((l, i) => text(l, 560, 640 + i * 40, { size: 32, weight: 700, align: 'center', alpha: m }));
      const mg = g.createRadialGradient(1340, 400, 20, 1400, 450, 170);
      mg.addColorStop(0, '#B9B5B0'); mg.addColorStop(1, '#3A3937');
      disc(1400, 450, 150 * k, mg, { alpha: m });
      for (let i = 0; i < 18; i++) {                                         // protons raining straight in
        const p = ((u * .9 + i * .23) % 1), ang = -2.2 + (i % 6) * .14;
        const r = lerp(520, 150, p), x = 1400 + Math.cos(ang) * r, y = 450 + Math.sin(ang) * r;
        disc(x, y, 7, C.caution, { glow: 12, alpha: m * (p < .95 ? 1 : 0) });
      }
      wrap(b.moon, 460, 32, 700).forEach((l, i) => text(l, 1400, 660 + i * 40, { size: 32, weight: 700, align: 'center', alpha: m }));
      text(b.note, 960, 790, { size: 28, weight: 600, color: C.muted, align: 'center', alpha: ex(seg(u, .8, 1.6)) });
    },
  });
})();
