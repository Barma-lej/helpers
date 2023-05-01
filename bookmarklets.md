## Bookmarklet (favelet, favlet) for Google Chrome

To create a Bookmarklet create a new bookmark, and past the *Name* into *Name* field and the *URL* into the *URL* destination field

### Go to top

Name: `▲`

URL:

```javascript
javascript:window.scrollTo(0,0);
```

### Go to bottom

Name: `▼`

URL:

```javascript
javascript:dh=document.documentElement.scrollHeight;ch=document.documentElement.clientHeight;if(dh>ch){moveme=dh-ch;window.scrollTo(0,moveme);}
```

### Google Translate (to Russian)

Name: `2Ru`

URL:

```javascript
javascript:qq=""+(window.getSelection?window.getSelection():document.getSelection?document.getSelection():document.selection.createRange().text);if(!qq)qq=location.href/*prompt("Sie haben nichts ausgewählt. Geben Sie bitte einen Suchbegriff ein:","")*/;if(qq!=null)(qq.substr(0,4)=="http"?window.open("https://translate.google.de/translate?sl=auto&tl=ru&js=y&prev=_t&hl=ru&ie=UTF-8&u="+encodeURIComponent(qq),""):window.open("https://translate.google.de/?sl=auto&tl=ru&op=translate&hl=ru&text="+encodeURIComponent(qq),""));void 0;
```
