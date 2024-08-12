<!----
	takes normal query terms, returns JSON.

	Wishlist: lock this down, supply users with some sort of key

	Figure out how to allow column customization

	Call the normal API to paginate etc. instead of just dumping JSON
---->


	<cfif not isdefined("session.resultColumnList") or len(session.resultColumnList) is 0>
		<cfset session.resultColumnList='GUID'>
	</cfif>
	<cfquery name="usercols" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey)#">
		select CF_VARIABLE,DISPLAY_TEXT,disp_order,SQL_ELEMENT from (
			select CF_VARIABLE,DISPLAY_TEXT,disp_order,SQL_ELEMENT from ssrch_field_doc where SPECIMEN_RESULTS_COL=1 and cf_variable in (#listqualify(lcase(session.resultColumnList),chr(39))#)
			union
			select CF_VARIABLE,DISPLAY_TEXT,disp_order,SQL_ELEMENT from ssrch_field_doc where SPECIMEN_RESULTS_COL=1 and category='required'
		)
		group by CF_VARIABLE,DISPLAY_TEXT,disp_order,SQL_ELEMENT
		order by disp_order
	</cfquery>
	<cfset session.resultColumnList=valuelist(usercols.CF_VARIABLE)>
	<cfset basSelect = " SELECT distinct #session.flatTableName#.collection_object_id">
	<cfif len(session.CustomOtherIdentifier) gt 0>
		<cfset basSelect = "#basSelect#
			,concatSingleOtherId(#session.flatTableName#.collection_object_id,'#session.CustomOtherIdentifier#') AS CustomID,
			'#session.CustomOtherIdentifier#' as myCustomIdType,
			to_number(ConcatSingleOtherIdInt(#session.flatTableName#.collection_object_id,'#session.CustomOtherIdentifier#')) AS CustomIDInt">
	</cfif>
	<cfloop query="usercols">
		<cfset basSelect = "#basSelect#,#evaluate("sql_element")# #CF_VARIABLE#">
	</cfloop>
	<cfset basFrom = " FROM #session.flatTableName#">
	<cfset basJoin = "">
	<cfset basWhere = " WHERE #session.flatTableName#.collection_object_id IS NOT NULL ">
	<cfset basQual = "">
	<cfset mapurl="">
	<cfinclude template="/includes/SearchSql.cfm">
	<!--- wrap everything up in a string --->
	<cfset SqlString = "#basSelect# #basFrom# #basJoin# #basWhere# #basQual#">
	<cfset sqlstring = replace(sqlstring,"flatTableName","#session.flatTableName#","all")>
	<!--- require some actual searching --->
	<cfset srchTerms="">
	<cfloop list="#mapurl#" delimiters="&" index="t">
		<cfset tt=listgetat(t,1,"=")>
		<cfset srchTerms=listappend(srchTerms,tt)>
	</cfloop>
	<cfif listcontains(srchTerms,"collection_id")>
		<cfset srchTerms=listdeleteat(srchTerms,listfindnocase(srchTerms,'collection_id'))>
	</cfif>
	<!--- ... and abort if there's nothing left --->
	<cfif len(srchTerms) is 0>
		<CFSETTING ENABLECFOUTPUTONLY=0>
		<font color="##FF0000" size="+2">You must enter some search criteria!</font>
		<cfabort>
	</cfif>

	<!---- build a temp table --->
	<cfset checkSql(SqlString)>
	<cfif isdefined("debug") and debug is true>
		#preserveSingleQuotes(SqlString)#
	</cfif>
	<cfquery name="buildIt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey)#" timeout="60">
		#preserveSingleQuotes(SqlString)#
	</cfquery>

	<cfif isdefined('goxml') and goxml is true>
		<cfset ColumnNames = ListToArray(buildIt.ColumnList)>
		<!--- Send the headers --->
		<cfsetting enablecfoutputonly="no"><?xml version="1.0" encoding="utf-8"?>
		<root>
			<cfoutput query="buildIt">
			<row>
				<cfloop from="1" to="#ArrayLen(ColumnNames)#" index="index">
				<cfset column = LCase(ColumnNames[index])>
				<cfset value = buildIt[column][buildIt.CurrentRow]>
					<#column#><![CDATA[#value#]]></#column#>
				</cfloop>
			</row>
		    </cfoutput>
		</root>
	<cfelseif isdefined('gocsv') and gocsv is true>
		<cfset  util = CreateObject("component","component.utilities")>
		<cfset csv = util.QueryToCSV2(Query=buildIt,Fields=buildIt.columnlist)>
		<cffile action = "write"
		    file = "#Application.webDirectory#/download/SpecimenResultsData.csv"
	    	output = "#csv#"
	    	addNewLine = "no">
		<cflocation url="/download.cfm?file=SpecimenResultsData.csv" addtoken="false">
	<cfelse>
		<cfset x=serializeJSON(buildIt)>
		<cfoutput>
			#x#
		</cfoutput>
	</cfif>