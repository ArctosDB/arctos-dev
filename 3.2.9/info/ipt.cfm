
<!----
https://github.com/ArctosDB/arctos/issues/1789

alter table collection add geographic_description varchar2(4000);
alter table collection add west_bounding_coordinate number;
alter table collection add east_bounding_coordinate number;
alter table collection add north_bounding_coordinate number;
alter table collection add south_bounding_coordinate number;
alter table collection add general_taxonomic_coverage varchar2(4000);
alter table collection add taxon_name_rank varchar2(4000);
alter table collection add taxon_name_value varchar2(4000);
alter table collection add purpose_of_collection varchar2(4000);
alter table collection add citation varchar2(4000);
alter table collection add specimen_preservation_method varchar2(4000);
alter table collection add time_coverage varchar2(4000);

<livingTimePeriod>



alter table collection add alternate_identifier_1 varchar2(4000);
alter table collection add alternate_identifier_2 varchar2(4000);


alternateIdentifier

    taxonomicCoverage?

need new fields in metadata

    generalTaxonomicCoverage (free text)
    taxonRankName (select from CTTAXON_TERM)
    taxonRankValue (select from SCIENTIFIC NAME)

    purpose?

need new field in metadata - Purpose of Collection (free text)

    citation?

An example of a citation is
Mayfield T (2018): UTEP Zoo (Arctos). v1.3. University of Texas at El Paso Biodiversity Collections. Dataset/Occurrence. http://ipt.vertnet.org:8080/ipt/resource?r=utep_bird&amp;v=1.3
New field (free text) OR build with "Data Quality Contact (Year of last edit to metadata): GUID_Prefix (Arctos). v(need a version counter) Institution. Need field for ipt resource address


---->


