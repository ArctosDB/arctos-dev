<cfinclude template="/includes/_header.cfm">
<cfset title="Bulkloader Stage Cleanup" />
<a href="BulkloaderStageCleanup.cfm">[ cleanup home ]</a>
<script>
	function getDistinct(col){
			$('#distHere').append('<img src="/images/indicator.gif">');
			var ptl="/ajax/bulk_stage_distinct.cfm?col=" + col;
			jQuery.get(ptl, function(data){ jQuery('#distHere').html(data); })

			$('#distnavdiv').html('<a href="#' + col + '">return to ' + col + '</a>');


			$('html, body').animate({
        		scrollTop: parseInt($("#distHere").offset().top)
    		}, 500);

		 }
		 function appendToSQL(l) {
		 	$("#s").append (' ' + l);
		 }
		 function showExample(i) {
		 	switch(i){
	        	case 1:
	           	 $("#s").val("enteredby='billybob'");
	            break;
	        case 2:
	            $("#s").val("enteredby='billybob',\naccn='blah'");
	            break;
	        case 3:
	            $("#s").val("enteredby='billybob',\naccn='blah'\nattribute_determiner_1=collector_agent_1");
	            break;
	         case 4:
	            $("#s").val("enteredby='billybob',\naccn='blah',\nattribute_determiner_1=collector_agent_1\nWHERE\ntaxon_name LIKE 'Sorex %'");
	            break;
  		  }
		 }
</script>
<cfif action is "ajaxGrid">
	<p>
		To delete a record, enter DELETE in status, tab out. Reload to refresh the view.
	</p>
	<link rel="stylesheet" type="text/css" href="/includes/DataTablesnojq/datatables.min.css"/>
	<script type="text/javascript" src="/includes/DataTablesnojq/datatables.min.js"></script>
	<cfoutput>
		<cfset reqdFlds="key,status,enteredby">
		<cfquery name="usrPrefs" datasource="uam_god">
			select unnest(usr_fields) as colname from cf_de_approve_settings where username='#session.username#'
		</cfquery>
		<cfif usrPrefs.recordcount gt 0>
			<cfset usrColumnList=reqdFlds>
			<cfset usrColumnList=listappend(usrColumnList,valuelist(usrPrefs.colname))>
			<div class="importantNotification">
				Table customization detected! This can be dangerous. <a href="browseBulk.cfm?action=customize">customize</a>
			</div>
		<cfelse>
			<cfquery name="cNames" datasource="uam_god">
				select column_name from information_schema.columns where table_name='bulkloader' and
					column_name not in  (<cfqueryparam cfsqltype="cf_sql_varchar" value="#reqdFlds#" list="true">)
			</cfquery>
			<cfset usrColumnList=reqdFlds>
			<cfset usrColumnList=listappend(usrColumnList,valuelist(cNames.column_name))>
		</cfif>
		<script>
			$(document).ready(function() {
				editor = new $.fn.dataTable.Editor( {
				 	ajax:   '/component/Bulkloader.cfc?method=stage_saveDTableEdit',
	    		    table: "##bedit",
			        idSrc: 'key',
	 				formOptions: {
			            inline: {
	        	        onBlur: 'submit'
	            	}
		        },
	    	    fields: [
					<cfloop list="#usrColumnList#" index="col">
						<cfif col is "enteredby" or col is "guid_prefix"  or col is "entered_t_obulk_date">
							{ label: "#col#" ,name: "#col#",type:'readonly', attr:{ disabled:true } }
						<cfelse>
							{ label: "#col#" ,name: "#col#" }
						</cfif>
						<cfif not listlast(usrColumnList) is col>,</cfif>
					</cfloop>
				     ]
		   		});

				var oTable = $('##bedit').DataTable( {
	        		"processing": true,
			        "serverSide": true,
	        		"searching": false,
			        keys: {
	        		    columns: ':not(:first-child)',
				          //  keys: [ 9 ],
	            		editor: editor,
			            editOnFocus: true
	        		},
			        "ajax": {
	        		    "url": "/component/Bulkloader.cfc?method=stage_getDTRecords",
			            "type": "POST",
	        		    "data": function ( d ) {
						}
	       		 	},
			        columns: [
						<cfloop list="#usrColumnList#" index="col">
							{ data: "#col#" }
							<cfif not listlast(usrColumnList) is col>,</cfif>
						</cfloop>
				    ],
				});

				editor.on( 'preSubmit', function ( e, data, action ) {
					$.each( data.data, function ( key, values ) {
						for (var xxx in values) {
					    	var fld=xxx;
					    	var fldval=values[xxx];
						}
						data.key = key;
					    data.fld = fld;
					    data.fldval = fldval;
					});
				});

				$("##goFilter").click(function() {
				   $('##bedit').DataTable().ajax.reload();
				});

				$('##bedit').css( 'display', 'table' );

				oTable.responsive.recalc();
			});
		</script>
		<table id="bedit" class="display compact nowrap stripe" style="width:100%">
			<thead>
				<tr><cfloop list="#usrColumnList#" index="col"><th>#col#</th></cfloop></tr>
			</thead>
			<tbody></tbody>
			<tfoot>
				<tr><cfloop list="#usrColumnList#" index="col"><th>#col#</th></cfloop></tr>
			</tfoot>
		</table>
	</cfoutput>
