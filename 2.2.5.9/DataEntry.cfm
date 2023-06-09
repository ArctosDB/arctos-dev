<div id="msg"></div>
<div><!--- spacer ---></div>
<cfinclude template="/includes/_header.cfm">
<cfset title="Data Entry">
<style>
.bigwarning{
	font-size:x-large;
	padding: 2em;
	margin: 2em;
}
</style>
<div class="importantNotification">
	<p class="bigwarning">
		This form is deprecated.
	</p>
	<p class="bigwarning">
		Do not use this form.
	</p>
	<p class="bigwarning">
		This form is not for use.
	</p>
	<p class="bigwarning">
		Please use the standard <a href="/enter_data.cfm">data entry form</a>
	</p>
	<p class="bigwarning">
		Please do not use this form.
	</p>
</div>




<!----


<script type='text/javascript' src='/includes/jquery/jquery-autocomplete/jquery.autocomplete.pack.js'></script>
---->
<script type='text/javascript' src='/includes/DEAjax.js?v=13.1'></script>
<link rel="stylesheet" type="text/css" href="/includes/_DEstyle.css">

<cf_showMenuOnly>
<cfif not isdefined("ImAGod") or len(ImAGod) is 0>
	<cfset ImAGod = "no">
</cfif>
<cfif isdefined("CFGRIDKEY") and not isdefined("collection_object_id")>
	<cfset collection_object_id = CFGRIDKEY>
</cfif>
<cfset collid = 1>
<cfset thisDate = dateformat(now(),"yyyy-mm-dd")>
<!--------------------------------------------------------------------------------------------------------->
<cfif action is "nothing">
	<cfoutput>
		<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select * from cf_dataentry_settings where username='#session.username#'
		</cfquery>
		<cfif d.recordcount is not 1>
			<cfquery name="seed" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				insert into cf_dataentry_settings (
					username
				) values (
					'#session.username#'
				)
			</cfquery>
		</cfif>
		<cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
			select * from collection ORDER BY guid_prefix
		</cfquery>
		<cfloop query="c">
			<cfquery  name="isBL" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select * from bulkloader where collection_object_id = #collection_id#
			</cfquery>
			<cfif isBl.recordcount is 0>
				<!--- use this to set up DEFAULTS and "prime" the bulkloader ---->
				<cfquery name="prime" datasource="uam_god">
					insert into bulkloader (
						collection_object_id,
						guid_prefix,
						status,
						collection_id,
						entered_agent_id,
						verificationstatus
					) VALUES (
						#collection_id#,
						'#guid_prefix#',
						'#ucase(guid_prefix)# TEMPLATE',
						#collection_id#,
						0,
						'unverified'
					)
				</cfquery>
			<cfelseif isBL.status is not "#ucase(guid_prefix)# TEMPLATE">
				<cfquery name="move" datasource="uam_god">
					update bulkloader set collection_object_id = nextval('bulkloader_pkey')
					where collection_object_id = #collection_id#
				</cfquery>
				<cfquery name="prime" datasource="uam_god">
					insert into bulkloader (
						collection_object_id,
						guid_prefix,
						status,
						collection_id,
						entered_agent_id
					) VALUES (
						#collection_id#,
						'#guid_prefix#',
						'#ucase(guid_prefix)# TEMPLATE',
						#collection_id#,
						0
					)
				</cfquery>
			</cfif>
		</cfloop>
		

		


		<p>Welcome to Data Entry, #session.username#</p>
		<ul>
			<li>Green Screen: You are entering data to a new record.</li>
			<li>Blue Screen: you are editing an unloaded record that you've previously entered.</li>
			<li>Pink Screen: A record has been saved but has errors that must be corrected. Fix and save to continue.</li>
		</ul>
    	<p><a href="/Bulkloader/cloneWithBarcodes.cfm">Clone records by Barcode</a></p>
		<cfquery name="theirLast" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select
				max(collection_object_id) theId,
				guid_prefix
			from bulkloader where enteredby = '#session.username#'
			GROUP BY
				guid_prefix
			order by guid_prefix
		</cfquery>
		Begin at....<br>
		<form name="begin" method="post" action="DataEntry.cfm">
			<input type="hidden" name="action" value="enter" />
			<select name="collection_object_id" size="1">
				<cfif theirLast.recordcount gt 0>
					<cfloop query="theirLast">
						<cfquery name="temp" dbtype="query">
							select GUID_PREFIX from c where guid_prefix='#guid_prefix#'
						</cfquery>
						<option value="#theId#">Your Last #temp.GUID_PREFIX#</option>
					</cfloop>
				</cfif>
				<cfloop query="c">
					<option value="#collection_id#">Enter a new #GUID_PREFIX# Record</option>
				</cfloop>
			</select>
			<input class="lnkBtn" type="submit" value="Enter Data"/>
		</form>
	</cfoutput>
</cfif>
<cfif action is "saveCust">
	<cfdump var=#form#>