<cfinclude template="/includes/_header.cfm">
<cfset title='EML Generator'>
<cfoutput>
	<cffunction name="formatAgent">
	    <cfargument name="collection_id" type="string" required="true" />
	    <cfargument name="role" type="string" required="true"  />
	    <cfargument name="lbl" type="string" required="true"  />
	    <cfargument name="ntabs" type="numeric" required="true"  />
	    <cfset btbs="">
	    <cfloop from ="1" to="#ntabs#" index="ti">
			<cfset btbs=btbs & chr(9)>
		</cfloop>
		<!--- can't use the get_address function here; it concatenates ---->
		<!--- two queries to somewhat normalize ---->
		<cfquery name="cc" datasource="uam_god">
			select
				collection_contacts.CONTACT_AGENT_ID agent_id,
				agent_name.agent_name_type,
				agent_name.agent_name
			from
				collection_contacts,
				agent_name
			where
				collection_contacts.CONTACT_AGENT_ID=agent_name.agent_id and
				COLLECTION_ID=#COLLECTION_ID# and
				CONTACT_ROLE='#role#'
		</cfquery>
		<cfquery name="aa" datasource="uam_god">
			select
				collection_contacts.CONTACT_AGENT_ID agent_id,
				address.address,
				address.address_type
			from
				collection_contacts,
				address
			where
				address.end_date is null and
				collection_contacts.CONTACT_AGENT_ID=address.agent_id and
				COLLECTION_ID=#COLLECTION_ID# and
				CONTACT_ROLE='#role#'
		</cfquery>
		<cfquery name="da" dbtype="query">
			select agent_id from cc group by agent_id order by agent_id
		</cfquery>
		<cfset x="">
		<cfloop query="da">
			<cfquery name="thisJSONA" dbtype="query">
				select address from aa where agent_id=#da.agent_id# and address_type='formatted JSON'
			</cfquery>
			<cfset x=x & chr(10) & btbs & '<#lbl#>'>
			<cfset x=x & chr(10) & btbs & chr(9) & '<individualName>'>
			<cfquery name="thisQ" dbtype="query">
				select agent_name from cc where agent_id=#da.agent_id# and agent_name_type='first name'
			</cfquery>
			<cfloop query="thisQ">
				<cfset x=x & chr(10) & btbs & chr(9) & chr(9) & '<givenName>#EncodeForXML(thisQ.agent_name)#</givenName>'>
			</cfloop>
			<cfquery name="thisQ" dbtype="query">
				select agent_name from cc where  agent_id=#da.agent_id# and agent_name_type='last name'
			</cfquery>
			<cfloop query="thisQ">
				<cfset x=x & chr(10) & btbs & chr(9) & chr(9) & '<surName>#EncodeForXML(thisQ.agent_name)#</surName>'>
			</cfloop>
			<cfset x=x & chr(10) & btbs & chr(9) & '</individualName>'>
			<cfloop query="thisJSONA">
				<cfif isjson(address)>
					<cfset jadr=DeserializeJSON(address)>
					<cfif structkeyexists(jadr,"ORGANIZATION")>
						<cfset x=x & chr(10) & btbs & chr(9) & '<organizationName>#EncodeForXML(jadr.ORGANIZATION)#</organizationName>'>
					</cfif>
				</cfif>
			</cfloop>
			<cfquery name="thisQ" dbtype="query">
				select agent_name from cc where agent_id=#da.agent_id# and agent_name_type='job title'
			</cfquery>
			<cfloop query="thisQ">
				<cfset x=x & chr(10) & btbs & chr(9) &  '<positionName>#thisQ.agent_name#</positionName>'>
			</cfloop>
			<cfloop query="thisJSONA">
				<cfif isjson(address)>
					<cfset jadr=DeserializeJSON(address)>
					<cfset x=x & chr(10) & btbs & chr(9) & '<address>'>

					<cfif structkeyexists(jadr,"STREET")>
						<cfset x=x & chr(10) & btbs & chr(9) & chr(9) &  '<deliveryPoint>#EncodeForXML(jadr.STREET)#</deliveryPoint>'>
					</cfif>
					<cfif structkeyexists(jadr,"CITY")>
						<cfset x=x & chr(10) & btbs & chr(9) & chr(9) &  '<city>#EncodeForXML(jadr.CITY)#</city>'>
					</cfif>
					<cfif structkeyexists(jadr,"STATE_PROV")>
						<cfset x=x & chr(10) & btbs & chr(9) & chr(9) &  '<administrativeArea>#EncodeForXML(jadr.STATE_PROV)#</administrativeArea>'>
					</cfif>
					<cfif structkeyexists(jadr,"POSTAL_CODE")>
						<cfset x=x & chr(10) & btbs & chr(9) & chr(9) &  '<postalCode>#EncodeForXML(jadr.POSTAL_CODE)#</postalCode>'>
					</cfif>
					<cfif structkeyexists(jadr,"COUNTRY")>
						<cfset x=x & chr(10) & btbs & chr(9) & chr(9) &  '<country>#EncodeForXML(jadr.COUNTRY)#</country>'>
					</cfif>
					<cfset x=x & chr(10) & btbs & chr(9) &  '</address>'>
				</cfif>
			</cfloop>
			<cfquery name="thisQ" dbtype="query">
				select address from aa where agent_id=#da.agent_id# and address_type='phone'
			</cfquery>
			<cfloop query="thisQ">
				<cfset x=x & chr(10) & btbs & chr(9) & '<phone>#EncodeForXML(thisQ.address)#</phone>'>
			</cfloop>
			<cfquery name="thisQ" dbtype="query">
				select address from aa where  agent_id=#da.agent_id# and address_type='email'
			</cfquery>
			<cfloop query="thisQ">
				<cfset x=x & chr(10) & btbs & chr(9) & '<electronicMailAddress>#EncodeForXML(thisQ.address)#</electronicMailAddress>'>
			</cfloop>
			<cfquery name="thisQ" dbtype="query">
				select address from aa where  agent_id=#da.agent_id# and address_type='url'
			</cfquery>
			<cfloop query="thisQ">
				<cfset x=x & chr(10) & btbs & chr(9) & '<onlineUrl>#EncodeForXML(thisQ.address)#</onlineUrl>'>
			</cfloop>
			<cfquery name="thisQ" dbtype="query">
				select address from aa where  agent_id=#da.agent_id# and address_type='ORCID'
			</cfquery>
			<cfloop query="thisQ">
				<cfset x=x & chr(10) & btbs & chr(9) & '<userId directory="http://orcid.org/">#EncodeForXML(thisQ.address)#</userId>'>
			</cfloop>


			<cfset x=x & chr(10) & btbs & '</#lbl#>'>
		</cfloop>
	    <cfreturn x>
	</cffunction>
	<cfquery name="ctg" datasource="uam_god">
		select guid_prefix from collection order by guid_prefix
	</cfquery>
	<cfparam name="url.guid_prefix" default="">
	<form method="get" action="ipt.cfm">
		<label for="guid_prefix">guid_prefix</label>
		<select name="guid_prefix">
			<option value=""></option>
			<cfloop query="ctg">
				<option <cfif url.guid_prefix is ctg.guid_prefix>selected="selected"</cfif> value="#guid_prefix#">#guid_prefix#</option>
			</cfloop>
		</select>
		<input type="submit" value="go">
	</form>

	<cfif len(guid_prefix) is 0>
		<cfabort>
	</cfif>
	<!--------------------------------------------------------->
		<cfquery name="d" datasource="uam_god">
			select
				collection.collection_id,
				collection.institution || ' ' || collection.collection collection,
				collection.descr,
				collection.citation,
				collection.web_link,
				collection_terms.display as collection_terms_display,
				collection_terms.uri  as collection_terms_uri,
				collection_terms.description  as collection_terms_description,
				external_license.display  as external_license_display,
				external_license.uri  as external_license_uri,
				external_license.description  as external_license_description,
				collection_cde,
				institution_acronym,
				collection.guid_prefix,
				GEOGRAPHIC_DESCRIPTION,
				WEST_BOUNDING_COORDINATE,
				EAST_BOUNDING_COORDINATE,
				NORTH_BOUNDING_COORDINATE,
				SOUTH_BOUNDING_COORDINATE,
				GENERAL_TAXONOMIC_COVERAGE,
				TAXON_NAME_RANK,
				TAXON_NAME_VALUE,
				PURPOSE_OF_COLLECTION,
				alternate_identifier_1,
				alternate_identifier_2,
				specimen_preservation_method,
				time_coverage
			from
				collection
				left outer join ctdata_license external_license on collection.external_license_id=external_license.data_license_id
				left outer join ctcollection_terms collection_terms on collection.collection_terms_id=collection_terms.collection_terms_id
			where
				collection.guid_prefix=<CFQUERYPARAM VALUE="#guid_prefix#"  CFSQLType="CF_SQL_VARCHAR"   MAXLENGTH="20">
				order by guid_prefix
		</cfquery>

		<cfif d.recordcount is not 1>
			fail<cfabort>
		</cfif>


		<cfset eml='<eml:eml xmlns:eml="eml://ecoinformatics.org/eml-2.1.1"'>
		<cfset eml=eml & chr(10) & chr(9) & 'xmlns:dc="http://purl.org/dc/terms/"'>
		<cfset eml=eml & chr(10) & chr(9) & 'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"'>
		<cfset eml=eml & chr(10) & chr(9) & 'xsi:schemaLocation="eml://ecoinformatics.org/eml-2.1.1 http://rs.gbif.org/schema/eml-gbif-profile/1.1/eml.xsd"'>
		<cfset eml=eml & chr(10) & chr(9) & 'packageId="f85f5c5c-ce02-4337-9317-23fe54769ff2/v1.3" system="http://gbif.org" scope="system"'>
		<cfset eml=eml & chr(10) & chr(9) & ' xml:lang="eng">'>
		<cfset eml=eml & chr(10) & '<dataset>'>
		<cfif len(d.alternate_identifier_1) gt 0>
			<cfset eml=eml & chr(10) & chr(9) & '<alternateIdentifier>#EncodeForXML(d.alternate_identifier_1)#</alternateIdentifier>'>
		</cfif>
		<cfif len(d.alternate_identifier_2) gt 0>
			<cfset eml=eml & chr(10) & chr(9) & '<alternateIdentifier>#EncodeForXML(d.alternate_identifier_2)#</alternateIdentifier>'>
		</cfif>
		<cfset eml=eml & chr(10) & chr(9) & '<title xml:lang="eng">#EncodeForXML(d.collection)# (Arctos)</title>'>


		<cfset x=formatAgent(collection_id='#d.COLLECTION_ID#',lbl='creator',role='creator',ntabs="1")>
		<cfset eml=eml & x>


		<cfset x=formatAgent(collection_id='#d.COLLECTION_ID#',lbl='metadataProvider',role='metadata provider',ntabs="1")>
		<cfset eml=eml & x>


		<cfset x=formatAgent(collection_id='#d.COLLECTION_ID#',lbl='associatedParty',role='associated party',ntabs="1")>
		<cfset eml=eml & x>

		<cfset eml=eml & chr(10) & chr(9) & '<pubDate>#dateformat(now(),"YYYY-MM-DD")#</pubDate>'>
		<cfset eml=eml & chr(10) & chr(9) & '<language>eng</language>'>
		<cfset eml=eml & chr(10) & chr(9) & '<abstract>'>
		<cfset eml=eml & chr(10) & chr(9) & chr(9) & '<para>#EncodeForXML(d.descr)#</para>'>
		<cfset eml=eml & chr(10) & chr(9) & '</abstract>'>
		<cfset eml=eml & chr(10) & chr(9) & '<keywordSet>'>
			<cfset eml=eml & chr(10) & chr(9) & chr(9) & '<keyword>Occurrence</keyword>'>
			<cfset eml=eml & chr(10) & chr(9) & chr(9) & '<keywordThesaurus>GBIF Dataset Type Vocabulary: http://rs.gbif.org/vocabulary/gbif/dataset_type.xml</keywordThesaurus>'>
		<cfset eml=eml & chr(10) & chr(9) & '</keywordSet>'>
		<cfset eml=eml & chr(10) & chr(9) & '<keywordSet>'>
			<cfset eml=eml & chr(10) & chr(9) & chr(9) & '<keyword>Specimen</keyword>'>
			<cfset eml=eml & chr(10) & chr(9) & chr(9) & '<keywordThesaurus>GBIF Dataset Type Vocabulary: http://rs.gbif.org/vocabulary/gbif/dataset_type.xml</keywordThesaurus>'>
		<cfset eml=eml & chr(10) & chr(9) & '</keywordSet>'>

		<cfset eml=eml & chr(10) & chr(9) & '<additionalInfo>'>
		<cfset eml=eml & chr(10) & chr(9) & chr(9) & '<para>'>
		<cfset eml=eml & chr(10) & chr(9) & chr(9) & chr(9) & '#EncodeForXML(d.collection_terms_display)#: #EncodeForXML(d.collection_terms_uri)#'>
		<cfset eml=eml & chr(10) & chr(9) & chr(9) & '</para>'>
		<cfset eml=eml & chr(10) & chr(9) & '</additionalInfo>'>


		<cfset eml=eml & chr(10) & chr(9) & '<intellectualRights>'>


		<cfset eml=eml & chr(10) & chr(9) & chr(9) & '<para>'>
		<cfset eml=eml & chr(10) & chr(9) & chr(9) &  chr(9) & 'License Description: #EncodeForXML(d.external_license_description)#'>
		<cfset eml=eml & chr(10) & chr(9) & chr(9) &  chr(9) & '<ulink url="#EncodeForXML(d.external_license_uri)#"><citetitle>#EncodeForXML(d.external_license_display)#</citetitle></ulink>'>
		<cfset eml=eml & chr(10) & chr(9) & chr(9) & '</para>'>
		<cfset eml=eml & chr(10) & chr(9) & '</intellectualRights>'>

		<cfset eml=eml & chr(10) & chr(9) & '<distribution scope="document">'>
			<cfset eml=eml & chr(10) & chr(9) & chr(9) & '<online>'>
			<cfset eml=eml & chr(10) & chr(9) & chr(9) & chr(9) & '<url function="information">#EncodeForXML(d.web_link)#</url>'>
			<cfset eml=eml & chr(10) & chr(9) & chr(9) & '</online>'>
		<cfset eml=eml & chr(10) & chr(9) & '</distribution>'>
		<cfset eml=eml & chr(10) & chr(9) & '<coverage>'>
		<cfset eml=eml & chr(10) & chr(9) & chr(9) & '<geographicCoverage>'>
		<cfset eml=eml & chr(10) & chr(9) & chr(9) & chr(9) & '<geographicDescription>#EncodeForXML(d.GEOGRAPHIC_DESCRIPTION)#</geographicDescription>'>
		<cfset eml=eml & chr(10) & chr(9) & chr(9) & chr(9) & '<boundingCoordinates>'>
		<cfset eml=eml & chr(10) & chr(9) & chr(9) & chr(9) & chr(9) &'<westBoundingCoordinate>#d.WEST_BOUNDING_COORDINATE#</westBoundingCoordinate>'>
		<cfset eml=eml & chr(10) & chr(9) & chr(9) & chr(9) & chr(9) &'<eastBoundingCoordinate>#d.EAST_BOUNDING_COORDINATE#</eastBoundingCoordinate>'>
		<cfset eml=eml & chr(10) & chr(9) & chr(9) & chr(9) & chr(9) &'<northBoundingCoordinate>#d.NORTH_BOUNDING_COORDINATE#</northBoundingCoordinate>'>
		<cfset eml=eml & chr(10) & chr(9) & chr(9) & chr(9) & chr(9) &'<southBoundingCoordinate>#d.SOUTH_BOUNDING_COORDINATE#</southBoundingCoordinate>'>
		<cfset eml=eml & chr(10) & chr(9) & chr(9) & chr(9) & '</boundingCoordinates>'>
		<cfset eml=eml & chr(10) & chr(9) & chr(9) & '</geographicCoverage>'>
		<cfset eml=eml & chr(10) & chr(9) & chr(9) & '<taxonomicCoverage>'>
		<cfset eml=eml & chr(10) & chr(9) & chr(9) & chr(9) & '<generalTaxonomicCoverage>#EncodeForXML(d.GENERAL_TAXONOMIC_COVERAGE)#</generalTaxonomicCoverage>'>
		<cfset eml=eml & chr(10) & chr(9) & chr(9) & chr(9) & '<taxonomicClassification>'>
		<cfset eml=eml & chr(10) & chr(9) & chr(9) & chr(9) &  chr(9) & '<taxonRankName>#EncodeForXML(d.TAXON_NAME_RANK)#</taxonRankName>'>
		<cfset eml=eml & chr(10) & chr(9) & chr(9) & chr(9) &  chr(9) & '<taxonRankValue>#EncodeForXML(d.TAXON_NAME_VALUE)#</taxonRankValue>'>
		<cfset eml=eml & chr(10) & chr(9) & chr(9) & chr(9) & '</taxonomicClassification>'>
		<cfset eml=eml & chr(10) & chr(9) & chr(9) & '</taxonomicCoverage>'>

		<cfset eml=eml & chr(10) & chr(9) & '</coverage>'>
		<cfset eml=eml & chr(10) & chr(9) & '<purpose>'>
		<cfset eml=eml & chr(10) & chr(9) &  chr(9) &'<para>#EncodeForXML(d.PURPOSE_OF_COLLECTION)#</para>'>
		<cfset eml=eml & chr(10) & chr(9) & '</purpose>'>

		<cfset eml=eml & chr(10) & chr(9) & '<maintenance>'>
		<cfset eml=eml & chr(10) & chr(9) &  chr(9) &'<description>'>
		<cfset eml=eml & chr(10) & chr(9) &  chr(9) &'</description>'>
		<cfset eml=eml & chr(10) & chr(9) &  chr(9) &'<maintenanceUpdateFrequency>monthly</maintenanceUpdateFrequency>'>
		<cfset eml=eml & chr(10) & chr(9) & '</maintenance>'>

		<cfset x=formatAgent(collection_id='#d.COLLECTION_ID#',lbl='contact',role='data quality',ntabs="1")>
		<cfset eml=eml & x>

		<cfset eml=eml & chr(10) & chr(9) & '<methods>'>
		<cfset eml=eml & chr(10) & chr(9) & chr(9) & '<methodStep>'>
		<cfset eml=eml & chr(10) & chr(9) & chr(9) & chr(9) &'<description>'>
		<cfset eml=eml & chr(10) & chr(9) & chr(9) & chr(9) & chr(9) &'<para></para>'>
		<cfset eml=eml & chr(10) & chr(9) & chr(9) & chr(9) &'</description>'>
		<cfset eml=eml & chr(10) & chr(9) & chr(9) & '</methodStep>'>
		<cfset eml=eml & chr(10) & chr(9) & '</methods>'>
		<cfset eml=eml & chr(10) & '</dataset>'>
		<cfset eml=eml & chr(10) & '<additionalMetadata>'>
		<cfset eml=eml & chr(10) & chr(9) & '<metadata>'>
		<cfset eml=eml & chr(10) & chr(9) & chr(9) & '<gbif>'>
		<cfset eml=eml & chr(10) & chr(9) & chr(9) & chr(9) & '<dateStamp>#dateformat(now(),"YYYY-MM-DD")#T#timeFormat( now(), "HH:mm:ss" )#</dateStamp>'>
		<cfset eml=eml & chr(10) & chr(9) & chr(9) & chr(9) & '<hierarchyLevel>dataset</hierarchyLevel>'>
		<cfset eml=eml & chr(10) & chr(9) & chr(9) & chr(9) & '<citation>#EncodeForXML(d.citation)#</citation>'>
		<cfset eml=eml & chr(10) & chr(9) & chr(9) & chr(9) & '<collection>'>
		<cfset eml=eml & chr(10) & chr(9) & chr(9) & chr(9) & chr(9) & '<parentCollectionIdentifier>#listGetAt(d.guid_prefix,1,":")#</parentCollectionIdentifier>'>
		<cfset eml=eml & chr(10) & chr(9) & chr(9) & chr(9) & chr(9) & '<collectionIdentifier>#application.serverRootURL#/collection/#d.guid_prefix#</collectionIdentifier>'>
		<cfset eml=eml & chr(10) & chr(9) & chr(9) & chr(9) & chr(9) & '<collectionName>#EncodeForXML(d.collection)#</collectionName>'>
		<cfset eml=eml & chr(10) & chr(9) & chr(9) & chr(9) & '</collection>'>
		<cfset eml=eml & chr(10) & chr(9) & chr(9) & chr(9) & '<specimenPreservationMethod>#EncodeForXML(d.specimen_preservation_method)#</specimenPreservationMethod>'>
		<cfset eml=eml & chr(10) & chr(9) & chr(9) & chr(9) & '<livingTimePeriod>#EncodeForXML(d.time_coverage)#</livingTimePeriod>'>
		<!----
		<cfset eml=eml & chr(10) & chr(9) & chr(9) & chr(9) & '<dc:replaces>f85f5c5c-ce02-4337-9317-23fe54769ff2/v1.3.xml</dc:replaces>'>
	---->
		<cfset eml=eml & chr(10) & chr(9) & chr(9) & '</gbif>'>
		<cfset eml=eml & chr(10) & chr(9) & '</metadata>'>

		<cfset eml=eml & chr(10) & '</additionalMetadata>'>
		<cfset eml=eml & chr(10) & '</eml:eml>'>



		<cfset fn=replace(guid_prefix,':','_','all')>
		<cffile action = "write"
		    file = "#Application.webDirectory#/download/#fn#.eml"
		    output = "#eml#"
		    addNewLine = "no">

	    <div class="importantNotification">
	    	The preview will mangle escaped characters; use the download option to save or edit.
	    </div>
	    <p>
			<a href="/download/#fn#.eml">download EML</a>
		</p>

		<p>
			EML Preview:
		</p>
		<p>
			<textarea rows="150" cols="100" style="width:100%;">#eml#</textarea>
		</p>



