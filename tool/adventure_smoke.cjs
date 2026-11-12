// Actual Canvas mouse/keyboard/touch input is checked separately from semantic actions.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const {chromium} = require('playwright');
const {typeText} = require('./browser_input.cjs');
(async () => {
  const browser = await chromium.launch({executablePath: process.env.CHROMIUM_PATH || '/usr/bin/chromium', headless: true, args: ['--no-sandbox']});
  let page, diagnostic;
  const errors = [], remote = [];
  const url = process.argv[2] || 'http://127.0.0.1:5173';
  const shots = path.resolve('docs/screenshots');
  fs.mkdirSync(shots, {recursive: true});
  async function start(p, semantics = true) {
    p.on('pageerror', e => errors.push(String(e)));
    p.on('request', r => {if (new URL(r.url()).origin !== new URL(url).origin) remote.push(r.url());});
    await p.goto(url);
    await p.waitForFunction(() => document.querySelector('flt-semantics-placeholder'));
    if (semantics) await p.locator('flt-semantics-placeholder').evaluate(e => e.click());
    await p.waitForTimeout(semantics ? 400 : 1500);
  }
  async function count(p, expected) {
    await p.waitForFunction(n => (JSON.parse(localStorage.getItem('reallife-rpg-data') || 'null')?.completions?.length || 0) === n, expected);
  }
  async function press(p, locator) {
    await locator.evaluate(e => e.click());
    await p.waitForTimeout(160);
  }
  try {
    const context = await browser.newContext({locale: 'tr-TR', viewport: {width: 1440, height: 1100}});
    page = await context.newPage();
    diagnostic = page;
    await start(page);
    assert.equal(await page.evaluate(() => localStorage.getItem('reallife-rpg-data')), null);
    await page.getByRole('button', {name: 'Yeni görev', exact: true}).waitFor();
    const labels = await page.locator('[aria-label]').evaluateAll(es => es.map(e => (e.getAttribute('aria-label') || '') + e.textContent).join(' '));
    assert.ok(labels.includes('Yeni görev düğmesiyle'), 'First-task help is exposed to accessibility');
    await page.screenshot({path: path.join(shots, 'aionia-first-task.png')});
    await press(page, page.getByRole('button', {name: 'Yeni görev', exact: true}));
    await typeText(page.getByRole('textbox', {name: /Görev adı/}), 'Bir sayfa oku');
    await press(page, page.getByRole('button', {name: 'Ekle', exact: true}));
    await page.waitForFunction(() => JSON.parse(localStorage.getItem('reallife-rpg-data') || 'null')?.tasks?.length === 1);
    const check = page.getByRole('checkbox', {name: /Bir sayfa oku.*Yapıldı/});
    const box = await check.boundingBox();
    assert.ok(box && box.height >= 48 && box.height <= 56 && box.width <= 56, 'Checkbox owns its 48px semantic target, not the whole card');
    console.log('STEP adventure checkbox geometry', box);
    // Identical saved data and layout, semantics OFF: physical Canvas controls.
    const pointer = await context.newPage();
    diagnostic = pointer;
    await start(pointer, false);
    await pointer.mouse.click(box.x + box.width / 2, box.y + box.height / 2);
    await count(pointer, 1);
    // Mouse activation and keyboard traversal are distinct paths on Flutter web.
    await pointer.locator('flt-semantics-placeholder').evaluate(e => e.click());
    const keyboardCheck = pointer.getByRole('checkbox', {name: /Bir sayfa oku.*Yapıldı/});
    let focused = false;
    for (let i = 0; i < 80; i++) {
      await pointer.keyboard.press('Tab');
      await pointer.waitForTimeout(40);
      if (await keyboardCheck.evaluate(e => e === document.activeElement || e.contains(document.activeElement))) {focused = true; break;}
    }
    assert.ok(focused, 'Real Tab traversal reaches the task checkbox');
    await pointer.keyboard.press('Space');
    await count(pointer, 0);
    await pointer.keyboard.press('Space');
    await count(pointer, 1);
    console.log('PASS adventure: Canvas mouse and Tab/Space retain the checkbox and persist each state');
    await pointer.screenshot({path: path.join(shots, 'aionia-task-done.png')});
    await pointer.reload();
    await pointer.waitForFunction(() => document.querySelector('flt-semantics-placeholder'));
    await pointer.locator('flt-semantics-placeholder').evaluate(e => e.click());
    const tick = pointer.getByRole('checkbox', {name: /Bir sayfa oku.*Yapıldı/});
    assert.equal(await tick.getAttribute('aria-checked'), 'true');
    await press(pointer, tick);
    await count(pointer, 0);
    await press(pointer, pointer.getByRole('button', {name: 'Geri al', exact: true}));
    await count(pointer, 1);
    // Simulated storage failure: visible state is never described as saved.
    await pointer.evaluate(() => {
      window.originalStorageWrite = Storage.prototype.setItem;
      Storage.prototype.setItem = function(k, v) {
        if (k === 'reallife-rpg-data') throw new DOMException('Simulated storage full', 'QuotaExceededError');
        return window.originalStorageWrite.call(this, k, v);
      };
    });
    await press(pointer, tick);
    await pointer.locator('[aria-label*="Değişiklik ekranda duruyor"]').waitFor();
    assert.equal(await tick.getAttribute('aria-checked'), 'false');
    await count(pointer, 1); // Disk state has not changed.
    await pointer.evaluate(() => {Storage.prototype.setItem = window.originalStorageWrite;});
    await press(pointer, tick); // Retry persists current state, no duplicate completion.
    await count(pointer, 1);
    await pointer.reload();
    await pointer.waitForFunction(() => document.querySelector('flt-semantics-placeholder'));
    await pointer.locator('flt-semantics-placeholder').evaluate(e => e.click());
    assert.equal(await pointer.getByRole('checkbox', {name: /Bir sayfa oku.*Yapıldı/}).getAttribute('aria-checked'), 'true');
    console.log('PASS adventure: create, Canvas mouse, Tab/Space, stable focus, undo, storage failure/retry and reload');
    await pointer.setViewportSize({width: 390, height: 844});
    await pointer.waitForTimeout(500);
    await pointer.screenshot({path: path.join(shots, 'aionia-phone.png')});
    // Mobile + 200% UI uses saved preferences; changing the controls is tested by browser_smoke.
    const mobile = await browser.newContext({locale: 'en-US', viewport: {width: 390, height: 844}, hasTouch: true, isMobile: true});
    await mobile.addInitScript(() => localStorage.setItem('reallife-rpg-settings', JSON.stringify({language: 'en', ui_scale: 2, game_mode: false, appearance: {reduce_motion: true, font: 'dyslexic'}})));
    const phone = await mobile.newPage();
    diagnostic = phone;
    await start(phone);
    await press(phone, phone.getByRole('button', {name: 'New task', exact: true}));
    await typeText(phone.getByRole('textbox', {name: /Task name/}), 'A task with a long title to keep readable on a phone');
    await press(phone, phone.getByRole('button', {name: 'Add', exact: true}));
    const phoneCheck = phone.getByRole('checkbox', {name: /A task with a long title.*Done/});
    for (let i = 0; i < 15; i++) {
      const b = await phoneCheck.count() ? await phoneCheck.boundingBox() : null;
      if (b && b.y > 50 && b.y + b.height < 700) break;
      await phone.mouse.move(300, 650);
      await phone.mouse.wheel(0, 250);
      await phone.waitForTimeout(150);
    }
    const pb = await phoneCheck.boundingBox();
    assert.ok(pb && pb.y > 0 && pb.y + pb.height < 844, '200% checkbox is visible after scrolling');
    await phone.touchscreen.tap(pb.x + pb.width / 2, pb.y + pb.height / 2);
    await count(phone, 1);
    await phone.screenshot({path: path.join(shots, 'aionia-phone-200.png')});
    assert.equal(await phoneCheck.getAttribute('aria-checked'), 'true');
    console.log('PASS adventure: English phone at 200%, long title, OpenDyslexic, reduced motion and real touch');
    assert.deepEqual(errors, []);
    assert.deepEqual(remote, [], 'The default task flow sends no requests to remote origins');
    console.log('PASS adventure: no remote-origin requests or uncaught browser errors in tested flow');
  } catch (error) {
    if (diagnostic) await diagnostic.screenshot({path: path.join(shots, 'aionia-failure.png')}).catch(() => {});
    throw error;
  } finally {await browser.close();}
})().catch(e => {console.error(e); process.exit(1);});
