<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
		version="1.0"
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:exsl="http://exslt.org/common"
		xmlns:sform="http://xanderadvertising.com/xslt"
		extension-element-prefixes="exsl sform">




	<!--
		Name: sform:label
		Description: Renders an HTML `label` element
		Returns: HTML <label> element
		Parameters:
		* `handle` (mandatory, string): Handle of the field name
		* `value` (optional, string|node set): The value inside the label. Can be HTML code as well
		* `attributes` (optional, node set): Other attributes for this element
		* `event` (optional, node set): The Sections event
		* `section` (optional, string): The section to where this belongs
		* `position` (optional, string): Index of this entry in a multiple entries situation
	-->
	<xsl:template name="sform:label">
		<xsl:param name="handle" select="''"/>
		<xsl:param name="value" select="''"/>
		<xsl:param name="attributes" select="''"/>
		<xsl:param name="event" select="$sform:event"/>
		<xsl:param name="section" select="'__fields'"/>
		<xsl:param name="position" select="''"/>

		<xsl:variable name="attribs" select="exsl:node-set($attributes)"/>

		<xsl:variable name="attrs">
			<xsl:if test="$handle != ''">
				<for>
					<xsl:call-template name="sform:control-id">
						<xsl:with-param name="name">
							<xsl:call-template name="sform:control-name">
								<xsl:with-param name="handle" select="$handle"/>
								<xsl:with-param name="section" select="$section"/>
								<xsl:with-param name="position" select="$position"/>
							</xsl:call-template>
						</xsl:with-param>
					</xsl:call-template>
				</for>
			</xsl:if>

			<xsl:call-template name="sform:attributes-class">
				<xsl:with-param name="event" select="$event"/>
				<xsl:with-param name="handle" select="$handle"/>
				<xsl:with-param name="section" select="$section"/>
				<xsl:with-param name="position" select="$position"/>
				<xsl:with-param name="class" select="$attribs/class"/>
			</xsl:call-template>

			<xsl:copy-of select="$attribs/*[ name() != 'for' and name() != 'id' and name() != 'class' ]"/>
		</xsl:variable>

		<xsl:call-template name="sform:render">
			<xsl:with-param name="element" select="'label'"/>
			<xsl:with-param name="attributes" select="$attrs"/>
			<xsl:with-param name="value" select="$value"/>
		</xsl:call-template>
	</xsl:template>




</xsl:stylesheet>
