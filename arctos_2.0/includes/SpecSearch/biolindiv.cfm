<script>
	$(document).ready(function () {
		$(document).on("change", '[id^="attribute_type_placeholder_"]', function(){
			var i =  this.id;
			i=i.replace("attribute_type_placeholder_", "");
			var thisVal=this.value;
			if ($('#' + thisVal).length){
				alert('That Attribute has already been added.');
				$("#" + this.id).val('');
				return;
			}
			var thisTxt=$("#" + this.id + " option:selected").text();
			var nEl='<input type="text" name="' + thisVal + '" id="' + thisVal + '" placeholder="' + thisTxt + '">';
			//nEl+='<span class="infoLink" onclick="resetAttr(' + this.id + ')">reset</span>';
			$("#attribute_value_placeholder_" + i).html(nEl);
			// hide the placeholder/picker
			var nlbl='<span class="helpLink" id="_' +thisVal+'">'+thisTxt+'</span>';
			$("#" + this.id).hide().after(nlbl);
		});
	});

	function resetAttr(id){

	}
	function moreAttr(){
		var i;
		 $('[id^= "attribute_type_placeholder_"]').each(function(){
            i=this.id.replace("attribute_type_placeholder_", "");
        });
        var lastNum=i;
        var nextNum=parseInt(i)+parseInt(1);
        var nelem='<tr><td class="lbl">';
        nelem+='<select name="attribute_type_placeholder_'+nextNum+'" id="attribute_type_placeholder_'+nextNum+'" size="1"></select>';
        nelem+='</td><td class="srch"><span id="attribute_value_placeholder_'+nextNum+'"></span></td></tr>';
        $('#attrCtlTR').before(nelem);
        $('#attribute_type_placeholder_1').find('option').clone().appendTo('#attribute_type_placeholder_' + nextNum);
	}
</script>



<cfoutput>
<cfif isdefined("session.portal_id") and session.portal_id gt 0>
	<cftry>
		<cfquery name="ctAttributeType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey)#" cachedwithin="#createtimespan(0,0,60,0)#">
			select distinct(attribute_type) from cctattribute_type#session.portal_id# order by attribute_type
		</cfquery>
		<cfcatch>
			<cfquery name="ctAttributeType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey)#" cachedwithin="#createtimespan(0,0,60,0)#">
				select distinct(attribute_type) from ctattribute_type order by attribute_type
			</cfquery>
		</cfcatch>
	</cftry>
<cfelse>
	<cfquery name="ctAttributeType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey)#" cachedwithin="#createtimespan(0,0,60,0)#">
		select distinct(attribute_type) from ctattribute_type order by attribute_type
	</cfquery>
</cfif>
<cfquery name="CTSPECPART_ATTRIBUTE_TYPE" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey)#" cachedwithin="#createtimespan(0,0,60,0)#">
			select distinct(ATTRIBUTE_TYPE) from CTSPECPART_ATTRIBUTE_TYPE order by attribute_type
		</cfquery>

<cfquery name="srchAttrs" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey)#" cachedwithin="#createtimespan(0,0,60,0)#">
	select * from ssrch_field_doc where SPECIMEN_QUERY_TERM=1 and category='attribute' order by cf_variable
</cfquery>




<table id="t_identifiers" class="ssrch">

	<tr>
		<td class="lbl">
			<select name="attribute_type_placeholder_1" id="attribute_type_placeholder_1" size="1">
				<option selected value="">[ pick an attribute ]</option>
					<cfloop query="srchAttrs">
						<option value="#srchAttrs.CF_VARIABLE#">#srchAttrs.DISPLAY_TEXT#</option>
					</cfloop>
			  </select>
		</td>
		<td class="srch">
			<span id="attribute_value_placeholder_1"></span>
		</td>
	</tr>
	<tr id="attrCtlTR">
		<td colspan="2">
			<div style="margin-left:3em;margin:1em;padding:.5em;border:1px solid green;;">
				<div>
					<span class="likeLink" onclick="moreAttr()">Add attribute</span> for more search options.
					Click the label after selecting an attribute type for more information.
					Empty values are ignored.
				</div>
			</div>
		</td>

	</tr>
	<tr>
		<td class="lbl">
			<select name="part_attribute" id="part_attribute" size="1">
				<option value="">Part Attribute....</option>
					<cfloop query="CTSPECPART_ATTRIBUTE_TYPE">
						<option value="#CTSPECPART_ATTRIBUTE_TYPE.attribute_type#">#CTSPECPART_ATTRIBUTE_TYPE.attribute_type#</option>
					</cfloop>
			  </select>
		</td>
		<td class="srch">
			<input type="text" id="part_attribute_value" name="part_attribute_value" size="60">
			<span class="infoLink" onclick="var e=document.getElementById('part_attribute_value');e.value='='+e.value;">Add = for exact match</span>
		</td>
	</tr>
	<tr>
		<td class="lbl">
			<span class="helpLink" id="_part_remark">Part Remark:</span>
		</td>
		<td class="srch">
			<input type="text" name="part_remark" id="part_remark">
		</td>
	</tr>

<!----






	<tr>
		<td class="lbl">
			<span class="helpLink infoLink" id="attribute_type">Help</span>
			<select name="attribute_type_1" id="attribute_type_1" size="1">
				<option selected value="">[ pick an attribute ]</option>
					<cfloop query="ctAttributeType">
						<option value="#ctAttributeType.attribute_type#">#ctAttributeType.attribute_type#</option>
					</cfloop>
			  </select>
		</td>
		<td class="srch">
			<select name="attOper_1" id="attOper_1" size="1">
				<option selected value="">equals</option>
				<option value="like">contains</option>
				<option value="greater">greater than</option>
				<option value="less">less than</option>
			</select>
			<input type="text" name="attribute_value_1" size="20">
			<span class="infoLink"
				onclick="windowOpener('/info/attributeHelpPick.cfm?attNum=1&attribute='+SpecData.attribute_type_1.value,'attPick','width=600,height=600, resizable,scrollbars');">
				Pick
			</span>
			<input type="text" name="attribute_units_1" size="6">(units)
		</td>

	<tr>
		<td class="lbl">
			<span class="helpLink" id="_attribute_remark">Attribute Remark:</span>
		</td>
		<td class="srch">
			<input type="text" name="attribute_remark" id="attribute_remark" size="80">
		</td>
	</tr>
	</tr>
	---->
	<tr>
		<td class="lbl">
			<span class="helpLink" id="ocr_text">OCR Text:</span>
		</td>
		<td class="srch">
			<input name="ocr_text" id="ocr_text" size="80">
		</td>
	</tr>
</table>
</cfoutput>