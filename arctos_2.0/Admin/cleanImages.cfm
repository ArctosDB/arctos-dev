<!---
	modify for final cleanup in move to S3
	old version is in v7.9.6

	this has served its purpose
---->
<cfabort>



<cfinclude template="/includes/_header.cfm">
<cfsetting requesttimeout="600">


<!----

select media_uri,media_id from media where media_uri like '%arctos.database%';

	drop table temp_m_f;

	create table temp_m_f as select
		media_id,
		media_uri,
		preview_uri
	from
		media
	where
		(media_uri like '%arctos.database%' and media_uri like '%mediaUploads%') or
		(preview_uri like '%arctos.database%' and preview_uri like '%mediaUploads%')
		;


	alter table temp_m_f add lcl_p varchar2(255);
	alter table temp_m_f add lcl_p_p varchar2(255);

	alter table temp_m_f add status varchar2(255);


	update temp_m_f set status=null,lcl_p=null where lcl_p='/';
		update temp_m_f set status=null,lcl_p_p=null where lcl_p_p='/';


select status,count(*) from temp_m_f group by status;

-- some some complexity
					select LABEL_VALUE from media_labels where MEDIA_LABEL='MD5 checksum' and MEDIA_ID in (select media_id from temp_m_f);

---->

	<p>
		 <a href="cleanImages.cfm?action=cleanup">cleanup</a>
	</p>
	<p>
		 <a href="cleanImages.cfm?action=upmuris">upmuris</a>
	</p>
	<p>
		 <a href="cleanImages.cfm?action=cpfls">cpfls</a>
	</p>
	<p>
		 <a href="cleanImages.cfm?action=mklclp">mklclp</a>
	</p>
	<p>
		 <a href="cleanImages.cfm?action=cklcl">cklcl</a>
	</p>
