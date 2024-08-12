<!--- over-ride the class=error (pop up in the middle) for this form --->
<style>
	.error {
		position:relative;
		top:0;
		left:0;
	}
</style>
<cfif not isdefined("toProperCase")>
	<cfinclude template="/includes/_header.cfm">
</cfif>
<cfoutput>
	<cfset cTemp="">
	<cfif len(request.rdurl) gt 0>
		<cfset cTemp=request.rdurl>
	<cfelseif len(cgi.script_name) gt 0>
		<cfset cTemp=cgi.script_name>
	</cfif>
	<cfquery name="redir" datasource="cf_dbuser">
		select new_path from redirect where upper(old_path)=
		<cfif left(cTemp,1) is "/">
			'#ucase(cTemp)#'
		<cfelse>
			'/#ucase(cTemp)#'
		</cfif>
	</cfquery>
	<cfif redir.recordcount is 1>
		<cfheader statuscode="301" statustext="Moved permanently">
		<cfif left(redir.new_path,4) is "http">
			<cfheader name="Location" value="#redir.new_path#">
		<cfelse>
			<cfheader name="Location" value="#application.serverRootURL##redir.new_path#">
		</cfif>
		<cfabort>
	</cfif>
	<cfset f = CreateObject("component","component.utilities")>
	<!--- pass in the URL to ensure the error side of the checker fires ---->
	<cfset x=f.checkRequest(request.rdurl)>
	<cfset fourohthree="dll,png,crossdomain,xml">
	<cfset browsergarbage="apple-touch-icon,browserconfig">
	<cfloop list="#request.rdurl#" delimiters="./&+()" index="i">
		<cfloop list="#browsergarbage#" index="bg">
			<cfif i contains bg>
				<cfthrow detail="Unsupported browser-specific file request" message="403: Forbidden" errorcode="403">
			</cfif>
		</cfloop>
		<cfif listfindnocase(fourohthree,i)>
			<cfthrow detail="You've requested a form which isn't available. This may be an indication of unwanted or malicious software on your computer." message="403: Forbidden" errorcode="403">
		</cfif>
	</cfloop>
	<!--- we don't have a redirect, and it's not on our hitlist, so 404 --->
	<cfheader statuscode="404" statustext="Not found">
	<cfset title="404: not found">
	<h2>
		404! The page you tried to access does not exist.
	</h2>

	<cfdirectory name="dlist" directory="#application.webDirectory#" action="list" recurse="true">
	<cfset fileinfo=listlast(request.rdurl,"/")>
	<cfset fileName=listfirst(fileinfo,".")>
	<cfset queryStringS=FindOneOf("&?",request.rdurl)>
	<cfif queryStringS gt 0>
		<cfset queryString="?" & right(request.rdurl,len(request.rdurl)-queryStringS)>
	<cfelse>
		<cfset queryString="">
	</cfif>
	<!----
		this is for public - limit this to root dir
		exclude things that require data
	---->
	<cfquery name="fq" dbtype="query">
		select * from dlist where
			upper(name) like '%#ucase(fileName)#%' and
			directory ='#application.webDirectory#' and
			name != 'SpecimenResultsDownload.cfm'
	</cfquery>
	<cfif fq.recordcount gt 0>
		<p>
			<h3>Did you mean?</h3>
			<ul>
				<cfloop query="#fq#">
					<li>
						<a href="#name#?#querystring#">#name##querystring#</a>
					</li>
				</cfloop>
			</ul>
		</p>
	</cfif>

	<script type="text/javascript">
		var GOOG_FIXURL_LANG = 'en';
		var GOOG_FIXURL_SITE = 'http://arctos.database.museum/';
	</script>
	<script type="text/javascript" src="http://linkhelp.clients.google.com/tbproxy/lh/wm/fixurl.js"></script>
	<!----
	<script type="text/javascript" language="javascript">
		function changeCollection () {
			jQuery.getJSON("/component/functions.cfc",
				{
					method : "changeexclusive_collection_id",
					tgt : '',
					returnformat : "json",
					queryformat : 'column'
				},
				function (d) {
		  			document.location='#request.rdurl#';
		  			//console.log('/#request.rdurl#');
				}
			);
		}
	</script>
	---->
	<cfset isGuid=false>
	<cfif len(request.rdurl) gt 0 and request.rdurl contains "guid">
		<cfset isGuid=true>
		<cfif session.dbuser is not "pub_usr_all_all">
			<cfquery name="yourcollid" datasource="cf_dbuser">
				select portal_name from cf_collection where DBUSERNAME='#session.dbuser#'
			</cfquery>
			<p>
				<cfif len(session.roles) gt 0 and session.roles is not "public">
					If you are an operator, you may have to log out or ask your supervisor for more access.
				</cfif>
				You are accessing Arctos through the #yourcollid.portal_name# portal, and cannot access specimen data in
				other collections. You may
				<span class="likeLink" onclick="changeCollection('/#request.rdurl#')">try again in the public portal</span>.
			</p>
		</cfif>
	</cfif>

	<p>
		If you followed a link from within Arctos, please <a href="/contact.cfm">Contact Us</a>
	 	with any information that might help us resolve this issue.
	</p>
	<p>
		If you followed an external link, please use your back button and tell the webmaster that
		something is broken, or <a href="/contact.cfm">Contact Us</a> telling us how you got this error.
	</p>

	<p><a href="/taxonomy.cfm">Search for Taxon Names here</a></p>
	<p><a href="/SpecimenUsage.cfm">Search for Projects and Publications here</a></p>
	<p>
		If you're trying to find specimens, you may:
		<ul>
			<li><a href="/SpecimenSearch">Search for them</a></li>
			<li>Access them by URLs of the format:
				<ul>
					<li>
						#Application.serverRootUrl#/guid/{guid_prefix}:{catnum}
						<br>Example: #Application.serverRootUrl#/guid/UAM:Mamm:1
						<br>&nbsp;
					</li>
				</ul>
			</li>
		</ul>
		Some specimens are restricted. You may <a href="/contact.cfm">contact us</a> for more information, or
		<a href="/info/encumbrances.cfm">view a summary of encumbrances</a>.
		<p>
			Occasionally, a specimen is recataloged. You may be able to find them by using Other Identifiers in Specimen Search.
		</p>
	</p>
	<cfif request.rdurl contains "mediaUploads">
		<cfquery name="pm" datasource="uam_god">
			select media_id, media_uri from media where upper(media_uri) like '%#ucase(listlast(request.rdurl,"/"))#%' and rownum<11
		</cfquery>
		<p>
			Media are stored on the fileserver only temporarily. Use <a href="/MediaSearch.cfm">MediaSearch</a> to find them
			<cfif pm.recordcount gt 0>
				or try these links:
				<ul>
				<cfloop query="pm">
					<li><a href="/media/#media_id#">#listlast(media_uri,"/")#</a></li>
				</cfloop>
				</ul>
			</cfif>
		</p>
	</cfif>

	<cfif isGuid is false>
		<cfset sub="404">
		<cfset frm="dead.link">
	<cfelse>
		<cfset sub="missing GUID">
		<cfset frm="dead.guid">
	</cfif>
	<cfif request.rdurl contains 'coldfusion.applets.CFGridApplet.class'>
		<cfset sub="stoopid safari">
		<cfset frm="stoopid.safari">
	</cfif>


	<cf_logError subject="#sub#">

	 <p>A message has been sent to the site administrator.</p>
	 <p>
	 	Use the tabs in the header to continue navigating Arctos.
	 </p>
</cfoutput>
<cfinclude template="/includes/_footer.cfm">