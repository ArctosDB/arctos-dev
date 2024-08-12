<cfinclude template="/includes/_pickHeader.cfm">
<style>
	.tsdiv {
		font-size:smaller;
		margin-left:1em;
	}
</style>
	<script>
	$(document).ready(function() {
		$("div[data-tid]").each(function( i, val ) {
			//console.log(val);
			var tid=$(this).attr("data-tid");
			//dois.push(doi);
			 $.ajax({
		        url: "/component/taxonomy.cfc?queryformat=column",
		        type: "GET",
		        dataType: "json",
		        //async: false,
		        data: {
		          method:  "getTaxonStatus",
		          taxon_name_id : tid,
		          returnformat : "json"
		        },
		        success: function(r) {
		          if ((r.STATUS) && r.STATUS=='success'){
		          	$("#t_" + r.TAXON_NAME_ID).append(r.TAXON_STATUS);
		          }
		          // else do nothing; this isn't that important
		        },
		          error: function (xhr, textStatus, errorThrown){
		            alert(errorThrown + ': ' + textStatus + ': ' + xhr);
		        }
		      });
		      $.ajax({
		        url: "/component/taxonomy.cfc?queryformat=column",
		        type: "GET",
		        dataType: "json",
		        //async: false,
		        data: {
		          method:  "getRelatedTaxa",
		          taxon_name_id : tid,
		          returnformat : "json"
		        },
		        success: function(r) {
		        	console.log(r);
		        	var rd='';
		        	for (i=0;i<r.ROWCOUNT;i++) {
    					console.log(r.DATA.RELATIONSHIP[i]);
    					rd+='<div>' + r.DATA.RELATIONSHIP[i] + '</div>';
		        	}

					$("#t_" + tid).append(rd);
		         // var rd='';
		         // for (i=0;i<r.ROWCOUNT;i++) {
		         // 	console.log(i);
		        //  	rd+='<div><a target="_blank" href="/name/' + r.DATA.SCIENTIFIC_NAME[i] + '">' + r.DATA.SCIENTIFIC_NAME[i] + '</a> [' + r.DATA.TAXON_RELATIONSHIP[i] + '] [' + r.DATA.RELDIR[i] + ' this name]</div>';

				//	console.log(rd);

		       // }
					//console.log(tid);
				//	if ((rd) && rd.length>0){

		        //		$("#t_" + tid).append(rd);
				//	}
		        },
		          error: function (xhr, textStatus, errorThrown){
		            alert(errorThrown + ': ' + textStatus + ': ' + xhr);
		        }
		      });
		});
	});
		function settaxaPickPrefs (v) {
			jQuery.getJSON("/component/functions.cfc",
				{
					method : "setSessionTaxaPickPrefs",
					val : v,
					returnformat : "json",
					queryformat : 'column'
				}
			);
		}


	</script>
	<cfoutput>
		<script>
			function useThisOne(formName,taxonIdFld,taxonNameFld,taxon_name_id,scientific_name){
				opener.document.#formName#.#taxonIdFld#.value=taxon_name_id;
				opener.document.#formName#.#taxonNameFld#.value=scientific_name;
				opener.document.#formName#.#taxonNameFld#.classList.remove('badPick');
				opener.document.#formName#.#taxonNameFld#.classList.add('goodPick');
				self.close();
			}
		</script>
		<cfif not isdefined("session.taxaPickPrefs") or len(session.taxaPickPrefs) is 0>
			<cfset session.taxaPickPrefs="anyterm">
		</cfif>
		<cfset taxaPickPrefs=session.taxaPickPrefs>
		<form name="s" method="post" action="TaxaPick.cfm">
			<input type="hidden" name="formName" value="#formName#">
			<input type="hidden" name="taxonIdFld" value="#taxonIdFld#">
			<input type="hidden" name="taxonNameFld" value="#taxonNameFld#">
			<label for="scientific_name">Scientific Name (STARTS WITH)</label>
			<input type="text" name="scientific_name" id="scientific_name" size="50" value="#scientific_name#">
			<label for="taxaPickPrefs">Filter Results by...</label>
			<select name="taxaPickPrefs" id="taxaPickPrefs" onchange="settaxaPickPrefs(this.value);">
				<option <cfif session.taxaPickPrefs is "anyterm"> selected="selected" </cfif> value="anyterm">Any Term (best performance)</option>
				<option <cfif session.taxaPickPrefs is "relatedterm"> selected="selected" </cfif> value="relatedterm">Include terms from relationships</option>
				<option <cfif session.taxaPickPrefs is "mycollections"> selected="selected" </cfif> value="mycollections">Include only terms with classifications preferred by my collections</option>
				<option <cfif session.taxaPickPrefs is "usedbymycollections"> selected="selected" </cfif> value="usedbymycollections">Include only terms used by my collections</option>
			</select>
			<br><input type="submit" class="lnkBtn" value="Search">
		</form>
		<cfif len(scientific_name) is 0 or scientific_name is 'undefined'>
			<cfabort>
		</cfif>
		<cfif taxaPickPrefs is "anyterm">
			<cfset sql="SELECT
				scientific_name,
				taxon_name_id
			from
				taxon_name
			where
				UPPER(scientific_name) LIKE '#ucase(scientific_name)#%'
			order by
			  		scientific_name">
		<cfelseif taxaPickPrefs is "usedbymycollections">
			<!--- VPD limits users to seeing only their collections, so just make the joins --->
			<cfset sql="select scientific_name,taxon_name_id from (
				SELECT
					taxon_name.scientific_name,
					taxon_name.taxon_name_id
				from
					taxon_name,
					identification_taxonomy,
					identification,
					cataloged_item
				where
					taxon_name.taxon_name_id=identification_taxonomy.taxon_name_id and
					identification_taxonomy.identification_id=identification.identification_id and
					identification.collection_object_id=cataloged_item.collection_object_id and
					UPPER(taxon_name.scientific_name) LIKE '#ucase(scientific_name)#%'
				)
				group by
					scientific_name,
					taxon_name_id
				order by
			  		scientific_name">
		<cfelseif taxaPickPrefs is "mycollections">
			<!--- VPD limits users to seeing only their collections, so just make the joins --->
			<cfset sql="select scientific_name,taxon_name_id from (
				SELECT
			 		taxon_name.scientific_name,
			  		taxon_name.taxon_name_id
				from
			  		taxon_name,
			  		taxon_term,
			  		collection
				where
					taxon_name.taxon_name_id=taxon_term.taxon_name_id and
					taxon_term.SOURCE=collection.PREFERRED_TAXONOMY_SOURCE and
			  		UPPER(taxon_name.scientific_name) LIKE '#ucase(scientific_name)#%'
			  	)
			  	group by
			  		scientific_name,
			  		taxon_name_id
			  	order by
			  		scientific_name">
		<cfelseif taxaPickPrefs is "relatedterm">
			<cfset sql="select * from (
				SELECT
					scientific_name,
					taxon_name_id
				from
					taxon_name
				where
					UPPER(taxon_name.scientific_name) LIKE '#ucase(scientific_name)#%'
				UNION
				SELECT
					a.scientific_name,
					a.taxon_name_id
				from
					taxon_name a,
					taxon_relations,
					taxon_name b
				where
					a.taxon_name_id = taxon_relations.taxon_name_id (+) and
					taxon_relations.related_taxon_name_id = b.taxon_name_id (+) and
					UPPER(B.scientific_name) LIKE '#ucase(scientific_name)#%'
				UNION
				SELECT
					b.scientific_name,
					b.taxon_name_id
				from
					taxon_name a,
					taxon_relations,
					taxon_name b
				where
					a.taxon_name_id = taxon_relations.taxon_name_id (+) and
					taxon_relations.related_taxon_name_id = b.taxon_name_id (+) and
					UPPER(a.scientific_name) LIKE '#ucase(scientific_name)#%'
			)
			where
				taxon_name_id is not null
			group by
				scientific_name,
				taxon_name_id
			ORDER BY
				scientific_name
		">
		</cfif>
		<cfquery name="getTaxa" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey)#">
			#PreserveSingleQuotes(sql)#
		</cfquery>
	</cfoutput>
	<cfif getTaxa.recordcount is 1>
		<cfoutput>
			<script>
				useThisOne('#formName#','#taxonIdFld#','#taxonNameFld#','#getTaxa.taxon_name_id#','#getTaxa.scientific_name#');
			</script>
		</cfoutput>
	<cfelseif #getTaxa.recordcount# is 0>
		<cfoutput>
			Nothing matched #scientific_name#.
		</cfoutput>
	<cfelse>
		<cfoutput query="getTaxa">
			<div>
				#scientific_name#
				<a target="_blank" href="/name/#scientific_name#">[ details ]</a>
				<span class="likeLink" onclick="useThisOne('#formName#','#taxonIdFld#','#taxonNameFld#','#taxon_name_id#','#scientific_name#')">[ use ]</span>
				<div class="tsdiv" id="t_#taxon_name_id#" data-tid="#taxon_name_id#"></div>
			</div>
	<!---
		<br><a href="##" onClick="javascript: document.selectedAgent.agentID.value='#agent_id#';document.selectedAgent.agentName.value='#agent_name#';document.selectedAgent.submit();">#agent_name# - #agent_id#</a> -
		<script>getStatus();</script>


	--->

	</cfoutput>

	</CFIF>

<cfinclude template="/includes/_pickFooter.cfm">