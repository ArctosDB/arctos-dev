<!----

	drop table cf_temp_classification;


	create table cf_temp_classification (
		-- admin junk
		status varchar2(4000),
		classification_id varchar2(4000),
		username varchar2(255) not null,
		source  varchar2(255) not null,
		taxon_name_id number,
		-- key AND lowest-ranking classification term
		scientific_name varchar2(255) not null,
		--non-classification terms
		author_text varchar2(255) null,
		infraspecific_author varchar2(255) null,
		nomenclatural_code varchar2(255) null,
		source_authority varchar2(4000) null,
		taxon_status varchar2(255) null,
		remark varchar2(4000),
		--classification terms - MAKE SURE THESE STAY ORDERED
		superkingdom varchar2(255) null,
		kingdom varchar2(255) null,
		subkingdom varchar2(255) null,
		infrakingdom varchar2(255) null,
		superphylum varchar2(255) null,
		phylum varchar2(255) null,
		subphylum varchar2(255) null,
		subdivision varchar2(255) null,
		infraphylum varchar2(255) null,
		superclass varchar2(255) null,
		class varchar2(255) null,
		subclass varchar2(255) null,
		infraclass varchar2(255) null,
		subterclass varchar2(255) null,
		hyperorder varchar2(255) null,
		superorder varchar2(255) null,
		phylorder varchar2(255) null,
		suborder varchar2(255) null,
		infraorder varchar2(255) null,
		hyporder varchar2(255) null,
		subhyporder varchar2(255) null,
		superfamily varchar2(255) null,
		family varchar2(255),
		subfamily varchar2(255) null,
		supertribe varchar2(255) null,
		tribe varchar2(255) null,
		subtribe varchar2(255) null,
		genus varchar2(255) null,
		subgenus varchar2(255) null,
		species varchar2(255) null,
		subspecies varchar2(255) null,
		forma varchar2(255) null,
		variety varchar2(4000)
);

alter table cf_temp_classification add preferred_name varchar2(255);

alter table cf_temp_classification add aphiaid varchar2(255);

alter table cf_temp_classification add epifamily varchar2(255);

create or replace public synonym cf_temp_classification for cf_temp_classification;

grant all on cf_temp_classification to coldfusion_user;


drop index iu_temp_class;
create unique index iu_temp_class on cf_temp_classification(scientific_name) tablespace uam_idx_1;



create or replace trigger trg_cf_temp_classification_key before insert on cf_temp_classification
	FOR EACH ROW
	begin
		if :NEW.username is null then
			select SYS_CONTEXT('USERENV', 'SESSION_USER') into :NEW.username from dual;
		end if;
	end;
/
sho err;


---->
<cfinclude template="/includes/_header.cfm">
<cfset title="Bulkload Classifications">


<!----------------------------------------------------------------->

