<cfinclude template="/includes/_includeHeader.cfm">

<script type='text/javascript' src='/includes/_editIdentification.js?v=1'></script>
<style>
	.fordelete {
		background-color: red;
	}
</style>
<script language="javascript" type="text/javascript">
	jQuery(document).ready(function() {
		confineToIframe();
		$(".reqdClr:visible").each(function(e){
		    $(this).prop('required',true);
		});
		$("input[type='date'], input[type='datetime']" ).datepicker();
		//$("#made_date").datepicker();
		//$("input[id^='made_date_']").each(function(){
			//$("#" + this.id).datepicker();
		//});
	});
	function citDel(cid){
		if ($("#type_status_" + cid).val()=='DELETE') {
			$("#tr_" + cid).removeClass().addClass('fordelete');
			alert('CAUTION: Deleting citation!');
		} else {
			$("#tr_" + cid).removeClass();
		}
	}
</script>
<!----------------------------------------------------------------------------------->
<cfif action is "nothing">
<cfoutput>
<cfquery name="ctnature" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select nature_of_id from ctnature_of_id order by nature_of_id
</cfquery>
<cfquery name="ctFormula" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select taxa_formula from cttaxa_formula order by taxa_formula
</cfquery>
<cfquery name="ctTypeStatus" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select type_status from ctcitation_type_status order by type_status
</cfquery>
<cfquery name="ctidentification_confidence" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select identification_confidence from ctidentification_confidence order by identification_confidence
</cfquery>
<cfquery name="getID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
	SELECT
		identification.identification_id,
		identification.scientific_name,
		identification.identification_confidence,
		identification.taxon_concept_id,
		cataloged_item.cat_num,
		preferred_agent_name.agent_name,
		identification_agent.identifier_order,
		identification_agent.agent_id,
		identification.made_date,
		identification.nature_of_id,
		identification.accepted_id_fg,
		identification.identification_remarks,
		identification_agent.identification_agent_id,
		publication.short_citation,
		identification.publication_id,
		identification.taxa_formula,
		taxon_name.scientific_name taxon_name,
		taxon_name.taxon_name_id,
		citation.OCCURS_PAGE_NUMBER,
		citation.TYPE_STATUS,
		citation.CITATION_REMARKS,
		citation.CITATION_ID,
		citpub.SHORT_CITATION cit_short_cit,
		citpub.DOI cit_doi,
		citpub.publication_id citpubid,
		taxon_concept.concept_label
	FROM
		cataloged_item
		inner join identification on cataloged_item.collection_object_id=identification.collection_object_id
		inner join collection on cataloged_item.collection_id=collection.collection_id
		left outer join identification_agent on identification.identification_id = identification_agent.identification_id
		left outer join preferred_agent_name on identification_agent.agent_id = preferred_agent_name.agent_id
		left outer join publication on identification.publication_id=publication.publication_id
		left outer join identification_taxonomy on identification.identification_id = identification_taxonomy.identification_id
		left outer join taxon_name on identification_taxonomy.taxon_name_id=taxon_name.taxon_name_id
		left outer join citation on identification.identification_id = citation.identification_id
		left outer join publication citpub on citation.publication_id=citpub.publication_id
		left outer join taxon_concept on identification.taxon_concept_id=taxon_concept.taxon_concept_id
	WHERE
		cataloged_item.collection_object_id = #collection_object_id#
		ORDER BY accepted_id_fg
	DESC
