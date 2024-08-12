<cfinclude template="/includes/_header.cfm">
<!---- 
	ctcollcdeeditor.cfm edits "normal" code tables with a collection_cde column
---->

<script type="text/javascript" src="/includes/tablesorter/tablesorter.js"></script>
<link rel="stylesheet" href="/includes/tablesorter/themes/blue/style.css">
<cfset title="ctattribute_type editor">
<style>
	.edited{background:#eaa8b4;}
</style>
<script>
	$(document).ready(function() {
	        $("#tbl").tablesorter();
	});
	
	function updateAttribute(a) {
		var rid='prow_' + a.replace(/\W/g, '_');
		$("#" + rid).addClass('edited');
		var guts = "/includes/forms/f2_ctattribute_type.cfm?attribute_type=" + encodeURI(a);
		$("<iframe src='" + guts + "' id='dialog' class='popupDialog' style='width:600px;height:600px;'></iframe>").dialog({
			autoOpen: true,
			closeOnEscape: true,
			height: 'auto',
			modal: true,
			position: ['center', 'center'],
			title: 'Edit Attribute',
				width:800,
	 			height:600,
			close: function() {
				$( this ).remove();
			}
		}).width(800-10).height(600-10);
		$(window).resize(function() {
			$(".ui-dialog-content").dialog("option", "position", ['center', 'center']);
		});
		$(".ui-widget-overlay").click(function(){
		    $(".ui-dialog-titlebar-close").trigger('click');
		});
	}
</script>
<cfif action is "nothing">
	<div class="importantNotification">
		<strong>IMPORTANT!</strong>
		<p>
			Attributes must be consistent across collection types; the definition
			(and eg, expected result of a search for the attribute)
			must be the same for all collections in which the term is used. That is, "some attribute" must have the same intent
			across all collection types.
		</p>
		<p>
			Edit existing attributes to make them available to other collections.
		</p>
		<p>
			Delete and re-create to change attribute name.
		</p>
		<p>
			Please include a description or definition.
		</p>
		<p class="edited">
			Rows that look like this may have been edited and may not be current; reload to refresh.
		</p>
	</div>
	<cfquery name="q" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey)#">
		select
			*
		from ctattribute_type
		ORDER BY
			collection_cde,attribute_type
	</cfquery>
	<cfquery name="ctcollcde" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey)#">
		select distinct collection_cde from ctcollection_cde order by collection_cde
	</cfquery>
	<cfoutput>
		Add record:
		<table class="newRec" border="1" >
			<tr>
				<th>Collection Type</th>
				<th>Attribute</td>
				<th>Description</th>
			</tr>
			<form name="newData" method="post" action="">
				<input type="hidden" name="action" value="insert">
				<tr>
					<td>
						<select name="collection_cde" size="1">
							<cfloop query="ctcollcde">
								<option value="#ctcollcde.collection_cde#">#ctcollcde.collection_cde#</option>
							</cfloop>
						</select>
					</td>
					<td>
						<input type="text" name="attribute_type">
					</td>
					<td>
						<textarea name="description" id="description" rows="4" cols="40"></textarea>
					</td>
					<td>
						<input type="submit" value="Insert" class="insBtn">
					</td>
				</tr>
			</form>
		</table>
		<cfset i = 1>
		Edit
		<table id="tbl" border="1" class="tablesorter">
			<thead>
			<tr>
				<th>Collection Type</th>
				<th>attribute_type</th>
				<th>Description</th>
				<th>Edit</th>
			</tr>
			</thead>
			<tbody>
			<cfquery name="pname" dbtype="query">
				select attribute_type from q group by attribute_type order by attribute_type
			</cfquery>
			<cfloop query="pname">
			<cfset rid=rereplace(attribute_type,"[^A-Za-z0-9]","_","all")>
				<cfset canedit=true>
				<tr id="prow_#rid#">
					<cfquery name="pd" dbtype="query">
						select * from q where attribute_type='#attribute_type#' order by collection_cde
					</cfquery>
					<td>
						<cfloop query="pd">
							<div>
								#collection_cde#
							</div>
						</cfloop>
					</td>
					<td>
						#attribute_type#
					</td>
					<td>
						<cfquery name="dsc" dbtype="query">
							select description from pd group by description
						</cfquery>
						<cfif dsc.recordcount gt 1>
							description inconsistency!!!
							#valuelist(dsc.description)#
							<cfset canedit=false>
						<cfelse>
							#dsc.description#
						</cfif>
					</td>
					<td nowrap="nowrap">
						<cfif canedit is false>
							Inconsistent data;contact a DBA.
						<cfelse>
							<br><span class="likeLink" onclick="updateAttribute('#attribute_type#')">[ Update ]</span>
						</cfif>
					</td>
				</tr>
				<cfset i=i+1>
			</cfloop>
			</tbody>
		</table>
	</cfoutput>
</cfif>
<cfif action is "insert">
	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey)#">
		select * from CTATTRIBUTE_TYPE where attribute_type='#attribute_type#'
	</cfquery>
	<cfif d.recordcount gt 0>
		<cfthrow message="Attribute already exists; edit to add collection types.">
	</cfif>
	<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey)#">
		insert into CTATTRIBUTE_TYPE (
			collection_cde,
			attribute_type,
			DESCRIPTION
		) values (
			'#collection_cde#',
			'#attribute_type#',
			'#description#'
		)
	</cfquery>
	<cflocation url="ctattribute_type.cfm" addtoken="false">
</cfif>
<cfinclude template="/includes/_footer.cfm">