<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
		version="1.0"
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:exsl="http://exslt.org/common"
		xmlns:sform="http://xanderadvertising.com/xslt"
		extension-element-prefixes="exsl sform">




	<!--
		Name: sform:checkbox
		Description: Renders an HTML checkbox `input` element
		Returns: HTML <input> element
		Parameters:
		* `handle` (mandatory, string): Handle of the field name
		* `value` (optional, string): The selected value sent when the form is submitted
		* `attributes` (optional, node set): Other attributes for this element
		* `event` (optional, node set): The Sections event
		* `section` (optional, string): The section to where this belongs
		* `position` (optional, string): Index of this entry in a multiple entries situation
	-->
	<xsl:template name="sform:checkbox">
		<xsl:param name="handle"/>
		<xsl:param name="value" select="''"/>
		<xsl:param name="attributes" select="''"/>
		<xsl:param name="event" select="$sform:event"/>
		<xsl:param name="section" select="'__fields'"/>
		<xsl:param name="position" select="''"/>

		<xsl:variable name="attribs" select="exsl:node-set($attributes)"/>

		<xsl:variable name="initial-value" select="normalize-space($value)"/>

		<xsl:variable name="postback-value">
			<xsl:call-template name="sform:postback-value">
				<xsl:with-param name="event" select="$event"/>
				<xsl:with-param name="handle" select="$handle"/>
				<xsl:with-param name="section" select="$section"/>
				<xsl:with-param name="position" select="$position"/>
			</xsl:call-template>
		</xsl:variable>

		<xsl:variable name="attrs">
			<xsl:call-template name="sform:attributes-general">
				<xsl:with-param name="handle" select="$handle"/>
				<xsl:with-param name="section" select="$section"/>
				<xsl:with-param name="position" select="$position"/>
			</xsl:call-template>

			<xsl:call-template name="sform:attributes-class">
				<xsl:with-param name="event" select="$event"/>
				<xsl:with-param name="handle" select="$handle"/>
				<xsl:with-param name="section" select="$section"/>
				<xsl:with-param name="position" select="$position"/>
				<xsl:with-param name="class" select="$attribs/class"/>
			</xsl:call-template>

			<type>checkbox</type>

			<value>
				<xsl:value-of select="$initial-value"/>
			</value>

			<xsl:if test="
				$postback-value = $initial-value or
				exsl:node-set($postback-value)/* = $initial-value or
				$postback-value = '' and $attribs/checked = 'checked'
			">
				<checked>checked</checked>
			</xsl:if>

			<xsl:copy-of select="$attribs/*[ name() != 'id' and name() != 'name' and name() != 'class' and name() != 'type' and name() != 'checked' ]"/>
		</xsl:variable>

		<xsl:call-template name="sform:render">
			<xsl:with-param name="element" select="'input'"/>
			<xsl:with-param name="attributes" select="$attrs"/>
		</xsl:call-template>
	</xsl:template>




</xsl:stylesheet>
