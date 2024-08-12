<cfif action is "getKeys">
<cfoutput>
	<cfquery name="d" datasource='uam_god'>
		select distinct DYNAMICPROPERTIES from temp_almnhvp where DYNAMICPROPERTIES is not null
	</cfquery>
<!----
	<cfdump var=#d#>
---->

	<cfset allkeys=querynew("keyname")>
	<cfloop query="d">
		<cfset x=DeserializeJSON(DYNAMICPROPERTIES)>
		<cfloop collection="#x#" item="key" >
			<cfset queryaddrow(allkeys,
					{keyname=key}
				)>
		</cfloop>


	</cfloop>

	<cfquery name="uk" dbtype="query">
		select distinct keyname from allkeys
	</cfquery>
	<cfdump var=#uk#>
	</cfoutput>


</cfif>

<!----


after getKeys, add to the table

alter table temp_apsu_fish add collection_method varchar2(4000);
alter table temp_apsu_fish add basin varchar2(4000);
alter table temp_apsu_fish add drainage varchar2(4000);
alter table temp_apsu_fish add jar_size varchar2(4000);
alter table temp_apsu_fish add original_collection_source varchar2(4000);
alter table temp_apsu_fish add original_drainage varchar2(4000);
alter table temp_apsu_fish add river_system  varchar2(4000);

alter table temp_apsu_fish add ext_d_p  varchar2(4000);


alter table temp_apsu_fish add dummy  varchar2(4000);

---->

<cfif action is "extractData">

<cfinclude template="/includes/functionLib.cfm">
<cfoutput>
	<cfquery name="d" datasource='uam_god'>
		select catalognumber, DYNAMICPROPERTIES from temp_almnhvp where DYNAMICPROPERTIES is not null and ext_d_p is null and rownum<20000
	</cfquery>
	<cfloop query="d">
		<cfquery name="pbu" datasource='uam_god'>
			update temp_almnhvp set ext_d_p='gotit'
			<cfset x=DeserializeJSON(DYNAMICPROPERTIES)>
			<cfloop collection="#x#" item="key" >
				<cfset f=replace(key," ","_","all")>
				,#f#='#escapeQuotes(x[key])#'
			</cfloop>
			where catalognumber='#catalognumber#'
		</cfquery>
		<p></p>
	</cfloop>
</cfoutput>
</cfif>


<!----

this was super-fast; next time just direct-update the table

