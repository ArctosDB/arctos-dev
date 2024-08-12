<cfinclude template="/includes/_header.cfm">
<cfset title="system statistics">
<script>
	$(document).ready(function() {
		$("#thisIsSlowYo").hide();
	});
</script>
<cfoutput>
	<cfquery name="d" datasource="uam_god" cachedwithin="#createtimespan(0,0,600,0)#">
		select * from collection order by guid_prefix
	</cfquery>
	<br>this form caches
	<table border>
		<tr><th>
				Metric
			</th>
			<th>
				Value
			</th></tr>
		<tr>
			<td>
				Number Collections
				<a href="##collections" class="infoLink">list</a>
			</td>
			<td><input value="#d.recordcount#"></td>
		</tr>
		<cfquery name="inst" dbtype="query">
			select institution from d group by institution order by institution
		</cfquery>
		<tr>
			<td>Number Institutions<a href="##rawinst" class="infoLink">list</a></td>
			<td><input value="#inst.recordcount#"></td>
		</tr>

		<cfquery name="cataloged_item" datasource="uam_god" cachedwithin="#createtimespan(0,0,600,0)#">
			select count(*) c from cataloged_item
		</cfquery>
		<tr>
			<td>Total Number Specimen Records</td>
			<td><input value="#NumberFormat(cataloged_item.c)#"></td>
		</tr>


		<cfquery name="citype" datasource="uam_god" cachedwithin="#createtimespan(0,0,600,0)#">
			select
				CATALOGED_ITEM_TYPE,
				count(*) c
			from
				cataloged_item
			group by
				CATALOGED_ITEM_TYPE
		</cfquery>
		<tr>
			<td>Number Specimen Records by cataloged_item_type</td>
			<td>
				<cfloop query="citype">
					<input value="#NumberFormat(c)#"> #CATALOGED_ITEM_TYPE#<br>
				</cfloop>
			</td>
		</tr>

		<cfquery name="taxonomy" datasource="uam_god" cachedwithin="#createtimespan(0,0,600,0)#">
			select count(*) c from taxon_name
		</cfquery>
		<tr>
			<td>Number Taxon Names</td>
			<td><input value="#NumberFormat(taxonomy.c)#"></td>
		</tr>
		<cfquery name="locality" datasource="uam_god" cachedwithin="#createtimespan(0,0,600,0)#">
			select count(*) c from locality
		</cfquery>
		<tr>
			<td>Number Localities</td>
			<td><input value="#NumberFormat(locality.c)#"></td>
		</tr>

		<cfquery name="collecting_event" datasource="uam_god" cachedwithin="#createtimespan(0,0,600,0)#">
			select count(*) c from collecting_event
		</cfquery>
		<tr>
			<td>Number Collecting Events</td>
			<td><input value="#NumberFormat(collecting_event.c)#"></td>
		</tr>

		<cfquery name="media" datasource="uam_god" cachedwithin="#createtimespan(0,0,600,0)#">
			select count(*) c from media
		</cfquery>
		<tr>
			<td>Number Media</td>
			<td><input value="#NumberFormat(media.c)#"></td>
		</tr>
		<cfquery name="agent" datasource="uam_god" cachedwithin="#createtimespan(0,0,600,0)#">
			select count(*) c from agent
		</cfquery>
		<tr>
			<td>Number Agents</td>
			<td><input value="#NumberFormat(agent.c)#"></td>
		</tr>
		<cfquery name="publication" datasource="uam_god"  cachedwithin="#createtimespan(0,0,600,0)#">
			select count(*) c from publication
		</cfquery>
		<tr>
			<td>
				Number Publications
				<cfif session.roles contains "coldfusion_user">
					(<a href="/info/MoreCitationStats.cfm">more detail</a>)
				</cfif>
			</td>
			<td><input value="#NumberFormat(publication.c)#"></td>
		</tr>
		<cfquery name="project" datasource="uam_god" cachedwithin="#createtimespan(0,0,600,0)#">
			select count(*) c from project
		</cfquery>
		<tr>
			<td>
				Number Projects
				<cfif session.roles contains "coldfusion_user">
					(<a href="/info/MoreCitationStats.cfm">more detail</a>)
				</cfif>
			</td>
			<td><input value="#NumberFormat(project.c)#"></td>
		</tr>

		<!----
		<cfquery name="user_tables" datasource="uam_god"  cachedwithin="#createtimespan(0,0,60,0)#">
			select TABLE_NAME from user_tables
		</cfquery>
		<tr>
			<td>Number Tables *</td>
			<td><input value="#user_tables.recordcount#"></td>
		</tr>
		<cfquery name="ct" dbtype="query">
			select TABLE_NAME from user_tables where table_name like 'CT%'
		</cfquery>
		<tr>
			<td>Number Code Tables *</td>
			<td><input value="#ct.recordcount#"></td>
		</tr>
		---->
		<cfquery name="gb"  datasource="uam_god"  cachedwithin="#createtimespan(0,0,600,0)#">
			select count(*) c from coll_obj_other_id_num where OTHER_ID_TYPE = 'GenBank'
		</cfquery>
		<tr>
			<td>Number GenBank Linkouts</td>
			<td><input value="#NumberFormat(gb.c)#"></td>
		</tr>
		<cfquery name="reln"  datasource="uam_god"  cachedwithin="#createtimespan(0,0,600,0)#">
			select count(*) c from coll_obj_other_id_num where ID_REFERENCES != 'self'
		</cfquery>
		<tr>
			<td>Number Inter-Specimen Relationships</td>
			<td><input value="#NumberFormat(reln.c)#"></td>
		</tr>
	</table>





	<!----
	* The numbers above represent tables owned by the system owner.
	There are about 85 "data tables" which contain primary specimen data. They're pretty useless by themselves - the other several hundred tables are user info,
	 VPD settings, user settings and customizations, temp CF bulkloading tables, CF admin stuff, cached data (collection-type-specific code tables),
	 archives of deletes from various places, snapshots of system objects (eg, audit), and the other stuff that together makes Arctos work. Additionally,
	 there are approximately 100,000 triggers, views, procedures, system tables, etc. - think of them as the duct tape that holds Arctos together.
	 Arctos is a deeply-integrated system which heavily uses Oracle functionality; it is not a couple tables loosely held together by some
	 middleware, a stark contrast to any other system with which we are familiar.
	 ---->

	<p>Query and Download stats are available under the Reports tab.</p>
	<a name="growth"></a>
	<hr>
	<cfif isdefined('getCSV') and getCSV is true>
		<cfset fileDir = "#Application.webDirectory#">
		<cfset variables.encoding="UTF-8">
		<cfset fname = "arctos_by_year.csv">
		<cfset variables.fileName="#Application.webDirectory#/download/#fname#">
	</cfif>
	Specimen Records and collection by year

	<a href="/info/sysstats.cfm?getCSV=true">CSV</a>

