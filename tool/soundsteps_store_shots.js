// Captures SoundSteps Play Store images from the real app (web build):
// six 1080x1920 phone screenshots and the 1024x500 feature graphic.
// Usage (from the repo root, after the two web builds in STORE_ASSETS.md):
//   NODE_PATH=$(npm root -g) node tool/soundsteps_store_shots.js
// Needs Node with the `playwright` package and a Chromium it can launch.
const http = require('http');
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

const OUT = path.resolve('docs/soundsteps/store');
const WORDS = ['zero', 'one', 'two', 'three', 'four', 'five', 'six', 'seven',
  'eight', 'nine', 'ten', 'eleven', 'twelve', 'thirteen', 'fourteen',
  'fifteen', 'sixteen', 'seventeen', 'eighteen', 'nineteen', 'twenty'];
const TYPES = { '.html': 'text/html', '.js': 'text/javascript', '.json': 'application/json',
  '.png': 'image/png', '.ttf': 'font/ttf', '.otf': 'font/otf', '.wasm': 'application/wasm' };

function serve(dir) {
  return new Promise(resolve => {
    const server = http.createServer((req, res) => {
      let file = path.join(dir, decodeURIComponent(req.url.split('?')[0]));
      if (file.endsWith('/')) file += 'index.html';
      fs.readFile(file, (err, data) => {
        if (err) { res.writeHead(404); res.end(); return; }
        res.writeHead(200, { 'Content-Type': TYPES[path.extname(file)] || 'application/octet-stream' });
        res.end(data);
      });
    }).listen(0, '127.0.0.1', () => resolve(server));
  });
}

// What a few weeks of play look like, written the way shared_preferences
// stores it on the web: key "flutter.<key>", value JSON-encoded.
function seed() {
  const day = d => d.toISOString().slice(0, 10);
  const play = {};
  [12, 9, 15, 0, 11, 14, 8].forEach((min, i) => {
    const d = new Date(); d.setDate(d.getDate() - (6 - i));
    if (min) play[day(d)] = min * 60;
  });
  const letters = {};
  for (const l of ['A', 'B', 'C', 'M', 'S', 'T', 'P']) letters[l] = { c: 4, m: 1 };
  for (const l of ['E', 'G', 'O', 'R']) letters[l] = { c: 1, m: 1 };
  letters.D = { c: 1, m: 3 };
  return {
    'flutter.soundsteps.progress.v1': JSON.stringify(JSON.stringify({ stars: 23, letters, play })),
    'flutter.soundsteps.settings.v1': JSON.stringify(JSON.stringify({
      name: 'Mia', speed: 'slow', break: 20, haptics: true, reduceMotion: false, onboarded: true })),
  };
}

(async () => {
  fs.mkdirSync(OUT, { recursive: true });
  const app = await serve(path.resolve('build/web'));
  const art = await serve(path.resolve('build/store_art'));
  const browser = await chromium.launch().catch(() =>
    chromium.launch({ executablePath: '/opt/pw-browsers/chromium-1194/chrome-linux/chrome' }));

  // Feature graphic.
  const g = await browser.newPage({ viewport: { width: 1024, height: 500 } });
  await g.goto(`http://127.0.0.1:${art.address().port}/`);
  await g.waitForTimeout(4000);
  await g.screenshot({ path: path.join(OUT, 'feature_graphic_1024x500.png') });

  // Phone screenshots: 360x640 at 3x = 1080x1920 (9:16).
  const page = await browser.newPage({ viewport: { width: 360, height: 640 }, deviceScaleFactor: 3 });
  const errors = [];
  page.on('pageerror', e => errors.push(String(e)));
  const values = seed();
  await page.addInitScript(v => { for (const [k, val] of Object.entries(v)) localStorage.setItem(k, val); }, values);
  await page.goto(`http://127.0.0.1:${app.address().port}/`);
  await page.waitForTimeout(5000);
  await page.evaluate(() => document.querySelector('flt-semantics-placeholder')?.click());
  await page.waitForTimeout(800);
  const esc = s => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  const tap = label => page.getByRole('button', { name: new RegExp('^' + esc(label)) }).first().click({ timeout: 5000 });
  const shot = name => page.screenshot({ path: path.join(OUT, name + '.png') });
  const labels = () => page.$$eval('[role=button]', els => els.map(e => (e.getAttribute('aria-label') || e.textContent || '').split('\n')[0]));

  await page.waitForTimeout(1200);
  await shot('01_home');

  await tap('Letters'); await page.waitForTimeout(1200);
  await tap('Letter B'); await page.waitForTimeout(900);
  await shot('02_letters');
  await tap('Back'); await page.waitForTimeout(1000);

  await tap('Picture words'); await page.waitForTimeout(1500);
  for (const c of (await labels()).filter(l => /^Letter [A-Z]$/.test(l))) {
    await tap(c); await page.waitForTimeout(160);
    const msg = await page.evaluate(() => [...document.querySelectorAll('flt-semantics, [aria-label]')]
      .map(e => (e.getAttribute('aria-label') || '') + ' ' + e.textContent).join(' '));
    if (msg.includes('Yes!')) { await page.waitForTimeout(140); await shot('03_picture_words'); break; }
  }
  await page.waitForTimeout(3000);
  await tap('Back'); await page.waitForTimeout(1000);

  await tap('Trace'); await page.waitForTimeout(1500);
  const pad = await page.locator('[aria-label^="Trace the letter"]').first().boundingBox();
  const at = ([x, y]) => [pad.x + x * pad.width, pad.y + y * pad.height];
  await page.mouse.move(...at([.5, .1])); await page.mouse.down();
  await page.mouse.move(...at([.2, .9]), { steps: 12 }); await page.mouse.up();
  await page.waitForTimeout(400);
  await shot('04_trace');
  await tap('Back'); await page.waitForTimeout(1000);

  await tap('My stickers'); await page.waitForTimeout(1200);
  await shot('05_stickers');
  await tap('Back'); await page.waitForTimeout(1000);

  await tap('Grown-ups'); await page.waitForTimeout(800);
  const texts = await page.evaluate(() => [...document.querySelectorAll('flt-semantics, [aria-label]')]
    .map(e => (e.getAttribute('aria-label') || '') + ' ' + e.textContent).join(' | '));
  const q = texts.match(/What is (\w+) plus (\w+)\?/);
  await tap(WORDS[WORDS.indexOf(q[1]) + WORDS.indexOf(q[2])]); await page.waitForTimeout(1500);
  await page.mouse.move(180, 400); await page.mouse.wheel(0, 330); await page.waitForTimeout(800);
  await shot('06_grown_ups');

  await browser.close(); app.close(); art.close();
  if (errors.length) { console.error('page errors:', errors); process.exit(1); }
  console.log('wrote', fs.readdirSync(OUT).join(', '));
})().catch(e => { console.error('FAILED', e.message); process.exit(1); });
