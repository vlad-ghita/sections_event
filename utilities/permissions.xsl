<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:func="http://exslt.org/functions"
		xmlns:permissions="http://xanderadvertising.com/functions"
		xmlns:utils="http://exslt.org/utils"
		extension-element-prefixes="func utils">




	<!-- include EFM stream -->
	<xsl:import href="efm://functions"/>




	<!--
		Checks for permissions.

		@param res - can be "section | field"
		@param res_id - can be ID of the section or field
		@param action - supported actions. Include "SE : Permissions" datasource for possible values

		@return 1 - if user has permission, 0 otherwise

		@example

			<xsl:if test="utils:permCheck('section',1,/data/se-permissions/actions/create) = 1">
				Ypiii. User has permission to create entries in section with ID 1
			</xsl:if>
	-->
	<func:function name="utils:permCheck">
		<xsl:param name="res_type"/>
		<xsl:param name="res_id"/>
		<xsl:param name="action"/>

		<func:result>
			<!-- Call Sections Event permission function through EXSL Function Manager-->
			<xsl:value-of select="permissions:controlCheck(string($res_type), string($res_id), string($action))"/>
		</func:result>
	</func:function>




	<!--
		Get permission level for resource.

		@param res_type - can be "section | event"
		@param res_id - resource ID
		@param action - see global actions for possible values

		@return any value from /data/se-permissions/levels/*

		@example

			Return permission level for section with ID = 1 for Action CREATE
			<xsl:value-of select="utils:permGetLevel('section', 1, /data/se-permissions/actions/create)"/>
	-->
	<func:function name="utils:permGetLevel">
		<xsl:param name="res_type"/>
		<xsl:param name="res_id"/>
		<xsl:param name="action"/>

		<func:result>
			<!-- Call Sections Event permission function through EXSL Function Manager-->
			<xsl:value-of select="permissions:controlGetLevel(string($res_type), string($res_id), string($action))"/>
		</func:result>
	</func:function>




</xsl:stylesheet>
