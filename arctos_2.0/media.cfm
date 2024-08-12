<cfset title="Manage Media">
<cfinclude template="/includes/_header.cfm">
<cfquery name="ctmedia_relationship" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey)#">
	select media_relationship from ctmedia_relationship order by media_relationship
</cfquery>
<cfquery name="ctmedia_label" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey)#">
	select media_label from ctmedia_label order by media_label
</cfquery>
<cfquery name="ctmedia_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey)#">
	select media_type from ctmedia_type order by media_type
</cfquery>
<cfquery name="ctmime_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey)#">
	select mime_type from ctmime_type order by mime_type
</cfquery>
<cfquery name="ctmedia_license" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey)#">
	select media_license_id,display media_license from ctmedia_license order by display
</cfquery>
<!----------------------------------------------------------------------------------------->
<cfif action is "saveEdit">
	<cfoutput>
		<div class="error">
			<p>
				DO NOT USE YOUR BACK BUTTON.
			</p>
			<p>
				It's haunted.
			</p>
			<p>
				(It's not really, but the previous form won't properly recover from an error.)
			</p>
			<p>
				<a href="media.cfm?action=edit&media_id=#media_id#">try this instead</a>
			</p>
		</div>
			<cfif len(FILETOUPLOAD) gt 0>
				<!---- get the filename as uploaded ---->
			    <cfset tmpPartsArray = Form.getPartsArray() />
			    <cfif IsDefined("tmpPartsArray")>
			        <cfloop array="#tmpPartsArray#" index="tmpPart">
			            <cfif tmpPart.isFile() AND tmpPart.getName() EQ "FILETOUPLOAD"> <!---   --->
			               <cfset fileName=tmpPart.getFileName() >
			            </cfif>
			        </cfloop>
			    </cfif>
				<cfif not isdefined("filename") or len(filename) is 0>
					Didn't get filename<cfabort>
				</cfif>
				<!---- read the file ---->
				<cffile action="READ" file="#FiletoUpload#" variable="fileContent">
				<!---- temporary safe name ---->
				<cfset tempName=createUUID()>
				<!---- stash the file in the sandbox ---->
				<cffile	action = "upload" destination = "#Application.sandbox#/#tempName#.tmp" fileField = "FILETOUPLOAD">
				<!--- send it to S3 ---->
				<cfset utilities = CreateObject("component","component.utilities")>
				<cfset x=utilities.sandboxToS3("#Application.sandbox#/#tempName#.tmp",fileName)>
				<cfif not isjson(x)>
					upload fail<cfdump var=#x#><cfabort>
				</cfif>
				<cfset x=deserializeJson(x)>
				<cfif (not isdefined("x.STATUSCODE")) or (x.STATUSCODE is not 200) or (not isdefined("x.MEDIA_URI")) or (len(x.MEDIA_URI) is 0)>
					upload fail<cfdump var=#x#><cfabort>
				</cfif>
				<cfset preview_uri=x.MEDIA_URI>
			</cfif>
		<cftransaction>
			<!--- update media --->
			<cfquery name="makeMedia" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey)#">
				update media set
				media_uri='#escapeQuotes(media_uri)#',
				mime_type='#mime_type#',
		        media_type='#media_type#',
		        preview_uri='#preview_uri#'
				<cfif len(media_license_id) gt 0>
					,media_license_id=#media_license_id#
				<cfelse>
					,media_license_id=NULL
				</cfif>
				where media_id=#media_id#
			</cfquery>
			<!--- relations --->
			<cfloop from="1" to="#number_of_relations#" index="n">
				<cfset thisRelationship = #evaluate("relationship__" & n)#>
				<cfset thisRelatedId = #evaluate("related_id__" & n)#>
				<cfif isdefined("media_relations_id__#n#")>
					<cfset thisRelationID=#evaluate("media_relations_id__" & n)#>
				<cfelse>
					<cfset thisRelationID=-1>
				</cfif>
				<cfif thisRelationID is -1>
					<cfquery name="makeRelation" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey)#">
						insert into media_relations (
							media_id,media_relationship,related_primary_key
						) values (
							#media_id#,'#thisRelationship#',#thisRelatedId#)
					</cfquery>
				<cfelse>
					<cfif #thisRelationship# is "delete">
						<cfquery name="upRelation" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey)#">
							delete from
								media_relations
							where media_relations_id=#thisRelationID#
						</cfquery>
					<cfelse>
						<cftry>
						<cfquery name="upRelation" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey)#">
							update
								media_relations
							set
								media_relationship='#thisRelationship#',
								related_primary_key=#thisRelatedId#
							where media_relations_id=#thisRelationID#
						</cfquery>
						<cfcatch>
							<!--- like a 99% chance this is because someone from another collection has something hooked to the media - we hope.... ---->
						</cfcatch>
						</cftry>
					</cfif>
				</cfif>
			</cfloop>
			<cfloop from="1" to="#number_of_labels#" index="n">
				<cfset thisLabel = #evaluate("label__" & n)#>
				<cfset thisLabelValue = #evaluate("label_value__" & n)#>
				<cfif isdefined("media_label_id__#n#")>
					<cfset thisLabelID=#evaluate("media_label_id__" & n)#>
				<cfelse>
					<cfset thisLabelID=-1>
				</cfif>
				<cfif thisLabelID is -1>
					<cfquery name="makeLabel" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey)#">
						insert into media_labels (media_id,media_label,label_value)
						values (#media_id#,'#thisLabel#','#thisLabelValue#')
					</cfquery>
				<cfelse>
					<cfif #thisLabel# is "delete">
						<cfquery name="upRelation" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey)#">
							delete from
								media_labels
							where media_label_id=#thisLabelID#
						</cfquery>
					<cfelse>
						<cfquery name="upRelation" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey)#">
							update
								media_labels
							set
								media_label='#thisLabel#',
								label_value='#thisLabelValue#'
							where media_label_id=#thisLabelID#
						</cfquery>
					</cfif>
				</cfif>
			</cfloop>
		</cftransaction>
	<cflocation url="media.cfm?action=edit&media_id=#media_id#" addtoken="false">