<cfoutput>


	<cfif action is "cleanup">
	<cfset ctr=0>
	 <cfdirectory directory = "#Application.webDirectory#/mediaUploads" action = "list" name = "D" recurse = "yes">
	 <CFLOOP QUERY="D">
		<cfif TYPE is "file">
			<cfif ctr lt 500>
				<cfset ctr=ctr+1>
				<cfset fpath=replace(DIRECTORY,'/usr/local/httpd/htdocs/wwwarctos','')>
				<br>fpath: #fpath#
				<cfset qn=fpath & '/' & name>
				<br>qn: #qn#
				<cfquery name="isUsed" datasource="uam_god">
					select count(*) c from media where media_uri like '%#qn#%' or preview_uri like '%#qn#%'
				</cfquery>
				<cfif isUsed.c is 0>
					<cffile action = "move"
						destination = "#Application.webDirectory#/media_notused_movetos3/#name#"
						source = "#DIRECTORY#/#name#">

					<br>notused
				</cfif>
			</cfif>

		</cfif>
	</CFLOOP>

	</cfif>
	<cfif action is "upmuris">
		<cfquery name="d" datasource="uam_god">
			select * from temp_m_f where status ='loaded_to_s3'
			and rownum<100
		</cfquery>
		<cfset f = CreateObject("component","component.functions")>

		<cfloop query="d">
			<hr>
			<br>lcl_p: #lcl_p#
			<br>lcl_p_p: #lcl_p_p#
			<cfset newMediaURI="">
			<cfset newPreviewURI="">
			<cfset newMediaChecksum="">
			<cfset hasExistingCheck=false>
			<cfset probs=false>
			<cfif len(lcl_p) gt 0>
				<br>lcl_p: #lcl_p#
				<br>lcl_p_p: #lcl_p_p#

				<cfset usrnm=lcase(listgetat(lcl_p,1,"/"))>
				<cfset filename=listlast(lcl_p,"/")>
				<cfset lclurl=media_uri>

				<cfset newMediaURI="https://web.corral.tacc.utexas.edu/arctos-s3/#usrnm#/2018-07-25/#filename#">
				<cfset lclchsm=f.genMD5(lclurl)>
				<cfset rmtchsm=f.genMD5(newMediaURI)>
				<br>lclchsm: #lclchsm#
				<br>rmtchsm: #rmtchsm#
				<br>lclurl: #lclurl#
				<br>newMediaURI: #newMediaURI#
				<cfquery name="ckck" datasource="uam_god">
					select LABEL_VALUE from media_labels where MEDIA_LABEL='MD5 checksum' and MEDIA_ID=#MEDIA_ID#
				</cfquery>


				<cfset newMediaChecksum=rmtchsm>

				<cfif lclchsm neq rmtchsm>
					<br>FAIL::nomatch
					<cfset probs=true>
				</cfif>
				<cfif len(ckck.LABEL_VALUE) gt 0>
					<cfset hasExistingCheck=true>
					<cfif ckck.LABEL_VALUE neq lclchsm>
						<cfset probs=true>
						<br>fail:nomatchw/exist
					</cfif>
				</cfif>
			</cfif>

			<cfif len(lcl_p_p) gt 0>
				<cfset usrnm=lcase(listgetat(lcl_p_p,1,"/"))>
				<cfset filename=listlast(lcl_p_p,"/")>
				<cfset lclurl=preview_uri>

				<cfset newPreviewURI="https://web.corral.tacc.utexas.edu/arctos-s3/#usrnm#/2018-07-25/tn/#filename#">
				<cfset lclchsm=f.genMD5(lclurl)>
				<cfset rmtchsm=f.genMD5(newPreviewURI)>
				<br>lclchsm: #lclchsm#
				<br>rmtchsm: #rmtchsm#


				<br>lclurl: #lclurl#
				<br>newPreviewURI: #newPreviewURI#


				<cfif lclchsm neq rmtchsm>
					<br>FAIL::nomatch
					<cfset probs=true>
				</cfif>
			</cfif>

			<p>
				probs: #probs#
			</p>
			<cfif probs is false>
				<cfquery name="upm" datasource="uam_god">
					update media set
					<cfif len(newMediaURI) gt 0>
						media_uri='#newMediaURI#'
					</cfif>
					<cfif len(newPreviewURI) gt 0>
						<cfif len(newMediaURI) gt 0>
							,
						</cfif>
						preview_uri='#newPreviewURI#'
					</cfif>
					where media_id=#media_id#
				</cfquery>
				update media set
					<cfif len(newMediaURI) gt 0>
						media_uri='#newMediaURI#'
					</cfif>
					<cfif len(newPreviewURI) gt 0>
						<cfif len(newMediaURI) gt 0>
							,
						</cfif>
						preview_uri='#newPreviewURI#'
					</cfif>
					where media_id=#media_id#
				<br>
				<cfif hasExistingCheck is false and len(newMediaChecksum) gt 0>
					<cfquery name="iml" datasource="uam_god">
						insert into media_labels (
							MEDIA_LABEL_ID,
							MEDIA_ID,
							MEDIA_LABEL,
							LABEL_VALUE,
							ASSIGNED_BY_AGENT_ID
						) values (
							sq_MEDIA_LABEL_ID.nextval,
							#MEDIA_ID#,
							'MD5 checksum',
							'#newMediaChecksum#',
							2072
						)
					</cfquery>

					insert into media_labels (
						MEDIA_LABEL_ID,
						MEDIA_ID,
						MEDIA_LABEL,
						LABEL_VALUE,
						ASSIGNED_BY_AGENT_ID
					) values (
						sq_MEDIA_LABEL_ID.nextval,
						#MEDIA_ID#,
						'MD5 checksum',
						'#newMediaChecksum#',
						2072
					)

				</cfif>
				<cfquery name="us" datasource="uam_god">
					update temp_m_f set status='move_complete' where media_id=#media_id#
				</cfquery>
			</cfif>
		</cfloop>
	</cfif>

	<cfif action is "cpfls">

		<cfquery name="d" datasource="uam_god">
			select * from temp_m_f where status ='spiffy'
			and rownum<100
		</cfquery>
		<cfquery name="s3" datasource="uam_god" cachedWithin="#CreateTimeSpan(0,1,0,0)#">
			select S3_ENDPOINT,S3_ACCESSKEY,S3_SECRETKEY from cf_global_settings
		</cfquery>
		<cfloop query="d">
			<hr>
			<cfif len(lcl_p) gt 0>
				<br>lcl_p: #lcl_p#
				<!---- make a username bucket. This will create or return an error of some sort. ---->
				<cfset uname=listgetat(lcl_p,1,"/")>
				<br>uname: #uname#
				<cfset currentTime = getHttpTimeString( now() ) />
				<cfset contentType = "text/html" />
				<cfset bucket="#lcase(uname)#">
				<cfset stringToSignParts = [
					    "PUT",
					    "",
					    contentType,
					    currentTime,
					    "/" & bucket
					] />
				<cfset stringToSign = arrayToList( stringToSignParts, chr( 10 ) ) />
				<cfset signature = binaryEncode(
					binaryDecode(
						hmac( stringToSign, s3.s3_secretKey, "HmacSHA1", "utf-8" ),
						"hex"
					),
					"base64"
				)>
				<cfhttp result="mkunamebkt" method="put" url="#s3.s3_endpoint#/#bucket#">
					<cfhttpparam type="header" name="Authorization" value="AWS #s3.s3_accesskey#:#signature#"/>
				    <cfhttpparam type="header" name="Content-Type" value="#contentType#" />
				    <cfhttpparam type="header" name="Date" value="#currentTime#" />
				</cfhttp>
				<br>mkunamebkt: #mkunamebkt.filecontent#


				<cffile variable="content" action = "readBinary" file="#Application.webDirectory#/mediaUploads/#lcl_p#">

				<cfset filename=listlast(lcl_p,"/")>


				<cfset mimetype="FAIL">
				<cfset mediatype="FAIL">
				<cfset fext=listlast(lcl_p,".")>
				<cfif fext is "jpg" or fext is "jpeg">
					<cfset mimetype="image/jpeg">
					<cfset mediatype="image">
				<cfelseif fext is "dng">
					<cfset mimetype="image/dng">
					<cfset mediatype="image">
				<cfelseif fext is "pdf">
					<cfset mimetype="application/pdf">
					<cfset mediatype="text">
				<cfelseif fext is "png">
					<cfset mimetype="image/png">
					<cfset mediatype="image">
				<cfelseif fext is "txt">
					<cfset mimetype="text/plain">
					<cfset mediatype="text">
				<cfelseif fext is "wav">
					<cfset mimetype="audio/x-wav">
					<cfset mediatype="audio">
				<cfelseif fext is "m4v">
					<cfset mimetype="video/mp4">
					<cfset mediatype="video">
				<cfelseif fext is "tif" or fext is "tiff">
					<cfset mimetype="image/tiff">
					<cfset mediatype="image">
				<cfelseif fext is "mp3">
					<cfset mimetype="audio/mpeg3">
					<cfset mediatype="audio">
				<cfelseif fext is "mov">
					<cfset mimetype="video/quicktime">
					<cfset mediatype="video">
				<cfelseif fext is "xml">
					<cfset mimetype="application/xml">
					<cfset mediatype="text">
				<cfelseif fext is "wkt">
					<cfset mimetype="text/plain">
					<cfset mediatype="text">
				</cfif>
				<br>mimetype:#mimetype#
				<br>mediatype:#mediatype#
				<cfset bucket="#lcase(uname)#/#dateformat(now(),'YYYY-MM-DD')#">
				<cfset currentTime = getHttpTimeString( now() ) />
				<cfset contentType=mimetype>
				<cfset contentLength=arrayLen( content )>
				<cfset stringToSignParts = [
				    "PUT",
				    "",
				    contentType,
				    currentTime,
				    "/" & bucket & "/" & fileName
				] />

				<cfset stringToSign = arrayToList( stringToSignParts, chr( 10 ) ) />
				<cfset signature = binaryEncode(
					binaryDecode(
						hmac( stringToSign, s3.s3_secretKey, "HmacSHA1", "utf-8" ),
						"hex"
					),
					"base64"
				)>
				<cfhttp result="putfile" method="put" url="#s3.s3_endpoint#/#bucket#/#fileName#">
					<cfhttpparam type="header" name="Authorization" value="AWS #s3.s3_accesskey#:#signature#"/>
				    <cfhttpparam type="header" name="Content-Length" value="#contentLength#" />
				    <cfhttpparam type="header" name="Content-Type" value="#contentType#"/>
				    <cfhttpparam type="header" name="Date" value="#currentTime#" />
				    <cfhttpparam type="body" value="#content#" />
				</cfhttp>
				<br>putfile: #putfile.filecontent#
			</cfif>

			<cfif len(lcl_p_p) gt 0>
				<br>lcl_p_p: #lcl_p_p#
				<!---- make a username bucket. This will create or return an error of some sort. ---->
				<cfset uname=listgetat(lcl_p_p,1,"/")>
				<br>uname: #uname#
				<cfset currentTime = getHttpTimeString( now() ) />
				<cfset contentType = "text/html" />
				<cfset bucket="#lcase(uname)#">
				<cfset stringToSignParts = [
					    "PUT",
					    "",
					    contentType,
					    currentTime,
					    "/" & bucket
					] />
				<cfset stringToSign = arrayToList( stringToSignParts, chr( 10 ) ) />
				<cfset signature = binaryEncode(
					binaryDecode(
						hmac( stringToSign, s3.s3_secretKey, "HmacSHA1", "utf-8" ),
						"hex"
					),
					"base64"
				)>
				<cfhttp result="mkunamebkt" method="put" url="#s3.s3_endpoint#/#bucket#">
					<cfhttpparam type="header" name="Authorization" value="AWS #s3.s3_accesskey#:#signature#"/>
				    <cfhttpparam type="header" name="Content-Type" value="#contentType#" />
				    <cfhttpparam type="header" name="Date" value="#currentTime#" />
				</cfhttp>
				<br>mkunamebkt: #mkunamebkt.filecontent#


				<cffile variable="content" action = "readBinary" file="#Application.webDirectory#/mediaUploads/#lcl_p_p#">

				<cfset filename=listlast(lcl_p_p,"/")>


				<cfset mimetype="FAIL">
				<cfset mediatype="FAIL">
				<cfset fext=listlast(lcl_p_p,".")>
				<cfif fext is "jpg" or fext is "jpeg">
					<cfset mimetype="image/jpeg">
					<cfset mediatype="image">
				<cfelseif fext is "dng">
					<cfset mimetype="image/dng">
					<cfset mediatype="image">
				<cfelseif fext is "pdf">
					<cfset mimetype="application/pdf">
					<cfset mediatype="text">
				<cfelseif fext is "png">
					<cfset mimetype="image/png">
					<cfset mediatype="image">
				<cfelseif fext is "txt">
					<cfset mimetype="text/plain">
					<cfset mediatype="text">
				<cfelseif fext is "wav">
					<cfset mimetype="audio/x-wav">
					<cfset mediatype="audio">
				<cfelseif fext is "m4v">
					<cfset mimetype="video/mp4">
					<cfset mediatype="video">
				<cfelseif fext is "tif" or fext is "tiff">
					<cfset mimetype="image/tiff">
					<cfset mediatype="image">
				<cfelseif fext is "mp3">
					<cfset mimetype="audio/mpeg3">
					<cfset mediatype="audio">
				<cfelseif fext is "mov">
					<cfset mimetype="video/quicktime">
					<cfset mediatype="video">
				<cfelseif fext is "xml">
					<cfset mimetype="application/xml">
					<cfset mediatype="text">
				<cfelseif fext is "wkt">
					<cfset mimetype="text/plain">
					<cfset mediatype="text">
				</cfif>
				<br>mimetype:#mimetype#
				<br>mediatype:#mediatype#
				<cfset bucket="#lcase(uname)#/#dateformat(now(),'YYYY-MM-DD')#/tn">
				<cfset currentTime = getHttpTimeString( now() ) />
				<cfset contentType=mimetype>
				<cfset contentLength=arrayLen( content )>
				<cfset stringToSignParts = [
				    "PUT",
				    "",
				    contentType,
				    currentTime,
				    "/" & bucket & "/" & fileName
				] />

				<cfset stringToSign = arrayToList( stringToSignParts, chr( 10 ) ) />
				<cfset signature = binaryEncode(
					binaryDecode(
						hmac( stringToSign, s3.s3_secretKey, "HmacSHA1", "utf-8" ),
						"hex"
					),
					"base64"
				)>
				<cfhttp result="putfile" method="put" url="#s3.s3_endpoint#/#bucket#/#fileName#">
					<cfhttpparam type="header" name="Authorization" value="AWS #s3.s3_accesskey#:#signature#"/>
				    <cfhttpparam type="header" name="Content-Length" value="#contentLength#" />
				    <cfhttpparam type="header" name="Content-Type" value="#contentType#"/>
				    <cfhttpparam type="header" name="Date" value="#currentTime#" />
				    <cfhttpparam type="body" value="#content#" />
				</cfhttp>
				<br>putfile: #putfile.filecontent#
			</cfif>

				update temp_m_f set status='loaded_to_s3' where media_id=#media_id#
			<cfquery name="mkup" datasource="uam_god">
				update temp_m_f set status='loaded_to_s3' where media_id=#media_id#
			</cfquery>

		</cfloop>

	</cfif>

















	 <cfif action is "cklcl">
		<cfquery name="d" datasource="uam_god">
			select * from temp_m_f where status is null
		</cfquery>

		<cfloop query="d">
			<cfset s="spiffy">
			<cfif len(lcl_p) gt 0>
				<cfif not FileExists("#Application.webDirectory#/mediaUploads/#lcl_p#")>
					<cfset s=listappend(s,'lcl_p not found')>
				</cfif>
			</cfif>
			<cfif len(lcl_p_p) gt 0>
				<cfif not FileExists("#Application.webDirectory#/mediaUploads/#lcl_p_p#")>
					<cfset s=listappend(s,'lcl_p_p not found')>
				</cfif>
			</cfif>

			<cfquery name="d" datasource="uam_god">
				update temp_m_f set status='#s#' where media_id=#media_id#
			</cfquery>
		</cfloop>
	</cfif>
	 <cfif action is "mklclp">
		<cfquery name="d" datasource="uam_god">
			select * from temp_m_f  where status is null
		</cfquery>
		<cfloop query="d">
			<cfset mf="">
			<cfset pf="">
			<cfif media_uri contains "/mediaUploads/" and media_uri contains "/arctos.database.museum/">
				<cfset mf=media_uri>
				<cfloop from ="1" to="5" index="i">
					<cfif listgetat(mf,1,'/') is not "mediaUploads">
						<cfset mf=listdeleteat(mf,1,'/')>
					</cfif>
				</cfloop>
				<cfset mf=listdeleteat(mf,1,'/')>
				<br>media_uri:#media_uri#
				<br>mf:#mf#
			<cfelse>
				<br>not local
			</cfif>

			<cfif preview_uri contains "/mediaUploads/" and preview_uri contains "/arctos.database.museum/">
				<cfset pf=preview_uri>
				<cfloop from ="1" to="5" index="i">
					<cfif listgetat(pf,1,'/') is not "mediaUploads">
						<cfset pf=listdeleteat(pf,1,'/')>
					</cfif>
				</cfloop>
				<cfset pf=listdeleteat(pf,1,'/')>
				<br>preview_uri:#preview_uri#
				<br>pf:#pf#
			<cfelse>
				<br>not local
			</cfif>
			<cfquery name="d" datasource="uam_god">
				update temp_m_f set lcl_p='#mf#',lcl_p_p='#pf#' where media_id=#media_id#
			</cfquery>
		</cfloop>


	</cfif>