<cfif action is "getCSV">
<cfoutput>
	<!---- just need a list of columns here --->
	<cfquery name="mine" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey)#">
		select * from CF_TEMP_CLASSIFICATION where 1=2
	</cfquery>

	<cfdump var=#mine#>
	<!--- get column order ---->
	<cfquery name="oClassTerms" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey)#">
		select
			*
		from
			CTTAXON_TERM
		WHERE TAXON_TERM !='display_name'
	</cfquery>

	<cfquery name="cterm" dbtype="query">
		select taxon_term from oClassTerms where IS_CLASSIFICATION=1 order by RELATIVE_POSITION
	</cfquery>
	<cfquery name="ncterm" dbtype="query">
		select taxon_term from oClassTerms where IS_CLASSIFICATION=0 order by taxon_term
	</cfquery>

	<cfset fList=valuelist(cterm.taxon_term)>
	<cfset fList=listappend(fList,'status')>
	<cfset fList=listappend(fList,valuelist(ncterm.taxon_term))>
	<cfset fList=replace(fList,',order,',',phylorder,')>

	<cfset fList=listappend(fList,'source')>


	<cfset BulkTableColList=mine.columnlist>
	<!--- remove admin stuff ---->
	<!----
	---->
		<cfset BulkTableColList=listDeleteAt(BulkTableColList,listfindnocase(BulkTableColList,'USERNAME'))>

	<cfset BulkTableColList=listDeleteAt(BulkTableColList,listfindnocase(BulkTableColList,'TAXON_NAME_ID'))>
	<cfset BulkTableColList=listDeleteAt(BulkTableColList,listfindnocase(BulkTableColList,'CLASSIFICATION_ID'))>



	<!--- make sure everything in the columnlist we just built from the code table is a table row ---->
	<cfloop list="#fList#" index="t">
		<cfif not listfindnocase(BulkTableColList,t)>
			<p>
				#t# is in CTTAXON_TERM and is NOT in CF_TEMP_CLASSIFICATION
			</p>
		</cfif>

	</cfloop>

	<!--- make sure everything in the table is also in the code table (plus the stuff we added up yonder) ---->
	<cfloop list="#BulkTableColList#" index="t">
		<cfif not listfindnocase(fList,t)>
			<p>
				#t# is in CF_TEMP_CLASSIFICATION and is NOT in CTTAXON_TERM - THIS IS FATAL
			</p>
		</cfif>

	</cfloop>

	<cfquery name="mine" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey)#">
		select #fList# from CF_TEMP_CLASSIFICATION where upper(username)='#ucase(session.username)#'
	</cfquery>

	<cfset  util = CreateObject("component","component.utilities")>
	<cfset csv = util.QueryToCSV2(Query=mine,Fields=fList)>
	<cffile action = "write"
	    file = "#Application.webDirectory#/download/BulkloadClassificationData.csv"
    	output = "#csv#"
    	addNewLine = "no">
	<cflocation url="/download.cfm?file=BulkloadClassificationData.csv" addtoken="false">
	<a href="/download.cfm?file=BulkloadClassificationData.csv">BulkloadClassificationData.csv</a>
</cfoutput>
</cfif>
<!----------------------------------------------------------------->
<cfif action is "setstatus">
	<cfoutput>
		  <cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey)#">
			update CF_TEMP_CLASSIFICATION set status='#status#' where upper(username)='#ucase(session.username)#'
		</cfquery>
		<cflocation url="BulkloadClassification.cfm?action=nothing" addtoken="false">
	</cfoutput>
</cfif>

<!----------------------------------------------------------------->
<cfif action is "pullNewNames">
	<cfoutput>
		<!--- this is way faster as a bunch nested queries for some weird reason --->
		<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey)#">
			select scientific_name from CF_TEMP_CLASSIFICATION where  upper(username)='#ucase(session.username)#' and
			scientific_name not in (select scientific_name from taxon_name) order by scientific_name
		</cfquery>
		<cfset  util = CreateObject("component","component.utilities")>
		<cfset csv = util.QueryToCSV2(Query=d,Fields=d.columnlist)>
		<cffile action = "write"
		    file = "#Application.webDirectory#/download/ClassificationNamesNotInArctos.csv"
	    	output = "#csv#"
	    	addNewLine = "no">
		<cflocation url="/download.cfm?file=ClassificationNamesNotInArctos.csv" addtoken="false">
		<a href="/download.cfm?file=ClassificationNamesNotInArctos.csv">ClassificationNamesNotInArctos.csv</a>
	</cfoutput>
</cfif>

