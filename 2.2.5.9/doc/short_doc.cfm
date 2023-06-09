<cfinclude template="/includes/_header.cfm">

deprecated - see /doc/field_documentation.cfm

<cfabort>

<cfif action is "nothing">
	<a href="short_doc.cfm?action=new">[ new record ]</a>
	<form name="d" method="post" action="short_doc.cfm">
		<input type="hidden" name="action" value="srch">
		<input type="submit" value="find everything">
	</form>
</cfif>
<cfif action is "srch">
	<cfoutput>
		<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select * from short_doc order by colname
		</cfquery>
		<table border>
			<tr>
				<th>ColumnName</th>
				<th>DisplayName</th>
				<th>Definition</th>
				<th>SearchHint</th>
				<th>MoreInfo</th>
			</tr>
			<cfloop query="d">
				<tr>
					<td>
						<a href="short_doc.cfm?action=edit&short_doc_id=#short_doc_id#">#ColName#</a>
					</td>
					<td>#display_name#</td>
					<td>#definition#</td>
					<td>#search_hint#</td>
					<td>#more_info#</td>
				</tr>
			</cfloop>
		</table>
	</cfoutput>

</cfif>

<cfif action is "new">
	<form name="d" method="post" action="short_doc.cfm">
		<input type="hidden" name="action" value="insert">
		<label for="colname">ColName</label>
		<input type="text" name="colname" id="colname" size="60">

		<label for="display_name">display_name</label>
		<input type="text" name="display_name" id="display_name" size="60">

		<label for="definition">definition</label>
		<textarea rows="4" cols="50" name="definition" id="definition"></textarea>

		<label for="search_hint">search_hint</label>
		<input type="text" name="search_hint" id="search_hint" size="60">
		<label for="more_info">MoreInfo</label>
		<input type="text" name="more_info" id="more_info" size="60">
		<br><input type="submit" value="create record">
	</form>
</cfif>

<cfif action is "insert">
	<cfoutput>
		<cfquery name="id" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select nextval('sq_short_doc_id') id
		</cfquery>
		<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			insert into short_doc
				(
					short_doc_id,
					colname,
					display_name,
					definition,
					search_hint,
					more_info
				) values (
					<cfqueryparam value="#id.id#" CFSQLType="cf_sql_int">,
					<cfqueryparam value="#colname#" CFSQLType="cf_sql_varchar">,
					<cfqueryparam value="#display_name#" CFSQLType="cf_sql_varchar">,
					<cfqueryparam value="#definition#" CFSQLType="cf_sql_varchar">,
					<cfqueryparam value="#search_hint#" CFSQLType="cf_sql_varchar">,
					<cfqueryparam value="#more_info#" CFSQLType="cf_sql_varchar">
				)
		</cfquery>
		<cflocation addtoken="false" url="short_doc.cfm?action=edit&short_doc_id=#id.id#">
	</cfoutput>
</cfif>
<cfif action is "edit">
	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select * from short_doc where short_doc_id=#short_doc_id#
	</cfquery>
	<cfoutput>
	<form name="d" method="post" action="short_doc.cfm">
		<input type="hidden" name="action" value="saveEdit">
		<input type="hidden" name="short_doc_id" value="#d.short_doc_id#">
		<label for="colname">ColName</label>
		<input type="text" name="colname" id="colname" value="#d.colname#" size="60">

		<label for="display_name">display_name</label>
		<input type="text" name="display_name" id="display_name" value="#d.display_name#" size="60">

		<label for="definition">definition</label>
		<textarea rows="4" cols="50" name="definition" id="definition">#d.definition#</textarea>

		<label for="search_hint">search_hint</label>
		<input type="text" name="search_hint" id="search_hint" value="#d.search_hint#"  size="60">
		<label for="more_info">MoreInfo</label>
		<input type="text" name="more_info" id="more_info" value="#d.more_info#"   size="60">
		<br><input type="submit" value="save edits">
		<a href="short_doc.cfm?action=delete&short_doc_id=#short_doc_id#">[ delete this record ]</a>
	</form>
	</cfoutput>
</cfif>

<cfif action is "delete">
	<cfoutput>
		<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			delete from short_doc where short_doc_id=#short_doc_id#
		</cfquery>
		deleted
	</cfoutput>
</cfif>
<cfif action is "saveEdit">
	<cfoutput>
		<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			update short_doc set
			ColName=<cfqueryparam value="#colname#" CFSQLType="cf_sql_varchar">,
			display_name=<cfqueryparam value="#display_name#" CFSQLType="cf_sql_varchar">,
			definition=<cfqueryparam value="#definition#" CFSQLType="cf_sql_varchar">,
			search_hint=<cfqueryparam value="#search_hint#" CFSQLType="cf_sql_varchar">,
			more_info=<cfqueryparam value="#more_info#" CFSQLType="cf_sql_varchar">
			where short_doc_id=<cfqueryparam value="#short_doc_id#" CFSQLType="cf_sql_int">
		</cfquery>
		<cflocation addtoken="false" url="short_doc.cfm?action=edit&short_doc_id=#short_doc_id#">
	</cfoutput>
</cfif>
<cfinclude template="/includes/_footer.cfm">