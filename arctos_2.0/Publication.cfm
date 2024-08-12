<cfinclude template="includes/_header.cfm">
<cfif action is "nothing" and isdefined("publication_id") and isnumeric(publication_id)>
	<cfoutput><cflocation url="Publication.cfm?action=edit&publication_id=#publication_id#" addtoken="false"></cfoutput>
</cfif>
<!---------------------------------------------------------------------------------------------------------->
<cfif action is "edit">
<cfset title = "Edit Publication">
<cfoutput>
	<script>
		jQuery(document).ready(function(){
            $("##mediaUpClickThis").click(function(){
			    addMedia('publication_id','#publication_id#');
			});
			 getMedia('publication','#publication_id#','pubMediaDv','20','1');
		});
	</script>
	<a href="/SpecimenUsage.cfm?action=search&publication_id=#publication_id#">Publication Details</a>
	<br>
	<cfquery name="ctpublication_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey)#">
		select publication_type from ctpublication_type order by publication_type
	</cfquery>
	<cfquery name="pub" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey)#">
		select * from publication where publication_id=#publication_id#
	</cfquery>
	<cfquery name="auth" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey)#">
		select
			publication_agent_id,
			publication_agent.agent_id,
			agent_name,
			author_role
		from
			publication_agent,
			preferred_agent_name
		where
			publication_agent.agent_id=preferred_agent_name.agent_id and
			publication_id=#publication_id#
		order by agent_name
	</cfquery>
	<form name="editPub" method="post" action="Publication.cfm">
		<br><input type="button" value="save" class="savBtn" onclick="editPub.action.value='saveEdit';editPub.submit();">
		<input type="hidden" name="publication_id" id="publication_id" value="#pub.publication_id#">
		<input type="hidden" name="action" value="saveEdit">
		<table>
			<tr>
				<td>
					<label class="helpLink" data-helplink="full_citation">Full Citation</label>
					<textarea name="full_citation" id="full_citation" class="reqdClr" rows="3" cols="80">#pub.full_citation#</textarea>
				</td>
				<td>
					<span class="infoLink" onclick="italicize('full_citation')">italicize selected text</span>
					<br><span class="infoLink" onclick="bold('full_citation')">bold selected text</span>
					<br><span class="infoLink" onclick="superscript('full_citation')">superscript selected text</span>
					<br><span class="infoLink" onclick="subscript('full_citation')">subscript selected text</span>
					<br><span class="infoLink" onclick="toProperCase('full_citation')">Proper Case selected text</span>
				</td>
			</tr>
		</table>
		<label for="short_citation" class="helpLink" data-helplink="short_citation">Short Citation</label>
		<input type="text" id="short_citation" name="short_citation" value="#pub.short_citation#" size="80">
		<table>
			<tr>
				<td>
					<label for="publication_type" class="helpLink" data-helplink="publication_type" class="likeLink">Publication Type</label>
					<select name="publication_type" id="publication_type" class="reqdClr">
						<option value=""></option>
						<cfloop query="ctpublication_type">
							<option <cfif publication_type is pub.publication_type> selected="selected" </cfif>
								value="#publication_type#">#publication_type#</option>
						</cfloop>
					</select>
				</td>
				<td>
					<label for="is_peer_reviewed_fg" class="helpLink" data-helplink="peer_review" class="likeLink">Peer Reviewed?</label>
					<select name="is_peer_reviewed_fg" id="is_peer_reviewed_fg" class="reqdClr">
						<option <cfif pub.is_peer_reviewed_fg is 1> selected="selected" </cfif>value="1">yes</option>
						<option <cfif pub.is_peer_reviewed_fg is 0> selected="selected" </cfif>value="0">no</option>
					</select>
				</td>
				<td>
					<label for="published_year" class="helpLink" data-helplink="published_year">Published Year</label>
					<input type="text" name="published_year" id="published_year" value="#pub.published_year#">
				</td>
			</tr>
		</table>
		<label for="doi" class="helpLink" data-helplink="publication_doi">Digital Object Identifier (DOI)</label>
		<input type="text" id="doi" name="doi" value="#pub.doi#" size="80">
		<cfif len(pub.doi) gt 0>
			<a class="infoLink external" target="_blank" href="https://doi.org/#pub.doi#">[ open DOI ]</a>
		<cfelse>
			<a id="addadoiplease" class="red likeLink" onclick="findDOI('#URLEncodedFormat(pub.full_citation)#')">Bah! No DOI! Click this!</a>
		</cfif>
		<label for="pmid" class="helpLink" data-helplink="publication_doi" class="likeLink">PubMed ID (PMID)</label>
		<input type="text" id="pmid" name="pmid" value="#pub.pmid#" size="80">
		<cfif len(pub.pmid) gt 0>
			<a class="infoLink external" target="_blank" href="http://www.ncbi.nlm.nih.gov/pubmed/#pub.pmid#">[ open PubMed ]</a>
		</cfif>
		<label for="publication_loc">Storage Location</label>
		<input type="text" name="publication_loc" id="publication_loc" size="80" value="#pub.publication_loc#">
		<label for="publication_remarks">Remark</label>
		<textarea name="publication_remarks" id="publication_remarks" class="largetextarea">#pub.publication_remarks#</textarea>

		<p></p>
		<span class="helpLink" data-helplink="publication_author">Current Authors</span>
		<table border id="authTab">
			<tr>
				<th>Role</th>
				<th>Name</th>
				<th></th>
			</tr>
			<cfset i=0>
			<cfloop query="auth">
				<cfset i=i+1>
				<input type="hidden" name="agent_id#i#" id="agent_id#i#" value="#agent_id#">
				<input type="hidden" name="publication_agent_id#i#" id="publication_agent_id#i#" value="#publication_agent_id#">
				<tr id="authortr#i#">
					<td>
						<select name="author_role#i#" id="author_role#i#">
							<option <cfif author_role is "author"> selected="selected" </cfif>value="author">author</option>
							<option <cfif author_role is "editor"> selected="selected" </cfif>value="editor">editor</option>
						</select>
					</td>
					<td>
						<input type="text" name="author_name#i#" id="author_name#i#" class="reqdClr" size="50"
							onchange="getAgent('agent_id#i#',this.name,'editPub',this.value)"
		 					onkeypress="return noenter(event);"
		 					value="#agent_name#">
					</td>
					<td>
						<span class="infoLink" onclick="deleteAgent(#i#)">Delete</span>
					</td>
				</tr>
			</cfloop>
			<input type="hidden" name="numberAuthors" id="numberAuthors" value="#i#">
		</table>
		<span class="helpLink" data-helplink="publication_author">Add Authors</span>
		<table border id="authTab" class="newRec">
			<tr>
				<th>Role</th>
				<th>Name</th>
				<th></th>
			</tr>
			<cfset numNewAuths="3">
			<cfloop from="1" to="#numNewAuths#" index="i">
				<input type="hidden" name="n_agent_id#i#" id="n_agent_id#i#">
				<tr id="n_authortr#i#">
					<td>
						<select name="n_author_role#i#" id="n_author_role#i#">
							<option value="author">author</option>
							<option value="editor">editor</option>
						</select>
					</td>
					<td>
						<input type="text" name="n_author_name#i#" id="n_author_name#i#" class="reqdClr" size="50"
							onchange="getAgent('n_agent_id#i#',this.name,'editPub',this.value)"
		 					onkeypress="return noenter(event);">
					</td>
					<td>
						-
					</td>
				</tr>
			</cfloop>
			<input type="hidden" name="numNewAuths" id="numNewAuths" value="#numNewAuths#">
		</table>

		<div class="cellDiv">
			<cfif isdefined("session.roles") and session.roles contains "manage_media">
				<span class="likeLink" id="mediaUpClickThis">Attach/Upload Media</span>
			<cfelse>
				You do not have permission to add Media.
			</cfif>
		</div>
		<div id="pubMediaDv"></div>


			<input type="hidden" name="origNumberLinks" id="origNumberLinks" value="#i#">
			<input type="hidden" name="numberLinks" id="numberLinks" value="#i#">
			<br><input type="button" value="save" class="savBtn" onclick="editPub.action.value='saveEdit';editPub.submit();">
			<input type="button" value="Delete Publication" class="delBtn" onclick="editPub.action.value='deletePub';confirmDelete('editPub');">
	</form>
