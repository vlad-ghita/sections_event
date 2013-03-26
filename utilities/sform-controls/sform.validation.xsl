<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
		version="1.0"
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:exsl="http://exslt.org/common"
		xmlns:func="http://exslt.org/functions"
		xmlns:sform="http://xanderadvertising.com/xslt"
		extension-element-prefixes="exsl func sform">




	<xsl:variable name="sform:STATUS_SUCCESS" select="'success'"/>
	<xsl:variable name="sform:STATUS_ERROR" select="'error'"/>
	<xsl:variable name="sform:STATUS_ANY" select="'*'"/>
	<xsl:variable name="sform:STATUS_NONE" select="''"/>




	<!-- Public utilities -->

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
		<xsl:param name="position" select="$sform:position"/>

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
			<xsl:call-template name="sform:validation-interpret-entry">
				<xsl:with-param name="entry-data" select="$entry-data"/>
				<xsl:with-param name="selection" select="$entry-selection"/>
				<xsl:with-param name="messages" select="$entry-messages"/>
				<xsl:with-param name="defaults" select="$entry-defaults"/>
			</xsl:call-template>

			<xsl:call-template name="sform:validation-interpret-filters">
				<xsl:with-param name="entry-data" select="$entry-data"/>
				<xsl:with-param name="selection" select="$filter-selection"/>
				<xsl:with-param name="messages" select="$filter-messages"/>
				<xsl:with-param name="defaults" select="$filter-defaults"/>
			</xsl:call-template>

			<xsl:call-template name="sform:validation-interpret-fields">
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




	<!--
		Name: sform:validation-render
		Description: Shows a HTML validation report from event interpretation.
		Returns: XML

		***** Interpretation *****
		* `interpretation` (mandatory, XML): An Interpretation data.
		* `interpretation-order` (optional, XML): The order in which to render the messages.

		* `html-wrappers` (optional, XML): The HTML wrappers for messages. @see variable wrappers_default for example

		* `success-class` (optional, string): Success class to be added on resulting validation HTML.
		* `error-class` (optional, string): Error class to be added on resulting validation HTML.

		* `main-wrapper` (optional, string): Main container for validation.
	-->
	<xsl:template name="sform:validation-render">
		<!-- Interpretation -->
		<xsl:param name="interpretation"/>
		<xsl:param name="interpretation-order">
			<entry/>
			<filters/>
			<fields/>
			<custom/>
		</xsl:param>

		<xsl:param name="html-wrappers"></xsl:param>

		<xsl:param name="success-class" select="'success'"/>
		<xsl:param name="error-class" select="'error'"/>

		<xsl:param name="main-wrapper" select="'div'"/>


		<!-- Overload values for HTML wrappers -->
		<xsl:variable name="wrappers_default">
			<entry>
				<wrapper>div</wrapper>
				<elem>p</elem>
			</entry>
			<filters>
				<wrapper>div</wrapper>
				<elem>p</elem>
			</filters>
			<fields>
				<wrapper>ul</wrapper>
				<elem>li</elem>
			</fields>
			<custom>
				<wrapper>ul</wrapper>
				<elem>li</elem>
			</custom>
		</xsl:variable>

		<xsl:variable name="wrappers_overloaded">
			<xsl:call-template name="sform:extend">
				<xsl:with-param name="def" select="$wrappers_default"/>
				<xsl:with-param name="in" select="$html-wrappers"/>
			</xsl:call-template>
		</xsl:variable>

		<xsl:variable name="items" select="exsl:node-set($interpretation)/*"/>
		<xsl:variable name="wrappers" select="exsl:node-set($wrappers_overloaded)/*"/>
		<xsl:variable name="order" select="exsl:node-set($interpretation-order)/*"/>


		<!-- Process each type of messages -->
		<xsl:variable name="result">
			<xsl:for-each select="$order">

				<!-- Only if interpretation for this type exist -->
				<xsl:if test="$items[ name() = name(current()) ]">
					<xsl:apply-templates select="." mode="sform:validation-render">
						<xsl:with-param name="items" select="$items[ name() = name(current()) ]"/>
						<xsl:with-param name="wrappers" select="$wrappers[ name() = name(current()) ]"/>
						<xsl:with-param name="success-class" select="$success-class"/>
						<xsl:with-param name="error-class" select="$error-class"/>
					</xsl:apply-templates>
				</xsl:if>

			</xsl:for-each>
		</xsl:variable>

		<!-- Output -->
		<xsl:if test="exsl:node-set($result)/* or exsl:node-set($result)/text() != ''">
			<xsl:choose>

				<!-- Wrapper enabled -->
				<xsl:when test="$main-wrapper != ''">
					<xsl:variable name="do-items-with-errors-exist">
						<xsl:for-each select="$order">
							<xsl:if test="$items[ name() = name(current()) and @cnt-error != 0]">error</xsl:if>
						</xsl:for-each>
					</xsl:variable>

					<xsl:element name="{$main-wrapper}">
						<xsl:attribute name="class">
							<xsl:text>validation </xsl:text>
							<xsl:choose>
								<xsl:when test="$do-items-with-errors-exist != ''">
									<xsl:value-of select="$error-class"/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="$success-class"/>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:attribute>

						<xsl:copy-of select="exsl:node-set($result)/* | exsl:node-set($result)/text()"/>
					</xsl:element>
				</xsl:when>

				<!-- No wrapper -->
				<xsl:otherwise>
					<xsl:copy-of select="exsl:node-set($result)/* | exsl:node-set($result)/text()"/>
				</xsl:otherwise>

			</xsl:choose>
		</xsl:if>
	</xsl:template>




	<!-- Utilities -->

	<!-- Convenience utility for a resource that should be processed -->
	<xsl:template name="sform:validation-tpl-sel">
		<xsl:param name="handle"/>
		<xsl:param name="status" select="''"/>
		<xsl:param name="label" select="''"/>
		<xsl:param name="extMode" select="''"/>
		<xsl:param name="suffix" select="''"/>

		<item handle="{$handle}">
			<xsl:if test="$extMode != ''">
				<xsl:attribute name="extMode">
					<xsl:value-of select="$extMode"/>
				</xsl:attribute>
			</xsl:if>

			<xsl:if test="$status != ''">
				<status>
					<xsl:value-of select="$status"/>
				</status>
			</xsl:if>

			<xsl:if test="$label != ''">
				<label>
					<xsl:value-of select="$label"/>
				</label>
			</xsl:if>

			<xsl:if test="$suffix != ''">
				<suffix>
					<xsl:value-of select="$suffix"/>
				</suffix>
			</xsl:if>
		</item>
	</xsl:template>

	<!-- Convenience utility for a resource's message that should be displayed -->
	<xsl:template name="sform:validation-tpl-msg">
		<xsl:param name="status"/>
		<xsl:param name="msg"/>
		<xsl:param name="handle" select="''"/>

		<item status="{$status}">
			<xsl:if test="$handle != ''">
				<xsl:attribute name="handle">
					<xsl:value-of select="$handle"/>
				</xsl:attribute>
			</xsl:if>

			<msg>
				<xsl:apply-templates select="exsl:node-set($msg)" mode="sform:html"/>
			</msg>
		</item>
	</xsl:template>

	<!-- Convenience utility for a resource's final result of processing -->
	<xsl:template name="sform:validation-tpl-item">
		<xsl:param name="handle"/>
		<xsl:param name="status"/>
		<xsl:param name="msg"/>
		<xsl:param name="original"/>
		<xsl:param name="label" select="''"/>
		<xsl:param name="suffix" select="''"/>
		<xsl:param name="identification"></xsl:param>

		<item handle="{$handle}" status="{$status}">
			<xsl:if test="$label != ''">
				<xsl:attribute name="label">
					<xsl:value-of select="$label"/>
				</xsl:attribute>
			</xsl:if>

			<xsl:if test="$suffix != ''">
				<xsl:attribute name="suffix">
					<xsl:value-of select="$suffix"/>
				</xsl:attribute>
			</xsl:if>

			<xsl:if test="exsl:node-set($identification)/*">
				<id>
					<xsl:copy-of select="$identification"/>
				</id>
			</xsl:if>

			<msg>
				<xsl:apply-templates select="exsl:node-set($msg)" mode="sform:html"/>
			</msg>

			<original>
				<xsl:copy-of select="$original"/>
			</original>
		</item>
	</xsl:template>




	<!-- Internal utilities -->

	<!--
		Name: sform:validation-interpret-entry
		Description: Interprets the results for entry.
		Returns: XML
	-->
	<xsl:template name="sform:validation-interpret-entry">
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
		Name: sform:validation-interpret-filters
		Description: Interprets the results for filters.
		Returns: XML
	-->
	<xsl:template name="sform:validation-interpret-filters">
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
		Name: sform:validation-interpret-fields
		Description: Interprets the results for fields.
		Returns: XML
	-->
	<xsl:template name="sform:validation-interpret-fields">
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




	<!-- Renders entry & filters interpretations -->
	<xsl:template match="*" mode="sform:validation-render">
		<xsl:param name="items"/>
		<xsl:param name="wrappers"/>
		<xsl:param name="success-class"/>
		<xsl:param name="error-class"/>

		<xsl:variable name="type" select="name()"/>

		<xsl:variable name="result">
			<xsl:for-each select="$items/*">
				<xsl:variable name="item" select="msg"/>

				<xsl:choose>

					<!-- Element wrapper is active -->
					<xsl:when test="$wrappers/elem">
						<xsl:element name="{$wrappers/elem}">
							<xsl:attribute name="class">
								<xsl:text>item-</xsl:text>
								<xsl:choose>
									<xsl:when test="@status = $sform:STATUS_SUCCESS">
										<xsl:value-of select="$success-class"/>
									</xsl:when>
									<xsl:when test="@status = $sform:STATUS_ERROR">
										<xsl:value-of select="$error-class"/>
									</xsl:when>
								</xsl:choose>
							</xsl:attribute>

							<xsl:copy-of select="$item/* | $item/text()"/>
						</xsl:element>
					</xsl:when>

					<!-- Element wrapper is not active -->
					<xsl:otherwise>
						<xsl:copy-of select="$item/* | $item/text()"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:for-each>
		</xsl:variable>

		<xsl:if test="exsl:node-set($result)/* or exsl:node-set($result)/text() != ''">
			<xsl:choose>

				<!-- Wrapper is active -->
				<xsl:when test="$wrappers/wrapper">
					<xsl:variable name="cls">
						<xsl:if test="$items/@cnt-success > 0">
							<xsl:value-of select="$type"/>
							<xsl:text>-</xsl:text>
							<xsl:value-of select="$success-class"/>
						</xsl:if>

						<xsl:text> </xsl:text>

						<xsl:if test="$items/@cnt-error > 0">
							<xsl:value-of select="$type"/>
							<xsl:text>-</xsl:text>
							<xsl:value-of select="$error-class"/>
						</xsl:if>
					</xsl:variable>

					<xsl:element name="{$wrappers/wrapper}">
						<xsl:attribute name="class">
							<xsl:value-of select="normalize-space($cls)"/>
						</xsl:attribute>

						<xsl:copy-of select="exsl:node-set($result)/* | exsl:node-set($result)/text()"/>
					</xsl:element>
				</xsl:when>

				<!-- Wrapper is not active -->
				<xsl:otherwise>
					<xsl:copy-of select="exsl:node-set($result)/* | exsl:node-set($result)/text()"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:if>
	</xsl:template>


	<!-- Renders fields interpretation -->
	<xsl:template match="fields" mode="sform:validation-render">
		<xsl:param name="items"/>
		<xsl:param name="wrappers"/>
		<xsl:param name="success-class"/>
		<xsl:param name="error-class"/>

		<xsl:variable name="type" select="name(.)"/>

		<xsl:variable name="result">
			<xsl:for-each select="$items/*">
				<xsl:variable name="item">
					<label>
						<xsl:attribute name="for">
							<xsl:call-template name="sform:control-id">
								<xsl:with-param name="name">
									<xsl:call-template name="sform:control-name">
										<xsl:with-param name="prefix" select="id/prefix"/>
										<xsl:with-param name="section" select="id/section"/>
										<xsl:with-param name="position" select="id/position"/>
										<xsl:with-param name="handle" select="@handle"/>
										<xsl:with-param name="suffix" select="suffix"/>
									</xsl:call-template>
								</xsl:with-param>
							</xsl:call-template>
						</xsl:attribute>

						<xsl:copy-of select="msg/* | msg/text()"/>
					</label>
				</xsl:variable>

				<xsl:choose>

					<!-- Element wrapper is active -->
					<xsl:when test="$wrappers/elem">
						<xsl:element name="{$wrappers/elem}">
							<xsl:attribute name="class">
								<xsl:text>item-</xsl:text>
								<xsl:choose>
									<xsl:when test="@status = $sform:STATUS_SUCCESS">
										<xsl:value-of select="$success-class"/>
									</xsl:when>
									<xsl:when test="@status = $sform:STATUS_ERROR">
										<xsl:value-of select="$error-class"/>
									</xsl:when>
								</xsl:choose>
							</xsl:attribute>

							<xsl:copy-of select="exsl:node-set($item)/* | exsl:node-set($item)/text()"/>
						</xsl:element>
					</xsl:when>

					<!-- Element wrapper is not active -->
					<xsl:otherwise>
						<xsl:copy-of select="exsl:node-set($item)/* | exsl:node-set($item)/text()"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:for-each>
		</xsl:variable>

		<xsl:if test="exsl:node-set($result)/* or exsl:node-set($result)/text() != ''">
			<xsl:choose>

				<!-- Wrapper is active -->
				<xsl:when test="$wrappers/wrapper">
					<xsl:variable name="cls">
						<xsl:if test="$items/@cnt-success > 0">
							<xsl:value-of select="$type"/>
							<xsl:text>-</xsl:text>
							<xsl:value-of select="$success-class"/>
						</xsl:if>

						<xsl:text> </xsl:text>

						<xsl:if test="$items/@cnt-error > 0">
							<xsl:value-of select="$type"/>
							<xsl:text>-</xsl:text>
							<xsl:value-of select="$error-class"/>
						</xsl:if>
					</xsl:variable>

					<xsl:element name="{$wrappers/wrapper}">
						<xsl:attribute name="class">
							<xsl:value-of select="normalize-space($cls)"/>
						</xsl:attribute>

						<xsl:copy-of select="exsl:node-set($result)/* | exsl:node-set($result)/text()"/>
					</xsl:element>
				</xsl:when>

				<!-- Wrapper is not active -->
				<xsl:otherwise>
					<xsl:copy-of select="exsl:node-set($result)/* | exsl:node-set($result)/text()"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:if>
	</xsl:template>




</xsl:stylesheet>
