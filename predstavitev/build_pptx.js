const pptx = require("pptxgenjs");
const p = new pptx();
p.defineLayout({ name: "W", width: 13.333, height: 7.5 });
p.layout = "W";
p.author = "Matija Gusel, Anej Vollmeier";
p.title = "HealthTrackMe";

const BG="070B13", SURF="0F1624", ALT="121B2C", BORD="243047",
      TXT="F5F7FB", MUT="94A3B8", ACC="5B8DEF", GRN="5FB878",
      PUR="7E7BF5", ORG="D4956A", WAT="3FA9F5", RED="FF6B6B";
const HEAD="Calibri", BODY="Calibri";
const shadow=()=>({type:"outer",color:"000000",blur:9,offset:3,angle:90,opacity:0.35});

function card(s,x,y,w,h,fill=SURF){
  s.addShape(p.shapes.ROUNDED_RECTANGLE,{x,y,w,h,rectRadius:0.12,
    fill:{color:fill},line:{color:BORD,width:1},shadow:shadow()});
}
function dot(s,x,y,color,d=0.46){
  s.addShape(p.shapes.OVAL,{x,y,w:d,h:d,fill:{color},line:{type:"none"}});
}
function kicker(s,t){s.addText(t,{x:0.7,y:0.55,w:10,h:0.4,fontFace:HEAD,fontSize:13,
  bold:true,color:ACC,charSpacing:3,margin:0});}

// ───────────────────── Slide 1 — Title ─────────────────────
let s=p.addSlide(); s.background={color:BG};
kicker(s,"PRAKTIKUM 2  ·  FERI  ·  2025/26");
s.addText([{text:"Health",options:{color:TXT}},{text:"TrackMe",options:{color:ACC}}],
  {x:0.66,y:1.35,w:8.5,h:1.4,fontFace:HEAD,fontSize:60,bold:true,margin:0});
s.addText("Tvoje zdravje, ki se spremlja samodejno — brez ročnega vnašanja. Koraki, spanje, srčni utrip in vadbe se iz telefona in ure pretočijo na eno mesto ter postanejo vpogledi.",
  {x:0.7,y:3.05,w:7.7,h:1.8,fontFace:BODY,fontSize:20,color:"C7D2E5",lineSpacingMultiple:1.25,margin:0});
s.addText([{text:"avtorja ",options:{color:MUT}},{text:"Matija Gusel & Anej Vollmeier",options:{color:TXT,bold:true}},
  {text:"   ·   Flutter · Spring Boot · PostgreSQL · Railway",options:{color:MUT}}],
  {x:0.7,y:6.35,w:12,h:0.5,fontFace:BODY,fontSize:15,margin:0});
// right mini stat cards (resnične vrednosti iz aplikacije)
const mini=[["9.148","povprečje korakov / teden",GRN],["7h 30m","spanja sinoči",PUR],["57 bpm","utrip v mirovanju",RED]];
mini.forEach((m,i)=>{const y=1.5+i*1.55; card(s,9.1,y,3.5,1.3);
  dot(s,9.4,y+0.42,m[2]);
  s.addText(m[0],{x:10.05,y:y+0.18,w:2.4,h:0.55,fontFace:HEAD,fontSize:26,bold:true,color:TXT,margin:0});
  s.addText(m[1],{x:10.05,y:y+0.74,w:2.5,h:0.35,fontFace:BODY,fontSize:12,color:MUT,margin:0});});

// ───────────────────── Slide 2 — Problem→Solution ─────────────────────
s=p.addSlide(); s.background={color:BG};
kicker(s,"IDEJA");
s.addText("Ročno beleženje zdravja je zamudno — zato ga ne počnemo.",
  {x:0.7,y:1.05,w:12,h:1.0,fontFace:HEAD,fontSize:34,bold:true,color:TXT,margin:0});