</cfoutput>



<cfinclude template="/includes/_footer.cfm">




<!--------------- old stuff below ----------->
<cfabort>

<p>
	Move media from webserver to archives.
</p>





<p>
	To the great astonishment of absolutely noone, this didn't turn into a nice script. Proceed with caution; aborting.
	<cfabort>
</p>
<!----

little cache to speed things along - probably a good idea to delete from this and start over


create table cf_media_migration (path varchar2(4000),status varchar2(255));


alter table cf_media_migration add fullLocalPath  varchar2(4000);
alter table cf_media_migration add fullRemotePath  varchar2(4000);


select * from cf_media_migration where fullRemotePath like 'STILL%';
---->
<cfoutput>

	<!---- weird migration paths... ---->



	<p>
		 <a href="cleanImages.cfm?action=confirmFullRemotePath">confirmFullRemotePath</a>
	</p>
	<p>
		<a href="cleanImages.cfm?action=confirmFullRemotePath2">confirmFullRemotePath2</a>
	</p>
	<p>
		<a href="cleanImages.cfm?action=confirmFullLocalPath">confirmFullLocalPath</a>
	</p>
	<p>
		<a href="cleanImages.cfm?action=checkLocalDir">checkLocalDir</a> to get all local media into the system
	</p>
	<p>
		<a href="cleanImages.cfm?action=checkFileServer">checkFileServer</a> to see what's where
	</p>
	<p>
		<a href="cleanImages.cfm?action=list_not_found">list_not_found</a> to get a list of the things that are NOT on
		Corral. Send this to TACC, ask them to move stuff
	</p>
	<p>
		<a href="cleanImages.cfm?action=find_not_used">find_not_used</a> to mark things that are NOT used in media
	</p>
	<p>
		<a href="cleanImages.cfm?action=update_media_and_delete__dryRun">update_media_and_delete__dryRun</a>: dry run
	</p>
	<p>
		<a href="cleanImages.cfm?action=stash_not_used">stash_not_used</a>
	</p>
	<p>
		<a href="cleanImages.cfm?action=update_media">update_media</a>
	</p>
	<p>
		<a href="cleanImages.cfm?action=ready_delete_flipped">ready_delete_flipped</a>
	</p>


	<p>
		After stuff has been moved, <a href="cleanImages.cfm?action=update_media_and_delete">update_media_and_delete</a>
		to update the media records and delete the local file
	</p>



<p>

AFTER THINGS HAVE BEEN MOVED TO TACC:
<p>
1)

		<a href="cleanImages.cfm?action=find_mediaUploads2018">find_mediaUploads2018</a>


URLs will need changed. Get the relative path and fill TACC url of everything we just moved.
	</p>
<p>
2) find the file on the arctos webserver


		<a href="cleanImages.cfm?action=find_movedMediaOnArctos">find_movedMediaOnArctos</a>
	</p>

<p>
	3) generate checksums

		<a href="cleanImages.cfm?action=generatechecksums">generatechecksums</a>
	</p>


	<p>
	4) SqLtime - see code for proper formatting.
	</p>
	<p>


	select * from ct_media_migration_aftermove where status='got_checksums' and local_checksum is null;

		select * from ct_media_migration_aftermove where status='got_checksums' and remote_checksum is null;

-- uhh - try again?

update  ct_media_migration_aftermove set status='found_in_arctos_media' where status='got_checksums' and remote_checksum is null;

-- okeedokee, worked....

select * from ct_media_migration_aftermove where status='got_checksums' and local_checksum != remote_checksum;

-- crap

update ct_media_migration_aftermove set status=null where status='got_checksums' and local_checksum != remote_checksum;

-- OK happy now
-- got checksums
-- everything matches
-- update media
-- procedure, because less messy
-- not enough data to worry about speed

-- paranoid though so...

create table temp_media20180227 as select * from media where media_uri in (select WEBSERVER_URL from ct_media_migration_aftermove);
insert into temp_media20180227 (select * from media where PREVIEW_URI in (select WEBSERVER_URL from ct_media_migration_aftermove));

