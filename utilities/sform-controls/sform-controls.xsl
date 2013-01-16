<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
		version="1.0"
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:exsl="http://exslt.org/common"
		xmlns:sform="http://xanderadvertising.com/xslt"
		extension-element-prefixes="exsl sform">




	<!--
		Name: Section Form Controls
		Description: An XSLT utility to create truly powerful HTML forms with Symphony.
					 Inspired from @nickdunn's Form Controls.
		Version: 1.0
		Author: Vlad Ghita <http://github.com/vlad-ghita>
		URL: http://github.com/vlad-ghita/sections-event
	-->




	<xsl:import href="sform.checkbox.xsl"/>
	<xsl:import href="sform.input.xsl"/>
	<xsl:import href="sform.label.xsl"/>
	<xsl:import href="sform.radio.xsl"/>
	<xsl:import href="sform.select.xsl"/>
	<xsl:import href="sform.textarea.xsl"/>
	<xsl:import href="sform.validation.xsl"/>




	<!-- Event -->
	<xsl:variable name="sform:event" select="/data/events/sections"/>

	<!-- Class to invalid form controls -->
	<xsl:variable name="sform:invalid-class" select="'invalid'"/>




	<!--
		Name: sform:attributes-general
		Description: attributes common to all form controls (name, id)
		Returns: node set
	-->
	<xsl:template name="sform:attributes-general">
		<xsl:param name="handle"/>
		<xsl:param name="section" select="'__fields'"/>
		<xsl:param name="position" select="''"/>
		<xsl:param name="prefix" select="''"/>

		<xsl:variable name="name">
			<xsl:call-template name="sform:control-name">
				<xsl:with-param name="handle" select="$handle"/>
				<xsl:with-param name="section" select="$section"/>
				<xsl:with-param name="position" select="$position"/>
			</xsl:call-template>
		</xsl:variable>

		<name>
			<xsl:value-of select="$name"/>
		</name>

		<id>
			<xsl:value-of select="$prefix"/>
			<xsl:call-template name="sform:control-id">
				<xsl:with-param name="name" select="$name"/>
			</xsl:call-template>
		</id>
	</xsl:template>


	<!--
		Name: sform:attributes-class
		Description: class attribute
		Returns: node set
	-->
	<xsl:template name="sform:attributes-class">
		<xsl:param name="handle"/>
		<xsl:param name="event" select="$sform:event"/>
		<xsl:param name="section" select="'__fields'"/>
		<xsl:param name="position" select="''"/>
		<xsl:param name="class" select="''"/>

		<xsl:variable name="entry-data">
			<xsl:call-template name="sform:entry-data">
				<xsl:with-param name="event" select="$event"/>
				<xsl:with-param name="section" select="$section"/>
				<xsl:with-param name="position" select="$position"/>
			</xsl:call-template>
		</xsl:variable>

		<xsl:variable name="is_valid">
			<xsl:choose>
				<xsl:when test="exsl:node-set($entry-data)/*/*[name()=$handle and (@type='missing' or @type='invalid')]">false</xsl:when>
				<xsl:otherwise>true</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>

		<xsl:variable name="cls">
			<xsl:if test="$is_valid = 'false'">
				<xsl:value-of select="$sform:invalid-class"/>
			</xsl:if>
			<xsl:text> </xsl:text>
			<xsl:value-of select="$class"/>
		</xsl:variable>

		<class>
			<xsl:value-of select="normalize-space($cls)"/>
		</class>
	</xsl:template>




	<!--
		Name: sform:entry-data
		Description: returns entry data from the event
		Returns: node set
	-->
	<xsl:template name="sform:entry-data">
		<xsl:param name="event" select="$sform:event"/>
		<xsl:param name="section" select="'__fields'"/>
		<xsl:param name="position" select="''"/>

		<xsl:variable name="pos">
			<xsl:choose>
				<xsl:when test="number($position) > 0">
					<xsl:value-of select="$position"/>
				</xsl:when>
				<xsl:otherwise>0</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>

		<xsl:copy-of select="$event/*[ name() = $section ]/entry[ @position = $pos ]"/>
	</xsl:template>




	<!--
		Name: sform:control-name
		Description: returns a keyed field name for use in HTML @name attributes
		Returns: string
	-->
	<xsl:template name="sform:control-name">
		<xsl:param name="handle"/>
		<xsl:param name="section" select="'__fields'"/>
		<xsl:param name="position" select="''"/>

		<xsl:value-of select="concat('sections[',$section,']')"/>

		<xsl:if test="$position != ''">
			<xsl:value-of select="concat('[',$position,']')"/>
		</xsl:if>

		<xsl:call-template name="sform:control-name-recurse">
			<xsl:with-param name="handle" select="$handle"/>
		</xsl:call-template>
	</xsl:template>

	<!--
		Name: sform:control-name-recurse
		Description: traverses the handle and builds named array
		Returns: string
	-->
	<xsl:template name="sform:control-name-recurse">
		<xsl:param name="handle"/>

		<xsl:choose>
			<xsl:when test="contains($handle, '/')">
				<xsl:value-of select="concat('[', substring-before($handle, '/'), ']')"/>
				<xsl:call-template name="sform:control-name-recurse">
					<xsl:with-param name="handle" select="substring-after($handle, '/')"/>
				</xsl:call-template>
			</xsl:when>

			<xsl:when test="$handle = ' '">
				<xsl:text>[]</xsl:text>
			</xsl:when>

			<xsl:when test="$handle != ''">
				<xsl:value-of select="concat('[', $handle, ']')"/>
			</xsl:when>
		</xsl:choose>
	</xsl:template>




	<!--
		Name: sform:control-id
		Description: returns a sanitised version of a field's @name for use as a unique @id attribute
		Returns: string
	-->
	<xsl:template name="sform:control-id">
		<xsl:param name="name"/>

		<xsl:variable name="length" select="string-length($name)"/>

		<xsl:variable name="clean_name">
			<xsl:choose>
				<xsl:when test="substring($name, $length - 2, 3) = '][]'">
					<xsl:value-of select="substring($name, 1, $length - 3)"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$name"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>

		<xsl:value-of select="translate(translate($clean_name,'[','-'),']','')"/>
	</xsl:template>




	<!--
		Name: sform:postback-value
		Description: determines the postback value of a control if the Event has been triggered
		Returns: string
	-->
	<xsl:template name="sform:postback-value">
		<xsl:param name="handle"/>
		<xsl:param name="section" select="'__fields'"/>
		<xsl:param name="event" select="$sform:event"/>
		<xsl:param name="position" select="''"/>

		<xsl:variable name="entry-data">
			<xsl:call-template name="sform:entry-data">
				<xsl:with-param name="event" select="$event"/>
				<xsl:with-param name="section" select="$section"/>
				<xsl:with-param name="position" select="$position"/>
			</xsl:call-template>
		</xsl:variable>

		<xsl:call-template name="sform:postback-value-recurse">
			<xsl:with-param name="node" select="exsl:node-set($entry-data)/*/post-values"/>
			<xsl:with-param name="handle" select="$handle"/>
		</xsl:call-template>
	</xsl:template>

	<!--
		Name: sform:postback-value-recurse
		Description: traverses the handle and extracts post value
		Returns: string
	-->
	<xsl:template name="sform:postback-value-recurse">
		<xsl:param name="node"/>
		<xsl:param name="handle"/>

		<xsl:choose>
			<xsl:when test="contains($handle, '/')">
				<xsl:call-template name="sform:postback-value-recurse">
					<xsl:with-param name="node" select="$node/*[ name() = substring-before($handle, '/') ]"/>
					<xsl:with-param name="handle" select="substring-after($handle, '/')"/>
				</xsl:call-template>
			</xsl:when>

			<xsl:when test="$handle = ' '">
				<xsl:copy-of select="$node/item"/>
			</xsl:when>

			<xsl:when test="$handle != ''">
				<xsl:value-of select="$node/*[ name() = $handle ]"/>
			</xsl:when>
		</xsl:choose>
	</xsl:template>




	<!--
		Name: sform:render
		Description: renders an element
		Returns: node set
	-->
	<xsl:template name="sform:render">
		<xsl:param name="element"/>
		<xsl:param name="attributes"/>
		<xsl:param name="value" select="''"/>

		<xsl:element name="{$element}">
			<xsl:for-each select="exsl:node-set($attributes)/*">
				<xsl:if test=". != ''">
					<xsl:attribute name="{name()}">
						<xsl:value-of select="."/>
					</xsl:attribute>
				</xsl:if>
			</xsl:for-each>

			<xsl:apply-templates select="exsl:node-set($value)" mode="sform:html"/>
		</xsl:element>
	</xsl:template>

	<xsl:template match="*" mode="sform:html">
		<xsl:element name="{name()}">
			<xsl:apply-templates select="* | @* | text()" mode="sform:html"/>
		</xsl:element>
	</xsl:template>

	<xsl:template match="@*" mode="sform:html">
		<xsl:attribute name="{name()}">
			<xsl:value-of select="."/>
		</xsl:attribute>
	</xsl:template>




	<!--
		Name: sform:incrementor
		Description: increases or decreases a number between two bounds
		Returns: a nodeset of <option> elements
	-->
	<xsl:template name="sform:incrementor">
		<xsl:param name="start"/>
		<xsl:param name="iterations"/>
		<xsl:param name="count" select="$iterations"/>
		<xsl:param name="direction" select="'+'"/>
		<xsl:if test="$count > 0">
			<option>
				<xsl:choose>
					<xsl:when test="$direction='-'">
						<xsl:value-of select="$start - ($iterations - $count)"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="$start + ($iterations - $count)"/>
					</xsl:otherwise>
				</xsl:choose>
			</option>
			<xsl:call-template name="sform:incrementor">
				<xsl:with-param name="count" select="$count - 1"/>
				<xsl:with-param name="start" select="$start"/>
				<xsl:with-param name="iterations" select="$iterations"/>
				<xsl:with-param name="direction" select="$direction"/>
			</xsl:call-template>
		</xsl:if>
	</xsl:template>




</xsl:stylesheet>
