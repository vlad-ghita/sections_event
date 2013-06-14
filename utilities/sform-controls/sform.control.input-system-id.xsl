<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
		version="1.0"
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:exsl="http://exslt.org/common"
		xmlns:sform="http://xanderadvertising.com/xslt"
		extension-element-prefixes="exsl sform">




	<!--
		Name: sform:input-system-id
		Description: Renders an HTML `input` element for an Entry ID
		Returns: HTML <input> element
		Parameters:

		* `section` (string): The section to where data should be sent.
		* `position` (optional, string): Index of this entry in a multiple entries situation. Leave empty if not needed.
		* `value` (string): Entry ID.
	-->
	<xsl:template name="sform:input-system-id">
		<xsl:param name="section"/>
		<xsl:param name="position" select="$sform:position"/>
		<xsl:param name="value"/>

		<xsl:call-template name="sform:input">
			<xsl:with-param name="section" select="$section"/>
			<xsl:with-param name="position" select="$position"/>
			<xsl:with-param name="handle" select="'__system-id'"/>
			<xsl:with-param name="interpretation" select="''"/>
			<xsl:with-param name="interpretation-el" select="''"/>
			<xsl:with-param name="value" select="$value"/>
			<xsl:with-param name="attributes">
				<type>hidden</type>
			</xsl:with-param>
			<xsl:with-param name="postback-value-enabled" select="false()"/>
		</xsl:call-template>
	</xsl:template>




</xsl:stylesheet>