UAM@ARCTOS> select count(*) from temp_media20180227;

  COUNT(*)
----------
      7231


UAM@ARCTOS> select count(*) from ct_media_migration_aftermove where status='got_checksums';

  COUNT(*)
----------
      7231

-- OK, do it
lock table media in exclusive mode nowait;
lock table media_labels in exclusive mode nowait;
lock table media_relations in exclusive mode nowait;
begin
	for r in (select * from ct_media_migration_aftermove where status='got_checksums') loop
		-- URI
		update media set media_uri=r.TACC_URL where media_uri=r.WEBSERVER_URL;
	end loop;
end;
/
select count(*) from media where media_uri in (select webserver_url from ct_media_migration_aftermove);
select count(*) from media where PREVIEW_URI in (select webserver_url from ct_media_migration_aftermove);



lock table media in exclusive mode nowait;
lock table media_labels in exclusive mode nowait;
lock table media_relations in exclusive mode nowait;


begin
	for r in (select * from ct_media_migration_aftermove where status='got_checksums' and rownum < 100) loop
		dbms_output.put_line(r.WEBSERVER_URL);

		-- and preview
		update media set PREVIEW_URI=r.TACC_URL where PREVIEW_URI=r.WEBSERVER_URL;

		update ct_media_migration_aftermove set status='set_preview_got_checksums' where relevant_path=r.relevant_path;
	end loop;
end;
/
- wtf super slow OK...


CREATE OR REPLACE PROCEDURE temp_update_junk IS
begin
  	for r in (select * from ct_media_migration_aftermove where status='got_checksums') loop
		update media set PREVIEW_URI=r.TACC_URL where PREVIEW_URI=r.WEBSERVER_URL;
	end loop;
end;
/


BEGIN
  DBMS_SCHEDULER.CREATE_JOB (
    job_name    => 'J_TEMP_UPDATE_JUNK',
    job_type    => 'STORED_PROCEDURE',
    job_action    => 'temp_update_junk',
    enabled     => TRUE,
    end_date    => NULL
  );
END;
/


select STATE,LAST_START_DATE,NEXT_RUN_DATE from all_scheduler_jobs where JOB_NAME='J_TEMP_UPDATE_JUNK';



		update media set PREVIEW_URI='https://web.corral.tacc.utexas.edu/UAF/arctos/mediaUploads2018/edbril/tn_UA2006_001_0002AB.jpg'
		where PREVIEW_URI='https://arctos.database.museum/mediaUploads/edbril/tn_UA2006_001_0002AB.jpg';




	</p>

	5) move local files to a directory from which they can be deleted

		<a href="cleanImages.cfm?action=moveLocalForDeletion">moveLocalForDeletion</a>
	</p>


	periodically ) delete old unused stuff

		<a href="cleanImages.cfm?action=delteOldUnused">delteOldUnused</a>
	</p>



	<cfif action is "delteOldUnused">

		<!----
			in support of https://github.com/ArctosDB/arctos/issues/897


			find and delte anything that's

			1) not used
			2) more than 90D old
		---->

		<cfdirectory
		    directory = "#application.webDirectory#/mediaUploads/"
		    action = "list"
		    name = "mupldir"
		    recurse = "yes"
		    type = "file">
<!----
		    <cfdump var=#mupldir#>
ATTRIBUTES 	DATELASTMODIFIED 	DIRECTORY 	MODE 	NAME 	SIZE 	TYPE
---->
	<cfset rcnt=0>
	<cfloop query="mupldir">
		<br>DIRECTORY: #DIRECTORY#
		<br>NAME: #NAME#
		<cfset dold=DateDiff("d", DATELASTMODIFIED, now())>
		<br>dold: #dold#
		<cfif rcnt lt 100>

			<!-- exclude onTaccReadyDelete, it's there to be deleted already --->
			<cfif dold gt 90 and directory does not contain "onTaccReadyDelete" and directory does not contain "oldNotUsed">

				<cfset rcnt=rcnt+1>


				<cfset rpath="/mediaUploads/" & listlast(DIRECTORY,"/") & name>



				<cfquery name="isUsed" datasource="uam_god">
					select * from media where
					 PREVIEW_URI like '%arctos.database.museum/%/#rpath#' or
					 media_uri like '%arctos.database.museum/%/#rpath#'
				</cfquery>
				<cfif isUsed.recordcount lt 1>
					<br>DATELASTMODIFIED: #DATELASTMODIFIED#




					<br>rpath: #rpath#
					<br>not used, can delete
					<cfset src="#DIRECTORY#/#NAME#">
					<br>src: #src#


					<cfset dstFldr="#application.webDirectory#/mediaUploads/oldNotUsed/#listlast(DIRECTORY,'/')#">


					<cfset dst="#dstFldr#/#name#">
					<br>dst: #dst#


					<cfif not directoryExists(dstFldr)>
					 <cfdirectory action="create" directory="#dstFldr#">
					</cfif>



					<cffile action = "move" destination = "#dst#" source = "#src#">

				<cfelse>
					<br>rpath: #rpath#
					<br>used in #isUsed.media_id#

				</cfif>
			</cfif>
		</cfif>
	</cfloop>


	</cfif>

	<cfif action is "moveLocalForDeletion">
		<!----
			need a directory

			make it manually

			-bash-4.1$ mkdir onTaccReadyDelete


		---->


		<cfquery name="d" datasource="uam_god">
			select * from ct_media_migration_aftermove where status='ready_to_delete' and rownum<1000
		</cfquery>



		<cfloop query="d">
			<cfquery name="finalCheck" datasource="uam_god">
				select * from media where
				 PREVIEW_URI like '%arctos.database.museum/%/#relevant_path#' or
				 media_uri like '%arctos.database.museum/%/#relevant_path#'
			</cfquery>
			<cfif finalCheck.recordcount is 0>
				<br>#relevant_path# is ready to delete
				<cfset fle=listlast(relevant_path,"/")>
				<cfset fldr=listfirst(relevant_path,"/")>
				<br>fle: #fle#
				<br>fldr: #fldr#
				<cfset dstFldr="#application.webDirectory#/mediaUploads/onTaccReadyDelete/#fldr#">

				<br>dstFldr: #dstFldr#

				<cfset dstFullPath="#dstFldr#/#fle#">

				<br>dstFullPath: #dstFullPath#

				<cfif not directoryExists(dstFldr)>
					 <cfdirectory action="create" directory="#dstFldr#">
				</cfif>


				<cffile action = "move" destination = "#dstFullPath#"
					source = "#application.webDirectory#/mediaUploads/#relevant_path#">
				<cfquery name="d" datasource="uam_god">
					update ct_media_migration_aftermove set status='moved_to_delete_folder' where  relevant_path='#relevant_path#'
				</cfquery>


			</cfif>

		</cfloop>


	</cfif>

	<p>


	</p>
<cfif action is "generatechecksums">
	<!--- this is probably better done in find_movedMediaOnArctos --->
	<!---

		alter table ct_media_migration_aftermove add local_checksum varchar2(4000);
		alter table ct_media_migration_aftermove add remote_checksum varchar2(4000);

	 --->
	<cfquery name="d" datasource="uam_god">
		select * from ct_media_migration_aftermove where status ='found_in_arctos_media' and rownum < 2000
	</cfquery>
	<cfloop query="d">
		<cfinvoke component="/component/functions" method="genMD5" returnVariable="lclHash">
			<cfinvokeargument name="returnFormat" value="plain">
			<cfinvokeargument name="uri" value="#WEBSERVER_URL#">
		</cfinvoke>
		<!--- grab a hash for the remote file ---->
		<cfinvoke component="/component/functions" method="genMD5" returnVariable="rmtHash">
			<cfinvokeargument name="returnFormat" value="plain">
			<cfinvokeargument name="uri" value="#TACC_URL#">
		</cfinvoke>

		<cfquery name="up" datasource="uam_god">
			update ct_media_migration_aftermove set
			local_checksum='#lclHash#',
			remote_checksum='#rmtHash#',
			status='got_checksums'
			where relevant_path='#relevant_path#'
		</cfquery>




	</cfloop>