</cfquery>
<form name="newID" id="newID" method="post" action="editIdentification.cfm">
<table class="newRec">
 <tr>
 	<td colspan="2">
		<h3>
			Add Determination
			<span class="helpLink" data-helplink="identification">Documentation</span>
		</h3>
	</td>
 </tr>
    <input type="hidden" name="Action" value="createNew">
    <input type="hidden" name="collection_object_id" value="#collection_object_id#" >
    <tr>
		<td>
			<div class="helpLink" id="taxa_formula">ID Formula:</div>
		</td>
		<td>
			<cfif not isdefined("taxa_formula")>
				<cfset taxa_formula='A'>
			</cfif>
			<cfset thisForm = "#taxa_formula#">
			<select name="taxa_formula" id="taxa_formula" size="1" class="reqdClr"
				onchange="newIdFormula(this.value);">
					<cfloop query="ctFormula">
						<option
							<cfif #thisForm# is "#ctFormula.taxa_formula#"> selected </cfif>value="#ctFormula.taxa_formula#">#taxa_formula#</option>
					</cfloop>
			</select>
		</td>
	</tr>
	<tr>
    	<td>
			<div class="helpLink" id="scientific_name">Taxon A:</div>
		</td>
         <td>
		  	<input type="text" name="taxona" id="taxona" class="reqdClr" size="50"
				onChange="taxaPick('taxona_id','taxona','newID',this.value); return false;"
				onKeyPress="return noenter(event);" placeholder="pick a taxon name">
			<input type="hidden" name="taxona_id" id="taxona_id" class="reqdClr">
		</td>
  	</tr>
	<tr id="userID" style="display:none;">
    	<td>
			<div class="helpLink" id="user_identification">Identification:</div>
		</td>
         <td>
		  	<input type="text" name="user_id" id="user_id" size="50" placeholder="type the identification string">
		</td>
  	</tr>
	<tr id="taxon_b_row" style="display:none;">
    	<td>
			<div align="right">Taxon B:</div>
		</td>
        <td>
			<input type="text" name="taxonb" id="taxonb"  size="50"
				onChange="taxaPick('taxonb_id','taxonb','newID',this.value); return false;"
				onKeyPress="return noenter(event);" placeholder="pick a taxon name">
			<input type="hidden" name="taxonb_id" id="taxonb_id">
		</td>
  	</tr>
    <tr>
    	<td>
			<div class="helpLink" id="id_by">ID By:</div>
		</td>
        <td>
			<input type="text" name="newIdBy" id="newIdBy" class="reqdClr" size="50"
				onchange="pickAgentModal('newIdBy_id',this.id,this.value);"
				placeholder="type+tab to pick Identifier (Agent)">
            <input type="hidden" name="newIdBy_id" id="newIdBy_id" class="reqdClr">
			<span class="infoLink" onclick="addNewIdBy('two');">more...</span>
		</td>
	</tr>
	<tr id="addNewIdBy_two" style="display:none;">
    	<td>
			<div align="right">
				ID By:<span class="infoLink" onclick="clearNewIdBy('two');"> remove</span>
			</div>
		</td>
        <td>
			<input type="text" name="newIdBy_two" id="newIdBy_two" size="50"
				onchange="pickAgentModal('newIdBy_two_id',this.id,this.value);"
				placeholder="type+tab to pick Identifier (Agent)">
            <input type="hidden" name="newIdBy_two_id" id="newIdBy_two_id">
			<span class="infoLink" onclick="addNewIdBy('three');">more...</span>
		 </td>
	</tr>
    <tr id="addNewIdBy_three" style="display:none;">
    	<td>
			<div align="right">
				ID By:<span class="infoLink" onclick="clearNewIdBy('three');"> remove</span>
			</div>
		</td>
        <td>
			<input type="text" name="newIdBy_three" id="newIdBy_three" size="50"
				onchange="pickAgentModal('newIdBy_three_id',this.id,this.value);"
				placeholder="type+tab to pick Identifier (Agent)">
            <input type="hidden" name="newIdBy_three_id" id="newIdBy_three_id">
		 </td>
    </tr>
    <tr>
    	<td>
			<div class="helpLink" id="identification.made_date">ID Date:</div>
		</td>
        <td>
			<input type="datetime" class="siput" name="made_date" id="made_date" placeholder="click to pick ID Date">
		</td>
	</tr>
    <tr>
    	<td>
			<div class="helpLink" id="nature_of_id">Nature of ID</div>
		</td>
		<td>
			<select name="nature_of_id" id="nature_of_id" size="1" class="reqdClr" placeholder="NoID">
				<option></option>
            	<cfloop query="ctnature">
                	<option  value="#ctnature.nature_of_id#">#ctnature.nature_of_id#</option>
                </cfloop>
            </select>
			<span class="infoLink" onClick="getCtDoc('ctnature_of_id',newID.nature_of_id.value)">Define</span>
		</td>
	</tr>
    <tr>
    	<td>
			<div class="helpLink" id="_identification_confidence">Confidence</div>
		</td>
		<td>
			<select name="identification_confidence" id="identification_confidence" size="1">
				<option></option>
            	<cfloop query="ctidentification_confidence">
                	<option  value="#ctidentification_confidence.identification_confidence#">#ctidentification_confidence.identification_confidence#</option>
                </cfloop>
            </select>
			<span class="infoLink" onClick="getCtDoc('ctidentification_confidence',newID.identification_confidence.value)">Define</span>
		</td>
	</tr>
    <tr>
    	<td>
			<div class="helpLink" id="identification_publication">Sensu:</div>
		</td>
		<td>
			<input type="hidden" name="new_publication_id" id="new_publication_id">
			<input type="text" id="newPub" onchange="getPublication(this.id,'new_publication_id',this.value,'newID')" size="50"
				placeholder="Type+tab to pick publication">
		</td>
	</tr>

	<tr>
    	<td>
			<div class="helpLink" id="taxon_concept">Taxon Concept:</div>
		</td>
		<td>
			<input type="hidden" name="new_concept_id" id="new_concept_id">
			<input type="text" id="new_concept" value='' onchange="pickTaxonConcept('new_concept_id',this.id,this.value)" size="50"
				placeholder="Type+tab to pick concept">
		</td>
	</tr>


    <tr>
    	<td>
			<div class="helpLink" id="identification_remarks">Remarks:</div>
		</td>
        <td>
			<input type="text" name="identification_remarks" id="identification_remarks" size="50" placeholder="Identification remarks">
		</td>
    </tr>
    <tr>
		<td colspan="2">
			<div align="center">
            	<input type="submit" id="newID_submit" value="Create" class="insBtn reqdClr" title="Create Identification">
             </div>
		</td>
    </tr>
	</table>
</form>

