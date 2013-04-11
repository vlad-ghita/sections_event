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
		<xsl:param name="interpretation"></xsl:param>
		<xsl:param name="interpretation-el"></xsl:param>

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




	<!--
		Name: sform:select-days
		Description: Renders an HTML `select` element populated with numbers from 1 to 31
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
		* `label-enabled` (optional, string): Switch to enable / disable $label
		* `label` (optional, string): Label to appear as first option
		* `options` (optional, HTML): Actual options to be displayed
	-->
	<xsl:template name="sform:select-days">
		<!-- Identification -->
		<xsl:param name="event" select="$sform:event"/>
		<xsl:param name="prefix" select="$sform:prefix"/>
		<xsl:param name="section" select="$sform:section"/>
		<xsl:param name="position" select="$sform:position"/>
		<xsl:param name="handle"/>
		<xsl:param name="suffix" select="$sform:suffix"/>

		<!-- Validation -->
		<xsl:param name="interpretation"></xsl:param>
		<xsl:param name="interpretation-el"></xsl:param>

		<!-- Element data -->
		<xsl:param name="value" select="''"/>
		<xsl:param name="attributes" select="''"/>
		<xsl:param name="label-enabled" select="false()"/>
		<xsl:param name="label" select="'Day'"/>
		<xsl:param name="options">
			<xsl:if test="$label-enabled = true()">
				<option value="">
					<xsl:value-of select="$label"/>
				</option>
			</xsl:if>
			<xsl:call-template name="sform:incrementor">
				<xsl:with-param name="start" select="'1'"/>
				<xsl:with-param name="iterations" select="31"/>
			</xsl:call-template>
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
			<xsl:with-param name="options" select="$options"/>
			<xsl:with-param name="attributes" select="$attributes"/>
		</xsl:call-template>
	</xsl:template>




	<!--
		Name: sform:select-months
		Description: Renders an HTML `select` element populated with month names
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
		* `label-enabled` (optional, string): Switch to enable / disable $label
		* `label` (optional, string): Label to appear as first option
		* `months` (optional, XML): Values for month names
		* `options` (optional, HTML): Actual options to be displayed
	-->
	<xsl:template name="sform:select-months">
		<!-- Identification -->
		<xsl:param name="event" select="$sform:event"/>
		<xsl:param name="prefix" select="$sform:prefix"/>
		<xsl:param name="section" select="$sform:section"/>
		<xsl:param name="position" select="$sform:position"/>
		<xsl:param name="handle"/>
		<xsl:param name="suffix" select="$sform:suffix"/>

		<!-- Validation -->
		<xsl:param name="interpretation"></xsl:param>
		<xsl:param name="interpretation-el"></xsl:param>

		<!-- Element data -->
		<xsl:param name="value" select="''"/>
		<xsl:param name="attributes" select="''"/>
		<xsl:param name="label-enabled" select="false()"/>
		<xsl:param name="label" select="'Month'"/>
		<xsl:param name="months">
			<option value="01">January</option>
			<option value="02">February</option>
			<option value="03">March</option>
			<option value="04">April</option>
			<option value="05">May</option>
			<option value="06">June</option>
			<option value="07">July</option>
			<option value="08">August</option>
			<option value="09">September</option>
			<option value="10">October</option>
			<option value="11">November</option>
			<option value="12">December</option>
		</xsl:param>
		<xsl:param name="options">
			<xsl:if test="$label-enabled = true()">
				<option value="">
					<xsl:value-of select="$label"/>
				</option>
			</xsl:if>

			<xsl:copy-of select="$months"/>
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
			<xsl:with-param name="options" select="$options"/>
			<xsl:with-param name="attributes" select="$attributes"/>
		</xsl:call-template>
	</xsl:template>




	<!--
		Name: sform:select-months
		Description: Renders an HTML `select` element populated with years. See $settings for details
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
		* `label-enabled` (optional, string): Switch to enable / disable $label
		* `label` (optional, string): Label to appear as first option
		* `settings` (optional, XML): Option to control direction and number. eg: '+20' => 2013...2033
		* `options` (optional, HTML): Actual options to be displayed
	-->
	<xsl:template name="sform:select-years">
		<!-- Identification -->
		<xsl:param name="event" select="$sform:event"/>
		<xsl:param name="prefix" select="$sform:prefix"/>
		<xsl:param name="section" select="$sform:section"/>
		<xsl:param name="position" select="$sform:position"/>
		<xsl:param name="handle"/>
		<xsl:param name="suffix" select="$sform:suffix"/>

		<!-- Validation -->
		<xsl:param name="interpretation"></xsl:param>
		<xsl:param name="interpretation-el"></xsl:param>

		<!-- Element data -->
		<xsl:param name="value" select="''"/>
		<xsl:param name="attributes" select="''"/>
		<xsl:param name="label-enabled" select="false()"/>
		<xsl:param name="label" select="'Year'"/>
		<xsl:param name="settings" select="''"/>
		<xsl:param name="options">
			<xsl:if test="$label-enabled = true()">
				<option value="">
					<xsl:value-of select="$label"/>
				</option>
			</xsl:if>

			<xsl:choose>
				<xsl:when test="contains($settings,'-')">
					<xsl:call-template name="sform:incrementor">
						<xsl:with-param name="start" select="/data/params/this-year"/>
						<xsl:with-param name="iterations" select="substring-after($settings,'-') + 1"/>
						<xsl:with-param name="direction" select="'-'"/>
					</xsl:call-template>
				</xsl:when>
				<xsl:when test="contains($settings,'+')">
					<xsl:call-template name="sform:incrementor">
						<xsl:with-param name="start" select="/data/params/this-year"/>
						<xsl:with-param name="iterations" select="substring-after($settings,'+') + 1"/>
					</xsl:call-template>
				</xsl:when>
			</xsl:choose>
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
			<xsl:with-param name="options" select="$options"/>
			<xsl:with-param name="attributes" select="$attributes"/>
		</xsl:call-template>
	</xsl:template>




	<!--
		Name: sform:select-base
		Description: Renders an HTML `select` element. For internal use only.
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
		* `label-enabled` (optional, string): Switch to enable / disable $label
		* `label` (optional, string): Label to appear as first option
		* `options` (optional, HTML): Actual options to be displayed
	-->
	<xsl:template name="sform:select-base">
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
		<xsl:param name="options"/>

		<xsl:variable name="attribs" select="exsl:node-set($attributes)"/>

		<xsl:variable name="s">
			<xsl:value-of select="$suffix"/>
			<xsl:if test="$attribs/multiple = 'multiple'">
				<xsl:text>/ </xsl:text>
			</xsl:if>
		</xsl:variable>

		<xsl:variable name="entry-data" select="exsl:node-set(sform:entry-data($event, $section, $position))/*"/>

		<xsl:variable name="pb-value">
			<xsl:choose>
				<xsl:when test="$postback-value != ''">
					<xsl:value-of select="$postback-value"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:call-template name="sform:postback-value">
						<xsl:with-param name="handle" select="$handle"/>
						<xsl:with-param name="suffix" select="$s"/>
						<xsl:with-param name="entry-data" select="$entry-data"/>
					</xsl:call-template>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>

		<xsl:variable name="initial-value" select="normalize-space($value)"/>

		<xsl:variable name="current-value">
			<xsl:choose>
				<xsl:when test="$postback-value-enabled = true() and $entry-data">
					<xsl:value-of select="$pb-value"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$initial-value"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>

		<xsl:variable name="attrs">
			<xsl:call-template name="sform:attributes-general">
				<xsl:with-param name="handle" select="$handle"/>
				<xsl:with-param name="prefix" select="$prefix"/>
				<xsl:with-param name="suffix" select="$s"/>
				<xsl:with-param name="section" select="$section"/>
				<xsl:with-param name="position" select="$position"/>
				<xsl:with-param name="name" select="$attribs/name"/>
				<xsl:with-param name="id" select="$attribs/id"/>
			</xsl:call-template>

			<xsl:call-template name="sform:attributes-class">
				<xsl:with-param name="interpretation" select="$interpretation-el"/>
				<xsl:with-param name="class" select="$attribs/class"/>
			</xsl:call-template>

			<xsl:copy-of select="$attribs/*[ name() != 'id' and name() != 'name' and name() != 'class' ]"/>
		</xsl:variable>

		<xsl:variable name="result_options">
			<xsl:choose>

				<!-- Optgroups -->
				<xsl:when test="count(exsl:node-set($options)/optgroup) > 0">
					<xsl:for-each select="exsl:node-set($options)/optgroup">
						<xsl:copy>
							<xsl:for-each select="@*">
								<xsl:copy/>
							</xsl:for-each>

							<xsl:apply-templates select="option" mode="sform:select-base.option">
								<xsl:with-param name="current-value" select="$current-value"/>
							</xsl:apply-templates>
						</xsl:copy>
					</xsl:for-each>
				</xsl:when>

				<!-- Only options -->
				<xsl:otherwise>
					<xsl:apply-templates select="exsl:node-set($options)/option" mode="sform:select-base.option">
						<xsl:with-param name="current-value" select="$current-value"/>
					</xsl:apply-templates>
				</xsl:otherwise>

			</xsl:choose>
		</xsl:variable>


		<xsl:call-template name="sform:render">
			<xsl:with-param name="element" select="'select'"/>
			<xsl:with-param name="attributes" select="$attrs"/>
			<xsl:with-param name="value" select="$result_options"/>
		</xsl:call-template>
	</xsl:template>



	<!-- Renders one select option -->
	<xsl:template match="option" mode="sform:select-base.option">
		<xsl:param name="current-value"/>

		<xsl:variable name="option-value">
			<xsl:choose>
				<xsl:when test="@value">
					<xsl:value-of select="@value"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="text()"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>

		<option>
			<xsl:if test="$current-value = $option-value">
				<xsl:attribute name="selected">selected</xsl:attribute>
			</xsl:if>

			<xsl:for-each select="@*">
				<xsl:attribute name="{name()}">
					<xsl:value-of select="normalize-space(.)"/>
				</xsl:attribute>
			</xsl:for-each>

			<xsl:value-of select="text()"/>
		</option>
	</xsl:template>




</xsl:stylesheet>
