<cfinclude template="/includes/_header.cfm">
<!---
drop table cf_temp_unload_data_loan_item;

create table cf_temp_unload_data_loan_item (
 	KEY NUMBER,
 	guid VARCHAR2(30),
	LOAN_number VARCHAR2(30),
	loan_guid_prefix VARCHAR2(30),
	collection_object_id number,
	transaction_id number,
	status varchar2(255)
);



create or replace public synonym cf_temp_unload_data_loan_item for cf_temp_unload_data_loan_item;
grant all on cf_temp_unload_data_loan_item to manage_transactions;

 CREATE OR REPLACE TRIGGER cf_tmp_unl_dt_ln_item_key
 before insert  ON cf_temp_unload_data_loan_item
 for each row
    begin
    	if :NEW.key is null then
    		select somerandomsequence.nextval into :new.key from dual;
    	end if;
    end;
/
sho err
--->
<cfset title="UnLoad Cataloged Item Loans">

<cfif action is "nothing">
	<cfoutput>
		<p>
		REMOVE items from data loans
		</p>
		Step 1: Upload a file comma-delimited text file (CSV) in the following format. Include column headers. <a href="DataLoanBulkUnload.cfm?action=makeTemplate">Get a template</a>

		<ul>
			<li>guid ("DWC Triplet" eg, "UAM:Mamm:12"; required)</li>
			<li>loan_guid_prefix (collection owning the loan, eg, UAM:Mamm)</li>
			<li>Loan_Number (required)</li>
		</ul>
	</cfoutput>

	<p>
		<div id="template">
			<textarea rows="2" cols="80" id="t">guid,loan_guid_prefix,loan_number</textarea>
		</div>
	</p>
	<form name="dlul" method="post" enctype="multipart/form-data" action="DataLoanBulkUnload.cfm">
		<input type="hidden" name="Action" value="getFile">
		<input type="file" name="FiletoUpload" size="45" onchange="checkCSV(this);">
		<input type="submit" value="Upload this file" #saveClr#>
	</form>
</cfif>
<!------------------------------------------------------->

<cfif action is "makeTemplate">
	<cffile action = "write"
    file = "#Application.webDirectory#/download/BulkUnloadDataLoan.csv"
    output = "guid,loan_guid_prefix,loan_number"
    addNewLine = "no">
	<cflocation url="/download.cfm?file=BulkUnloadDataLoan.csv" addtoken="false">
</cfif>
<!------------------------------------------------------->
<cfif #action# is "getFile">
	<cfquery name="killOld" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		delete from cf_temp_unload_data_loan_item
	</cfquery>

	<cftransaction>
		<cfinvoke component="/component/utilities" method="uploadToTable">
	    	<cfinvokeargument name="tblname" value="cf_temp_unload_data_loan_item">
		</cfinvoke>
	</cftransaction>

	<cfquery name="gotit" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select * from cf_temp_unload_data_loan_item
	</cfquery>
	<cfdump var="#gotit#">
	If the above table is accurate, <a href="DataLoanBulkUnload.cfm?action=verify">click here to proceed to validation</a>.
</cfif>
<!------------------------------------------------------->
<cfif action is "verify">
<cfoutput>
<cftransaction>
	<cfquery name="loanID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		update
			cf_temp_unload_data_loan_item
		set
			(transaction_id)
		= (select
				loan.transaction_id
			from
				trans,loan,collection
			where
				trans.transaction_id = loan.transaction_id and
				loan.loan_type='data' and
				trans.collection_id = collection.collection_id and
				collection.guid_prefix=cf_temp_unload_data_loan_item.loan_guid_prefix and
				loan.loan_number = cf_temp_unload_data_loan_item.loan_number
			)
	</cfquery>
	<cfquery name="missedMe" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		update cf_temp_unload_data_loan_item set status = 'loan not found' where transaction_id is null
	</cfquery>
	<cfquery name="collObj" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		update
			cf_temp_unload_data_loan_item
		set
			(collection_object_id)
		= (select
				collection_object_id
			from
				flat
			where
				flat.guid=cf_temp_unload_data_loan_item.guid
			)
	</cfquery>
	<cfquery name="missedMeS" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		update cf_temp_unload_data_loan_item set status = 'item not found' where collection_object_id is null
	</cfquery>

	<cfquery name="done" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select * from cf_temp_unload_data_loan_item
	</cfquery>
	<cfdump var=#done#>
	<cfquery name="bads" dbtype="query">
		select count(*) c from done where status is not null
	</cfquery>
	<cfif bads.c is 0 or bads.c is ''>
		If everything in the table above looks OK, <a href="DataLoanBulkUnload.cfm?action=unloadData">click here to finalize unloading</a>.
	<cfelse>
		Something isn't happy. Check the status column in the above table, fix your data, and try again.
	</cfif>
</cftransaction>
</cfoutput>
</cfif>
<!------------------------------------------------------->
<cfif action is "unloadData">
<cfoutput>
	<cfquery name="move" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		delete from loan_item where (transaction_id,collection_object_id) in (select transaction_id,collection_object_id from cf_temp_unload_data_loan_item)
	</cfquery>
	Spiffy, all done.
</cfoutput>
</cfif>
<cfinclude template="/includes/_footer.cfm">
