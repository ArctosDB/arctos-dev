<!----

create unique index ixu_cf_temp_lbl2contr_bc on cf_temp_lbl2contr (barcode) tablespace uam_idx_1;




UAM@ARCTOS> UAM@ARCTOS> desc cf_temp_lbl2contr
 Name								   Null?    Type
 ----------------------------------------------------------------- -------- --------------------------------------------
 BARCODE							   NOT NULL VARCHAR2(255)
 OLD_CONTAINER_TYPE						   NOT NULL VARCHAR2(255)
 CONTAINER_TYPE 						   NOT NULL VARCHAR2(255)
 DESCRIPTION								    VARCHAR2(255)
 CONTAINER_REMARKS							    VARCHAR2(255)
 HEIGHT 								    NUMBER
 LENGTH 								    NUMBER
 WIDTH									    NUMBER
 NUMBER_POSITIONS							    NUMBER
 STATUS 								    VARCHAR2(255)
 NOTE									    VARCHAR2(4000)
 LABEL									    VARCHAR2(255)


---->
<cfinclude template="/includes/_header.cfm">
<cfset title="Bulk Edit Container">
<cfset thecolumns="BARCODE,LABEL,OLD_CONTAINER_TYPE,CONTAINER_TYPE,DESCRIPTION,CONTAINER_REMARKS,HEIGHT,LENGTH,WIDTH,number_rows,number_columns,orientation,positions_hold_container_type">

<cfif action is "makeTemplate">
	<cfset header=thecolumns>
	<cffile action = "write"
    file = "#Application.webDirectory#/download/BulkContainerEdit.csv"
    output = "#header#"
    addNewLine = "no">
	<cflocation url="/download.cfm?file=BulkContainerEdit.csv" addtoken="false">
</cfif>
<!------------------------------------------------------------------------------------------->
<cfif action is "nothing">
	<p>
		Edit groups of containers by loading CSV.
	</p>
	<p>
		This form is not restricted to labels; it will alter ANY container. That's dangerous; don't use this form unless you are sure of what you're doing.
	</p>
	<p>
		This form will happily overwrite existing <strong><em>important</em></strong> information. Use it with caution and make sure you know what it's doing!
	</p>
	<p>
		Upload CSV with the following columns. <a href="bulkEditContainer.cfm?action=makeTemplate">Get a template</a>
	</p>
	<p>
		<a href="/labels2containers.cfm">Build CSV</a>
	</p>
	<table border>
		<tr>
			<th>Column</th>
			<th>Description</th>
		</tr>
		<tr>
			<td>BARCODE</td>
			<td>Required; must be unique.</td>
		</tr>
		<tr>
			<td>OLD_CONTAINER_TYPE</td>
			<td>Required. <a href="/info/ctDocumentation.cfm?table=CTCONTAINER_TYPE">CTCONTAINER_TYPE</a></td>
		</tr>
		<tr>
			<td>CONTAINER_TYPE</td>
			<td>Required. New container type. <a href="/info/ctDocumentation.cfm?table=CTCONTAINER_TYPE">CTCONTAINER_TYPE</a></td>
		</tr>
		<tr>
			<td>LABEL</td>
			<td>Empty (no value) to ignore, new value to update.</td>
		</tr>
		<tr>
			<td>DESCRIPTION</td>
			<td>"NULL" (no quotes, case-sensitive) will update to NULL; blank will be ignored (no updates).</td>
		</tr>
		<tr>
			<td>CONTAINER_REMARKS</td>
			<td>"NULL" (no quotes, case-sensitive) will update to NULL; blank will be ignored (no updates).</td>
		</tr>
		<tr>
			<td>HEIGHT</td>
			<td>"0" (no quotes) will update to NULL; blank will be ignored (no updates).</td>
		</tr>
		<tr>
			<td>LENGTH</td>
			<td>"0" (no quotes) will update to NULL; blank will be ignored (no updates).</td>
		</tr>
		<tr>
			<td>WIDTH</td>
			<td>"0" (no quotes)  will update to NULL; blank will be ignored (no updates).</td>
		</tr>

		<tr>
			<td>NUMBER_ROWS</td>
			<td>All-or-none position group memeber. "0" (no quotes)  will update to NULL; blank will be ignored (no updates).</td>
		</tr>
		<tr>
			<td>NUMBER_COLUMNS</td>
			<td>All-or-none position group memeber. "0" (no quotes)  will update to NULL; blank will be ignored (no updates).</td>
		</tr>
		<tr>
			<td>ORIENTATION</td>
			<td>All-or-none position group memeber. "0" (no quotes)  will update to NULL; blank will be ignored (no updates).</td>
		</tr>
		<tr>
			<td>POSITIONS_HOLD_CONTAINER_TYPE</td>
			<td>All-or-none position group memeber. "0" (no quotes)  will update to NULL; blank will be ignored (no updates). "horizontal" or "vertical"</td>
		</tr>
	</table>
	<form enctype="multipart/form-data" action="bulkEditContainer.cfm" method="POST">
		<input type="hidden" name="action" value="getFile">
		<label for="FiletoUpload">Upload CSV</label>
		<input type="file" name="FiletoUpload" size="45" onchange="checkCSV(this);">

		<input type="submit" value="Upload this file" class="insBtn">
	</form>
