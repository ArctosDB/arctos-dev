<cfinclude template="/includes/_includeHeader.cfm">
<!------------


		use findAccn for data entry
		
		
------------>
<cfoutput>
	<cfquery name="ctcollection" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select guid_prefix,collection_id from collection order by guid_prefix
	</cfquery>
	<form name="searchForAccn" action="getAccnMedia.cfm" method="get">
		<input type="hidden" name="idOfTxtFld" value="#idOfTxtFld#">
		<input type="hidden" name="idOfPKeyFld" value="#idOfPKeyFld#">
		
		<label for="collectionID">Collection</label>
		<select name="collectionID" id="collectionID">
			<option value=""></option>
			<cfloop query="ctcollection">
				<option value="#collection_id#">#guid_prefix#</option>
			</cfloop>
		</select>
		<label for="accnNumber">Accn Number</label>
		<input type="text" name="accnNumber" id="accnNumber">
		<input type="submit" value="Search"	class="lnkBtn">
	</form>
	<cfif isdefined("accnNumber") and len(accnNumber) gt 0>
		<cfquery name="getAccn" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			SELECT 
				collection.guid_prefix,
				collection.collection_id,
				accn_number,
				accn.transaction_id
			FROM
				accn,
				trans,
				collection
			WHERE
				accn.transaction_id=trans.transaction_id and
				trans.collection_id=collection.collection_id and
				<cfif len(collectionID) gt 0>
					collection.collection_id=#collectionID# and
				</cfif>
				upper(accn_number) like '%#ucase(accnNumber)#%'
			ORDER BY
				collection.guid_prefix,
				accn_number
		</cfquery>
		<cfif getAccn.recordcount is 0>
			Nothing matched.
		<cfelse>
			<cfloop query="getAccn">
				<br><span class="likeLink" onClick="opener.document.getElementById('#idOfTxtFld#').value='#guid_prefix# #accn_number#';opener.document.getElementById('#idOfPKeyFld#').value='#transaction_id#';self.close();">#guid_prefix# #accn_number#</span>
			</cfloop>
		</cfif>
	</cfif>
</cfoutput>
<cfinclude template="../includes/_pickFooter.cfm">