<!---
	<cfquery name="sby" datasource="uam_god">
		select
	    to_number(to_char(COLL_OBJECT_ENTERED_DATE,'YYYY')) yr,
	    count(*) numberSpecimens,
	    count(distinct(collection_id)) numberCollections
	  from
	    cataloged_item,
	    coll_object
	  where cataloged_item.collection_object_id=coll_object.collection_object_id
	  group by
	    to_number(to_char(COLL_OBJECT_ENTERED_DATE,'YYYY'))
		order by to_number(to_char(COLL_OBJECT_ENTERED_DATE,'YYYY'))
	</cfquery>
	<cfdump var=#sby#>

	<cfset cCS=0>
	<cfset cCC=0>

	<cfloop query="sby">
		<cfquery name="thisyear" dbtype="query">
			select * from sby where yr <= #yr#
		</cfquery>
		<cfdump var=#thisyear#>

		<cfset cCS=ArraySum(thisyear['numberSpecimens'])>
		<cfset cCC=ArraySum(thisyear['numberCollections'])>

		<p>
			y: #yr#; cCS: #cCS#; cCC: #cCC#
		</p>

	</cfloop>
	---->
	<cfif not isdefined('getCSV') or getCSV is not true>
		<div id="thisIsSlowYo">
			Fetching data....<img src="/images/indicator.gif">
		</div>
		<cfflush>
	</cfif>
<table border>
		<tr>
			<th>Year</th>
			<th>Number Collections</th>
			<th>Number Specimen Records</th>
		</tr>
	<cfif isdefined('getCSV') and getCSV is true>
		<cfscript>
			variables.joFileWriter = createObject('Component', '/component.FileWriter').init(variables.fileName, variables.encoding, 32768);
			variables.joFileWriter.writeLine("year,NumberCollections,NumberSpecimens");
		</cfscript>
	</cfif>
	<cfloop from="1995" to="#dateformat(now(),"YYYY")#" index="y">
		<cfquery name="qy" datasource="uam_god" cachedwithin="#createtimespan(0,0,600,0)#">
 			select
				count(*) numberSpecimens,
				count(distinct(collection_id)) numberCollections
			from
				cataloged_item,
				coll_object
			where cataloged_item.collection_object_id=coll_object.collection_object_id and
		 		to_number(to_char(COLL_OBJECT_ENTERED_DATE,'YYYY')) between 1995 and #y#
		</cfquery>
		<tr>
			<td>#y#</td>
			<td>#qy.numberCollections#</td>
			<td>#NumberFormat(qy.numberSpecimens)#</td>
		</tr>
		<cfif isdefined('getCSV') and getCSV is true>
			<cfscript>
				variables.joFileWriter.writeLine('"#y#","#qy.numberCollections#","#qy.numberSpecimens#"');
			</cfscript>
		</cfif>
	</cfloop>
	</table>
		<cfif isdefined('getCSV') and getCSV is true>
			<cfscript>
				variables.joFileWriter.close();
			</cfscript>
			<cflocation url="/download.cfm?file=#fname#" addtoken="false">
		</cfif>
	<hr>
	<a name="collections"></a>
	<p>List of collections in Arctos:</p>
	<ul>
		<cfloop query="d">
			<li>#guid_prefix#: #institution# #collection#</li>
		</cfloop>
	</ul>
	<hr>
	<a name="rawinst"></a>
	<p>List of institutions in Arctos:</p>
	<ul>
		<cfloop query="inst">
			<li>#institution#</li>
		</cfloop>
	</ul>
</cfoutput>
<cfinclude template="/includes/_footer.cfm">