<!----


</dataset>
  <additionalMetadata>
    <metadata>
      <gbif>

          <hierarchyLevel>dataset</hierarchyLevel>
            <citation>Mayfield T (2018): UTEP Zoo (Arctos). v1.3. University of Texas at El Paso Biodiversity Collections. Dataset/Occurrence. http://ipt.vertnet.org:8080/ipt/resource?r=utep_bird&amp;v=1.3</citation>
              <collection>
                  <parentCollectionIdentifier>UTEP</parentCollectionIdentifier>
                  <collectionIdentifier>UTEP:Zoo</collectionIdentifier>
                <collectionName>Univerisity of Texas at El Paso Biodiversity Collections - Zooplankton</collectionName>
              </collection>
                <specimenPreservationMethod>ethanol, formalin, trophi</specimenPreservationMethod>
              <livingTimePeriod>1900-present</livingTimePeriod>

      </gbif>
    </metadata>
  </additionalMetadata>
</eml:eml>







<cfsavecontent variable="eml">

	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xsi:schemaLocation="eml://ecoinformatics.org/eml-2.1.1 http://rs.gbif.org/schema/eml-gbif-profile/1.1/eml.xsd"
	packageId="f85f5c5c-ce02-4337-9317-23fe54769ff2/v1.3" system="http://gbif.org" scope="system"
	xml:lang="eng">
	<dataset>
	<cfif len(alternate_identifier_1) gt 0>
		<alternateIdentifier>#alternate_identifier_1#</alternateIdentifier>
	</cfif>


				,
				alternate_identifier_2

	<cfloop query="d">
		<br><a name="#guid_prefix#" href="##top">scroll to top</a>
		<br>
		<span class="redborder">
			<br>
			<label for="">collection</label>
			<input type="text" size="80" value="#collection#">
			<label for="">guid_prefix</label>
			<input type="text" size="80" value="#guid_prefix#">
			<label for="">descr</label>
			<textarea rows="6" cols="80">#descr#</textarea>
			<label for="">citation</label>
			<input type="text" size="80" value="#citation#">
			<label for="">web_link</label>
			<input type="text" size="80" value="#web_link#">
			<label for="">license</label>
			<input type="text" size="80" value="#display#">
			<label for="">license_uri</label>
			<input type="text" size="80" value="#uri#">
			<cfquery name="gc" datasource="uam_god">
				select continent_ocean from flat where continent_ocean is not null and collection_id=#collection_id# group by continent_ocean order by count(*) DESC
			</cfquery>
			<label for="">Geographic  Coverage</label>
			<cfset geocov=valuelist(gc.continent_ocean)>
			<cfif listfind(geocov,"no higher geography recorded")>
				<cfset geocov=listdeleteat(geocov,listfind(geocov,"no higher geography recorded"))>
			</cfif>
			<cfset geocov=replace(geocov,",",", ","all")>
			<textarea rows="6" cols="80">#geocov#</textarea>
			<cfquery name="tc" datasource="uam_god">
				select phylclass from flat where phylclass is not null and collection_id=#collection_id# group by phylclass order by count(*) DESC
			</cfquery>

				<cfset taxcov=replace(valuelist(tc.phylclass),",",", ","all")>
			<label for="">Taxonomic  Coverage</label>
			<textarea rows="6" cols="80">#taxcov#</textarea>
			<cfquery name="tec" datasource="uam_god">
				select min(began_date) earliest, max(ended_date) latest from flat where collection_id=#collection_id#
			</cfquery>
			<label for="">Temporal Coverage - earliest</label>
			<input type="text" size="80" value="#tec.earliest#">
			<label for="">Temporal Coverage - latest</label>
			<input type="text" size="80" value="#tec.latest#">
			<cfquery name="contacts" datasource="uam_god">
				select
					getAgentNameType(CONTACT_AGENT_ID,'first name') first_name,
					getAgentNameType(CONTACT_AGENT_ID,'last name') last_name,
					getAgentNameType(CONTACT_AGENT_ID,'job title') job_title,
					CONTACT_ROLE,
					CONTACT_AGENT_ID
				from
					collection_contacts,
					agent
				where
				CONTACT_AGENT_ID=agent.agent_id and
				collection_id=#collection_id#
			</cfquery>
			<cfloop query="contacts">
				<br>
				<span class="greenborder">
					<label for="">CONTACT_ROLE</label>
					<input type="text" size="80" value="#CONTACT_ROLE#">
					<label for="">first_name</label>
					<input type="text" size="80" value="#first_name#">
					<label for="">last_name</label>
					<input type="text" size="80" value="#last_name#">
					<label for="">JOB_TITLE</label>
					<input type="text" size="80" value="#contacts.job_title#">
					<cfquery name="addr" datasource="uam_god">
						select
							*
						from
							address
						where
							VALID_ADDR_FG = 1 and
							agent_id=#CONTACT_AGENT_ID#
					</cfquery>
					<cfloop query="addr">
						<br>
						<span class="blueborder">
							<label for="">#address_type# address</label>
							<textarea class="hugetextarea">#address#</textarea>
						</span>
					</cfloop>
				</span>
			</cfloop>

		</span>
		<br>
	</cfloop>





	<!---- what is this? ---->
  	<alternateIdentifier>f85f5c5c-ce02-4337-9317-23fe54769ff2</alternateIdentifier>
  	<alternateIdentifier>http://ipt.vertnet.org:8080/ipt/resource?r=#d.guid_prefix#</alternateIdentifier>
  	<title xml:lang="eng">#d.collection# (Arctos)</title>
	<!---- where do I get this? Using me for now... ---->
    <creator>
	    <individualName>
	      <givenName>Dusty</givenName>
	      <surName>McDonald</surName>
	    </individualName>
    	<organizationName>#d.INSTITUTION#</organizationName>
		<!---- where do I get this? Using me for now... ---->
    	<positionName>Data Janitor</positionName>
    <address>
        <deliveryPoint>500 West University Avenue, Biology Bldg. ##222</deliveryPoint>
        <city>El Paso</city>
        <administrativeArea>TX</administrativeArea>
        <postalCode>79968</postalCode>
        <country>US</country>
    </address>
    <phone>+01 915-747-5479</phone>
    <electronicMailAddress>tmayfield.utepbc@jegelewicz.net</electronicMailAddress>
    <onlineUrl>https://www.utep.edu/biodiversity/collections/invertebrate-biology.html</onlineUrl>
      </creator>
      <metadataProvider>
    <individualName>
        <givenName>Teresa</givenName>
      <surName>Mayfield</surName>
    </individualName>
    <organizationName>University of Texas at El Paso</organizationName>
    <positionName>Manager, UTEP Biodiversity Collections</positionName>
    <address>
        <deliveryPoint>500 West University Avenue, Biology Bldg. ##222</deliveryPoint>
        <city>El Paso</city>
        <administrativeArea>TX</administrativeArea>
        <postalCode>79968</postalCode>
        <country>US</country>
    </address>
    <phone>+01 915-747-5479</phone>
    <electronicMailAddress>tmayfield.utepbc@jegelewicz.net</electronicMailAddress>
    <onlineUrl>https://www.utep.edu/biodiversity/</onlineUrl>
      </metadataProvider>
      <associatedParty>
    <individualName>
        <givenName>Laura</givenName>
      <surName>Russell</surName>
    </individualName>
    <organizationName>VertNet</organizationName>
    <positionName>Programmer</positionName>
    <electronicMailAddress>larussell@vertnet.org</electronicMailAddress>
    <onlineUrl>http://www.vertnet.org</onlineUrl>
    <role>programmer</role>
      </associatedParty>
      <associatedParty>
    <individualName>
        <givenName>David</givenName>
      <surName>Bloom</surName>
    </individualName>
    <organizationName>VertNet</organizationName>
    <positionName>Coordinator</positionName>
    <electronicMailAddress>dbloom@vertnet.org</electronicMailAddress>
    <onlineUrl>http://www.vertnet.org</onlineUrl>
    <role>programmer</role>
      </associatedParty>
      <associatedParty>
    <individualName>
        <givenName>John</givenName>
      <surName>Wieczorek</surName>
    </individualName>
    <organizationName>Museum of Vertebrate Zoology at UC Berkeley</organizationName>
    <positionName>Information Architect</positionName>
    <electronicMailAddress>tuco@berkeley.edu</electronicMailAddress>
    <role>programmer</role>
      </associatedParty>
      <associatedParty>
    <individualName>
        <givenName>Dusty</givenName>
      <surName>McDonald</surName>
    </individualName>
    <organizationName>University of Alaska Museum</organizationName>
    <positionName>Arctos Database Programmer</positionName>
    <electronicMailAddress>dlmcdonald@alaska.edu</electronicMailAddress>
    <onlineUrl>http://arctos.database.museum</onlineUrl>
    <role>pointOfContact</role>
      </associatedParty>
  <pubDate>
      2018-02-08
  </pubDate>
  <language>eng</language>
  <abstract>
    <para>The University of Texas at El Paso Biodiversity Collections Zooplankton material includes a collection of rotifers curated by Dr. Elizabeth Walsh. Dr. Walsh’s laboratory uses molecular techniques to address evolutionary and ecological questions.</para>
  </abstract>
      <keywordSet>
            <keyword>Occurrence</keyword>
        <keywordThesaurus>GBIF Dataset Type Vocabulary: http://rs.gbif.org/vocabulary/gbif/dataset_type.xml</keywordThesaurus>
      </keywordSet>
      <keywordSet>
            <keyword>Specimen</keyword>
        <keywordThesaurus>GBIF Dataset Subtype Vocabulary: http://rs.gbif.org/vocabulary/gbif/dataset_subtype.xml</keywordThesaurus>
      </keywordSet>
  <intellectualRights>
    <para>To the extent possible under law, the publisher has waived all rights to these data and has dedicated them to the <ulink url="http://creativecommons.org/publicdomain/zero/1.0/legalcode"><citetitle>Public Domain (CC0 1.0)</citetitle></ulink>. Users may copy, modify, distribute and use the work, including for commercial purposes, without restriction.</para>
  </intellectualRights>
  <distribution scope="document">
    <online>
      <url function="information">https://www.utep.edu/biodiversity/collections/invertebrate-biology.html</url>
    </online>
  </distribution>
  <coverage>
      <geographicCoverage>
          <geographicDescription>Specimens were collected primarily in the United States.</geographicDescription>
        <boundingCoordinates>
          <westBoundingCoordinate>-180</westBoundingCoordinate>
          <eastBoundingCoordinate>180</eastBoundingCoordinate>
          <northBoundingCoordinate>90</northBoundingCoordinate>
          <southBoundingCoordinate>-90</southBoundingCoordinate>
        </boundingCoordinates>
      </geographicCoverage>
          <taxonomicCoverage>
              <generalTaxonomicCoverage>Rotifera</generalTaxonomicCoverage>
              <taxonomicClassification>
                  <taxonRankName>phylum</taxonRankName>
                <taxonRankValue>Rotifera</taxonRankValue>
              </taxonomicClassification>
          </taxonomicCoverage>
  </coverage>
  <purpose>
    <para>Data set was developed through the work of University of Texas at El Paso faculty and students and is created to support future research.</para>
  </purpose>
  <maintenance>
    <description>
      <para></para>
    </description>
    <maintenanceUpdateFrequency>monthly</maintenanceUpdateFrequency>
  </maintenance>

      <contact>
    <individualName>
        <givenName>Teresa</givenName>
      <surName>Mayfield</surName>
    </individualName>
    <organizationName>University of Texas at El Paso</organizationName>
    <positionName>Manager, UTEP Biodiversity Collections</positionName>
    <address>
        <deliveryPoint>500 West University Avenue, Biology Bldg. ##222</deliveryPoint>
        <city>El Paso</city>
        <administrativeArea>TX</administrativeArea>
        <postalCode>79968</postalCode>
        <country>US</country>
    </address>
    <phone>+01 915-747-5479</phone>
    <electronicMailAddress>tmayfield.utepbc@jegelewicz.net</electronicMailAddress>
    <onlineUrl>https://www.utep.edu/biodiversity/</onlineUrl>
      </contact>
      <contact>
    <individualName>
        <givenName>Elizabeth</givenName>
      <surName>Walsh</surName>
    </individualName>
    <organizationName>University of Texas at El Paso</organizationName>
    <positionName>Curator, UTEP Biodiversity Collections</positionName>
    <address>
        <deliveryPoint>500 West University Avenue, Biology Bldg. ##222</deliveryPoint>
        <city>El Paso</city>
        <administrativeArea>Texas</administrativeArea>
        <postalCode>79968</postalCode>
        <country>US</country>
    </address>
    <phone>01 915-747-5479</phone>
    <electronicMailAddress>ewalsh@utep.edu</electronicMailAddress>
      </contact>
  <methods>
        <methodStep>
          <description>
            <para></para>
          </description>
        </methodStep>
  </methods>
