<!---
	IMPORTANT

	this is a companion file to ScheduledTasks/collection_report.

	ScheduledTasks is fast, minimal, and send email.

	info is a comprehensive summary of your collection's users

---->

<cfinclude template="/includes/_header.cfm">
<script src="/includes/sorttable.js"></script>
<cfset title="collection contact report">
<style>
	.hasNoContact{
		color:red;
		margin:1em;
		padding:1em;
		border:3px solid red;
		display:inline-block;
	}
</style>
<cfoutput>
	<cfquery name="colns" datasource="uam_god">
		select guid_prefix from collection order by guid_prefix
	</cfquery>
	<cfquery name="CTCOLL_CONTACT_ROLE" datasource="uam_god">
		select
			CONTACT_ROLE
		from
			CTCOLL_CONTACT_ROLE
		where
			CONTACT_ROLE not in ('mentor')
		order by
			CONTACT_ROLE
	</cfquery>
	<form action="collection_report.cfm">
		<label for="guid_prefix">GUID Prefix</label>

		<select name="guid_prefix">
			<option value=""></option>
			<cfloop query="colns">
				<option value="#guid_prefix#">#guid_prefix#</option>
			</cfloop>
		</select>
		<input type="submit" value="go" class="lnkBtn">
	</form>

<cfif not isdefined("guid_prefix") or len(guid_prefix) is 0><cfabort></cfif>
	<cfquery name="coln" datasource="uam_god">
		select * from collection where upper(guid_prefix)='#ucase(guid_prefix)#'
	</cfquery>
	<cfif coln.recordcount neq 1>
		collection not found<cfabort>
	</cfif>
	<h2>
		User and Contacts report for collection #coln.guid_prefix#
	</h2>
	<h3>
		Collection Data
	</h3>
	<cfif len(coln.USE_LICENSE_ID) gt 0>
		<cfquery name="license" datasource="uam_god">
			select  * from  ctmedia_license where MEDIA_LICENSE_ID=#coln.USE_LICENSE_ID#
		</cfquery>

	</cfif>

	<div><strong>GUID_PREFIX:</strong> #coln.GUID_PREFIX#</div>
	<div><strong>CollectionID:</strong> #coln.COLLECTION_ID#</div>
	<div><strong>Code Tables:</strong> #coln.COLLECTION_CDE#</div>
	<div><strong>Collection:</strong> #coln.COLLECTION#</div>
	<div><strong>Institution Acronym:</strong> #coln.INSTITUTION_ACRONYM#</div>
	<div><strong>INSTITUTION:</strong> #coln.INSTITUTION#</div>

	<div><strong>Description:</strong> #coln.DESCR#</div>
	<div><strong>Web Link:</strong> #coln.WEB_LINK#</div>
	<div><strong>Web Link Text:</strong> #coln.WEB_LINK_TEXT#</div>
	<div><strong>Loan Policy:</strong> #coln.LOAN_POLICY_URL#</div>
	<div><strong>License:</strong>
	<cfif len(coln.USE_LICENSE_ID) gt 0>
		#license.DISPLAY# (URL: #license.URI# Description: #license.DESCRIPTION#)
	<cfelse>
		NONE
	</cfif>
	</div>
	<div><strong>Citation:</strong> #coln.CITATION#</div>
	<div><strong>Taxonomy Source:</strong> #coln.PREFERRED_TAXONOMY_SOURCE#</div>
	<div><strong>Catalog NUmber Format:</strong> #coln.CATALOG_NUMBER_FORMAT#</div>
	<cfquery name="users" datasource="uam_god">
		select
			agent.agent_id,
			grantee username,
			agent.preferred_agent_name
		from
			dba_role_privs,
			agent_name,
			agent
		where
			upper(dba_role_privs.granted_role) = upper(replace('#guid_prefix#',':','_')) and
			upper(dba_role_privs.grantee) = upper(agent_name.agent_name) and
			agent_name.agent_name_type='login' and
			agent_name.agent_id=agent.agent_id
		order by
			agent.preferred_agent_name
	</cfquery>
	<cfquery name="contacts"  datasource="uam_god">
		select
			get_address(collection_contacts.contact_agent_id,'email') address,
			collection_contacts.CONTACT_ROLE,
			agent.preferred_agent_name
		from
			collection_contacts,
			agent
		where
			collection_contacts.collection_id=#coln.collection_id# and
			collection_contacts.contact_agent_id=agent.agent_id
		order by preferred_agent_name
	</cfquery>
	<cfloop query="CTCOLL_CONTACT_ROLE">
		<cfquery name="hasActiveContact" dbtype="query">
			select count(*) c from contacts where address is not null and CONTACT_ROLE='#CONTACT_ROLE#'
		</cfquery>
		<cfif hasActiveContact.c lt 1>
			<div>
				<div class="hasNoContact">
					WARNING: collection has no active #CONTACT_ROLE# contact!
				</div>
			</div>
		</cfif>
	</cfloop>
	<p>
		Collection Contacts
		<br><a href="/Admin/Collection.cfm?action=findColl&collection_id=#coln.collection_id#">Manage Contacts</a>
		<br>NOTE: contacts without an email address may not have a "valid" email, or their account may be locked.
		<table border>
			<tr>
				<td>PreferredName</td>
				<td>Role</td>
				<td>Email</td>
			</tr>
			<cfloop query="contacts">
				<tr>
					<td>#preferred_agent_name#</td>
					<td>#CONTACT_ROLE#</td>
					<td>#address#</td>
				</tr>
			</cfloop>
		</table>
	</p>
	<cfset summary=querynew("u,p,s,c")>
	<cfsavecontent variable="details">
		<cfloop query="users">
			<cfquery name="acts" datasource="uam_god">
				select account_status FROM dba_users where username='#users.username#'
			</cfquery>

			<hr>
			<div id="#users.username#">
				Preferred Name: #users.preferred_agent_name#
			</div>
			<br>Username: #users.username#
			<br>Account Status: #acts.account_status#
			<br><a href="/AdminUsers.cfm?action=edit&username=#users.username#">manage user account</a>
			<br><a href="/agents.cfm?agent_id=#users.agent_id#">manage agent record</a>
			<br><a href="/info/agentActivity.cfm?agent_id=#users.agent_id#">view agent activity report</a>
			<cfquery name="cct" datasource="uam_god">
				select * from collection_contacts where CONTACT_AGENT_ID=#users.agent_id#  and
				collection_contacts.collection_id=#coln.collection_id#
				order by CONTACT_ROLE
			</cfquery>

			<cfif acts.account_status neq 'OPEN' and cct.recordcount gt 0>
				<cfset ctn='LOCKED COLLECTION CONTACT'>
			<cfelse>
				<cfset ctn=''>
			</cfif>
			<cfset queryaddrow(summary,
				{u=users.username,
				p=users.preferred_agent_name,
				s=acts.account_status,
				c=ctn}
			)>
			<cfloop query="cct">
				<br>Collection Contact Role: #cct.CONTACT_ROLE#
			</cfloop>
			<cfquery name="addr" datasource="uam_god">
				select * from address where agent_id=#users.agent_id#
			</cfquery>
			<cfloop query="addr">
				<br>#replace(ADDRESS_TYPE,chr(10),"<br>","all")#: #ADDRESS# (<cfif VALID_ADDR_FG is 1>valid<cfelse>not valid</cfif>)
			</cfloop>
			<cfquery name="role" datasource="uam_god">
				select
					granted_role
				from
					dba_role_privs
				where
					upper(grantee) = '#users.username#'
					and granted_role not in (select upper(replace(guid_prefix,':','_')) from collection)
					order by granted_role
			</cfquery>
			<p>Roles</p>
			<ul>
				<cfloop query="role">
					<li>#granted_role#</li>
				</cfloop>
			</ul>
		</cfloop>
	</cfsavecontent>
	<cfquery name="os" dbtype="query">
		select * from summary order by c desc,s desc,u
	</cfquery>
	<p>
		Users Summary
		<table border>
			<tr>
				<th>Username</th>
				<th>Preferred Name</th>
				<th>Account Status</th>
				<th>Problem</th>
			</tr>
			<cfloop query="os">
				<tr>
					<td><a href="###u#">#u#</a></td>
					<td>#p#</td>
					<td>#s#</td>
					<td>#c#</td>
				</tr>
			</cfloop>
		</table>
	</p>
	<p></p>
	#details#