</cfif>
<!------------------------------------------------------------------------------------------->
<cfif action IS "getFile">
	<cfoutput>
		<cfquery name="killOld" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey)#">
			delete from cf_temp_lbl2contr
		</cfquery>
		<cffile action="READ" file="#FiletoUpload#" variable="fileContent">
        <cfset  util = CreateObject("component","component.utilities")>
		<cfset x=util.CSVToQuery(fileContent.Trim())>
        <cfset cols=x.columnlist>
		<cftransaction>
	        <cfloop query="x">
	            <cfquery name="ins" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey)#">
		            insert into cf_temp_lbl2contr (#cols#) values (
		            <cfloop list="#cols#" index="i">
		            		'#stripQuotes(evaluate(i))#'
		            	<cfif i is not listlast(cols)>
		            		,
		            	</cfif>
		            </cfloop>
		            )
	            </cfquery>
	        </cfloop>
		</cftransaction>
		<a href="bulkEditContainer.cfm?action=validateUpload">data loaded - proceed to validation</a>
	</cfoutput>
</cfif>
<!------------------------------------------------------------------------------------------->
<cfif action is "deleteStagingData">
	<cfquery name="killOld" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey)#">
		delete from cf_temp_lbl2contr
	</cfquery>
	<p>
		Data deleted. <a href="bulkEditContainer.cfm">load more</a>
	</p>