<strong><font size="+1">Edit an Existing Determination</font></strong>
<span class="helpLink" data-helplink="identification">Documentation</span>
<cfset i = 1>
<cfquery name="distIds" dbtype="query">
	SELECT
		identification_id,
		scientific_name,
		cat_num,
		made_date,
		nature_of_id,
		accepted_id_fg,
		identification_remarks,
		short_citation,
		publication_id,
		taxa_formula,
		identification_confidence,
		taxon_concept_id,
		concept_label
	FROM
		getID
	GROUP BY
		identification_id,
		scientific_name,
		cat_num,
		made_date,
		nature_of_id,
		accepted_id_fg,
		identification_remarks,
		short_citation,
		publication_id,
		taxa_formula,
		identification_confidence,
		taxon_concept_id,
		concept_label
	ORDER BY
		accepted_id_fg DESC,
		made_date
</cfquery>
<form name="editIdentification" id="editIdentification" method="post" action="editIdentification.cfm">
    <input type="hidden" name="Action" value="saveEdits">
    <input type="hidden" name="collection_object_id" value="#collection_object_id#" >
	<input type="hidden" name="number_of_ids" id="number_of_ids" value="#distIds.recordcount#">
<table border>
<cfloop query="distIds">
	<input type="hidden" name="taxa_formula_#i#" id="taxa_formula_#i#" value="#taxa_formula#">
	<tr #iif(i MOD 2,DE("class='evenRow'"),DE("class='oddRow'"))#><td>
	<cfquery name="identifiers" dbtype="query">
		select
			agent_name,
			identifier_order,
			agent_id,
			identification_agent_id
		FROM
			getID
		WHERE
			identification_id=#identification_id#
		group by
			agent_name,
			identifier_order,
			agent_id,
			identification_agent_id
		ORDER BY
			identifier_order
	</cfquery>
	<cfset thisIdentification_id = #identification_id#>
	<input type="hidden" name="identification_id_#i#" id="identification_id_#i#" value="#identification_id#">
	<input type="hidden" name="number_of_identifiers_#i#" id="number_of_identifiers_#i#" value="#identifiers.recordcount#">
	<table id="mainTable_#i#">
    	<tr>
        	<td class="valigntop">
				<div align="right">Scientific Name:</div>
			</td>
            <td>
				<cfif accepted_id_fg is 1 and taxa_formula is 'A {string}'>
					<cfquery name="taxa" dbtype="query">
						select
							taxon_name,
							taxon_name_id
						from
							getID
						where
							identification_id=#identification_id#
						group by
							taxon_name,
							taxon_name_id
						order by
							taxon_name
					</cfquery>
					<input type="hidden" name="number_of_taxa_#i#" id="number_of_taxa_#i#" value="#taxa.recordcount#">
					<label for="scientific_name_#i#">Identification String (type stuff)</label>
					<input id="scientific_name_#i#" name="scientific_name_#i#" value="#encodeforhtml(scientific_name)#" class="minput reqdClr">
					<br>
					<label for="x">
						Associated Taxa (pick names to link)
						<span class="helpLink" data-helplink="identification_astring">[ help ]</span>
						<span class="likeLink" onclick="addAssTax(#i#)">[ add a row ]</span>
					</label>
					<cfset n=1>
					<div id="tdiv_#i#">
						<cfloop query="taxa">
							<div>
								<input type="text" name="taxon_name_#i#_#n#" id="taxon_name_#i#_#n#" size="50" value="#taxon_name#"
									onChange="taxaPick('taxon_name_id_#i#_#n#',this.id,'editIdentification',this.value); return false;"
									onKeyPress="return noenter(event);" placeholder="pick a taxon name" class="minput reqdClr">

								<img src='/images/del.gif' class="likeLink" onclick="deleteAssTax(#i#,#n#)">
								<input type="hidden" name="taxon_name_id_#i#_#n#" id="taxon_name_id_#i#_#n#" value="#taxon_name_id#">
							</div>
							<cfset n=n+1>
						</cfloop>
					</div>
				<cfelse>
					<b><i>#scientific_name#</i></b>
				</cfif>
			</td>
        </tr>
        <tr>
        	<td colspan="2">
				<table>
					<tr>
						<td><div align="right">Accepted?</div></td>
						<td>
							<cfif accepted_id_fg is 0>
								<select name="accepted_id_fg_#i#"
									id="accepted_id_fg_#i#" size="1"
									class="reqdClr" onchange="flippedAccepted('#i#')">
									<option value="1"
										<cfif ACCEPTED_ID_FG is 1> selected </cfif>>yes</option>
			                    	<option
										<cfif accepted_id_fg is 0> selected </cfif>value="0">no</option>
									<cfif ACCEPTED_ID_FG is 0>
										<option value="DELETE">DELETE</option>
									</cfif>
			                  	</select>
								<cfif ACCEPTED_ID_FG is 0>
									<span class="infoLink red" onclick="document.getElementById('accepted_id_fg_#i#').value='DELETE';flippedAccepted('#i#');">Delete</span>
								</cfif>
							<cfelse>
								<input name="accepted_id_fg_#i#" id="accepted_id_fg_#i#" type="hidden" value="1">
								<b>Yes</b>
							</cfif>

						</td>
						<td>
							<div style="display:block;widtht:10em;"></div>
						</td>
						<td><div align="right">
								Formula:
							</div>
						</td>
						<td>
							#taxa_formula#
							<cfif taxa_formula is "A {string}" and accepted_id_fg is 0>
								<span style="font-size:small">(More informationi is available when identifications are accepted.)</span>
							</cfif>
						</td>
					</tr>
				</table>
			</td>
       	</tr>
        <tr>
			<td colspan="2">
				<table id="identifierTable_#i#">
					<tbody id="identifierTableBody_#i#">
						<cfset idnum=1>
						<cfloop query="identifiers">
							<tr id="IdTr_#i#_#idnum#">
								<td>Identified By:</td>
								<td>
									<input type="text"
										name="IdBy_#i#_#idnum#"
										id="IdBy_#i#_#idnum#"
										value="#encodeforhtml(agent_name)#"
										class="reqdClr"
										size="50"
										onchange="pickAgentModal('IdBy_#i#_#idnum#_id',this.id,this.value);">
									<input type="hidden"
										name="IdBy_#i#_#idnum#_id"
										id="IdBy_#i#_#idnum#_id" value="#agent_id#"
										class="reqdClr">
									<input type="hidden" name="identification_agent_id_#i#_#idnum#" id="identification_agent_id_#i#_#idnum#"
										value="#identification_agent_id#">
									<cfif idnum gt 1>
										<img src="/images/del.gif" class="likeLink"
											onclick="removeIdentifier('#i#','#idnum#')" />
									</cfif>
				 				</td>
				 			</tr>
							<cfset idnum=idnum+1>
						</cfloop>
					</tbody>
				</table>
			</td>
		</tr>
        <tr>
			<td>
				<span class="infoLink" id="addIdentifier_#i#"
					onclick="addIdentifier('#i#','#idnum#')">Add Identifier</span>
			</td>
		</tr>
		<tr>
        	<td>
				<div class="helpLink" id="identification.made_date">ID Date:</div>
			</td>
            <td>
				<input type="datetime" value="#made_date#" name="made_date_#i#" class="sinput" id="made_date_#i#"
					placeholder="date of identification">
           </td>
		</tr>
        <tr>
	        <td>
				<div class="helpLink" id="nature_of_id">Nature of ID:</div>
			</td>
	        <td>
				<cfset thisID = nature_of_id>
				<select name="nature_of_id_#i#" id="nature_of_id_#i#" size="1" class="reqdClr">
	            	<cfloop query="ctnature">
	                	<option <cfif #ctnature.nature_of_id# is #thisID#> selected </cfif> value="#ctnature.nature_of_id#">#ctnature.nature_of_id#</option>
	                </cfloop>
	           	</select>
				<span class="infoLink" onClick="getCtDoc('ctnature_of_id',newID.nature_of_id.value)">Define</span>
			</td>
        </tr>
		  <tr>
    	<td>
			<div class="helpLink" id="_identification_confidence">Confidence</div>
		</td>
		<td>

			<cfset thicConf = identification_confidence>
			<select name="identification_confidence_#i#" id="identification_confidence_#i#" size="1">
				<option></option>
            	<cfloop query="ctidentification_confidence">
                	<option  <cfif #ctidentification_confidence.identification_confidence# is #thicConf#> selected </cfif> value="#ctidentification_confidence.identification_confidence#">#ctidentification_confidence.identification_confidence#</option>
                </cfloop>
            </select>
			<span class="infoLink" onClick="getCtDoc('ctidentification_confidence',newID.identification_confidence.value)">Define</span>
		</td>
	</tr>

        <tr>
	        <td>
				<div class="helpLink" id="identification_publication">Sensu:</div>
			</td>
	        <td>
				<input type="hidden" name="publication_id_#i#" id="publication_id_#i#" value="#publication_id#">
				<input type="text"
					id="publication_#i#"
					value="#short_citation#"
					onchange="getPublication(this.id,'publication_id_#i#',this.value,'editIdentification')" size="50"
					placeholder="Type+tab to pick publication">
				<span class="infoLink" onclick="$('##publication_id_#i#').val('');$('##publication_#i#').val('');">Remove</span>

			</td>
        </tr>

		  <tr>
	        <td>
				<div class="helpLink" id="taxon_concept">Taxon Concept:</div>
			</td>
	        <td>
				<input type="hidden" name="taxon_concept_id_#i#" id="taxon_concept_id_#i#" value="#taxon_concept_id#">
				<input type="text"
					id="taxon_concept_#i#"
					value='#concept_label#'
					onchange="pickTaxonConcept('taxon_concept_id_#i#',this.id,this.value)" size="50"
					placeholder="Type+tab to pick concept">

				<span class="infoLink" onclick="$('##taxon_concept_id_#i#').val('');$('##taxon_concept_#i#').val('');">Remove</span>

			</td>
        </tr>


        <tr>
          	<td><div align="right">Remarks:</div></td>
         	 <td>
				<input type="text" name="identification_remarks_#i#" id="identification_remarks_#i#"
					value="#encodeforhtml(identification_remarks)#" size="50"
					placeholder="identification remarks">
			</td>
        </tr>
		<cfquery name="cit" dbtype="query">
			select
				OCCURS_PAGE_NUMBER,
				TYPE_STATUS,
				CITATION_REMARKS,
				CITATION_ID,
				cit_short_cit,
				cit_doi,
				citpubid,
				SHORT_CITATION
			from
				getID
			where
				identification_id=#identification_id# and
				TYPE_STATUS is not null
			group by
				OCCURS_PAGE_NUMBER,
				TYPE_STATUS,
				CITATION_REMARKS,
				CITATION_ID,
				cit_short_cit,
				cit_doi,
				citpubid,
				SHORT_CITATION
			order by
				SHORT_CITATION
		</cfquery>
		<tr>
          	<td>
				<div class="helpLink" id="citations">Citations:</div>
			</td>
			<td>
				<table border>
					<tr>
						<th>TypeStatus</th>
						<th>Publication</th>
						<th>Pg.</th>
						<th>Remark</th>
					</tr>
					<tr class="newRec">
						<td>
							<input type="hidden"
								id="citation_id_#distIds.identification_id#_NEW"
								name="citation_id_#distIds.identification_id#_NEW">
							<select
								name="type_status_#distIds.identification_id#_NEW"
								id="type_status_#distIds.identification_id#_NEW"
								size="1">
									<option value="">Pick to Create</option>
									<cfloop query="ctTypeStatus">
										<option value="#ctTypeStatus.type_status#">#ctTypeStatus.type_status#</option>
									</cfloop>
							</select>
							<span class="infoLink" onClick="getCtDoc('CTCITATION_TYPE_STATUS')">Define</span>
						</td>
						<td>
							<input type="hidden" name="publication_id_#distIds.identification_id#_NEW"
								id="publication_id_#distIds.identification_id#_NEW">
							<input type="text"
								id="publication_#distIds.identification_id#_NEW"
								placeholder="type+tab to pick publication"
								onchange="getPublication(this.id,'publication_id_#distIds.identification_id#_NEW',this.value)" size="50">
						</td>
						<td>
							<input type="number" name="page_#distIds.identification_id#_NEW" id="page_#distIds.identification_id#_NEW"
								placeholder="page number">
						</td>
						<td>
							<textarea
								name="citation_remark_#distIds.identification_id#_NEW"
								id="citation_remark_#distIds.identification_id#_NEW"
								class="smalltextarea"
								placeholder="citation remarks">
							</textarea>
						</td>
					</tr>
					<cfloop query="cit">
						<tr id="tr_#distIds.identification_id#_#citation_id#">
							<td>
								<input type="hidden" id="citation_id_#distIds.identification_id#_#citation_id#" name="citation_id_#distIds.identification_id#_#citation_id#" value="#citation_id#">
								<select name="type_status_#distIds.identification_id#_#citation_id#" id="type_status_#distIds.identification_id#_#citation_id#" size="1" onchange="citDel('#distIds.identification_id#_#citation_id#');">
									<option style="color:red;" value="DELETE">DELETE THIS CITATION</option>
									<cfloop query="ctTypeStatus">
										<option
											<cfif ctTypeStatus.type_status is cit.type_status> selected </cfif>value="#ctTypeStatus.type_status#">#ctTypeStatus.type_status#</option>
									</cfloop>
								</select>
								<span class="infoLink" onClick="getCtDoc('CTCITATION_TYPE_STATUS')">Define</span>
							</td>
							<td>
								<input type="hidden" name="publication_id_#distIds.identification_id#_#citation_id#" id="publication_id_#distIds.identification_id#_#citation_id#" value="#citpubid#">
								<input type="text"
									id="publication_#distIds.identification_id#_#citation_id#"
									value='#cit_short_cit#'
									onchange="getPublication(this.id,'publication_id_#distIds.identification_id#_#citation_id#',this.value)" size="50">
								<a href="/publication/#citpubid#" class="infoLink" target="_blank">[ open ]</a>
							</td>
							<td>
								<input type="number" name="page_#distIds.identification_id#_#citation_id#" id="page_#distIds.identification_id#_#citation_id#" value="#OCCURS_PAGE_NUMBER#">
							</td>
							<td>
								<textarea name="citation_remark_#distIds.identification_id#_#citation_id#" id="citation_remark_#distIds.identification_id#_#citation_id#" class="smalltextarea">#CITATION_REMARKS#</textarea>
							</td>
						</tr>
					</cfloop>
				</table>
			</td>
		</tr>
	</table>
  <cfset i = i+1>
