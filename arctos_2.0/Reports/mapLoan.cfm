<cfinclude template="/includes/_header.cfm">
	<!---
		just georeference all shipping addresses
		alter table address add s$coordinates varchar2(255);
		alter table address add s$lastdate date;



	create table temp_loan_map as select
		guid_prefix collection,
		loan_number,
		s$coordinates
	from
		collection,
		trans,
		loan,
		shipment,
		address
	where
		collection.collection_id=trans.collection_id and
		trans.transaction_id=loan.transaction_id and
		loan.transaction_id=shipment.transaction_id and
		shipment.SHIPPED_TO_ADDR_ID=address.address_id and
		s$coordinates is not null
	;

		--->


select
	address_Type,
	count(*)
from
	address,
	shipment
where
	shipment.SHIPPED_TO_ADDR_ID=address.address_id
group by address_type;


select
	address_Type,
	count(*)
from
	address,
	shipment
where
	shipment.SHIPPED_FROM_ADDR_ID=address.address_id
group by address_type;



<cfoutput>

	select count(*) from address where address_Type in ('shipping', 'correspondence') ;
	select count(*) from address where address_Type in ('shipping', 'correspondence') and s$lastdate is not null ;

	<cfquery name="d" datasource="prod" >
			 select
		*
	from
		address
	where
		s$lastdate is null and
		address_Type in ('shipping', 'correspondence') and
		rownum<200
		</cfquery>

					<cfset utilities = CreateObject("component","component.utilities")>

		<cfloop query="d">
			<cfset coords=''>
			<br>#address#

			<!--- faster??--->


			<cfset x=utilities.georeferenceAddress(address)>
			<p>
				#x#
			</p>

			<cfquery name="p" datasource="prod" >
				update address set S$COORDINATES='#x#', S$LASTDATE=sysdate where address_id=#address_id#
			</cfquery>
			<!----


			<cfset rmturl=replace(Application.serverRootUrl,"https","http")>
			<cfhttp method="get" url="#rmturl#/component/utilities.cfc?method=georeferenceAddress&returnformat=plain&address=#URLEncodedFormat(address)#" >
			<cfset coords=cfhttp.fileContent>
			<br>#coords#

			---->

		</cfloop>
								<!--- call remote so no transaction datasource conflicts---->





<!--------

	<cfset rmturl=replace(Application.serverRootUrl,"https","http")>
								<!--- call remote so no transaction datasource conflicts---->
								<cfhttp method="get" url="#rmturl#/component/utilities.cfc?method=georeferenceAddress&returnformat=plain&address=#URLEncodedFormat(thisAddress)#" >
								<cfset coords=cfhttp.fileContent>



<cfset fn="arctos_#randRange(1,1000)#">

<cfset variables.localXmlFile="#Application.webDirectory#/bnhmMaps/tabfiles/#fn#.xml">
<cfset variables.localTabFile="#Application.webDirectory#/bnhmMaps/tabfiles/#fn#.txt">
<cfset rmturl=replace(Application.serverRootUrl,"https","http")>

