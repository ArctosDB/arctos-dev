<cfset title="Publications By Collection">
<cfinclude template="/includes/_header.cfm">
<script src="/includes/sorttable.js"></script>
<cfquery name="ctcollection" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
	select guid_prefix,collection_id from collection order by guid_prefix
</cfquery>
<cfif not isdefined("collection_id")>
	<cfset collection_id="">
</cfif>
<cfif not isdefined("peerr")>
	<cfset peerr="">
</cfif>

<cfif collection_id is "-1''">
	<cfset bl_reason="-1 collection_id">
	<cfinclude template="/errors/blocked.cfm">
	<cfabort>
</cfif>
<cfif not isdefined("citationonly")>
	<cfset citationonly=true>
</cfif>
<cfoutput>
<form name="f" method="get" action="publicationbycollection.cfm">
	<label for="collection_id">Collection</label>
	<select name="collection_id" id="collection_id" size="1">
		<cfset thiscollectionid=collection_id>
		<cfloop query="ctcollection">
			<option <cfif thiscollectionid is ctcollection.collection_id> selected="selected" </cfif>
				value="#ctcollection.collection_id#">#ctcollection.guid_prefix#</option>
		</cfloop>
	</select>
	<label for="citationonly">Show publications related by ....</label>
	<select name="citationonly" id="citationonly" size="1">
		<option <cfif citationonly is true> selected="selected" </cfif> value="true">citations only</option>
		<option <cfif citationonly is false> selected="selected" </cfif> value="false">citations and projects</option>
	</select>
	<label for="peerr">
		Peer Reviewed</label>
	<select name="peerr" id="peerr" size="1">
		<option value="">All</option>
		<option <cfif peerr is true> selected="selected" </cfif> value="true">Peer Reviewed Only</option>
		<option <cfif peerr is false> selected="selected" </cfif> value="false">NOT Peer Reviewed Only</option>
	</select>
	<p />
	<input type="submit" class="lnkBtn" value="Find Publications">
</form>