</td></tr>
</cfloop>
<tr>
	<td>
		<input type="submit" class="savBtn" id="editIdentification_submit" value="Save Changes" title="Save Changes">
	</td>
</tr>
</table>
</form>
</cfoutput>
</cfif>
<!----------------------------------------------------------------------------------->
<cfif action is "saveEdits">
<cfoutput>
	<cftransaction>
		<cfloop from="1" to="#NUMBER_OF_IDS#" index="n">
			<cfset thisAcceptedIdFg = evaluate("ACCEPTED_ID_FG_" & n)>
			<cfset thisTaxaFormula = evaluate("taxa_formula_" & n)>
			<cfset thisIdentificationId = evaluate("IDENTIFICATION_ID_" & n)>
			<cfset thisIdRemark = evaluate("IDENTIFICATION_REMARKS_" & n)>
			<cfset thisMadeDate = evaluate("MADE_DATE_" & n)>
			<cfset thisNature = evaluate("NATURE_OF_ID_" & n)>
			<cfset thisNumIds = evaluate("NUMBER_OF_IDENTIFIERS_" & n)>
			<cfset thisPubId = evaluate("publication_id_" & n)>
			<cfset thisIdConf = evaluate("identification_confidence_" & n)>
			<cfset thisConcId = evaluate("taxon_concept_id_" & n)>


			<!--- citations --->
			<cfloop list="#form.fieldnames#" index="i">
				<cfif
					listlen(i,"_") is 4 and
					listgetat(i,1,"_") is "CITATION" and
					listgetat(i,2,"_") is "ID" and
					listgetat(i,3,"_") is thisIdentificationId>
					<cfset thisCitationID=listlast(i,"_")>
					<cfset thisTypeStatus=evaluate("type_status_" & thisIdentificationId & "_" & thisCitationID)>
					<cfif thisTypeStatus is "DELETE">
						<cfquery name="delCt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
							delete from citation where citation_id=#thisCitationID#
						</cfquery>
					<cfelse>
						<cfset thisPublicationID=evaluate("publication_id_" & thisIdentificationId & "_" & thisCitationID)>
						<cfset thisPage=evaluate("page_" & thisIdentificationId & "_" & thisCitationID)>
						<cfset thisRemark=evaluate("citation_remark_" & thisIdentificationId & "_" & thisCitationID)>
						<cfif thisCitationID is "NEW">
							<!---- only if we got a typestatus ---->
							<cfif len(thisTypeStatus) gt 0>
								<cfquery name="ncit" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
									insert into citation (
										citation_id,
										PUBLICATION_ID,
										OCCURS_PAGE_NUMBER,
										TYPE_STATUS,
										CITATION_REMARKS,
										IDENTIFICATION_ID,
										collection_object_id
									) values (
										nextval('sq_citation_id'),
										<cfqueryparam value = "#thisPublicationID#" CFSQLType="cf_sql_int">,
										<cfqueryparam value = "#thisPage#" CFSQLType="cf_sql_int"  null="#Not Len(Trim(thisPage))#">,
										<cfqueryparam value = "#thisTypeStatus#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisTypeStatus))#">,
										<cfqueryparam value = "#thisRemark#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisRemark))#">,
										<cfqueryparam value = "#thisIdentificationId#" CFSQLType="cf_sql_int">,
										<cfqueryparam value = "#collection_object_id#" CFSQLType="cf_sql_int">
									)
								</cfquery>
							</cfif>
						<cfelse>
							<cfquery name="upcit" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
								update citation set
									PUBLICATION_ID=<cfqueryparam value = "#thisPublicationID#" CFSQLType="cf_sql_int">,
									OCCURS_PAGE_NUMBER=<cfqueryparam value = "#thisPage#" CFSQLType="cf_sql_int"  null="#Not Len(Trim(thisPage))#">,
									TYPE_STATUS=<cfqueryparam value = "#thisTypeStatus#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisTypeStatus))#">,
									CITATION_REMARKS=<cfqueryparam value = "#thisRemark#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisRemark))#">
								where
									citation_id=#val(thisCitationID)#
							</cfquery>
						</cfif>
					</cfif>
				</cfif>
			</cfloop>
			<cfif thisAcceptedIdFg is 1>
				<cfquery name="upOldID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					UPDATE identification SET ACCEPTED_ID_FG=0 where collection_object_id = #val(collection_object_id)#
				</cfquery>
				<cfquery name="newAcceptedId" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					UPDATE identification SET ACCEPTED_ID_FG=1 where identification_id = #val(thisIdentificationId)#
				</cfquery>
			</cfif>
			<cfif thisAcceptedIdFg is "DELETE">
				<cfquery name="deleteId" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					DELETE FROM identification_agent WHERE identification_id = #val(thisIdentificationId)#
				</cfquery>
				<cfquery name="deleteTId" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					DELETE FROM identification_taxonomy WHERE identification_id = #val(thisIdentificationId)#
				</cfquery>
				<cfquery name="deleteId" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					DELETE FROM identification WHERE identification_id = #val(thisIdentificationId)#
				</cfquery>
			<cfelse>
				<cfif n is 1 and thisAcceptedIdFg is 1 and thisTaxaFormula is 'A {string}'>
					<cfset thisScientificName = evaluate("scientific_name_" & n)>
					<cfquery name="updateId" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
						UPDATE identification SET
						scientific_name = <cfqueryparam value = "#thisScientificName#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisScientificName))#">,
						nature_of_id = <cfqueryparam value = "#thisNature#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisNature))#">,
						made_date = <cfqueryparam value = "#thisMadeDate#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisMadeDate))#">,
						identification_confidence= <cfqueryparam value = "#thisIdConf#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisIdConf))#">,
						identification_remarks = <cfqueryparam value = "#thisIdRemark#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisIdRemark))#">,
						publication_id = <cfqueryparam value = "#thisPubId#" CFSQLType="cf_sql_int"  null="#Not Len(Trim(thisPubId))#">,
						taxon_concept_id = <cfqueryparam value = "#thisConcId#" CFSQLType="cf_sql_int"  null="#Not Len(Trim(thisConcId))#">
						where identification_id=#val(thisIdentificationId)#
					</cfquery>
					<cfquery name="killlinks" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
						delete from identification_taxonomy where identification_id=#val(thisIdentificationId)#
					</cfquery>
					<cfset numtaxa = evaluate("number_of_taxa_" & n)>
					<cfloop from ="1" to="#numtaxa#" index="i">
						<cfset thisTaxonName=evaluate("taxon_name_" & n & "_" & i)>
						<cfif thisTaxonName is not "DELETE">
							<cfset thisTaxonNameID=evaluate("taxon_name_id_" & n & "_" & i)>
							<cfif len(thisTaxonNameID) gt 0>
								<cfquery name="newlink" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
									insert into identification_taxonomy (
										IDENTIFICATION_ID,TAXON_NAME_ID,VARIABLE
									) values (
										#val(thisIdentificationId)#,
										#val(thisTaxonNameID)#,
										'A'
									)
								</cfquery>
							</cfif>
						</cfif>
					</cfloop>
				<cfelse>
					<cfquery name="updateId" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
						UPDATE identification SET
						nature_of_id = <cfqueryparam value = "#thisNature#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisNature))#">,
						made_date = <cfqueryparam value = "#thisMadeDate#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisMadeDate))#">,
						identification_confidence=<cfqueryparam value = "#thisIdConf#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisIdConf))#">,
						identification_remarks = <cfqueryparam value = "#thisIdRemark#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisIdRemark))#">,
						publication_id = <cfqueryparam value = "#thisPubId#" CFSQLType="cf_sql_int"  null="#Not Len(Trim(thisPubId))#">,
						taxon_concept_id = <cfqueryparam value = "#thisConcId#" CFSQLType="cf_sql_int"  null="#Not Len(Trim(thisConcId))#">
						where identification_id=#val(thisIdentificationId)#
					</cfquery>
				</cfif>
				<cfloop from="1" to="#thisNumIds#" index="nid">
					<cftry>
						<!--- couter does not increment backwards - may be a few empty loops in here ---->
						<cfset thisIdId = evaluate("IdBy_" & n & "_" & nid & "_id")>
						<cfcatch>
							<cfset thisIdId =-1>
						</cfcatch>
					</cftry>
					<cftry>
						<cfset thisIdAgntId = evaluate("identification_agent_id_" & n & "_" & nid)>
						<cfcatch>
							<cfset thisIdAgntId=-1>
						</cfcatch>
					</cftry>
					<cfif thisIdAgntId is -1 and (thisIdId is not "DELETE" and thisIdId gte 0)>
						<!--- new identifier --->
						<cfquery name="updateIdA" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
							insert into identification_agent
								( IDENTIFICATION_ID,AGENT_ID,IDENTIFIER_ORDER)
							values
								(
									#val(thisIdentificationId)#,
									#val(thisIdId)#,
									#val(nid)#
								)
						</cfquery>
					<cfelse>
						<!--- update or delete --->
						<cfif thisIdId is "DELETE">
							<!--- delete --->
							<cfquery name="updateIdA" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
								delete from identification_agent
								where identification_agent_id=#val(thisIdAgntId)#
							</cfquery>
						<cfelseif thisIdId gte 0>
							<!--- update, but we can get here if there was no identifier --->
							<cfif len(thisIdAgntId) gt 0>
								<cfquery name="updateIdA" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
									update identification_agent set
										agent_id=#val(thisIdId)#,
										identifier_order=#val(nid)#
									 where
									 	identification_agent_id=#val(thisIdAgntId)#
								</cfquery>
							<cfelse>
								<cfquery name="updateIdA" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
									insert into identification_agent
										( IDENTIFICATION_ID,AGENT_ID,IDENTIFIER_ORDER)
									values
										(
											#val(thisIdentificationId)#,
											#val(thisIdId)#,
											#val(nid)#
										)
								</cfquery>
							</cfif>

						</cfif>
					</cfif>
				</cfloop>
			</cfif>
		</cfloop>
	</cftransaction>
	<cflocation url="editIdentification.cfm?collection_object_id=#collection_object_id#" addtoken="false">