<!----------------------------------------------------------------->
<cfif action is "getUsingCollectionContacts">
	<cfoutput>
		<!--- this is way faster as a bunch nested queries for some weird reason --->
		<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey)#">
			select addr from (
				select
					get_address(CONTACT_AGENT_ID,'email',1) addr
				from
					collection_contacts
				where
					CONTACT_ROLE='data quality' and
					COLLECTION_ID in (
						select collection_id from collection where preferred_taxonomy_source in (
							select source  from CF_TEMP_CLASSIFICATION where upper(username)='#ucase(session.username)#'
						) and
						collection_id in (
							select collection_id from cataloged_item where collection_object_id  in (
								select COLLECTION_OBJECT_ID from identification where identification_id in (
									select  identification_id from identification_taxonomy where taxon_name_id in (
										select taxon_name_id from CF_TEMP_CLASSIFICATION where upper(username)='#ucase(session.username)#'
									)
								)
							) group by collection_id
						) group by collection_id
					)
				)
			where
				addr is not null
			group by
				addr
		</cfquery>
		<cfset al=''>
		<cfloop query="d">
			<cfset al=listappend(al,addr)>
		</cfloop>
		<p>
		"data quality" contact email for collections using taxa in your bulkloader
		</p>
		<br>
		<textarea class="hugetextarea">#al#</textarea>
	</cfoutput>
</cfif>



<!----------------------------------------------------------------->
<cfif action is "nothing">
	<cfoutput>

		<p>
			Important: This form is new and scary, and none of the automation yet automates. Use the contact link below if you need
			to update classifications.

			<!--- see /ScheduledTasks/processBulkloadClassification.cfm ---->
		</p>
		<p>
			This form REPLACES classifications; ALL classifications at the intersection of taxon_name.scientific_name and the source
			from these data will be DELETED and replaced with these data.
		<p>
		<p>
			Multiple classification warnings may be an indication of someone trying to create homonyms or similar. Check and preserve
			the data elsewhere if possible.
		</p>
		<p>
			<a href="BulkloadClassification.cfm?action=getUsingCollectionContacts">[ getUsingCollectionContacts ]</a>
			- get email addresses of active 'data quality' contacts for collections which use "your" taxa in specimen identifications
		</p>
		<p>
			<a href="BulkloadClassification.cfm?action=makeTemplate">[ Get a Template ]</a> and view column descriptions
		</p>
		<p>
			<a href="BulkloadClassification.cfm?action=getCSV">Download all of your data</a>. Do this often as a backup.
		</p>
		<p>
			<a href="BulkloadClassification.cfm?action=pullNewNames">Download names which are not in Arctos.</a>. These can be created after vetting.
		</p>
		<p>
			<a href="BulkloadClassification.cfm?action=deletemystuff">Delete all of your data</a>. Do this before re-loading
			something you've downloaded and fixed.
		</p>
		<p>
			Load (more) data. This is additive; you may want to delete first.
			<cfform name="oids" method="post" enctype="multipart/form-data" action="BulkloadClassification.cfm">
				<input type="hidden" name="action" value="getFileData">
				<label for="">Load CSV. Will APPEND to existing data. Check "Count" in the table below.</label>
				<input type="file" name="FiletoUpload" size="45" onchange="checkCSV(this);">
				<input type="submit" value="Upload this file">
			</cfform>

			<p>
				The selected File name will be shown until it is uploaded.  Then the status will return to "no file selected."
				No need to select it again.
			</p>
		</p>
		<!-----
		<p>
			Display_Name is required. You may <a href="BulkloadClassification.cfm?action=getDisplayName">autogenerate display_name</a>.
			This may produce strange data; carefully verify the results of this operation. This will NOT over-write anything
			already in
			display_name; download CSV, remove display_name, and re-upload to accomplish that.
		</p>
		----->

		<p>
			<a href="BulkloadClassification.cfm?action=doEverything">Flag to run all data checks</a>: After creating what you believe to
			 be valid records, you should verify them.
			This will catch (most) problems which would prevent a record from loading, and many potential problems or inconsistencies
			which you
			may not wish to introduce into the data.
			<!----
			If you plan to
			fill_in_the_blanks_from_genus (e.g., fetch species and subspecies level data to make consistent
			through this tool), you should verify before and after that step.
			---->
			 You should verify after
			you've changed anything. This can be a slow (ca. 400 records/minute)
				process; check status summary by reloading this page, and contact a DBA if nothing seems to be happening.
				<p style='font-size:x-small;margin-left:2em;'>
					/ScheduledTasks/processBulkloadClassification.cfm?action=doEverything
				</p>
		</p>
		<p>
			This form will NOT create names. This form REPLACES classifications; that is all.
		</p>
		<p>
			"WillBeLost classifications" errors are advisory indications of funky terms (those not in CTTAXON_TERM) in
			 existing data.
			Check that the data which will be lost is retained in a known term in your bulkload.
		</p>
		<p>
			When the data checks are complete and accurate, the Status bar will read "go_go_all."
			Reload page and Status Bar will begin to list errors or show that checks have passed.
			If necessary Download your data, correct errors, delete data and reload corrected data.
			Reload page until the Status bar reads "all_checks_passed." Marking to load when the Status bar
			reads "go_go_all" will result in errors.

		</p>

		<p>

			<a href="BulkloadClassification.cfm?action=markToLoad">Mark to load</a>:

			When the Status bar reads "all_checks_passed, click this to flag for loading.
			Status bar will read "ready_to_load." Reload this page until it reads "made_updates_all done."
			Delete all of your data using above link.
			<p style='font-size:x-small;margin-left:2em;'>
				/ScheduledTasks/processBulkloadClassification.cfm?action=load
			</p>
		</p>

		<!----
		weird bug-thing just confuses people
		<li>
			<a href="BulkloadClassification.cfm?action=setstatus&status=fill_in_the_blanks_from_genus">fill_in_the_blanks_from_genus</a>.
			Use this to set status of ALL of your data to "fill_in_the_blanks_from_genus." This will cause Arctos to insert species
			and subspecies
			data, and to fill in any gaps in the genus-only source record. Check stats below before clicking;
			 this force-overwrites anything in STATUS.
		</li>
		---->