</cfif>
<!------------------------------------------------------------------------------------------->
<cfif action IS "validateUpload">
	<script src="/includes/sorttable.js"></script>
	<cfoutput>
		<cfquery name="upsbc" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey)#">
			update
				cf_temp_lbl2contr
			set
				status='barcode_not_found'
			where
				barcode not in (select barcode from container where barcode is not null)
		</cfquery>
		<cfquery name="uasdfasps" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey)#">
			update
				cf_temp_lbl2contr
			set
				status='new/old container type mismatch'
			where
				status is null and
				OLD_CONTAINER_TYPE is null and
				CONTAINER_TYPE is not null
		</cfquery>
		<cfquery name="ups" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey)#">
			update
				cf_temp_lbl2contr
			set
				status='old_container_type_nomatch'
			where
				status is null and
				(barcode,old_container_type) not in (select barcode,container_type from container where barcode is not null)
		</cfquery>
		<cfquery name="upn_descr" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey)#">
			update
				cf_temp_lbl2contr
			set
				note=note || '; ' || 'existing container has description'
			where
				description ='NULL' and
				barcode in (select barcode from container where description is not null)
		</cfquery>

		<cfquery name="upn_r" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey)#">
			update
				cf_temp_lbl2contr
			set
				note=note || '; ' || 'existing container has remark'
			where
				container_remarks='NULL' and
				barcode in (select barcode from container where container_remarks is not null)
		</cfquery>
		<cfquery name="upn_l" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey)#">
			update
				cf_temp_lbl2contr
			set
				note=note || '; ' || 'existing container has length'
			where
				length =0 and
				barcode in (select barcode from container where length is not null)
		</cfquery>
		<cfquery name="upn_h" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey)#">
			update
				cf_temp_lbl2contr
			set
				note=note || '; ' || 'existing container has height'
			where
				height =0 and
				barcode in (select barcode from container where height is not null)
		</cfquery>
		<cfquery name="upn_w" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey)#">
			update
				cf_temp_lbl2contr
			set
				note=note || '; ' || 'existing container has width'
			where
				width =0 and
				barcode in (select barcode from container where width is not null)
		</cfquery>

		<cfquery name="fail" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey)#">
			select count(*) c from cf_temp_lbl2contr where status is not null
		</cfquery>
		<cfif fail.c gt 0>
			There are problems. Fix the data and try again.
		<cfelse>
			Validation complete
			<p>
				Please review the data in the staging table below. Pay special attention to the "note" column - these are not "errors"
				but information here may be an indication that the edit you are about to make is not exactly correct or what you want.
				Instructions for completing the upload or making changes to this data are found at the bottom of the staging table.
			</p>
		</cfif>
		<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey)#">
			select * from cf_temp_lbl2contr
		</cfquery>
		<table border id="t" class="sortable">
			<tr>
				<th>barcode</th>
				<th>label</th>
				<th>status</th>
				<th>note</th>
				<th>old_container_type</th>
				<th>container_type</th>
				<th>description</th>
				<th>container_remarks</th>
				<th>height</th>
				<th>length</th>
				<th>width</th>
				<th>NUMBER_ROWS</th>
				<th>NUMBER_COLUMNS</th>
				<th>ORIENTATION</th>
				<th>POSITIONS_HOLD_CONTAINER_TYPE</th>
			</tr>
			<cfloop query="d">
				<tr>
					<td>#barcode#</td>
					<td>
						<cfif len(label) eq 0>
							NO UPDATE
						<cfelse>
							#label#
						</cfif>
					</td>
					<td>#status#</td>
					<td>#note#</td>
					<td>#old_container_type#</td>
					<td>#container_type#</td>
					<td>
						<cfif len(description) eq 0>
							NO UPDATE
						<cfelse>
							#description#
						</cfif>
					</td>
					<td>
						<cfif len(container_remarks) eq 0>
							NO UPDATE
						<cfelse>
							#container_remarks#
						</cfif>
					</td>
					<td>
						<cfif len(height) eq 0>
							NO UPDATE
						<cfelse>
							#height#
						</cfif>
					</td>
					<td>
						<cfif len(length) eq 0>
							NO UPDATE
						<cfelse>
							#length#
						</cfif>
					</td>
					<td>
						<cfif len(width) eq 0>
							NO UPDATE
						<cfelse>
							#width#
						</cfif>
					</td>
					<td>
						<cfif len(NUMBER_ROWS) eq 0>
							NO UPDATE
						<cfelse>
							#NUMBER_ROWS#
						</cfif>
					</td>
					<td>
						<cfif len(NUMBER_COLUMNS) eq 0>
							NO UPDATE
						<cfelse>
							#NUMBER_COLUMNS#
						</cfif>
					</td>
					<td>
						<cfif len(ORIENTATION) eq 0>
							NO UPDATE
						<cfelse>
							#ORIENTATION#
						</cfif>
					</td>
					<td>
						<cfif len(POSITIONS_HOLD_CONTAINER_TYPE) eq 0>
							NO UPDATE
						<cfelse>
							#POSITIONS_HOLD_CONTAINER_TYPE#
						</cfif>
					</td>
				</tr>
			</cfloop>
		</table>
		<cfif fail.c gt 0>
			<p>
				 The data in the staging table contains errors or does not appear as expected. Delete it from the staging table without uploading.
			</p>
			<form action="bulkEditContainer.cfm">
				<input type="hidden" name="action" value="deleteStagingData">
	    		<input type="submit" class="delBtn" value="Delete Data" />
			</form>

		<cfelse>
			<p>
				The data in the staging table appears as expected. The upload can be finalized and the data deleted from the staging table.
			</p>
			<form action="bulkEditContainer.cfm">
				<input type="hidden" name="action" value="finalizeUpload">
	    		<input type="submit" class="savBtn" value="Make Changes and delete local data" />
			</form>
		</cfif>
	</cfoutput>
</cfif>
<!------------------------------------------>
<cfif action IS "finalizeUpload">
	<cftransaction>
		<cfstoredproc procedure="bulkUpdateContainer" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey)#">
		</cfstoredproc>
		<cfquery name="cleanup" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey)#">
			delete from cf_temp_lbl2contr
		</cfquery>
	</cftransaction>
	all done
</cfif>
<cfinclude template="/includes/_footer.cfm">