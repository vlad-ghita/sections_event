<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
		version="1.0"
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:exsl="http://exslt.org/common"
		xmlns:sform="http://xanderadvertising.com/xslt"
		extension-element-prefixes="exsl sform">




	<!--
		Name: sform:validation
		Description: Renders a success/error message and list of invalid fields for an entry
		Returns: HTML
		Parameters:
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
	-->
	<xsl:template name="sform:validation">
		<xsl:param name="errors" select="''"/>
		<xsl:param name="errors-enabled" select="true()"/>
		<xsl:param name="custom-errors" select="''"/>
		<xsl:param name="event" select="$sform:event"/>
		<xsl:param name="section" select="'__fields'"/>
		<xsl:param name="position" select="''"/>
		<xsl:param name="error-class" select="'error'"/>
		<xsl:param name="error-message" select="''"/>
		<xsl:param name="success-class" select="'success'"/>
		<xsl:param name="success-message" select="''"/>
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

		<xsl:variable name="e" select="exsl:node-set($entry-data)/*"/>
		<xsl:variable name="errs" select="exsl:node-set($errors)"/>

		<xsl:choose>
			<xsl:when test="$e/@result = 'error'">
				<xsl:variable name="result">
					<xsl:choose>
						<xsl:when test="exsl:node-set($error-message)/* or $error-message != ''">
							<xsl:copy-of select="exsl:node-set($error-message)/* | exsl:node-set($error-message)/text()"/>
						</xsl:when>
						<xsl:otherwise>
							<p>
								<xsl:value-of select="$e/message"/>
							</p>
						</xsl:otherwise>
					</xsl:choose>

					<xsl:variable name="result-errors">
						<xsl:if test="$errors-enabled = true()">
							<xsl:for-each select="$e/*[ not(name() = 'filter') and @type ]">
								<xsl:element name="{$html-elem}">
									<label>
										<xsl:variable name="handle" select="name(.)"/>

										<xsl:attribute name="for">
											<xsl:call-template name="sform:control-id">
												<xsl:with-param name="name">
													<xsl:call-template name="sform:control-name">
														<xsl:with-param name="handle" select="$handle"/>
														<xsl:with-param name="section" select="$section"/>
														<xsl:with-param name="position" select="$position"/>
													</xsl:call-template>
												</xsl:with-param>
											</xsl:call-template>
										</xsl:attribute>

										<xsl:variable name="custom-err" select="$errs/error[ @handle = $handle ]"/>

										<xsl:choose>

											<!-- Custom error: missing -->
											<xsl:when test="@type = 'missing' and $custom-err[ @type = 'missing' ]">
												<xsl:copy-of select="$custom-err[ @type = 'missing' ]/* | $custom-err[ @type = 'missing' ]/text()"/>
											</xsl:when>

											<!-- Custom error: invalid -->
											<xsl:when test="@type = 'invalid' and $custom-err[ @type = 'invalid' ]">
												<xsl:copy-of select="$custom-err[ @type = 'invalid' ]/* | $custom-err[ @type = 'invalid' ]/text()"/>
											</xsl:when>

											<!-- Custom error: no specific type match -->
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
				</xsl:variable>

				<xsl:choose>
					<xsl:when test="$html-container-enabled = true()">
						<div class="validation-summary {$error-class}" data-status="error">
							<xsl:copy-of select="exsl:node-set($result)/* | exsl:node-set($result)/text()"/>
						</div>
					</xsl:when>
					<xsl:otherwise>
						<xsl:copy-of select="exsl:node-set($result)/* | exsl:node-set($result)/text()"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>

			<xsl:when test="$e/@result = 'success'">
				<xsl:variable name="result">
					<xsl:choose>
						<xsl:when test="exsl:node-set($success-message)/* or $success-message != ''">
							<xsl:copy-of select="exsl:node-set($success-message)/* | exsl:node-set($success-message)/text()"/>
						</xsl:when>
						<xsl:otherwise>
							<p>
								<xsl:value-of select="$e/message"/>
							</p>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>

				<xsl:choose>
					<xsl:when test="$html-container-enabled = true()">
						<div class="validation-summary {$success-class}" data-status="success">
							<xsl:copy-of select="exsl:node-set($result)/* | exsl:node-set($result)/text()"/>
						</div>
					</xsl:when>
					<xsl:otherwise>
						<xsl:copy-of select="exsl:node-set($result)/* | exsl:node-set($result)/text()"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
		</xsl:choose>
	</xsl:template>




</xsl:stylesheet>