</dataset>
  <additionalMetadata>
    <metadata>
      <gbif>
          <dateStamp>2016-10-04T01:12:33.886-05:00</dateStamp>
          <hierarchyLevel>dataset</hierarchyLevel>
            <citation>Mayfield T (2018): UTEP Zoo (Arctos). v1.3. University of Texas at El Paso Biodiversity Collections. Dataset/Occurrence. http://ipt.vertnet.org:8080/ipt/resource?r=utep_bird&amp;v=1.3</citation>
              <collection>
                  <parentCollectionIdentifier>UTEP</parentCollectionIdentifier>
                  <collectionIdentifier>UTEP:Zoo</collectionIdentifier>
                <collectionName>Univerisity of Texas at El Paso Biodiversity Collections - Zooplankton</collectionName>
              </collection>
                <specimenPreservationMethod>ethanol, formalin, trophi</specimenPreservationMethod>
              <livingTimePeriod>1900-present</livingTimePeriod>
          <dc:replaces>f85f5c5c-ce02-4337-9317-23fe54769ff2/v1.3.xml</dc:replaces>
      </gbif>
    </metadata>
  </additionalMetadata>
</eml:eml>
		</cfsavecontent>


		<hr>

		<cfdump var=#eml#>

		<hr>


<cffile action = "write"
    file = "#Application.webDirectory#/download/tempeml.eml"
    output = "#eml#"
    addNewLine = "no">
	<a href="/download/tempeml.eml">/download/tempeml.eml</a>



	<cfabort>



	------------>






