<cfinclude template = "/includes/_header.cfm">
<cfset title = "Partless Specimens">
<cfif action is "nothing">
<cfoutput>
	<h2>Find catalog records with no parts</h2>
<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
	select collection_id,guid_prefix from collection order by guid_prefix
</cfquery>
<form method="post">
	<input type="hidden" name="action" value="show">
	<label for="collection_id">Collection</label>
	<select name="collection_id" id="collection_id">
		<option value="">All</option>
		<cfloop query="d">
			<option value="#collection_id#">#guid_prefix#</option>
		</cfloop>
	</select>
	<input type="submit" class="lnkBtn" value="Go">
</form>
</cfoutput>
</cfif>
<cfif action is "show">
<cfoutput>
<h2>The following catalog records have no parts.</h2>
<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
	select
		collection.guid_prefix,
		cataloged_item.cat_num
	from
		collection
		inner join cataloged_item on collection.collection_id = cataloged_item.collection_id
		left outer join specimen_part on cataloged_item.collection_object_id=specimen_part.derived_From_cat_item
	where
		specimen_part.derived_from_cat_item is null
		<cfif isdefined("collection_id") and collection_id gt 0>
			and collection.collection_id=#collection_id#
		</cfif>
	order by
		collection.guid_prefix,
		cat_num
</cfquery>
<cfset fileDir = "#Application.webDirectory#">
<cfset fileName = "ArctosData_#left(session.sessionKey,10)#.csv">
<cfset header="collection,cat_num">
<cffile action="write" file="#Application.webDirectory#/download/#fileName#" addnewline="yes" output="#header#">
<cfloop query="d">
	<cfset oneLine = "#guid_prefix#,#cat_num#">
	<cffile action="append" file="#Application.webDirectory#/download/#fileName#" addnewline="yes" output="#oneLine#">
</cfloop>
<br>
<a href="/download.cfm?file=#fileName#">Download as CSV</a>
<cfdump var=#d#>
</cfoutput>
</cfif>
<cfinclude template = "/includes/_footer.cfm">