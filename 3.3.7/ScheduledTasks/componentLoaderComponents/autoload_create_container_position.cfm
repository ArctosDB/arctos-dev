<cfquery name="d" datasource="uam_god" >
	select * from cf_temp_container_position where status = 'autoload' order by last_ts desc limit #recLimit#
</cfquery>
<cfif debug is true>
	<cfdump var=#d#>
</cfif>

<cfoutput>
	<cffunction name="update_record">
		<cfargument name="key" type="numeric" required="yes">
		<cfargument name="status" type="string" required="yes">
		<cfquery name="fail" datasource="uam_god">
			update 
				cf_temp_container_position 
			set 
				status=<cfqueryparam value="#status#" CFSQLType="CF_SQL_VARCHAR"> 
			where 
				key=<cfqueryparam value="#key#" CFSQLType="cf_sql_int">
		</cfquery>
		<cfreturn>
	</cffunction>
	<cfloop query="d">
		<cfset thisRan=true>
		<cfif debug is true>
			<br>looping for key=#d.key#
		</cfif>
		<cfset errs="">
		<!---- make sure they have sufficient access to the tool---->
		<cfquery name="checkUserHasRole" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
			select checkUserHasRole(
				<cfqueryparam value="#d.username#" CFSQLType="CF_SQL_VARCHAR">,
				<cfqueryparam value="admin_container" CFSQLType="CF_SQL_VARCHAR">
			) as hasAccess
		</cfquery>
		<cfif debug>
			<cfdump var=#checkUserHasRole#>
		</cfif>
		<cfif not checkUserHasRole.hasAccess>
			<cfset errs="insufficient access">
			<cfif debug>
				<cfdump var=#errs#>
			</cfif>
			<cfset x=update_record(d.key,errs)>
			<cfcontinue />
		</cfif>
		<cfif len(d.container_id) gt 0>
			<cfquery name="parent_container" datasource="uam_god">
				select * from container where container_id =<cfqueryparam value="#d.container_id#" CFSQLType="cf_sql_int">
			</cfquery>
		<cfelseif len(d.barcode) gt 0>
			<cfquery name="parent_container" datasource="uam_god">
				select * from container where barcode=<cfqueryparam value="#d.barcode#" CFSQLType="cf_sql_varchar">
			</cfquery>
		<cfelse>
			<cfset errs="container not found">
			<cfif debug>
				<cfdump var=#errs#>
			</cfif>
			<cfset x=update_record(d.key,errs)>
			<cfcontinue />
		</cfif>
		<cfif parent_container.recordcount neq 1 or len(parent_container.container_id) lt 1>
			<cfset errs="container not found">
			<cfif debug>
				<cfdump var=#errs#>
			</cfif>
			<cfset x=update_record(d.key,errs)>
			<cfcontinue />
		</cfif>
		<cfif debug>
			<cfdump var=#parent_container#>
		</cfif>
		<cfif len(parent_container.width) is 0 or 
			len(parent_container.height) is 0 or 
			len(parent_container.length) is 0 or 
			len(parent_container.number_rows) is 0 or 
			len(parent_container.number_columns) is 0 or 
			len(parent_container.orientation) is 0 or 
			len(parent_container.positions_hold_container_type) is 0
		>
			<cfset errs="setup fail">
			<cfif debug>
				<cfdump var=#errs#>
			</cfif>
			<cfset x=update_record(d.key,errs)>
			<cfcontinue />
		</cfif>
		<!---- belt and suspenders, this should all be handled by triggers, but paranoia.... --->
		<cfquery name="parent_contents" datasource="uam_god">
			select count(*) c from container where parent_container_id=<cfqueryparam value="#parent_container.container_id#" CFSQLType="cf_sql_int">
		</cfquery>
		<cfif parent_contents.c gt 0>
			<cfset errs="unempty">
			<cfif debug>
				<cfdump var=#errs#>
			</cfif>
			<cfset x=update_record(d.key,errs)>
			<cfcontinue />
		</cfif>



		<cfset pvol=parent_container.width * parent_container.height * parent_container.length>
		<cfset psnvol=d.position_width * d.position_height * d.position_length * parent_container.number_rows * parent_container.number_columns>

		<cfif pvol lte psnvol>
			<cfset errs="size fail">
			<cfif debug>
				<cfdump var=#errs#>
			</cfif>
			<cfset x=update_record(d.key,errs)>
			<cfcontinue />
		</cfif>
		<cftry>
			<cftransaction>
				<cfset number_positions=parent_container.NUMBER_ROWS * parent_container.NUMBER_COLUMNS>
				<cfquery name="make_positions" datasource="uam_god">
					 insert into container (
					 	container_id,
					 	parent_container_id,
					 	container_type,
					 	label,
					 	description,
					 	container_remarks,
					 	width,
					 	height,
					 	length,
					 	number_rows,
					 	number_columns,
					 	orientation,
					 	positions_hold_container_type,
					 	barcode,
					 	institution_acronym,
					 	last_update_tool
					 ) values 
					 <cfloop from="1" to="#number_positions#" index="i">
						 (
						 	nextval('sq_container_id'),
							<cfqueryparam value="#parent_container.container_id#" CFSQLType="cf_sql_int">,
							<cfqueryparam value="position" CFSQLType="CF_SQL_VARCHAR">,
							<cfqueryparam value="#i#" CFSQLType="CF_SQL_VARCHAR">,
							null,
							null,
							<cfqueryparam value="#d.position_width#" CFSQLType="CF_SQL_DOUBLE">,
							<cfqueryparam value="#d.position_height#" CFSQLType="CF_SQL_DOUBLE">,
							<cfqueryparam value="#d.position_length#" CFSQLType="CF_SQL_DOUBLE">,
							null,
							null,
							null,
							null,
							null,
							<cfqueryparam value="#parent_container.institution_acronym#" CFSQLType="CF_SQL_VARCHAR">,
							'autoload_create_container_position'
						)<cfif i lt number_positions>,</cfif>
					</cfloop>
				</cfquery>
					<cfif debug is true>
					<br>delete from cf_temp_container_position where key=#d.key#
				</cfif>
				<cfquery name="cleanup" datasource="uam_god">
					delete from cf_temp_container_position where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
				</cfquery>
			</cftransaction>
		<cfcatch>
			<cfif debug is true>
				<cfdump var=#cfcatch#>
			</cfif>
			<cfquery name="cleanupf" datasource="uam_god">
				update cf_temp_container_position set
				status=<cfqueryparam value="load fail::#cfcatch.message#" CFSQLType="CF_SQL_VARCHAR"> where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
			</cfquery>
		</cfcatch>
		</cftry>
	</cfloop>
</cfoutput>