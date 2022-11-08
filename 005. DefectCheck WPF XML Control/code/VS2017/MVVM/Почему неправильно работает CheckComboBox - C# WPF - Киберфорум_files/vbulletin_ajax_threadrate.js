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
* Adds onclick events to appropriate elements for thread rating
*
* @param	string	The ID of the form that contains the rating options
*/
function vB_AJAX_ThreadRate_Init(formid)
{
	var formobj = fetch_object(formid);

	if (AJAX_Compatible && (typeof vb_disable_ajax == 'undefined' || vb_disable_ajax < 2) && formobj)
	{
		for (var i = 0; i < formobj.elements.length; i++)
		{
			//alert(1);
			if (formobj.elements[i].type == 'submit')
			{
				// prevent the form from submitting when clicking the submit button
				var sbutton = formobj.elements[i];
				var button = document.createElement('input');
				button.type = 'button';
				button.className = sbutton.className;
				button.value     = sbutton.value;
				button.onclick   = vB_AJAX_ThreadRate.prototype.form_click;
				sbutton.parentNode.insertBefore(button, sbutton);
				sbutton.parentNode.removeChild(sbutton);
			}
		}
	}
};

/**
* Class to handle thread rating
*
* @param	object	The form object containing the vote options
*/
function vB_AJAX_ThreadRate(formobj)
{
	this.formobj = formobj;

	// vB_Hidden_Form object to handle form variables
	this.pseudoform = new vB_Hidden_Form('threadrate.php');
	this.pseudoform.add_variable('ajax', 1);
	this.pseudoform.add_variables_from_object(this.formobj);

	// Output object
	this.output_element_id = 'threadrating_current';
};

/**
* Handles AJAX request response
*
* @param	object	YUI AJAX
*/
vB_AJAX_ThreadRate.prototype.handle_ajax_response = function(ajax)
{
	if (ajax.responseXML)
	{
		// check for error first
		var error = ajax.responseXML.getElementsByTagName('error');
		if (error.length)
		{
			// Hide thread rating popup menu now
			if (vBmenu.activemenu == 'threadrating')
			{
				vBmenu.hide();
			}
			alert(error[0].firstChild.nodeValue);
		}
		else
		{
			var newrating = ajax.responseXML.getElementsByTagName('voteavg');
			if (newrating.length && newrating[0].firstChild && newrating[0].firstChild.nodeValue != "")
			{
				fetch_object(this.output_element_id).innerHTML = newrating[0].firstChild.nodeValue;
			}
			// Hide thread rating popup menu now
			if (vBmenu.activemenu == 'threadrating')
			{
				vBmenu.hide();
			}

			var message = ajax.responseXML.getElementsByTagName('message');
			if (message.length)
			{
				alert(message[0].firstChild.nodeValue);
			}
		}
	}
}

/**
* Places the vote
*/
vB_AJAX_ThreadRate.prototype.rate = function()
{
	if (this.pseudoform.fetch_variable('vote') != null)
	{
		YAHOO.util.Connect.asyncRequest("POST", "threadrate.php?t=" + threadid + "&vote=" + PHP.urlencode(this.pseudoform.fetch_variable("vote")), {
			success: this.handle_ajax_response,
			failure: this.handle_ajax_error,
			timeout: vB_Default_Timeout,
			scope: this
		}, SESSIONURL + "securitytoken=" + SECURITYTOKEN + "&" + this.pseudoform.build_query_string());
	}
};

/**
* Handles AJAX Errors
*
* @param	object	YUI AJAX
*/
vB_AJAX_ThreadRate.prototype.handle_ajax_error = function(ajax)
{
	vBulletin_AJAX_Error_Handler(ajax);
	this.formobj.submit();
}

/**
* Handles the form 'submit' action
*/
vB_AJAX_ThreadRate.prototype.form_click = function()
{
	var AJAX_ThreadRate = new vB_AJAX_ThreadRate(this.form);
	AJAX_ThreadRate.rate();
	return false;
};

/*======================================================================*\
|| ####################################################################
|| # NulleD By - FintMax
|| # CVS: $RCSfile$ - $Revision: 39862 $
|| ####################################################################
\*======================================================================*/