</cfoutput>
</cfif>
<!---------------------------------------------------------------------------------------------------------->
<cfif action is "deletePub">
	<cftransaction>
		<cfquery name="dpublication_agent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey)#">
			delete from publication_agent where publication_id=#publication_id#
		</cfquery>
		<cfquery name="dpublication" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey)#">
			delete from publication where publication_id=#publication_id#
		</cfquery>
	</cftransaction>
	it's gone.
</cfif>
<!---------------------------------------------------------------------------------------------------------->
<cfif action is "saveEdit">
<cfoutput>
	<cftransaction>
		<cfif len(doi) gt 0>
			<cfinvoke component="/component/functions" method="checkDOI" returnVariable="isok">
				<cfinvokeargument name="doi" value="#doi#">
			</cfinvoke>
			<cfif isok is not "true">
				<cfthrow message = "DOI #doi# failed validation with StatusCode #isok#">
			</cfif>
		</cfif>
		<cfquery name="pub" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey)#">
			update publication set
				published_year=<cfif len(published_year) gt 0>#published_year#<cfelse>NULL</cfif>,
				publication_type='#publication_type#',
				publication_loc='#publication_loc#',
				full_citation='#escapeQuotes(full_citation)#',
				short_citation='#escapeQuotes(short_citation)#',
				publication_remarks='#escapeQuotes(publication_remarks)#',
				is_peer_reviewed_fg=#is_peer_reviewed_fg#,
				doi='#doi#',
				pmid='#pmid#'
			where publication_id=#publication_id#
		</cfquery>
		<cfset noAuthFail=true>
		<cfloop from="1" to="#numberAuthors#" index="n">
			<cfset publication_agent_id = evaluate("publication_agent_id" & n)>
			<cfset agent_id = evaluate("agent_id" & n)>
			<cfset author_role = evaluate("author_role" & n)>
			<cfset author_name = evaluate("author_name" & n)>
			<cfif author_name is "deleted">
				<cfquery name="delAuth" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey)#">
					delete from publication_agent where
					publication_agent_id=#publication_agent_id#
				</cfquery>
			<cfelse>
				<cfset noAuthFail=false>
				<cfquery name="uAuth" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey)#">
					update publication_agent set
						agent_id=#agent_id#,
						author_role='#author_role#'
					where
						publication_agent_id=#publication_agent_id#
				</cfquery>
			</cfif>
		</cfloop>
		<cfloop from="1" to="#numNewAuths#" index="n">
			<cfset agent_id = evaluate("n_agent_id" & n)>
			<cfset author_role = evaluate("n_author_role" & n)>
			<cfif len(agent_id) gt 0>
				<cfset noAuthFail=false>
				<cfquery name="insAuth" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey)#">
					insert into publication_agent (
						publication_id,
						agent_id,
						author_role
					) values (
						#publication_id#,
						#agent_id#,
						'#author_role#'
					)
				</cfquery>
			</cfif>
		</cfloop>
		<cfif noAuthFail is true>
			<cfthrow message="At least one author is required to save publication edits.">
		</cfif>
	</cftransaction>
	<cflocation url="Publication.cfm?action=edit&publication_id=#publication_id#" addtoken="false">