</cfoutput>
</cfif>
<!---------------------------------------------------------------------------------------------->
<cfif #Action# is "deleteIdent">
	<cfif #accepted_id_fg# is "1">
		<font color="#FF0000" size="+1">You can't delete the accepted identification!</font>
		<cfabort>
    </cfif>
	<cflocation url="editIdentification.cfm?collection_object_id=#collection_object_id#" addtoken="false">
</cfif>
<!--------------------------------------------------------------------------------------------------->
<cfif #Action# is "multi">
<cfoutput>
	<cflocation url="multiIdentification.cfm?collection_object_id=#collection_object_id#" addtoken="false">
</cfoutput>
</cfif>
<!----------------------------------------------------------------------------------->
<cfif action is "createNew">
<cfoutput>
<cfif taxa_formula is "A {string}">
	<cfset scientific_name = user_id>
<cfelseif taxa_formula is "A">
	<cfset scientific_name = taxona>
<cfelseif taxa_formula is "A or B">
	<cfset scientific_name = "#taxona# or #taxonb#">
<cfelseif taxa_formula is "A and B">
	<cfset scientific_name = "#taxona# and #taxonb#">
<cfelseif taxa_formula is "A x B">
	<cfset scientific_name = "#taxona# x #taxonb#">
<cfelseif taxa_formula is "A ?">
	<cfset scientific_name = "#taxona# ?">