</cfoutput>
</cfif>
<!----------------------------------------------------------------------------------------->
<cfif action is "edit">
<style>
	.mLblDisp{
		font-size:small;
	}
</style>
	<cfset  func = CreateObject("component","component.functions")>
	<script>
		jQuery(document).ready(function() {
			$("select[id^='label__']").each(function(e){
				if ($(this).val()=='made date'){
					//console.log(this.id + ' is made date');
					var veid=this.id.replace('label__','label_value__');
					$('#' + veid).datepicker();
				}
			});
		});

	</script>
	<!----
		<select name="label__#i#" id="label__#i#" size="1">
					<option value="delete">delete</option>
					<cfloop query="ctmedia_label">
						<option <cfif d is media_label> selected="selected" </cfif>value="#media_label#">#media_label#</option>
					</cfloop>
				</select>:&nbsp;<input type="text" name="label_value__#i#" id="label_value__#i#" size="80" value="#stripQuotes(label_value)#">
				</div>


			---->

	<cfquery name="media" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey)#">
		select * from media where media_id=#media_id#
	</cfquery>
	<cfset relns=func.getMediaRelations(#media_id#)>
	<cfquery name="labels"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey)#">
		select
			media_label,
			label_value,
			getPreferredAgentName(ASSIGNED_BY_AGENT_ID) agent_name,
			to_char(assigned_on_date,'YYYY-MM-DD') assigned_on_date,
			media_label_id
		from
			media_labels
		where
			media_id=#media_id#
	</cfquery>
	<cfquery name="tag"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey)#">
		select count(*) c from tag where media_id=#media_id#
	</cfquery>
	<p>
		<span class="helpLink" data-helplink="media_guidelines">READ THE DOCUMENTATION!</span>
	</p>
	<cfoutput>
		Edit Media
		<br><a href="/TAG.cfm?media_id=#media_id#">edit #tag.c# TAGs</a> ~
		<a href="/showTAG.cfm?media_id=#media_id#">View #tag.c# TAGs</a> ~
		<a href="/media/#media_id#">Detail Page</a>
		<form name="newMedia" method="post" action="media.cfm" enctype="multipart/form-data">
			<input type="hidden" name="action" value="saveEdit">
			<input type="hidden" id="number_of_relations" name="number_of_relations" value="#relns.recordcount#">
			<input type="hidden" id="number_of_labels" name="number_of_labels" value="#labels.recordcount#">
			<input type="hidden" id="media_id" name="media_id" value="#media_id#">
			<label for="media_uri">Media URI (<a href="#media.media_uri#" target="_blank">open</a>)</label>
			<input type="text" name="media_uri" id="media_uri" size="90" value="#media.media_uri#">
			<span class="infoLink" onclick="generateMD5()">Generate Checksum</span>
			<label for="preview_uri">Preview URI
				<cfif len(media.preview_uri) gt 0>
					(<a href="#media.preview_uri#" target="_blank">open</a>)
				</cfif>
			</label>
			<input type="text" name="preview_uri" id="preview_uri" size="90" value="#media.preview_uri#">
			<!----
				<span class="infoLink" onclick="clickUploadPreview()">Load...</span>
				---->
			<label for="FiletoUpload">upload a thumbnail</label>
				<input type="file" name="FiletoUpload" size="45" >

			<label for="mime_type">MIME Type</label>
			<select name="mime_type" id="mime_type">
				<cfloop query="ctmime_type">
				    <option <cfif #media.mime_type# is #ctmime_type.mime_type#> selected="selected"</cfif> value="#mime_type#">#mime_type#</option>
				</cfloop>
			</select>
			<span class="infoLink" onclick="getCtDoc('ctmime_type');">Define</span>
			<label for="media_type">Media Type</label>
			<select name="media_type" id="media_type">
				<cfloop query="ctmedia_type">
					<option <cfif #media.media_type# is #ctmedia_type.media_type#> selected="selected"</cfif> value="#media_type#">#media_type#</option>
				</cfloop>
			</select>
			<span class="infoLink" onclick="getCtDoc('ctmedia_type');">Define</span>

			<label for="media_license_id">License</label>
			<select name="media_license_id" id="media_license_id">
				<option value="">NONE</option>
				<cfloop query="ctmedia_license">
					<option <cfif media.media_license_id is ctmedia_license.media_license_id> selected="selected"</cfif> value="#ctmedia_license.media_license_id#">#ctmedia_license.media_license#</option>
				</cfloop>
			</select>
			<span class="infoLink" onclick="getCtDoc('ctmedia_license');">Define</span>
			<label for="relationships">Media Relationships | <span class="likeLink" onclick="manyCatItemToMedia('#media_id#')">Add multiple "shows cataloged_item" records</span>
			<span class="likeLink" onclick="getCtDoc('ctmedia_relationship');">Define</span>
			</label>
			<br>To edit, change relationship to "delete" then change to new type. Make sure to save when you're done.
			<div id="relationships" style="border:1px dashed red;">
				<cfset i=1>
				<cfif relns.recordcount is 0>
				<!--- seed --->
                <div id="seedMedia" style="display:none">
                    <input type="hidden" id="media_relations_id__0" name="media_relations_id__0">
					<cfset d="">
                    <select name="relationship__0" id="relationship__0" size="1"  onchange="pickedRelationship(this.id)">
						<option value="delete">delete</option>
						<cfloop query="ctmedia_relationship">
							<option <cfif #d# is #media_relationship#> selected="selected" </cfif>value="#media_relationship#">#media_relationship#</option>
						</cfloop>
					</select>:&nbsp;<input type="text" name="related_value__0" id="related_value__0" size="80">
					<input type="hidden" name="related_id__0" id="related_id__0">
                </div>
                </cfif>
                <cfloop query="relns">
					<cfset d=media_relationship>
					<input type="hidden" id="media_relations_id__#i#" name="media_relations_id__#i#" value="#media_relations_id#">
					<select name="relationship__#i#" id="relationship__#i#" size="1"  onchange="pickedRelationship(this.id)">
						<option value="delete">delete</option>
						<cfloop query="ctmedia_relationship">
							<option <cfif #d# is #media_relationship#> selected="selected" </cfif>value="#media_relationship#">#media_relationship#</option>
						</cfloop>
					</select>:&nbsp;<input type="text" name="related_value__#i#" id="related_value__#i#" size="80" value="#summary#">
					<input type="hidden" name="related_id__#i#" id="related_id__#i#" value="#related_primary_key#">
					<span class="mLblDisp">Created by #created_agent_name# on #created_on_date#</span>
					<cfset i=i+1>
					<br>
				</cfloop>

				<br><span class="infoLink" id="addRelationship" onclick="addRelation(#i#)">Add Relationship</span>
			</div>

			<br>
			<label for="labels">Media Labels <span class="likeLink" onclick="getCtDoc('ctmedia_label');">Define</span></label>
			<div id="labels" style="border:1px dashed red;">

			<cfset i=1>
			<cfif labels.recordcount is 0>
				<!--- seed --->
				<div id="seedLabel" style="display:none;">
					<div id="labelsDiv__0">
						<input type="hidden" id="media_label_id__0" name="media_label_id__0">
						<cfset d="">
						<select name="label__0" id="label__0" size="1">
							<option value="delete">delete</option>
							<cfloop query="ctmedia_label">
								<option <cfif #d# is #media_label#> selected="selected" </cfif>value="#media_label#">#media_label#</option>
							</cfloop>
						</select>:&nbsp;<input type="text" name="label_value__0" id="label_value__0" size="80">
					</div>
				</div>
			</cfif>
			<cfloop query="labels">
				<cfset d=media_label>
				<div id="labelsDiv__#i#">
				<input type="hidden" id="media_label_id__#i#" name="media_label_id__#i#" value="#media_label_id#">
				<select name="label__#i#" id="label__#i#" size="1">
					<option value="delete">delete</option>
					<cfloop query="ctmedia_label">
						<option <cfif d is media_label> selected="selected" </cfif>value="#media_label#">#media_label#</option>
					</cfloop>
				</select>:&nbsp;<input type="text" name="label_value__#i#" id="label_value__#i#" size="80" value="#stripQuotes(label_value)#">
				<span class="mLblDisp">Assigned by #agent_name# on #assigned_on_date#</span>
				</div>
				<cfset i=i+1>
			</cfloop>

				<span class="infoLink" id="addLabel" onclick="addLabel(#i#)">Add Label</span>
			</div>
			<br>
			<input type="button"
				value="Save Edits"
				class="savBtn"
				onclick="newMedia.action.value='saveEdit';newMedia.submit();">
			<cfif relns.recordcount is 0 and labels.recordcount is 0>
				<input type="button"
					value="delete media"
					class="delBtn"
					onclick="newMedia.action.value='delMedia';confirmDelete('newMedia');">
			<cfelse>
				[ delete labels and relationships to delete media ]
			</cfif>
		</form>
	</cfoutput>