</cfoutput>
</cfif>
<!---------------------------------------------------------------------------------------------------------->
<cfif action is "newPub">
<cfset title = "Create Publication">
	<cfquery name="ctpublication_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey)#">
		select publication_type from ctpublication_type order by publication_type
	</cfquery>
	<style>
		.missing {
			border:2px solid red;
			}
	</style>
	<script>
		function confirmpub() {
			var r=true;
			var msg='';
			$('.missing').removeClass('missing');
			$('.reqdClr').each(function() {
                var thisel=$("#" + this.id)
                if ($(thisel).val().length==0){
                	msg += this.id + ' is required\n';
                	$(thisel).addClass('missing');
                }
        	});
        	if (msg.length>0){
        		alert(msg);
        		return false;
        	} else {
        		if ($("#doi").val().length==0 && $("#pmid").val().length==0){
					msg = 'Please enter a DOI or PMID if one is available for this article is available\n';
					msg+='Click OK to enter a DOI or PMID before creating this article, or Cancel to proceed.\n';
					msg+='There are also tools on the next page to help find DOI.';

					var r = confirm(msg);
					if (r == true) {
					    return false;
					} else {
					    return true;
					}
				}
				return true;
        	}
		}
		function toggleMedia() {
			if($('#media').css('display')=='none') {
				$('#mediaToggle').html('[ Remove Media ]');
				$('#media').show();
				$('#media_uri').addClass('reqdClr');
				$('#preview_uri').addClass('reqdClr');
				$('#mime_type').addClass('reqdClr');
				$('#media_type').addClass('reqdClr');
				$('#media_desc').addClass('reqdClr');
			} else {
				$('#mediaToggle').html('[ Add Media ]');
				$('#media').hide();
				$('#media_uri').val('').removeClass('reqdClr');
				$('#preview_uri').val('').removeClass('reqdClr');
				$('#mime_type').val('').removeClass('reqdClr');
				$('#media_type').val('').removeClass('reqdClr');
				$('#media_desc').val('').removeClass('reqdClr');
			}
		}
		function useThisAuthor (i,name,id) {
			$("#n_agent_id" + i).val(id);
			$("#n_author_name" + i).val(name);
		}
		function getPubMeta(idtype){
			$("#doilookup").html('<image src="/images/indicator.gif">');
			$("#pmidlookup").html('<image src="/images/indicator.gif">');
			$('#doi').val($('#doi').val().trim());
			$('#pmid').val($('#pmid').val().trim());
			if (idtype=='DOI'){
				var identifier=$('#doi').val();
			} else {
				var identifier=$('#pmid').val();
			}
			jQuery.getJSON("/component/functions.cfc",
				{
					method : "getPublication",
					identifier : identifier,
					idtype: idtype,
					returnformat : "json",
					queryformat : 'column'
				},
				function (d) {
					if(d.DATA.STATUS=='success'){
						$("#full_citation").val(d.DATA.LONGCITE);
						$("#short_citation").val(d.DATA.SHORTCITE);
						$("#publication_type").val(d.DATA.PUBLICATIONTYPE);
						$("#is_peer_reviewed_fg").val(1);
						$("#published_year").val(d.DATA.YEAR);
						$("#short_citation").val(d.DATA.SHORTCITE);
						for (i = 1; i<5; i++) {
							$("#authSugg" + i).html('');
							var thisAuthStr=eval("d.DATA.AUTHOR"+i);
							thisAuthStr=String(thisAuthStr);
							if (thisAuthStr.length>0){
								thisAuthAry=thisAuthStr.split("|");
								for (z = 0; z<thisAuthAry.length; z++) {
									var thisAuthRec=thisAuthAry[z].split('@');
									var thisAgentName=thisAuthRec[0];
									var thisAgentID=thisAuthRec[1];
									var thisSuggest='<span class="infoLink" onclick="useThisAuthor(';
									thisSuggest += "'" + i + "','" + thisAgentName + "','" + thisAgentID + "'" + ');"> [ ' + thisAgentName + " ] </span>";
									try {
										$("#authSugg" + i).append(thisSuggest);
									} catch(err){}
								}
							}
						}
						$("#doilookup").html(' [ crossref ] ');
						$("#pmidlookup").html(' [ pubmed ] ');
					} else {
						$("#doilookup").text(' [ crossref ] ');
						$("#pmidlookup").text(' [ pubmed ] ');
						alert(d.DATA.STATUS);
					}
				}
			);
		}
	</script>
	<style>
		#pleaseusethis {
			border:1px solid orange;
			padding:1em;
			margin:1em;
			display: inline-block;
	</style>
	<cfoutput>

		<form name="newpub" method="post" onsubmit="if (!confirmpub()){return false;}" action="Publication.cfm">

			<div id="pleaseusethis">
				<p>
					Please enter a DOI (preferred) or PMID if there is one available. DOIs are extremely valuable in
					documenting collection usage.
				</p>
				<div style="float:right;border:2px solid green;max-width:40%;padding:1em;font-size:smaller;margin:.5em;">
			Paste a DOI (the ID only - no prefix) or PubMed ID in and click the appropriate link to look up
			article metadata. Note that this returns only what was reported by the publisher and that is often imperfect; you are ultimately
			responsible for the Publications you create. (Try DOI=<span class="likeLink" onclick="$('##doi').val('10.1006/mpev.1994.1005');">10.1006/mpev.1994.1005</span>
			 vs. PMID=<span class="likeLink" onclick="$('##pmid').val('8025728');">80257285</span>
			  for an example of potential differences.)
			<p>
				Agent suggestions may be provided. Click them to accept.
			</p>
			<p>
				Shift-reload the page to start over.
			</p>
		</div>
				<label for="doi" class="helpLink" data-helplink="publication_doi">Digital Object Identifier (DOI)</label>
				<input type="text" id="doi" name="doi" value="" size="80">
				<span class="likeLink" id="doilookup" onclick="getPubMeta('DOI');"> [ crossref ] </span>
				<label for="pmid" class="helpLink" data-helplink="publication_doi" class="likeLink">PubMed ID (PMID)</label>
				<input type="text" id="pmid" name="pmid" value="" size="80">
				<span class="likeLink" id="pmidlookup" onclick="getPubMeta('PMID');"> [ pubmed ] </span>
				<input type="hidden" name="action" value="createPub">
			</div>
			<table>
				<tr>
					<td>
						<label for="full_citation" class="helpLink" data-helplink="full_citation">Full Citation</label>
						<textarea name="full_citation" id="full_citation" class="reqdClr" rows="3" cols="80"></textarea>
					</td>
					<td>
						<span class="infoLink" onclick="italicize('full_citation')">italicize selected text</span>
						<br><span class="infoLink" onclick="bold('full_citation')">bold selected text</span>
						<br><span class="infoLink" onclick="superscript('full_citation')">superscript selected text</span>
						<br><span class="infoLink" onclick="subscript('full_citation')">subscript selected text</span>
						<br><span class="infoLink" onclick="toProperCase('full_citation')">Proper Case selected text</span>

					</td>
				</tr>
			</table>
			<label for="short_citation" class="helpLink" data-helplink="short_citation">Short Citation</label>
			<input type="text" id="short_citation" name="short_citation" class="reqdClr" value="" size="80">
			<table>
				<tr>
					<td>
						<label for="publication_type" class="helpLink" data-helplink="publication_type">Publication Type</label>
						<select name="publication_type" id="publication_type" class="reqdClr">
							<option value=""></option>
							<cfloop query="ctpublication_type">
								<option value="#publication_type#">#publication_type#</option>
							</cfloop>
						</select>
					</td>
					<td>
						<label for="is_peer_reviewed_fg" class="helpLink" data-helplink="peer_review">Peer Reviewed?</label>
						<select name="is_peer_reviewed_fg" id="is_peer_reviewed_fg" class="reqdClr">
							<option value="1">yes</option>
							<option value="0">no</option>
						</select>
					</td>
					<td>
						<label for="published_year" class="helpLink" data-helplink="published_year">Published Year</label>
						<input type="text" name="published_year" id="published_year" value="">
					</td>
				</tr>
			</table>
			<label for="publication_loc">Storage Location</label>
			<input type="text" name="publication_loc" id="publication_loc" size="80" value="">
			<label for="publication_remarks">Remark</label>
			<input type="text" name="publication_remarks" id="publication_remarks" size="80" value="">
			<p></p>
			<span class="helpLink" data-helplink="publication_author">Add Authors</span>
			<table border id="authTab" class="newRec">
				<tr>
					<th>Role</th>
					<th>Name</th>
					<th></th>
				</tr>
				<cfset numNewAuths="5">
				<cfloop from="1" to="#numNewAuths#" index="i">
					<input type="hidden" name="n_agent_id#i#" id="n_agent_id#i#">
					<tr id="n_authortr#i#">
						<td>
							<select name="n_author_role#i#" id="n_author_role#i#">
								<option value="author">author</option>
								<option value="editor">editor</option>
							</select>
						</td>
						<td>
							<input type="text" name="n_author_name#i#" id="n_author_name#i#" size="50"
								onchange="getAgent('n_agent_id#i#',this.name,'newpub',this.value)"
			 					onkeypress="return noenter(event);"
			 					<cfif i is 1>class="reqdClr"</cfif>>
						</td>
						<td id="authSugg#i#">
						</td>
					</tr>
				</cfloop>
			</table>
			<input type="hidden" name="numNewAuths" id="numNewAuths" value="#numNewAuths#">
			<br><input type="submit" value="create publication" class="insBtn">
		</form>
	</cfoutput>