<!------

		<p>
			SUMMARY: One way of using this form
			<ol>
				<li>Load some data</li>
				<li>Click "" if necessa</li>
				<li>Click the 'Flag to run all data checks' link</li>
				<li>Ensure that all records have been flagged for check (status "go_go_all")</li>
				<li></li>
				<li>Download everything</li>
				<li>Fix any problems</li>
				<li>Delete, re-upload</li>
				<li>Run consistency check (because things happen, esp. when eg., Excel is involved)</li>
				<li>Runse and repeat until 'consistency_check_passed' on everything</li>
				<li>Move on to the next check; repeat if anything might have broken the consistency checker.</li>
			</ol>



			Many of the checks below may not be combined with other checks. For example, clicking Check for consistency
			will set STATUS of <strong>all</strong> records to "go_go_check_consistency." The consistency checker will ignore
			anything without a flagged status, and when done (which may take several days for large datasets) will leave no
			records with that status. Doing anything else during the process will reset everything. The entire procedure for checking
			consistency is therefore:
			<ol>
				<li>Load some data</li>
				<li>Click the 'Check for consistency' link</li>
				<li>Ensure that all records have been processed (status 'inconsistency detected...' or 'consistency_check_passed')</li>
				<li>Download everything</li>
				<li>Fix any problems</li>
				<li>Delete, re-upload</li>
				<li>Run consistency check (because things happen, esp. when eg., Excel is involved)</li>
				<li>Runse and repeat until 'consistency_check_passed' on everything</li>
				<li>Move on to the next check; repeat if anything might have broken the consistency checker.</li>
			</ol>
			------->
		<!----
		<p>
			<a href="BulkloadClassification.cfm?action=checkConsistency">Check for consistency</a>. This will flag records which appear
			to have inconsistent "hierarchies" - eg, one genus --> two families.
		</p>




		<p>
			<a href="BulkloadClassification.cfm?action=checkGaps">Check for gaps</a>. This will
			find data in Arctos which has no place in this loader; these data will be lost if the
			data are loaded as-is. This will time out for large (few thousand) datasets; send us an email.
			<br>Note: fill_in_the_blanks_from_genus contains this functionality; the check is not necessary if you're
			filling in blanks.
		</p>

		<p>
			<a href="BulkloadClassification.cfm?action=sciname_valid_check">sciname_valid_check</a>. This will
			check for scientific_names which do not seem to be valid (mostly formatting).
		</p>




		<p>
			<a href="BulkloadClassification.cfm?action=sciname_weird_check">Check for sciname_weird_check</a>. This will flag records where the
			scientific name does not look correct, generally meaning that scientific_name != {lowest-ranking non-NULL term}.
		</p>



		<p>
			The following options are slow, and so are performed asynchronously. Clicking these links simply updates STATUS.
			Check status below for progress.
			<ul>
				<li>
					<a href="BulkloadClassification.cfm?action=setstatus&status=fill_in_the_blanks_from_genus">fill_in_the_blanks_from_genus</a>.
					Use this to set status of ALL of your data to "fill_in_the_blanks_from_genus." This will cause Arctos to insert species
					and subspecies
					data, and to fill in any gaps in the genus-only source record. Check stats below before clicking;
					 this force-overwrites anything in STATUS.
				</li>
				<li>
					<a href="BulkloadClassification.cfm?action=setstatus&status=ready_to_check">Mark to process</a>.
					Use this to begin pre-load processing. Use this AFTER fill_in_the_blanks_from_genus and
					autogenerate display_name. Check stats below before clicking;
					 this force-overwrites anything in STATUS.
				</li>
				<li>
					use the contact form to actually load
				</li>
			</ul>
		</p>

		---->
		<cfquery name="summary" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey)#">
			select
				status,
				count(*) c from CF_TEMP_CLASSIFICATION where upper(username)='#ucase(session.username)#'
			group by status
		</cfquery>
		<cfquery name="tot" dbtype="query">
			select sum(c) s from summary
		</cfquery>
		<p>
			Summary:
			<table border>
				<tr>
					<th>Status</th>
					<th>Count</th>
				</tr>
				<cfloop query="summary">
					<tr>
						<td>#status#</td>
						<td>#c#</td>
					</tr>
				</cfloop>
				<tr>
					<td>
						<div style="align:right;font-weight:bold">Total</div>
					</td>
					<td><div style="font-weight:bold">#tot.s#</div></td>
				</tr>
			</table>
		</p>
		<!----
		toobookoo

		<cfquery name="dbcols" datasource="uam_god">
			select
				column_name
			from
				user_tab_cols
			where
				upper(table_name)='CF_TEMP_CLASSIFICATION' and
				lower(column_name) not in ('taxon_name_id','classification_id')
			ORDER BY INTERNAL_COLUMN_ID
		</cfquery>


		<table border>
			<tr>
			<cfloop query="dbcols">
				<th>#column_name#</th>
			</cfloop>
			</tr>
			<cfloop query="d">
				<tr>
					<cfloop query="dbcols">
						<td>#evaluate("d." & column_name)#</td>
					</cfloop>
				</tr>
			</cfloop>
		</table>
		---->
	</cfoutput>
