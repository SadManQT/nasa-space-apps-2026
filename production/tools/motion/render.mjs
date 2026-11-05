// Frame capture for build.py, after Tweenkit's render.mjs, but through the installed Google Chrome (playwright-core,
// no browser download). The page exposes window.ready {W, H, FPS, duration} and renderAt(t).
//   node render.mjs <stage.html> stills <outDir> <t1> <t2> ...   -> <outDir>/NN.png
//   node render.mjs <stage.html> frames <outDir>                 -> <outDir>/00000.jpg ... (skips frames already there)
import { chromium } from 'playwright-core';
import fs from 'fs';
import path from 'path';

const [stage, mode, outDir, ...ts] = process.argv.slice(2);
if (!stage || !['stills', 'frames'].includes(mode) || !outDir) {
  console.error('usage: render.mjs <stage.html> stills|frames <outDir> [t ...]'); process.exit(2);
}
const browser = await chromium.launch({ channel: 'chrome', args: ['--font-render-hinting=none', '--force-color-profile=srgb', '--disable-lcd-text'] });
const page = await browser.newPage({ viewport: { width: 1920, height: 1080 }, deviceScaleFactor: 1 });
let failed = false;
page.on('pageerror', e => { failed = true; console.error('PAGEERROR', e.message); });
await page.goto('file://' + path.resolve(stage));
await page.waitForFunction(() => window.ready, null, { timeout: 15000 }).catch(() => { failed = true; });
const info = await page.evaluate(() => window.ready);
if (failed || !info) { console.error('page failed to initialise'); await browser.close(); process.exit(1); }
await page.evaluate(() => document.fonts.ready);
fs.mkdirSync(outDir, { recursive: true });
const canvas = page.locator('#c');
if (mode === 'stills') {
  for (let i = 0; i < ts.length; i++) {
    await page.evaluate(t => renderAt(t), +ts[i]);
    await canvas.screenshot({ path: `${outDir}/${String(i).padStart(2, '0')}.png` });
  }
} else {
  const n = Math.round(info.duration * info.FPS);
  for (let f = 0; f < n; f++) {
    const p = `${outDir}/${String(f).padStart(5, '0')}.jpg`;
    if (fs.existsSync(p)) continue;
    await page.evaluate(t => renderAt(t), f / info.FPS);
    for (let tries = 1; ; tries++) {                  // a busy machine can stall one capture; retry, then give up
      try { await canvas.screenshot({ path: p + '.tmp.jpg', type: 'jpeg', quality: 95, timeout: 120000 }); break; }
      catch (err) { if (tries >= 3) throw err; console.error('retry frame', f, err.name); }
    }
    fs.renameSync(p + '.tmp.jpg', p);
    if (f % 120 === 0) console.log('frame', f, '/', n);
  }
}
console.log(failed ? 'FAILED' : 'DONE');
await browser.close();
process.exit(failed ? 1 : 0);