</cfif>

<cfif action is "find_movedMediaOnArctos">
 <!---
	-- these don't matter...
	delete from ct_media_migration_aftermove where relevant_path like '%Parent Directory';

	-- need a place to stash status
	alter table ct_media_migration_aftermove add status varchar2(255);
	-- and the arctos.database url
	alter table ct_media_migration_aftermove add webserver_url varchar2(4000);

	select status,count(*) from ct_media_migration_aftermove group by status;

	select * from ct_media_migration_aftermove where status='not_found_in_arctos_media';

---->
	<cfquery name="d" datasource="uam_god">
		select relevant_path from ct_media_migration_aftermove where status is null and rownum < 2000
	</cfquery>
	<cfloop query="d">
		<cfset theURL=''>
		<cfquery name="gm" datasource="uam_god">
			select * from media where media_uri like '%/#relevant_path#'
		</cfquery>

		<cfif gm.recordcount is 1>
				<cfset theURL=gm.media_uri>
		<cfelse>
			<!--- maybe it's preview --->
			<cfquery name="gpm" datasource="uam_god">
				select * from media where PREVIEW_URI like '%/#relevant_path#'
			</cfquery>
			<cfif gpm.recordcount is 1>
				<cfset theURL=gpm.PREVIEW_URI>
			</cfif>
		</cfif>

		<cfif len(theURL) gt 0>
			<cfquery name="rslt" datasource="uam_god">
				update ct_media_migration_aftermove set
					status='found_in_arctos_media',
					webserver_url='#theURL#'
					where relevant_path='#relevant_path#'
			</cfquery>
			<br>update ct_media_migration_aftermove set
					status='found_in_arctos_media',
					webserver_url='#theURL#'
					where relevant_path='#relevant_path#'
		<cfelse>
			<cfquery name="rslt" datasource="uam_god">
				update ct_media_migration_aftermove set
					status='NOT__found_in_arctos_media',
					webserver_url='#theURL#'
					where relevant_path='#relevant_path#'
			</cfquery>
			<br>update ct_media_migration_aftermove set
					status='NOT__found_in_arctos_media',
					webserver_url='#theURL#'
					where relevant_path='#relevant_path#'
		</cfif>
	</cfloop>

</cfif>
<cfif action is "find_mediaUploads2018">
	<!--- get path of everything that was just moved to TACC ---->
	<!--- create a new temp table for this, because....
		drop table ct_media_migration_aftermove;

		create table ct_media_migration_aftermove (
			relevant_path varchar2(4000),
			tacc_url varchar2(4000)
		);
	---->


	<cfset fpaths=querynew("p")>

	<cfset baseURL='https://web.corral.tacc.utexas.edu/UAF/arctos/mediaUploads2018'>

	<cfhttp method="get" url="#baseURL#"></cfhttp>
	<cfset xStr=cfhttp.FileContent>
	<cfset xStr= replace(xStr,' xmlns="http://www.w3.org/1999/xhtml" xml:lang="en"','')>
	<cfset xdir=xmlparse(xStr)>
	<cfset dir = xmlsearch(xdir, "//td[@class='n']")>

	<cfloop index="i" from="1" to="#arrayLen(dir)#">
		<cfset folder = dir[i].XmlChildren[1].xmlText>
		<br>folder: #folder#
		<cfhttp url="#baseURL#/#folder#" charset="utf-8" method="get"></cfhttp>

		<hr>got #folder#....
		<cfset ximgStr=cfhttp.FileContent>
		<!--- goddamned xmlns bug in CF --->
		<cfset ximgStr = replace(ximgStr,' xmlns="http://www.w3.org/1999/xhtml" xml:lang="en"','')>
		<cfset xImgAll=xmlparse(ximgStr)>
		<cfset xImage = xmlsearch(xImgAll, "//td[@class='n']")>
		<cfloop index="i" from="1" to="#arrayLen(xImage)#">
			<cfset fname = xImage[i].XmlChildren[1].xmlText>
			<br>fname: #fname#
			<cfquery name="d" datasource="uam_god">
				insert into ct_media_migration_aftermove (
					relevant_path,
					tacc_url) values (
					'#folder#/#fname#',
					'#baseURL#/#folder#/#fname#'
				)
			</cfquery>
		</cfloop>





	</cfloop>

</cfif>


	<cfif action is "ready_delete_flipped">
		<cfquery name="d" datasource="uam_god">
			select path from cf_media_migration where status='media_uris_flipped' and rownum<2000
		</cfquery>

		<cfloop query="d">
			<cftransaction>
			<br>#path#
			<cfset uname=listgetat(path,1,"/")>
			<cfset fname=listlast(path,"/")>
			<!--- dir exists? --->
			<cfif not DirectoryExists("#application.webDirectory#/download/temp_media_movetocorral/#uname#")>
				<!--- make it ---->
				<br>does not exist,making #application.webDirectory#/download/temp_media_movetocorral/#uname#
				<cfset DirectoryCreate("#application.webDirectory#/download/temp_media_movetocorral/#uname#")>
			</cfif>
			<!--- now move --->
			<br>moving #application.webDirectory#/mediaUploads/#path# to #application.webDirectory#/download/temp_media_movetocorral/#uname#/#fname#
			<cffile action = "move" destination = "#application.webDirectory#/download/temp_media_movetocorral/#uname#/#fname#"
				source = "#application.webDirectory#/mediaUploads/#path#">
			<br>moved....
			<cfquery name="ms" datasource="uam_god">
				update cf_media_migration set status='moved_to_junk' where path='#path#'
			</cfquery>
			</cftransaction>
		</cfloop>

	</cfif>




