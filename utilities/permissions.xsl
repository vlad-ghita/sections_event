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
		<xsl:param name="res"/>
		<xsl:param name="res_id"/>
		<xsl:param name="action"/>

		<func:result>
			<!-- Call Sections Event permission function through EXSL Function Manager-->
			<xsl:value-of select="permissions:check($res, string($res_id), string($action))"/>
		</func:result>
	</func:function>




</xsl:stylesheet>
