function quick_quote_init()
{
     kr_delete_cookie('krqqpid');
     fetch_cookie('krqqpid');
}
function get_e(e)
{
     return (e) ? e : (window.event) ? event : null;
}
function who_fired_event(e)
{
      e = get_e(e);
      if(!e) 
      {
           return;
      }
      var targ = (e.target) ? e.target : (e.srcElement ? e.srcElement : null);
      if(targ && targ.nodeType == 3)
      { 
           targ = targ.parentNode;
      }
      return targ;
}
var selection,
krobj = new krqquote();
function catchSelection()
{
    if (window.getSelection && !window.opera)
    {
          selection = window.getSelection().toString();
    }
    else if(document.getSelection)
    {
          selection = document.getSelection();
    }
    else if(document.selection)
    {
          selection = document.selection.createRange().text;
    }
}
function insertnick(nickname, userid, tag)
{
tag='nick';
    if(userid == 0 || nickname == '' || krquoteit_bburl == '')
    {
        return; 
    }
    else if(userid == '-1')
    {
        nickname = vB_Editor[QR_EditorID].wysiwyg_mode ? '[' + tag + ']' + nickname + '[/' + tag + '], ' : '[' + tag + ']' + nickname + '[/' + tag + '], ';
    }
    else
    {
        nickname = vB_Editor[QR_EditorID].wysiwyg_mode ? '<a href="member.php?u=' + userid + '">[' + tag + ']' + nickname + '[/' + tag + ']</a>, ' : '[url="' + krquoteit_bburl + '/member.php?u=' + userid + '"][' + tag + ']' + nickname + '[/' + tag + '][/url], ';
    }
    vB_Editor[QR_EditorID].insert_text(nickname);
    vB_Editor[QR_EditorID].collapse_selection_end();
    vB_Editor[QR_EditorID].check_focus();
}
function insertquote(selection)
{
    if(selection === '')
    {
          return false;
    }else{
          vB_Editor[QR_EditorID].insert_text(selection);
          vB_Editor[QR_EditorID].collapse_selection_end();
    }
}
//
function kr_set_cookie(name, value, expires, path, domain, secure)
{
    var today = new Date(),
    expires_date = new Date(today.getTime()+(expires));
    today.setTime(today.getTime());
    if(expires)
    {
        expires = expires * 1000 * 60 * 60 * 24;
    }
    document.cookie = name + "=" +escape(value)+((expires)?";expires="+expires_date.toGMTString():"")+((path)?";path="+path:"")+((domain)?";domain="+domain:"")+((secure)?";secure":"");
}
function kr_get_cookie(check_name) 
{
    var a_all_cookies = document.cookie.split(';'),
        i,
        a_temp_cookie = '',
        cookie_name = '',
        cookie_value = '',
        b_cookie_found = false;
    for(i = 0; i < a_all_cookies.length; i++)
    {
        a_temp_cookie = a_all_cookies[i].split('=');
        cookie_name = a_temp_cookie[0].replace(/^\s+|\s+$/g, '');
        if(cookie_name == check_name)
        {
            b_cookie_found = true;
            if(a_temp_cookie.length > 1)
            {
                cookie_value = unescape(a_temp_cookie[1].replace(/^\s+|\s+$/g, ''));
            }
            return cookie_value;
            break;
        }
        a_temp_cookie = null;
        cookie_name = '';
    }
    if(!b_cookie_found)
    {
        return null;
    }
}
function kr_delete_cookie(name, path, domain)
{
    if(kr_get_cookie(name)) 
    {
        console.log("Delete Cookie :: %s", name);
        document.cookie = name + "=" + ((path)?"; path="+path:"")+((domain)?"; domain="+domain:"")+"; expires=Thu, 01-Jan-1970 00:00:01 GMT";
    }
}