<cfif action is "update_media">
		<!---barf out sql ---->
		<cfquery name="d" datasource="uam_god">
			select * from  cf_media_migration where status='dry_run_happy' and rownum < 2000 order by path
		</cfquery>
		<cfset lclURL=replace(application.serverRootURL,'https://','http://')>
		<cfloop query="d">
			<cftransaction>
				<br>#path#
				<!---- make sure we're using this thing --->
				<cfquery name="mid" datasource="uam_god">
					select media_id from media where replace(media_uri,'https://','http://')='#lclURL#/mediaUploads#path#'
				</cfquery>
				<cfif len(mid.media_id) gt 0>
					<cfset usedas='media_uri'>
				<cfelse>
					<cfquery name="mid" datasource="uam_god">
						select media_id from media where replace(preview_uri,'https://','http://')='#lclURL#/mediaUploads#path#'
					</cfquery>
					<cfif len(mid.media_id) gt 0>
						<cfset usedas='preview_uri'>
					<cfelse>
						<cfset usedas='nothing'>
					</cfif>
				</cfif>
				<cfif usedas is 'nothing'>
					<br>not used!!
					<cfquery name="orp" datasource="uam_god">
						update cf_media_migration set status='found_on_corral_not_used_in_media' where path='#path#'
					</cfquery>
				<cfelse>
					<br>used, rock on....
					<br>media_id: #mid.media_id#
					<br>FULLLOCALPATH: #FULLLOCALPATH#
					<br>FULLREMOTEPATH: #FULLREMOTEPATH#



						<!--- now switcharoo media_uri or preview_uri.... ---->
						<!----
						<cfquery name="upmuri" datasource="uam_god">
							update media set #usedas#='https://web.corral.tacc.utexas.edu/UAF/arctos/mediaUploads#path#'
							where media_id=#mid.media_id#
						</cfquery>
						---->

						<br>update media set #usedas#='#FULLREMOTEPATH#' where media_id=#mid.media_id#
						<cfquery name="upm" datasource="uam_god">
							update media set #usedas#='#FULLREMOTEPATH#' where media_id=#mid.media_id#
						</cfquery>
						<br>update media_flat set #usedas#='#FULLREMOTEPATH#' where media_id=#mid.media_id#
						<cfquery name="upmf" datasource="uam_god">
							update media_flat set #usedas#='#FULLREMOTEPATH#' where media_id=#mid.media_id#
						</cfquery>
						<cfquery name="upmm" datasource="uam_god">
							update cf_media_migration set status='media_uris_flipped' where path='#path#'
						</cfquery>

						<!----  ....and delete the local file ---->
						<br>update cf_media_migration set status='media_uris_flipped' where path='#path#'


						<!----
						<cfquery name="orp" datasource="uam_god">
							update cf_media_migration set status='add_moved_over_ready_to_delete' where path='#path#'
						</cfquery>


						<cfquery name="orp" datasource="uam_god">
							update cf_media_migration set status='dry_run_happy' where path='#path#'
						</cfquery>
						<br>update cf_media_migration set status='dry_run_happy' where path='#path#'
						---->


						<!----
						<cffile action = "delete" file = "#application.webDirectory#/mediaUploads/#path#">
						---->

				</cfif>
			</cftransaction>
		</cfloop>
	</cfif>








	<cfif action is "stash_not_used">
		<cfquery name="d" datasource="uam_god">
			select path from cf_media_migration where status='found_on_corral_not_used_in_media' and rownum<200
		</cfquery>

		<cfloop query="d">
			<cftransaction>
			<br>#path#
			<cfset uname=listgetat(path,1,"/")>
			<cfset fname=listlast(path,"/")>
			<!--- dir exists? --->
			<cfif not DirectoryExists("#application.webDirectory#/download/temp_media_notused/#uname#")>
				<!--- make it ---->
				<br>does not exist,making #application.webDirectory#/download/temp_media_notused/#uname#
				<cfset DirectoryCreate("#application.webDirectory#/download/temp_media_notused/#uname#")>
			</cfif>
			<!--- now move --->
			<br>moving #application.webDirectory#/mediaUploads/#path# to #application.webDirectory#/download/temp_media_notused/#uname#/#fname#
			<cffile action = "move" destination = "#application.webDirectory#/download/temp_media_notused/#uname#/#fname#"
				source = "#application.webDirectory#/mediaUploads/#path#">
			<br>moved....
			<cfquery name="ms" datasource="uam_god">
				update cf_media_migration set status='stashed_as_notused' where path='#path#'
			</cfquery>
			</cftransaction>
		</cfloop>

	</cfif>

	<cfif action is "confirmFullRemotePath2">
		<cfquery name="d" datasource="uam_god">
			select * from cf_media_migration where fullRemotePath like 'STILLNOT %'
		</cfquery>
		<cfloop query="d">
			<cfset rp='http://web.corral.tacc.utexas.edu/UAF/arctos/mediaUploads/20170607/' & listlast(path,'/')>
			<br>#rp#

			<cfhttp method="head" url="#rp#"></cfhttp>
			<cfif cfhttp.statusCode is '200 OK'>
				<cfquery name="fl" datasource="uam_god">
					update cf_media_migration set fullRemotePath='#rp#' where path='#path#'
				</cfquery>
				<br>ishappy
			<cfelse>
				<cfquery name="fl" datasource="uam_god">
					update cf_media_migration set fullRemotePath='ANOTHERMISS #rp#' where path='#path#'
				</cfquery>
				<br>unhappy
			</cfif>
			---------->
		</cfloop>
	</cfif>




	<cfif action is "confirmFullRemotePath">
		<cfquery name="d" datasource="uam_god">
			select * from cf_media_migration where fullRemotePath is null
		</cfquery>
		<cfloop query="d">
			<cfset rp='https://web.corral.tacc.utexas.edu/UAF/arctos/mediaUploads2018/' & #path#>
			<br>#rp#
			<cfhttp method="head" url="#rp#"></cfhttp>
			<cfif cfhttp.statusCode is '200 OK'>
				<cfquery name="fl" datasource="uam_god">
					update cf_media_migration set fullRemotePath='#rp#' where path='#path#'
				</cfquery>
				<br>happy
			<cfelse>
				<cfquery name="fl" datasource="uam_god">
					update cf_media_migration set fullRemotePath='NOT #rp#' where path='#path#'
				</cfquery>
				<br>unhappy
			</cfif>
		</cfloop>
	</cfif>
	<cfif action is "confirmFullLocalPath">
		<cfquery name="d" datasource="uam_god">
			select * from cf_media_migration where fullLocalPath is null
		</cfquery>
		<cfloop query="d">
			<cfset lp=replace(application.serverRootURL,'https://','http://') & '/mediaUploads' & #path#>
			<br>#lp#
			<cfhttp method="head" url="#lp#"></cfhttp>
			<cfif cfhttp.statusCode is '200 OK'>
				<cfquery name="fl" datasource="uam_god">
					update cf_media_migration set fullLocalPath='#lp#' where path='#path#'
				</cfquery>
				<br>happy
			<cfelse>
				<cfdump var=#cfhttp#>
			</cfif>
		</cfloop>
	</cfif>
	<cfif action is "find_not_used">
		<!--- find and flag stuff that's not used. That's it. ---->
		<!---

		update cf_media_migration set status='found_on_corral' where fullRemotePath is not null;

		--->
		<cfquery name="d" datasource="uam_god">
			select * from  cf_media_migration where status='found_on_corral' and rownum < 501 order by path
		</cfquery>
		<cfset lclURL=replace(application.serverRootURL,'https://','http://')>
		<cfloop query="d">
			<cftransaction>
				<br>#path#
				<!---- make sure we're using this thing --->
				<cfquery name="mid" datasource="uam_god">
					select media_id from media where replace(media_uri,'https://','http://')='#lclURL#/mediaUploads#path#'
				</cfquery>
				<cfif len(mid.media_id) gt 0>
					<cfset usedas='media_uri'>
				<cfelse>
					<cfquery name="mid" datasource="uam_god">
						select media_id from media where replace(preview_uri,'https://','http://')='#lclURL#/mediaUploads#path#'
					</cfquery>
					<cfif len(mid.media_id) gt 0>
						<cfset usedas='preview_uri'>
					<cfelse>
						<cfset usedas='nothing'>
					</cfif>
				</cfif>
				<cfif usedas is 'nothing'>
					<br>not used!!
					<cfquery name="orp" datasource="uam_god">
						update cf_media_migration set status='found_on_corral_not_used_in_media' where path='#path#'
					</cfquery>
				<cfelse>
					<cfquery name="orp" datasource="uam_god">
						update cf_media_migration set status='found_on_corral_confirm_used_in_media' where path='#path#'
					</cfquery>
					<br>is used, flag so we can ignore on next loop....
				</cfif>
			</cftransaction>
			<cfflush>
		</cfloop>
	</cfif>

	<cfif action is "update_media_and_delete__dryRun">
		<!---barf out sql ---->
		<cfquery name="d" datasource="uam_god">
			select * from  cf_media_migration where status='found_on_corral_confirm_used_in_media' and rownum < 2000 order by path
		</cfquery>
		<cfset lclURL=replace(application.serverRootURL,'https://','http://')>
		<cfloop query="d">
			<cftransaction>
				<br>#path#
				<!---- make sure we're using this thing --->
				<cfquery name="mid" datasource="uam_god">
					select media_id from media where replace(media_uri,'https://','http://')='#lclURL#/mediaUploads#path#'
				</cfquery>
				<cfif len(mid.media_id) gt 0>
					<cfset usedas='media_uri'>
				<cfelse>
					<cfquery name="mid" datasource="uam_god">
						select media_id from media where replace(preview_uri,'https://','http://')='#lclURL#/mediaUploads#path#'
					</cfquery>
					<cfif len(mid.media_id) gt 0>
						<cfset usedas='preview_uri'>
					<cfelse>
						<cfset usedas='nothing'>
					</cfif>
				</cfif>
				<cfif usedas is 'nothing'>
					<br>not used!!
					<cfquery name="orp" datasource="uam_god">
						update cf_media_migration set status='found_on_corral_not_used_in_media' where path='#path#'
					</cfquery>
				<cfelse>
					<br>used, rock on....
					<br>media_id: #mid.media_id#
					<br>FULLLOCALPATH: #FULLLOCALPATH#
					<br>FULLREMOTEPATH: #FULLREMOTEPATH#
					<!--- grab a hash for the local file ---->
					<cfinvoke component="/component/functions" method="genMD5" returnVariable="lclHash">
						<cfinvokeargument name="returnFormat" value="plain">
						<cfinvokeargument name="uri" value="#FULLLOCALPATH#">
					</cfinvoke>
					<Cfdump var=#lclHash#>
					<!--- grab a hash for the remote file ---->
					<cfinvoke component="/component/functions" method="genMD5" returnVariable="rmtHash">
						<cfinvokeargument name="returnFormat" value="plain">
						<cfinvokeargument name="uri" value="#FULLREMOTEPATH#">
					</cfinvoke>
					<Cfdump var=#rmtHash#>
					<cfif len(lclHash) gt 0 and len(rmtHash) gt 0 and lclHash eq rmtHash>
						<br>hash match!
						<!--- already got a hash stored with the image?? --->
						<!--- only do this if it's media; not for thumbs ---->

						<cfif  usedas is 'media_uri'>
							<cfquery name="hh" datasource="uam_god">
								select count(*) c from media_labels where MEDIA_ID=#mid.media_id# and media_label='MD5 checksum'
							</cfquery>
							<cfif hh.c is 0>
								<br>insert into media_labels (
									MEDIA_LABEL_ID,
									MEDIA_ID,
									MEDIA_LABEL,
									LABEL_VALUE,
									ASSIGNED_BY_AGENT_ID
								) values (
									sq_MEDIA_LABEL_ID.nextval,
									#mid.media_id#,
									'MD5 checksum',
									'#lclHash#',
									#session.myAgentID#
								)
								<cfquery name="ilbl" datasource="uam_god">
									insert into media_labels (
										MEDIA_LABEL_ID,
										MEDIA_ID,
										MEDIA_LABEL,
										LABEL_VALUE,
										ASSIGNED_BY_AGENT_ID
									) values (
										sq_MEDIA_LABEL_ID.nextval,
										#mid.media_id#,
										'MD5 checksum',
										'#lclHash#',
										#session.myAgentID#
									)
								</cfquery>
							</cfif>
						<cfelse>
							<br>is thumb, no label necessary
						</cfif>
						<!--- now switcharoo media_uri or preview_uri.... ---->
						<!----
						<cfquery name="upmuri" datasource="uam_god">
							update media set #usedas#='https://web.corral.tacc.utexas.edu/UAF/arctos/mediaUploads#path#'
							where media_id=#mid.media_id#
						</cfquery>
						---->
						<br>
						update media set #usedas#='https://web.corral.tacc.utexas.edu/UAF/arctos/mediaUploads#path#'
							where media_id=#mid.media_id#
						<!----  ....and delete the local file ---->
						<br>deleting #application.webDirectory#/mediaUploads/#path#
						<!----
						<cfquery name="orp" datasource="uam_god">
							update cf_media_migration set status='add_moved_over_ready_to_delete' where path='#path#'
						</cfquery>
						---->
						<cfquery name="orp" datasource="uam_god">
							update cf_media_migration set status='dry_run_happy' where path='#path#'
						</cfquery>
						<br>update cf_media_migration set status='dry_run_happy' where path='#path#'

						<!----
						<cffile action = "delete" file = "#application.webDirectory#/mediaUploads/#path#">
						---->
					<cfelse>
						<cfquery name="orp" datasource="uam_god">
							update cf_media_migration set status='found_on_corral_bad_checksum' where path='#path#'
						</cfquery>
						<br>update cf_media_migration set status='found_on_corral_bad_checksum' where path='#path#'
					</cfif>
				</cfif>
			</cftransaction>
		</cfloop>
	</cfif>



	<cfif action is "update_media_and_delete">


	<cfabort>


		<cfquery name="d" datasource="uam_god">
			select * from  cf_media_migration where status='found_on_corral' and rownum < 2 order by path
		</cfquery>
		<cfset lclURL=replace(application.serverRootURL,'https://','http://')>
		<cfloop query="d">
			<cftransaction>
				<br>#path#
				<!---- make sure we're using this thing --->
				<cfquery name="mid" datasource="uam_god">
					select media_id from media where replace(media_uri,'https://','http://')='#lclURL#/mediaUploads#path#'
				</cfquery>
				<cfif len(mid.media_id) gt 0>
					<cfset usedas='media_uri'>
				<cfelse>
					<cfquery name="mid" datasource="uam_god">
						select media_id from media where replace(preview_uri,'https://','http://')='#lclURL#/mediaUploads#path#'
					</cfquery>
					<cfif len(mid.media_id) gt 0>
						<cfset usedas='preview_uri'>
					<cfelse>
						<cfset usedas='nothing'>
					</cfif>
				</cfif>
				<cfif usedas is 'nothing'>
					<br>not used!!
					<cfquery name="orp" datasource="uam_god">
						update cf_media_migration set status='found_on_corral_not_used_in_media' where path='#path#'
					</cfquery>
				<cfelse>
					<br>used, rock on....
					<br>media_id: #mid.media_id#
					<!--- grab a hash for the local file ---->
					<cfinvoke component="/component/functions" method="genMD5" returnVariable="lclHash">
						<cfinvokeargument name="returnFormat" value="plain">
						<cfinvokeargument name="uri" value="#lclURL#/mediaUploads#path#">
					</cfinvoke>
					<Cfdump var=#lclHash#>
					<!--- grab a hash for the remote file ---->
					<cfinvoke component="/component/functions" method="genMD5" returnVariable="rmtHash">
						<cfinvokeargument name="returnFormat" value="plain">
						<cfinvokeargument name="uri" value="http://web.corral.tacc.utexas.edu/UAF/arctos/mediaUploads#path#">
					</cfinvoke>
					<Cfdump var=#rmtHash#>
					<cfif len(lclHash) gt 0 and len(rmtHash) gt 0 and lclHash eq rmtHash>
						<br>hash match!
						<!--- already got a hash stored with the image?? --->
						<cfquery name="hh" datasource="uam_god">
							select count(*) c from media_labels where MEDIA_ID=#mid.media_id# and media_label='MD5 checksum'
						</cfquery>
						<cfdump var=#hh#>
						<cfif hh.c is 0>
							<br>insert into media_labels (
								MEDIA_LABEL_ID,
								MEDIA_ID,
								MEDIA_LABEL,
								LABEL_VALUE,
								ASSIGNED_BY_AGENT_ID
							) values (
								sq_MEDIA_LABEL_ID.nextval,
								#mid.media_id#,
								'MD5 checksum',
								'#lclHash#',
								#session.myAgentID#
							)
							<cfquery name="ilbl" datasource="uam_god">
								insert into media_labels (
									MEDIA_LABEL_ID,
									MEDIA_ID,
									MEDIA_LABEL,
									LABEL_VALUE,
									ASSIGNED_BY_AGENT_ID
								) values (
									sq_MEDIA_LABEL_ID.nextval,
									#mid.media_id#,
									'MD5 checksum',
									'#lclHash#',
									#session.myAgentID#
								)
							</cfquery>

						</cfif>
						<!--- now switcharoo media_uri or preview_uri.... ---->
						<cfquery name="upmuri" datasource="uam_god">
							update media set #usedas#='https://web.corral.tacc.utexas.edu/UAF/arctos/mediaUploads#path#'
							where media_id=#mid.media_id#
						</cfquery>
						<br>
						update media set #usedas#='https://web.corral.tacc.utexas.edu/UAF/arctos/mediaUploads#path#'
							where media_id=#mid.media_id#
						<!----  ....and delete the local file ---->
						<br>deleting #application.webDirectory#/mediaUploads/#path#

						<cfquery name="orp" datasource="uam_god">
							update cf_media_migration set status='add_moved_over_ready_to_delete' where path='#path#'
						</cfquery>
						<!----
						<cffile action = "delete" file = "#application.webDirectory#/mediaUploads/#path#">
						---->
					<cfelse>
						<cfquery name="orp" datasource="uam_god">
							update cf_media_migration set status='found_on_corral_bad_checksum' where path='#path#'
						</cfquery>
						<br>update cf_media_migration set status='found_on_corral_bad_checksum' where path='#path#'
					</cfif>
				</cfif>
			</cftransaction>
		</cfloop>
	</cfif>
	<cfif action is "checkFileServer">
		<!--- get 'new' stuff; list as text. Send this to TACC, request a move ---->
		<cfquery name="d" datasource="uam_god">
			select * from  cf_media_migration where status not like 'found_on_corral%' order by path
		</cfquery>
		<cfloop query="d">
			<br>checking http://web.corral.tacc.utexas.edu/UAF/arctos/mediaUploads#path#
			<cfhttp url='http://web.corral.tacc.utexas.edu/UAF/arctos/mediaUploads#path#' method="head"></cfhttp>
			<cfdump var=#cfhttp.Statuscode#>
			<cfif left(cfhttp.Statuscode,3) is "200">
				<cfset newstatus='found_on_corral'>
			<cfelse>
				<cfset newstatus='not_found_on_corral'>
			</cfif>
			<cfquery name="u" datasource="uam_god">
				update cf_media_migration set status='#newstatus#' where path='#path#'
			</cfquery>
		</cfloop>
	</cfif>
	<cfif action is "list_not_found">
		<!--- get 'new' stuff; list as text. Send this to TACC, request a move ---->
		<cfquery name="found_new" datasource="uam_god">
			select * from  cf_media_migration where status='not_found_on_corral' order by path
		</cfquery>
		<cfloop query="found_new">
			<br>#Application.webDirectory#/mediaUploads#path#
		</cfloop>
	</cfif>

	<cfif action is "checkLocalDir">
		<!--- first make sure we know about everything in the local directory ---->
		<CFDIRECTORY
			ACTION="List"
			DIRECTORY="#Application.webDirectory#/mediaUploads"
			NAME="mediaUploads"
			recurse="yes"
			type="file">
		<cfquery name="cf_media_migration" datasource="uam_god">
			select * from cf_media_migration
		</cfquery>
		<cfloop query="mediaUploads">
			<cfset dirpath="#DIRECTORY#/#name#">
			<br>DIRECTORY: #DIRECTORY#
			<br>name: #name#
			<br>dirpath: #dirpath#
			<cfset basepath=replace(dirpath,"#Application.webDirectory#/mediaUploads",'')>
			<br>basepath: #basepath#
			<cfquery name="alreadygotone" dbtype="query">
				select count(*) c from cf_media_migration where path='#basepath#'
			</cfquery>
			<cfif alreadygotone.c lt 1>
				<br>this is new insert into processing table
				<cfquery name="found_new" datasource="uam_god">
					insert into cf_media_migration (path,status) values ('#basepath#','new')
				</cfquery>
			</cfif>
		</cfloop>
	</cfif>



