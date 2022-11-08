/*!======================================================================*\
|| #################################################################### ||
|| # vBulletin 3.8.7
|| # ---------------------------------------------------------------- # ||
|| # Copyright ©2000-2011 vBulletin Solutions, Inc. All Rights Reserved. ||
|| # This file may not be redistributed in whole or significant part. # ||
|| # ---------------- VBULLETIN IS NOT FREE SOFTWARE ---------------- # ||
|| # http://www.vbulletin.com | http://www.vbulletin.com/license.html # ||
|| #################################################################### ||
\*======================================================================*/

/**
* Register a post for ajax reputation
*
* @param	string	Postid
*
* @return	vB_Reputation_Object
*/
function vbrep_register(postid)
{
	if (typeof vBrep == 'object' && typeof postid != 'undefined')
	{
		return vBrep.register(postid);
	}
}

// #############################################################################
// vB_Reputation_Handler
// #############################################################################

/**
* vBulletin reputation registry
*/
function vB_Reputation_Handler()
{
	this.reps = new Array();
	this.ajax = new Array();
};

// =============================================================================
// vB_Reputation_Handler methods

/**
* Register a control object as a reputation control
*
* @param	string	ID of the control object
*
* @return	vB_Reputation_Object
*/
vB_Reputation_Handler.prototype.register = function(postid)
{
	if (AJAX_Compatible && (typeof vb_disable_ajax == 'undefined' || vb_disable_ajax < 2))
	{
		this.reps[postid] = new vB_Reputation_Object(postid);
		var obj;
		if (obj = fetch_object('reputation_' + postid))
		{
			obj.onclick = vB_Reputation_Object.prototype.reputation_click;
			return this.reps[postid];
		}
	}
};

// #############################################################################
// initialize reputation registry

vBrep = new vB_Reputation_Handler();

// #############################################################################
// vB_Reputation_Object
// #############################################################################

/**
* vBulletin Reputation class constructor
*
* Manages a single reputation and control object
* Initializes control object
*
* @param	string	postid
*/
function vB_Reputation_Object(postid)
{
	this.postid = postid;
	this.divname = 'reputationmenu_' + postid + '_menu';
	this.divobj = null;
	this.postobj = fetch_object('post' + postid);

	this.vbmenuname = 'reputationmenu_' + postid;
	this.vbmenu = null;

	this.xml_sender_populate = null;
	this.xml_sender_submit = null;
}

/**
* Submit OnReadyStateChange callback. Uses a closure to keep state.
* Remember to use me instead of "this" inside this function!
*/
vB_Reputation_Object.prototype.onreadystatechange_submit = function(ajax)
{
	if (ajax.responseXML)
	{
		// Register new menu item for this reputation icon
		if (!this.vbmenu)
		{
			this.vbmenu = vbmenu_register(this.vbmenuname, true);
			// Remove menu's mouseover event
			fetch_object(this.vbmenu.controlkey).onmouseover = '';
			fetch_object(this.vbmenu.controlkey).onclick = '';
		}

		// check for error first
		var error = ajax.responseXML.getElementsByTagName('error');
		if (error.length)
		{
			this.vbmenu.hide(fetch_object(this.vbmenuname));
			alert(error[0].firstChild.nodeValue);
		}
		else
		{
			this.vbmenu.hide(fetch_object(this.vbmenuname));
			var repinfo =  ajax.responseXML.getElementsByTagName('reputation')[0];
			var repdisplay = repinfo.getAttribute('repdisplay');
			var reppower = repinfo.getAttribute('reppower');
			var userid = repinfo.getAttribute('userid');

			var spans = fetch_tags(document, 'span');
			var match = null;

			for (var i = 0; i < spans.length; i++)
			{
				if (match = spans[i].id.match(/^reppower_(\d+)_(\d+)$/))
				{
					if (match[2] == userid)
					{
						spans[i].innerHTML = reppower;
					}
				}
				else if (match = spans[i].id.match(/^repdisplay_(\d+)_(\d+)$/))
				{
					if (match[2] == userid)
					{
						spans[i].innerHTML = repdisplay;
					}
				}
			}
			alert(repinfo.firstChild.nodeValue);
		}
	}
}