<!----

select
					granted_role role_name
				from
					dba_role_privs,
					collection
				where
					upper(dba_role_privs.granted_role) = upper(replace(collection.guid_prefix,':','_')) and
					upper(grantee) = '#ucasename#'




	<cfquery name="c" datasource="uam_god">
		select
			collection.guid_prefix,
			collection.collection_id,
			collection_contacts.CONTACT_ROLE,
			getPreferredAgentName(collection_contacts.CONTACT_AGENT_ID) contactName,
			get_address(collection_contacts.contact_agent_id,'email',1) activeEmail,
			get_address(collection_contacts.contact_agent_id,'email',0) allEmail
		from
			collection,
			collection_contacts
		where
			collection.guid_prefix='UAM:Mamm' and
			collection.collection_id=collection_contacts.collection_id (+)
		order by
			collection.guid_prefix,
			collection_contacts.CONTACT_ROLE,
			getPreferredAgentName(collection_contacts.CONTACT_AGENT_ID)
	</cfquery>
	<p>
		<ul>
			<li><strong>Email</strong> is email address attached to agent record</li>
			<li>
				<strong>Active Email</strong> is valid email address attached to agent record of active Operator. This is generally
				the only address used when sending notifications to collection contacts.
			</li>
		</ul>
	</p>

	<table border id="t" class="sortable">
		<tr>
			<th>Collection</th>
			<th>Contact</th>
			<th>Role</th>
			<th>Email</th>
			<th>Active Email</th>
		</tr>
		<cfloop query="c">
			<tr>

				<td>
					#c.guid_prefix#
					<cfquery name="hasDQ" dbtype="query">
						select count(*) c from c where guid_prefix='#guid_prefix#' and activeEmail is not null
						and CONTACT_ROLE='data quality'
					</cfquery>
					<cfif hasDQ.c lt 1>
						<div class="hasNoContact">
							no active data quality contact
						</div>
					</cfif>
					<cfquery name="hasLR" dbtype="query">
						select count(*) c from c where guid_prefix='#guid_prefix#' and activeEmail is not null
						and CONTACT_ROLE='loan request'
					</cfquery>
					<cfif hasLR.c lt 1>
						<div class="hasNoContact">
							no active loan request contact
						</div>
					</cfif>
					<cfquery name="hasTS" dbtype="query">
						select count(*) c from c where guid_prefix='#guid_prefix#' and activeEmail is not null
						and CONTACT_ROLE='technical support'
					</cfquery>
					<cfif hasTS.c lt 1>
						<div class="hasNoContact">
							no active technical support contact
						</div>
					</cfif>
				</td>
				<td>#c.contactName#</td>
				<td>#c.CONTACT_ROLE#</td>
				<td>#c.allEmail#</td>
				<td>#c.activeEmail#</td>

			</tr>
		</cfloop>
	</table>
	--->
	</cfoutput>
<cfinclude template="/includes/_footer.cfm">
