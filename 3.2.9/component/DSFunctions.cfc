<cfcomponent>
	
	<!--------------------------------------------------------------------------->
	<cffunction name="updatecf_temp_spec_to_geog" access="remote">
		<cfargument name="old" type="string" required="yes">
		<cfargument name="new" type="string" required="yes">
		 <!---- this has to be called remotely, but only allow logged-in Operators access--->
	    <cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
	      <cfthrow message="unauthorized">
	    </cfif>
		<cfquery name="gotone" datasource="uam_god">
			update cf_temp_spec_to_geog set higher_geog='#new#' where spec_locality='#old#'
		</cfquery>
		<cfreturn "ok">
	</cffunction>
		<!--------------------------------------------------------------------------->
	
<!---------------------------------------------------------------------->
</cfcomponent>