</cfif>
<!---------------------------------------------------------------------------------------------------------->
<cfif action is "createPub">
<cfoutput>
	<cftransaction>
		<cfquery name="p" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey)#">
			select sq_publication_id.nextval p from dual
		</cfquery>
		<cfset pid=p.p>
		<cfif len(doi) gt 0>
			<cfinvoke component="/component/functions" method="checkDOI" returnVariable="isok">
				<cfinvokeargument name="doi" value="#doi#">
			</cfinvoke>
			<cfif isok is not "true">
				<cfthrow message = "DOI #doi# failed validation with StatusCode #isok#">
			</cfif>
		</cfif>
		<cfquery name="pub" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey)#">
			insert into publication (
				publication_id,
				published_year,
				publication_type,
				publication_loc,
				full_citation,
				short_citation,
				publication_remarks,
				is_peer_reviewed_fg,
				doi,
				pmid
			) values (
				#pid#,
				<cfif len(published_year) gt 0>#published_year#<cfelse>NULL</cfif>,
				'#publication_type#',
				'#publication_loc#',
				'#escapeQuotes(full_citation)#',
				'#escapeQuotes(short_citation)#',
				'#publication_remarks#',
				#is_peer_reviewed_fg#,
				'#doi#',
				'#pmid#'
			)
		</cfquery>
		<cfloop from="1" to="#numNewAuths#" index="n">
			<cfset agent_id = evaluate("n_agent_id" & n)>
			<cfset author_role = evaluate("n_author_role" & n)>
			<cfif len(agent_id) gt 0>
				<cfquery name="insAuth" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey)#">
					insert into publication_agent (
						publication_id,
						agent_id,
						author_role
					) values (
						#pid#,
						#agent_id#,
						'#author_role#'
					)
				</cfquery>
			</cfif>
		</cfloop>
	</cftransaction>
	<cflocation url="Publication.cfm?action=edit&publication_id=#pid#" addtoken="false">
</cfoutput>
</cfif>
<cfinclude template="includes/_footer.cfm">