<cfquery name="d" datasource="uam_god">
	select * from dgr_locator where freezer='#f#' and rack='#r#' and box='#b#'
</cfquery>
<cfoutput>
<cftransaction>
	<cfquery name="box" dbtype="query">
		select freezer, rack, box from d group by freezer, rack, box
	</cfquery>
	<cfquery name="isbox" datasource="uam_god">
		select * from container where label='DGR-#box.freezer#-#box.rack#-#box.box#'
	</cfquery>
	<cfif len(isbox.container_id) gt 0>
		box DGR-#box.freezer#-#box.rack#-#box.box# already exists - aborting
		<cfquery name="ss" datasource="uam_god">
			update temp_dgrbox set status=status || 'box_already_exists' where box='#box.box#' and rack='#rack.rack#' and freezer='#freezer.freezer#'
		</cfquery>
		<cfabort>
	</cfif>

	<cfquery name="cid" datasource="uam_god">
		select sq_container_id.nextval id from dual
	</cfquery>

	<cfquery name="mkbox" datasource="uam_god">
		insert into container (
			container_id,
			parent_container_id,
			container_type,
			label,
			institution_acronym,
			NUMBER_POSITIONS
		) values (
			#cid.id#,
			15300802,
			'freezer box',
			'DGR-#box.freezer#-#box.rack#-#box.box#',
			'MSB',
			100
		)
	</cfquery>
	<cfset boxid=cid.id>

	<p>
		make box with label DGR-#box.freezer#-#box.rack#-#box.box#
	</p>

	<!--- Mariel can we make these all 100-position boxes, even if that's not quite true?? --->
	<cfloop from ="1" to="100" index="p">
		<p>
			 insert into new box position #p#
		</p>

		<cfquery name="cid" datasource="uam_god">
			select sq_container_id.nextval id from dual
		</cfquery>
		<cfquery name="mkbp" datasource="uam_god">
			insert into container (
				container_id,
				parent_container_id,
				container_type,
				label,
				institution_acronym
			) values (
				#cid.id#,
				#boxid#,
				'position',
				'#p#',
				'MSB'
			)
		</cfquery>
		<cfset lpid=cid.id>
		<!--- if and only if there's a tissue, make a cryovial ---->
		<cfquery name="ist" dbtype="query">
			select * from d where place=#p#
		</cfquery>
		<cfif len(ist.nk) gt 0>
			<cfquery name="cid" datasource="uam_god">
				select sq_container_id.nextval id from dual
			</cfquery>
			<cfquery name="mkbp" datasource="uam_god">
				insert into container (
					container_id,
					parent_container_id,
					container_type,
					label,
					institution_acronym,
					CONTAINER_REMARKS
				) values (
					#cid.id#,
					#lpid#,
					'cryovial',
					'NK #ist.nk# #ist.tissue_type#',
					'MSB',
					'autocreated from DGR Locator data'
				)
			</cfquery>
		</cfif>

	</cfloop>

	<cfquery name="ss" datasource="uam_god">
		update temp_dgrbox set status=status || 'box_create_success' where box='#box.box#' and rack='#box.rack#' and freezer='#box.freezer#'
	</cfquery>
</cftransaction>
</cfoutput>