</cfif>
	<!--------------------------------------------------------------------------------->
	<cfif action is "runSQL">
		<cfoutput>
			<cfset sql="update bulkloader_stage set collection_object_id=collection_object_id,#s#" />
			<cfquery name="update" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				#preservesinglequotes(sql)#
			</cfquery>
			<cfdump var=#sql# />
			<hr>
			done -
			<a href="BulkloaderStageCleanup.cfm?action=sql">back to sql</a>
		</cfoutput>
	</cfif>
	<!--------------------------------------------------------------------------------->
	<cfif action is "sql">
		<cfoutput>
			<table width="100%">
				<tr>
					<td valign="top">
						<div id="distHere" style="border:2px solid red;">results of "show distinct" go here</div>
						<div id="distnavdiv"></div>

						Write your own SQL.
						<br>
						Whatever you enter in the box will be appended to "update bulkloader_stage set "
						<br>
						This isn't a great place to learn SQL - make sure you know what you're doing!
						<br>
						Examples: update.....
						<ul>
							<li>
								<span class="likeLink" onclick="showExample(1)">
									<strong>enteredby</strong>
									to "billybob"
								</span>
							</li>
							<li>
								<span class="likeLink" onclick="showExample(2)">
									<strong>enteredby</strong>
									to "billybob";
									<strong>accn</strong>
									to "blah"
								</span>
							</li>
							<li>
								<span class="likeLink" onclick="showExample(3)">
									<strong>enteredby</strong>
									to "billybob,"
									<strong>accn</strong>
									to "blah," and
									<strong>attribute_determined_1</strong>
									to
									<em>collector_agent_1</em>
								</span>
							</li>
							<li>
								<span class="likeLink" onclick="showExample(4)">
									<strong>enteredby</strong>
									to "billybob,"
									<strong>accn</strong>
									to "blah," and
									<strong>attribute_determined_1</strong>
									to
									<em>collector_agent_1</em>
									where
									<strong>taxon_name</strong>
									starts with "Sorex "
								</span>
							</li>
						</ul>
						<form name="x" method="post" action="BulkloaderStageCleanup.cfm">
							<input type="hidden" name="action" value="runSQL">
							<label for="s">SQL: UPDATE bulkloader_stage SET ....</label>
							<textarea name="s" id="s" rows="20" cols="90"></textarea>
							<br>
							<input type="submit" value="run SQL">
						</form>
					</td>
					<td valign="top">
						<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
							select * from bulkloader_stage where 1=2
						</cfquery>
						<div style="max-height:600px;overflow:auto;">
							<cfloop list="#d.columnList#" index="l">
								<br>
								#l#
								<span class="infoLink" onclick="getDistinct('#l#')">distinct</span>
							</cfloop>
						</div>
					</td>
				</tr>
			</table>
		</cfoutput>
	</cfif>
	<!--------------------------------------------------------------------------------->
	<cfif action is "distinctValues">
		<cfoutput>
			<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select * from bulkloader_stage
			</cfquery>
			<table border>
				<tr>
					<th>Column Name</th>
					<th>Distinct Values</th>
				</tr>
				<cfset theCols=d.columnList>
				<cfif listFindNoCase(theCols,'key')>
					<cfset theCols=listdeleteat(theCols,listFindNoCase(theCols,'key'))>
				</cfif>
				<cfif listFindNoCase(theCols,'ENTERED_TO_BULK_DATE')>
					<cfset theCols=listdeleteat(theCols,listFindNoCase(theCols,'ENTERED_TO_BULK_DATE'))>
				</cfif>
				<cfloop list="#theCols#" index="colname">
					<tr>
						<td>#colname#</td>
						<cfquery name="thisDistinct" dbtype="query">
							select #colname# cval from d group by #colname# order by #colname#
						</cfquery>
						<td>
							<cfloop query="thisDistinct"><br>
								#cval#</cfloop>
						</td>
					</tr>
				</cfloop>
			</table>
		</cfoutput>
	</cfif>
	<!--------------------------------------------------------------------------------->
	<cfif action is "runUpdate">
		<cfoutput>
			<cfset sql="update bulkloader_stage set collection_object_id=collection_object_id" />
			<cfloop list="#form.fieldnames#" index="f">
				<cfif f is not "ACTION">
					<cfset thisValue=evaluate(f) />
					<cfif len(thisValue) gt 0>
						<cfset sql=sql&",#f#='#thisValue#'" />
					</cfif>
				</cfif>
			</cfloop>
			<cfset sql=replace(sql,"'{","","all")>
			<cfset sql=replace(sql,"}'","","all")>

				<cfdump var=#sql# />

			<cfquery name="update" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				#preservesinglequotes(sql)#
			</cfquery>
			<hr>
			done -
			<a href="BulkloaderStageCleanup.cfm?action=updateCommonDefaults">back to update defaults</a>
		</cfoutput>
	</cfif>
	<!--------------------------------------------------------------------------------->
	<cfif action is "updateCommonDefaults">

		<div class="importantNotification">
			File an issue if you'd like to use this.
			<cfabort>
		</div>


		<cfoutput>
			<cfquery name="ctLAT_LONG_UNITS" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
				select ORIG_LAT_LONG_UNITS from ctLAT_LONG_UNITS order by orig_lat_long_units
			</cfquery>
			<cfquery name="ctdatum" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
				select datum from ctdatum order by datum
			</cfquery>
			<cfquery name="ctlength_units" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
				select length_units from ctlength_units order by length_units
			</cfquery>
			<cfquery name="ctverificationstatus" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
				select verificationstatus from ctverificationstatus order by verificationstatus
			</cfquery>
			<cfquery name="ctCOLLECTION_CDE" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
				select COLLECTION_CDE from COLLECTION group by COLLECTION_CDE order by COLLECTION_CDE
			</cfquery>
			<cfquery name="ctinstitution_acronym" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
				select institution_acronym from COLLECTION group by institution_acronym order by institution_acronym
			</cfquery>
			<cfquery name="ctdisposition" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
				select disposition from ctdisposition order by disposition
			</cfquery>
			<cfquery name="ctcollecting_source" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
				select collecting_source from ctcollecting_source order by collecting_source
			</cfquery>
			<cfquery name="ctspecimen_event_type" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
				select specimen_event_type from ctspecimen_event_type order by specimen_event_type
			</cfquery>
			<cfquery name="ctcollector_role" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
				select collector_role from ctcollector_role order by collector_role
			</cfquery>

			<hr>
			<br>
			This form will happily replace all your good values with garbage. There is no finesse. (Load to bulkloader and use SQL browse/edit option.) Reload your text file and start over if you muck it up.
			<div id="distHere" style="border:2px solid red">results of "show distinct" go here</div>
			<div id="distnavdiv"></div>

			<form name="x" method="post" action="BulkloaderStageCleanup.cfm">
				<input type="hidden" name="action" value="runUpdate">
				<table border>
					<tr>
						<th>ColumnName</th>
						<th>UpdateTo (leave blank to ignore)</th>
					</tr>
					<tr>
						<td>
							ENTEREDBY
							<span class="likeLink" onclick="getDistinct('ENTEREDBY')">[ Show Distinct ]</span>
						</td>
						<td>
							<select name="ENTEREDBY" id="ENTEREDBY">
								<option value=""></option>
								<option value="#session.username#">#session.username#</option>
							</select>
						</td>
					</tr>
					<tr>
						<td>
							ID_MADE_BY_AGENT
							<span class="likeLink" onclick="getDistinct('ID_MADE_BY_AGENT')">[ Show Distinct ]</span>
						</td>
						<td>
							<select name="ID_MADE_BY_AGENT" id="ID_MADE_BY_AGENT">
								<option value=""></option>
								<option value="{collector_agent_1}">{collector_agent_1}</option>
							</select>
						</td>
					</tr>
					<tr>
						<td>MADE_DATE</td>
						<td>
							<select name="MADE_DATE" id="MADE_DATE">
								<option value=""></option>
								<option value="{began_date}">{began_date}</option>
							</select>
						</td>
					</tr>
					<tr>
						<td>BEGAN_DATE</td>
						<td>
							<select name="BEGAN_DATE" id="BEGAN_DATE">
								<option value=""></option>
								<!----
								<option value="{verbatim_date}">{verbatim_date}</option>
								---->
							</select>
						</td>
					</tr>
					<tr>
						<td>ENDED_DATE</td>
						<td>
							<select name="ENDED_DATE" id="ENDED_DATE">
								<option value=""></option><!----
									<option value="{verbatim_date}">{verbatim_date}</option>
									---->
							</select>
						</td>
					</tr>
					<tr>
						<td>VERBATIM_LOCALITY</td>
						<td>
							<select name="VERBATIM_LOCALITY" id="VERBATIM_LOCALITY">
								<option value=""></option>
								<option value="{spec_locality}">{spec_locality}</option>
							</select>
						</td>
					</tr>
					<tr>
						<td>
							ORIG_LAT_LONG_UNITS
							<span class="likeLink" onclick="getDistinct('ORIG_LAT_LONG_UNITS')">[ Show Distinct ]</span>
						</td>
						<td>
							<select name="VERBATIM_LOCALITY" id="VERBATIM_LOCALITY">
								<option value=""></option>
								<cfloop query="ctLAT_LONG_UNITS">
									<option value="#ORIG_LAT_LONG_UNITS#">#ORIG_LAT_LONG_UNITS#</option>
								</cfloop>
							</select>
						</td>
					</tr>
					<tr>
						<td>
							DATUM
							<span class="likeLink" onclick="getDistinct('DATUM')">[ Show Distinct ]</span>
						</td>
						<td>
							<select name="VERBATIM_LOCALITY" id="VERBATIM_LOCALITY">
								<option value=""></option>
								<cfloop query="ctdatum"><option value="#datum#">
										#datum#
									</option></cfloop>
							</select>
						</td>
					</tr>
					
					<tr>
						<td>
							MAX_ERROR_UNITS
							<span class="likeLink" onclick="getDistinct('MAX_ERROR_UNITS')">[ Show Distinct ]</span>
						</td>
						<td>
							<select name="MAX_ERROR_UNITS" id="MAX_ERROR_UNITS">
								<option value=""></option>
								<cfloop query="ctlength_units">
									<option value="#length_units#">#length_units#</option>
								</cfloop>
							</select>
						</td>
					</tr>
					<tr>
						<td>
							GEOREFERENCE_PROTOCOL
							<span class="likeLink" onclick="getDistinct('GEOREFERENCE_PROTOCOL')">[ Show Distinct ]</span>
						</td>
						<td>
							<select name="GEOREFERENCE_PROTOCOL" id="GEOREFERENCE_PROTOCOL">
								<option value=""></option>
								<cfloop query="ctgeoreference_protocol">
									<option value="#georeference_protocol#">#georeference_protocol#</option>
								</cfloop>
							</select>
						</td>
					</tr>
					<tr>
						<td>EVENT_ASSIGNED_BY_AGENT</td>
						<td>
							<select name="EVENT_ASSIGNED_BY_AGENT" id="EVENT_ASSIGNED_BY_AGENT">
								<option value=""></option>
								<option value="{collector_agent_1}">{collector_agent_1}</option>
							</select>
						</td>
					</tr>
					<tr>
						<td>
							EVENT_ASSIGNED_DATE
							<span class="likeLink" onclick="getDistinct('EVENT_ASSIGNED_DATE')">[ Show Distinct ]</span>
						</td>
						<td>
							<select name="EVENT_ASSIGNED_DATE" id="EVENT_ASSIGNED_DATE">
								<option value=""></option>
								<option value="verbatim_date">{verbatim_date}</option>
							</select>
						</td>
					</tr>
					<tr>
						<td>
							VERIFICATIONSTATUS
							<span class="likeLink" onclick="getDistinct('VERIFICATIONSTATUS')">[ Show Distinct ]</span>
						</td>
						<td>
							<select name="VERIFICATIONSTATUS" id="VERIFICATIONSTATUS">
								<option value=""></option>
								<cfloop query="ctverificationstatus">
									<option value="#verificationstatus#">#verificationstatus#</option>
								</cfloop>
							</select>
						</td>
					</tr>
					<cfloop from="1" to="8" index="x">
						<tr>
							<td>
								COLLECTOR_ROLE_#x#
								<span class="likeLink" onclick="getDistinct('COLLECTOR_ROLE_#x#')">[ Show Distinct ]</span>
							</td>
							<td>
								<select name="COLLECTOR_ROLE_#x#" id="COLLECTOR_ROLE_#x#">
									<option value=""></option>
									<cfloop query="ctcollector_role">
										<option value="#collector_role#">#collector_role#</option>
									</cfloop>
								</select>
							</td>
						</tr>
					</cfloop>
					
					<cfloop from="1" to="12" index="x">
						<tr>
							<td>
								PART_CONDITION_#x#
								<span class="likeLink" onclick="getDistinct('PART_CONDITION_#x#')">[ Show Distinct ]</span>
							</td>
							<td>
								<select name="PART_CONDITION_#x#" id="PART_CONDITION_#x#">
									<option value=""></option>
									<option value="unchecked">unchecked</option>
								</select>
							</td>
						</tr>
						<tr>
							<td>
								PART_LOT_COUNT_#x#
								<span class="likeLink" onclick="getDistinct('PART_LOT_COUNT_#x#')">[ Show Distinct ]</span>
							</td>
							<td>
								<select name="PART_LOT_COUNT_#x#" id="PART_LOT_COUNT_#x#">
									<option value=""></option>
									<option value="1">1</option>
								</select>
							</td>
						</tr>
						<tr>
							<td>
								PART_DISPOSITION_#x#
								<span class="likeLink" onclick="getDistinct('PART_DISPOSITION_#x#')">[ Show Distinct ]</span>
							</td>
							<td>
								<select name="PART_DISPOSITION_#x#" id="PART_DISPOSITION_#x#">
									<option value=""></option>
									<cfloop query="ctdisposition">
										<option value="#disposition#">#disposition#</option>
									</cfloop>
								</select>
							</td>
						</tr>
					</cfloop>
					<cfloop from="1" to="10" index="x">
						<tr>
							<td>
								ATTRIBUTE_DATE_#x#
								<span class="likeLink" onclick="getDistinct('ATTRIBUTE_DATE_#x#')">[ Show Distinct ]</span>
							</td>
							<td>
								<select name="ATTRIBUTE_DATE_#x#" id="ATTRIBUTE_DATE_#x#">
									<option value=""></option>
									<option value="{began_date}">{began_date}</option>
								</select>
							</td>
						</tr>
						<tr>
							<td>
								ATTRIBUTE_DETERMINER_#x#
								<span class="likeLink" onclick="getDistinct('ATTRIBUTE_DETERMINER_#x#')">[ Show Distinct ]</span>
							</td>
							<td>
								<select name="ATTRIBUTE_DETERMINER_#x#" id="ATTRIBUTE_DETERMINER_#x#">
									<option value=""></option>
									<option value="{collector_agent_1}">{collector_agent_1}</option>
								</select>
							</td>
						</tr>
					</cfloop>
					<tr>
						<td>
							COLLECTING_SOURCE
							<span class="likeLink" onclick="getDistinct('COLLECTING_SOURCE')">[ Show Distinct ]</span>
						</td>
						<td>
							<select name="COLLECTING_SOURCE" id="COLLECTING_SOURCE">
								<option value=""></option>
								<cfloop query="ctcollecting_source">
									<option value="#collecting_source#">#collecting_source#</option>
								</cfloop>
							</select>
						</td>
					</tr>
					<tr>
						<td>
							SPECIMEN_EVENT_TYPE
							<span class="likeLink" onclick="getDistinct('SPECIMEN_EVENT_TYPE')">[ Show Distinct ]</span>
						</td>
						<td>
							<select name="SPECIMEN_EVENT_TYPE" id="SPECIMEN_EVENT_TYPE">
								<option value=""></option>
								<cfloop query="ctspecimen_event_type">
									<option value="#specimen_event_type#">#specimen_event_type#</option>
								</cfloop>
							</select>
						</td>
					</tr>
				</table>
				<input type="submit" value="update everything">
			</form>
		</cfoutput>
	</cfif>
	<cfif action is "spaceStripper">
		<cfquery datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select bulk_stage_junkstripper()
		</cfquery>
		<a href="BulkloaderStageCleanup.cfm">Done - continue</a>
	</cfif>
	<cfif action is "nothing">
		<cfoutput>
			<p>
				This form can be useful for cleanup of minor errors. Note that this is still part of the single-user form; usage should be timely.
			</p>
			<p>
				<a href="/Admin/CSVAnyTable.cfm?tableName=bulkloader_stage">Download</a> data with errors
			</p>

			<p>
				This form will very happily mess up all of your data. Make sure you have backups, and check the results of your actions often and carefully.
			</p>
			<ul>
				<li>
					<a href="BulkloaderStageCleanup.cfm?action=ajaxGrid">Edit in grid</a> provides a tabular editable view of the data in bulkloader stage.
				</li>
				<li>
					<a href="BulkloaderStageCleanup.cfm?action=spaceStripper">strip junk</a> trims and removes all "junk" (mostly non-printing) characters from all text fields.
				</li>
				<li>
					<a href="BulkloadSpecimens.cfm?action=checkStaged">Check these records</a> runs the pre-check scripts on all records.
				</li>
				<li>
					<a href="BulkloadSpecimens.cfm?action=validate">Return to "just uploaded" form</a>
				</li>
			</ul>

			All of the following options may eat your browser on large datasets. Use with caution.
			<ul>
				<li>
					<a href="BulkloaderStageCleanup.cfm?action=distinctValues">Show distinct values</a> provides a list of unique values in every field.
				</li>
				<li>
					<a href="BulkloaderStageCleanup.cfm?action=updateCommonDefaults">Update Common Defaults</a><!--- provides an easy mechanism to update all records. This is
					generally useful for some flavor of "unknown" on required fields.
					----->
				</li>
				<li>
					<a href="BulkloaderStageCleanup.cfm?action=sql">Write SQL</a> provides direct access to the table.
				</li>
			</ul>
		</cfoutput>
	</cfif>
	<cfinclude template="/includes/_footer.cfm">