<!----

		<p>

			<cfquery name="alreadygotone" dbtype="query">
				select count(*) c from cf_media_migration where path='#dirpath#'
			</cfquery>
			<cfif alreadygotone.c gt 0>
				<p>this file is already being processed.....</p>
			<cfelse>
				<p>
					this file is new....inserting into migration workflow
				</p>
					<cfquery name="found_new" datasource="uam_god">
						insert into cf_media_migration (path,status) values (
					</cfquery>





				<br>dirpath: #dirpath#
				<cfset olddpath=replace(dirpath,"/usr/local/httpd/htdocs/wwwarctos",application.serverRootURL)>
				<br>olddpath: #olddpath#
				<cfset newpath=replace(dirpath,"/usr/local/httpd/htdocs/wwwarctos","http://web.corral.tacc.utexas.edu/UAF/arctos")>
				<br>newpath: #newpath#
				<cfquery name="old_media" datasource="uam_god">
					select count(*) c from media where media_uri='#olddpath#'
				</cfquery>
				<cfquery name="old_thumb" datasource="uam_god">
					select count(*) c from media where PREVIEW_URI='#olddpath#'
				</cfquery>
				<cfquery name="new_media" datasource="uam_god">
					select count(*) c from media where media_uri='#newpath#'
				</cfquery>
				<cfquery name="new_thumb" datasource="uam_god">
					select count(*) c from media where PREVIEW_URI='#newpath#'
				</cfquery>
				<!---- only do things where
					- old is NOT used
					- new IS used

					anything else could be mid-processing
				---->

				<cfif old_media.c is 0 and old_thumb.c is 0 and (new_media.c gt 0 or new_thumb.c gt 0)>
					<br>DELETING #DIRECTORY#/#name#

					<!----
					<cffile action = "delete" file = "#DIRECTORY#/#name#">
					---->

				<cfelseif old_media.c is 1 and new_media.c is 0>
					<cfhttp url='#newpath#' method="head"></cfhttp>
					<cfif cfhttp.statuscode is "200 OK">
						<br>update media set media_uri='#newpath#' where media_uri='#olddpath#'

						<!----
						<cfquery name="udm" datasource="uam_god">
							update media set media_uri='#newpath#' where media_uri='#olddpath#'
						</cfquery>
						---->
					<cfelse>

					<!----
						<cfquery name="ss" datasource="uam_god">
							insert into cf_media_migration (path,status) values ('#dirpath#','new_not_found')
						</cfquery>
					----->
						<br>WONKY NEW NOT FOUND!!
					</cfif>
				<cfelseif old_thumb.c is 1 and new_thumb.c is 0>
					<cfhttp url='#newpath#' method="head"></cfhttp>
					<cfif cfhttp.statuscode is "200 OK">
						<br>update media set preview_uri='#newpath#' where preview_uri='#olddpath#'
						<!-----
						<cfquery name="udmp" datasource="uam_god">
							update media set preview_uri='#newpath#' where preview_uri='#olddpath#'
						</cfquery>
						---->
					<cfelse>
						<!----
						<cfquery name="ss" datasource="uam_god">
							insert into cf_media_migration (path,status) values ('#dirpath#','new_not_found')
						</cfquery>
						---->
						<br>WONKY NEW NOT FOUND!!
					</cfif>
				<cfelse>
				<!----
						<cfquery name="ss" datasource="uam_god">
							insert into cf_media_migration (path,status) values ('#dirpath#','not_used')
						</cfquery>
						---->
					<br>CAUTION:
					<br>old_media.c: #old_media.c#
					<br>old_thumb.c: #old_thumb.c#
					<br>new_media.c: #new_media.c#
					<br>new_thumb.c: #new_thumb.c#
				</cfif>

			</cfif>
			<!----
			<cfif old.c is 0>
				<br>the old path is not used....
			<cfelse>
				<br>CAUTION: old path IS used
			</cfif>
			<cfquery name="new" datasource="uam_god">
				select count(*) c from media where media_uri='#newpath#' or PREVIEW_URI='#newpath#'
			</cfquery>
			<cfif new.c is 0>
				<br>CAUTION: the new path is not used....
			<cfelseif new.c is 1>
				<br>new path IS used
			<cfelse>
				<br>WUT??
			</cfif>
			<cfif old.c is 0 and new.c is 1>
				<cfscript>
					variables.joFileWriter.writeLine('rm #DIRECTORY#/#name#');
				</cfscript>

				<br>everything looks in order this can probably be deleted
			</cfif>
			---->
		</p>
		---------->



</cfoutput>
<cfinclude template="/includes/_footer.cfm">