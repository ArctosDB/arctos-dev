<!---
drop table ds_temp_agent_split;

create table ds_temp_agent_split (
	key serial not null,
	preferred_name varchar,
	other_name_1  varchar,
	other_name_type_1   varchar,
	other_name_2  varchar,
	other_name_type_2   varchar,
	other_name_3  varchar,
	other_name_type_3   varchar,
	other_name_4  varchar,
	other_name_type_4   varchar,
	agent_remark varchar
	);

grant select, usage on ds_temp_agent_split_key_seq to public;

grant insert,update,delete,select on ds_temp_agent_split to coldfusion_user;

---->
<cfinclude template="/includes/_header.cfm">
<cfset title='Agent Name Splitter Thingee'>
<cfsetting requestTimeOut = "600">

<cfif action is "nothing">

<p>
	Upload a CSV file of agent names with one column, header "preferred_name".
</p>
	<ul>
		<li>This app is a tool, not magic; you are fully responsible for the result.</li>
		<li>This app only returns a file which may then be cleaned up and bulkloaded. Clean and reload as many times as necessary before
			accepting the result.</li>
		<li>There will be columns in the result that will not fit in the agent bulkloader; you must delete them.</li>
		<li>other_name_1 and other_name_type_1 will be a "formatted name." You may need to copy these data into preferred_name and original preferred_name
			into a more-suitable agent name type (eg, aka) if your data are "nonstandard" (eg, lastname, firstname middleinitial format).
		</li>
		<li>Change "formatted name" to an appropriate name type to load.</li>
		<li>Upload a smaller file if you get a timeout.</li>
				<!----

		<li>Fix your data or add an alias to the existing agent if there's a good suggestion.</li>
		<li>Suggestions with more "reasons" are typically stronger; a suggestion with >~4 reasons deserves very close scrutiny</li>
		<li>Suggestions with few reasons, or no suggestions, are about equally likely to be well-formatted, new, unique names, and horribly mangled garbage.</li>
		---->
		<li>
			Consider tossing low-quality agents (eg, initials only, first name only, common last name only) into agent "unknown"
			(and perhaps an appropriate remarks field)
		</li>
		<li>
			There is precisely one "unknown" agent in Arctos. It, like all of Arctos, is case-sensitive. Do NOT create horrid copies of "unknown" (Unknown, ANONYMOUS, etc.).
		</li>
		<li>Input (preferred_name) will be TRIMMED; remove leading and trailing spaces and control characters from your data.</li>
	</ul>

	<form name="atts" method="post" enctype="multipart/form-data">
		<input type="hidden" name="Action" value="getFile">
		<input type="file" name="FiletoUpload" size="45" onchange="checkCSV(this);">
		<input type="submit" value="Upload this file" class="savBtn">
	</form>
</cfif>
<cfif action is "getFile">
<cfoutput>
	<cffile action="READ" file="#FiletoUpload#" variable="fileContent">
	<cfquery name="killOld" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		delete from ds_temp_agent_split
	</cfquery>
	<cftransaction>
		<cfinvoke component="/component/utilities" method="uploadToTable">
	    	<cfinvokeargument name="tblname" value="ds_temp_agent_split">
		</cfinvoke>
	</cftransaction>

</cfoutput>
<cflocation url="agentNameSplitter.cfm?action=validate" addtoken="false">
</cfif>
<cfif action is "validate">
<cfoutput>
	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select * from ds_temp_agent_split where preferred_name is not null 
	</cfquery>
	<cfset obj = CreateObject("component","component.agent")>
	<cfloop query="d">

		  <br>#preferred_name#


		<cfset splitAgentName = obj.splitAgentName(name="#preferred_name#")>

		<!----
		<cfset checkAgent = obj.checkAgent(preferred_name="#preferred_name#", agent_type='person')>
		,
				suggestions='#checkAgent#'
---->


		<cfquery name="d" datasource="uam_god">
			update ds_temp_agent_split set
				other_name_1='#splitAgentName.formatted_name#',
				other_name_type_1='formatted name',
				other_name_2='#splitAgentName.last#',
				other_name_type_2='last name',
				other_name_3='#splitAgentName.middle#',
				other_name_type_3='middle name',
				other_name_4='#splitAgentName.first#',
				other_name_type_4='first name'
			where key=#key#
		</cfquery>

	</cfloop>
			<!-----


			other_name_1  varchar2(255),
	other_name_type_1   varchar2(255),
	other_name_2  varchar2(255),
	other_name_type_2   varchar2(255),
	other_name_3  varchar2(255),
	other_name_type_3   varchar2(255),
	other_name_4  varchar2(255),
	other_name_type_4   varchar2(255),



			<cfset temp = queryaddrow(d,1)>
	<cfset temp = QuerySetCell(d, "name", name, 1)>
	<cfset temp = QuerySetCell(d, "nametype", nametype, 1)>
	<cfset temp = QuerySetCell(d, "first", trim(first), 1)>
	<cfset temp = QuerySetCell(d, "middle", trim(middle), 1)>
	<cfset temp = QuerySetCell(d, "last", trim(last), 1)>
	<cfset temp = QuerySetCell(d, "formatted_name", trim(formatted_name), 1)>



		<cfquery name="d" datasource="uam_god">
			update ds_temp_agent_split set
				agent_type='person',
				preferred_name='#thisName#',
				first_name='#firstn#',
				middle_name='#mdln#',
				last_name='#lastn#',
				birth_date='',
				death_date='',
				prefix='#pfx#',
				suffix='#sfx#',
				other_name_1='',
				other_name_type_1='',
				other_name_2='',
				other_name_type_2='',
				other_name_3='',
				other_name_type_3='',
				agent_remark='',
				suggestions='#sugn#',
				status='#s#'
			where key=#key#
		</cfquery>