patching everything back together is a PITA



	-- just turn the junk from VN into usable variable names with replace

	update temp_uwbm_mamm set DYNAMICPROPERTIES=replace(DYNAMICPROPERTIES,'"Accession Number"','"accn"');
	update temp_uwbm_mamm set DYNAMICPROPERTIES=replace(DYNAMICPROPERTIES,'"Collector and Collector Number"','"colls"');
	update temp_uwbm_mamm set DYNAMICPROPERTIES=replace(DYNAMICPROPERTIES,'"earLengthInMM"','"earmm"');
	update temp_uwbm_mamm set DYNAMICPROPERTIES=replace(DYNAMICPROPERTIES,'"hindfootLengthInMM"','"hfmm"');
	update temp_uwbm_mamm set DYNAMICPROPERTIES=replace(DYNAMICPROPERTIES,'"Preparator and Preparator Number"','"preps"');
	update temp_uwbm_mamm set DYNAMICPROPERTIES=replace(DYNAMICPROPERTIES,'"total length measurement system"','""');
	update temp_uwbm_mamm set DYNAMICPROPERTIES=replace(DYNAMICPROPERTIES,'"reproductive remarks"','"repro"');
	update temp_uwbm_mamm set DYNAMICPROPERTIES=replace(DYNAMICPROPERTIES,'"Litter size"','"littersize"');
	update temp_uwbm_mamm set DYNAMICPROPERTIES=replace(DYNAMICPROPERTIES,'"foot length measurement system"','"foot_units"');
	update temp_uwbm_mamm set DYNAMICPROPERTIES=replace(DYNAMICPROPERTIES,'"measurement comment"','"measremk"');
	update temp_uwbm_mamm set DYNAMICPROPERTIES=replace(DYNAMICPROPERTIES,'"Other Materials Collected"','"moreparts"');

	-- bah, deal with crappy not-quite-JSON one at a time...
		update temp_uwbm_mamm set DYNAMICPROPERTIES=replace(DYNAMICPROPERTIES,'"medium size"','`medium size`');
		update temp_uwbm_mamm set DYNAMICPROPERTIES=replace(DYNAMICPROPERTIES,'"large"','`large`') where DYNAMICPROPERTIES like '%"large"%';
		update temp_uwbm_mamm set DYNAMICPROPERTIES=replace(DYNAMICPROPERTIES,'"Pack 016"','`Pack 016`') where DYNAMICPROPERTIES like '%"Pack 016"%';
	update temp_uwbm_mamm set DYNAMICPROPERTIES=replace(DYNAMICPROPERTIES,'"Pack 006"','`Pack 006`') where DYNAMICPROPERTIES like '%"Pack 006"%';
	update temp_uwbm_mamm set DYNAMICPROPERTIES=replace(DYNAMICPROPERTIES,'"Pack 011"','`Pack 011`') where DYNAMICPROPERTIES like '%"Pack 011"%';
	update temp_uwbm_mamm set DYNAMICPROPERTIES=replace(DYNAMICPROPERTIES,'"Pack 004"','`Pack 004`') where DYNAMICPROPERTIES like '%"Pack 004"%';
	update temp_uwbm_mamm set DYNAMICPROPERTIES=replace(DYNAMICPROPERTIES,'"Pack 002"','`Pack 002`') where DYNAMICPROPERTIES like '%"Pack 002"%';
	update temp_uwbm_mamm set DYNAMICPROPERTIES=replace(DYNAMICPROPERTIES,'"Pack 010"','`Pack 010`') where DYNAMICPROPERTIES like '%"Pack 010"%';
	update temp_uwbm_mamm set DYNAMICPROPERTIES=replace(DYNAMICPROPERTIES,'"Pack 014"','`Pack 014`') where DYNAMICPROPERTIES like '%"Pack 014"%';
	update temp_uwbm_mamm set DYNAMICPROPERTIES=replace(DYNAMICPROPERTIES,'"Pack 012"','`Pack 012`') where DYNAMICPROPERTIES like '%"Pack 012"%';
	update temp_uwbm_mamm set DYNAMICPROPERTIES=replace(DYNAMICPROPERTIES,'"Pack 008"','`Pack 008`') where DYNAMICPROPERTIES like '%"Pack 008"%';
	update temp_uwbm_mamm set DYNAMICPROPERTIES=replace(DYNAMICPROPERTIES,'"Pack 005"','`Pack 005`') where DYNAMICPROPERTIES like '%"Pack 005"%';
	update temp_uwbm_mamm set DYNAMICPROPERTIES=replace(DYNAMICPROPERTIES,'"Pack 003"','`Pack 003`') where DYNAMICPROPERTIES like '%"Pack 003"%';
	update temp_uwbm_mamm set DYNAMICPROPERTIES=replace(DYNAMICPROPERTIES,'"Pack 015"','`Pack 015`') where DYNAMICPROPERTIES like '%"Pack 015"%';
	update temp_uwbm_mamm set DYNAMICPROPERTIES=replace(DYNAMICPROPERTIES,'"Pack 017"','`Pack 017`') where DYNAMICPROPERTIES like '%"Pack 017"%';
	update temp_uwbm_mamm set DYNAMICPROPERTIES=replace(DYNAMICPROPERTIES,'"Justin"','`Justin`') where DYNAMICPROPERTIES like '%"Justin"%';
	update temp_uwbm_mamm set DYNAMICPROPERTIES=replace(DYNAMICPROPERTIES,'"Lupina"','`Lupina`') where DYNAMICPROPERTIES like '%"Lupina"%';
	update temp_uwbm_mamm set DYNAMICPROPERTIES=replace(DYNAMICPROPERTIES,'"Bilbo"','`Bilbo`') where DYNAMICPROPERTIES like '%"Bilbo"%';
	update temp_uwbm_mamm set DYNAMICPROPERTIES=replace(DYNAMICPROPERTIES,'"lip"','`lip`') where DYNAMICPROPERTIES like '%"lip"%';
	update temp_uwbm_mamm set DYNAMICPROPERTIES=replace(DYNAMICPROPERTIES,'""CuL 918, ALFF 173, ALHF 202, AG 541""','"CuL 918, ALFF 173, ALHF 202, AG 541"') where DYNAMICPROPERTIES like '%""CuL 918, ALFF 173, ALHF 202, AG 541""%';
	update temp_uwbm_mamm set DYNAMICPROPERTIES=replace(DYNAMICPROPERTIES,'""cofo We 56316, 1180""','"cofo We 56316, 1180"') where DYNAMICPROPERTIES like '%""cofo We 56316, 1180""%';
	update temp_uwbm_mamm set DYNAMICPROPERTIES=replace(DYNAMICPROPERTIES,'27.5"x2.5" and 26.75"x2""','27.5``x2.5`` and 26.75``x2``"') where DYNAMICPROPERTIES like '%%';
	update temp_uwbm_mamm set DYNAMICPROPERTIES=replace(DYNAMICPROPERTIES,'"xxxxx"','`xxxxx`') where DYNAMICPROPERTIES like '%"xxxxx"%';
	update temp_uwbm_mamm set DYNAMICPROPERTIES=replace(DYNAMICPROPERTIES,'"xxxxx"','`xxxxx`') where DYNAMICPROPERTIES like '%"xxxxx"%';
	update temp_uwbm_mamm set DYNAMICPROPERTIES=replace(DYNAMICPROPERTIES,'"xxxxx"','`xxxxx`') where DYNAMICPROPERTIES like '%"xxxxx"%';
	update temp_uwbm_mamm set DYNAMICPROPERTIES=replace(DYNAMICPROPERTIES,'"xxxxx"','`xxxxx`') where DYNAMICPROPERTIES like '%"xxxxx"%';
	update temp_uwbm_mamm set DYNAMICPROPERTIES=replace(DYNAMICPROPERTIES,'"xxxxx"','`xxxxx`') where DYNAMICPROPERTIES like '%"xxxxx"%';
	update temp_uwbm_mamm set DYNAMICPROPERTIES=replace(DYNAMICPROPERTIES,'"xxxxx"','`xxxxx`') where DYNAMICPROPERTIES like '%"xxxxx"%';
	update temp_uwbm_mamm set DYNAMICPROPERTIES=replace(DYNAMICPROPERTIES,'"xxxxx"','`xxxxx`') where DYNAMICPROPERTIES like '%"xxxxx"%';
	update temp_uwbm_mamm set DYNAMICPROPERTIES=replace(DYNAMICPROPERTIES,'"xxxxx"','`xxxxx`') where DYNAMICPROPERTIES like '%"xxxxx"%';
	update temp_uwbm_mamm set DYNAMICPROPERTIES=replace(DYNAMICPROPERTIES,'"xxxxx"','`xxxxx`') where DYNAMICPROPERTIES like '%"xxxxx"%';
	update temp_uwbm_mamm set DYNAMICPROPERTIES=replace(DYNAMICPROPERTIES,'"xxxxx"','`xxxxx`') where DYNAMICPROPERTIES like '%"xxxxx"%';
	update temp_uwbm_mamm set DYNAMICPROPERTIES=replace(DYNAMICPROPERTIES,'"xxxxx"','`xxxxx`') where DYNAMICPROPERTIES like '%"xxxxx"%';
	update temp_uwbm_mamm set DYNAMICPROPERTIES=replace(DYNAMICPROPERTIES,'"xxxxx"','`xxxxx`') where DYNAMICPROPERTIES like '%"xxxxx"%';
	update temp_uwbm_mamm set DYNAMICPROPERTIES=replace(DYNAMICPROPERTIES,'"xxxxx"','`xxxxx`') where DYNAMICPROPERTIES like '%"xxxxx"%';
	update temp_uwbm_mamm set DYNAMICPROPERTIES=replace(DYNAMICPROPERTIES,'"xxxxx"','`xxxxx`') where DYNAMICPROPERTIES like '%"xxxxx"%';
	update temp_uwbm_mamm set DYNAMICPROPERTIES=replace(DYNAMICPROPERTIES,'"xxxxx"','`xxxxx`') where DYNAMICPROPERTIES like '%"xxxxx"%';
	update temp_uwbm_mamm set DYNAMICPROPERTIES=replace(DYNAMICPROPERTIES,'"xxxxx"','`xxxxx`') where DYNAMICPROPERTIES like '%"xxxxx"%';
	update temp_uwbm_mamm set DYNAMICPROPERTIES=replace(DYNAMICPROPERTIES,'"xxxxx"','`xxxxx`') where DYNAMICPROPERTIES like '%"xxxxx"%';
	update temp_uwbm_mamm set DYNAMICPROPERTIES=replace(DYNAMICPROPERTIES,'"xxxxx"','`xxxxx`') where DYNAMICPROPERTIES like '%"xxxxx"%';
	update temp_uwbm_mamm set DYNAMICPROPERTIES=replace(DYNAMICPROPERTIES,'"xxxxx"','`xxxxx`') where DYNAMICPROPERTIES like '%"xxxxx"%';
	update temp_uwbm_mamm set DYNAMICPROPERTIES=replace(DYNAMICPROPERTIES,'"xxxxx"','`xxxxx`') where DYNAMICPROPERTIES like '%"xxxxx"%';