const feats=[
  ["Samodejna sinhronizacija",ACC,"Bere korake, srčni utrip, spanje in vadbe iz Health Connecta — v ospredju in v ozadju. Brez tipkanja."],
  ["Zaznavanje na napravi",PUR,"Iz samega telefona zazna nočno spanje ter sprehode in teke, nato jih predlaga v potrditev."],
  ["Vpogledi in svetovanje",WAT,"Tedenski UI-povzetki in pomočnik »vprašaj svoje podatke«, z e-poštnimi poročili — na podlagi tvojih trendov."],
  ["Navade in igrifikacija",GRN,"Nizi, raven Zdravstvenega ščita, opomniki za zdravila in lestvica prijateljev te ohranjajo pri beleženju."]];
feats.forEach((f,i)=>{const x=0.7+(i%2)*6.1, y=2.55+Math.floor(i/2)*2.15;
  card(s,x,y,5.85,1.9);
  dot(s,x+0.35,y+0.32,f[1],0.5);
  s.addText(f[0],{x:x+1.05,y:y+0.3,w:4.5,h:0.5,fontFace:HEAD,fontSize:19,bold:true,color:TXT,margin:0});
  s.addText(f[2],{x:x+0.38,y:y+0.95,w:5.1,h:0.85,fontFace:BODY,fontSize:13.5,color:MUT,lineSpacingMultiple:1.2,margin:0});});

// ───────────────────── Slide 3 — Kaj ponuja (funkcije) ─────────────────────
s=p.addSlide(); s.background={color:BG};
kicker(s,"KAJ PONUJA");
s.addText("Vse tvoje zdravje na enem mestu",
  {x:0.7,y:1.05,w:12,h:0.9,fontFace:HEAD,fontSize:34,bold:true,color:TXT,margin:0});
const fx=[
  ["Nadzorna plošča",ACC,"Pregled dneva in priljubljene kartice"],
  ["Aktivnost",GRN,"Koraki, hoja, tek in kolesarjenje"],
  ["Spanje",PUR,"Nočno spanje in cilj 7 h"],
  ["Vitalni znaki",RED,"Utrip, stres, krvni tlak, SpO₂"],
  ["Zdravila",ORG,"Urnik, odmerki in opomniki"],
  ["Hidracija",WAT,"Dnevni vnos vode"],
  ["Vpogledi & trendi",ACC,"Tedenski UI-povzetki"],
  ["Ščit & nizi",PUR,"Ravni, XP in nizi (streaki)"],
  ["Prijatelji",GRN,"Lestvica in primerjava"]];
fx.forEach((f,i)=>{const x=0.7+(i%3)*4.18, y=2.15+Math.floor(i/3)*1.5;
  card(s,x,y,3.85,1.3);
  dot(s,x+0.32,y+0.42,f[1],0.42);
  s.addText(f[0],{x:x+0.86,y:y+0.26,w:2.85,h:0.4,fontFace:HEAD,fontSize:16,bold:true,color:TXT,margin:0});
  s.addText(f[2],{x:x+0.86,y:y+0.66,w:2.85,h:0.5,fontFace:BODY,fontSize:11,color:MUT,lineSpacingMultiple:1.1,margin:0});});

// ───────────────────── Slide 4 — Architecture ─────────────────────
s=p.addSlide(); s.background={color:BG};
kicker(s,"KAKO JE ZGRAJENO");
s.addText("Čista, večplastna arhitektura",
  {x:0.7,y:1.05,w:12,h:0.9,fontFace:HEAD,fontSize:34,bold:true,color:TXT,margin:0});
const nodes=[
  ["Aplikacija Flutter","Material UI za Android, go_router. Storitvi za sinhronizacijo v ospredju in ozadju ter zaznavanje spanja/hoje na napravi.","HEALTH CONNECT · WORKMANAGER",ACC],
  ["Spring Boot · Kotlin","REST API, avtentikacija JWT z lastništvom na uporabnika, JPA/ORM, migracije Flyway. Vpogledi Groq/LLM + e-poštna poročila.","RAILWAY",PUR],
  ["PostgreSQL","En vnos na dan za vitalne znake in spanje, aktivnosti, zdravila in vpoglede — verzionirana shema.","UPRAVLJA FLYWAY",WAT]];
