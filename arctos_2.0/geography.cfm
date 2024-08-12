<cfinclude template="includes/_header.cfm">
<script src="/includes/sorttable.js"></script>
<script>
	$(document).ready(function () {
	 	$('#t').each(function(a, tbl) {
	 		// strip unused columns
	        $(tbl).find('th').each(function(i) {
	            var remove = true;
	            var currentTable = $(this).parents('table');
	            var tds = currentTable.find('tr td:nth-child(' + (i + 1) + ')');
	            tds.each(function(j) { if (this.innerHTML.trim() != '') remove = false; });
	            if (remove) {
	                $(this).hide();
	                tds.hide();
	            }
	        });
	    });
	});
</script>
<cfoutput>
	<cfset title="Find Geography">
	<strong>Find Higher Geography:</strong>
	<form name="getCol" method="post" action="geography.cfm">
	    <input type="hidden" name="Action" value="findGeog">
		<cfinclude template="/includes/frmFindLocation_guts.cfm">
	</form>
	<cf_findLocality type="geog">
	<cfif localityResults.recordcount is 0>
		<cfinclude template="includes/_footer.cfm">
		<cfabort>
	</cfif>
	<cfset title="Geography Search Results">
	<table border id="t" class="sortable">
		<tr>
			<th>Links</th>
			<th>Higher Geog</th>
			<th>Continent</th>
			<th>Country</th>
			<th>State</th>
			<th>County</th>
			<th>Quad</th>
			<th>Feature</th>
			<th>Drainage</th>
			<th>IslandGroup</th>
			<th>Island</th>
			<th>Sea</th>
			<th>WKT?</th>
			<th>Remark</th>
			<th>SrchTerm</th>
		</tr>
		<cfset i=0>
		<cfloop query="localityResults">
			<cfset i=i+1>
			<tr #iif(i MOD 2,DE("class='evenRow'"),DE("class='oddRow'"))#>
				<td>
					<div style="border:1px dashed gray; font-size:x-small;">
						<cfif session.roles contains "manage_geography" or  session.roles contains "manage_locality">
							<div>
								<a href="Locality.cfm?Action=editGeog&geog_auth_rec_id=#geog_auth_rec_id#">Edit #geog_auth_rec_id#</a>
							</div>
						</cfif>
						<div>
							<cfif left(SOURCE_AUTHORITY,4) is 'http'>
								<a href="#SOURCE_AUTHORITY#" class="external" target="_blank">#SOURCE_AUTHORITY#</a>
							<cfelse>
								#SOURCE_AUTHORITY#
							</cfif>
						</div>
						<div>
							<a href="/SpecimenResults.cfm?geog_auth_rec_id=#geog_auth_rec_id#">Specimens</a>
						</div>
					</div>
				</td>
				<td>
					<div>#higher_geog#</div>
				</td>
				<td>
					<cfif len(CONTINENT_OCEAN) gt 0>
						<a href="geography.cfm?CONTINENT_OCEAN=#CONTINENT_OCEAN#">#CONTINENT_OCEAN#</a>
					</cfif>
				<td>
					<cfif len(COUNTRY) gt 0>
						<a href="geography.cfm?COUNTRY=#COUNTRY#">#COUNTRY#</a>
					</cfif>
				</td>
				<td>
					<cfif len(STATE_PROV) gt 0>
						<a href="geography.cfm?STATE_PROV=#STATE_PROV#">#STATE_PROV#</a>
					</cfif>
				</td>
				<td>
					<cfif len(COUNTY) gt 0>
						<a href="geography.cfm?COUNTY=#COUNTY#">#COUNTY#</a>
					</cfif>
				</td>
				<td>
					<cfif len(QUAD) gt 0>
						<a href="geography.cfm?QUAD=#QUAD#">#QUAD#</a>
					</cfif>
				</td>
				<td>
					<cfif len(FEATURE) gt 0>
						<a href="geography.cfm?FEATURE=#FEATURE#">#FEATURE#</a>
					</cfif>
				</td>
				<td>
					<cfif len(drainage) gt 0>
						<a href="geography.cfm?drainage=#drainage#">#drainage#</a>
					</cfif>
				</td>
				<td>
					<cfif len(ISLAND_GROUP) gt 0>
						<a href="geography.cfm?ISLAND_GROUP=#ISLAND_GROUP#">#ISLAND_GROUP#</a>
					</cfif>
				</td>
				<td>
					<cfif len(ISLAND) gt 0>
						<a href="geography.cfm?ISLAND=#ISLAND#">#ISLAND#</a>
					</cfif>
				</td>
				<td>
					<cfif len(SEA) gt 0>
						<a href="geography.cfm?SEA=#SEA#">#SEA#</a>
					</cfif>
				</td>
				<td>
					#has_geo_poly#
				</td>
				<td>
					<cfif len(geog_remark) gt 0>
						<div style="font-size:x-small;">
							#geog_remark#
						</div>
					</cfif>
				</td>
				<cfquery name="searchterm" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey)#">
					select SEARCH_TERM from geog_search_term where geog_auth_rec_id=#geog_auth_rec_id# order by SEARCH_TERM
				</cfquery>
				<td valign="top">
					<cfloop query="searchterm">
						<div style="border:1px dashed gray; font-size:x-small;">
							#SEARCH_TERM#
						</div>
					</cfloop>
				</td>
			</tr>
		</cfloop>
	</table>
</cfoutput>
<cfinclude template="includes/_footer.cfm">