
<cfoutput>


	<cfquery name="d" datasource="uam_god">
		select nvl(parent_tid,0) parent_tid, term,tid,rank from hierarchical_taxonomy where parent_tid is null
	</cfquery>
	<cfset x="[">
	<cfset i=1>
	<cfloop query="d">

		<!----
		<cfset x=x & '{"id":"id_#tid#","text":"#term# (#rank#)","children":true}'>
		---->
		<cfset x=x & '["#tid#","#parent_tid#","#rank#"]'>
		<cfif i lt d.recordcount>
			<cfset x=x & ",">
		</cfif>
		<cfset i=i+1>
	</cfloop>
	<cfset x=x & "]">

		#x#
	</cfoutput>
	<!-----------------
			myTree.parse([[1,0,"1111"], [2,0,"2222"], [3,0,"3333"], [4,2,"child"]], "jsarray");


		<cfif isdefined("q") and len(q) gt 0>
			<!--- run a query ---->
			<cfquery name="d" datasource="uam_god">
				SELECT
					SYS_CONNECT_BY_PATH(tid || '\' || parent_tid || '\' || TERM || ' (' || rank || ')','|')  pth
				FROM
					hierarchical_taxonomy
				where term like 'Latia%'
					START WITH parent_tid is null
					CONNECT BY PRIOR tid = parent_tid;
			</cfquery>
			<cfset x="[">
			<cfset i=1>
			<cfloop query="d">
				<cfset x=x & '{'>
				<cfloop list="#pth#" index="i" delimiters="|">

				</cfloop>
			</cfloop>

<!----
 || ' (' || rank || ')'
			<cfquery name="d" datasource="uam_god">

SELECT TID,PARENT_TID,TERM, rank   FROM hierarchical_taxonomy   START WITH tid in (select tid from hierarchical_taxonomy where term like '#q#%')  CONNECT BY PRIOR parent_tid=tid
</cfquery>

<cfset x="[">
			<cfset i=1>
			<cfloop query="d">
				<cfif len(parent_tid) is 0>
					<cfset p='##'>
				<cfelse>
					<cfset p='id_#parent_tid#'>
				</cfif>
				<cfset x=x & '{"id":"id_#tid#","text":"#term# (#rank#)","parent":"#p#"}'>
				<cfif i lt d.recordcount>
					<cfset x=x & ",">
				</cfif>
				<cfset i=i+1>
			</cfloop>
			<cfset x=x & "]">

---->
<cfset x='
[
	{"id":"id_82783984","text":"Eukaryota (superkingdom)","parent":"##","children" : true},
	{"id":"id_82783985","text":"Metazoa (kingdom)","parent":"id_82783984","children" : true},
	{"id":"id_82783986","text":"Mollusca (phylum)","parent":"id_82783985","children" : true},
	{"id":"id_82783987","text":"Gastropoda (class)","parent":"id_82783986","children" : true},
	{"id":"id_82795321","text":"Basommatophora (order)","parent":"id_82783987","children" : true},
	{"id":"id_82795322","text":"Latiidae (family)","parent":"id_82795321","children" : true},
	{"id":"id_82795323","text":"Latia (genus)","parent":"id_82795322","children" : true},
	{"id":"id_82795324","text":"Latia lateralis (species)","parent":"id_82795323","children" : true}
] '>



		<cfelse>
			<!--- initial load, or..... ---->
			<cfset dbid=replace(id,"id_","")>




		<cfif dbid is "##">
			<cfquery name="d" datasource="uam_god">
				select term,tid,rank from hierarchical_taxonomy where parent_tid is null
			</cfquery>
			<cfset x="[">
			<cfset i=1>
			<cfloop query="d">

				<!----
				<cfset x=x & '{"id":"id_#tid#","text":"#term# (#rank#)","children":true}'>
				---->
				<cfset x=x & '{"id":"id_#tid#","text":"#term# (#rank#)","parent": "##","children" : true}'>
				<cfif i lt d.recordcount>
					<cfset x=x & ",">
				</cfif>
				<cfset i=i+1>
			</cfloop>
			<cfset x=x & "]">
			<!--- getting children of  anode ---->
		<cfelse>
			<!---- get children of the passed-in node ---->
			<cfquery name="d" datasource="uam_god">
				select term,tid,parent_tid, rank from hierarchical_taxonomy where parent_tid = #dbid#
			</cfquery>
			<cfset x="[">
			<cfset i=1>
			<cfloop query="d">
				<cfif len(parent_tid) is 0>
					<cfset p='##'>
				<cfelse>
					<cfset p='id_#parent_tid#'>
				</cfif>
				<!----
				<cfset x=x & '{"id":"id_#tid#","text":"#term# (#rank#)","state": "closed","children":true}'>
				---->
				<cfset x=x & '{"id":"id_#tid#","parent": "#p#", "text":"#term# (#rank#)","state": "closed","children":true}'>

				<cfif i lt d.recordcount>
					<cfset x=x & ",">
				</cfif>
				<cfset i=i+1>
			</cfloop>
			<cfset x=x & "]">



		</cfif>
			</cfif>

		#x#
</cfoutput>


------------>
<!------

[{"id": "animal", "parent": "#", "text": "Animals<cfif isdefined("test")><cfoutput>#test#</cfoutput></cfif>"},{"id": "device", "parent": "#", "text": "Devices"},{"id": "dog", "parent": "animal", "text": "Dogs"} ]


-- this works
[
                    {"id": "animal", "parent": "#", "text": "Animals"},
                    {"id": "device", "parent": "#", "text": "Devices"},
                    {"id": "dog", "parent": "animal", "text": "Dogs"},
                    {"id": "lion", "parent": "animal", "text": "Lions"},
                    {"id": "mobile", "parent": "device", "text": "Mobile Phones"},
                    {"id": "lappy", "parent": "device", "text": "Laptops"},
                    {"id": "daburman", "parent": "dog", "text": "Dabur Man", "icon": "/"},
                    {"id": "dalmatian", "parent": "dog", "text": "Dalmatian", "icon": "/"},
                    {"id": "african", "parent": "lion", "text": "African Lion", "icon": "/"},
                    {"id": "indian", "parent": "lion", "text": "Indian Lion", "icon": "/"},
                    {"id": "apple", "parent": "mobile", "text": "Apple IPhone 6", "icon": "/"},
                    {"id": "samsung", "parent": "mobile", "text": "Samsung Note II", "icon": "/"},
                    {"id": "lenevo", "parent": "lappy", "text": "Lenevo", "icon": "/"},
                    {"id": "hp", "parent": "lappy", "text": "HP", "icon": "/"}
                ]
				--- end works
<cfoutput>
	<cfif isdefined('getChild')>
		<cfset dbid=replace(id,"id_","")>
		<cfif dbid is "##">
			<cfquery name="d" datasource="uam_god">
				select term,tid,rank from hierarchical_taxonomy where parent_tid is null
			</cfquery>
			<cfset x="[">
			<cfset i=1>
			<cfloop query="d">
				<cfset x=x & '{"id":"id_#tid#","text":"#term# (#rank#)","children":true}'>
				<cfif i lt d.recordcount>
					<cfset x=x & ",">
				</cfif>
				<cfset i=i+1>
			</cfloop>
			<cfset x=x & "]">
		<cfelse>
			<!---- get children of the passed-in node ---->
			<cfquery name="d" datasource="uam_god">
				select term,tid,rank from hierarchical_taxonomy where parent_tid = #dbid#
			</cfquery>
			<cfset x="[">
			<cfset i=1>
			<cfloop query="d">
				<cfset x=x & '{"id":"id_#tid#","text":"#term# (#rank#)","state": "closed","children":true}'>
				<cfif i lt d.recordcount>
					<cfset x=x & ",">
				</cfif>
				<cfset i=i+1>
			</cfloop>
			<cfset x=x & "]">



		</cfif>

		#x#
	</cfif>
</cfoutput>

---->
<!----------

"id":"id_#tid#",



[{
  "id":1,"text":"Root node","children":true
},
{
  "id":2,"text":"Root node2","children":true
}]



[{
  "id":1,"text":"Root node","children":[
    {"id":2,"text":"Child node 1","children":true},
    {"id":3,"text":"Child node 2"}
  ]
}]




[
	{"id":82783984, "text":"Eukaryota","children":"true"}
	{"id":82783975, "text":"adassfas","children":"true"}
]



[
       { "id" : "ajson1", "parent" : "#", "text" : "Simple root node" },
       { "id" : "ajson2", "parent" : "#", "text" : "Root node 2" },
       { "id" : "ajson3", "parent" : "ajson2", "text" : "Child 1" },
       { "id" : "ajson4", "parent" : "ajson2", "text" : "Child 2" },
]


[{
  "id":1,"text":"Root node","children":[
    {"id":2,"text":"Child node 1","children":true},
    {"id":3,"text":"Child node 2"}
  ]
}]


SELECT  LPAD(' ', 2 * LEVEL - 1) || term   FROM hierarchical_taxonomy   START WITH parent_tid is null  CONNECT BY PRIOR tid = parent_tid;
----------->