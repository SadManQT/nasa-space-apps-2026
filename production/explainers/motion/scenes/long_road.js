// Scenes for sci_long_road (spec: ../specs/sci_long_road.json). The map places each named feature by its gazetteer
// latitude and longitude (polar stereographic, pole at the centre); sizes are the gazetteer diameters to the same scale.
(() => {
  const R = 1737.4;                                                            // lunar radius, km (the fixture's sphere)
  const KM = 2.6;                                                              // px per km on screen
  const CX = 560, CY = 610;
  function place(lat, lonE) {                                                  // south polar stereographic, km from the pole
    const r = 2 * R * Math.tan((90 + lat) * Math.PI / 360), a = lonE * Math.PI / 180;
    return [CX + r * Math.sin(a) * KM, CY - r * Math.cos(a) * KM];
  }
  Object.assign(SCENES, {
    // The named features on a real-scale map; a straight line from the pole to Mons Malapert.
    names(g, u, b) {
      const { C, text, line, disc, ring, ex, seg, es, pop, rgba } = K;
      const mk = ex(seg(u, 0, .9));
      ring(CX, CY, 130 * KM, rgba(C.muted, .35), { width: 2, dash: [8, 10], alpha: mk });
      disc(CX, CY, 9, C.ivory, { alpha: mk }); text(b.pole, CX, CY + 84, { size: 26, weight: 700, align: 'center', alpha: mk });
      let i = 0;
      for (const [name, f] of Object.entries(D.features)) {
        const [x, y] = place(f.center_lat_deg, f.center_lon_deg_east), k = pop(u, .6 + i * .5, 1.4 + i * .5); i++;
        if (k <= 0) continue;
        const isMountain = name.startsWith('Mons');
        ring(x, y, f.diameter_km / 2 * KM * Math.min(1, k), isMountain ? C.accent : C.water, { width: 3 });
        disc(x, y, 5, isMountain ? C.accent : C.water);
        const left = x < CX - 20;                                         // names west of the pole sit to the left of their ring
        text(name, left ? x - f.diameter_km / 2 * KM - 12 : x + f.diameter_km / 2 * KM + 12, y + 8, { size: 28, weight: 700, align: left ? 'right' : 'left', color: isMountain ? C.accent : C.water, alpha: Math.min(1, k) });
      }
      const m = D.features['Mons Malapert'], [mx, my] = place(m.center_lat_deg, m.center_lon_deg_east);
      line(CX, CY, mx, my, { color: C.ivory, width: 4, dash: [14, 10], p: es(u, 4.6, 7.0) });
      const lk = pop(u, 6.4, 7.2);
      if (lk > 0) { K.panel(1060, 230, 760, 100, Math.min(1, lk)); text(b.line, 1440, 294, { size: 34, weight: 800, align: 'center', alpha: Math.min(1, lk) }); }
      // three marathon runners' lanes, laid end to end along the line (caption 3)
      const rk = ex(seg(u, 9.4, 10.2));
      if (rk > 0) {
        for (let j = 0; j < 3; j++) {
          const t0 = j / 3, t1 = (j + .92) / 3, x0 = CX + (mx - CX) * t0, y0 = CY + (my - CY) * t0, x1 = CX + (mx - CX) * t1, y1 = CY + (my - CY) * t1;
          line(x0 + 18, y0, x1 + 18, y1, { color: [C.good, C.caution, C.amara][j], width: 8, alpha: rk });
        }
        K.panel(1060, 370, 760, 90, rk); text(b.marathons, 1440, 428, { size: 34, weight: 800, align: 'center', color: C.good, alpha: rk });
      }
    },
    // The drivable road winds around craters and slopes: far longer than the straight line.
    road(g, u, b) {
      const { C, text, line, poly, disc, es, pop, rgba } = K;
      const m = D.features['Mons Malapert'], [mx, my] = place(m.center_lat_deg, m.center_lon_deg_east);
      line(CX, CY, mx, my, { color: rgba(C.ivory, .35), width: 3, dash: [10, 10] });
      for (const [name, f] of Object.entries(D.features)) {
        const [x, y] = place(f.center_lat_deg, f.center_lon_deg_east);
        K.ring(x, y, f.diameter_km / 2 * KM, rgba(name.startsWith('Mons') ? C.accent : C.water, .6), { width: 2 });
      }
      const pts = [];
      for (let i = 0; i <= 60; i++) {                                         // a road that bends away from the straight line
        const t = i / 60, w = Math.sin(t * Math.PI * 3) * 70 + Math.sin(t * Math.PI * 7) * 22;
        const nx = -(my - CY), ny = mx - CX, n = Math.hypot(nx, ny);
        pts.push([CX + (mx - CX) * t + nx / n * w, CY + (my - CY) * t + ny / n * w]);
      }
      poly(pts, es(u, .4, 4.6), { color: C.good, width: 6, glow: 12 });
      const rk = pop(u, 4.8, 5.6);
      if (rk > 0) { K.panel(1060, 230, 760, 160, Math.min(1, rk)); text(b.road_l, 1440, 294, { size: 34, weight: 800, align: 'center', color: C.good, alpha: Math.min(1, rk) }); text(b.slope_l, 1440, 350, { size: 30, weight: 700, align: 'center', alpha: Math.min(1, rk) }); }
    },
  });
})();