<cfif action is "oldstuff">



	<!--------------------------------------------------------->
	<cfset title="IPT/Collection Metadata report">
	<cfif (isdefined("session.roles") and session.roles contains "coldfusion_user")>
		<cfset session.iptauthenticated=true>
	</cfif>
	<cfif not isdefined("session.iptauthenticated")>
		Top-secret <strong>password</strong> required.
		<br>This is not your regular Arctos <strong>password</strong>.
		<br>It's just a light bit of fake security to keep bots and stuff out.
		<br>That's necessary because we want people without real accounts to be able to use this.
		<br>
		<a target="_blank" href="https://github.com/ArctosDB/arctos/issues/new?assignees=&labels=contact&template=contact-arctos.md&title=%5BCONTACT%5D">Contact Us</a>
		if you need the <strong>password</strong>.
		<form method="post" action="ipt.cfm">
			<label for="password">enter password</label>
			<input type="password" name="password">
			<br><input type="submit" value="go">
		</form>
		<cfif not isdefined("password")>
			you did not enter password
			<cfabort>
		</cfif>
		<cfif hash(password) is not "5F4DCC3B5AA765D61D8327DEB882CF99">
			you did not enter password
			<cfabort>
		</cfif>
		<cfset session.iptauthenticated=true>
		<cflocation url="/info/ipt.cfm" addtoken="false">
	</cfif>
	<style>
		.redborder {border:2px solid red; margin:1em;display: inline-block;}
		.greenborder {border:2px solid green; padding: 1em 1em 1em 2em; margin:1em; display: inline-block;}
		.blueborder {border:2px solid blue; padding: 1em 1em 1em 2em; margin:1em;display: inline-block;}
		.yellowborder {border:2px solid yellow; padding: 1em 1em 1em 2em; margin:1em;display: inline-block;}
	</style>
	<cfquery name="d" datasource="uam_god">
		select
			collection.collection_id,
			collection.institution || ' ' || collection.collection collection,
			collection.descr,
			collection.citation,
			collection.web_link,
			display,
			uri,
			collection_cde,
			institution_acronym,
			collection.guid_prefix
		from
			collection
			left outer join ctmedia_license on collection.USE_LICENSE_ID=ctmedia_license.media_license_id
		where
			order by guid_prefix
	</cfquery>
	<a name="top"></a>
		<br><a href="##institution">institution</a>
	<cfloop query="d">
		<br><a href="###guid_prefix#">#guid_prefix#</a>
	</cfloop>
	<cfquery name="i" datasource="uam_god">
		select
			institution_acronym,
			count(*) speccount
		from
			collection,
			cataloged_item
		where
			collection.collection_id=cataloged_item.collection_id
		group by
			institution_acronym
		order by
			institution_acronym
	</cfquery>
	<p>
		<a name="institution" href="##top">scroll to top</a>
	</p>

	<table border>
		<tr>
			<th>Institution</th>
			<th>SpecimenCount</th>
		</tr>
		<cfloop query="i">
			<tr>
				<td>#institution_acronym#</td>
				<td>#speccount#</td>
			</tr>
		</cfloop>
	</table>
	<cfloop query="d">
		<br><a name="#guid_prefix#" href="##top">scroll to top</a>
		<br>
		<span class="redborder">
			<br>
			<label for="">collection</label>
			<input type="text" size="80" value="#collection#">
			<label for="">guid_prefix</label>
			<input type="text" size="80" value="#guid_prefix#">
			<label for="">descr</label>
			<textarea rows="6" cols="80">#descr#</textarea>
			<label for="">citation</label>
			<input type="text" size="80" value="#citation#">
			<label for="">web_link</label>
			<input type="text" size="80" value="#web_link#">
			<label for="">license</label>
			<input type="text" size="80" value="#display#">
			<label for="">license_uri</label>
			<input type="text" size="80" value="#uri#">
			<cfquery name="gc" datasource="uam_god">
				select continent_ocean from flat where continent_ocean is not null and collection_id=#collection_id# group by continent_ocean order by count(*) DESC
			</cfquery>
			<label for="">Geographic  Coverage</label>
			<cfset geocov=valuelist(gc.continent_ocean)>
			<cfif listfind(geocov,"no higher geography recorded")>
				<cfset geocov=listdeleteat(geocov,listfind(geocov,"no higher geography recorded"))>
			</cfif>
			<cfset geocov=replace(geocov,",",", ","all")>
			<textarea rows="6" cols="80">#geocov#</textarea>
			<cfquery name="tc" datasource="uam_god">
				select phylclass from flat where phylclass is not null and collection_id=#collection_id# group by phylclass order by count(*) DESC
			</cfquery>

				<cfset taxcov=replace(valuelist(tc.phylclass),",",", ","all")>
			<label for="">Taxonomic  Coverage</label>
			<textarea rows="6" cols="80">#taxcov#</textarea>
			<cfquery name="tec" datasource="uam_god">
				select min(began_date) earliest, max(ended_date) latest from flat where collection_id=#collection_id#
			</cfquery>
			<label for="">Temporal Coverage - earliest</label>
			<input type="text" size="80" value="#tec.earliest#">
			<label for="">Temporal Coverage - latest</label>
			<input type="text" size="80" value="#tec.latest#">
			<cfquery name="contacts" datasource="uam_god">
				select
					getAgentNameType(CONTACT_AGENT_ID,'first name') first_name,
					getAgentNameType(CONTACT_AGENT_ID,'last name') last_name,
					getAgentNameType(CONTACT_AGENT_ID,'job title') job_title,
					CONTACT_ROLE,
					CONTACT_AGENT_ID
				from
					collection_contacts,
					agent
				where
				CONTACT_AGENT_ID=agent.agent_id and
				collection_id=#collection_id#
			</cfquery>
			<cfloop query="contacts">
				<br>
				<span class="greenborder">
					<label for="">CONTACT_ROLE</label>
					<input type="text" size="80" value="#CONTACT_ROLE#">
					<label for="">first_name</label>
					<input type="text" size="80" value="#first_name#">
					<label for="">last_name</label>
					<input type="text" size="80" value="#last_name#">
					<label for="">JOB_TITLE</label>
					<input type="text" size="80" value="#contacts.job_title#">
					<cfquery name="addr" datasource="uam_god">
						select
							*
						from
							address
						where
							end_date is null and
							agent_id=#CONTACT_AGENT_ID#
					</cfquery>
					<cfloop query="addr">
						<br>
						<span class="blueborder">
							<label for="">#address_type# address</label>
							<textarea class="hugetextarea">#address#</textarea>
						</span>
					</cfloop>
				</span>
			</cfloop>

		</span>
		<br>
	</cfloop>
	</cfif><!--- end oldstuff --->
</cfoutput>
<cfinclude template="/includes/_footer.cfm">
