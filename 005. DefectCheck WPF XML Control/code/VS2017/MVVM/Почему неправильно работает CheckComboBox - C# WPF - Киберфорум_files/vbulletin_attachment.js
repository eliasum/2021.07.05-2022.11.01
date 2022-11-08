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


// #############################################################################
// vB_Attachment
// #############################################################################

/**
* Class to deal with attachments
*
* @param	string	ID of the HTML element to contain the list of attachments
* @param	string	ID of the editor object
*/
function vB_Attachment(listobjid, editorid)
{
	this.attachments = new Array();
	this.menu_contents = new Array();
	this.windows = new Array();

	this.listobjid = listobjid;

	if (editorid == '')
	{
		for (editorid in vB_Editor)
		{
			if (YAHOO.lang.hasOwnProperty(vB_Editor, editorid))
			{
				this.editorid = editorid;
				break;
			}
		}
	}
	else
	{
		this.editorid = (editorid ? editorid : null);
	}
};

// =============================================================================
// vB_Attachment methods

/**
* Does the editor popup exist in a built state?
*
* @package	vBulletin
* @version	$Revision: 39862 $
* @date		$Date: 2010-10-18 18:16:44 -0700 (Mon, 18 Oct 2010) $
* @author	Freddie Bingham, vBulletin Development Team
*
* @return	boolean
*/
vB_Attachment.prototype.popup_exists = function()
{
	if (
		this.editorid &&
		((typeof vB_Editor[this.editorid].popups['attach'] != 'undefined' && vB_Editor[this.editorid].popups['attach'] != null)
		||
		(!vB_Editor[this.editorid].popupmode && typeof vB_Editor[this.editorid].buttons['attach'] != 'undefined' && vB_Editor[this.editorid].buttons['attach'] != null))
	)
	{
		return true;
	}
	else
	{
		return false;
	}
};

/**
* Add a new attachment
*
* @param	integer	Attachment ID
* @param	string	File name
* @param	string	File size
* @param	string	Path to item's image (images/attach/jpg.gif etc.)
*/
vB_Attachment.prototype.add = function(id, filename, filesize, imgpath)
{
	this.attachments[id] = new Array();
	this.attachments[id] = {
		'filename' : filename,
		'filesize' : filesize,
		'imgpath'  : imgpath
	};

	this.update_list();
};

/**
* Remove an attachment
*
* @param	integer	Attachment ID
*/
vB_Attachment.prototype.remove = function(id)
{
	if (typeof this.attachments[id] != 'undefined')
	{
		this.attachments[id] = null;

		this.update_list();
	}
};

/**
* Do we have any attachments?
*
* @return	boolean
*/
vB_Attachment.prototype.has_attachments = function()
{
	for (var id in this.attachments)
	{
		if (YAHOO.lang.hasOwnProperty(this.attachments, id) && this.attachments[id] != null)
		{
			return true;
		}
	}
	return false;
};

/**
* Reset the attachments array
*/
vB_Attachment.prototype.reset = function()
{
	this.attachments = new Array();

	this.update_list();
};

/**
* Build Attachments List
*
* @param	string	ID of the HTML element to contain the list of attachments
*/
vB_Attachment.prototype.build_list = function(listobjid)
{
	var listobj = fetch_object(listobjid);

	if (listobjid != null)
	{
		while (listobj.hasChildNodes())
		{
			listobj.removeChild(listobj.firstChild);
		}

		for (var id in this.attachments)
		{
			if (!YAHOO.lang.hasOwnProperty(this.attachments, id))
			{
				continue;
			}

			var div = document.createElement('div');
			// try to use the template if it's been submitted to Javascript
			if (typeof newpost_attachmentbit != 'undefined')
			{
				div.innerHTML = construct_phrase(newpost_attachmentbit,
					this.attachments[id]['imgpath'],
					SESSIONURL,
					id,
					Math.ceil((new Date().getTime()) / 1000),
					this.attachments[id]['filename'],
					this.attachments[id]['filesize']
				);
			}
			else
			{
				div.innerHTML =
					'<div style="margin:2px"><img src="' + this.attachments[id]['imgpath'] + '" alt="" class="inlineimg" /> ' +
					'<a href="attachment.php?' + SESSIONURL + 'attachmentid=' + id + '&stc=1&d=' + Math.ceil((new Date().getTime()) / 1000) + '" target="_blank" />' + this.attachments[id]['filename'] + '</a> ' +
					'(' + this.attachments[id]['filesize'] + ')</div>';
			}
			listobj.appendChild(div);
		}
	}
};

/**
* Update the places we show a list of attachments
*/
vB_Attachment.prototype.update_list = function()
{
	this.build_list(this.listobjid);

	if (this.popup_exists())
	{
		vB_Editor[this.editorid].build_attachments_popup(
			vB_Editor[this.editorid].popupmode ? vB_Editor[this.editorid].popups['attach'] : vB_Editor[this.editorid].buttons['attach'],
			vB_Editor[this.editorid].buttons['attach']
		);
	}
};

/**
* Opens the attachment manager window
*
* @param	string	URL
* @param	integer	Width
* @param	integer	Height
* @param	string	Hash
*
* @return	window
*/
vB_Attachment.prototype.open_window = function(url, width, height, hash)
{
	if (typeof(this.windows[hash]) != 'undefined' && this.windows[hash].closed == false)
	{
		this.windows[hash].focus();
	}
	else
	{
		this.windows[hash] = openWindow(url, width, height, 'Attach' + hash);
	}

	return this.windows[hash];
};

/*======================================================================*\
|| ####################################################################
|| # NulleD By - FintMax
|| # CVS: $RCSfile$ - $Revision: 39862 $
|| ####################################################################
\*======================================================================*/