""

	-- temp table to hold this stuff
	create table cf_vnDynamicProps (
		catnum  varchar2(4000),
		accn varchar2(4000),
		colls varchar2(4000),
		earmm varchar2(4000),
		hfmm varchar2(4000),
		tail varchar2(4000),
		totalLength varchar2(4000),
		weight varchar2(4000),
		tl_units varchar2(4000),
		repro varchar2(4000),
		littersize varchar2(4000)
	);

	alter table cf_vnDynamicProps add wth  varchar2(4000);
	alter table cf_vnDynamicProps add foot_units  varchar2(4000);
	alter table cf_vnDynamicProps add measurements  varchar2(4000);
	alter table cf_vnDynamicProps add preps  varchar2(4000);
	alter table cf_vnDynamicProps add FEATURE  varchar2(4000);

	alter table cf_vnDynamicProps add measremk  varchar2(4000);
	alter table cf_vnDynamicProps add moreparts  varchar2(4000);
---->

<cfif action is "asfad">
<cfquery name="kc" datasource='prod'>
	select * from cf_vnDynamicProps where 1=2
</cfquery>

<cfquery name="d" datasource='prod'>
	select DYNAMICPROPERTIES,CATALOGNUMBER from temp_apsu_fish
</cfquery>
<cfoutput>
	<cfloop query="d">
		<br>#CATALOGNUMBER#: #DYNAMICPROPERTIES#
		<cfset x=DeserializeJSON(DYNAMICPROPERTIES)>
		<cfquery name="insone" datasource='prod'>
			insert into cf_vnDynamicProps (catnum
			<cfloop list="#structKeyList(x)#" index="key">
				,#key#
			</cfloop>
			) values (
			'#CATALOGNUMBER#'
			<cfloop list="#structKeyList(x)#" index="key">
				,'#x[key]#'
			</cfloop>
			)
		</cfquery>
	</cfloop>
</cfoutput>
</cfif>