</cfif>
<!------------ editEnterData --------------------------------------------------------------------------------------------->
<cfif action is "enter" or action is "edit">
	<cfoutput>
		<cfif not isdefined("collection_object_id") or len(collection_object_id) is 0>
			you don't have an ID. <cfabort>
		</cfif>

		<cfquery name="ctid_references" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select id_references from ctid_references where id_references != 'self' order by id_references
		</cfquery>
		<cfquery name="ctnature" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select nature_of_id from ctnature_of_id order by nature_of_id
		</cfquery>
		<cfquery name="ctunits" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	       select ORIG_LAT_LONG_UNITS from ctLAT_LONG_UNITS order by orig_lat_long_units
	    </cfquery>
		<cfquery name="ctflags" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	       select flags from ctflags order by flags
	    </cfquery>
		<cfquery name="CTCOLL_OBJ_DISP" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	       select COLL_OBJ_DISPOSITION from CTCOLL_OBJ_DISP order by coll_obj_DISPOSITION
	    </cfquery>
		<cfquery name="CTPART_PRESERVATION" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	       select part_preservation from CTPART_PRESERVATION order by part_preservation
	    </cfquery>
		<cfquery name="ctdatum" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select datum from ctdatum order by datum
	    </cfquery>
		<cfquery name="ctverificationstatus" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	       	select verificationstatus from ctverificationstatus order by verificationstatus
	    </cfquery>
		<cfquery name="ctcollecting_source" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	       	select collecting_source from ctcollecting_source order by collecting_source
	    </cfquery>
	    <cfquery name="ctew" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	    	select e_or_w from ctew order by e_or_w
	    </cfquery>
	    <cfquery name="ctcollector_role" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	    	select collector_role from ctcollector_role order by collector_role
	    </cfquery>
	    <cfquery name="ctns" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	       	select n_or_s from ctns order by n_or_s
	    </cfquery>
		<cfquery name="ctOtherIdType" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			SELECT distinct other_id_type,sort_order FROM ctColl_Other_id_type order by sort_order, other_id_type
	    </cfquery>

		<cfquery name="ctgeoreference_protocol" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select georeference_protocol from ctgeoreference_protocol order by georeference_protocol
		</cfquery>
		<cfquery name="ctspecimen_event_type" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select specimen_event_type from ctspecimen_event_type order by specimen_event_type
		</cfquery>
		<cfquery name="ctlength_units" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select length_units from ctlength_units order by length_units
		</cfquery>
		<cfquery name="ctlocality_attribute_type" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select attribute_type from ctlocality_attribute_type order by attribute_type
		</cfquery>
		<cfquery name="ctidentification_confidence" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select identification_confidence from ctidentification_confidence order by identification_confidence
		</cfquery>
		<cfquery name="ctcataloged_item_type"  datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select * from ctcataloged_item_type  order by cataloged_item_type
		</cfquery>
		<cfquery name="ctCodes" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select
				attribute_type,
				value_code_table,
				units_code_table
		 	from ctattribute_code_tables
		</cfquery>
		<cfset sql = "select collection_object_id from bulkloader where collection_object_id > 1000  ">
		<cfif ImAGod is "no">
			 <cfset sql = "#sql# AND enteredby = '#session.username#'">
		</cfif>
		<cfset sql = "#sql# order by collection_object_id limit 1000">
		<cfquery name="whatIds" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			#preservesinglequotes(sql)#
		</cfquery>
		<cfset idList=valuelist(whatIds.collection_object_id)>
		<cfset currentPos = listFind(idList,collection_object_id)>
		<div id="loadedMsgDiv"></div>
		<form name="dataEntry" method="post" action="DataEntry.cfm" onsubmit="return cleanup(); return noEnter();" id="dataEntry">
			<input type="hidden" name="action" value="#action#" id="action">
			<input type="hidden" name="nothing" value="" id="nothing"/><!--- trashcan for picks - don't delete --->
			<input type="hidden" name="ImAGod" value="#ImAGod#" id="ImAGod"><!--- allow power users to browse other's records --->
			<input type="hidden" name="sessionusername" value="#session.username#" id="sessionusername">
			<input type="hidden" name="sessioncustomotheridentifier" value="#session.customotheridentifier#" id="sessioncustomotheridentifier">
			<input type="hidden" name="collection_object_id" value="#collection_object_id#" id="collection_object_id"/>
			<div id="DEControls">
				<span id="customizeForm" class="likeLink" onclick="customize()">[ customize form ]</span>
				<span id="calControl" class="likeLink" onclick="removeCalendars();">[ disable calendars ]</span>
				<span id="killSortable" class="likeLink" onclick="killSortable();">[ disable sortable ]</span>
				<span id="makeSortable" class="likeLink" onclick="makeSortable();">[ enable sortable ]</span>
				<span id="resetSort" class="likeLink" onclick="resetSort();">[ reset default sort ]</span> ~
				<span>Drag gray cell title bars to rearrange form</span>
			</div>
			<div id="dataEntryContainer">

				    <div id="left-col">

				        <div class="wrapper" id="sort_catitemid">
				            <div class="item">
								<div class="celltitle">Cat Item IDs</div>
								<table cellpadding="0" cellspacing="0" class="fs" border="1"><!--- cat item IDs --->
									<tr>
										<td class="valigntop">
											<label for="guid_prefix">Coln</label>
											<input type="text" readonly="readonly" class="readClr" name="guid_prefix" id="guid_prefix" size="8">
										</td>
										<td class="valigntop">
											<label for="cat_num">Cat##</label>
											<input type="text" name="cat_num" size="17" id="cat_num">
											<span id="catNumLbl" class="f11a"></span>
										</td>
										<td class="valigntop">
											<label for="other_id_num_type_5">CustomID Type</label>
											<select name="other_id_num_type_5" style="width:180px"
												id="other_id_num_type_5" onChange="deChange(this.id);">
												<option value=""></option>
												<cfloop query="ctOtherIdType">
													<option value="#other_id_type#">#other_id_type#</option>
												</cfloop>
											</select>
										</td>
										<td class="valigntop">
											<label for="other_id_num_5">CustomID</label>
											<input type="text" name="other_id_num_5" size="8" id="other_id_num_5">

										</td>
										<td class="valigntop">
											<label for="autoinc">AutoInc?</label>
											<input type="checkbox" id="autoinc">
										</td>
										<td class="nowrap valigntop">
											<label for="accn">Accn <span class="infoLink" onclick="getDEAccn();">[ pick ]</span></label>
											<input type="text" name="accn" size="25" class="reqdClr" id="accn" onchange="getDEAccn();">
										</td>
									</tr>
									<tr>
										<td colspan="2">
											<label for="enteredby">Entered&nbsp;By</label>
											<input type="text" class="readClr" readonly="readonly" size="15" name="enteredby" id="enteredby">
										</td>
										<td colspan="3">
											<label for="status">Status</label>
											<input type="text" name="status" size="100" id="status" readonly="readonly" class="readClr" value="waiting approval">
										</td>
										<td>
											<label for="uuid">UUID</label>
											<input type="text" name="uuid" id="uuid" readonly="readonly" class="readClr">
										</td>
									</tr>
								</table><!---------------------------------- / cat item IDs ---------------------------------------------->
				            </div><!--- end item --->
				        </div><!--- end sort_catitemid --->

				        <div class="wrapper" id="sort_agent">
				            <div class="item">
								<div class="celltitle">Agents <span class="helpLink" data-helplink="agent">[ documentation ]</span></div>
								<table cellpadding="0" cellspacing="0" class="fs"><!--- agents --->
									<tr>
										<cfloop from="1" to="5" index="i">
											<cfif i is 1 or i is 3 or i is 5><tr></cfif>
											<td id="d_collector_role_#i#" align="right">
												<select name="collector_role_#i#" size="1" <cfif i is 1>class="reqdClr"</cfif> id="collector_role_#i#">
													<cfloop query="ctcollector_role">
														<option value="#collector_role#">#collector_role#</option>
													</cfloop>
												</select>
											</td>
											<td  id="d_collector_agent_#i#" nowrap="nowrap">
												<span class="f11a">#i#</span>
												<input type="hidden" id="nothing" name="nothing">
												<input type="text" name="collector_agent_#i#"
													<cfif i is 1>class="reqdClr"</cfif> id="collector_agent_#i#"
													onchange="getAgent('nothing',this.id,'dataEntry',this.value);"
													onkeypress="return noenter(event);">
												<span class="infoLink" onclick="copyAllAgents('collector_agent_#i#');">Copy2All</span>
											</td>
											<cfif i is 2 or i is 4 or i is 5></tr></cfif>
										</cfloop>
								</table><!---- / agents------------->
				            </div><!--- end item --->
						</div><!--- end sort_agent --->

						<div class="wrapper" id="sort_otherid">
				            <div class="item">
								<div class="celltitle">Other IDs  <span class="helpLink" data-helplink="other_id">[ documentation ]</span></div>
									<table cellpadding="0" cellspacing="0" class="fs"><!------ other IDs ------------------->
										<tr>
											<th>ID References</th>
											<th>ID Type</th>
											<th>ID Value</th>
											<th></th>
										</tr>
										<cfloop from="1" to="4" index="i">
											<tr>

												<td>
													<select name="other_id_references_#i#" id="other_id_references_#i#" size="1">
														<option value="">self</option>
														<cfloop query="ctid_references">
															<option value="#ctid_references.id_references#">#ctid_references.id_references#</option>
														</cfloop>
													</select>
												</td>
												<td id="d_other_id_num_#i#">
													<span class="f11a">OtherID #i#</span>
													<select name="other_id_num_type_#i#" style="width:250px"
														id="other_id_num_type_#i#" onChange="deChange(this.id);">
														<option value=""></option>
														<cfloop query="ctOtherIdType">
															<option value="#other_id_type#">#other_id_type#</option>
														</cfloop>
													</select>
												</td>
												<td>
													<input type="text" name="other_id_num_#i#" id="other_id_num_#i#">
												</td>
												<td>
													<span class="infoLink" onclick="getRelatedData(#i#)">[ pull ]</span>
												</td>
											</tr>
										</cfloop>
								</table><!---- /other IDs ---->
					        </div><!--- end item --->
				        </div><!--- end sort_otherid --->

						<div class="wrapper" id="sort_identification">
				            <div class="item">
								<div class="celltitle">Identification <span class="helpLink" data-helplink="identification">[ documentation ]</span></div>
								<table cellpadding="0" cellspacing="0" class="fs"><!----- identification ----->
									<tr>
										<td align="right">
											<span class="f11a">Scientific&nbsp;Name</span>
										</td>
										<td>
											<input type="text" name="taxon_name" class="reqdClr" size="40" id="taxon_name"
												onchange="taxaPick('nothing',this.id,'dataEntry',this.value)">
												<span class="infoLink" onclick="buildTaxonName();">build</span>
										</td>
									</tr>
									<tr>
										<td align="right"><span class="f11a">ID By</span></td>
										<td>
											<input type="text" name="id_made_by_agent" class="reqdClr" size="40"
												id="id_made_by_agent"
												onchange="getAgent('nothing',this.id,'dataEntry',this.value);"
												onkeypress="return noenter(event);">
											<span class="infoLink" onclick="copyAllAgents('id_made_by_agent');">Copy2All</span>
										</td>
									</tr>
									<tr>
										<td align="right"><span class="f11a">Nature</span></td>
										<td>
											<select name="nature_of_id" class="reqdClr" id="nature_of_id">
												<option value=""></option>
												<cfloop query="ctnature">
													<option value="#ctnature.nature_of_id#">#ctnature.nature_of_id#</option>
												</cfloop>
											</select>
										</td>
									</tr>
									<tr>
										<td align="right"><span class="f11a">Confidence</span></td>
										<td>
											<select name="identification_confidence" class="" id="identification_confidence">
												<option value=""></option>
												<cfloop query="ctidentification_confidence">
													<option value="#ctidentification_confidence.identification_confidence#">#ctidentification_confidence.identification_confidence#</option>
												</cfloop>
											</select>
										</td>
									</tr>
									<tr>
										<td align="right"><span class="f11a">Date</span></td>
										<td>
											<input type="text" name="made_date" id="made_date">
											<span class="infoLink" onclick="copyAllDates('made_date');">Copy2All</span>
										</td>
									</tr>
									<tr id="d_identification_remarks">
										<td align="right"><span class="f11a">ID Remk</span></td>
										<td>
											<textarea rows="1" cols="40" class="mediumtextarea"  name="identification_remarks" id="identification_remarks"></textarea>
										</td>
									</tr>
								</table><!------ /identification -------->
					        </div><!--- end item --->
				        </div><!--- end sort_identification --->

						<div class="wrapper" id="sort_attributes">
							<div class="item">
								<div class="celltitle">Attributes</div>
								<table cellpadding="0" cellspacing="0" class="fs"><!----- attributes ------->
									<tr>
										<td id="attributeTableCell">
											<!----
											<cfinclude template="/form/DataEntryAttributeTable.cfm">
											---->
										</td>
									</tr>
								</table><!---- /attributes ----->
							</div><!--- end item --->
						</div><!--- end sort_attributes --->
						<div class="wrapper" id="sort_randomness">
							<div class="item">
								<div class="celltitle">Random Junk</div>
								<table cellpadding="0" cellspacing="0" class="fs"><!------- remarkey stuff --->
									<tr id="d_coll_object_remarks">
										<td colspan="2">
											<span class="f11a">Spec&nbsp;Remark</span>
												<textarea style="largetextarea" name="coll_object_remarks" id="coll_object_remarks" rows="2" cols="60"></textarea>
										</td>
									</tr>
									<tr>
										<td id="d_associated_species"  colspan="2">
											<span class="f11a">Associated&nbsp;Species</span>
											<input type="text" name="associated_species" size="60" id="associated_species">
										</td>
									</tr>
									<tr>
										<td id="d_cataloged_item_type">
											<span class="f11a">Cat&nbsp;Itm&nbsp;Typ</span>
											<select name="cataloged_item_type" id="cataloged_item_type" >
												<option value=""></option>
												<cfloop query="ctcataloged_item_type">
													<option	value="#ctcataloged_item_type.cataloged_item_type#">#ctcataloged_item_type.cataloged_item_type#</option>
												</cfloop>
											</select>
										</td>
										<td id="d_flags">
											<span class="f11a">Missing</span>
											<select name="flags" size="1" style="width:120px" id="flags">
												<option  value=""></option>
												<cfloop query="ctflags">
													<option value="#flags#">#flags#</option>
												</cfloop>
											</select>
										</td>
									</tr>
								</table><!------- /remarkey stuff --->
							</div><!--- end item --->
						</div><!--- end sort_randomness --->
