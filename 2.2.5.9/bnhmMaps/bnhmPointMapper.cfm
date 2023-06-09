Retrieving map data - please wait....
<cfoutput>
	<cfif not (isdefined("locality_id")) and (not (isdefined("dec_lat") and isdefined("dec_long")))>
		not enough info
		<cfabort>
	</cfif>
	<cfif isdefined("locality_id") and len(locality_id) gt 0>
		<cfquery name="getMapData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			SELECT
				'<a href="#Application.ServerRootUrl#/place.cfm?action=detail&locality_id=' || locality.locality_id || '" target="_blank">' || locality.locality_id || '</a>' as locality_id,
				spec_locality,
				dec_lat,
				dec_long,
				to_meters(max_error_distance,max_error_units) max_error_meters,
				datum
			FROM locality
			WHERE
				locality.locality_id IN (
				 <cfqueryparam value = "#locality_id#" CFSQLType = "CF_SQL_NUMERIC" list = "yes" separator = ",">
				)
				and not exists (
					select locality_id from locality_attributes where locality_attributes.locality_id=locality.locality_id and attribute_type='locality access'
				)
		</cfquery>
		<cfif getMapData.recordcount is 0>
			not found<cfabort>
		</cfif>
	<cfelse>
		<cfparam name="spec_locality" default="">
		<cfparam name="max_error_meters" default="0">
		<cfparam name="datum" default="World Geodetic System 1984">

		<cfset getMapData = querynew("locality_id,spec_locality,dec_lat,dec_long,max_error_meters,datum")>
		<cfset temp = queryaddrow(getMapData,1)>
		<cfset temp = QuerySetCell(getMapData, "locality_id", -1, 1)>
		<cfset temp = QuerySetCell(getMapData, "spec_locality", spec_locality, 1)>
		<cfset temp = QuerySetCell(getMapData, "dec_lat", dec_lat, 1)>
		<cfset temp = QuerySetCell(getMapData, "dec_long", dec_long, 1)>
		<cfset temp = QuerySetCell(getMapData, "max_error_meters", max_error_meters, 1)>
		<cfset temp = QuerySetCell(getMapData, "datum", datum, 1)>
	</cfif>
	<cfset dlPath = "#Application.webDirectory#/bnhmMaps/tabfiles/">
	<cfset dlFile = "tabfile_l_#randRange(1,100000)#.txt">

	<cffile action="write" file="#dlPath##dlFile#" addnewline="no" output="" nameconflict="overwrite">
	<cfloop query="getMapData">
		<cfset relInfo='<a href="#Application.ServerRootUrl#/editLocality.cfm?locality_id=#locality_id#" target="_blank">#spec_locality#</a>'>
		<cfset oneLine="#relInfo##chr(9)##locality_id##chr(9)##spec_locality##chr(9)##dec_lat##chr(9)##dec_long##chr(9)##max_error_meters##chr(9)##datum#">
		<cfset oneLine=trim(oneLine)>
		<cffile action="append" file="#dlPath##dlFile#" addnewline="yes" output="#oneLine#">
	</cfloop>
<cfset bnhmUrl="https://berkeleymapper.berkeley.edu/?ViewResults=tab&tabfile=#Application.ServerRootUrl#/bnhmMaps/tabfiles/#dlFile#&configfile=#Application.ServerRootUrl#/bnhmMaps/PointMap.xml&sourcename=Locality&queryerrorcircles=1&maxerrorinmeters=1">
	<script type="text/javascript" language="javascript">
		document.location='#bnhmUrl#';
	</script>
</cfoutput>