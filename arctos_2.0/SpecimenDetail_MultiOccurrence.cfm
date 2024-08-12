



<cfinclude template="/includes/_header.cfm">






<cfif not isdefined("session.sdmapclass") or len(session.sdmapclass) is 0>
	<cfset session.sdmapclass='tinymap'>
</cfif>





<cfquery name="cf_global_settings" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
		select
			google_client_id,
			google_private_key
		from cf_global_settings
	</cfquery>
	<cfoutput>
		<cfhtmlhead text='<script src="https://maps.googleapis.com/maps/api/js?client=#cf_global_settings.google_client_id#&libraries=geometry" type="text/javascript"></script>'>
	</cfoutput>
<cftry>
	<script>
		jQuery(document).ready(function() {
			$( "#dialog" ).dialog({
				autoOpen: false,
				width: "50%"
			});
			$( ".mapdialog" ).click(function() {
				$( "#dialog" ).dialog( "open" );
			});
			mapsYo();
		});
		function saveSDMap(){
			$("div[id^='mapdiv_']").each(function(e){
				$(this).removeClass().addClass($("#sdetmapsize").val());
			});
			jQuery.getJSON("/component/functions.cfc",
				{
					method : "changeUserPreference",
					pref : "sdmapclass",
					val : $("#sdetmapsize").val(),
					returnformat : "json",
					queryformat : 'column'
				}
			);
			$('#dialog').dialog('close');
			mapsYo();
		}
		function mapsYo(){
			$("input[id^='coordinates_']").each(function(e){
				var seid=this.id.split('_')[1];
				var coords=this.value;
				var bounds = new google.maps.LatLngBounds();
				var polygonArray = [];
				var ptsArray=[];
				var lat=coords.split(',')[0];
				var lng=coords.split(',')[1];
				var errorm=$("#error_" + seid).val();
				var mapOptions = {
					zoom: 3,
				    center: new google.maps.LatLng(55, -135),
				    mapTypeId: google.maps.MapTypeId.ROADMAP,
				    panControl: false,
				    scaleControl: true
				};
				var map = new google.maps.Map(document.getElementById("mapdiv_" + seid), mapOptions);
				var center=new google.maps.LatLng(lat,lng);
				var marker = new google.maps.Marker({
					position: center,
					map: map,
					zIndex: 10
				});
				bounds.extend(center);
				if (parseInt(errorm)>0){
					var circleoptn = {
						strokeColor: '#FF0000',
						strokeOpacity: 0.8,
						strokeWeight: 2,
						fillColor: '#FF0000',
						fillOpacity: 0.15,
						map: map,
						center: center,
						radius: parseInt(errorm),
						zIndex:-99
					};
					crcl = new google.maps.Circle(circleoptn);
					bounds.union(crcl.getBounds());
				}
				// WKT can be big and slow, so async fetch
				$.get( "/component/utilities.cfc?returnformat=plain&method=getGeogWKT&specimen_event_id=" + seid, function( wkt ) {
  					  if (wkt.length>0){
						var regex = /\(([^()]+)\)/g;
						var Rings = [];
						var results;
						while( results = regex.exec(wkt) ) {
						    Rings.push( results[1] );
						}
						for(var i=0;i<Rings.length;i++){
							// for every polygon in the WKT, create an array
							var lary=[];
							var da=Rings[i].split(",");
							for(var j=0;j<da.length;j++){
								// push the coordinate pairs to the array as LatLngs
								var xy = da[j].trim().split(" ");
								var pt=new google.maps.LatLng(xy[1],xy[0]);
								lary.push(pt);
								//console.log(lary);
								bounds.extend(pt);
							}
							// now push the single-polygon array to the array of arrays (of polygons)
							ptsArray.push(lary);
						}
						var poly = new google.maps.Polygon({
						    paths: ptsArray,
						    strokeColor: '#1E90FF',
						    strokeOpacity: 0.8,
						    strokeWeight: 2,
						    fillColor: '#1E90FF',
						    fillOpacity: 0.35
						});
						poly.setMap(map);
						polygonArray.push(poly);
						// END this block build WKT
  					  	} else {
  					  		$("#mapdiv_" + seid).addClass('noWKT');
  					  	}
  					  	if (bounds.getNorthEast().equals(bounds.getSouthWest())) {
					       var extendPoint1 = new google.maps.LatLng(bounds.getNorthEast().lat() + 0.05, bounds.getNorthEast().lng() + 0.05);
					       var extendPoint2 = new google.maps.LatLng(bounds.getNorthEast().lat() - 0.05, bounds.getNorthEast().lng() - 0.05);
					       bounds.extend(extendPoint1);
					       bounds.extend(extendPoint2);
					    }
						map.fitBounds(bounds);
			        	for(var a=0; a<polygonArray.length; a++){
			        		if  (! google.maps.geometry.poly.containsLocation(center, polygonArray[a]) ) {
			        			$("#mapdiv_" + seid).addClass('uglyGeoSPatData');
				        	} else {
				    			$("#mapdiv_" + seid).addClass('niceGeoSPatData');
			        		}
			        	}
					});
			});
		}
	</script>