</cfif>
<!----------------------------------------------------------------->
<cfif action is "sciname_weird_check">
        <cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey)#">
			update CF_TEMP_CLASSIFICATION set status='sciname_weird_check' where upper(username)='#ucase(session.username)#'
		</cfquery>
		<p>
			Records have been flagged for sciname_weird_check.

			 Check back later, or ScheduledTasks/processBulkloadClassification.cfm
			if you're comfortable in and have rights to ScheduledTasks
		</p>
		<p>
			<a href="BulkloadClassification.cfm">continue</a>
		</p>
</cfif>
<!----------------------------------------------------------------->
<cfif action is "doEverything">
        <cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey)#">
			update CF_TEMP_CLASSIFICATION set status='go_go_all' where upper(username)='#ucase(session.username)#'
		</cfquery>
		<p>
			Records have been flagged for doEverything.

			 Check back later, or ScheduledTasks/processBulkloadClassification.cfm
			if you're comfortable in and have rights to ScheduledTasks
		</p>
		<p>
			<a href="BulkloadClassification.cfm">continue</a>
		</p>
</cfif>
<!----------------------------------------------------------------->
<cfif action is "markToLoad">
        <cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey)#">
			update CF_TEMP_CLASSIFICATION set status='ready_to_load' where upper(username)='#ucase(session.username)#'
		</cfquery>
		<p>
			Records have been flagged to load.

			 Check back later, or ScheduledTasks/processBulkloadClassification.cfm
			if you're comfortable in and have rights to ScheduledTasks
		</p>
		<p>
			<a href="BulkloadClassification.cfm">continue</a>
		</p>
