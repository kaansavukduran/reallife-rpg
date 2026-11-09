// Development-only check. Requires Playwright and a local Chromium installation.
// Serve `build/web`, then: node tool/browser_smoke.cjs [http://127.0.0.1:5173]
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { chromium } = require('playwright');

(async () => {
  const temporary = fs.mkdtempSync(path.join(os.tmpdir(), 'reallife-browser-'));
  const browser = await chromium.launch({
    executablePath: process.env.CHROMIUM_PATH || '/usr/bin/chromium',
    headless: true,
    args: ['--no-sandbox'],
  });
  try {
    const page = await browser.newPage({viewport: {width: 1440, height: 1050}, acceptDownloads: true});
    const errors = [];
    page.on('pageerror', error => errors.push(String(error)));
    await page.goto(process.argv[2] || 'http://127.0.0.1:5173');
    await page.waitForFunction(() => document.querySelector('flt-semantics-placeholder'));
    await page.waitForTimeout(1500); // Finite companion entrance.
    const screenshots = path.resolve('docs/screenshots');
    fs.mkdirSync(screenshots, {recursive: true});
    await page.screenshot({path: path.join(screenshots, 'adventure-desktop.png')});
    await page.setViewportSize({width: 390, height: 844});
    await page.waitForTimeout(300);
    await page.screenshot({path: path.join(screenshots, 'adventure-mobile.png')});
    await page.setViewportSize({width: 1440, height: 1050});
    await page.locator('flt-semantics-placeholder').evaluate(element => element.click());
    await page.getByText('Sağlık', {exact: true}).click();
    await page.getByRole('button', {name: 'Bir bardak su ekle'}).click();
    await page.getByText('Maceram', {exact: true}).click();
    await page.getByRole('button', {name: 'Yeni görev', exact: true}).click();
    await page.getByRole('textbox', {name: /Görev adı/}).fill('Bir sayfa öğren');
    await page.getByRole('button', {name: 'Ekle', exact: true}).click();
    await page.getByText('Gün', {exact: true}).click();
    await page.getByRole('checkbox').click();
    await page.waitForTimeout(1500);
    await page.getByText('Ayarlar', {exact: true}).click();
    await page.getByRole('button', {name: 'Yedeği dışa aktar'}).scrollIntoViewIfNeeded();
    const downloading = page.waitForEvent('download');
    await page.getByRole('button', {name: 'Yedeği dışa aktar'}).click();
    const backup = path.join(temporary, 'backup.json');
    await (await downloading).saveAs(backup);
    const exported = JSON.parse(fs.readFileSync(backup, 'utf8'));
    assert.equal(exported.completions.length, 1);
    assert.equal(Object.values(exported.life.health)[0].water, 1);
    const choosing = page.waitForEvent('filechooser');
    await page.getByRole('button', {name: 'Yedeği içe aktar'}).click();
    await (await choosing).setFiles(backup);
    await page.getByText(/^Seçilen JSON yedeği/).click();
    await page.getByRole('button', {name: 'Yükle', exact: true}).click();
    await page.waitForTimeout(300);
    await page.reload();
    await page.waitForFunction(() => document.querySelector('flt-semantics-placeholder'));
    const restored = await page.evaluate(() => JSON.parse(localStorage.getItem('reallife-rpg-data')));
    assert.equal(restored.tasks[0].title, 'Bir sayfa öğren');
    assert.equal(restored.completions.length, 1);
    assert.equal(Object.values(restored.life.health)[0].water, 1);
    assert.deepEqual(errors, []);
    console.log('PASS: desktop/mobile render, health record, task create/complete, JSON export/import, restart persistence; no browser errors.');
  } finally {
    await browser.close();
    fs.rmSync(temporary, {recursive: true, force: true});
  }
})().catch(error => { console.error(error); process.exitCode = 1; });