<!-----

turn this off for test - turn it back on if this becomes something real




<cfif isdefined("collection_object_id")>
	<cfset checkSql(collection_object_id)>
	<cfoutput>
		<cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey)#">
			select GUID from #session.flatTableName# where collection_object_id=#collection_object_id#
		</cfquery>
		<cfheader statuscode="301" statustext="Moved permanently">
		<cfheader name="Location" value="/guid/#c.guid#">
		<cfabort>
	</cfoutput>
</cfif>
<cfif isdefined("guid")>
	<cfif cgi.script_name contains "/SpecimenDetail.cfm">
		<cfheader statuscode="301" statustext="Moved permanently">
		<cfheader name="Location" value="/guid/#guid#">
		<cfabort>
	</cfif>
	<cfset checkSql(guid)>
	<cfif guid contains ":">
		<cfoutput>
			<cfset sql="select #session.flatTableName#.collection_object_id from
					#session.flatTableName#,cataloged_item
				WHERE
					#session.flatTableName#.collection_object_id=cataloged_item.collection_object_id and
					upper(#session.flatTableName#.guid)='#ucase(guid)#'">
			<cfset checkSql(sql)>
			<cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey)#">
				#preservesinglequotes(sql)#
			</cfquery>
		</cfoutput>
	</cfif>
	<cfif isdefined("c.collection_object_id") and len(c.collection_object_id) gt 0>
		<cfset collection_object_id=c.collection_object_id>
	<cfelse>
		<cfinclude template="/errors/404.cfm">
		<cfabort>
	</cfif>
<cfelse>
	<cfinclude template="/errors/404.cfm">
	<cfabort>
</cfif>
---->
<cfset detSelect = "
	SELECT
		#session.flatTableName#.guid,
		#session.flatTableName#.collection_id,
		#session.flatTableName#.locality_id,
		web_link,
		web_link_text,
		#session.flatTableName#.cat_num,
		#session.flatTableName#.collection_object_id as collection_object_id,
		#session.flatTableName#.scientific_name,
		#session.flatTableName#.collecting_event_id,
		#session.flatTableName#.higher_geog,
		#session.flatTableName#.spec_locality,
		#session.flatTableName#.verbatim_date,
		#session.flatTableName#.BEGAN_DATE,
		#session.flatTableName#.ended_date,
		#session.flatTableName#.parts as partString,
		#session.flatTableName#.dec_lat,
		#session.flatTableName#.dec_long">
