const {openMenu}=require('./browser_menu.cjs');
const {typeText}=require('./browser_input.cjs');
// Browser selection/persistence and phone/reduced-motion checks for F101.
// Canvas pointer coverage remains in progress_smoke; selection uses semantics.
const assert=require('node:assert/strict');
const fs=require('node:fs');
const path=require('node:path');
const {chromium}=require('playwright');
(async()=>{
 const browser=await chromium.launch({executablePath:process.env.CHROMIUM_PATH||'/usr/bin/chromium',headless:true,args:['--no-sandbox']});
 try{
  const page=await browser.newPage({locale:'tr-TR',viewport:{width:1440,height:1500}});
  const errors=[];page.on('pageerror',e=>errors.push(String(e)));
  await page.goto(process.argv[2]||'http://127.0.0.1:5173');
  const semantics=async()=>{await page.waitForFunction(()=>document.querySelector('flt-semantics-placeholder'));await page.locator('flt-semantics-placeholder').evaluate(e=>e.click());};
  await semantics();
  const press=async locator=>{await locator.evaluate(e=>e.click());await page.waitForTimeout(200);};
  await openMenu(page,'Yol arkadaşları');
  const ids=['aion','sheep','wolf','owl'];
  const shots=path.resolve('docs/screenshots');fs.mkdirSync(shots,{recursive:true});
  for(let i=0;i<ids.length;i++){
   await press(page.getByRole('button',{name:/^(Seç|Seçili)$/}).nth(i));
   await page.waitForFunction(id=>JSON.parse(localStorage.getItem('reallife-rpg-data')||'null')?.life?.companion===id,ids[i]);
   await page.getByRole('img',{name:/Yol arkadaşı sahnesi/}).first().screenshot({path:path.join(shots,`companion-browser-${ids[i]}.png`)});
   const atlasReady=i===0 ? page.waitForResponse(r=>r.url().endsWith('/assets/companions/chest_press.png') && r.ok()) : null;
   await press(page.getByRole('checkbox',{name:'Göğüs pres makinesi',exact:true}));
   if(atlasReady)await (await atlasReady).finished();
   await page.waitForTimeout(250);
   await press(page.getByRole('button',{name:'Animasyonu duraklat',exact:true}));
   const chestFigure=page.getByRole('img',{name:/Yol arkadaşı sahnesi/}).first();
   const phase=page.getByRole('slider').first();
   await phase.press('Home');await page.waitForTimeout(200);
   const start=await chestFigure.screenshot();
   for(let step=0;step<4;step++){
    await phase.press('ArrowRight');
    // Each native semantics action uses the current frame's increment closure.
    // Wait for its exact acknowledgement before sending another key.
    await page.waitForFunction(expected=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>(el.getAttribute('aria-valuetext')||'').endsWith(expected)),`${step+2}/8`);
   }
   await page.waitForTimeout(200);
   assert.notDeepEqual(start,await chestFigure.screenshot(),'Dedicated chest press extends the actual drawn arms');
   await chestFigure.screenshot({path:path.join(shots,`chest-press-browser-${ids[i]}.png`)});
   await phase.press('End');await page.waitForTimeout(150);
   assert.match(await phase.getAttribute('aria-valuetext'),/8\/8/);
   const benchReady=i===0 ? page.waitForResponse(r=>r.url().endsWith('/assets/companions/bench_press.png') && r.ok()) : null;
   await press(page.getByRole('checkbox',{name:'Halterle bench press',exact:true}));
   if(benchReady)await (await benchReady).finished();
   await press(page.getByRole('button',{name:'Animasyonu duraklat',exact:true}));
   await phase.press('Home');
   await page.waitForFunction(()=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>/1\/8$/.test(el.getAttribute('aria-valuetext')||'')));
   const benchStart=await chestFigure.screenshot();
   for(let step=0;step<4;step++){
    await phase.press('ArrowRight');
    // Each native semantics action uses the current frame's increment closure.
    // Wait for its exact acknowledgement before sending another key.
    await page.waitForFunction(expected=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>(el.getAttribute('aria-valuetext')||'').endsWith(expected)),`${step+2}/8`);
   }
   await page.waitForFunction(()=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>/5\/8$/.test(el.getAttribute('aria-valuetext')||'')));
   assert.notDeepEqual(benchStart,await chestFigure.screenshot(),'Dedicated barbell bench press extends the supine character arms');
   await chestFigure.screenshot({path:path.join(shots,`bench-press-browser-${ids[i]}.png`)});
   await phase.press('End');
   await page.waitForFunction(()=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>/8\/8$/.test(el.getAttribute('aria-valuetext')||'')));
   assert.match(await phase.getAttribute('aria-valuetext'),/8\/8/);


  }
  await press(page.getByRole('checkbox',{name:'Arka omuz açış',exact:true}));
  await press(page.getByRole('button',{name:'Animasyonu duraklat',exact:true}));
  const figure=page.getByRole('img',{name:/Yol arkadaşı sahnesi/}).first();
  await page.getByRole('slider').first().press('Home');await page.waitForTimeout(200);
  const first=await figure.screenshot();
  await page.getByRole('slider').first().press('End');await page.waitForTimeout(200);
  assert.notDeepEqual(first,await figure.screenshot(),'Paused phase input changes the actual seated character');
  await openMenu(page,'Spor');
  await press(page.getByRole('checkbox',{name:'Hareket kütüphanesi',exact:true}));
  const search=page.getByRole('textbox',{name:'Hareket veya kas ara',exact:true});
  await typeText(search,'Göğüs pres makinesi');
  const movement=page.getByRole('button',{name:'Çalışan kaslar · şematik',exact:true});
  const box=await movement.boundingBox();assert.ok(box);
  await page.mouse.click(box.x+box.width/2,box.y+box.height/2);
  await page.getByRole('button',{name:'Animasyonu duraklat',exact:true}).waitFor();
  assert.equal(await page.getByText(/Bu hareketin özel kareleri hazırlanıyor/).count(),0);
  await press(page.getByRole('button',{name:'Animasyonu duraklat',exact:true}));
  await page.getByRole('slider').first().press('End');
  // Keyboard actions and the Flutter semantics update are asynchronous.
  // Require the exact final phase, rather than reading the previous frame.
  await page.waitForFunction(()=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>/8\/8$/.test(el.getAttribute('aria-valuetext')||'')));
  assert.match(await page.getByRole('slider').first().getAttribute('aria-valuetext'),/8\/8/);
  await page.screenshot({path:path.join(shots,'chest-press-exercise.png')});
  await press(page.getByRole('button',{name:'Kapat',exact:true}));
  await typeText(search,'Barbell bench press');
  const benchBox=await movement.boundingBox();assert.ok(benchBox);
  await page.mouse.click(benchBox.x+benchBox.width/2,benchBox.y+benchBox.height/2);
  await page.getByRole('button',{name:'Animasyonu duraklat',exact:true}).waitFor();
  assert.equal(await page.getByText(/Bu hareketin özel kareleri hazırlanıyor/).count(),0);
  await press(page.getByRole('button',{name:'Animasyonu duraklat',exact:true}));
  await page.getByRole('slider').first().press('End');
  await page.waitForFunction(()=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>/8\/8$/.test(el.getAttribute('aria-valuetext')||'')));
  await page.screenshot({path:path.join(shots,'bench-press-exercise.png')});
  await press(page.getByRole('button',{name:'Kapat',exact:true}));
  await typeText(search,'Eğimli');
  await press(page.getByRole('button',{name:'Çalışan kaslar · şematik',exact:true}));
  await page.getByText(/Bu hareketin özel kareleri hazırlanıyor/).waitFor();
  await press(page.getByRole('button',{name:'Kapat',exact:true}));
  const before=await page.evaluate(()=>JSON.parse(localStorage.getItem('reallife-rpg-data')));
  assert.equal(before.tasks.length,0);assert.equal(before.completions.length,0);
  // Preference fixture only: no tasks, dates or completion records are injected.
  await page.evaluate(()=>{const saved=JSON.parse(localStorage.getItem('reallife-rpg-settings')||'{}');localStorage.setItem('reallife-rpg-settings',JSON.stringify({...saved,ui_scale:2,appearance:{...saved.appearance,font:'dyslexic',reduce_motion:true}}));});
  await page.setViewportSize({width:390,height:844});await page.reload();await semantics();
  // Flutter merges the tall phone hero into one labelled semantics node.
  // Exercise its actual vertical/horizontal viewport rather than expecting
  // the desktop's separate image role to remain exposed at 200%.
  await page.mouse.move(260,600);await page.mouse.wheel(0,600);await page.waitForTimeout(250);
  await page.mouse.wheel(170,0);await page.waitForTimeout(450);
  await page.waitForFunction(()=>Array.from(document.querySelectorAll('[aria-label]')).some(e=>e.getAttribute('aria-label').includes('Yol arkadaşı sahnesi: Baykuş Ömer')));
  const clip={x:20,y:140,width:350,height:500};
  await page.mouse.move(5,30);await page.waitForTimeout(150);
  const a=await page.screenshot({clip});
  await page.mouse.move(380,30);await page.waitForTimeout(150);
  const b=await page.screenshot({clip});
  assert.deepEqual(a,b,'Reduced-motion portrait stays still under actual pointer movement');
  await page.screenshot({path:path.join(shots,'companion-phone-200.png')});
  const stored=await page.evaluate(()=>({data:JSON.parse(localStorage.getItem('reallife-rpg-data')),settings:JSON.parse(localStorage.getItem('reallife-rpg-settings'))}));
  assert.equal(stored.settings.ui_scale,2);assert.equal(stored.settings.appearance.reduce_motion,true);
  assert.equal(stored.data.life.companion,'owl');assert.deepEqual(stored.data.tasks,before.tasks);assert.deepEqual(stored.data.completions,before.completions);
  assert.deepEqual(errors,[]);
  console.log('PASS: four full-body sprite characters, eight chest and bench press frames per character, exact chest_press/machine and bench_press/barbell routes with physical mouse, other presses remain pending, paused seated movement frame, no task/XP records, persisted character, phone at actual 200 percent, stable reduced-motion frame.');
 }finally{await browser.close();}
})().catch(e=>{console.error(e);process.exitCode=1;});