</cfif>

<!----------------------------------------------------------------------------------------->
<cfif action is "delMedia">
	<cfquery name="deleteMedia" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey)#">
		delete from media where media_id=#media_id#
	</cfquery>
	<cfoutput>
		<br>-you deleted media #media_id#-
		<br>The files
		<br> #media_uri#
		<cfif len(preview_uri) gt 0>
			and #preview_uri#
		</cfif>
		are unaffected. You should delete them if you don't need them around anymore.
	</cfoutput>

</cfif>

<!----------------------------------------------------------------------------------------->
<cfif action is "newMedia">
	<cfoutput>
		CAUTION: This form should be used only for special situations.

		<p>
			This form uploads a file and creates a bare Media record.
		</p>
		<p>
			The Attach/Upload Media link on any page which contains Media will create Media and accompanying thumbnails, and many
			will automatically create relationships and labels.
		</p>
		<form name="newMedia" method="post" action="media.cfm" enctype="multipart/form-data">
			<input type="hidden" name="action" value="saveNew">
			<label for="FiletoUpload">upload a file</label>
			<input type="file" name="FiletoUpload" size="45" >
			<label for="mime_type">MIME Type</label>
			<select name="mime_type" id="mime_type" class="reqdClr" required>
				<option></option>
				<cfloop query="ctmime_type">
				    <option value="#mime_type#">#mime_type#</option>
				</cfloop>
			</select>
			<span class="infoLink" onclick="getCtDoc('ctmime_type');">Define</span>
			<label for="media_type">Media Type</label>
			<select name="media_type" id="media_type" class="reqdClr" required>
				<option></option>
				<cfloop query="ctmedia_type">
					<option value="#media_type#">#media_type#</option>
				</cfloop>
			</select>
			<span class="infoLink" onclick="getCtDoc('ctmedia_type');">Define</span>
			<br>
			<input type="submit" value="upload and create" class="insBtn">
		</form>
	</cfoutput>