<cfset variables.remoteXmlFile="#rmturl#/bnhmMaps/tabfiles/#fn#.xml">
<cfset variables.remoteTabFile="#rmturl#/bnhmMaps/tabfiles/#fn#.txt">
<cfset variables.encoding="UTF-8">
<!---- write an XML config file specific to the critters they're mapping --->
	<cfscript>
		variables.joFileWriter = createObject('Component', '/component.FileWriter').init(variables.localXmlFile, variables.encoding, 32768);
		a='<berkeleymapper>' & chr(10) &
			chr(9) & '<colors method="dynamicfield" fieldname="darwin:collectioncode" label="Collection"></colors>' & chr(10) &
			chr(9) & '<concepts>' & chr(10) &
			chr(9) & chr(9) & '<concept viewlist="1" datatype="darwin:collectioncode" alias="Collection"/>' & chr(10) &
			chr(9) & chr(9) & '<concept viewlist="1" datatype="char120:2" alias="Loan Number"/>' & chr(10) &
			chr(9) & chr(9) & '<concept viewlist="0" datatype="darwin:decimallatitude" alias="Decimal Latitude"/>' & chr(10) &
			chr(9) & chr(9) & '<concept viewlist="0" datatype="darwin:decimallongitude" alias="Decimal Longitude"/>' & chr(10) &
			chr(9) & '</concepts>' & chr(10);
		variables.joFileWriter.writeLine(a);
	</cfscript>


	<cfscript>
		a = chr(9) & '<logos>' & chr(10) &
			chr(9) & chr(9) & '<logo img="http://arctos.database.museum/images/genericHeaderIcon.gif" url="http://arctos.database.museum/"/>' & chr(10) &
			chr(9) & '</logos>' & chr(10) &
			'</berkeleymapper>';
		variables.joFileWriter.writeLine(a);
		variables.joFileWriter.close();
		variables.joFileWriter = createObject('Component', '/component.FileWriter').init(variables.localTabFile, variables.encoding, 32768);
	</cfscript>


<cfloop query="d">
	<cfset lat=listgetat(s$coordinates,1)>
	<cfset lng=listgetat(s$coordinates,2)>

	<cfscript>
		a= collection &
			chr(9) & loan_number  &
			chr(9) & lat  &
			chr(9) & lng ;
		variables.joFileWriter.writeLine(a);
	</cfscript>
	</cfloop>

	<cfscript>
		variables.joFileWriter.close();
	</cfscript>
	<cfset bnhmUrl="http://berkeleymapper.berkeley.edu/?ViewResults=tab&tabfile=#variables.remoteTabFile#&configfile=#variables.remoteXmlFile#">

	<!---
	<script type="text/javascript" language="javascript">
		document.location='#bnhmUrl#';
	</script>
	---->

	<p>
	<a href="#bnhmUrl#">#bnhmUrl#</a>
	</p>
	 <noscript>BerkeleyMapper requires JavaScript.</noscript>



--------->
	<!----


	init georeference



	<cfquery name="d" datasource="uam_god">
		select
			ADDRESS_ID,
			ADDRESS
		from
		ADDRESS where
		address_type='shipping' and
		 S$LASTDATE is null and rownum<200
	</cfquery>
	<cfset obj = CreateObject("component","component.functions")>
	<cfloop query="d">

		<cfset mAddress=address>

		<cfset mAddress=replace(mAddress,chr(10),", ","all")>

		<p>#mAddress#</p>
		<!----
			extract ZIP
			start at the end, take the "first" thing that's numbers
		 ---->

		<cfset ttu="">
	 	<cfloop index="i" list="#mAddress#">
			<cfif REFind("[0-9]+", i) gt 0>
				<cfset ttu=i>
			</cfif>
		</cfloop>
		<p>
			using #ttu#
		</p>

		<cfset signedURL = obj.googleSignURL(
			urlPath="/maps/api/geocode/json",
			urlParams="address=#URLEncodedFormat('#ttu#')#")>
		<cfhttp result="x" method="GET" url="#signedURL#"  timeout="20"/>
		<cfset llresult=DeserializeJSON(x.filecontent)>
		<cfif llresult.status is "OK">
			<cfset coords=llresult.results[1].geometry.location.lat & "," & llresult.results[1].geometry.location.lng>
		<cfelse>
			<cfset coords=''>
		</cfif>
		<p>
			update address set
				s$coordinates='#coords#',
				s$lastdate=sysdate
			where ADDRESS_ID=#ADDRESS_ID#
		</p>
		<cfquery name="upEsDollar" datasource="uam_god">
			update address set
				s$coordinates='#coords#',
				s$lastdate=sysdate
			where ADDRESS_ID=#ADDRESS_ID#
		</cfquery>



	END 	init georeference
	</cfloop>

---->


</cfoutput>
<cfinclude template="/includes/_footer.cfm">