<cfif len(session.CustomOtherIdentifier) gt 0>
	<cfset detSelect = "#detSelect#
	,concatSingleOtherId(#session.flatTableName#.collection_object_id,'#session.CustomOtherIdentifier#') as	CustomID">
</cfif>
<cfset detSelect = "#detSelect#
	FROM
		#session.flatTableName#,
		collection
	where
		#session.flatTableName#.collection_id = collection.collection_id AND
		#session.flatTableName#.collection_object_id = #collection_object_id#
	ORDER BY
		cat_num">





<cfset checkSql(detSelect)>
<cfquery name="detail" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey)#">
	#preservesinglequotes(detSelect)#
</cfquery>
<cfquery name="doi" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey)#">
	select doi from doi where COLLECTION_OBJECT_ID=#collection_object_id#
</cfquery>






<cfoutput>
	<cfset title="#detail.guid#: #detail.scientific_name#">
	<cfset metaDesc="#detail.guid#; #detail.scientific_name#; #detail.higher_geog#; #detail.spec_locality#">
	<cf_customizeHeader collection_id=#detail.collection_id#>
	<cfif (detail.verbatim_date is detail.began_date) AND (detail.verbatim_date is detail.ended_date)>
		<cfset thisDate = detail.verbatim_date>
	<cfelseif (
			(detail.verbatim_date is not detail.began_date) OR
	 		(detail.verbatim_date is not detail.ended_date)
		)
		AND
		detail.began_date is detail.ended_date>
		<cfset thisDate = "#detail.verbatim_date# (#detail.began_date#)">
	<cfelse>
		<cfset thisDate = "#detail.verbatim_date# (#detail.began_date# - #detail.ended_date#)">
	</cfif>




	<table width="100%" cellspacing="0" cellpadding="0">
		<tr>
			<td valign="top">
				<table cellspacing="0" cellpadding="0">
					<tr>
						<td nowrap valign="top">
							<div id="SDCollCatBlk">
								<span id="SDheaderCollCatNum">
									#detail.guid#
								</span>
								<cfif len(session.CustomOtherIdentifier) gt 0>
									<div id="SDheaderCustID">
										#session.CustomOtherIdentifier#: #detail.CustomID#
									</div>
								</cfif>
								<cfset sciname = '#replace(detail.Scientific_Name," or ","</i>&nbsp;or&nbsp;<i>")#'>
								<div id="SDheaderSciName">
									#sciname#
								</div>
								<div id="SDheaderGoBakBtn">
									<cfif isdefined("session.mapURL") and len(session.mapURL) gt 0>
										<a href="/SpecimenResults.cfm?#session.mapURL#"><< Return&nbsp;to&nbsp;results</a>
									</cfif>
								</div>
								<cfif len(doi.doi) gt 0>
									doi:#doi.doi#
								<cfelse>
									<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
										<a href="/tools/doi.cfm?collection_object_id=#collection_object_id#">get a DOI</a>
									</cfif>
								</cfif>
							</div>
						</td>
					</tr>
				</table>
			</td>
		    <td valign="top">
		    	<table cellspacing="0" cellpadding="0">
					<tr>
						<td valign="top">
							<div id="SDheaderSpecLoc">
								#detail.spec_locality#
							</div>
							<div id="SDheaderGeog">
								#detail.higher_geog#
							</div>
							<div id="SDheaderDate">
								#thisDate#
							</div>
						</td>
					</tr>
				</table>
			</td>
			<td valign="top">
				<div id="SDheaderPart">
					#detail.partString#
				</div>
			</td>
		    <td valign="top" align="right">
		        <div id="annotateSpace">
					<cfquery name="existingAnnotations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey)#">
						select
							decode(REVIEWER_AGENT_ID,NULL,0,1) isreviewed,
							count(*) cnt
						from
							annotations
						where
							collection_object_id = #detail.collection_object_id#
						group by
							decode(REVIEWER_AGENT_ID,NULL,0,1)
					</cfquery>
					<cfquery name="ra" dbtype="query">
						select sum(cnt) c from existingAnnotations where isreviewed=1
					</cfquery>
					<cfquery name="ua" dbtype="query">
						select sum(cnt) c from existingAnnotations where isreviewed=0
					</cfquery>
					<cfif len(ra.c) is 0>
						<cfset gac=0>
					<cfelse>
						<cfset gac=ra.c>
					</cfif>
					<cfif len(ua.c) is 0>
						<cfset bac=0>
					<cfelse>
						<cfset bac=ua.c>
					</cfif>
					<button type="button" onclick="openAnnotation('collection_object_id=#detail.collection_object_id#')" class="annobtn">
						<span class="abt">Report Bad Data&nbsp;<span class="gdAnnoCt">[#gac#]</span><span class="badAnnoCt">[#bac#]</span>
					</button>
					<cfif len(detail.web_link) gt 0>
						<cfif len(detail.web_link_text) gt 0>
							<cfset cLink=detail.web_link_text>
						<cfelse>
							<cfset cLink="collection">
						</cfif>
						<br><a href="#detail.web_link#" target="_blank" class="external">#cLink#</a>
					</cfif>
					<cfif isdefined("session.collObjIdList") and len(session.collObjIdList) gt 0 and listcontains(session.collObjIdList,detail.collection_object_id)>
						<cfset isPrev = "no">
						<cfset isNext = "no">
						<cfset currPos = 0>
						<cfset lenOfIdList = 0>
						<cfset firstID = collection_object_id>
						<cfset nextID = collection_object_id>
						<cfset prevID = collection_object_id>
						<cfset lastID = collection_object_id>
						<cfset currPos = listfind(session.collObjIdList,collection_object_id)>
						<cfset lenOfIdList = listlen(session.collObjIdList)>
						<cfset firstID = listGetAt(session.collObjIdList,1)>
						<cfif currPos lt lenOfIdList>
							<cfset nextID = listGetAt(session.collObjIdList,currPos + 1)>
						</cfif>
						<cfif currPos gt 1>
							<cfset prevID = listGetAt(session.collObjIdList,currPos - 1)>
						</cfif>
						<cfset lastID = listGetAt(session.collObjIdList,lenOfIdList)>
						<cfif lenOfIdList gt 1>
							<cfif currPos gt 1>
								<cfset isPrev = "yes">
							</cfif>
							<cfif currPos lt lenOfIdList>
								<cfset isNext = "yes">
							</cfif>
						</cfif>
						<div id="navSpace">
							<table width="100%" cellpadding="0" cellspacing="0">
								<tr>
									<cfif isPrev is "yes">
										<th>
											<span onclick="document.location='/SpecimenDetail.cfm?collection_object_id=#firstID#'">first</span>
										</th>
										<th>
											<span onclick="document.location='/SpecimenDetail.cfm?collection_object_id=#prevID#'">prev</span>
										</th>
									<cfelse>
										<th>first</th>
										<th>prev</th>
									</cfif>
									<cfif isNext is "yes">
										<th>
											<span onclick="document.location='/SpecimenDetail.cfm?collection_object_id=#nextID#'">next</span>
										</th>
										<th>
											<span onclick="document.location='/SpecimenDetail.cfm?collection_object_id=#lastID#'">last</span>
										</th>
									<cfelse>
										<th>next</th>
										<th>last</th>
									</cfif>
								</tr>
								<tr>
								<cfif isPrev is "yes">
									<td align="middle">
										<img src="/images/first.gif" class="likeLink" onclick="document.location='/SpecimenDetail.cfm?collection_object_id=#firstID#'" alt="[ First Record ]">
									</td>
									<td align="middle">
									<img src="/images/previous.gif" class="likeLink"  onclick="document.location='/SpecimenDetail.cfm?collection_object_id=#prevID#'" alt="[ Previous Record ]">
								</td>
								<cfelse>
									<td align="middle">
										<img src="/images/no_first.gif" alt="[ inactive button ]">
									</td>
									<td align="middle">
										<img src="/images/no_previous.gif" alt="[ inactive button ]">
									</td>
								</cfif>
								<cfif isNext is "yes">
									<td align="middle">
										<img src="/images/next.gif" class="likeLink" onclick="document.location='/SpecimenDetail.cfm?collection_object_id=#nextID#'" alt="[ Next Record ]">
									</td>
									<td align="middle">
										<img src="/images/last.gif" class="likeLink" onclick="document.location='/SpecimenDetail.cfm?collection_object_id=#lastID#'" alt="[ Last Record ]">
									</td>
								<cfelse>
									<td align="middle">
										<img src="/images/no_next.gif" alt="[ inactive button ]">
									</td>
									<td align="middle">
										<img src="/images/no_last.gif" alt="[ inactive button ]">
									</td>
								</cfif>
								</tr>
								<tr>
									<cfset lp=1>
									<td>Record</td>
									<td colspan="2">
										<select id="recpager" onchange="document.location='/SpecimenDetail.cfm?collection_object_id='+this.value">
											<cfloop list="#session.collObjIdList#" index="ccid">
												<option <cfif currPos is lp>selected="selected"</cfif>	value="#ccid#">#lp#</option>
												<cfset lp=lp+1>
											</cfloop>
										</select>
									</td>
									<td>of #listlen(session.collObjIdList)#</td>
								</tr>
							</table>
						</div>
					</cfif>
				 </div>
            </td>
        </tr>
    </table>
	<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
		<script language="javascript" type="text/javascript">
			function closeEditApp() {
				$('##bgDiv').remove();
				$('##bgDiv', window.parent.document).remove();
				$('##popDiv').remove();
				$('##popDiv', window.parent.document).remove();
				$('##cDiv').remove();
				$('##cDiv', window.parent.document).remove();
				$('##theFrame').remove();
				$('##theFrame', window.parent.document).remove();
				$("span[id^='BTN_']").each(function(){
					$("##" + this.id).removeClass('activeButton');
					$('##' + this.id, window.parent.document).removeClass('activeButton');
				});
			}
			function loadEditApp(q) {
				closeEditApp();
				if (q=='media'){
					 addMedia('collection_object_id','#collection_object_id#');
				} else {
					var bgDiv = document.createElement('div');
					bgDiv.id = 'bgDiv';
					bgDiv.className = 'bgDiv';
					bgDiv.setAttribute('onclick','closeEditApp()');
					document.body.appendChild(bgDiv);
					var popDiv=document.createElement('div');
					popDiv.id = 'popDiv';
					popDiv.className = 'editAppBox';
					document.body.appendChild(popDiv);
					var links='<ul id="navbar">';
					links+='<li><span onclick="loadEditApp(\'editIdentification\')" class="likeLink" id="BTN_editIdentification">Identification</span></li>';
					links+='<li><span onclick="loadEditApp(\'addAccn\')" class="likeLink" id="BTN_addAccn">Accession</span></li>';
					links+='<li><span onclick="loadEditApp(\'specLocality\')" class="likeLink" id="BTN_specLocality">Locality</span></li>';
					links+='<li><span onclick="loadEditApp(\'editColls\')" class="likeLink" id="BTN_editColls">Agent</span></li>';
					links+='<li><span onclick="loadEditApp(\'editParts\')" class="likeLink" id="BTN_editParts">Parts</span></li>';
					links+='<li><span onclick="loadEditApp(\'findContainer\')" class="likeLink" id="BTN_findContainer">Part Location</span></li>';
					links+='<li><span onclick="loadEditApp(\'editBiolIndiv\')" class="likeLink" id="BTN_editBiolIndiv">Attributes</span></li>';
					links+='<li><span onclick="loadEditApp(\'editIdentifiers\')" class="likeLink" id="BTN_editIdentifiers">Other IDs</span></li>';
					links+='<li><span onclick="loadEditApp(\'media\');" class="likeLink" id="BTN_MediaSearch">Media</span></li>';
					links+='<li><span onclick="loadEditApp(\'Encumbrances\')" class="likeLink" id="BTN_Encumbrances">Encumbrance</span></li>';
					//links+='<li><span onclick="loadEditApp(\'catalog\')" class="likeLink" id="BTN_catalog">Catalog</span></li>';
					links+="</ul>";
					$("##popDiv").append(links);
					var cDiv=document.createElement('div');
					cDiv.className = 'fancybox-close';
					cDiv.id='cDiv';
					cDiv.setAttribute('onclick','closeEditApp()');
					$("##popDiv").append(cDiv);
					$("##popDiv").append('<img src="/images/loadingAnimation.gif" class="centeredImage">');
					var theFrame = document.createElement('iFrame');
					theFrame.id='theFrame';
					theFrame.className = 'editFrame';
					var ptl="/" + q + ".cfm?collection_object_id=" + #collection_object_id#;
					theFrame.src=ptl;
					//document.body.appendChild(theFrame);
					$("##popDiv").append(theFrame);
					$("span[id^='BTN_']").each(function(){
						$("##" + this.id).removeClass('activeButton');
						$('##' + this.id, window.parent.document).removeClass('activeButton');
					});
					$("##BTN_" + q).addClass('activeButton');
					$('##BTN_' + q, window.parent.document).addClass('activeButton');
				}
			}
		</script>
		 <table width="100%">
		    <tr>
			    <td align="center">
					<form name="incPg" method="post" action="SpecimenDetail.cfm">
				        <input type="hidden" name="collection_object_id" value="#collection_object_id#">
						<input type="hidden" name="suppressHeader" value="true">
						<input type="hidden" name="action" value="nothing">
						<input type="hidden" name="Srch" value="Part">
						<input type="hidden" name="collecting_event_id" value="#detail.collecting_event_id#">

						<ul id="navbar">
							<li><span onclick="loadEditApp('editIdentification')" class="likeLink" id="BTN_editIdentification">Identification</span></li>
							<li>
								<span onclick="loadEditApp('addAccn')"	class="likeLink" id="BTN_addAccn">Accn</span>
							</li>
							<li>
								<span onclick="loadEditApp('specLocality')" class="likeLink" id="BTN_specLocality">Locality</span>
							</li>
							<li>
								<span onclick="loadEditApp('editColls')" class="likeLink" id="BTN_editColls">Agents</span>
							</li>
							<li>
								<span onclick="loadEditApp('editParts')" class="likeLink" id="BTN_editParts">Parts</span>
							</li>
							<li>
								<span onclick="loadEditApp('findContainer')" class="likeLink" id="BTN_findContainer">Part Locn.</span>
							</li>
							<li>
								<span onclick="loadEditApp('editBiolIndiv')" class="likeLink" id="BTN_editBiolIndiv">Attributes</span>
							</li>
							<li>
								<span onclick="loadEditApp('editIdentifiers')"	class="likeLink" id="BTN_editIdentifiers">Other IDs</span>
							</li>
							<li>
								<span onclick="loadEditApp('media')" class="likeLink" id="BTN_MediaSearch">Media</span>
							</li>
							<li>
								<span onclick="loadEditApp('Encumbrances')" class="likeLink" id="BTN_Encumbrances">Encumbrances</span>
							</li>
						</ul>
	                </form>
		        </td>
		    </tr>
		</table>
	</cfif>


	<cfquery name="occurrences" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey)#">
		select * from coll_obj_other_id_num where collection_object_id=#collection_object_id# and ID_REFERENCES='occurrence of'
	</cfquery>

	<div>
		This record is an Occurrence, or one instance of this individual at a place and time. It is not a full representation of
		and individual. Citations to this catalog number may have used material from related Occurrences, and related Occurrences may
		be cited as this catalog number. This needs rewritten if we keep it.

		<p>Summary of related Occurrences:</p>

		<cfloop query="occurrences">
			<cfset hasRD=true>
			<cfquery name="relr" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey)#">
				select BASE_URL from CTCOLL_OTHER_ID_TYPE where other_id_type='#occurrences.other_id_type#'
			</cfquery>
			<cfif relr.base_url contains "arctos.database.museum/guid/">
				<!--- one of ours, see if it's public ---->
				<cfquery name="thisOc" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey)#">
					select * from filtered_flat where guid='#occurrences.OTHER_ID_TYPE#:#occurrences.DISPLAY_VALUE#'
				</cfquery>
				<cfif thisOc.recordcount is 1>
					<div>
						Summary Data for <a href="#relr.base_url#/#occurrences.DISPLAY_VALUE#">#relr.base_url#/#occurrences.DISPLAY_VALUE#</a>
						<table border>
							<tr>
								<th>Term</th>
								<th>Value</th>
							</tr>
							<tr>
								<td>GUID/catalog number</td>
								<td>#thisOc.guid#</td>
							</tr>
							<tr>
								<td>Identification</td>
								<td>#thisOc.scientific_name#</td>
							</tr>
							<tr>
								<td>Collecting Date</td>
								<td>#thisOc.began_date#-#thisOc.ended_date#</td>
							</tr>

							<tr>
								<td>this is pulling from filtered_flat</td>
								<td>we can put most anything here, as long as it's not encumbered</td>
							</tr>
							<tr>
								<td>might get big</td>
								<td>we could do the expand/collapse thing if so</td>
							</tr>
							<tr>
								<td>not sure what's necessary</td>
								<td>a little bit and the link?</td>
							</tr>

							<tr>
								<td>or basically everything here</td>
								<td>we can do both</td>
							</tr>

							<tr>
								<td>and it doesn't have to be in a table</td>
								<td>because this is sort of weird</td>
							</tr>

							<tr>
								<td>Or maybe it should be in one table</td>
								<td>rather than one per related Occurrence</td>
							</tr>

						</table>
					</div>
				<cfelse>
					<!--- has a funky base_url ---->
					<p>
						Details of this related Occurrence are not available, or have been restricted by the collection.
						More information may be available at <a href="#relr.base_url#/#occurrences.DISPLAY_VALUE#">#relr.base_url#/#occurrences.DISPLAY_VALUE#</a>
						<a
					</p>
				</cfif>
			<cfelse>
					<cfif len(relr.base_url) gt 0>
					<!--- has a funky base_url ---->
					<p>
						Details of this related Occurrence are not available, or have been restricted by the collection.
						More information may be available at <a href="#relr.base_url#/#occurrences.DISPLAY_VALUE#">#relr.base_url#/#occurrences.DISPLAY_VALUE#</a>
						<a
					</p>
					<cfelse>
						<!--- no base URL --->
						<p>
							A related Occurrence has been recorded, but is not in an actionable format. The related Occurrence is #occurrences.other_id_type# #occurrences.display_value#
						</p>
					</cfif>
			</cfif>

		</cfloop>
	</div>







	<cfinclude template="SpecimenDetail_body.cfm">
	<cfinclude template="/includes/_footer.cfm">
	<cfif isdefined("showAnnotation") and showAnnotation is "true">
		<script language="javascript" type="text/javascript">
			openAnnotation('collection_object_id=#collection_object_id#');
		</script>
	</cfif>
</cfoutput>
<cfcatch>
	<cfdump var=#cfcatch#>
	<cf_logError subject="SpecimenDetail error" attributeCollection=#cfcatch#>
	<div class="error">
		Oh no! Part of this page has failed to load!
		<br>This error has been logged. Please <a href="/contact.cfm?ref=specimendetail">contact us</a> with any useful information.
	</div>
</cfcatch>
</cftry>