</cfif>


<!----------------------------------------------------------------->
<cfif action is "sciname_valid_check">
        <cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey)#">
			update CF_TEMP_CLASSIFICATION set status='sciname_valid_check' where upper(username)='#ucase(session.username)#'
		</cfquery>
		<p>
			Records have been flagged for sciname_valid_check.

			 Check back later, or ScheduledTasks/processBulkloadClassification.cfm
			if you're comfortable in and have rights to ScheduledTasks
		</p>
		<p>
			<a href="BulkloadClassification.cfm">continue</a>
		</p>
</cfif>
<!----------------------------------------------------------------->
<cfif action is "checkConsistency">
        <cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey)#">
			update CF_TEMP_CLASSIFICATION set status='go_go_check_consistency' where upper(username)='#ucase(session.username)#'
		</cfquery>
		<p>
			Records have been flagged for consistency check. Check back later, or ScheduledTasks/processBulkloadClassification.cfm
			if you're comfortable in and have rights to ScheduledTasks
		</p>
		<p>
			<a href="BulkloadClassification.cfm">continue</a>
		</p>

</cfif>
<!----------------------------------------------------------------->
<cfif action is "deletemystuff">
	<cfoutput>
        <cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey)#">
			delete from CF_TEMP_CLASSIFICATION where upper(username)='#ucase(session.username)#'
		</cfquery>
		<cflocation url="BulkloadClassification.cfm?action=nothing" addtoken="false">
	</cfoutput>
</cfif>
<!----------------------------------------------------------------->


<!-----

this is deprecated

<cfif action is "getDisplayName">
	<p>
		Timeout errors below? Just reload (or <a href="/contact">contact us</a> if that doesn't help).
	</p>
	<cfoutput>
	    <cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey)#">
			select * from CF_TEMP_CLASSIFICATION where upper(username)='#ucase(session.username)#'
			and display_name is null
		</cfquery>

        <cfloop query="d">
			<cftransaction>
			<cfset problem="">
			<!---- infraspecific crap ---->
			<cfif len(genus) gt 0>
				<cfset ist="">
				<cfset irnk="">
				<!--- check for infraspecific data ---->
				<cfif len(forma) gt 0 or len(subsp) gt 0 or len(subspecies) gt 0>
					<cfif len(genus) is 0 or len(species) is 0>
						<cfset problem="infraspecific terms must be accompanied by genus and species">
					<cfelse>
						<cfif len(forma) gt 0>
							<cfset ist=forma>
							<cfset irnk="forma">
						<cfelseif len(subspecies) gt 0>
							<cfset ist=subspecies>
						<cfelseif len(subsp) gt 0>
							<cfset ist=subsp>
							<cfset irnk="subsp.">
						</cfif>
					</cfif>
				</cfif>
				<cfif nomenclatural_code is "ICZN">
					<cfset dname='<i>' & genus & ' ' & species & ' ' & ist & '</i> ' & author_text>
				<cfelse>
					<cfset dname='<i>' & genus & ' ' & species & '</i> ' & author_text & ' ' & irnk & ' ' & ' <i>' & ist & '</i> ' & infraspecific_author>
				</cfif>
			<cfelse>
				<!--- no genus just use scientificname --->
				<cfset dname=scientific_name>
			</cfif>
			<cfset dname=rereplace(dname,'\s\s+','','All')>
			<cfset dname=replace(dname,'<i></i>','','All')>
			<cfset dname=replace(dname,' </i>','</i>','All')>
			<cfset dname=trim(dname)>
			<cfif len(problem) gt 0>
	    		<cfquery name="p" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey)#">
					update CF_TEMP_CLASSIFICATION set status='Autogen DisplayName: #problem#' where scientific_name='#scientific_name#'
				</cfquery>
			<cfelse>
	    		<cfquery name="p" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey)#">
					update CF_TEMP_CLASSIFICATION set display_name='#dname#' where scientific_name='#scientific_name#'
				</cfquery>
			</cfif>
			</cftransaction>
        </cfloop>
		<p>
			all done. Back to <a href="BulkloadClassification.cfm?action=nothing">manage</a>
		</p>
	</cfoutput>