nodes.forEach((n,i)=>{const x=0.7+i*4.18, y=2.55;
  card(s,x,y,3.85,2.85);
  dot(s,x+0.32,y+0.34,n[3],0.42);
  s.addText(n[0],{x:x+0.86,y:y+0.32,w:2.9,h:0.5,fontFace:HEAD,fontSize:18,bold:true,color:TXT,margin:0});
  s.addText(n[1],{x:x+0.34,y:y+0.95,w:3.2,h:1.4,fontFace:BODY,fontSize:13,color:MUT,lineSpacingMultiple:1.22,margin:0});
  s.addText(n[2],{x:x+0.34,y:y+2.4,w:3.2,h:0.35,fontFace:BODY,fontSize:10.5,bold:true,color:ACC,charSpacing:1,margin:0});
  if(i<2) s.addText("›",{x:x+3.78,y:y+1.0,w:0.45,h:0.8,fontFace:HEAD,fontSize:34,bold:true,color:"3B4A63",align:"center",margin:0});});
// tech-stack chips
const chips=["Flutter","Kotlin / Spring Boot","PostgreSQL","Health Connect","JWT + prijava Google","Groq · Llama 3.3","E-pošta Brevo","GitHub Actions → Firebase","Railway"];
let cx=0.7, cy=5.85;
chips.forEach(c=>{const w=0.34+c.length*0.105; if(cx+w>12.7){cx=0.7;cy+=0.62;}
  s.addShape(p.shapes.ROUNDED_RECTANGLE,{x:cx,y:cy,w,h:0.48,rectRadius:0.24,fill:{color:ALT},line:{color:BORD,width:1}});
  s.addText(c,{x:cx,y:cy,w,h:0.48,fontFace:BODY,fontSize:12,bold:true,color:MUT,align:"center",valign:"middle",margin:0});
  cx+=w+0.18;});

// ───────────────────── Slide 5 — Demo + status ─────────────────────
s=p.addSlide(); s.background={color:BG};
kicker(s,"V ŽIVO");
s.addShape(p.shapes.ROUNDED_RECTANGLE,{x:0.7,y:1.15,w:11.93,h:1.15,rectRadius:0.14,
  fill:{color:ACC,transparency:84},line:{color:ACC,width:1.5},shadow:shadow()});
s.addText("▶   Demo v živo — prijava in sprehod skozi aplikacijo",
  {x:1.1,y:1.15,w:11,h:1.15,fontFace:HEAD,fontSize:24,bold:true,color:TXT,valign:"middle",margin:0});
const pills=[["Samodejna sinhronizacija in zgodovina",GRN,1],["Zaznavanje spanja in hoje",GRN,1],["Pregledni grafi in dnevne kartice",GRN,1],
  ["UI vpogledi in tedenska e-pošta",GRN,1],["HRV iz Health Connecta",ORG,0],["Obvestila s predlogi v ozadju",ORG,0]];
let px=0.7, py=2.75;
pills.forEach(pl=>{const w=0.7+pl[0].length*0.108; if(px+w>12.7){px=0.7;py+=0.7;}
  s.addShape(p.shapes.ROUNDED_RECTANGLE,{x:px,y:py,w,h:0.58,rectRadius:0.14,
    fill:{color:pl[1],transparency:86},line:{color:pl[1],width:1}});
  s.addText((pl[2]?"✓  ":"◆  ")+pl[0],{x:px,y:py,w,h:0.58,fontFace:BODY,fontSize:13.5,bold:true,
    color:pl[1],align:"center",valign:"middle",margin:0});
  px+=w+0.2;});
s.addText([{text:"Kaj smo se naučili:  ",options:{bold:true,color:TXT}},
  {text:"najtežji hrošč ni bil funkcija — sinhronizacija je delovala v razhroščevalni različici, a je v izdani tiho odpovedala (manjkajoče dovoljenje v manifestu). Pravo vrednost je prineslo testiranje na svežem računu, ne na razvijalčevem. CI samodejno zgradi in pošlje APK testerjem; zaledje se samo namesti na Railway.",options:{color:MUT}}],
  {x:0.7,y:5.35,w:11.93,h:1.9,fontFace:BODY,fontSize:15.5,lineSpacingMultiple:1.35,margin:0});

p.writeFile({fileName:"HealthTrackMe.pptx"}).then(f=>console.log("WROTE",f));
