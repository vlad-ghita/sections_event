<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
		version="1.0"
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:exsl="http://exslt.org/common"
		xmlns:func="http://exslt.org/functions"
		xmlns:sform="http://xanderadvertising.com/xslt"
		extension-element-prefixes="exsl func sform">




	<xsl:import href="sform.interpretation-classic.xsl"/>
	<xsl:import href="sform.interpretation-custom.xsl"/>




	<xsl:variable name="sform:STATUS_SUCCESS" select="'success'"/>
	<xsl:variable name="sform:STATUS_ERROR" select="'error'"/>
	<xsl:variable name="sform:STATUS_ANY" select="'*'"/>
	<xsl:variable name="sform:STATUS_NONE" select="''"/>




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

		<xsl:param name="wrapper-success-class" select="$success-class"/>
		<xsl:param name="wrapper-error-class" select="$error-class"/>

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
									<xsl:value-of select="$wrapper-error-class"/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="$wrapper-success-class"/>
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
