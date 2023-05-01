Google Translate (to Russian)
```javascript
javascript:qq=""+(window.getSelection?window.getSelection():document.getSelection?document.getSelection():document.selection.createRange().text);if(!qq)qq=location.href/*prompt("Sie haben nichts ausgewählt. Geben Sie bitte einen Suchbegriff ein:","")*/;if(qq!=null)(qq.substr(0,4)=="http"?window.open("https://translate.google.de/translate?sl=auto&tl=ru&js=y&prev=_t&hl=ru&ie=UTF-8&u="+encodeURIComponent(qq),""):window.open("https://translate.google.de/?sl=auto&tl=ru&op=translate&hl=ru&text="+encodeURIComponent(qq),""));void 0;
```
