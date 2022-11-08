/*==============================*/
/* Floating Quick Reply         */
/* by kerk http://vbsupport.org */
/*==============================*/
var qrdd;
function do_qrpos(stat)
{
     var objPos = fetch_object('kr_quickreply');
     var objLink = fetch_object('kr_link');
     var s = stat ? 0 : 1;
     var objDD = fetch_object('kr_quickreply_dd'+s);
     if(stat)
     {
           objDD.id = 'kr_quickreply_dd1';
           objPos.style.position = 'fixed';
           objPos.style.width = '50%';
           objDD.style.cursor = 'move';
           objLink.innerHTML = '[<a href="javascript:do_qrpos(0);">'+krflqr_normal+'</a>]';
           center_element(objPos);
           get_post(stat);
     }else{
           objDD.id = 'kr_quickreply_dd0';
           objPos.style.position = '';
           objPos.style.width = '';
           objPos.style.top = '';
           objPos.style.left = '';
           objDD.style.cursor = 'default';
           objLink.innerHTML = '[<a href="javascript:do_qrpos(1);">'+krflqr_float+'</a>]';
           get_post(stat);
     }
     YAHOO.util.Event.onDOMReady(function() 
     {  
           qrdd = new YAHOO.util.DD("kr_quickreply");
           qrdd.setHandleElId("kr_quickreply_dd1");
     });
}
function get_post(stat)
{
	 var spans = fetch_tags(fetch_object('posts'), 'span');
	 for (var i = 0; i < spans.length; i++)
	 {
		if(spans[i].hasChildNodes() && spans[i].id && spans[i].id.substr(0, 11) == 'kr_floatqr_')
		{
			if(stat)
            {
                  spans[i].innerHTML = '[<a href="javascript:do_qrpos(0);">'+krflqr_normal+'</a>]';
            }else{
                  spans[i].innerHTML = '[<a href="javascript:do_qrpos(1);">'+krflqr_float+'</a>]';            
            }
		}
	 }
}


