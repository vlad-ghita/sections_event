<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
		version="1.0"
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:exsl="http://exslt.org/common"
		xmlns:sform="http://xanderadvertising.com/xslt"
		extension-element-prefixes="exsl sform">




	<!--
		Name: sform:textarea
		Description: Renders an HTML `textarea` element
		Returns: HTML <textarea> element
		Parameters:

		***** Identification *****
		* `event` (optional, string): The Event powering the form.
		* `prefix` (optional, string): The prefix that will hold all form data.
		* `section` (optional, string): The section to where data should be sent.
		* `position` (optional, string): Index of this entry in a multiple entries situation. Leave empty if not needed.
		* `handle` (mandatory, string): Handle of the field.
		* `suffix` (optional, string): An xPath like string for more flexibility.

		***** Validation *****
		* `interpretation` (optional, XML node-set): An XML with the validation of the form
		* `interpretation-el` (optional, XML node-set): An XML with the validation for this field

		***** Element data *****
		* `value` (optional, string): The value sent when the form is submitted.
		* `attributes` (optional, node set): Other attributes for this element.
		* `label-enabled` (optional, string): Switch to enable / disable $label
		* `label` (optional, string): Label to appear as first option
	-->
	<xsl:template name="sform:textarea">
		<!-- Identification -->
		<xsl:param name="event" select="$sform:event"/>
		<xsl:param name="prefix" select="$sform:prefix"/>
		<xsl:param name="section" select="$sform:section"/>
		<xsl:param name="position" select="$sform:position"/>
		<xsl:param name="handle"/>
		<xsl:param name="suffix" select="$sform:suffix"/>

		<!-- Validation -->
		<xsl:param name="interpretation">
			<xsl:call-template name="sform:validation-interpret">
				<xsl:with-param name="event" select="$event"/>
				<xsl:with-param name="prefix" select="$prefix"/>
				<xsl:with-param name="section" select="$section"/>
				<xsl:with-param name="position" select="$position"/>
				<xsl:with-param name="fields-sel">
					<xsl:call-template name="sform:validation-tpl-sel">
						<xsl:with-param name="handle" select="$handle"/>
						<xsl:with-param name="extMode" select="'update'"/>
						<xsl:with-param name="suffix" select="$suffix"/>
					</xsl:call-template>
				</xsl:with-param>
			</xsl:call-template>
		</xsl:param>
		<xsl:param name="interpretation-el" select="exsl:node-set($interpretation)/fields/item[ @handle = $handle ]"/>

		<!-- Element data -->
		<xsl:param name="value" select="''"/>
		<xsl:param name="attributes" select="''"/>
		<xsl:param name="postback-value" select="''"/>
		<xsl:param name="postback-value-enabled" select="true()"/>

		<xsl:variable name="attribs" select="exsl:node-set($attributes)"/>

		<xsl:variable name="initial-value" select="exsl:node-set($value)"/>

		<xsl:variable name="entry-data" select="exsl:node-set(sform:entry-data($event, $section, $position))/*"/>

		<xsl:variable name="pb-value">
			<xsl:choose>
				<xsl:when test="exsl:node-set($postback-value)/* or exsl:node-set($postback-value)/text()">
					<xsl:copy-of select="exsl:node-set($postback-value)/* | exsl:node-set($postback-value)/text()"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:call-template name="sform:postback-value">
						<xsl:with-param name="handle" select="$handle"/>
						<xsl:with-param name="suffix" select="$suffix"/>
						<xsl:with-param name="entry-data" select="$entry-data"/>
					</xsl:call-template>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>

		<xsl:variable name="attrs">
			<xsl:call-template name="sform:attributes-general">
				<xsl:with-param name="prefix" select="$prefix"/>
				<xsl:with-param name="handle" select="$handle"/>
				<xsl:with-param name="section" select="$section"/>
				<xsl:with-param name="position" select="$position"/>
				<xsl:with-param name="suffix" select="$suffix"/>
				<xsl:with-param name="name" select="$attribs/name"/>
				<xsl:with-param name="id" select="$attribs/id"/>
			</xsl:call-template>

			<xsl:call-template name="sform:attributes-class">
				<xsl:with-param name="interpretation" select="$interpretation-el"/>
				<xsl:with-param name="class" select="$attribs/class"/>
			</xsl:call-template>

			<xsl:copy-of select="$attribs/*[
				name() != 'id'
				and name() != 'name'
				and name() != 'class'
			]"/>
		</xsl:variable>

		<xsl:call-template name="sform:render">
			<xsl:with-param name="element" select="'textarea'"/>
			<xsl:with-param name="attributes" select="$attrs"/>
			<xsl:with-param name="value">
				<xsl:choose>
					<xsl:when test="$postback-value-enabled = true() and $entry-data">
						<xsl:copy-of select="exsl:node-set($pb-value)/* | exsl:node-set($pb-value)/text()"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:copy-of select="exsl:node-set($initial-value)/* | exsl:node-set($initial-value)/text()"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>




</xsl:stylesheet>