<!---- ---->
				    </div><!-- end left-col -->
				    <div id="right-col">
						<div class="wrapper" id="sort_specevent">
							<div class="item">
								<div class="celltitle">Specimen/Event <span class="helpLink" data-helplink="specimen_event">[ documentation ]</span></div>
								<table cellspacing="0" cellpadding="0" class="fs"><!----- Specimen/Event ---------->
									<tr>
										<td colspan="2">
											<table>
												<tr>
													<td align="right">
														<span class="f11a">Event Determiner</span>
													</td>
													<td>
														<input type="text" name="event_assigned_by_agent" class="reqdClr"
															id="event_assigned_by_agent"
															onchange="getAgent('nothing',this.id,'dataEntry',this.value);"
															onkeypress="return noenter(event);">
													</td>
													<td align="right"><span class="f11a">Detr. Date</span></td>
													<td>
														<input type="text" name="event_assigned_date" class="reqdClr" id="event_assigned_date">
														<span class="infoLink" onclick="copyAllDates('event_assigned_date');">Copy2All</span>
													</td>
												</tr>
											</table>
										</td>
									</tr>
									<tr>
										<td align="right"><span class="f11a">Specimen/Event Type</span></td>
										<td>
											<select name="specimen_event_type" size="1" id="specimen_event_type" class="reqdClr">
												<cfloop query="ctspecimen_event_type">
													<option value="#ctspecimen_event_type.specimen_event_type#">#ctspecimen_event_type.specimen_event_type#</option>
												</cfloop>
											</select>
										</td>
									</tr>
									<tr>
										<td align="right"><span class="f11a">Coll. Src.:</span></td>
										<td>
											<table cellspacing="0" cellpadding="0">
												<tr>
													<td>
														<select name="collecting_source" size="1" id="collecting_source">
															<option value=""></option>
															<cfloop query="ctcollecting_source">
																<option value="#collecting_source#">#collecting_source#</option>
															</cfloop>
														</select>
													</td>
													<td align="right"><span class="f11a">Coll. Meth.:</span></td>
													<td>
														<input type="text" name="collecting_method" id="collecting_method">
													</td>
												</tr>
											</table>
										</td>
									</tr>

									<tr id="d_habitat">
										<td align="right"><span class="f11a">Habitat</span></td>
										<td>
											<input type="text" name="habitat" size="50" id="habitat">
										</td>
									</tr>
									<tr>
										<td align="right"><span class="f11a">VerificationStatus</span></td>
										<td>
											<select name="verificationstatus" size="1" class="reqdClr" id="verificationstatus">
												<cfloop query="ctverificationstatus">
													<option <cfif ctverificationstatus.verificationstatus is "unverified"> selected="selected" </cfif>value="#ctverificationstatus.verificationstatus#">#ctverificationstatus.verificationstatus#</option>
												</cfloop>
											</select>
										</td>
									</tr>
									<tr>
										<td align="right"><span class="f11a">Specimen/Event Remark</span></td>
										<td>
											<textarea rows="1" cols="40" class="mediumtextarea"  name="specimen_event_remark" id="specimen_event_remark"></textarea>
										</td>
									</tr>
								</table>
							</div><!--- end item --->
						</div><!--- end sort_specevent --->
						<div class="wrapper" id="sort_collevent">
							<div class="item">
								<div class="celltitle">Collecting Event <span class="helpLink" data-helplink="collecting_event">[ documentation ]</span></div>
								<table cellspacing="0" cellpadding="0" class="fs">
									<tr>
										<td colspan="2">
											<table>
												<tr>
													<td align="right"><span class="f11a">Event Nickname</span></td>
													<td>
														<input type="text" name="collecting_event_name" class="" id="collecting_event_name" size="60"
															onchange="findCollEvent('collecting_event_id','dataEntry','verbatim_locality',this.value);">
													</td>
													<td id="d_collecting_event_id">
													<span class="f11a">Existing&nbsp;EventID</span>
													</td><td>
														<input type="text" name="collecting_event_id" id="collecting_event_id" class="readClr" size="8">
														<input type="hidden" id="fetched_eventid">
													</td>
													<td>
														<span class="infoLink" id="eventPicker" onclick="findCollEvent('collecting_event_id','dataEntry','verbatim_locality'); return false;">
															Pick&nbsp;Event
														</span>
														<span class="infoLink" id="eventUnPicker" style="display:none;" onclick="unpickEvent()">
															Depick&nbsp;Event
														</span>
													</td>
												</tr>
											</table>
										</td>
									</tr>
									<tr>
										<td align="right"><span class="f11a">Verbatim Locality</span></td>
										<td>
											<input type="text"  name="verbatim_locality"
												class="reqdClr" size="80"
												id="verbatim_locality">
											<span class="infoLink" onclick="document.getElementById('verbatim_locality').value=document.getElementById('spec_locality').value;">
												&nbsp;Use&nbsp;Specloc
											</span>
										</td>
									</tr>
									<tr>
										<td align="right"><span class="f11a">VerbatimDate</span></td>
										<td>
											<input type="text" name="verbatim_date" class="reqdClr" id="verbatim_date" size="20">
											<span class="infoLink"
												onClick="copyVerbatim($('##verbatim_date').val());">--></span>
											<span class="f11a">Begin</span>
											<input type="text" name="began_date" class="reqdClr"  id="began_date" size="10">
											<span class="infoLink" onclick="copyBeganEnded();">>></span>
											<span class="f11a">End</span>
											<input type="text" name="ended_date" class="reqdClr"  id="ended_date" size="10">
											<span class="infoLink" onclick="copyAllDates('ended_date');">Copy2All</span>
										</td>
									</tr>
									<tr id="d_coll_event_remarks">
										<td align="right"><span class="f11a">CollEvntRemk</span></td>
										<td>
											<textarea rows="1" cols="40" class="mediumtextarea"  name="coll_event_remarks" id="coll_event_remarks"></textarea>
										</td>
									</tr>
									<tr>
										<td colspan="2" id="dateConvertStatus"></td>
									</tr>
								</table>
							</div><!--- end item --->
						</div><!--- end sort_collevent --->
						<div class="wrapper" id="sort_locality">
							<div class="item">
								<div class="celltitle">Locality <span class="helpLink" data-helplink="locality">[ documentation ]</span></div>
								<table cellspacing="0" cellpadding="0" class="fs">
									<tr>
										<td align="right"><span class="f11a">Higher Geog</span></td>
										<td>
											<!----
											<input type="text" name="higher_geog" class="reqdClr" id="higher_geog" size="80"
												onchange="getGeog('nothing',this.id,'dataEntry',this.value)">
												---->
												<input type="text" name="higher_geog" class="reqdClr" id="higher_geog" size="80"
												onchange="GeogPick('nothing',this.id,'dataEntry',this.value)">
										</td>
									</tr>
									<tr>
										<td colspan="2">
											<table>
												<tr>
													<td align="right"><span class="f11a">Locality Nickname</span></td>
													<td>
														<input type="text" name="locality_name" class="" id="locality_name" size="60"
															onchange="LocalityPick('locality_id','spec_locality','dataEntry',this.value);">
													</td>
													<td id="d_locality_id">
													<span class="f11a">Existing&nbsp;LocalityID</span>
													</td><td>
														<input type="hidden" id="fetched_locid">
														<input type="text" name="locality_id" id="locality_id" class="readClr" size="8">
													</td>
													<td>
														<span class="infoLink" id="localityPicker"
															onclick="LocalityPick('locality_id','spec_locality','dataEntry',''); return false;">
															Pick&nbsp;Locality
														</span>
														<span class="infoLink"
															id="localityUnPicker"
															style="display:none;"
															onclick="unpickLocality()">
															Depick&nbsp;Locality
														</span>
													</td>
												</tr>
											</table>
										</td>
									</tr>
									<tr>
										<td align="right"><span class="f11a">Spec Locality</span></td>
										<td>
											<input type="text" name="spec_locality" class="reqdClr" id="spec_locality" size="80">
											<span class="infoLink" onclick="document.getElementById('spec_locality').value=document.getElementById('verbatim_locality').value;">
												&nbsp;Use&nbsp;VerbLoc
											</span>
											<span class="infoLink" onclick="document.getElementById('spec_locality').value='No specific locality recorded.';">
												&nbsp;No&nbsp;specific&nbsp;locality&nbsp;recorded.
											</span>
										</td>
									</tr>
									<tr>
										<td colspan="2" id="d_orig_elev_units">
											<div class="oneFormSectionCompact">
												<span class="f11a">Elevation&nbsp;(min-max)&nbsp;between</span>
												<input type="text" name="minimum_elevation" size="4" id="minimum_elevation">
												<span class="infoLink"
													onclick="document.getElementById('maximum_elevation').value=document.getElementById('minimum_elevation').value";>&nbsp;>>&nbsp;</span>
												<input type="text" name="maximum_elevation" size="4" id="maximum_elevation">
												<select name="orig_elev_units" size="1" id="orig_elev_units">
													<option value=""></option>
													<cfloop query="ctlength_units">
														<option value="#length_units#">#length_units#</option>
													</cfloop>
												</select>
												provide all or none
											</div>

										</td>
									</tr>
									<tr>
										<td colspan="2" id="d_depth_units">
											<div class="oneFormSectionCompact">
												<span class="f11a">Depth&nbsp;(min-max)&nbsp;between</span>
												<input type="text" name="min_depth" size="4" id="min_depth">
												<span class="infoLink"
													onclick="document.getElementById('max_depth').value=document.getElementById('min_depth').value";>&nbsp;>>&nbsp;</span>
												<input type="text" name="max_depth" size="4" id="max_depth">
												<select name="depth_units" size="1" id="depth_units">
													<option value=""></option>
													<cfloop query="ctlength_units">
														<option value="#length_units#">#length_units#</option>
													</cfloop>
												</select>
												provide all or none
											</div>
										</td>
									</tr>

									<tr id="d_locality_remarks">
										<td align="right"><span class="f11a">LocalityRemk</span></td>
										<td>
											<textarea rows="1" cols="40" class="mediumtextarea"  name="locality_remarks" id="locality_remarks"></textarea>
										</td>
									</tr>
									<tr id="d_wkt_media_id">
										<td align="right"><span class="f11a">WKTMediaID</span></td>
										<td>
											<input type="text" name="wkt_media_id" id="wkt_media_id" size="20">
										</td>
									</tr>
								</table><!----- /locality ---------->
							</div><!--- end item --->
						</div><!--- end sort_locality --->
						<div class="wrapper" id="sort_coordinates">
							<div class="item">
								<div class="celltitle">
									Coordinates (event and locality) <span class="helpLink" data-helplink="coordinates">[ documentation ]</span>
								</div>
								<table cellpadding="0" cellspacing="0" class="fs" id="d_orig_lat_long_units"><!------- coordinates ------->
									<tr>
										<td>
											<table>
												<tr>
													<td align="right"  valign="top"><span class="f11a">Original&nbsp;lat/long&nbsp;Units</span></td>
													<td colspan="99">
														<table>
															<tr>
																<td valign="top">
																	<select name="orig_lat_long_units" id="orig_lat_long_units"
																		onChange="switchActive(this.value);dataEntry.max_error_distance.focus();">
																		<option value=""></option>
																		<cfloop query="ctunits">
																		  <option value="#ctunits.ORIG_LAT_LONG_UNITS#">#ctunits.ORIG_LAT_LONG_UNITS#</option>
																		</cfloop>
																	</select>
																</td>
																<td valign="top">
																	<span style="font-size:small" class="likeLink" onclick="geolocate()">[ geolocate ]</span>
																</td>
																<td valign="top">
																	<div id="geoLocateResults" style="font-size:small"></div>
																</td>
															</tr>
														</table>
													</td>
												</tr>
											</table>
										</td>
									</tr>
									<tr>
										<td>
											<div id="lat_long_meta" class="noShow">
												<table cellpadding="0" cellspacing="0">
													<tr>
														<td align="right"><span class="f11a">Max Error</span></td>
														<td>
															<input type="text" name="max_error_distance" id="max_error_distance" size="10">
															<select name="max_error_units" size="1" id="max_error_units">
																<option value=""></option>
																<cfloop query="ctlength_units">
																  <option value="#ctlength_units.length_units#">#ctlength_units.length_units#</option>
																</cfloop>
															</select>
														</td>
													</tr>
													<tr>
														<td align="right"><span class="f11a">Datum</span></td>
														<td>
															<select name="datum" size="1" class="reqdClr" id="datum">
																<option value=""></option>
																<cfloop query="ctdatum">
																	<option value="#datum#">#datum#</option>
																</cfloop>
															</select>
														</td>
													</tr>


													<tr>
														<td align="right"><span class="f11a">Georeference Source</span></td>
														<td colspan="3" nowrap="nowrap">
															<input type="text" name="georeference_source" id="georeference_source"  class="reqdClr" size="60">
														</td>
													</tr>
													<tr>
														<td align="right"><span class="f11a">Georeference Protocol</span></td>
														<td>
															<select name="georeference_protocol" size="1" class="reqdClr" style="width:130px" id="georeference_protocol">
																<option value=""></option>
																<cfloop query="ctgeoreference_protocol">
																	<option value="#ctgeoreference_protocol.georeference_protocol#">#ctgeoreference_protocol.georeference_protocol#</option>
																</cfloop>
															</select>
														</td>
													</tr>
												</table>
											</div>
											<div id="dms" class="noShow">
												<table cellpadding="0" cellspacing="0">
													<tr>
														<td align="right"><span class="f11a">Lat Deg</span></td>
														<td>
															<input type="text" name="latdeg" size="4" id="latdeg" class="reqdClr">
														</td>
														<td align="right"><span class="f11a">Min</span></td>
														<td>
															<input type="text"
																 name="LATMIN"
																size="4"
																id="latmin"
																class="reqdClr">
														</td>
														<td align="right"><span class="f11a">Sec</span></td>
														<td>
															<input type="text"
																 name="latsec"
																size="6"
																id="latsec"
																class="reqdClr">
															</td>
														<td align="right"><span class="f11a">Dir</span></td>
														<td>
															<select name="latdir" size="1" id="latdir" class="reqdClr">
																<option value=""></option>
																<option value="N">N</option>
																<option value="S">S</option>
															  </select>
														</td>
													</tr>
													<tr>
														<td align="right"><span class="f11a">Long Deg</span></td>
														<td>
															<input type="text"
																name="longdeg"
																size="4"
																id="longdeg"
																class="reqdClr">
														</td>
														<td align="right"><span class="f11a">Min</span></td>
														<td>
															<input type="text"
																name="longmin"
																size="4"
																id="longmin"
																class="reqdClr">
														</td>
														<td align="right"><span class="f11a">Sec</span></td>
														<td>
															<input type="text"
																 name="longsec"
																size="6"
																id="longsec"
																class="reqdClr">
														</td>
														<td align="right"><span class="f11a">Dir</span></td>
														<td>
															<select name="longdir" size="1" id="longdir" class="reqdClr">
																<option value=""></option>
																<option value="E">E</option>
																<option value="W">W</option>
															  </select>
														</td>
													</tr>
												</table>
											</div>
											<div id="ddm" class="noShow">
												<table cellpadding="0" cellspacing="0">
													<tr>
														<td align="right"><span class="f11a">Lat Deg</span></td>
														<td>
															<input type="text"
																 name="decLAT_DEG"
																size="4"
																id="decLAT_DEG"
																class="reqdClr"
																onchange="dataEntry.latdeg.value=this.value;">
														</td>
														<td align="right"><span class="f11a">Dec Min</span></td>
														<td>
															<input type="text"
																name="dec_lat_min"
																 size="8"
																id="dec_lat_min"
																class="reqdClr">
														</td>
														<td align="right"><span class="f11a">Dir</span></td>
														<td>
															<select name="decLAT_DIR"
																size="1"
																id="decLAT_DIR"
																class="reqdClr"
																onchange="dataEntry.latdir.value=this.value;">
																<option value=""></option>
																<option value="N">N</option>
																<option value="S">S</option>
															</select>
														</td>
													</tr>
													<tr>
														<td align="right"><span class="f11a">Long Deg</span></td>
														<td>
															<input type="text"
																name="decLONGDEG"
																size="4"
																id="decLONGDEG"
																class="reqdClr"
																onchange="dataEntry.longdeg.value=this.value;">
														</td>
														<td align="right"><span class="f11a">Dec Min</span></td>
														<td>
															<input type="text"
																name="DEC_LONG_MIN"
																size="8"
																id="dec_long_min"
																class="reqdClr">
														</td>
														<td align="right"><span class="f11a">Dir</span></td>
														<td>
															<select name="decLONGDIR"
																 size="1"
																id="decLONGDIR"
																class="reqdClr"
																onchange="dataEntry.longdir.value=this.value;">
																<option value=""></option>
																<option value="E">E</option>
																<option value="W">W</option>
															</select>
														</td>
													</tr>
												</table>
											</div>
											<div id="dd" class="noShow">
												<span class="f11a">Dec Lat</span>
												<input type="text"
													 name="dec_lat"
													size="8"
													id="dec_lat"
													class="reqdClr">
												<span class="f11a">Dec Long</span>
													<input type="text"
														 name="dec_long"
														size="8"
														id="dec_long"
														class="reqdClr">
											</div>
											<div id="utm" class="noShow">
												<span class="f11a">UTM Zone</span>
												<input type="text"
													 name="utm_zone"
													size="8"
													id="utm_zone"
													class="reqdClr">
												<span class="f11a">UTM E/W</span>
												<input type="text"
													 name="utm_ew"
													size="8"
													id="utm_ew"
													class="reqdClr">
												<span class="f11a">UTM N/S</span>
												<input type="text"
													 name="utm_ns"
													size="8"
													id="utm_ns"
													class="reqdClr">
											</div>
										</td>
									</tr>
								</table><!---- /coordinates ---->
							</div><!--- end item --->
						</div><!--- end sort_coordinates --->
						<div class="wrapper" id="sort_geology">
							<div class="item">
								<div class="celltitle">
									Locality Attribute <span class="helpLink" data-helplink="locality_attribute">[ documentation ]</span>
								</div>
									<table cellpadding="0" cellspacing="0" class="fs">
										<tr>
											<td>
												<table cellpadding="0" cellspacing="0">
													<tr>
														<th nowrap="nowrap"><span class="f11a">Attribute</span></th>
														<th><span class="f11a">Value</span></th>
														<th><span class="f11a">Unit</span></th>
														<th><span class="f11a">Determiner</span></th>
														<th><span class="f11a">Date</span></th>
														<th><span class="f11a">Method</span></th>
														<th><span class="f11a">Remark</span></th>
													</tr>
													<cfloop from="1" to="6" index="i">
														<div id="#i#">
														<tr id="d_locality_attribute_type_#i#">
															<td>
																<select name="locality_attribute_type_#i#" id="locality_attribute_type_#i#" size="1" onchange="populateGeology(this.id);">
																	<option value=""></option>
																	<cfloop query="ctlocality_attribute_type">
																		<option value="#attribute_type#">#attribute_type#</option>
																	</cfloop>
																</select>
															</td>
															<td id='loc_val_cell_#i#'>
																<!---- initialize this as text; switch to select later --->
																<input type="text" name="locality_attribute_value_#i#" id="locality_attribute_value_#i#">
															</td>
															<td id='loc_unit_cell_#i#'>
																<!---- initialize this as text; switch to select later --->
																<input type="text" name="locality_attribute_units_#i#" id="locality_attribute_units_#i#">
															</td>
															<td>
																<input type="text"
																	name="locality_attribute_determiner_#i#"
																	id="locality_attribute_determiner_#i#"
																	onchange="getAgent('nothing',this.id,'dataEntry',this.value);"
																	onkeypress="return noenter(event);">
															</td>
															<td>
																<input type="text"
																	name="locality_attribute_detr_date_#i#"
																	id="locality_attribute_detr_date_#i#"
																	size="10">
															</td>
															<td>
																<input type="text"
																	name="locality_attribute_detr_meth_#i#"
																	id="locality_attribute_detr_meth_#i#"
																	size="15">
															</td>
															<td>
																<input type="text"
																	name="locality_attribute_remark_#i#"
																	id="locality_attribute_remark_#i#"
																	size="15">
															</td>
														</tr>
														</div>
													</cfloop>
												</table>
											</td>
										</tr>
									</table>
							</div><!--- end item --->
						</div><!--- end sort_geology --->
						<div class="wrapper" id="sort_parts">
							<div class="item">
								<div class="celltitle">Parts <span class="helpLink" data-helplink="parts">[ documentation ]</span></div>
								<table cellpadding="0" cellspacing="0" class="fs">
									<tr>
										<th><span class="f11a">Part Name</span></th>
										<th><span class="f11a">Condition</span></th>
										<th><span class="f11a">Disposition</span></th>
										<th><span class="f11a">Preservation</span></th>
										<th><span class="f11a">##</span></th>
										<th><span class="f11a">Barcode</span></th>
										<th><span class="f11a">Remark</span></th>
									</tr>
									<cfloop from="1" to="12" index="i">
										<tr id="d_part_name_#i#">
											<td>
												<input type="text" name="part_name_#i#" id="part_name_#i#"
													 size="20" onchange="DEpartLookup(this.id);requirePartAtts('#i#',this.value);"
													onkeypress="return noenter(event);">
											</td>
											<td>
												<textarea class="smalltextarea" name="part_condition_#i#" id="part_condition_#i#" rows="1" cols="15"></textarea>
											<!----
												<input type="text" name="part_condition_#i#" id="part_condition_#i#">---->
											</td>
											<td>
												<select id="part_disposition_#i#" name="part_disposition_#i#" style="max-width:80px;">
													<option value=""></option>
													<cfloop query="CTCOLL_OBJ_DISP">
														<option value="#COLL_OBJ_DISPOSITION#">#COLL_OBJ_DISPOSITION#</option>
													</cfloop>
												</select>
											</td>
											<td>
												<select id="part_preservation_#i#" name="part_preservation_#i#" style="max-width:80px;">
													<option value=""></option>
													<cfloop query="CTPART_PRESERVATION">
														<option value="#part_preservation#">#part_preservation#</option>
													</cfloop>
												</select>
											</td>
											<td>
												<input type="text" name="part_lot_count_#i#" id="part_lot_count_#i#" size="1">
											</td>
											<td>
												<input type="text" name="part_barcode_#i#" id="part_barcode_#i#"
													 size="15" onchange="setPartLabel(this.id);">
											</td>
											<td>
												<textarea class="smalltextarea" name="part_remark_#i#" id="part_remark_#i#" rows="1" cols="20"></textarea>
											</td>
										</tr>
									</cfloop>
								</table>
							</div><!--- end item --->
						</div><!--- end sort_parts --->
				    </div><!-- end right-col -->
				</div><!---- end bodywrapperthingee ---->

			<table cellpadding="0" cellspacing="0" width="100%" style="background-color:##339999">
				<tr>
					<td width="15%">
						<span id="theNewButton" style="display:none;">
							<input type="button" value="Save This As A New Record" class="insBtn" onclick="saveNewRecord();"/>
						 </span>
					</td>
					<td width="15%">
						<span id="enterMode" style="display:none">
							<input type="button"
								value="Edit Your Last Record"
								class="lnkBtn"
								onclick="editLast()">
						</span>
						<span id="editMode" style="display:none">
							<input type="button" value="Clone This Record" class="lnkBtn" onclick="createClone()">
						</span>
					</td>
					<td width="15%" nowrap="nowrap">
						 <span id="theSaveButton" style="display:none;">
							<input type="button" value="Save Edits" class="savBtn" onclick="saveEditedRecord();" />
							<input type="button" value="Delete Record" class="delBtn" onclick="deleteThisRec();" />
						</span>
					</td>
					<td width="29%">
						<a href="/Bulkloader/browseBulk.cfm?enteredby=#session.username#">[ table ]</a>
						<a href="/Bulkloader/browseBulk.cfm?enteredby=#session.username#&action=sqlTab">[ SQL ]</a>
						<!----
						<a href="/Bulkloader/browseBulk.cfm?enteredby=#session.username#&action=viewTable">[ Java ]</a>
						---->
						<a href="/Bulkloader/browseBulk.cfm?enteredby=#session.username#&action=download">[ download ]</a>
						<select id="more" name="more" onchange="addMoreStuff(this.value);">
							<option value="">Add more...</option>
							<option value="help">About</option>
							<option value="seeWhatsThere">Check Existing</option>
							<option value="addSE">Add Specimen Event</option>
							<option value="addPart">Add Specimen Part</option>
							<option value="addIdReln">Add ID/Relationship</option>
							<option value="addAttribute">Add Specimen Attribute</option>
							<option value="addCollector">Add Collector</option>
							<option value="addIdentification">Add Identification</option>
						</select>
					</td>
					<td align="right" width="15%" nowrap="nowrap">
						<span id="recCount">#whatIds.recordcount#</span> records <cfif whatIds.recordcount is 1000>(limit)</cfif>
							<span id="browseThingy">
								 - Jump to
								<!----
								<span class="infoLink" id="pBrowse" onclick="browseTo('previous')">[ previous ]</span>
								---->
								<select name="browseRecs" size="1" id="selectbrowse" onchange="loadRecordEdit(this.value);">
									<cfloop query="whatIds">
										<option <cfif collection_object_id is whatIds.collection_object_id> selected="selected" </cfif>
											value="#collection_object_id#">#collection_object_id#</option>
									</cfloop>
								</select>
								<!----
								<span id="nBrowse" class="infoLink" onclick="browseTo('next')">[ next ]</span>
								---->
							</span>
						</span>
					</td>
				</tr>
			</table>
</form>
<script language="javascript" type="text/javascript">
	// fire this off here at init page load
	loadRecord('#collection_object_id#');
</script>
</cfoutput>
</cfif>
<cfinclude template="/includes/_footer.cfm">
