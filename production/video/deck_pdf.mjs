// Export deck.html to deck.pdf (seven 1280x720 pages) with the installed Google Chrome, no browser download.
// Uses production/tools/motion's playwright-core: run `npm ci` in production/tools/motion once, then
//   node production/video/deck_pdf.mjs
// PLAYWRIGHT_CORE=<dir> points at another playwright-core install.
import path from 'path';
import { fileURLToPath } from 'url';

const here = path.dirname(fileURLToPath(import.meta.url));
const pw = process.env.PLAYWRIGHT_CORE || path.join(here, '../tools/motion/node_modules/playwright-core');
const { chromium } = await import(path.join(pw, 'index.mjs'));

const browser = await chromium.launch({ channel: 'chrome' });
const page = await browser.newPage({ viewport: { width: 1280, height: 720 } });
await page.goto('file://' + path.join(here, 'deck.html'), { waitUntil: 'networkidle' });
await page.evaluate(() => document.fonts.ready);
const missing = await page.evaluate(() => [...document.images].filter(i => !i.naturalWidth).map(i => i.src));
if (missing.length) { console.error('missing images (git lfs pull?):', missing); process.exit(1); }
await page.pdf({ path: path.join(here, 'deck.pdf'), width: '1280px', height: '720px', printBackground: true, preferCSSPageSize: true });
await browser.close();
console.log('wrote', path.join(here, 'deck.pdf'));