alter table ds_temp_agent_split add status varchar2(4000);

	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select * from ds_temp_agent_split where preferred_name is not null
	</cfquery>
	<cfquery name="ctsuffix" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select suffix from ctsuffix
	</cfquery>
	<cfquery name="ctprefix" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select prefix from ctprefix
	</cfquery>
	<cfset sfxLst=valuelist(ctsuffix.suffix)>
	<cfset pfxLst=valuelist(ctprefix.prefix)>
	<cfloop query="d">
		<cfset s=''>
		<cfset pfx=''>
		<cfset sfx=''>
		<cfset firstn=''>
		<cfset lastn=''>
		<cfset mdln=''>
		<cfset sugn=''>
		<cftry>
			<cfset thisName=trim(preferred_name)>
			<cfif len(thisName) is 0>
				<cfset s=listappend(s,"preferred_name may not be blank",";")>
			</cfif>
			<cfif thisName is not preferred_name>
				<cfset s=listappend(s,"leading or trailing spaces trimmed",";")>
			</cfif>
			<cfif thisName contains "  ">
				<cfset thisName=replace(thisName,"  "," ","all")>
				<cfset s=listappend(s,"trimmed double spaces",";")>
			</cfif>
			<cfquery name="isThere" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select agent_id from agent_name where agent_name='#thisName#'
			</cfquery>
			<cfif isThere.recordcount is 1>
				<cfset s=listappend(s,"found #isThere.recordcount# match",";")>
			<cfelseif isThere.recordcount gt 1>
				<cfset s=listappend(s,"found #isThere.recordcount# matches-merge or make unique",";")>
			</cfif>
			<cfloop index="i" list="#thisName#" delimiters=" ,;">
				<cfif listfindnocase(pfxLst,i)>
					<cfset pfx=i>
				</cfif>
				<cfif listfindnocase(sfxLst,i)>
					<cfset sfx=i>
				</cfif>
			</cfloop>
			<cfset tempName=thisName>
			<cfif len(pfx) gt 0>
				<cfset tempName=replace(tempName,pfx,'')>
			</cfif>
			<cfif len(sfx) gt 0>
				<cfset tempName=replace(tempName,sfx,'')>
			</cfif>
			<cfset tempName=trim(tempName)>
			<cfif right(tempName,1) is ",">
				<cfset tempName=left(tempName,len(tempName)-1)>
			</cfif>
			<cfif listlen(tempName," ") is 1>
				<cfset s=listappend(s,"will not deal with no-space agents",";")>
			<cfelseif listlen(tempName," ") is 2>
				<cfset firstn=listFirst(tempName," ")>
				<cfset lastn=listLast(tempName," ")>
			<cfelse>
				<cfset firstn=listFirst(tempName," ")>
				<cfset lastn=listLast(tempName," ")>
				<cfset mdln=tempName>
				<cfset mdln=replace(mdln,firstn,'')>
				<cfset mdln=replace(mdln,lastn,'')>
				<cfset mdln=trim(mdln)>
			</cfif>
			<cfset ProbNotPersonClue="class,biol,alaska,california,field,station,research,summer,student,students,uaf,national,estate">
			<cfset pnap=false>
			<cfloop list="#ProbNotPersonClue#" index="i">
				<cfif listfindnocase(thisName,i," ,;-")>
					<cfset pnap=true>
				</cfif>
			</cfloop>
			<cfif refind("[A-Z][A-Z]",thisName)>
				<cfset pnap=true>
			</cfif>
			<cfif refind("[0-9]",thisName)>
				<cfset pnap=true>
			</cfif>
			<cfif pnap>
				<cfset s=listappend(s,"probably not a person",";")>
			</cfif>
			<cfif s does not contain "found">
				<cfquery name="ln" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					select agent_name from preferred_agent_name,person where
					person.person_id=preferred_agent_name.agent_id and
					person.last_name='#lastn#'
					group by agent_name
				</cfquery>
				<cfif ln.recordcount gt 0>
					<cfset sugn=valuelist(ln.agent_name,"; ")>
				</cfif>
				<cfif len(sugn) gt 3500>
					<cfset sugn=left(sugn,3500) & '...'>
				</cfif>
			</cfif>
		<cfcatch>
			<cfset s="something very strange happened - check for nonprinting or special characters">
		</cfcatch>
		</cftry>
		<!--- this has to run as UAM because the CF datathingy is completely retarded and fails on agent name "grant" ---->
		<cfquery name="d" datasource="uam_god">
			update ds_temp_agent_split set
				agent_type='person',
				preferred_name='#thisName#',
				first_name='#firstn#',
				middle_name='#mdln#',
				last_name='#lastn#',
				birth_date='',
				death_date='',
				prefix='#pfx#',
				suffix='#sfx#',
				other_name_1='',
				other_name_type_1='',
				other_name_2='',
				other_name_type_2='',
				other_name_3='',
				other_name_type_3='',
				agent_remark='',
				suggestions='#sugn#',
				status='#s#'
			where key=#key#
		</cfquery>
	</cfloop>



	---->
	all done <a href="agentNameSplitter.cfm?action=showTable">move on</a>