</cfif>

----->
<!----------------------------------------------------------------->
<cfif action is "getFileData">
	<cfoutput>
		<cffile action="READ" file="#FiletoUpload#" variable="fileContent">
        <cfset  util = CreateObject("component","component.utilities")>
		<cfset x=util.CSVToQuery(fileContent)>
        <cfset cols=x.columnlist>
        <cfloop query="x">
            <cfquery name="ins" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey)#">
	            insert into CF_TEMP_CLASSIFICATION (#cols#) values (
	            <cfloop list="#cols#" index="i">
	            		'#stripQuotes(evaluate(i))#'
	            	<cfif i is not listlast(cols)>
	            		,
	            	</cfif>
	            </cfloop>
	            )
            </cfquery>
        </cfloop>
		<cflocation url="BulkloadClassification.cfm?action=nothing" addtoken="false">
	</cfoutput>
</cfif>
<!----------------------------------------------------------------->
<cfif action is "makeTemplate">
	<ul>
		<li>scientific_name is globally-unique; coordinate with other users if there's a conflict.</li>
		<li>subgeneric terms are multinomial. Sorex cinereus, NOT cinereus.</li>
		<li>Terms are defined at is <a href="/info/ctDocumentation.cfm?table=CTTAXON_TERM">CTTAXON_TERM</a></li>
		<li>username is required and must match your Arctos username</li>
		<li>
			Source (NOT source_authority) is required and must be from
			<a href="/info/ctDocumentation.cfm?table=CTTAXONOMY_SOURCE">CTTAXONOMY_SOURCE</a>
		</li>
		<li>nomenclatural_code is required and must be one of (ICZN, ICBN)</li>
		<li>
			"classification" is defined as the intersection of source and scientific_name. This tool REPLACES entire
			classifications (but see the fill_in_the_blanks_from_genus option)
		</li>
		<li>
			If multiple classifications exist (e.g., two sets of data in the "Arctos" classification for
			 <i>Some name</i>), an error will be thrown and no
			updates will be performed.
		</li>
		<li>Only one infraspecific term may be given; "subsp" and "forma" may not both exist in the same record</li>
	</ul>
	<cfquery name="dbcols" datasource="uam_god">
		select
			column_name
		from
			user_tab_cols
		where
			upper(table_name)='CF_TEMP_CLASSIFICATION' and
			lower(column_name) not in ('status','taxon_name_id','classification_id')
		ORDER BY INTERNAL_COLUMN_ID
	</cfquery>
	<cfset thecolumns="">
	<cfloop query="dbcols">
		<cfset thecolumns=listappend(thecolumns,column_name)>
	</cfloop>
	<cfset header=thecolumns>
	<cffile action = "write"
	    file = "#Application.webDirectory#/download/BulkloadClassification.csv"
	    output = "#header#"
	    addNewLine = "no">
	<a href="/download.cfm?file=BulkloadClassification.csv">get the template</a>
</cfif>
<!----------------------------------------------------------------->
<cfif action is "checkGaps">
	  <cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey)#">
			update CF_TEMP_CLASSIFICATION set status='go_go_gap_checker' where upper(username)='#ucase(session.username)#'
		</cfquery>
		<p>
			Records have been flagged for gap check. Check back later, or ScheduledTasks/processBulkloadClassification.cfm
			if you're comfortable in and have rights to ScheduledTasks
		</p>
		<p>
			<a href="BulkloadClassification.cfm">continue</a>
		</p>
</cfif>
<cfinclude template="/includes/_footer.cfm">