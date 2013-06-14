<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
		version="1.0"
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:exsl="http://exslt.org/common"
		xmlns:func="http://exslt.org/functions"
		xmlns:sform="http://xanderadvertising.com/xslt"
		extension-element-prefixes="exsl func sform">




	<!--
		Name: sform:validation-interpret
		Description: Interprets the results of an event's data and returns it as custom XML.
		Returns: XML

		***** Identification *****
		* `event` (optional, string): The Event powering the form.
		* `prefix` (optional, string): The prefix that will hold all form data.
		* `section` (optional, string): The section to where data should be sent.
		* `position` (optional, string): Index of this entry in a multiple entries situation. Leave empty if not needed.

		***** Entry *****
		* `entry-selection` (optional, string|XML): Select the entry that will be interpreted. Defaults to all
		* `entry-messages` (optional, XML): Set the success / error messages. @call sform:validation-tpl-msg to add message
		* `entry-defaults` (optional, XML): Default success / error messages

		***** Filters *****
		* `filter-selection` (optional, string|XML): Select the filters that will be interpreted. Defaults to all
		* `filter-messages` (optional, XML): Set the success / error messages. @call sform:validation-tpl-msg to add message
		* `filter-defaults` (optional, XML): Default success / error messages

		***** Fields *****
		* `filter-selection` (optional, string|XML): Select the fields that will be interpreted. Defaults to all
		* `filter-messages` (optional, XML): Set the success / error messages. @call sform:validation-tpl-msg to add message
		* `filter-defaults` (optional, XML): Default success / error messages

	-->
	<xsl:template name="sform:validation-interpret">
		<!-- Identification -->
		<xsl:param name="event" select="$sform:event"/>
		<xsl:param name="prefix" select="$sform:prefix"/>
		<xsl:param name="section" select="$sform:section"/>
		<xsl:param name="position" select="$sform:events/sections/*[1]/entry[1]/@position"/>

		<!-- Entry -->
		<xsl:param name="entry-selection" select="$sform:STATUS_ANY"/>
		<xsl:param name="entry-messages"></xsl:param>
		<xsl:param name="entry-defaults">
			<xsl:call-template name="sform:validation-tpl-msg">
				<xsl:with-param name="status" select="$sform:STATUS_SUCCESS"/>
				<xsl:with-param name="msg" select="'Entry successfully saved.'"/>
			</xsl:call-template>

			<xsl:call-template name="sform:validation-tpl-msg">
				<xsl:with-param name="status" select="$sform:STATUS_ERROR"/>
				<xsl:with-param name="msg" select="'There were errors saving the entry.'"/>
			</xsl:call-template>
		</xsl:param>

		<!-- Filters -->
		<xsl:param name="filter-selection" select="$sform:STATUS_ANY"/>
		<xsl:param name="filter-messages"></xsl:param>
		<xsl:param name="filter-defaults">
			<xsl:call-template name="sform:validation-tpl-msg">
				<xsl:with-param name="status" select="$sform:STATUS_SUCCESS"/>
				<xsl:with-param name="msg" select="'Filter passed.'"/>
			</xsl:call-template>

			<xsl:call-template name="sform:validation-tpl-msg">
				<xsl:with-param name="status" select="$sform:STATUS_ERROR"/>
				<xsl:with-param name="msg" select="'Filter failed.'"/>
			</xsl:call-template>
		</xsl:param>

		<!-- Fields -->
		<xsl:param name="field-selection"></xsl:param>
		<xsl:param name="field-messages"></xsl:param>
		<xsl:param name="field-defaults">
			<xsl:call-template name="sform:validation-tpl-msg">
				<xsl:with-param name="status" select="$sform:STATUS_SUCCESS"/>
				<xsl:with-param name="msg" select="'Field is OK.'"/>
			</xsl:call-template>

			<xsl:call-template name="sform:validation-tpl-msg">
				<xsl:with-param name="status" select="$sform:STATUS_ERROR"/>
				<xsl:with-param name="msg" select="'Field is invalid.'"/>
			</xsl:call-template>
		</xsl:param>

		<!-- Get entry data -->
		<xsl:variable name="entry-data-nodeset">
			<xsl:call-template name="sform:entry-data">
				<xsl:with-param name="event" select="$event"/>
				<xsl:with-param name="section" select="$section"/>
				<xsl:with-param name="position" select="$position"/>
			</xsl:call-template>
		</xsl:variable>

		<xsl:variable name="entry-data" select="exsl:node-set($entry-data-nodeset)/*"/>

		<!-- Go further only if data exists -->
		<xsl:if test="$entry-data != '' or $entry-data/*">
			<xsl:call-template name="sform:interpretation-classic.entry">
				<xsl:with-param name="entry-data" select="$entry-data"/>
				<xsl:with-param name="selection" select="$entry-selection"/>
				<xsl:with-param name="messages" select="$entry-messages"/>
				<xsl:with-param name="defaults" select="$entry-defaults"/>
			</xsl:call-template>

			<xsl:call-template name="sform:interpretation-classic.filters">
				<xsl:with-param name="entry-data" select="$entry-data"/>
				<xsl:with-param name="selection" select="$filter-selection"/>
				<xsl:with-param name="messages" select="$filter-messages"/>
				<xsl:with-param name="defaults" select="$filter-defaults"/>
			</xsl:call-template>

			<xsl:call-template name="sform:interpretation-classic.fields">
				<xsl:with-param name="prefix" select="$prefix"/>
				<xsl:with-param name="section" select="$section"/>
				<xsl:with-param name="position" select="$position"/>
				<xsl:with-param name="entry-data" select="$entry-data"/>
				<xsl:with-param name="selection" select="$field-selection"/>
				<xsl:with-param name="messages" select="$field-messages"/>
				<xsl:with-param name="defaults" select="$field-defaults"/>
			</xsl:call-template>
		</xsl:if>
	</xsl:template>




	<!-- Internal utilities -->

	<!--
		Name: sform:interpretation-classic.entry
		Description: Interprets the results for entry.
		Returns: XML
	-->
	<xsl:template name="sform:interpretation-classic.entry">
		<xsl:param name="entry-data"/>
		<xsl:param name="selection"/>
		<xsl:param name="messages"/>
		<xsl:param name="defaults"/>

		<xsl:variable name="default_selection">
			<xsl:call-template name="sform:validation-tpl-sel">
				<xsl:with-param name="handle" select="name($entry-data)"/>
				<xsl:with-param name="status" select="$sform:STATUS_ANY"/>
			</xsl:call-template>
		</xsl:variable>

		<!-- Overwrite default selection -->
		<xsl:variable name="v_selection-nodeset">
			<xsl:call-template name="sform:extend">
				<xsl:with-param name="def" select="$default_selection"/>
				<xsl:with-param name="in" select="$selection"/>
			</xsl:call-template>
		</xsl:variable>

		<xsl:variable name="v_selection" select="exsl:node-set($v_selection-nodeset)/*"/>
		<xsl:variable name="v_messages" select="exsl:node-set($messages)/*"/>
		<xsl:variable name="v_defaults" select="exsl:node-set($defaults)/*"/>

		<!-- Process entries -->
		<xsl:variable name="result-nodeset">
			<xsl:for-each select="$v_selection">

				<!-- Status of this item -->
				<xsl:variable name="item_status">
					<xsl:choose>
						<xsl:when test="$entry-data/@result = 'success'">
							<xsl:value-of select="$sform:STATUS_SUCCESS"/>
						</xsl:when>
						<xsl:when test="$entry-data/@result = 'error'">
							<xsl:value-of select="$sform:STATUS_ERROR"/>
						</xsl:when>
					</xsl:choose>
				</xsl:variable>

				<!-- Check if selection has valid status -->
				<xsl:if test="status = $sform:STATUS_ANY or status = $item_status">

					<!-- Original information -->
					<xsl:variable name="item_original">
						<xsl:element name="{name($entry-data)}">
							<xsl:for-each select="$entry-data/@*">
								<xsl:attribute name="{name(.)}">
									<xsl:value-of select="."/>
								</xsl:attribute>
							</xsl:for-each>
						</xsl:element>
					</xsl:variable>

					<!-- Find out the message -->
					<xsl:variable name="item_message">
						<xsl:choose>

							<!-- Custom -->
							<xsl:when test="$v_messages[ @status = $item_status ]">
								<xsl:copy-of select="$v_messages[ @status = $item_status ]/msg/* | $v_messages[ @status = $item_status ]/msg/text()"/>
							</xsl:when>

							<!-- Symphony -->
							<xsl:when test="$entry-data/message[ not(@status) ]">
								<xsl:copy-of select="$entry-data/message[ not(@status) ]/* | $entry-data/message[ not(@status) ]/text()"/>
							</xsl:when>

							<!-- Default -->
							<xsl:otherwise>
								<xsl:copy-of select="$v_defaults[ @status = $item_status ]/* | $v_defaults[ @status = $item_status ]/text()"/>
							</xsl:otherwise>

						</xsl:choose>
					</xsl:variable>

					<!-- Return the info -->
					<xsl:call-template name="sform:validation-tpl-item">
						<xsl:with-param name="handle" select="@handle"/>
						<xsl:with-param name="status" select="$item_status"/>
						<xsl:with-param name="msg" select="$item_message"/>
						<xsl:with-param name="original" select="$item_original"/>
					</xsl:call-template>
				</xsl:if>
			</xsl:for-each>
		</xsl:variable>

		<xsl:variable name="result" select="exsl:node-set($result-nodeset)/*"/>

		<!-- Return all items -->
		<entry>
			<xsl:attribute name="cnt-success">
				<xsl:value-of select="count($result[ @status = $sform:STATUS_SUCCESS ])"/>
			</xsl:attribute>

			<xsl:attribute name="cnt-error">
				<xsl:value-of select="count($result[ @status = $sform:STATUS_ERROR ])"/>
			</xsl:attribute>

			<xsl:copy-of select="$result"/>
		</entry>
	</xsl:template>


	<!--
		Name: sform:interpretation-classic.filters
		Description: Interprets the results for filters.
		Returns: XML
	-->
	<xsl:template name="sform:interpretation-classic.filters">
		<xsl:param name="entry-data"/>
		<xsl:param name="selection"/>
		<xsl:param name="messages"/>
		<xsl:param name="defaults"/>

		<!-- Defaults to all filters that have errors -->
		<xsl:variable name="default_selection">
			<xsl:for-each select="$entry-data/filter[ not(@type) and not(@label) ]">
				<xsl:call-template name="sform:validation-tpl-sel">
					<xsl:with-param name="handle" select="@name"/>
					<xsl:with-param name="status" select="$sform:STATUS_ERROR"/>
				</xsl:call-template>
			</xsl:for-each>
		</xsl:variable>

		<!-- Overwrite default selection -->
		<xsl:variable name="v_selection-nodeset">
			<xsl:call-template name="sform:extend">
				<xsl:with-param name="def" select="$default_selection"/>
				<xsl:with-param name="in" select="$selection"/>
			</xsl:call-template>
		</xsl:variable>

		<xsl:variable name="v_selection" select="exsl:node-set($v_selection-nodeset)/*"/>
		<xsl:variable name="v_messages" select="exsl:node-set($messages)/*"/>
		<xsl:variable name="v_defaults" select="exsl:node-set($defaults)/*"/>

		<!-- Process filters -->
		<xsl:variable name="result-nodeset">
			<xsl:for-each select="$v_selection">

				<!-- Original information -->
				<xsl:variable name="item_original" select="$entry-data/filter[ @name = current()/@handle and not(@type) ]"/>

				<!-- Find the status -->
				<xsl:variable name="item_status">
					<xsl:choose>
						<xsl:when test="$item_original/@status = 'passed'">
							<xsl:value-of select="$sform:STATUS_SUCCESS"/>
						</xsl:when>
						<xsl:when test="$item_original/@status = 'failed'">
							<xsl:value-of select="$sform:STATUS_ERROR"/>
						</xsl:when>
					</xsl:choose>
				</xsl:variable>

				<xsl:if test="status = $sform:STATUS_ANY or status = $item_status">

					<!-- Find the message -->
					<xsl:variable name="item_message">
						<xsl:choose>

							<!-- Custom -->
							<xsl:when test="$v_messages[ @status = $item_status and @handle = current()/@handle ]">
								<xsl:copy-of select="$v_messages[ @status = $item_status and @handle = current()/@handle ]/* | $v_messages[ @status = $item_status and @handle = current()/@handle ]/text()"/>
							</xsl:when>

							<!-- Symphony -->
							<xsl:when test="$item_original/* or $item_original != ''">
								<xsl:copy-of select="$item_original/* | $item_original/text()"/>
							</xsl:when>

							<!-- Default -->
							<xsl:otherwise>
								<xsl:copy-of select="$v_defaults[ @status = $item_status ]/* | $v_defaults[ @status = $item_status ]/text()"/>
							</xsl:otherwise>

						</xsl:choose>
					</xsl:variable>

					<!-- Return the info -->
					<xsl:call-template name="sform:validation-tpl-item">
						<xsl:with-param name="handle" select="@handle"/>
						<xsl:with-param name="status" select="$item_status"/>
						<xsl:with-param name="msg" select="$item_message"/>
						<xsl:with-param name="original" select="$item_original"/>
					</xsl:call-template>
				</xsl:if>
			</xsl:for-each>
		</xsl:variable>

		<xsl:variable name="result" select="exsl:node-set($result-nodeset)/*"/>

		<!-- Return all items -->
		<filters>
			<xsl:attribute name="cnt-success">
				<xsl:value-of select="count($result[ @status = $sform:STATUS_SUCCESS ])"/>
			</xsl:attribute>

			<xsl:attribute name="cnt-error">
				<xsl:value-of select="count($result[ @status = $sform:STATUS_ERROR ])"/>
			</xsl:attribute>

			<xsl:copy-of select="$result"/>
		</filters>
	</xsl:template>


	<!--
		Name: sform:interpretation-classic.fields
		Description: Interprets the results for fields.
		Returns: XML
	-->
	<xsl:template name="sform:interpretation-classic.fields">
		<xsl:param name="prefix"/>
		<xsl:param name="section"/>
		<xsl:param name="position"/>
		<xsl:param name="entry-data"/>
		<xsl:param name="selection"/>
		<xsl:param name="messages"/>
		<xsl:param name="defaults"/>

		<!-- These are the fields that have errors -->
		<xsl:variable name="default_selection">
			<xsl:for-each select="$entry-data/*[ not(name() = 'filter') and @type ]">
				<xsl:call-template name="sform:validation-tpl-sel">
					<xsl:with-param name="handle" select="name(.)"/>
					<xsl:with-param name="status" select="$sform:STATUS_ERROR"/>
				</xsl:call-template>
			</xsl:for-each>
		</xsl:variable>

		<!-- Overwrite default selection -->
		<xsl:variable name="v_selection-nodeset">
			<xsl:call-template name="sform:extend">
				<xsl:with-param name="def" select="$default_selection"/>
				<xsl:with-param name="in" select="$selection"/>
			</xsl:call-template>
		</xsl:variable>

		<xsl:variable name="v_selection" select="exsl:node-set($v_selection-nodeset)/*"/>
		<xsl:variable name="v_messages" select="exsl:node-set($messages)/*"/>
		<xsl:variable name="v_defaults" select="exsl:node-set($defaults)/*"/>

		<!-- Process fields -->
		<xsl:variable name="result-nodeset">
			<xsl:for-each select="$v_selection">

				<!-- Original information -->
				<xsl:variable name="item_original" select="$entry-data/*[ name() = current()/@handle and @type ]"/>

				<!-- Find the status -->
				<xsl:variable name="item_status">
					<xsl:choose>
						<xsl:when test="$item_original">
							<xsl:value-of select="$sform:STATUS_ERROR"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="$sform:STATUS_SUCCESS"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>

				<xsl:if test="status = $sform:STATUS_ANY or status = $item_status">

					<!-- Find the label -->
					<xsl:variable name="item_label">
						<xsl:choose>

							<!-- Custom -->
							<xsl:when test="label != ''">
								<xsl:value-of select="label"/>
							</xsl:when>

							<!-- Symphony -->
							<xsl:when test="$item_original/@label != ''">
								<xsl:value-of select="$item_original/@label"/>
							</xsl:when>

							<!-- Default -->
							<xsl:otherwise>
								<xsl:value-of select="@handle"/>
							</xsl:otherwise>

						</xsl:choose>
					</xsl:variable>

					<!-- Find the suffix -->
					<xsl:variable name="item_suffix">
						<!-- Custom -->
						<xsl:if test="suffix != ''">
							<xsl:value-of select="suffix"/>
						</xsl:if>
					</xsl:variable>

					<!-- Find the message -->
					<xsl:variable name="item_message">
						<xsl:choose>

							<!-- Custom -->
							<xsl:when test="$v_messages[ @status = $item_status and @handle = current()/@handle ]">
								<xsl:copy-of select="$v_messages[ @status = $item_status and @handle = current()/@handle ]/* | $v_messages[ @status = $item_status and @handle = current()/@handle ]/text()"/>
							</xsl:when>

							<!-- Symphony -->
							<xsl:when test="$item_original/@message">
								<xsl:value-of select="$item_original/@message"/>
							</xsl:when>

							<!-- Default -->
							<xsl:otherwise>
								<xsl:copy-of select="$v_defaults[ @status = $item_status ]/* | $v_defaults[ @status = $item_status ]/text()"/>
							</xsl:otherwise>

						</xsl:choose>
					</xsl:variable>

					<!-- Return the info -->
					<xsl:call-template name="sform:validation-tpl-item">
						<xsl:with-param name="handle" select="@handle"/>
						<xsl:with-param name="status" select="$item_status"/>
						<xsl:with-param name="msg" select="$item_message"/>
						<xsl:with-param name="original" select="$item_original"/>
						<xsl:with-param name="label" select="$item_label"/>
						<xsl:with-param name="suffix" select="$item_suffix"/>
						<xsl:with-param name="identification">
							<prefix>
								<xsl:value-of select="$prefix"/>
							</prefix>
							<section>
								<xsl:value-of select="$section"/>
							</section>
							<position>
								<xsl:value-of select="$position"/>
							</position>
						</xsl:with-param>
					</xsl:call-template>
				</xsl:if>
			</xsl:for-each>
		</xsl:variable>

		<xsl:variable name="result" select="exsl:node-set($result-nodeset)/*"/>

		<!-- Return all items -->
		<fields>
			<xsl:attribute name="cnt-success">
				<xsl:value-of select="count($result[ @status = $sform:STATUS_SUCCESS ])"/>
			</xsl:attribute>

			<xsl:attribute name="cnt-error">
				<xsl:value-of select="count($result[ @status = $sform:STATUS_ERROR ])"/>
			</xsl:attribute>

			<xsl:copy-of select="$result"/>
		</fields>
	</xsl:template>




</xsl:stylesheet>