function krqquote()
{
    this.nickname = '';
    this.postid = '';
    this.validobj = false;
    this.is_sel_started = false;
    this.insert_over = false;
    this.link_over = false;
    this.mouse_down = false;
    document.write('<div id="krqqdiv" class="smallfont krqq_popupbutton" onmouseout="krobj.settime=setTimeout(\'hide_insert()\',' + krquoteit_displaytime + '); krobj.insert_over = false;" onmousedown="krobj.insert_text();" onmouseover="clearTimeout(krobj.settime); krobj.insert_over=true; catchSelection();" title="' + krquoteit_title + '">' + krquoteit + '</div>');
    this.is_valid_tag = function(evt)
    {
        evt = get_e(evt);
        var targ = who_fired_event(evt);
        if(targ && targ.tagName != 'TEXTAREA' && targ.tagName != 'A' && targ.tagName != 'IMG' && (targ.tagName != 'INPUT' && targ.type != 'TEXT' && targ.type != 'PASSWORD') && (this.nickname && this.postid && this.validobj)) 
        {
            if(kr_get_cookie('krqqpid') !== this.postid)
            {
                kr_set_cookie('krqqpid', this.postid);
                console.log("Set Cookie :: ", 'krqqpid = '+this.postid);
            }
            return true;
        }
        else
        {
            if(kr_get_cookie('krqqpid') !== null && kr_get_cookie('krqqpid') !== '')
            {
                kr_delete_cookie('krqqpid');
            }
            return false;
        }
    }

    this.paste_to_textarea = function(evt)
    {
        this.mouse_down = false;
        if(!this.is_sel_started) 
        {
            return;
        }
        else
        { 
            this.is_sel_started = false;
        }
        evt = get_e(evt);
        var selectext,
        iwp = fetch_object('kr_lquickquote_'+this.postid),
        coords = getMouseCoords(evt),
        iw = fetch_object('krqqdiv');           
        if (window.getSelection && !window.opera)
        {
            selectext = window.getSelection().toString();
        }
        else if (document.getSelection)
        {
            selectext = document.getSelection();
        }
        else if (document.selection)
        {
            selectext = document.selection.createRange().text;
        }
        if(selectext != '' && this.is_valid_tag(evt) && typeof(document.forms.vbform) != 'undefined' && typeof(document.forms.vbform.message) != 'undefined')
        {
            if(krquoteit_ldisplaytime > 0)
            {
                if(iwp !== null)
                {
                    iwp.style.visibility = 'visible';
                }
                else
                {
                    console.error("Object is Null, Check template!");
                }
                this.lsettime = setTimeout(hide_link,krquoteit_ldisplaytime);
            }                                  
            iw.style.left = (coords[0]-80) + 'px';
            iw.style.top = (coords[1]+10) + 'px';
            iw.style.visibility = 'visible';
            this.settime = setTimeout(this.hide_insert,krquoteit_displaytime);
            console.log("Show :: ", 'QWindow: visible; Link: '+((krquoteit_ldisplaytime > 0 && iwp !== null) ? 'visible; postid_'+kr_get_cookie('krqqpid') : 'Always visible; postid_'+kr_get_cookie('krqqpid')));
        }
    }
    this.insert_text = function()
    {
        var selectxt = selection.toString().replace(/(\r?\n\s*){2,}/gi,'\r\n').replace(/^\s+|\s+$/gi,'').replace(/(\ |\t)+/gi,' ');
        if(selectxt == '' || kr_get_cookie('krqqpid') !== this.postid)
        {
            if(krquoteit_ldisplaytime > 0)
            {
                this.hide_link();
            }
            kr_delete_cookie('krqqpid');
        }
        else
        {
            insertquote('[quote="' + this.nickname + ';' + this.postid + '"]' + selectxt + '[/quote]\r\n');
            vB_Editor[QR_EditorID].wysiwyg_mode ? vB_Editor[QR_EditorID].check_focus() : document.vbform.message.focus();
        }
        this.insert_over = false;
        this.link_over = false;
        this.hide_insert();
        if(krquoteit_ldisplaytime > 0)
        {
            this.hide_link();
        }
    }
    this.hide_link = function()
    {
        if(!this.link_over) 
        {
            var iwp = fetch_object('kr_lquickquote_'+this.postid);
            if(iwp)
            {
                iwp.style.visibility = 'hidden';
                console.log("Hide Link :: ", this.postid);
            }
            else
            {
                console.error("Object is Null, Check template!");
            }
        }
    }      
    this.hide_insert = function()
    {
        if(!this.insert_over) 
        {
            var iw = fetch_object('krqqdiv');
            iw.style.left = -100 + 'px';
            iw.style.top = -100 + 'px';
            iw.style.visibility = 'hidden';
            if(kr_get_cookie('krqqpid'))
            {
                console.log("Hide QWindow");
            }
        }
    }
}
function hide_insert() 
{
    krobj.hide_insert();
}
function hide_link() 
{
    krobj.hide_link();
}
function getMouseCoords(e) 
{
    var posx = 0, posy = 0;
    e = get_e(e);
    if (e.pageX || e.pageY)
    {
        posx = e.pageX;
        posy = e.pageY;
    }
    else if(e.clientX || e.clientY)
    {
        posx = e.clientX + document.body.scrollLeft + document.documentElement.scrollLeft;
        posy = e.clientY + document.body.scrollTop + document.documentElement.scrollTop;
    }
    return [posx,posy]
}
document.body.onmousedown = function(evt)
{
    if(typeof krobj == 'object' && krobj.is_valid_tag(evt)) 
    {
        krobj.mouse_down = true;
    }
}
document.body.onmousemove = function()
{
    if(typeof krobj == 'object' && krobj.mouse_down && !krobj.is_sel_started) 
    {
        krobj.is_sel_started = true;
        krobj.mouse_down = false;
    }
}
document.body.onmouseup = function(evt)
{
    if(typeof krobj == 'object') 
    {
        krobj.paste_to_textarea(evt);
    }
}
quick_quote_init();
