/* DOM-only interaction checks. This does not substitute for browser layout QA. */
'use strict';
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const dependency = process.argv[2];
const partial = process.argv.includes('--partial');
if (!dependency) throw new Error('Pass the absolute path to an installed linkedom package.');
const {parseHTML} = require(dependency);
const root = __dirname;
const markup = fs.readFileSync(path.join(root,'index.html'),'utf8');
const {window,document} = parseHTML(markup);
const store = new Map();
const fakeLocation = {hash:''};
const events = {printed:0};
const timerIds=[];
const dialog=document.getElementById('search-dialog');
dialog.showModal=function(){this.open=true;this.setAttribute('open','');};
dialog.close=function(){this.open=false;this.removeAttribute('open');};
window.scrollTo=()=>{};
window.print=()=>{events.printed++;};
window.HTMLElement.prototype.focus=function(){};
window.HTMLElement.prototype.scrollIntoView=function(){};
const context = vm.createContext({window,document,console,URL,Blob,Set,Map,JSON,String,Number,Math,Array,RegExp,
  location:fakeLocation,
  history:{replaceState:(a,b,url)=>{fakeLocation.hash=url;}},
  localStorage:{getItem:k=>store.get(k)||null,setItem:(k,v)=>store.set(k,v)},
  requestAnimationFrame:fn=>fn(),
  setTimeout:(fn,ms)=>{const id=setTimeout(fn,ms);timerIds.push(id);return id;},clearTimeout,
});
const assertions=[];
const verify=(condition,label)=>{assert.ok(condition,label);assertions.push(label);};
const run=code=>vm.runInContext(code,context);
const click=node=>{assert.ok(node,'Clickable target exists');node.dispatchEvent(new window.Event('click',{bubbles:true}));};
try {
  vm.runInContext(fs.readFileSync(path.join(root,'app.compiled.js'),'utf8'),context,{filename:'app.compiled.js'});
  verify(document.querySelectorAll('.chapter-card').length===8,'Overview renders eight chapter cards');
  verify(document.querySelector('.hero h1').textContent.includes('One small flower'),'Overview renders story hero');
  verify(document.querySelectorAll('.stats .stat').length===4,'Overview renders campaign scope');
  click(document.getElementById('mobile-menu'));
  verify(document.getElementById('sidebar').classList.contains('open')&&document.getElementById('mobile-menu').getAttribute('aria-expanded')==='true','Mobile navigation opens with accessible state');
  click(document.getElementById('mobile-menu'));
  verify(!document.getElementById('sidebar').classList.contains('open'),'Mobile navigation closes on its toggle');
  const seen=new Set();
  for(let chapter=1;chapter<=8;chapter++){
    if(partial && run(`chapters[${chapter-1}].scenes.length`)===0)continue;
    run(`show('chapter',${chapter})`);
    verify(document.querySelectorAll('details.scene').length===12,`Chapter ${chapter}: twelve scene disclosures render`);
    verify(document.querySelectorAll('.mission-section').length===4,`Chapter ${chapter}: four required missions render`);
    verify(!document.getElementById('main').textContent.includes('undefined'),`Chapter ${chapter}: no unresolved content fields`);
    for(const scene of document.querySelectorAll('details.scene'))seen.add(scene.id);
    verify(document.querySelectorAll('.action-block li').length>=36,`Chapter ${chapter}: concrete player actions render`);
    verify(document.querySelectorAll('.choice-buttons button').length===24,`Chapter ${chapter}: response choices render`);
    verify(document.querySelectorAll('.scene .studio-only').length===12,`Chapter ${chapter}: production contracts render`);
  }
  verify(seen.size===(partial?run('sceneIndex.length'):96),partial?'All currently authored scenes are reachable':'All 96 unique scenes are reachable');
  if(!partial){fakeLocation.hash='#chapter-8-EX-CH08-S12';run('loadHash()');verify(document.getElementById('EX-CH08-S12')?.open,'Direct scene link opens the finale scene');}
  run("show('chapter',1)");
  const firstChoice=document.querySelector('[data-choice-scene]');
  click(firstChoice);
  verify(firstChoice.getAttribute('aria-pressed')==='true','Delegated choice input selects a response');
  verify(document.querySelector('.choice-result').textContent.length>10,'Choice input reveals authored feedback');
  const read=document.querySelector('[data-read]');
  click(read);
  verify(document.getElementById('progress-label').textContent.startsWith('1 / 96'),'Read marker updates progress');
  verify(JSON.parse(store.get('lla-story-edition2')).read.length===1,'Read progress persists locally');
  click(read);
  verify(document.getElementById('progress-label').textContent.startsWith('0 / 96'),'Read marker can be undone');
  click(document.querySelector('[data-action="studio"]'));
  verify(!document.body.classList.contains('reader-mode'),'Studio toggle exposes production information');
  click(document.querySelector('[data-action="reader"]'));
  verify(document.body.classList.contains('reader-mode'),'Read toggle restores reading mode');
  click(document.querySelector('[data-action="expand-all"]'));
  verify([...document.querySelectorAll('.scene')].every(x=>x.open),'Open-all expands all twelve scenes');
  click(document.querySelector('[data-action="collapse-all"]'));
  verify([...document.querySelectorAll('.scene')].every(x=>!x.open),'Close-all collapses all twelve scenes');
  click(document.querySelector('[data-action="search"]'));
  verify(dialog.open,'Search dialog opens');
  const input=document.getElementById('search-input');
  input.value='pressure';input.dispatchEvent(new window.Event('input',{bubbles:true}));
  verify(document.querySelectorAll('.search-hit').length>0,'Search finds full-scene narrative matches');
  const searchHit=document.querySelector('.search-hit');
  const searchId=searchHit.dataset.searchScene;
  click(searchHit);
  verify(!dialog.open&&document.getElementById(searchId)?.open,'Search result opens the matched chapter and scene');
  run("searchResults('<img src=x onerror=alert(1)>')");
  verify(!document.querySelector('#search-results img'),'Search input is never interpolated as active HTML');
  run("show('learning')");
  verify(document.querySelectorAll('.learning-card').length===8,'Learning view covers all eight chapters');
  verify(document.querySelectorAll('.source-card a[href^="https://"]').length>=14,'Learning view exposes primary-source links');
  run("show('crew')");
  verify(document.querySelectorAll('.crew-card').length===8,'Crew view covers four cadets, mentors and plant lineage');
  run("show('timeline')");
  verify(document.querySelectorAll('.timeline-row').length===12,'Timeline bridges all large calendar intervals');
  run("show('continuity')");
  verify(document.querySelectorAll('.lock').length>=12,'Continuity view exposes narrative and physical locks');
  run("show('studio')");
  verify(document.querySelectorAll('.budget-table tbody tr').length===9,'Production view budgets eight chapters and total');
  verify(document.querySelector('.budget-table').textContent.includes('840m / 14h'),'Production view shows full mandatory 10–14h range');
  run('printManuscript()');
  verify(events.printed===1,'Print control invokes print after building the manuscript');
  verify(document.querySelectorAll('#print-root .print-scene').length===(partial?seen.size:96),'Print manuscript contains the complete authored scene set');
  const markdown=run('manuscript()');
  verify((markdown.match(/^#### EX-CH/gm)||[]).length===(partial?seen.size:96),'Markdown export includes the complete authored scene set');
  const css=document.querySelector('style').textContent;
  verify(css.includes('@media(max-width:680px)')&&css.includes('@media print'),'Mobile and print styles are embedded');
  verify(!document.querySelector('script[src],link[rel="stylesheet"],img[src^="http"]'),'HTML has no network-dependent scripts, styles or images');
  verify(markup.includes('lang="bn"'),'Bengali reading guidance has a language tag');
  const result={partial,passed:assertions.length,checks:assertions,verificationBoundary:'DOM-only checks cover content rendering and interactions. Native browser preview was unavailable; responsive geometry, screenshots and printed page layout were not visually inspected.'};
  fs.writeFileSync(path.join(root,'dom-check-results.json'),JSON.stringify(result,null,2));
  console.log(JSON.stringify(result,null,2));
} finally {timerIds.forEach(clearTimeout);}
