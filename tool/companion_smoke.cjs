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
   const inclineReady=i===0 ? page.waitForResponse(r=>r.url().endsWith('/assets/companions/incline_press.png') && r.ok()) : null;
   await press(page.getByRole('checkbox',{name:'Eğimli dambıl pres',exact:true}));
   if(inclineReady)await (await inclineReady).finished();
   await press(page.getByRole('button',{name:'Animasyonu duraklat',exact:true}));
   await phase.press('Home');
   await page.waitForFunction(()=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>/1\/8$/.test(el.getAttribute('aria-valuetext')||'')));
   const inclineStart=await chestFigure.screenshot();
   for(let step=0;step<4;step++){
    await phase.press('ArrowRight');
    // Each native semantics action uses the current frame's increment closure.
    // Wait for its exact acknowledgement before sending another key.
    await page.waitForFunction(expected=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>(el.getAttribute('aria-valuetext')||'').endsWith(expected)),`${step+2}/8`);
   }
   await page.waitForFunction(()=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>/5\/8$/.test(el.getAttribute('aria-valuetext')||'')));
   assert.notDeepEqual(inclineStart,await chestFigure.screenshot(),'Dedicated incline dumbbell press raises two separate weights above the inclined body');
   await chestFigure.screenshot({path:path.join(shots,`incline-press-browser-${ids[i]}.png`)});
   await phase.press('End');
   await page.waitForFunction(()=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>/8\/8$/.test(el.getAttribute('aria-valuetext')||'')));
   assert.match(await phase.getAttribute('aria-valuetext'),/8\/8/);
   const pushReady=i===0 ? page.waitForResponse(r=>r.url().endsWith('/assets/companions/'+ids[i]+'_push_up.png') && r.ok()) : null;
   await press(page.getByRole('checkbox',{name:'Şınav',exact:true}));
   if(pushReady)await (await pushReady).finished();
   await press(page.getByRole('button',{name:'Animasyonu duraklat',exact:true}));
   await phase.press('Home');
   await page.waitForFunction(()=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>/1\/8$/.test(el.getAttribute('aria-valuetext')||'')));
   const pushStart=await chestFigure.screenshot();
   for(let step=0;step<4;step++){
    await phase.press('ArrowRight');
    // Each native semantics action uses the current frame's increment closure.
    // Wait for its exact acknowledgement before sending another key.
    await page.waitForFunction(expected=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>(el.getAttribute('aria-valuetext')||'').endsWith(expected)),`${step+2}/8`);
   }
   await page.waitForFunction(()=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>/5\/8$/.test(el.getAttribute('aria-valuetext')||'')));
   assert.notDeepEqual(pushStart,await chestFigure.screenshot(),'Reference character lowers and raises in its dedicated push-up drawings');
   await chestFigure.screenshot({path:path.join(shots,`push-up-browser-${ids[i]}.png`)});
   await phase.press('End');
   await page.waitForFunction(()=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>/8\/8$/.test(el.getAttribute('aria-valuetext')||'')));
   assert.match(await phase.getAttribute('aria-valuetext'),/8\/8/);
   const pecReady=i===0 ? page.waitForResponse(r=>r.url().endsWith('/assets/companions/'+ids[i]+'_pec_deck.png') && r.ok()) : null;
   await press(page.getByRole('checkbox',{name:'Pec deck göğüs açış',exact:true}));
   if(pecReady)await (await pecReady).finished();
   await press(page.getByRole('button',{name:'Animasyonu duraklat',exact:true}));
   await phase.press('Home');
   await page.waitForFunction(()=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>/1\/8$/.test(el.getAttribute('aria-valuetext')||'')));
   const pecStart=await chestFigure.screenshot();
   for(let step=0;step<4;step++){
    await phase.press('ArrowRight');
    // Each native semantics action uses the current frame's increment closure.
    // Wait for its exact acknowledgement before sending another key.
    await page.waitForFunction(expected=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>(el.getAttribute('aria-valuetext')||'').endsWith(expected)),`${step+2}/8`);
   }
   await page.waitForFunction(()=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>/5\/8$/.test(el.getAttribute('aria-valuetext')||'')));
   assert.notDeepEqual(pecStart,await chestFigure.screenshot(),'Character brings pec deck pads together in front of chest');
   await chestFigure.screenshot({path:path.join(shots,`pec-deck-browser-${ids[i]}.png`)});
   await phase.press('End');
   await page.waitForFunction(()=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>/8\/8$/.test(el.getAttribute('aria-valuetext')||'')));
   assert.match(await phase.getAttribute('aria-valuetext'),/8\/8/);
   const cableReady=i===0 ? page.waitForResponse(r=>r.url().endsWith('/assets/companions/'+ids[i]+'_cable_fly.png') && r.ok()) : null;
   await press(page.getByRole('checkbox',{name:'Kablo göğüs açış',exact:true}));
   if(cableReady)await (await cableReady).finished();
   await press(page.getByRole('button',{name:'Animasyonu duraklat',exact:true}));
   await phase.press('Home');
   await page.waitForFunction(()=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>/1\/8$/.test(el.getAttribute('aria-valuetext')||'')));
   const cableStart=await chestFigure.screenshot();
   for(let step=0;step<4;step++){
    await phase.press('ArrowRight');
    // Each native semantics action uses the current frame's increment closure.
    // Wait for its exact acknowledgement before sending another key.
    await page.waitForFunction(expected=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>(el.getAttribute('aria-valuetext')||'').endsWith(expected)),`${step+2}/8`);
   }
   await page.waitForFunction(()=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>/5\/8$/.test(el.getAttribute('aria-valuetext')||'')));
   assert.notDeepEqual(cableStart,await chestFigure.screenshot(),'Character sweeps cable handles together in front of chest');
   await chestFigure.screenshot({path:path.join(shots,`cable-fly-browser-${ids[i]}.png`)});
   await phase.press('End');
   await page.waitForFunction(()=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>/8\/8$/.test(el.getAttribute('aria-valuetext')||'')));
   assert.match(await phase.getAttribute('aria-valuetext'),/8\/8/);
   const reverseReady=i===0 ? page.waitForResponse(r=>r.url().endsWith('/assets/companions/'+ids[i]+'_reverse_dumbbell_fly.png') && r.ok()) : null;
   await press(page.getByRole('checkbox',{name:'Dambıl ters açış',exact:true}));
   if(reverseReady)await (await reverseReady).finished();
   await press(page.getByRole('button',{name:'Animasyonu duraklat',exact:true}));
   await phase.press('Home');
   await page.waitForFunction(()=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>/1\/8$/.test(el.getAttribute('aria-valuetext')||'')));
   const reverseStart=await chestFigure.screenshot();
   for(let step=0;step<4;step++){
    await phase.press('ArrowRight');
    // Each native semantics action uses the current frame's increment closure.
    // Wait for its exact acknowledgement before sending another key.
    await page.waitForFunction(expected=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>(el.getAttribute('aria-valuetext')||'').endsWith(expected)),`${step+2}/8`);
   }
   await page.waitForFunction(()=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>/5\/8$/.test(el.getAttribute('aria-valuetext')||'')));
   assert.notDeepEqual(reverseStart,await chestFigure.screenshot(),'Bent-over character opens two dumbbells out to the sides');
   await chestFigure.screenshot({path:path.join(shots,`reverse-dumbbell-fly-browser-${ids[i]}.png`)});
   await phase.press('End');
   await page.waitForFunction(()=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>/8\/8$/.test(el.getAttribute('aria-valuetext')||'')));
   assert.match(await phase.getAttribute('aria-valuetext'),/8\/8/);
   const faceReady=i===0 ? page.waitForResponse(r=>r.url().endsWith('/assets/companions/'+ids[i]+'_face_pull.png') && r.ok()) : null;
   await press(page.getByRole('checkbox',{name:'Kablo face pull',exact:true}));
   if(faceReady)await (await faceReady).finished();
   await press(page.getByRole('button',{name:'Animasyonu duraklat',exact:true}));
   await phase.press('Home');
   await page.waitForFunction(()=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>/1\/8$/.test(el.getAttribute('aria-valuetext')||'')));
   const faceStart=await chestFigure.screenshot();
   for(let step=0;step<4;step++){
    await phase.press('ArrowRight');
    // Each native semantics action uses the current frame's increment closure.
    // Wait for its exact acknowledgement before sending another key.
    await page.waitForFunction(expected=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>(el.getAttribute('aria-valuetext')||'').endsWith(expected)),`${step+2}/8`);
   }
   await page.waitForFunction(()=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>/5\/8$/.test(el.getAttribute('aria-valuetext')||'')));
   assert.notDeepEqual(faceStart,await chestFigure.screenshot(),'Character pulls the two rope ends toward either side of the face');
   await chestFigure.screenshot({path:path.join(shots,`face-pull-browser-${ids[i]}.png`)});
   await phase.press('End');
   await page.waitForFunction(()=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>/8\/8$/.test(el.getAttribute('aria-valuetext')||'')));
   assert.match(await phase.getAttribute('aria-valuetext'),/8\/8/);
   const shoulderReady=i===0 ? page.waitForResponse(r=>r.url().endsWith('/assets/companions/'+ids[i]+'_shoulder_press.png') && r.ok()) : null;
   await press(page.getByRole('checkbox',{name:'Omuz pres makinesi',exact:true}));
   if(shoulderReady)await (await shoulderReady).finished();
   await press(page.getByRole('button',{name:'Animasyonu duraklat',exact:true}));
   await phase.press('Home');
   await page.waitForFunction(()=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>/1\/8$/.test(el.getAttribute('aria-valuetext')||'')));
   const shoulderStart=await chestFigure.screenshot();
   for(let step=0;step<4;step++){
    await phase.press('ArrowRight');
    // Each native semantics action uses the current frame's increment closure.
    // Wait for its exact acknowledgement before sending another key.
    await page.waitForFunction(expected=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>(el.getAttribute('aria-valuetext')||'').endsWith(expected)),`${step+2}/8`);
   }
   await page.waitForFunction(()=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>/5\/8$/.test(el.getAttribute('aria-valuetext')||'')));
   assert.notDeepEqual(shoulderStart,await chestFigure.screenshot(),'Seated character presses machine handles from shoulder height overhead');
   await chestFigure.screenshot({path:path.join(shots,`shoulder-press-browser-${ids[i]}.png`)});
   await phase.press('End');
   await page.waitForFunction(()=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>/8\/8$/.test(el.getAttribute('aria-valuetext')||'')));
   assert.match(await phase.getAttribute('aria-valuetext'),/8\/8/);
   const dumbbellShoulderReady=i===0 ? page.waitForResponse(r=>r.url().endsWith('/assets/companions/'+ids[i]+'_shoulder_dumbbell.png') && r.ok()) : null;
   await press(page.getByRole('checkbox',{name:'Dambıl omuz pres',exact:true}));
   if(dumbbellShoulderReady)await (await dumbbellShoulderReady).finished();
   await press(page.getByRole('button',{name:'Animasyonu duraklat',exact:true}));
   await phase.press('Home');
   await page.waitForFunction(()=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>/1\/8$/.test(el.getAttribute('aria-valuetext')||'')));
   const dumbbellShoulderStart=await chestFigure.screenshot();
   for(let step=0;step<4;step++){
    await phase.press('ArrowRight');
    // Each native semantics action uses the current frame's increment closure.
    // Wait for its exact acknowledgement before sending another key.
    await page.waitForFunction(expected=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>(el.getAttribute('aria-valuetext')||'').endsWith(expected)),`${step+2}/8`);
   }
   await page.waitForFunction(()=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>/5\/8$/.test(el.getAttribute('aria-valuetext')||'')));
   assert.notDeepEqual(dumbbellShoulderStart,await chestFigure.screenshot(),'Upright seated character presses two independent dumbbells overhead');
   await chestFigure.screenshot({path:path.join(shots,`shoulder-dumbbell-browser-${ids[i]}.png`)});
   await phase.press('End');
   await page.waitForFunction(()=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>/8\/8$/.test(el.getAttribute('aria-valuetext')||'')));
   assert.match(await phase.getAttribute('aria-valuetext'),/8\/8/);
   const barbellReady=i===0 ? page.waitForResponse(r=>r.url().endsWith('/assets/companions/'+ids[i]+'_overhead_barbell.png') && r.ok()) : null;
   await press(page.getByRole('checkbox',{name:'Halter omuz pres',exact:true}));
   if(barbellReady)await (await barbellReady).finished();
   await press(page.getByRole('button',{name:'Animasyonu duraklat',exact:true}));
   await phase.press('Home');
   await page.waitForFunction(()=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>/1\/8$/.test(el.getAttribute('aria-valuetext')||'')));
   const barbellStart=await chestFigure.screenshot();
   for(let step=0;step<4;step++){
    await phase.press('ArrowRight');
    // Each native semantics action uses the current frame's increment closure.
    // Wait for its exact acknowledgement before sending another key.
    await page.waitForFunction(expected=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>(el.getAttribute('aria-valuetext')||'').endsWith(expected)),`${step+2}/8`);
   }
   await page.waitForFunction(()=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>/5\/8$/.test(el.getAttribute('aria-valuetext')||'')));
   assert.notDeepEqual(barbellStart,await chestFigure.screenshot(),'Standing character presses one connected barbell overhead');
   await chestFigure.screenshot({path:path.join(shots,`barbell-overhead-browser-${ids[i]}.png`)});
   await phase.press('End');
   await page.waitForFunction(()=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>/8\/8$/.test(el.getAttribute('aria-valuetext')||'')));
   assert.match(await phase.getAttribute('aria-valuetext'),/8\/8/);
   const lateralReady=i===0 ? page.waitForResponse(r=>r.url().endsWith('/assets/companions/'+ids[i]+'_lateral_machine.png') && r.ok()) : null;
   await press(page.getByRole('checkbox',{name:'Yana açış makinesi',exact:true}));
   if(lateralReady)await (await lateralReady).finished();
   await press(page.getByRole('button',{name:'Animasyonu duraklat',exact:true}));
   await phase.press('Home');
   await page.waitForFunction(()=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>/1\/8$/.test(el.getAttribute('aria-valuetext')||'')));
   const lateralStart=await chestFigure.screenshot();
   for(let step=0;step<4;step++){
    await phase.press('ArrowRight');
    // Each native semantics action uses the current frame's increment closure.
    // Wait for its exact acknowledgement before sending another key.
    await page.waitForFunction(expected=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>(el.getAttribute('aria-valuetext')||'').endsWith(expected)),`${step+2}/8`);
   }
   await page.waitForFunction(()=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>/5\/8$/.test(el.getAttribute('aria-valuetext')||'')));
   assert.notDeepEqual(lateralStart,await chestFigure.screenshot(),'Seated character lifts both elbow pads sideways toward shoulder height');
   await chestFigure.screenshot({path:path.join(shots,`lateral-machine-browser-${ids[i]}.png`)});
   await phase.press('End');
   await page.waitForFunction(()=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>/8\/8$/.test(el.getAttribute('aria-valuetext')||'')));
   assert.match(await phase.getAttribute('aria-valuetext'),/8\/8/);
   const lateralDumbbellReady=i===0 ? page.waitForResponse(r=>r.url().endsWith('/assets/companions/'+ids[i]+'_lateral_dumbbell.png') && r.ok()) : null;
   await press(page.getByRole('checkbox',{name:'Dambıl yana açış',exact:true}));
   if(lateralDumbbellReady)await (await lateralDumbbellReady).finished();
   await press(page.getByRole('button',{name:'Animasyonu duraklat',exact:true}));
   await phase.press('Home');
   await page.waitForFunction(()=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>/1\/8$/.test(el.getAttribute('aria-valuetext')||'')));
   const lateralDumbbellStart=await chestFigure.screenshot();
   for(let step=0;step<4;step++){
    await phase.press('ArrowRight');
    // Each native semantics action uses the current frame's increment closure.
    // Wait for its exact acknowledgement before sending another key.
    await page.waitForFunction(expected=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>(el.getAttribute('aria-valuetext')||'').endsWith(expected)),`${step+2}/8`);
   }
   await page.waitForFunction(()=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>/5\/8$/.test(el.getAttribute('aria-valuetext')||'')));
   assert.notDeepEqual(lateralDumbbellStart,await chestFigure.screenshot(),'Standing character lifts two independent dumbbells sideways toward shoulder height');
   await chestFigure.screenshot({path:path.join(shots,`lateral-dumbbell-browser-${ids[i]}.png`)});
   await phase.press('End');
   await page.waitForFunction(()=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>/8\/8$/.test(el.getAttribute('aria-valuetext')||'')));
   assert.match(await phase.getAttribute('aria-valuetext'),/8\/8/);
   const lateralCableReady=i===0 ? page.waitForResponse(r=>r.url().endsWith('/assets/companions/'+ids[i]+'_lateral_cable.png') && r.ok()) : null;
   await press(page.getByRole('checkbox',{name:'Kablo yana açış',exact:true}));
   if(lateralCableReady)await (await lateralCableReady).finished();
   await press(page.getByRole('button',{name:'Animasyonu duraklat',exact:true}));
   await phase.press('Home');
   await page.waitForFunction(()=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>/1\/8$/.test(el.getAttribute('aria-valuetext')||'')));
   const lateralCableStart=await chestFigure.screenshot();
   for(let step=0;step<4;step++){
    await phase.press('ArrowRight');
    // Each native semantics action uses the current frame's increment closure.
    // Wait for its exact acknowledgement before sending another key.
    await page.waitForFunction(expected=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>(el.getAttribute('aria-valuetext')||'').endsWith(expected)),`${step+2}/8`);
   }
   await page.waitForFunction(()=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>/5\/8$/.test(el.getAttribute('aria-valuetext')||'')));
   assert.notDeepEqual(lateralCableStart,await chestFigure.screenshot(),'Standing character lifts one cable handle sideways from a fixed low pulley');
   await chestFigure.screenshot({path:path.join(shots,`lateral-cable-browser-${ids[i]}.png`)});
   await phase.press('End');
   await page.waitForFunction(()=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>/8\/8$/.test(el.getAttribute('aria-valuetext')||'')));
   assert.match(await phase.getAttribute('aria-valuetext'),/8\/8/);
   const frontRaiseReady=i===0 ? page.waitForResponse(r=>r.url().endsWith('/assets/companions/'+ids[i]+'_front_raise.png') && r.ok()) : null;
   await press(page.getByRole('checkbox',{name:'Dambıl öne kaldırış',exact:true}));
   if(frontRaiseReady)await (await frontRaiseReady).finished();
   await press(page.getByRole('button',{name:'Animasyonu duraklat',exact:true}));
   await phase.press('Home');
   await page.waitForFunction(()=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>/1\/8$/.test(el.getAttribute('aria-valuetext')||'')));
   const frontRaiseStart=await chestFigure.screenshot();
   for(let step=0;step<4;step++){
    await phase.press('ArrowRight');
    // Each native semantics action uses the current frame's increment closure.
    // Wait for its exact acknowledgement before sending another key.
    await page.waitForFunction(expected=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>(el.getAttribute('aria-valuetext')||'').endsWith(expected)),`${step+2}/8`);
   }
   await page.waitForFunction(()=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>/5\/8$/.test(el.getAttribute('aria-valuetext')||'')));
   assert.notDeepEqual(frontRaiseStart,await chestFigure.screenshot(),'Standing character lifts two dumbbells forward toward shoulder height');
   await chestFigure.screenshot({path:path.join(shots,`front-raise-browser-${ids[i]}.png`)});
   await phase.press('End');
   await page.waitForFunction(()=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>/8\/8$/.test(el.getAttribute('aria-valuetext')||'')));
   assert.match(await phase.getAttribute('aria-valuetext'),/8\/8/);
   const latPulldownReady=i===0 ? page.waitForResponse(r=>r.url().endsWith('/assets/companions/'+ids[i]+'_lat_pulldown.png') && r.ok()) : null;
   await press(page.getByRole('checkbox',{name:'Lat pulldown · sırt çekiş',exact:true}));
   if(latPulldownReady)await (await latPulldownReady).finished();
   await press(page.getByRole('button',{name:'Animasyonu duraklat',exact:true}));
   await phase.press('Home');
   await page.waitForFunction(()=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>/1\/8$/.test(el.getAttribute('aria-valuetext')||'')));
   const latPulldownStart=await chestFigure.screenshot();
   for(let step=0;step<4;step++){
    await phase.press('ArrowRight');
    // Each native semantics action uses the current frame's increment closure.
    // Wait for its exact acknowledgement before sending another key.
    await page.waitForFunction(expected=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>(el.getAttribute('aria-valuetext')||'').endsWith(expected)),`${step+2}/8`);
   }
   await page.waitForFunction(()=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>/5\/8$/.test(el.getAttribute('aria-valuetext')||'')));
   assert.notDeepEqual(latPulldownStart,await chestFigure.screenshot(),'Seated character pulls a connected overhead cable bar down toward the upper chest');
   await chestFigure.screenshot({path:path.join(shots,`lat-pulldown-browser-${ids[i]}.png`)});
   await phase.press('End');
   await page.waitForFunction(()=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>/8\/8$/.test(el.getAttribute('aria-valuetext')||'')));
   assert.match(await phase.getAttribute('aria-valuetext'),/8\/8/);
   const pullUpCount=ids[i]==='aion'?9:8;
   const pullUpReady=i===0 ? page.waitForResponse(r=>r.url().endsWith('/assets/companions/'+ids[i]+'_pull_up.png') && r.ok()) : null;
   await press(page.getByRole('checkbox',{name:'Barfiks',exact:true}));
   if(pullUpReady)await (await pullUpReady).finished();
   await press(page.getByRole('button',{name:'Animasyonu duraklat',exact:true}));
   await phase.press('Home');
   await page.waitForFunction(c=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>(el.getAttribute('aria-valuetext')||'').endsWith(`1/${c}`)),pullUpCount);
   const pullUpStart=await chestFigure.screenshot();
   for(let step=0;step<4;step++){
    await phase.press('ArrowRight');
    // Each native semantics action uses the current frame's increment closure.
    // Wait for its exact acknowledgement before sending another key.
    await page.waitForFunction(expected=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>(el.getAttribute('aria-valuetext')||'').endsWith(expected)),`${step+2}/${pullUpCount}`);
   }
   await page.waitForFunction(c=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>(el.getAttribute('aria-valuetext')||'').endsWith(`5/${c}`)),pullUpCount);
   assert.notDeepEqual(pullUpStart,await chestFigure.screenshot(),'Character raises its whole body on a fixed pull-up bar');
   await chestFigure.screenshot({path:path.join(shots,`pull-up-browser-${ids[i]}.png`)});
   await phase.press('End');
   await page.waitForFunction(c=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>(el.getAttribute('aria-valuetext')||'').endsWith(`${c}/${c}`)),pullUpCount);
   assert.ok((await phase.getAttribute('aria-valuetext')).endsWith(`${pullUpCount}/${pullUpCount}`));
   const assistedPullUpReady=i===0 ? page.waitForResponse(r=>r.url().endsWith('/assets/companions/'+ids[i]+'_assisted_pull_up.png') && r.ok()) : null;
   await press(page.getByRole('checkbox',{name:'Destekli barfiks',exact:true}));
   if(assistedPullUpReady)await (await assistedPullUpReady).finished();
   await press(page.getByRole('button',{name:'Animasyonu duraklat',exact:true}));
   await phase.press('Home');
   await page.waitForFunction(()=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>/1\/8$/.test(el.getAttribute('aria-valuetext')||'')));
   const assistedPullUpStart=await chestFigure.screenshot();
   for(let step=0;step<4;step++){
    await phase.press('ArrowRight');
    // Each native semantics action uses the current frame's increment closure.
    // Wait for its exact acknowledgement before sending another key.
    await page.waitForFunction(expected=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>(el.getAttribute('aria-valuetext')||'').endsWith(expected)),`${step+2}/8`);
   }
   await page.waitForFunction(()=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>/5\/8$/.test(el.getAttribute('aria-valuetext')||'')));
   assert.notDeepEqual(assistedPullUpStart,await chestFigure.screenshot(),'Character and assistance pad rise together under a fixed machine bar');
   await chestFigure.screenshot({path:path.join(shots,`assisted-pull-up-browser-${ids[i]}.png`)});
   await phase.press('End');
   await page.waitForFunction(()=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>/8\/8$/.test(el.getAttribute('aria-valuetext')||'')));
   assert.match(await phase.getAttribute('aria-valuetext'),/8\/8/);
   const cableRowReady=i===0 ? page.waitForResponse(r=>r.url().endsWith('/assets/companions/'+ids[i]+'_cable_row.png') && r.ok()) : null;
   await press(page.getByRole('checkbox',{name:'Oturarak kablo kürek',exact:true}));
   if(cableRowReady)await (await cableRowReady).finished();
   await press(page.getByRole('button',{name:'Animasyonu duraklat',exact:true}));
   await phase.press('Home');
   await page.waitForFunction(()=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>/1\/8$/.test(el.getAttribute('aria-valuetext')||'')));
   const cableRowStart=await chestFigure.screenshot();
   for(let step=0;step<4;step++){
    await phase.press('ArrowRight');
    // Each native semantics action uses the current frame's increment closure.
    // Wait for its exact acknowledgement before sending another key.
    await page.waitForFunction(expected=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>(el.getAttribute('aria-valuetext')||'').endsWith(expected)),`${step+2}/8`);
   }
   await page.waitForFunction(()=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>/5\/8$/.test(el.getAttribute('aria-valuetext')||'')));
   assert.notDeepEqual(cableRowStart,await chestFigure.screenshot(),'Handle pulls horizontally toward the abdomen on a fixed seated machine');
   await chestFigure.screenshot({path:path.join(shots,`cable-row-browser-${ids[i]}.png`)});
   await phase.press('End');
   await page.waitForFunction(()=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>/8\/8$/.test(el.getAttribute('aria-valuetext')||'')));
   assert.match(await phase.getAttribute('aria-valuetext'),/8\/8/);
   const machineRowReady=i===0 ? page.waitForResponse(r=>r.url().endsWith('/assets/companions/'+ids[i]+'_machine_row.png') && r.ok()) : null;
   await press(page.getByRole('checkbox',{name:'Göğüs destekli kürek',exact:true}));
   if(machineRowReady)await (await machineRowReady).finished();
   await press(page.getByRole('button',{name:'Animasyonu duraklat',exact:true}));
   await phase.press('Home');
   await page.waitForFunction(()=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>/1\/8$/.test(el.getAttribute('aria-valuetext')||'')));
   const machineRowStart=await chestFigure.screenshot();
   for(let step=0;step<4;step++){
    await phase.press('ArrowRight');
    // Each native semantics action uses the current frame's increment closure.
    // Wait for its exact acknowledgement before sending another key.
    await page.waitForFunction(expected=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>(el.getAttribute('aria-valuetext')||'').endsWith(expected)),`${step+2}/8`);
   }
   await page.waitForFunction(()=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>/5\/8$/.test(el.getAttribute('aria-valuetext')||'')));
   assert.notDeepEqual(machineRowStart,await chestFigure.screenshot(),'Separate machine handles pull toward ribs against a fixed chest pad');
   await chestFigure.screenshot({path:path.join(shots,`machine-row-browser-${ids[i]}.png`)});
   await phase.press('End');
   await page.waitForFunction(()=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>/8\/8$/.test(el.getAttribute('aria-valuetext')||'')));
   assert.match(await phase.getAttribute('aria-valuetext'),/8\/8/);
   const oneArmRowReady=i===0 ? page.waitForResponse(r=>r.url().endsWith('/assets/companions/'+ids[i]+'_one_arm_row.png') && r.ok()) : null;
   await press(page.getByRole('checkbox',{name:'Tek kol dambıl kürek',exact:true}));
   if(oneArmRowReady)await (await oneArmRowReady).finished();
   await press(page.getByRole('button',{name:'Animasyonu duraklat',exact:true}));
   await phase.press('Home');
   await page.waitForFunction(()=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>/1\/8$/.test(el.getAttribute('aria-valuetext')||'')));
   const oneArmRowStart=await chestFigure.screenshot();
   for(let step=0;step<4;step++){
    await phase.press('ArrowRight');
    // Each native semantics action uses the current frame's increment closure.
    // Wait for its exact acknowledgement before sending another key.
    await page.waitForFunction(expected=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>(el.getAttribute('aria-valuetext')||'').endsWith(expected)),`${step+2}/8`);
   }
   await page.waitForFunction(()=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>/5\/8$/.test(el.getAttribute('aria-valuetext')||'')));
   assert.notDeepEqual(oneArmRowStart,await chestFigure.screenshot(),'One dumbbell rises toward hip while opposite support and bench stay fixed');
   await chestFigure.screenshot({path:path.join(shots,`one-arm-row-browser-${ids[i]}.png`)});
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
  const inclineBox=await movement.boundingBox();assert.ok(inclineBox);
  await page.mouse.click(inclineBox.x+inclineBox.width/2,inclineBox.y+inclineBox.height/2);
  await page.getByRole('button',{name:'Animasyonu duraklat',exact:true}).waitFor();
  assert.equal(await page.getByText(/Bu hareketin özel kareleri hazırlanıyor/).count(),0);
  await press(page.getByRole('button',{name:'Animasyonu duraklat',exact:true}));
  await page.getByRole('slider').first().press('End');
  await page.waitForFunction(()=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>/8\/8$/.test(el.getAttribute('aria-valuetext')||'')));
  await page.screenshot({path:path.join(shots,'incline-press-exercise.png')});
  await press(page.getByRole('button',{name:'Kapat',exact:true}));
  await typeText(search,'Şınav');
  await press(movement);
  await page.getByRole('button',{name:'Animasyonu duraklat',exact:true}).waitFor();
  assert.equal(await page.getByText(/Bu hareketin özel kareleri hazırlanıyor/).count(),0);
  await press(page.getByRole('button',{name:'Animasyonu duraklat',exact:true}));
  await page.getByRole('slider').first().press('End');
  await page.waitForFunction(()=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>/8\/8$/.test(el.getAttribute('aria-valuetext')||'')));
  await page.screenshot({path:path.join(shots,'push-up-exercise.png')});
  await press(page.getByRole('button',{name:'Kapat',exact:true}));
  await typeText(search,'Pec deck göğüs');
  const pecBox=await movement.boundingBox();assert.ok(pecBox);
  await page.mouse.click(pecBox.x+pecBox.width/2,pecBox.y+pecBox.height/2);
  await page.getByRole('button',{name:'Animasyonu duraklat',exact:true}).waitFor();
  assert.equal(await page.getByText(/Bu hareketin özel kareleri hazırlanıyor/).count(),0);
  await press(page.getByRole('button',{name:'Animasyonu duraklat',exact:true}));
  await page.getByRole('slider').first().press('End');
  await page.waitForFunction(()=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>/8\/8$/.test(el.getAttribute('aria-valuetext')||'')));
  await page.screenshot({path:path.join(shots,'pec-deck-exercise.png')});
  await press(page.getByRole('button',{name:'Kapat',exact:true}));
  await typeText(search,'Kablo göğüs açış');
  const cableBox=await movement.boundingBox();assert.ok(cableBox);
  await page.mouse.click(cableBox.x+cableBox.width/2,cableBox.y+cableBox.height/2);
  await page.getByRole('button',{name:'Animasyonu duraklat',exact:true}).waitFor();
  assert.equal(await page.getByText(/Bu hareketin özel kareleri hazırlanıyor/).count(),0);
  await press(page.getByRole('button',{name:'Animasyonu duraklat',exact:true}));
  await page.getByRole('slider').first().press('End');
  await page.waitForFunction(()=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>/8\/8$/.test(el.getAttribute('aria-valuetext')||'')));
  await page.screenshot({path:path.join(shots,'cable-fly-exercise.png')});
  await press(page.getByRole('button',{name:'Kapat',exact:true}));
  await typeText(search,'Dambıl ters açış');
  const reverseBox=await movement.boundingBox();assert.ok(reverseBox);
  await page.mouse.click(reverseBox.x+reverseBox.width/2,reverseBox.y+reverseBox.height/2);
  await page.getByRole('button',{name:'Animasyonu duraklat',exact:true}).waitFor();
  assert.equal(await page.getByText(/Bu hareketin özel kareleri hazırlanıyor/).count(),0);
  await press(page.getByRole('button',{name:'Animasyonu duraklat',exact:true}));
  await page.getByRole('slider').first().press('End');
  await page.waitForFunction(()=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>/8\/8$/.test(el.getAttribute('aria-valuetext')||'')));
  await page.screenshot({path:path.join(shots,'reverse-dumbbell-fly-exercise.png')});
  await press(page.getByRole('button',{name:'Kapat',exact:true}));
  await typeText(search,'Kablo face pull');
  const faceBox=await movement.boundingBox();assert.ok(faceBox);
  await page.mouse.click(faceBox.x+faceBox.width/2,faceBox.y+faceBox.height/2);
  await page.getByRole('button',{name:'Animasyonu duraklat',exact:true}).waitFor();
  assert.equal(await page.getByText(/Bu hareketin özel kareleri hazırlanıyor/).count(),0);
  await press(page.getByRole('button',{name:'Animasyonu duraklat',exact:true}));
  await page.getByRole('slider').first().press('End');
  await page.waitForFunction(()=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>/8\/8$/.test(el.getAttribute('aria-valuetext')||'')));
  await page.screenshot({path:path.join(shots,'face-pull-exercise.png')});
  await press(page.getByRole('button',{name:'Kapat',exact:true}));
  await typeText(search,'Omuz pres makinesi');
  const shoulderBox=await movement.boundingBox();assert.ok(shoulderBox);
  await page.mouse.click(shoulderBox.x+shoulderBox.width/2,shoulderBox.y+shoulderBox.height/2);
  await page.getByRole('button',{name:'Animasyonu duraklat',exact:true}).waitFor();
  assert.equal(await page.getByText(/Bu hareketin özel kareleri hazırlanıyor/).count(),0);
  await press(page.getByRole('button',{name:'Animasyonu duraklat',exact:true}));
  await page.getByRole('slider').first().press('End');
  await page.waitForFunction(()=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>/8\/8$/.test(el.getAttribute('aria-valuetext')||'')));
  await page.screenshot({path:path.join(shots,'shoulder-press-exercise.png')});
  await press(page.getByRole('button',{name:'Kapat',exact:true}));
  await typeText(search,'Dambıl omuz pres');
  const dumbbellShoulderBox=await movement.boundingBox();assert.ok(dumbbellShoulderBox);
  await page.mouse.click(dumbbellShoulderBox.x+dumbbellShoulderBox.width/2,dumbbellShoulderBox.y+dumbbellShoulderBox.height/2);
  await page.getByRole('button',{name:'Animasyonu duraklat',exact:true}).waitFor();
  assert.equal(await page.getByText(/Bu hareketin özel kareleri hazırlanıyor/).count(),0);
  await press(page.getByRole('button',{name:'Animasyonu duraklat',exact:true}));
  await page.getByRole('slider').first().press('End');
  await page.waitForFunction(()=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>/8\/8$/.test(el.getAttribute('aria-valuetext')||'')));
  await page.screenshot({path:path.join(shots,'shoulder-dumbbell-exercise.png')});
  await press(page.getByRole('button',{name:'Kapat',exact:true}));
  await typeText(search,'Halter omuz pres');
  const barbellBox=await movement.boundingBox();assert.ok(barbellBox);
  await page.mouse.click(barbellBox.x+barbellBox.width/2,barbellBox.y+barbellBox.height/2);
  await page.getByRole('button',{name:'Animasyonu duraklat',exact:true}).waitFor();
  assert.equal(await page.getByText(/Bu hareketin özel kareleri hazırlanıyor/).count(),0);
  await press(page.getByRole('button',{name:'Animasyonu duraklat',exact:true}));
  await page.getByRole('slider').first().press('End');
  await page.waitForFunction(()=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>/8\/8$/.test(el.getAttribute('aria-valuetext')||'')));
  await page.screenshot({path:path.join(shots,'barbell-overhead-exercise.png')});
  await press(page.getByRole('button',{name:'Kapat',exact:true}));
  await typeText(search,'Yana açış makinesi');
  const lateralBox=await movement.boundingBox();assert.ok(lateralBox);
  await page.mouse.click(lateralBox.x+lateralBox.width/2,lateralBox.y+lateralBox.height/2);
  await page.getByRole('button',{name:'Animasyonu duraklat',exact:true}).waitFor();
  assert.equal(await page.getByText(/Bu hareketin özel kareleri hazırlanıyor/).count(),0);
  await press(page.getByRole('button',{name:'Animasyonu duraklat',exact:true}));
  await page.getByRole('slider').first().press('End');
  await page.waitForFunction(()=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>/8\/8$/.test(el.getAttribute('aria-valuetext')||'')));
  await page.screenshot({path:path.join(shots,'lateral-machine-exercise.png')});
  await press(page.getByRole('button',{name:'Kapat',exact:true}));
  await typeText(search,'Dambıl yana açış');
  const lateralDumbbellBox=await movement.boundingBox();assert.ok(lateralDumbbellBox);
  await page.mouse.click(lateralDumbbellBox.x+lateralDumbbellBox.width/2,lateralDumbbellBox.y+lateralDumbbellBox.height/2);
  await page.getByRole('button',{name:'Animasyonu duraklat',exact:true}).waitFor();
  assert.equal(await page.getByText(/Bu hareketin özel kareleri hazırlanıyor/).count(),0);
  await press(page.getByRole('button',{name:'Animasyonu duraklat',exact:true}));
  await page.getByRole('slider').first().press('End');
  await page.waitForFunction(()=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>/8\/8$/.test(el.getAttribute('aria-valuetext')||'')));
  await page.screenshot({path:path.join(shots,'lateral-dumbbell-exercise.png')});
  await press(page.getByRole('button',{name:'Kapat',exact:true}));
  await typeText(search,'Kablo yana açış');
  const lateralCableBox=await movement.boundingBox();assert.ok(lateralCableBox);
  await page.mouse.click(lateralCableBox.x+lateralCableBox.width/2,lateralCableBox.y+lateralCableBox.height/2);
  await page.getByRole('button',{name:'Animasyonu duraklat',exact:true}).waitFor();
  assert.equal(await page.getByText(/Bu hareketin özel kareleri hazırlanıyor/).count(),0);
  await press(page.getByRole('button',{name:'Animasyonu duraklat',exact:true}));
  await page.getByRole('slider').first().press('End');
  await page.waitForFunction(()=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>/8\/8$/.test(el.getAttribute('aria-valuetext')||'')));
  await page.screenshot({path:path.join(shots,'lateral-cable-exercise.png')});
  await press(page.getByRole('button',{name:'Kapat',exact:true}));
  await typeText(search,'Dambıl öne kaldırış');
  const frontRaiseBox=await movement.boundingBox();assert.ok(frontRaiseBox);
  await page.mouse.click(frontRaiseBox.x+frontRaiseBox.width/2,frontRaiseBox.y+frontRaiseBox.height/2);
  await page.getByRole('button',{name:'Animasyonu duraklat',exact:true}).waitFor();
  assert.equal(await page.getByText(/Bu hareketin özel kareleri hazırlanıyor/).count(),0);
  await press(page.getByRole('button',{name:'Animasyonu duraklat',exact:true}));
  await page.getByRole('slider').first().press('End');
  await page.waitForFunction(()=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>/8\/8$/.test(el.getAttribute('aria-valuetext')||'')));
  await page.screenshot({path:path.join(shots,'front-raise-exercise.png')});
  await press(page.getByRole('button',{name:'Kapat',exact:true}));
  await typeText(search,'Lat pulldown · sırt çekiş');
  const latPulldownBox=await movement.boundingBox();assert.ok(latPulldownBox);
  await page.mouse.click(latPulldownBox.x+latPulldownBox.width/2,latPulldownBox.y+latPulldownBox.height/2);
  await page.getByRole('button',{name:'Animasyonu duraklat',exact:true}).waitFor();
  assert.equal(await page.getByText(/Bu hareketin özel kareleri hazırlanıyor/).count(),0);
  await press(page.getByRole('button',{name:'Animasyonu duraklat',exact:true}));
  await page.getByRole('slider').first().press('End');
  await page.waitForFunction(()=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>/8\/8$/.test(el.getAttribute('aria-valuetext')||'')));
  await page.screenshot({path:path.join(shots,'lat-pulldown-exercise.png')});
  await press(page.getByRole('button',{name:'Kapat',exact:true}));
  await typeText(search,'Barfiks');
  const pullUpBox=await movement.first().boundingBox();assert.ok(pullUpBox);
  await page.mouse.click(pullUpBox.x+pullUpBox.width/2,pullUpBox.y+pullUpBox.height/2);
  await page.getByRole('button',{name:'Animasyonu duraklat',exact:true}).waitFor();
  assert.equal(await page.getByText(/Bu hareketin özel kareleri hazırlanıyor/).count(),0);
  await press(page.getByRole('button',{name:'Animasyonu duraklat',exact:true}));
  await page.getByRole('slider').first().press('End');
  await page.waitForFunction(()=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>/8\/8$/.test(el.getAttribute('aria-valuetext')||'')));
  await page.screenshot({path:path.join(shots,'pull-up-exercise.png')});
  await press(page.getByRole('button',{name:'Kapat',exact:true}));
  await typeText(search,'Destekli barfiks');
  const assistedPullUpBox=await movement.boundingBox();assert.ok(assistedPullUpBox);
  await page.mouse.click(assistedPullUpBox.x+assistedPullUpBox.width/2,assistedPullUpBox.y+assistedPullUpBox.height/2);
  await page.getByRole('button',{name:'Animasyonu duraklat',exact:true}).waitFor();
  assert.equal(await page.getByText(/Bu hareketin özel kareleri hazırlanıyor/).count(),0);
  await press(page.getByRole('button',{name:'Animasyonu duraklat',exact:true}));
  await page.getByRole('slider').first().press('End');
  await page.waitForFunction(()=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>/8\/8$/.test(el.getAttribute('aria-valuetext')||'')));
  await page.screenshot({path:path.join(shots,'assisted-pull-up-exercise.png')});
  await press(page.getByRole('button',{name:'Kapat',exact:true}));
  await typeText(search,'Oturarak kablo kürek');
  const cableRowBox=await movement.boundingBox();assert.ok(cableRowBox);
  await page.mouse.click(cableRowBox.x+cableRowBox.width/2,cableRowBox.y+cableRowBox.height/2);
  await page.getByRole('button',{name:'Animasyonu duraklat',exact:true}).waitFor();
  assert.equal(await page.getByText(/Bu hareketin özel kareleri hazırlanıyor/).count(),0);
  await press(page.getByRole('button',{name:'Animasyonu duraklat',exact:true}));
  await page.getByRole('slider').first().press('End');
  await page.waitForFunction(()=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>/8\/8$/.test(el.getAttribute('aria-valuetext')||'')));
  await page.screenshot({path:path.join(shots,'cable-row-exercise.png')});
  await press(page.getByRole('button',{name:'Kapat',exact:true}));
  await typeText(search,'Göğüs destekli kürek');
  const machineRowBox=await movement.boundingBox();assert.ok(machineRowBox);
  await page.mouse.click(machineRowBox.x+machineRowBox.width/2,machineRowBox.y+machineRowBox.height/2);
  await page.getByRole('button',{name:'Animasyonu duraklat',exact:true}).waitFor();
  assert.equal(await page.getByText(/Bu hareketin özel kareleri hazırlanıyor/).count(),0);
  await press(page.getByRole('button',{name:'Animasyonu duraklat',exact:true}));
  await page.getByRole('slider').first().press('End');
  await page.waitForFunction(()=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>/8\/8$/.test(el.getAttribute('aria-valuetext')||'')));
  await page.screenshot({path:path.join(shots,'machine-row-exercise.png')});
  await press(page.getByRole('button',{name:'Kapat',exact:true}));
  await typeText(search,'Tek kol dambıl kürek');
  const oneArmRowBox=await movement.boundingBox();assert.ok(oneArmRowBox);
  await page.mouse.click(oneArmRowBox.x+oneArmRowBox.width/2,oneArmRowBox.y+oneArmRowBox.height/2);
  await page.getByRole('button',{name:'Animasyonu duraklat',exact:true}).waitFor();
  assert.equal(await page.getByText(/Bu hareketin özel kareleri hazırlanıyor/).count(),0);
  await press(page.getByRole('button',{name:'Animasyonu duraklat',exact:true}));
  await page.getByRole('slider').first().press('End');
  await page.waitForFunction(()=>Array.from(document.querySelectorAll('[role=slider]')).some(el=>/8\/8$/.test(el.getAttribute('aria-valuetext')||'')));
  await page.screenshot({path:path.join(shots,'one-arm-row-exercise.png')});
  await press(page.getByRole('button',{name:'Kapat',exact:true}));
  await typeText(search,'Barbell eğilerek kürek');
  await press(movement);
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
  // Preferences/load/layout finish after the semantics placeholder appears.
  // Wait for the actual page, then scroll until its lazy hero is exposed.
  try{
  await page.waitForFunction(()=>Array.from(document.querySelectorAll('[aria-label]')).some(e=>e.getAttribute('aria-label').includes('Kendi hikâyenin kahramanı ol.')));
  for(let attempt=0;attempt<8;attempt++){
   if(await page.evaluate(()=>Array.from(document.querySelectorAll('[aria-label]')).some(e=>e.getAttribute('aria-label').includes('Yol arkadaşı sahnesi: Baykuş Ömer'))))break;
   await page.mouse.move(260,600);await page.mouse.wheel(0,attempt===0?600:250);await page.waitForTimeout(200);
   await page.mouse.wheel(170,0);await page.waitForTimeout(200);
  }
  await page.waitForFunction(()=>Array.from(document.querySelectorAll('[aria-label]')).some(e=>e.getAttribute('aria-label').includes('Yol arkadaşı sahnesi: Baykuş Ömer')));
  }catch(error){
   console.error('PHONE HERO DIAGNOSTIC',await page.evaluate(()=>({labels:Array.from(document.querySelectorAll('[aria-label]')).map(e=>e.getAttribute('aria-label')).slice(0,30),companion:JSON.parse(localStorage.getItem('reallife-rpg-data')||'null')?.life?.companion,viewport:[innerWidth,innerHeight]})));
   throw error;
  }
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
  console.log('PASS: four full-body sprite characters, eight chest, bench, incline press and reference-consistent push-up, pec deck, cable fly, dumbbell reverse fly, rope face pull separate seated machine/dumbbell shoulder press and standing connected barbell overhead and seated lateral raise machine and standing dumbbell lateral raise and single-arm low cable lateral raise and dedicated forward dumbbell front raise and connected overhead-cable lat pulldown and dedicated fixed-bar whole-body pull-up and separate counterweight-assisted pull-up with moving blue support pad and dedicated seated horizontal cable row with fixed feet/base and separate chest-supported machine row with fixed blue front pad and single-dumbbell bench-supported one-arm row frames per character, exact chest_press/machine, bench_press/barbell and incline_press/dumbbell routes with physical mouse, other presses remain pending, paused seated movement frame, no task/XP records, persisted character, phone at actual 200 percent, stable reduced-motion frame.');
 }finally{await browser.close();}
})().catch(e=>{console.error(e);process.exitCode=1;});
