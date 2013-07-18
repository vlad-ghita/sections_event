<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
		version="1.0"
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:exsl="http://exslt.org/common"
		xmlns:sform="http://xanderadvertising.com/xslt"
		extension-element-prefixes="exsl sform">




	<!--
		Name: sform:select
		Description: Renders an HTML `select` element
		Returns: HTML <select> element
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
		* `postback-value` (optional, node set): Value to use after form was posted and page reloaded.
		* `postback-value-enabled` (optional, node set): Switcher to enable the display of postback value.
		* `items` (optional, XPath/XML): Options to automatically build a list of <option> elements
		* `options` (optional, HTML): Actual options to be displayed. Mandatory if $items is not supplied
	-->
	<xsl:template name="sform:select">
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
		<xsl:param name="items" select="''"/>
		<xsl:param name="options">
			<xsl:for-each select="exsl:node-set($items)/* | exsl:node-set($items)">
				<xsl:if test="text() != ''">
					<option>
						<xsl:if test="@handle or @id or @link-id or @link-handle or @value">
							<xsl:attribute name="value">
								<xsl:value-of select="@handle | @id | @link-id | @link-handle | @value"/>
							</xsl:attribute>
						</xsl:if>

						<xsl:value-of select="text()"/>
					</option>
				</xsl:if>
			</xsl:for-each>
		</xsl:param>

		<xsl:call-template name="sform:select-base">
			<xsl:with-param name="event" select="$event"/>
			<xsl:with-param name="prefix" select="$prefix"/>
			<xsl:with-param name="section" select="$section"/>
			<xsl:with-param name="position" select="$position"/>
			<xsl:with-param name="handle" select="$handle"/>
			<xsl:with-param name="suffix" select="$suffix"/>

			<xsl:with-param name="interpretation" select="$interpretation"/>
			<xsl:with-param name="interpretation-el" select="$interpretation-el"/>

			<xsl:with-param name="value" select="$value"/>
			<xsl:with-param name="postback-value" select="$postback-value"/>
			<xsl:with-param name="postback-value-enabled" select="$postback-value-enabled"/>
			<xsl:with-param name="options" select="$options"/>
			<xsl:with-param name="attributes" select="$attributes"/>
		</xsl:call-template>
	</xsl:template>




</xsl:stylesheet>