/**
* Populate OnReadyStateChange callback. Uses a closure to keep state.
* Remember to use me instead of "this" inside this function!
*/
vB_Reputation_Object.prototype.onreadystatechange_populate = function(ajax)
{
	if (ajax.responseXML)
	{
		// check for error first
		var error = ajax.responseXML.getElementsByTagName('error');
		if (error.length)
		{
			alert(error[0].firstChild.nodeValue);
		}
		else
		{
			if (!this.divobj)
			{
				// Create new div to hold reputation menu html
				this.divobj = document.createElement('div');
				this.divobj.id = this.divname;
				this.divobj.style.display = 'none';
				this.divobj.onkeypress = vB_Reputation_Object.prototype.repinput_onkeypress; //TODO
				this.postobj.parentNode.appendChild(this.divobj);

				this.vbmenu = vbmenu_register(this.vbmenuname, true);
				// Remove menu's mouseover event
				fetch_object(this.vbmenu.controlkey).onmouseover = '';
				fetch_object(this.vbmenu.controlkey).onclick = '';
			}

			this.divobj.innerHTML = ajax.responseXML.getElementsByTagName('reputationbit')[0].firstChild.nodeValue;

			var inputs = fetch_tags(this.divobj, 'input');
			for (var i = 0; i < inputs.length; i++)
			{
				if (inputs[i].type == 'submit')
				{
					var sbutton = inputs[i];
					var button = document.createElement('input');
					button.type = 'button';
					button.className = sbutton.className;
					button.value = sbutton.value;
					button.onclick = vB_Reputation_Object.prototype.submit_onclick;
					sbutton.parentNode.insertBefore(button, sbutton);
					sbutton.parentNode.removeChild(sbutton);
					button.name = sbutton.name;
					button.id = sbutton.name + '_' + this.postid
				}
			}

			this.vbmenu.show(fetch_object(this.vbmenuname));
		}
	}
}

/**
* Handles click events on reputation icon
*/
vB_Reputation_Object.prototype.reputation_click = function (e)
{
	e = e ? e : window.event;

	do_an_e(e);
	var postid = this.id.substr(this.id.lastIndexOf('_') + 1);
	var repobj = vBrep.reps[postid];

	// fetch and return reputation html
	if (repobj.vbmenu == null)
	{
		repobj.populate();
	}
	else if (vBmenu.activemenu != repobj.vbmenuname)
	{
		repobj.vbmenu.show(fetch_object(repobj.vbmenuname));
	}
	else
	{
		repobj.vbmenu.hide();
	}

	return true;
}

/**
* Handles click events on reputation submit button
*/

vB_Reputation_Object.prototype.submit_onclick = function (e)
{
	e = e ? e : window.event;
	do_an_e(e);

	var postid = this.id.substr(this.id.lastIndexOf('_') + 1);
	var repobj = vBrep.reps[postid];
	repobj.submit();

	return false;
}

/**
*	Catches the keypress of the reputation controls to keep them from submitting to inlineMod
*/
vB_Reputation_Object.prototype.repinput_onkeypress = function (e)
{
	e = e ? e : window.event;

	switch (e.keyCode)
	{
		case 13:
		{
			vBrep.reps[this.id.split(/_/)[1]].submit();
			return false;
		}
		default:
		{
			return true;
		}
	}
}

/**
* Queries for proper response to reputation, response varies
*
*/
vB_Reputation_Object.prototype.populate = function()
{
	YAHOO.util.Connect.asyncRequest("POST", "reputation.php?p=" + this.postid, {
		success: this.onreadystatechange_populate,
		failure: this.handle_ajax_error,
		timeout: vB_Default_Timeout,
		scope: this
	}, SESSIONURL + "securitytoken=" + SECURITYTOKEN + "&p=" + this.postid + "&ajax=1");
}

/**
* Handles AJAX Errors
*
* @param	object	YUI AJAX
*/
vB_Reputation_Object.prototype.handle_ajax_error = function(ajax)
{
	//TODO: Something bad happened, try again
	vBulletin_AJAX_Error_Handler(ajax);
};

/**
* Submits reputation
*
*/
vB_Reputation_Object.prototype.submit = function()
{
	this.psuedoform = new vB_Hidden_Form('reputation.php');
	this.psuedoform.add_variable('ajax', 1);
	this.psuedoform.add_variables_from_object(this.divobj);

	YAHOO.util.Connect.asyncRequest("POST", "reputation.php?do=addreputation&p=" + this.psuedoform.fetch_variable('p'), {
		success: this.onreadystatechange_submit,
		failure: vBulletin_AJAX_Error_Handler,
		timeout: vB_Default_Timeout,
		scope: this
	}, SESSIONURL + "securitytoken=" + SECURITYTOKEN + "&" + this.psuedoform.build_query_string());
}

/*======================================================================*\
|| ####################################################################
|| # NulleD By - FintMax
|| # CVS: $RCSfile$ - $Revision: 39862 $
|| ####################################################################
\*======================================================================*/
