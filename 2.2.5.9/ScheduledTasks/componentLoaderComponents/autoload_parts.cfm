
<!--------------------------------------------------------------------- parts ---------------------------------------------------------------->

	<cfset numPartAttrs=6>

	<cfquery name="d" datasource="uam_god">
		select * from cf_temp_parts where status = 'autoload' order by last_ts desc limit #recLimit#
	</cfquery>
	<cfif d.recordcount is 0>
		<!--- autoload:record_not_found (and autoload: whatever someone felt like typing) records only need to load weekly or so ---->
		<cfquery name="d" datasource="uam_god">
			select * from cf_temp_parts where status like 'autoload%' and last_ts < current_timestamp - INTERVAL '7 days' order by last_ts desc limit #recLimit#
		</cfquery>
	</cfif>

	<cfif debug is true>
		<cfdump var=#d#>
	</cfif>


	<cfloop query="d">
		<cfset thisRan=true>
		<cfif debug is true>
			<br>looping for key=#d.key#>
		</cfif>
		<cfset errs="">
		
		
		<!--- this can be created by data_entry, no additional checks here ---->	


		<cftry>
			<cftransaction>
				<!--- get specimen --->
				<cfif len(d.guid) gt 0>
					<cfquery name="cid" datasource="uam_god">
						select
							cataloged_item.collection_object_id,
							collection.guid_prefix
						from
							cataloged_item
							inner join collection on cataloged_item.collection_id=collection.collection_id
						where
							concat(collection.guid_prefix,':',cataloged_item.cat_num)=<cfqueryparam value="#d.guid#" CFSQLType="CF_SQL_VARCHAR">
					</cfquery>
				<cfelseif len(d.guid_prefix) gt 0 and len(d.other_id_type) gt 0 and len(d.other_id_number) gt 0>
					<cfquery name="cid" datasource="uam_god">
						select
							cataloged_item.collection_object_id,
							collection.guid_prefix
						from
							cataloged_item
							inner join collection on cataloged_item.collection_id=collection.collection_id
							inner join coll_obj_other_id_num on cataloged_item.collection_object_id=coll_obj_other_id_num.collection_object_id
						where
							collection.guid_prefix=<cfqueryparam value="#d.guid_prefix#" CFSQLType="CF_SQL_VARCHAR"> and
							coll_obj_other_id_num.other_id_type=<cfqueryparam value="#d.other_id_type#" CFSQLType="CF_SQL_VARCHAR"> and
							coll_obj_other_id_num.display_value=<cfqueryparam value="#d.other_id_number#" CFSQLType="CF_SQL_VARCHAR">
					</cfquery>
				<cfelseif len(d.other_id_type) gt 0 and len(d.other_id_number) gt 0>
					<cfquery name="cid" datasource="uam_god">
						select
							coll_obj_other_id_num.collection_object_id,
							collection.guid_prefix
						from
							cataloged_item
							inner join collection on cataloged_item.collection_id=collection.collection_id
							inner join coll_obj_other_id_num on cataloged_item.collection_object_id=coll_obj_other_id_num.collection_object_id
						where
							coll_obj_other_id_num.other_id_type=<cfqueryparam value="#d.other_id_type#" CFSQLType="CF_SQL_VARCHAR"> and
							coll_obj_other_id_num.display_value=<cfqueryparam value="#d.other_id_number#" CFSQLType="CF_SQL_VARCHAR">
					</cfquery>
				<cfelse>
					<cfset errs="autoload:catalog record not resolved">
					<cfquery name="cleanupf" datasource="uam_god">
						update cf_temp_parts set last_ts=current_timestamp,status=<cfqueryparam value="#errs#" CFSQLType="CF_SQL_VARCHAR"> where key=#val(d.key)#
					</cfquery>
					<cfcontinue />
				</cfif>


				<cfif cid.recordcount is not 1 or len(cid.collection_object_id) eq 0>
					<cfset errs="catalog record not resolved">
					<cfquery name="cleanupf" datasource="uam_god">
						update cf_temp_parts set last_ts=current_timestamp,status=<cfqueryparam value="#errs#" CFSQLType="CF_SQL_VARCHAR"> where key=#val(d.key)#
					</cfquery>
					<cfcontinue />
				</cfif>

				<cfquery name="accessCheck" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
					select checkCollectionAccess (<cfqueryparam value="#cid.guid_prefix#" CFSQLType="CF_SQL_VARCHAR">,<cfqueryparam value="#d.username#" CFSQLType="CF_SQL_VARCHAR">) as hasAccess
				</cfquery>
				<cfif debug>
					<cfdump var=#accessCheck#>
				</cfif>
				<cfif not accessCheck.hasAccess>
					<cfquery name="fail" datasource="uam_god">
						update cf_temp_parts set status='username does not have access to collection' where key=#val(d.key)#
					</cfquery>
					<cfcontinue />
				</cfif>


				<cfquery name="thisCC" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
					select
						collection.collection_cde
					from
						cataloged_item
						inner join collection on cataloged_item.collection_id=collection.collection_id
					where
						cataloged_item.collection_object_id = <cfqueryparam value="#cid.collection_object_id#" CFSQLType="cf_sql_int">
				</cfquery>

				<cfquery name="isVP" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
					select part_name from ctspecimen_part_name where
					collection_cde=<cfqueryparam value="#thisCC.collection_cde#" CFSQLType="CF_SQL_VARCHAR"> and
					part_name=<cfqueryparam value="#d.part_name#" CFSQLType="CF_SQL_VARCHAR">
				</cfquery>
				<cfif isVP.recordcount is not 1 or len(isVP.part_name) eq 0>
					<cfset errs="invalid part name">
					<cfquery name="cleanupf" datasource="uam_god">
						update cf_temp_parts set status=<cfqueryparam value="#errs#" CFSQLType="CF_SQL_VARCHAR"> where key=#val(d.key)#
					</cfquery>
					<cfcontinue />
				</cfif>

				<cfquery name="isVD" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
					select COLL_OBJ_DISPOSITION from CTCOLL_OBJ_DISP where
					COLL_OBJ_DISPOSITION=<cfqueryparam value="#d.disposition#" CFSQLType="CF_SQL_VARCHAR">
				</cfquery>
				<cfif isVD.recordcount is not 1 or len(isVD.COLL_OBJ_DISPOSITION) eq 0>
					<cfset errs="invalid disposition">
					<cfquery name="cleanupf" datasource="uam_god">
						update cf_temp_parts set status=<cfqueryparam value="#errs#" CFSQLType="CF_SQL_VARCHAR"> where key=#val(d.key)#
					</cfquery>
					<cfcontinue />
				</cfif>

				<cfset thisContainerID="">
				<cfif len(d.container_barcode) gt 0>
					<cfquery name="pcid" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
						select container_id from container where
						barcode=<cfqueryparam value="#d.container_barcode#" CFSQLType="CF_SQL_VARCHAR">
					</cfquery>
					<cfif pcid.recordcount is not 1 or len(pcid.container_id) eq 0>
						<cfset errs="invalid container">
						<cfquery name="cleanupf" datasource="uam_god">
							update cf_temp_parts set status=<cfqueryparam value="#errs#" CFSQLType="CF_SQL_VARCHAR"> where key=#val(d.key)#
						</cfquery>
						<cfcontinue />
					<cfelse>
						<cfset thisContainerID=pcid.container_id>
					</cfif>
				</cfif>
				<cfloop from="1" to="#numPartAttrs#" index="i">
					<cfset thisAttr=evaluate("part_attribute_type_" & i)>
					<cfset thisAttrVal=evaluate("part_attribute_value_" & i)>
					<cfset thisAttrUnit=evaluate("part_attribute_units_" & i)>
					<cfif len(thisAttr) gt 0 and len(thisAttrVal) gt 0>
						<cfquery name="isva" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
							select  isValidPartAttribute (
								<cfqueryparam value="#thisAttr#" CFSQLType="CF_SQL_VARCHAR">,
								<cfqueryparam value="#thisAttrVal#" CFSQLType="CF_SQL_VARCHAR">,
								<cfqueryparam value="#thisAttrUnit#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisAttrUnit))#">
							) rst
						</cfquery>
						<cfif debug is true>
							<cfdump var=#isva#>
						</cfif>
						<cfif isva.rst is not true>
							<cfset errs=listappend(errs,'attribute #i# invalid')>
						<cfelse>
							<cfset thisAttrDr=evaluate("part_attribute_determiner_" & i)>
							<cfif len(thisAttrDr) gt 0>
								<cfquery name="ck_agnt" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#" >
									select getAgentId('#thisAttrDr#') as aid
								</cfquery>
								<cfif len(ck_agnt.aid) is 0>
									<cfset errs=listappend(errs,"invalid determiner #i#")>
								</cfif>
							</cfif>
						</cfif>
					</cfif>
				</cfloop>
				<cfif len(d.parent_part_barcode) gt 0>
					<cfquery name="gtPrnt" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
						select
							specimen_part.collection_object_id
						from
							specimen_part
							inner join coll_obj_cont_hist on specimen_part.collection_object_id=coll_obj_cont_hist.collection_object_id
							inner join container pc on coll_obj_cont_hist.container_id=pc.container_id
							inner join container bcc on pc.parent_container_id=bcc.container_id
						where
							specimen_part.derived_from_cat_item=<cfqueryparam value="#cid.collection_object_id#" CFSQLType="cf_sql_int"> and
							bcc.barcode=<cfqueryparam value="#d.parent_part_barcode#" CFSQLType="CF_SQL_VARCHAR">
					</cfquery>
					<cfif gtPrnt.recordcount is 1 and len(gtPrnt.collection_object_id) gt 0>
						<cfset derivedFrom=gtPrnt.collection_object_id>
					<cfelse>
						<cfset errs=listappend(errs,"parent part not resolved")>
					</cfif>
				<cfelseif len(d.parent_part_name) gt 0>
					<cfquery name="gtPrnt" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
						select
							specimen_part.collection_object_id
						from
							specimen_part
						where
							specimen_part.derived_from_cat_item=<cfqueryparam value="#cid.collection_object_id#" CFSQLType="cf_sql_int"> and
							specimen_part.part_name=<cfqueryparam value="#d.parent_part_name#" CFSQLType="CF_SQL_VARCHAR">
					</cfquery>
					<cfif gtPrnt.recordcount is 1 and len(gtPrnt.collection_object_id) gt 0>
						<cfset derivedFrom=gtPrnt.collection_object_id>
					<cfelse>
						<cfset errs=listappend(errs,"parent part not resolved")>
					</cfif>
				<cfelse>
					<cfset derivedFrom="">
				</cfif>
				<cfif LEN(errs) GT 0>
					<cfquery name="cleanupf" datasource="uam_god">
						update cf_temp_parts set status=<cfqueryparam value="#errs#" CFSQLType="CF_SQL_VARCHAR"> where key=#val(d.key)#
					</cfquery>
					<cfcontinue />
				</cfif>

				<!---- if we made it here there's a reasonable chance everything will work, give it a go ---->

				<cfquery name="QthisUserID" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
					select getAgentId('#d.username#') as aid
				</cfquery>
				<cfset thisUserID=QthisUserID.aid>
				<cfif len(thisUserID) lt 1>
					<cfquery name="cleanupf" datasource="uam_god">
						update cf_temp_parts set status=<cfqueryparam value="username not resolved" CFSQLType="CF_SQL_VARCHAR"> where key=#val(d.key)#
					</cfquery>
					<cfcontinue />
				</cfif>

				<!---- could use next/currval but this makes getting container slightly more transparent, doens't much affect performance, etc. --->
				<cfquery name="NEXTID"  datasource="uam_god">
					select nextval('sq_collection_object_id') NEXTID
				</cfquery>
				<cfset thisPartID=NEXTID.NEXTID>
				<cfquery name="insColl" datasource="uam_god">
					INSERT INTO coll_object (
						COLLECTION_OBJECT_ID,
						ENTERED_PERSON_ID,
						COLL_OBJECT_ENTERED_DATE,
						LAST_EDITED_PERSON_ID,
						COLL_OBJ_DISPOSITION,
						LOT_COUNT,
						CONDITION
					) VALUES (
						#thisPartID#,
						<cfqueryparam value="#thisUserID#" CFSQLType="cf_sql_int">,
						current_date,
						<cfqueryparam value="#thisUserID#" CFSQLType="cf_sql_int">,
						<cfqueryparam value="#d.disposition#" CFSQLType="CF_SQL_VARCHAR">,
						<cfqueryparam value="#d.lot_count#" CFSQLType="CF_SQL_INT">,
						<cfqueryparam value="#d.condition#" CFSQLType="CF_SQL_VARCHAR">
					)
				</cfquery>

				<cfquery name="newTiss" datasource="uam_god">
					INSERT INTO specimen_part (
						COLLECTION_OBJECT_ID,
						PART_NAME,
						DERIVED_FROM_cat_item,
						sampled_from_obj_id
					) VALUES (
						#thisPartID#,
						<cfqueryparam value="#d.PART_NAME#" CFSQLType="CF_SQL_VARCHAR">,
						<cfqueryparam value="#cid.collection_object_id#" CFSQLType="cf_sql_int">,
						<cfqueryparam value="#derivedFrom#" CFSQLType="cf_sql_int" null="#Not Len(Trim(derivedFrom))#">
					)
				</cfquery>
				<cfif len(d.remarks) gt 0>
					<!---- new remark --->
					<cfquery name="newCollRem" datasource="uam_god">
						INSERT INTO coll_object_remark (
							collection_object_id,
							coll_object_remarks
						) VALUES (
							#thisPartID#,
							<cfqueryparam value="#d.remarks#" CFSQLType="CF_SQL_VARCHAR">
						)
					</cfquery>
				</cfif>
				<cfif len(d.container_barcode) gt 0>
					<cfset thisCollectionObjectID=thisPartId>
					<cfset thisBarcode=d.container_barcode>
					<cfset thisContainerID="">
					<cfset thisParentType="">
					<cfset thisParentLabel="">
					<cfquery name="imaproc" datasource="uam_god">
						call movePartToContainer(
							#thisPartID#,
							<cfqueryparam value="#thisBarcode#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisBarcode))#">,
							<cfqueryparam value="#thisContainerID#" CFSQLType="cf_sql_int" null="#Not Len(Trim(thisContainerID))#">,
							<cfqueryparam value="#thisParentType#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisParentType))#">,
							<cfqueryparam value="#thisParentLabel#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisParentLabel))#">
						)
					</cfquery>
				</cfif>

				<cfloop from="1" to="#numPartAttrs#" index="i">
					<cfset thisAttr=evaluate("part_attribute_type_" & i)>
					<cfset thisAttrVal=evaluate("part_attribute_value_" & i)>
					<cfif len(thisAttr) gt 0 and len(thisAttrVal) gt 0>
						<cfset thisAttrUnit=evaluate("part_attribute_units_" & i)>
						<cfset thisAttrDate=evaluate("part_attribute_date_" & i)>
						<cfif debug>
							<p>
								thisAttrDate==#thisAttrDate#
							</p>
						</cfif>
						<cfset thisAttrDr=evaluate("part_attribute_determiner_" & i)>
						<cfset thisAttRmk=evaluate("part_attribute_remark_" & i)>
						<cfset thisAttMth=evaluate("part_attribute_method_" & i)>
						<cfquery name="ck_agnt" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#" >
							select getAgentId('#thisAttrDr#') as aid
						</cfquery>
						<cfif debug>
							<cfdump var="#ck_agnt#">
						</cfif>
						<cfquery name="npa" datasource="uam_god" result="irslt">
							insert into specimen_part_attribute (
								collection_object_id,
								attribute_type,
								attribute_value,
								attribute_units,
								determined_date,
								determined_by_agent_id,
								attribute_remark,
								determination_method
							) values (
								<cfqueryparam value="#thisPartID#" CFSQLType="cf_sql_int">,
								<cfqueryparam value="#thisAttr#" CFSQLType="CF_SQL_VARCHAR">,
								<cfqueryparam value="#thisAttrVal#" CFSQLType="CF_SQL_VARCHAR">,
								<cfqueryparam value="#thisAttrUnit#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisAttrUnit))#">,
								<cfqueryparam value="#thisAttrDate#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisAttrDate))#">,
								<cfqueryparam value="#ck_agnt.aid#" CFSQLType="cf_sql_int" null="#Not Len(Trim(ck_agnt.aid))#">,
								<cfqueryparam value="#thisAttRmk#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisAttRmk))#">,
								<cfqueryparam value="#thisAttMth#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisAttMth))#">
							)
						</cfquery>
						<cfif debug>
							<cfdump var=#irslt#>
						</cfif>
					</cfif>
				</cfloop>
				<cfif debug is true>
					<br>delete from cf_temp_parts where key=#val(d.key)#
				</cfif>
				<cfquery name="cleanup" datasource="uam_god">
					delete from cf_temp_parts where key=#val(d.key)#
				</cfquery>
			</cftransaction>

			<cfcatch>
				<cfif debug is true>
					<cfdump var=#cfcatch#>
				</cfif>
				<cfquery name="cleanupf" datasource="uam_god">
					update cf_temp_parts set
					status=<cfqueryparam value="load fail::#cfcatch.message#" CFSQLType="CF_SQL_VARCHAR"> where key=#val(d.key)#
				</cfquery>
			</cfcatch>
		</cftry>
	</cfloop>
	<!--------------------------------------------------------------------- END parts ---------------------------------------------------------------->