</cfoutput>
</cfif>
<cfif action is "showTable">
	<cfoutput>

	<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select * from ds_temp_agent_split
	</cfquery>
	<!--- little bit of ordering --->


	<cfset theCols="preferred_name,other_name_type_1,other_name_1,other_name_type_2,other_name_2,other_name_type_3,other_name_3,other_name_type_4,other_name_4">
	<script src="/includes/sorttable.js"></script>
	<table border id="t" class="sortable">
		<tr>
			<cfloop list="#theCols#" index="i">
				<th>#i#</th>
			</cfloop>
		</tr>
		<cfloop query="data">
			<tr>
				<cfloop list="#theCols#" index="i">
					<td>
						#evaluate("data." & i)#
					</td>
				</cfloop>
			</tr>
		</cfloop>
	</table>
	<a href="agentNameSplitter.cfm?action=download">[ download ]</a>
	<!----
	<br><a href="agentNameSplitter.cfm?action=delete&s=foundOneMatch">[ delete all "found one match" records ]</a>
	<br><a href="agentNameSplitter.cfm?action=delete&s=pnap">[ delete all "probably not a person" records ]</a>
	----->

</cfoutput>
</cfif>
<cfif action is "delete">
	<cfif s is "foundOneMatch">
		<cfset sql="delete from ds_temp_agent_split where status like '%found 1 match%'">
	<cfelseif s is "pnap">
		<cfset sql="delete from ds_temp_agent_split where status like '%probably not a person%'">
	</cfif>

	<cfquery name="delete" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		#preserveSingleQuotes(sql)#
	</cfquery>
	<cflocation url="agentNameSplitter.cfm?action=validate" addtoken="false">
</cfif>
<cfif action is "download">
	<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			PREFERRED_NAME,
			OTHER_NAME_1,
			OTHER_NAME_TYPE_1,
			OTHER_NAME_2,
			OTHER_NAME_TYPE_2,
			OTHER_NAME_3,
			OTHER_NAME_TYPE_3,
			OTHER_NAME_4,
			OTHER_NAME_TYPE_4,
			AGENT_REMARK
		from ds_temp_agent_split
	</cfquery>

	<cfset  util = CreateObject("component","component.utilities")>
	<cfset csv = util.QueryToCSV2(Query=data,Fields=data.columnlist)>
	<cffile action = "write"
	    file = "#Application.webDirectory#/download/splitAgentNames.csv"
	   	output = "#csv#"
	   	addNewLine = "no">


	   	<!----
	<cfset theCols=data.columnList>
	<cfset theCols=listdeleteat(theCols,listFindNoCase(theCols,"key"))>



	<cfset variables.encoding="UTF-8">
	<cfset variables.fileName="#Application.webDirectory#/download/splitAgentNames.csv">
	<cfscript>
		variables.joFileWriter = createObject('Component', '/component.FileWriter').init(variables.fileName, variables.encoding, 32768);
		variables.joFileWriter.writeLine(theCols);
	</cfscript>

	<cfloop query="data">
		<cfset d=''>
		<cfloop list="#theCols#" index="i">
			<cfset t='"' & evaluate("data." & i) & '"'>
			<cfset d=listappend(d,t,",")>
		</cfloop>
		<cfscript>
			variables.joFileWriter.writeLine(d);
		</cfscript>
	</cfloop>
	<cfscript>
		variables.joFileWriter.close();
	</cfscript>
	---->
	<cflocation url="/download.cfm?file=splitAgentNames.csv" addtoken="false">
	<a href="/download/splitAgentNames.csv">Click here if your file does not automatically download.</a>
</cfif>
<cfinclude template="/includes/_footer.cfm">
