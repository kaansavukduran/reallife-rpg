const {openMenu}=require('./browser_menu.cjs');
// Development-only browser checks; run against a served Flutter web build.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const {chromium} = require('playwright');
const {typeText} = require('./browser_input.cjs');
(async () => {
  const browser = await chromium.launch({executablePath: process.env.CHROMIUM_PATH || '/usr/bin/chromium', headless: true, args: ['--no-sandbox']});
  try {
    const page = await browser.newPage({locale: 'tr-TR', viewport: {width: 1440, height: 1100}});
    const errors=[];
    page.on('pageerror', e=>errors.push(String(e)));
    await page.goto(process.argv[2] || 'http://127.0.0.1:5173');
    await page.waitForFunction(()=>document.querySelector('flt-semantics-placeholder'));
    await page.locator('flt-semantics-placeholder').evaluate(el=>el.click());
    const press=async locator=>{await locator.evaluate(el=>el.click());await page.waitForTimeout(200);};
    await openMenu(page,'Spor');
    await press(page.getByRole('checkbox',{name:'Hareket kütüphanesi',exact:true}));
    await typeText(page.getByRole('textbox',{name:'Hareket veya kas ara',exact:true}), 'reverse pec');
    await page.waitForFunction(()=>Array.from(document.querySelectorAll('[role=button]')).filter(el=>el.textContent==='Çalışan kaslar · şematik').length===1);
    await press(page.getByRole('button',{name:'Çalışan kaslar · şematik',exact:true}));
    await page.getByRole('button',{name:'Animasyonu duraklat',exact:true}).waitFor();
    await page.waitForTimeout(700);
    const shotDir=path.resolve('docs/screenshots');fs.mkdirSync(shotDir,{recursive:true});
    await page.screenshot({path:path.join(shotDir,'reverse-pec-deck.png')});
    await press(page.getByRole('button',{name:'Animasyonu duraklat',exact:true}));
    const figure=page.getByRole('img',{name:/Yol arkadaşı sahnesi/});
    const slider=page.getByRole('slider').first();
    await slider.press('Home');await page.waitForTimeout(200);
    const first=await figure.screenshot();
    await slider.press('End');await page.waitForTimeout(200);
    const second=await figure.screenshot();
    assert.notDeepEqual(first,second,'Paused phase control changes the rendered character, not only the thumb');
    await press(page.getByRole('button',{name:'Kapat',exact:true}));
    await openMenu(page,'Beslenme');
    await press(page.getByRole('button',{name:'Öğüne besin ekle',exact:true}));
    await page.getByRole('button',{name:/^Meyveler/}).waitFor();
    await page.screenshot({path:path.join(shotDir,'food-groups.png')});
    await press(page.getByRole('button',{name:/^Meyveler/}));
    await typeText(page.getByRole('textbox',{name:'Besin ara (TR / EN)',exact:true}), 'blueberries, raw');
    await page.screenshot({path:path.join(shotDir,'food-family.png')});
    await press(page.getByRole('button',{name:/^Yaban mersini/}));
    await page.screenshot({path:path.join(shotDir,'food-forms.png')});
    await press(page.getByRole('button',{name:/Yaban mersini.*Çiğ/}));
    await typeText(page.getByRole('textbox',{name:/Yenilebilir miktar/}), '150,5');
    await page.keyboard.press('Tab');
    await press(page.getByRole('button',{name:'Kaydet',exact:true}));
    // The form result is committed after DialogRoute.completed, so a fast
    // semantic click must wait for persistence instead of assuming 200 ms.
    await page.waitForFunction(()=>JSON.parse(localStorage.getItem('reallife-rpg-data')||'null')?.life?.nutrition?.entries?.length===1);
    const read=()=>page.evaluate(()=>JSON.parse(localStorage.getItem('reallife-rpg-data')));
    let data=await read();assert.equal(data.life.nutrition.entries[0].grams,150.5);assert.equal(data.life.nutrition.entries[0].eaten,true);
    await press(page.getByRole('checkbox',{name:/Yaban mersini/}));
    await page.waitForFunction(()=>JSON.parse(localStorage.getItem('reallife-rpg-data')||'null')?.life?.nutrition?.entries?.[0]?.eaten===false);
    await press(page.getByRole('checkbox',{name:/Yaban mersini/}));
    await page.waitForFunction(()=>JSON.parse(localStorage.getItem('reallife-rpg-data')||'null')?.life?.nutrition?.entries?.[0]?.eaten===true);
    data=await read();assert.equal(data.life.nutrition.entries[0].eaten,true);assert.equal(data.completions.length,0);
    await page.screenshot({path:path.join(shotDir,'nutrition-tr.png')});
    // Physical pointer selects a meat family/cut; actual keyboard searches
    // Turkish cut names. Source variants and saved nutrients stay distinct.
    await press(page.getByRole('button',{name:'Öğüne besin ekle',exact:true}));
    const meatGroup=page.getByRole('button',{name:/^Et ve kümes hayvanları/});
    for(let i=0;i<10 && await meatGroup.count()===0;i++) {
      await page.mouse.move(750,700);await page.mouse.wheel(0,400);await page.waitForTimeout(150);
    }
    await press(meatGroup);
    await typeText(page.getByRole('textbox',{name:'Besin ara (TR / EN)',exact:true}), 'kıyma');
    const mousePress=async locator=>{
      await locator.scrollIntoViewIfNeeded();const box=await locator.boundingBox();assert.ok(box);
      await page.mouse.click(box.x+Math.min(30,box.width/2),box.y+box.height/2);
      await page.waitForTimeout(250);
    };
    await mousePress(page.getByRole('button',{name:/^Sığır eti/}));
    await page.getByRole('button',{name:/^Kıyma/}).waitFor();
    await press(page.getByRole('button',{name:'Filtreleri temizle',exact:true}));
    await page.screenshot({path:path.join(shotDir,'meat-cut-selection.png')});
    await typeText(page.getByRole('textbox',{name:'Besin ara (TR / EN)',exact:true}), 'kıyma');
    await mousePress(page.getByRole('button',{name:/^Kıyma/}));
    await page.screenshot({path:path.join(shotDir,'meat-cut-forms.png')});
    await press(page.getByLabel('Çiğ',{exact:true}));
    const foodIndex=JSON.parse(fs.readFileSync('assets/data/food_index.json','utf8'));
    const expectedMeat=JSON.parse(fs.readFileSync('assets/data/foods.json','utf8')).find(f=>{
      const item=foodIndex.items[f.id];return item[0]==='meat/beef'&&item[1]==='raw'&&item[2]==='ground';
    });
    const choice=page.getByRole('button',{name:new RegExp('NDB '+expectedMeat.id.split(':')[1])});
    await choice.waitFor();
    assert.ok((await choice.textContent()).includes('Sığır eti · Kıyma · Çiğ'));
    await page.screenshot({path:path.join(shotDir,'meat-short-labels.png')});
    await mousePress(choice);
    await press(page.getByRole('button',{name:'Kaynak ayrıntısı',exact:true}));
    const fullSource=expectedMeat.en+'\n'+expectedMeat.source;
    // Flutter exposes labeled selectable text as either a text node or a
    // labeled element, depending on the engine accessibility representation.
    await page.getByText(fullSource,{exact:true}).or(page.getByLabel(fullSource,{exact:true})).first().waitFor({timeout:5000}).catch(async error=>{
      console.log('SOURCE_REPRESENTATION',await page.locator('flt-semantics,textarea,input').evaluateAll(els=>els.filter(e=>[e.textContent,e.getAttribute('aria-label'),e.value].some(v=>v?.includes('Beef'))).map(e=>({tag:e.tagName,role:e.getAttribute('role'),label:e.getAttribute('aria-label'),text:e.textContent,value:e.value}))));
      throw error;
    });
    await press(page.getByRole('button',{name:'Kaydet',exact:true}));
    await page.waitForFunction(()=>JSON.parse(localStorage.getItem('reallife-rpg-data')||'null')?.life?.nutrition?.entries?.length===2);
    data=await read();assert.equal(data.life.nutrition.entries[1].food.id,expectedMeat.id);
    assert.deepEqual(data.life.nutrition.entries[1].food,expectedMeat);
    assert.equal(data.life.nutrition.entries[1].eaten,true);assert.equal(data.completions.length,0);
    await openMenu(page,'Dersler');
    await press(page.getByRole('button',{name:'Ders ekle',exact:true}));
    await typeText(page.getByRole('textbox',{name:'Ders adı',exact:true}), 'Örnek Biyoloji');
    const unitCount=page.getByRole('textbox',{name:'Ünite sayısı',exact:true});
    await typeText(unitCount, '3');
    await press(page.getByRole('button',{name:'Kaydet',exact:true}));
    await page.waitForFunction(()=>JSON.parse(localStorage.getItem('reallife-rpg-data')||'null')?.life?.study?.courses?.length===1);
    assert.equal((await read()).life.study.courses[0].units.length,3);
    await press(page.getByRole('checkbox',{name:/Ünite 1/}));
    await page.waitForFunction(()=>JSON.parse(localStorage.getItem('reallife-rpg-data')||'null')?.life?.study?.courses?.[0]?.units?.[0]?.completed_at!=null);
    await page.screenshot({path:path.join(shotDir,'courses-tr.png')});
    await openMenu(page,'Sağlık');
    await press(page.getByRole('button',{name:'Boy / kilo gir veya düzenle',exact:true}));
    await typeText(page.getByRole('textbox',{name:'Boy (cm)',exact:true}), '175');
    await typeText(page.getByRole('textbox',{name:/Vücut ağırlığı/}), '70');
    await press(page.getByRole('checkbox',{name:/18 yaş ve üzerindeyim/}));
    await press(page.getByRole('button',{name:'Kaydet',exact:true}));
    await page.waitForFunction(()=>JSON.parse(localStorage.getItem('reallife-rpg-data')||'null')?.life?.measurements?.height_cm===175).catch(async error=>{
      // This fresh browser context contains only the explicit smoke fixtures.
      console.log('MEASUREMENT_SAVE',await page.evaluate(()=>{
        const data=JSON.parse(localStorage.getItem('reallife-rpg-data')||'null');
        return {measurements:data?.life?.measurements,bodyKg:data?.life?.fitness?.body_kg,inputs:Array.from(document.querySelectorAll('input')).map(e=>({label:e.getAttribute('aria-label'),value:e.value}))};
      }));
      await page.screenshot({path:path.join(shotDir,'health-save-failure.png')});
      throw error;
    });
    data=await read();assert.equal(data.life.fitness.body_kg,70);assert.equal(data.life.measurements.adult_reference,true);assert.equal(data.completions.length,0);
    await page.screenshot({path:path.join(shotDir,'health-tr.png')});
    await openMenu(page,'Ayarlar');
    await press(page.getByRole('button',{name:/Dil \/ Language/}));
    await press(page.getByRole('menuitem',{name:'English',exact:true}));
    await openMenu(page,'Nutrition');
    await page.getByRole('button',{name:'Add food to meal',exact:true}).waitFor();
    await page.screenshot({path:path.join(shotDir,'nutrition-en.png')});
    await page.reload();await page.waitForFunction(()=>document.querySelector('flt-semantics-placeholder'));
    await page.locator('flt-semantics-placeholder').evaluate(el=>el.click());
    assert.equal(await page.evaluate(()=>JSON.parse(localStorage.getItem('reallife-rpg-settings')).language),'en');
    assert.equal((await read()).life.nutrition.entries[0].eaten,true);
    assert.deepEqual((await read()).life.nutrition.entries[1].food,expectedMeat);
    await openMenu(page,'Nutrition');
    const savedMeat=page.getByRole('checkbox',{name:/Beef · Ground meat · Raw.*NDB 13047/s});
    await savedMeat.waitFor();
    assert.equal(await savedMeat.getAttribute('aria-checked'),'true');
    assert.deepEqual(errors,[]);
    console.log('PASS: exercise search, character frames, muscle map, USDA food search, physical meat family/cut selection, bilingual short labels with original source, unchanged saved snapshots, grams, planned/eaten separation, TR/EN language persistence, courses/units, height/weight/adult BMI, no fake task completion or browser errors.');
  } finally {await browser.close();}
})().catch(error=>{console.error(error);process.exitCode=1;});
