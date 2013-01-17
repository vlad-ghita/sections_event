<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
		version="1.0"
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:exsl="http://exslt.org/common"
		xmlns:func="http://exslt.org/functions"
		xmlns:sform="http://xanderadvertising.com/xslt"
		extension-element-prefixes="exsl func sform">




	<!--
		Name: sform:validation
		Description: Renders a success/error message and list of invalid fields for an entry
		Returns: HTML
		Parameters:
		* `handle` (optional, string/XML): Handle of field to be processed. If missing, all fields are processed. XML can be supplied with a list of handle to be processed
		* `errors` (optional, XML): Custom errors that will override Symphony ones
		* `errors-enabled` (optional, bool): Switch to enable/disable Symphony errors
		* `custom_errors` (optional, node set): Custom errors that will be appended after Symphony errors
		* `event` (optional, node set): The Sections event
		* `section` (optional, string): The section to where this belongs
		* `position` (optional, string): Index of this entry in a multiple entries situation
		* `error-class` (optional, string): Error class added to container
		* `error-message` (optional, string/XPath): Error notification message. Defaults to Symphony message
		* `success-class` (optional, string): Success class added to container
		* `success-message` (optional, string/XPath): Success notification message. Defaults to Symphony message
		* `html-container-enabled` (optional, string): Switch to enable/disable container
		* `html-wrapper` (optional, string): HTML element to wrapper all errors in
		* `html-wrapper-enabled` (optional, string): Switch to enable/disable errors wrapper
		* `html-elem` (optional, string): HTML element for an error

		Example of multiple handle call:

		<xsl:call-template name="sform:validation">
			<xsl:with-param name="handle">
				<handle>title</handle>
				<handle>body</body>
			</xsl:with-param>
		</xsl:call-template>
	-->
	<xsl:template name="sform:validation">
		<xsl:param name="handle" select="''"/>
		<xsl:param name="errors" select="''"/>
		<xsl:param name="errors-enabled" select="true()"/>
		<xsl:param name="custom-errors" select="''"/>
		<xsl:param name="event" select="$sform:event"/>
		<xsl:param name="section" select="'__fields'"/>
		<xsl:param name="position" select="''"/>
		<xsl:param name="error-class" select="'error'"/>
		<xsl:param name="error-message" select="''"/>
		<xsl:param name="error-message-enabled" select="true()"/>
		<xsl:param name="success-class" select="'success'"/>
		<xsl:param name="success-message" select="''"/>
		<xsl:param name="success-message-enabled" select="true()"/>
		<xsl:param name="html-container-enabled" select="true()"/>
		<xsl:param name="html-wrapper" select="'ul'"/>
		<xsl:param name="html-wrapper-enabled" select="true()"/>
		<xsl:param name="html-elem" select="'li'"/>

		<xsl:variable name="entry-data">
			<xsl:call-template name="sform:entry-data">
				<xsl:with-param name="event" select="$event"/>
				<xsl:with-param name="section" select="$section"/>
				<xsl:with-param name="position" select="$position"/>
			</xsl:call-template>
		</xsl:variable>

		<xsl:variable name="entry" select="exsl:node-set($entry-data)/*"/>
		<xsl:variable name="errs" select="exsl:node-set($errors)"/>

		<!-- Resulting class -->
		<xsl:variable name="result-class">
			<xsl:choose>
				<xsl:when test="$entry/@result = 'error'">
					<xsl:value-of select="$error-class"/>
				</xsl:when>
				<xsl:when test="$entry/@result = 'success'">
					<xsl:value-of select="$success-class"/>
				</xsl:when>
			</xsl:choose>
		</xsl:variable>

		<!-- Resulting status -->
		<xsl:variable name="result-status">
			<xsl:choose>
			    <xsl:when test="$entry/@result = 'error'">error</xsl:when>
				<xsl:when test="$entry/@result = 'success'">success</xsl:when>
			</xsl:choose>
		</xsl:variable>

		<!-- Resulting HTML -->
		<xsl:variable name="result">
			<xsl:choose>
				<xsl:when test="$entry/@result = 'error'">

					<!-- Show main message -->
					<xsl:if test="$error-message-enabled = true()">
						<xsl:choose>
							<xsl:when test="exsl:node-set($error-message)/* or $error-message != ''">
								<xsl:copy-of select="exsl:node-set($error-message)/* | exsl:node-set($error-message)/text()"/>
							</xsl:when>
							<xsl:otherwise>
								<p>
									<xsl:value-of select="$entry/message"/>
								</p>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:if>

					<!-- Compute individual errors -->
					<xsl:variable name="result-errors">
						<xsl:if test="$errors-enabled = true()">

							<!-- Which fields need to be traversed -->
							<xsl:variable name="fields">
								<xsl:choose>

									<!-- Many fields -->
									<xsl:when test="exsl:node-set($handle)/*">
										<xsl:copy-of select="$entry/*[ name() = exsl:node-set($handle)/* ]"/>
									</xsl:when>

									<!-- One field -->
								    <xsl:when test="$handle != ''">
									    <xsl:copy-of select="$entry/*[ name() = $handle ]"/>
								    </xsl:when>

									<!-- All fields -->
								    <xsl:otherwise>
									    <xsl:copy-of select="$entry/*[ not(name() = 'filter') and @type ]"/>
								    </xsl:otherwise>

								</xsl:choose>
							</xsl:variable>
							
							<xsl:for-each select="exsl:node-set($fields)/*">
								<xsl:element name="{$html-elem}">
									<label>
										<xsl:variable name="h" select="name(.)"/>

										<xsl:attribute name="for">
											<xsl:call-template name="sform:control-id">
												<xsl:with-param name="name">
													<xsl:call-template name="sform:control-name">
														<xsl:with-param name="handle" select="$h"/>
														<xsl:with-param name="section" select="$section"/>
														<xsl:with-param name="position" select="$position"/>
													</xsl:call-template>
												</xsl:with-param>
											</xsl:call-template>
										</xsl:attribute>

										<xsl:variable name="custom-err" select="$errs/error[ @handle = $h ]"/>

										<xsl:choose>

											<!-- Custom err: Missing -->
											<xsl:when test="@type = 'missing' and $custom-err[ @type = 'missing' ]">
												<xsl:copy-of select="$custom-err[ @type = 'missing' ]/* | $custom-err[ @type = 'missing' ]/text()"/>
											</xsl:when>

											<!-- Custom err: Invalid -->
											<xsl:when test="@type = 'invalid' and $custom-err[ @type = 'invalid' ]">
												<xsl:copy-of select="$custom-err[ @type = 'invalid' ]/* | $custom-err[ @type = 'invalid' ]/text()"/>
											</xsl:when>

											<!-- Custom err: No specific type match -->
											<xsl:when test="$custom-err[ not(@type) and not(@message) ]">
												<xsl:copy-of select="$custom-err/* | $custom-err/text()"/>
											</xsl:when>

											<!-- Try message -->
											<xsl:when test="@message">
												<xsl:value-of select="@message"/>
											</xsl:when>

											<!-- Default to something useful -->
											<xsl:otherwise>
												<span class="field-name">
													<xsl:value-of select="translate(name(),'-',' ')"/>
												</span>
												<xsl:text> is </xsl:text>
												<xsl:value-of select="@type"/>
											</xsl:otherwise>

										</xsl:choose>
									</label>
								</xsl:element>
							</xsl:for-each>
						</xsl:if>

						<xsl:copy-of select="exsl:node-set($custom-errors)/* | exsl:node-set($custom-errors)/text()"/>
					</xsl:variable>

					<!-- Display in wrapper -->
					<xsl:if test="exsl:node-set($result-errors)/* or $result-errors != ''">
						<xsl:choose>
							<xsl:when test="$html-wrapper-enabled = true()">
								<xsl:element name="{$html-wrapper}">
									<xsl:copy-of select="exsl:node-set($result-errors)/* | exsl:node-set($result-errors)/text()"/>
								</xsl:element>
							</xsl:when>
							<xsl:otherwise>
								<xsl:copy-of select="exsl:node-set($result-errors)/* | exsl:node-set($result-errors)/text()"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:if>

				</xsl:when>
				<xsl:when test="$entry/@result = 'success'">

					<!-- Show main message -->
					<xsl:if test="$success-message-enabled = true()">
						<xsl:choose>
							<xsl:when test="exsl:node-set($success-message)/* or $success-message != ''">
								<xsl:copy-of select="exsl:node-set($success-message)/* | exsl:node-set($success-message)/text()"/>
							</xsl:when>
							<xsl:otherwise>
								<p>
									<xsl:value-of select="$entry/message"/>
								</p>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:if>

				</xsl:when>
			</xsl:choose>
		</xsl:variable>

		<!-- Display in container -->
		<xsl:choose>
			<xsl:when test="$html-container-enabled = true()">
				<div class="validation {$result-class}" data-status="{$result-status}">
					<xsl:copy-of select="exsl:node-set($result)/* | exsl:node-set($result)/text()"/>
				</div>
			</xsl:when>
			<xsl:otherwise>
				<xsl:copy-of select="exsl:node-set($result)/* | exsl:node-set($result)/text()"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>




	<!--
		Name: sform:validation-status
		Description: Returns status info about a field
		Returns: XML
		Parameters:
		* `handle` (optional, string): Handle of the field name
		* `event` (optional, node set): The Sections event
		* `section` (optional, string): The section to where this belongs
		* `position` (optional, string): Index of this entry in a multiple entries situation
	-->
	<xsl:template name="sform:validation-status">
		<xsl:param name="handle"/>
		<xsl:param name="event" select="$sform:event"/>
		<xsl:param name="section" select="'__fields'"/>
		<xsl:param name="position" select="''"/>

		<!-- Get entry data -->
		<xsl:variable name="entry-data">
			<xsl:call-template name="sform:entry-data">
				<xsl:with-param name="event" select="$event"/>
				<xsl:with-param name="section" select="$section"/>
				<xsl:with-param name="position" select="$position"/>
			</xsl:call-template>
		</xsl:variable>

		<xsl:variable name="field" select="exsl:node-set($entry-data)/*/*[ name() = $handle ]"/>

		<xsl:choose>

			<!-- Field has data only in case of error -->
			<xsl:when test="$field/@type">
				<xsl:element name="{$handle}">
					<xsl:attribute name="result">error</xsl:attribute>

					<xsl:for-each select="$field/@*">
						<xsl:attribute name="{name(.)}">
							<xsl:value-of select="."/>
						</xsl:attribute>
					</xsl:for-each>

					<xsl:copy-of select="$field/* | $field/text()"/>
				</xsl:element>
			</xsl:when>

			<!-- Success -->
			<xsl:otherwise>
				<xsl:element name="{$handle}">
					<xsl:attribute name="result">success</xsl:attribute>
				</xsl:element>
			</xsl:otherwise>

		</xsl:choose>
	</xsl:template>




	<!--
		Name: sform:validation-status
		Description: Same as @template sform:validation-status but as a function of easy access
		Returns: XML
		Parameters:
		* `handle` (optional, string): Handle of the field name
		* `event` (optional, node set): The Sections event
		* `section` (optional, string): The section to where this belongs
		* `position` (optional, string): Index of this entry in a multiple entries situation
	-->
	<func:function name="sform:validation-status">
		<xsl:param name="handle"/>
		<xsl:param name="section" select="'__fields'"/>
		<xsl:param name="position" select="''"/>
		<xsl:param name="event" select="$sform:event"/>

		<func:result>
			<xsl:call-template name="sform:validation-status">
				<xsl:with-param name="handle" select="$handle"/>
				<xsl:with-param name="event" select="$event"/>
				<xsl:with-param name="section" select="$section"/>
				<xsl:with-param name="position" select="$position"/>
			</xsl:call-template>
		</func:result>
	</func:function>




</xsl:stylesheet>
