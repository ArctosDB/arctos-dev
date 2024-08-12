<cfinclude template="/includes/_header.cfm">
<cfoutput>
	<!--------------------------------------------------------->
	<cfif action is "geneml">


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
			collection,
			ctmedia_license
		where
			collection.guid_prefix='#guid_prefix#' and
			collection.USE_LICENSE_ID=ctmedia_license.media_license_id (+)
			order by guid_prefix
	</cfquery>

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




		<cfsavecontent variable="eml"><eml:eml xmlns:eml="eml://ecoinformatics.org/eml-2.1.1"
    xmlns:dc="http://purl.org/dc/terms/"
	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xsi:schemaLocation="eml://ecoinformatics.org/eml-2.1.1 http://rs.gbif.org/schema/eml-gbif-profile/1.1/eml.xsd"
	packageId="f85f5c5c-ce02-4337-9317-23fe54769ff2/v1.3" system="http://gbif.org" scope="system"
	xml:lang="eng">
	<dataset>
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
	</cfif>










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
		<br><a href="/contact.cfm">contact us</a> if you need the <strong>password</strong>.
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
			collection,
			ctmedia_license
		where
			collection.USE_LICENSE_ID=ctmedia_license.media_license_id (+)
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
</cfoutput>
<cfinclude template="/includes/_footer.cfm">