<cfelseif taxa_formula is "A sp.">
	<cfset scientific_name = "#taxona# sp.">
<cfelseif taxa_formula is "A ssp.">
	<cfset scientific_name = "#taxona# ssp.">
<cfelseif taxa_formula is "A cf.">
	<cfset scientific_name = "#taxona# cf.">
<cfelseif taxa_formula is "A aff.">
	<cfset scientific_name = "#taxona# aff.">
<cfelseif taxa_formula is "A / B intergrade">
	<cfset scientific_name = "#taxona# / #taxonb# intergrade">
<cfelse>
	The taxa formula you entered isn't handled yet! Please submit a bug report.
	<cfabort>
</cfif>
<cftransaction>
	<cfquery name="upOldID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		UPDATE identification SET ACCEPTED_ID_FG=0 where collection_object_id = #collection_object_id#
	</cfquery>
	<cfquery name="id" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select nextval('sq_identification_id') id
	</cfquery>
	<cfquery name="newID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		INSERT INTO identification (
			IDENTIFICATION_ID,
			COLLECTION_OBJECT_ID,
			MADE_DATE,
			NATURE_OF_ID,
			ACCEPTED_ID_FG,
			IDENTIFICATION_REMARKS,
			taxa_formula,
			scientific_name,
			publication_id,
			identification_confidence,
			taxon_concept_id
		) VALUES (
			<cfqueryparam value = "#id.id#" CFSQLType="cf_sql_int">,
			<cfqueryparam value = "#COLLECTION_OBJECT_ID#" CFSQLType="cf_sql_int">,
			<cfqueryparam value = "#MADE_DATE#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(MADE_DATE))#">,
			<cfqueryparam value = "#NATURE_OF_ID#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(NATURE_OF_ID))#">,
			1,
			<cfqueryparam value = "#IDENTIFICATION_REMARKS#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(IDENTIFICATION_REMARKS))#">,
			<cfqueryparam value = "#taxa_formula#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(taxa_formula))#">,
			<cfqueryparam value = "#scientific_name#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(scientific_name))#">,
			<cfqueryparam value = "#new_publication_id#" CFSQLType="cf_sql_int" null="#Not Len(Trim(new_publication_id))#">,
			<cfqueryparam value = "#identification_confidence#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(identification_confidence))#">,
			<cfqueryparam value = "#new_concept_id#" CFSQLType="cf_sql_int" null="#Not Len(Trim(new_concept_id))#">
		)
	</cfquery>
	<cfif len(newIdBy_id) gt 0>
		<cfquery name="newIdAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			insert into identification_agent (
				identification_id,
				agent_id,
				identifier_order)
			values (
				<cfqueryparam value = "#id.id#" CFSQLType="cf_sql_int">,
				<cfqueryparam value = "#newIdBy_id#" CFSQLType="cf_sql_int">,
				1
			)
		</cfquery>
	</cfif>
	<cfif len(#newIdBy_two_id#) gt 0>
		<cfquery name="newIdAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			insert into identification_agent (
				identification_id,
				agent_id,
				identifier_order)
			values (
				<cfqueryparam value = "#id.id#" CFSQLType="cf_sql_int">,
			<cfqueryparam value = "#newIdBy_two_id#" CFSQLType="cf_sql_int">,
				2
				)
		</cfquery>
	</cfif>
	<cfif len(#newIdBy_three_id#) gt 0>
		<cfquery name="newIdAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			insert into identification_agent (
				identification_id,
				agent_id,
				identifier_order)
			values (
				<cfqueryparam value = "#id.id#" CFSQLType="cf_sql_int">,
			<cfqueryparam value = "#newIdBy_three_id#" CFSQLType="cf_sql_int">,
				3
				)
		</cfquery>
	</cfif>
	<cfquery name="newId2" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		INSERT INTO identification_taxonomy (
			identification_id,
			taxon_name_id,
			variable)
		VALUES (
				<cfqueryparam value = "#id.id#" CFSQLType="cf_sql_int">,
			<cfqueryparam value = "#taxona_id#" CFSQLType="cf_sql_int">,
			'A')
	 </cfquery>
	 <cfif #taxa_formula# contains "B">
		 <cfquery name="newId3" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			INSERT INTO identification_taxonomy (
				identification_id,
				taxon_name_id,
				variable)
			VALUES (
				<cfqueryparam value = "#id.id#" CFSQLType="cf_sql_int">,
			<cfqueryparam value = "#taxonb_id#" CFSQLType="cf_sql_int">,
				'B')
		 </cfquery>
	 </cfif>
</cftransaction>
	<cflocation url="editIdentification.cfm?collection_object_id=#collection_object_id#" addtoken="false">
</cfoutput>
</cfif>
<!----------------------------------------------------------------------------------->
<cfinclude template="includes/_pickFooter.cfm">
<cf_customizeIFrame>