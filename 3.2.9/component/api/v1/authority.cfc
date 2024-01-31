<cfcomponent rest="true" restpath="/auth">

	<cffunction name="code_tables" access="remote" returnformat="json" httpMethod="get">
		<cfparam name="api_key" type="string" default="no_api_key">
		<cfparam name="tbl" type="string" default="">
		<cfquery name="api_auth_key" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
			select
				count(*) c
			from
				api_key
			where
				api_key='#api_key#' and
				expires > current_date
		</cfquery>
		<cfif api_auth_key.c lt 1>
			<cfset result.Result="Denied: You must have an API key to access this resource. See /component/api/v1/about.cfc?method=api_map for more information.">
			<cfreturn result>
			<cfabort>
		</cfif>
		<cfoutput>
			<cftry>
				<cfquery name="usrenv" datasource="uam_god">
					select lower(dbusername) as dbusername,dbpwd from cf_collection where lower(dbusername)='pub_usr_all_all'
				</cfquery>
				<cfif len(tbl) is 0>
					<!--- listing --->
					<cfquery name="d" datasource="user_login" username="#usrenv.dbusername#" password="#usrenv.dbpwd#">
						select array_to_json(array_agg(d)) from (
							select table_name from information_schema.tables where table_name like 'ct%' order by table_name
						) d
					</cfquery>
					<cfset x=deserializejson(d.ARRAY_TO_JSON)>
					<cfset result.documentation="Use ?tbl={table_name} to download an authority table, including documentation.">
					<cfset result.tbl=x>
					<cfreturn result>
				<cfelse>
					<cfif left(tbl,2) is not 'ct'>
						<cfset result.Result="bad tbl">
						<cfreturn result>
						<cfabort>
					</cfif>
					<cfquery name="d" datasource="user_login" username="#usrenv.dbusername#" password="#usrenv.dbpwd#">
						select array_to_json(array_agg(d)) from (
							select * from #tbl#
						) d
					</cfquery>
					<cfset result=deserializejson(d.ARRAY_TO_JSON)>
					<cfreturn result>
				</cfif>

			<cfcatch>
				<cfreturn cfcatch>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cffunction>
</cfcomponent>