<cfif len(collection_id) gt 0>
	<cfquery name="citations" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
		select
			FULL_CITATION,
			publication_id,
			linkage,
			DOI,
			PMID,
			transaction_id,
			IS_PEER_REVIEWED,
			c
			from (
			select
				FULL_CITATION,
				publication.publication_id,
				'citation' linkage,
				DOI,
				PMID,
				0 transaction_id,
				case IS_PEER_REVIEWED_FG when 0 then 'no' else 'yes' end IS_PEER_REVIEWED,
				count(*) c
			from
				publication,
				citation,
				cataloged_item
			where
				publication.publication_id=citation.publication_id and
				citation.collection_object_id=cataloged_item.collection_object_id and
				cataloged_item.collection_id=
				<cfqueryparam value = "#collection_id#" CFSQLType = "CF_SQL_NUMERIC" list = "yes" separator = ",">
			group by
				FULL_CITATION,
				publication.publication_id,
				DOI,
				PMID,
				case IS_PEER_REVIEWED_FG when 0 then 'no' else 'yes' end
			<cfif citationonly is false>
				union
				select
					FULL_CITATION,
					publication.publication_id,
					'accession project' linkage,
					DOI,
					PMID,
					cataloged_item.ACCN_ID transaction_id,
					case IS_PEER_REVIEWED_FG when 0 then 'no' else 'yes' end IS_PEER_REVIEWED,,
					count(*) c
				from
					publication,
					project_publication,
					project_trans,
					cataloged_item
				where
					publication.publication_id=project_publication.publication_id and
					project_publication.PROJECT_ID=project_trans.PROJECT_ID and
					project_trans.TRANSACTION_ID=cataloged_item.ACCN_ID and
					cataloged_item.collection_id=<cfqueryparam value = "#collection_id#" CFSQLType = "CF_SQL_NUMERIC" list = "yes" separator = ",">
				group by
					FULL_CITATION,
					publication.publication_id,
					'accession project',
					DOI,
					PMID,
					cataloged_item.ACCN_ID,
					case IS_PEER_REVIEWED_FG when 0 then 'no' else 'yes' end IS_PEER_REVIEWED,
				union
				select
					FULL_CITATION,
					publication.publication_id,
					'specimen loan' linkage,
					DOI,
					PMID,
					loan_item.transaction_id,
					case IS_PEER_REVIEWED_FG when 0 then 'no' else 'yes' end IS_PEER_REVIEWED,
					count(*) c
				from
					publication,
					project_publication,
					project_trans,
					loan_item,
					specimen_part,
					cataloged_item
				where
					publication.publication_id=project_publication.publication_id and
					project_publication.PROJECT_ID=project_trans.PROJECT_ID and
					project_trans.TRANSACTION_ID=loan_item.TRANSACTION_ID and
					loan_item.part_id=specimen_part.COLLECTION_OBJECT_ID and
					specimen_part.derived_from_cat_item=cataloged_item.COLLECTION_OBJECT_ID and
					cataloged_item.collection_id=<cfqueryparam value = "#collection_id#" CFSQLType = "CF_SQL_NUMERIC" list = "yes" separator = ",">
				group by
					FULL_CITATION,
					publication.publication_id,
					'specimen loan',
					DOI,
					PMID,
					loan_item.transaction_id,
					case IS_PEER_REVIEWED_FG when 0 then 'no' else 'yes' end
				union
				select
					FULL_CITATION,
					publication.publication_id,
					'data loan' linkage,
					DOI,
					PMID,
					loan_item.transaction_id,
					case IS_PEER_REVIEWED_FG when 0 then 'no' else 'yes' end IS_PEER_REVIEWED,
					count(*) c
				from
					publication,
					project_publication,
					project_trans,
					loan_item,
					cataloged_item
				where
					publication.publication_id=project_publication.publication_id and
					project_publication.PROJECT_ID=project_trans.PROJECT_ID and
					project_trans.TRANSACTION_ID=loan_item.TRANSACTION_ID and
					loan_item.cataloged_item_id=cataloged_item.COLLECTION_OBJECT_ID and
					cataloged_item.collection_id=<cfqueryparam value = "#collection_id#" CFSQLType = "CF_SQL_NUMERIC" list = "yes" separator = ",">
				group by
					FULL_CITATION,
					publication.publication_id,
					'data loan',
					DOI,
					PMID,
					loan_item.transaction_id,
					case IS_PEER_REVIEWED_FG when 0 then 'no' else 'yes' end
			</cfif>
		) x
		<cfif peerr is true>
			where IS_PEER_REVIEWED='yes'
		<cfelseif peerr is false>
			where IS_PEER_REVIEWED='no'
		</cfif>
		group by
			FULL_CITATION,
			publication_id,
			linkage,
			DOI,
			PMID,
			transaction_id,
			IS_PEER_REVIEWED,
			c
	</cfquery>
	<cfif citations.recordcount lt 1>
		nothing found<cfabort>
	</cfif>
	<cfquery name="pubs" dbtype="query">
		select
			FULL_CITATION,
			publication_id,
			DOI,
			PMID,
			IS_PEER_REVIEWED
		from
			citations
		group by
			FULL_CITATION,
			publication_id,
			DOI,
			PMID,
			IS_PEER_REVIEWED
		order by
			full_citation
	</cfquery>
	<cfquery name="coln" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
		select guid_prefix from collection where collection_id=#collection_id#
	</cfquery>
	<cfquery name="countcitations" dbtype="query">
		select sum(c) n from citations where linkage='citation'
	</cfquery>

	<br>#pubs.recordcount# publications containing #countcitations.n# direct citations that reference the #coln.guid_prefix# collection.
	<table border id="t" class="sortable">
		<tr>
			<th>Publication</th>
			<th>Details</th>
			<th>DOI</th>
			<th>PMID</th>
			<th>PeerReview?</th>
			<th>Google&nbsp;Scholar</th>
			<th>Citations</th>
			<cfif citationonly is false>
				<th>Other&nbsp;Specimens</th>
			</cfif>
		</tr>
		<cfloop query="pubs">
			<tr>
				<td>#full_citation#</td>
				<td><a href="/publication/#publication_id#">detail</a></td>
				<td><a href="#doi#">#doi#</a></td>
				<td><a href="http://www.ncbi.nlm.nih.gov/pubmed/?term=#pmid#">#pmid#</a></td>
				<td>#IS_PEER_REVIEWED#</td>
				<td><a href="http://scholar.google.com/scholar?hl=en&q=#FULL_CITATION#">[ search ]</a></td>
				<cfquery name="citation" dbtype="query">
					select
						c
					from
						citations
					where
						publication_id=#publication_id# and
						linkage='citation'
				</cfquery>

				<td>
					<cfif citation.recordcount gt 0>
						<a href="/search.cfm?publication_id=#publication_id#">#citation.c#&nbsp;specimens</a>
					</cfif>
				</td>
				<cfif citationonly is false>
					<td>
						<cfquery name="acnproj" dbtype="query">
							select
								transaction_id
							from
								citations
							where
								publication_id=#publication_id# and
								linkage='accession project' and
								c>0
							group by
								transaction_id
						</cfquery>
						<cfif acnproj.recordcount gt 0>
							<a href="/search.cfm?accn_trans_id=#valuelist(acnproj.transaction_id)#&collection_id=#collection_id#">
								Specimens accessioned by projects which reference this publication
							</a><br>
						</cfif>
						<cfquery name="loanproj" dbtype="query">
							select
								transaction_id
							from
								citations
							where
								publication_id=#publication_id# and
								linkage in ('specimen loan','data loan') and
								c>0
							group by transaction_id
						</cfquery>
						<cfif loanproj.recordcount gt 0>
							<a href="/search.cfm?loan_trans_id=#valuelist(loanproj.transaction_id)#&collection_id=#collection_id#">
								Specimens used by projects which reference this publication
							</a>
						</cfif>
					</td>
				</cfif>
				</td>
			</tr>
		</cfloop>
	</table>
</cfif>
	</cfoutput>
	<cfinclude template="/includes/_footer.cfm">