</cfif>
<!------------------------------------------------------------------------------------------>
<cfif action is "saveNew">
	<cfoutput>
		<cfif len(FILETOUPLOAD) is 0>
			no file<cfabort>
		</cfif>
		<!---- get the filename as uploaded ---->
	    <cfset tmpPartsArray = Form.getPartsArray() />
	    <cfif IsDefined("tmpPartsArray")>
	        <cfloop array="#tmpPartsArray#" index="tmpPart">
	            <cfif tmpPart.isFile() AND tmpPart.getName() EQ "FILETOUPLOAD"> <!---   --->
	               <cfset fileName=tmpPart.getFileName() >
	            </cfif>
	        </cfloop>
	    </cfif>
		<cfif not isdefined("filename") or len(filename) is 0>
			Didn't get filename<cfabort>
		</cfif>
		<!---- read the file ---->
		<cffile action="READ" file="#FiletoUpload#" variable="fileContent">
		<!---- temporary safe name ---->
		<cfset tempName=createUUID()>
		<!---- stash the file in the sandbox ---->
		<cffile	action = "upload" destination = "#Application.sandbox#/#tempName#.tmp" fileField = "FILETOUPLOAD">
		<!--- send it to S3 ---->
		<cfset utilities = CreateObject("component","component.utilities")>
		<cfset x=utilities.sandboxToS3("#Application.sandbox#/#tempName#.tmp",fileName)>
		<cfif not isjson(x)>
			upload fail<cfdump var=#x#><cfabort>
		</cfif>
		<cfset x=deserializeJson(x)>
		<cfif (not isdefined("x.STATUSCODE")) or (x.STATUSCODE is not 200) or (not isdefined("x.MEDIA_URI")) or (len(x.MEDIA_URI) is 0)>
			upload fail<cfdump var=#x#><cfabort>
		</cfif>
		<cfset media_uri=x.MEDIA_URI>
		<cfquery name="mid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey)#">
			select sq_media_id.nextval nv from dual
		</cfquery>
		<cfset media_id=mid.nv>
		<cfquery name="makeMedia" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey)#">
			insert into media (media_id,media_uri,mime_type,media_type)
            values (#media_id#,'#escapeQuotes(media_uri)#','#mime_type#','#media_type#')
		</cfquery>
		<p>
			Media Created <a href="media.cfm?action=edit&media_id=#media_id#">continue to Edit Media</a>
		</p>
		<p>
			Key for geography WKT links:
			<textarea>MEDIA::#media_id#</textarea>
		</p>
	</cfoutput>
</cfif>
<cfinclude template="/includes/_footer.cfm">