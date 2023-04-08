/*! https://github.com/leeoniya/uFuzzy (v1.0.6) */
var uFuzzy=function(){"use strict";const e=new Intl.Collator("en").compare,t=1/0,l=/(?:\s+|^)-[a-z\d]+/gi,n={unicode:!1,interSplit:"[^A-Za-z0-9']+",intraSplit:"[a-z][A-Z]",intraBound:"[A-Za-z][0-9]|[0-9][A-Za-z]|[a-z][A-Z]",interLft:0,interRgt:0,interChars:".",interIns:t,intraChars:"[a-z\\d']",intraIns:0,intraContr:"'[a-z]{1,2}\\b",intraMode:0,intraSlice:[1,t],intraSub:0,intraTrn:0,intraDel:0,intraFilt:()=>!0,sort:(t,l)=>{let{idx:n,chars:r,terms:i,interLft2:s,interLft1:a,start:g,intraIns:f,interIns:h}=t;return n.map(((e,t)=>t)).sort(((t,u)=>r[u]-r[t]||f[t]-f[u]||i[u]+s[u]+.5*a[u]-(i[t]+s[t]+.5*a[t])||h[t]-h[u]||g[t]-g[u]||e(l[n[t]],l[n[u]])))}},r=(e,l)=>0==l?"":1==l?e+"??":l==t?e+"*?":e+`{0,${l}}?`,i="(?:\\b|_)";function s(e){e=Object.assign({},n,e);const{unicode:t,interLft:s,interRgt:a,intraMode:f,intraSlice:h,intraIns:u,intraSub:c,intraTrn:o,intraDel:p,intraContr:m,intraSplit:b,interSplit:d,intraBound:x,intraChars:R}=e;let S=t?"u":"",{intraRules:I}=e;null==I&&(I=e=>{let t=n.intraSlice,l=0,r=0,i=0,s=0,a=e.length;return a>4?(t=h,l=u,r=c,i=o,s=p):3>a||(i=Math.min(o,1),4==a&&(l=Math.min(u,1))),{intraSlice:t,intraIns:l,intraSub:r,intraTrn:i,intraDel:s}});let A=!!b,z=RegExp(b,"g"+S),E=RegExp(d,"g"+S),k=RegExp("^"+d+"|"+d+"$","g"+S),C=RegExp(m,"gi"+S);const L=e=>(e=e.replace(k,"").toLowerCase(),A&&(e=e.replace(z,(e=>e[0]+" "+e[1]))),e.split(E).filter((e=>""!=e))),y=(t,l=0,n=!1)=>{let g=L(t);if(0==g.length)return[];let h,c=Array(g.length).fill("");if(g=g.map(((e,t)=>e.replace(C,(e=>(c[t]=e,""))))),1==f)h=g.map(((e,t)=>{let{intraSlice:l,intraIns:n,intraSub:i,intraTrn:s,intraDel:a}=I(e);if(n+i+s+a==0)return e+c[t];let[g,f]=l,h=e.slice(0,g),u=e.slice(f),o=e.slice(g,f);1==n&&1==h.length&&h!=o[0]&&(h+="(?!"+h+")");let p=o.length,m=[e];if(i)for(let e=0;p>e;e++)m.push(h+o.slice(0,e)+R+o.slice(e+1)+u);if(s)for(let e=0;p-1>e;e++)o[e]!=o[e+1]&&m.push(h+o.slice(0,e)+o[e+1]+o[e]+o.slice(e+2)+u);if(a)for(let e=0;p>e;e++)m.push(h+o.slice(0,e+1)+"?"+o.slice(e+1)+u);if(n){let e=r(R,1);for(let t=0;p>t;t++)m.push(h+o.slice(0,t)+e+o.slice(t)+u)}return"(?:"+m.join("|")+")"+c[t]}));else{let e=r(R,u);2==l&&u>0&&(e=")("+e+")("),h=g.map(((t,l)=>t.split("").map(((e,t,l)=>(1==u&&0==t&&l.length>1&&e!=l[t+1]&&(e+="(?!"+e+")"),e))).join(e)+c[l]))}let o=2==s?i:"",p=2==a?i:"",m=p+r(e.interChars,e.interIns)+o;return l>0?n?h=o+"("+h.join(")"+p+"|"+o+"(")+")"+p:(h="("+h.join(")("+m+")(")+")",h="(.??"+o+")"+h+"("+p+".*)"):(h=h.join(m),h=o+h+p),[RegExp(h,"i"+S),g,c]},j=(e,t,l)=>{let[n]=y(t);if(null==n)return null;let r=[];if(null!=l)for(let t=0;l.length>t;t++){let i=l[t];n.test(e[i])&&r.push(i)}else for(let t=0;e.length>t;t++)n.test(e[t])&&r.push(t);return r};let w=!!x,M=RegExp(d,S),Z=RegExp(x,S);const D=(t,l,n)=>{let[r,i,g]=y(n,1),[f]=y(n,2),h=i.length,u=t.length,c=Array(u).fill(0),o={idx:Array(u),start:c.slice(),chars:c.slice(),terms:c.slice(),interIns:c.slice(),intraIns:c.slice(),interLft2:c.slice(),interRgt2:c.slice(),interLft1:c.slice(),interRgt1:c.slice(),ranges:Array(u)},p=1==s||1==a,m=0;for(let n=0;t.length>n;n++){let u=l[t[n]],c=u.match(r),b=c.index+c[1].length,d=b,x=!1,R=0,I=0,A=0,z=0,E=0,k=0,C=0,L=0,y=[];for(let t=0,l=2;h>t;t++,l+=2){let n=c[l].toLowerCase(),r=i[t]+g[t],f=r.length,o=n.length,m=n==r;if(!m&&c[l+1].length>=f){let e=c[l+1].toLowerCase().indexOf(r);e>-1&&(y.push(d,e,f),d+=T(c,l,e,f),n=r,o=f,m=!0,0==t&&(b=d))}if(p||m){let e=d-1,t=d+o,i=!0,g=!0;if(-1==e||M.test(u[e]))m&&R++;else{if(2==s){x=!0;break}if(w&&Z.test(u[e]+u[e+1]))m&&I++;else{if(1==s){let e=c[l+1],t=d+o;if(e.length>=f){let i,s=0,a=!1,g=RegExp(r,"ig"+S);for(;i=g.exec(e);){s=i.index;let e=t+s,l=e-1;if(-1==l||M.test(u[l])){R++,a=!0;break}if(Z.test(u[l]+u[e])){I++,a=!0;break}}if(a){y.push(d,s,f),d+=T(c,l,s,f),n=r,o=f,m=!0;break}}x=!0;break}i=!1}}if(t==u.length||M.test(u[t]))m&&A++;else{if(2==a){x=!0;break}if(w&&Z.test(u[t-1]+u[t]))m&&z++;else{if(1==a){x=!0;break}g=!1}}m&&(E+=f,i&&g&&k++)}if(o>f&&(L+=o-f),t>0&&(C+=c[l-1].length),!e.intraFilt(r,n,d)){x=!0;break}h-1>t&&(d+=o+c[l+1].length)}if(!x){o.idx[m]=t[n],o.interLft2[m]=R,o.interLft1[m]=I,o.interRgt2[m]=A,o.interRgt1[m]=z,o.chars[m]=E,o.terms[m]=k,o.interIns[m]=C,o.intraIns[m]=L,o.start[m]=b;let e=u.match(f),l=o.ranges[m]=[],r=e.index+e[1].length,i=r,s=r,a=y.length,g=a>0?0:1/0,h=a-3;for(let t=2;e.length>t;t++){let n=e[t].length;if(g>h||y[g]!=r)r+=n;else{let l=y[g+2],s=y[g+1]+l;r+=n+s,i=r-l,e[t+1]=e[t+1].slice(s),g+=3}t%2==0?s=r:n>0&&(l.push(i,s),i=s=r)}s>i&&l.push(i,s),m++}}if(t.length>m)for(let e in o)o[e]=o[e].slice(0,m);return o},T=(e,t,l,n)=>{let r=e[t]+e[t+1].slice(0,l);return e[t-1]+=r,e[t]=e[t+1].slice(l,l+n),e[t+1]=e[t+1].slice(l+n),r.length};return{search:(...t)=>((t,n,r=!1,i=1e3,s)=>{let a=null,f=null,h=[];n=n.replace(l,(e=>(h.push(e.trim().slice(1)),"")));let u,c=L(n);if(h.length>0){if(u=RegExp(h.join("|"),"i"+S),0==c.length){let e=[];for(let l=0;t.length>l;l++)u.test(t[l])||e.push(l);return[e,null,null]}}else if(0==c.length)return[null,null,null];if(r){let e=L(n);if(e.length>1){let l=e.slice().sort(((e,t)=>t.length-e.length));for(let e=0;l.length>e;e++){if(0==s?.length)return[[],null,null];s=j(t,l[e],s)}a=g(e).map((e=>e.join(" "))),f=[];let n=new Set;for(let e=0;a.length>e;e++)if(s.length>n.size){let l=s.filter((e=>!n.has(e))),r=j(t,a[e],l);for(let e=0;r.length>e;e++)n.add(r[e]);f.push(r)}else f.push([])}}null==a&&(a=[n],f=[s?.length>0?s:j(t,n)]);let o=null,p=null;if(h.length>0&&(f=f.map((e=>e.filter((e=>!u.test(t[e])))))),i>=f.reduce(((e,t)=>e+t.length),0)){o={},p=[];for(let l=0;f.length>l;l++){let n=f[l];if(null==n||0==n.length)continue;let r=a[l],i=D(n,t,r),s=e.sort(i,t,r);if(l>0)for(let e=0;s.length>e;e++)s[e]+=p.length;for(let e in i)o[e]=(o[e]??[]).concat(i[e]);p=p.concat(s)}}return[[].concat(...f),o,p]})(...t),split:L,filter:j,info:D,sort:e.sort}}const a=(()=>{let e={A:"ÁÀÃÂÄĄ",a:"áàãâäą",E:"ÉÈÊËĖ",e:"éèêëę",I:"ÍÌÎÏĮ",i:"íìîïį",O:"ÓÒÔÕÖ",o:"óòôõö",U:"ÚÙÛÜŪŲ",u:"úùûüūų",C:"ÇČ",c:"çč",N:"Ñ",n:"ñ",S:"Š",s:"š"},t=new Map,l="";for(let n in e)e[n].split("").forEach((e=>{l+=e,t.set(e,n)}));let n=RegExp(`[${l}]`,"g"),r=e=>t.get(e);return e=>{if("string"==typeof e)return e.replace(n,r);let t=Array(e.length);for(let l=0;e.length>l;l++)t[l]=e[l].replace(n,r);return t}})();function g(e){let t,l,n=(e=e.slice()).length,r=[e.slice()],i=Array(n).fill(0),s=1;for(;n>s;)s>i[s]?(t=s%2&&i[s],l=e[s],e[s]=e[t],e[t]=l,++i[s],s=1,r.push(e.slice())):(i[s]=0,++s);return r}const f=(e,t)=>t?`<mark>${e}</mark>`:e,h=(e,t)=>e+t;return s.latinize=a,s.permute=e=>g([...Array(e.length).keys()]).sort(((e,t)=>{for(let l=0;e.length>l;l++)if(e[l]!=t[l])return e[l]-t[l];return 0})).map((t=>t.map((t=>e[t])))),s.highlight=function(e,t,l=f,n="",r=h){n=r(n,l(e.substring(0,t[0]),!1))??n;for(let i=0;t.length>i;i+=2)n=r(n,l(e.substring(t[i],t[i+1]),!0))??n,t.length-3>i&&(n=r(n,l(e.substring(t[i+1],t[i+2]),!1))??n);return r(n,l(e.substring(t[t.length-1]),!1))??n},s}();
document.addEventListener("DOMContentLoaded", () => {
  let haystackPromise = null;
  let haystack = null;
  let haystackPlain = null;
  let fuzzy = null;
  function loadFuzzy() {
    if (fuzzy !== null) return fuzzy;
    return fuzzy = new uFuzzy({});
  }
  function loadHaystack() {
    if (haystackPromise !== null) return haystackPromise;
    return haystackPromise = new Promise(async (resolve) => {
      let res = await fetch("search.json");
      haystack = await res.json();
      haystackPlain = haystack.map(page => page[4]);
      resolve();
    });
  }
  const searchEl = document.getElementById("search");
  const menuSplits = document.querySelectorAll("#menu .menu-split");
  searchEl.addEventListener("focus", loadHaystack);
  let existingQuery = null;
  let lastOp = 0;
  searchEl.addEventListener("input", () => {
    if (existingQuery !== null) {
      clearTimeout(existingQuery);
      existingQuery = null;
    }
    const query = searchEl.value.trim();
    const queryOp = ++lastOp;
    existingQuery = setTimeout(() => {
      if (query === "") {
        menuSplits[0].classList.remove("show");
        menuSplits[1].classList.add("show");
      } else {
        menuSplits[0].innerText = "Searching...";
        menuSplits[0].classList.add("show");
        menuSplits[1].classList.remove("show");
        loadHaystack().then(() => {
          if (queryOp !== lastOp) return;
          const [idxs, info, order] = loadFuzzy().search(haystackPlain, query);
          if (!order || order.length === 0) {
            menuSplits[0].innerText = "No results found!";
          } else {
            menuSplits[0].innerHTML = "<ul>" + order.map(i => {
              const infoIdx = order[i];
              const resultIdx = info.idx[infoIdx];
              const found = haystack[resultIdx];
              let title = found[2];
              if (found[3]) {
                title = `${title} — ${found[3]}`;
              }
              let url = found[0] + ".html";
              if (found[1]) {
                url = `${url}#${found[1]}`;
              }
              const plain = found[4];
              const ranges = info.ranges[infoIdx];
              const range = [ranges[0], ranges[ranges.length - 1]];
              const ctx = 35;
              let preEl = "";
              let postEl = "";
              let rangeBefore = [range[0] - ctx, range[0]];
              if (rangeBefore[0] < 0) rangeBefore[0] = 0;
              else preEl = "…";
              let rangeAfter = [range[1], range[1] + ctx];
              if (rangeAfter[1] >= plain.length) rangeAfter[1] = plain.length;
              else postEl = "…";
              const pre = plain.substring(...rangeBefore);
              const post = plain.substring(...rangeAfter);
              const snippet = plain.substring(...range);
              return `<li><a href="${url}">${title}</a><br>"${preEl}${pre}<b>${snippet}</b>${post}${preEl}"</li>`;
            }).join("") + "</ul>";
          }
        });
      }
    }, 200);
  });
});
