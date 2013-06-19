<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
		version="1.0"
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:exsl="http://exslt.org/common"
		xmlns:func="http://exslt.org/functions"
		xmlns:sform="http://xanderadvertising.com/xslt"
		extension-element-prefixes="exsl func sform">




	<!--
		Name: Section Form Controls
		Description: An XSLT utility to create truly powerful HTML forms with Symphony.
		Author: Vlad Ghita <http://github.com/vlad-ghita>
		URL: http://github.com/vlad-ghita/sections_event
	-->




	<xsl:import href="sform.control.checkbox.xsl"/>
	<xsl:import href="sform.control.input-entry-action.xsl"/>
	<xsl:import href="sform.control.input-system-id.xsl"/>
	<xsl:import href="sform.control.input.xsl"/>
	<xsl:import href="sform.control.label.xsl"/>
	<xsl:import href="sform.control.radio.xsl"/>
	<xsl:import href="sform.control.select-base.xsl"/>
	<xsl:import href="sform.control.select-days.xsl"/>
	<xsl:import href="sform.control.select-months.xsl"/>
	<xsl:import href="sform.control.select-years.xsl"/>
	<xsl:import href="sform.control.select.xsl"/>
	<xsl:import href="sform.control.textarea.xsl"/>
	<xsl:import href="sform.validation.xsl"/>




	<!-- Some default config. DO NOT change this. -->
	<xsl:variable name="sform:null" select="'SFORM_NULL'"/>
	<xsl:variable name="sform:event" select="'sections'"/>
	<xsl:variable name="sform:prefix" select="'sections'"/>
	<xsl:variable name="sform:section" select="'__fields'"/>
	<xsl:variable name="sform:position" select="$sform:null"/>
	<xsl:variable name="sform:suffix" select="''"/>
	<xsl:variable name="sform:events" select="/data/events"/>

	<!-- Class for invalid form controls -->
	<xsl:variable name="sform:invalid-class" select="'error'"/>




	<!--
		Name: sform:attributes-general
		Description: attributes common to all form controls (name, id)
		Returns: XML
	-->
	<xsl:template name="sform:attributes-general">
		<!-- Identification -->
		<xsl:param name="prefix" select="$sform:prefix"/>
		<xsl:param name="section" select="$sform:section"/>
		<xsl:param name="position" select="$sform:position"/>
		<xsl:param name="handle"/>
		<xsl:param name="suffix" select="$sform:suffix"/>

		<!-- Incoming values -->
		<xsl:param name="name" select="false()"/>
		<xsl:param name="id" select="false()"/>

		<xsl:variable name="default-name">
			<xsl:call-template name="sform:control-name">
				<xsl:with-param name="prefix" select="$prefix"/>
				<xsl:with-param name="section" select="$section"/>
				<xsl:with-param name="position" select="$position"/>
				<xsl:with-param name="handle" select="$handle"/>
				<xsl:with-param name="suffix" select="$suffix"/>
			</xsl:call-template>
		</xsl:variable>

		<name>
			<xsl:choose>
			    <xsl:when test="$name != false()">
				    <xsl:value-of select="string($name)"/>
			    </xsl:when>
			    <xsl:otherwise>
				    <xsl:value-of select="$default-name"/>
			    </xsl:otherwise>
			</xsl:choose>
		</name>

		<id>
			<xsl:choose>
			    <xsl:when test="$id != false()">
			        <xsl:value-of select="string($id)"/>
			    </xsl:when>
			    <xsl:otherwise>
				    <xsl:call-template name="sform:control-id">
					    <xsl:with-param name="name" select="$default-name"/>
				    </xsl:call-template>
			    </xsl:otherwise>
			</xsl:choose>
		</id>
	</xsl:template>


	<!--
		Name: sform:attributes-class
		Description: class attribute
		Returns: XML
	-->
	<xsl:template name="sform:attributes-class">
		<!-- Validation result -->
		<xsl:param name="interpretation"/>
		<xsl:param name="class" select="''"/>

		<xsl:variable name="cls">
			<xsl:if test="exsl:node-set($interpretation)/@status = $sform:STATUS_ERROR">
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
		Returns: XML
	-->
	<xsl:template name="sform:entry-data">
		<xsl:param name="event" select="$sform:event"/>
		<xsl:param name="section" select="$sform:section"/>
		<xsl:param name="position" select="$sform:position"/>

		<xsl:choose>

			<!-- Sections Event signature -->
		    <xsl:when test="$section != ''">
			    <xsl:variable name="pos">
				    <xsl:choose>
					    <xsl:when test="$position != $sform:position and number($position) > 0">
						    <xsl:value-of select="$position"/>
					    </xsl:when>
					    <xsl:otherwise>0</xsl:otherwise>
				    </xsl:choose>
			    </xsl:variable>

			    <xsl:copy-of select="$sform:events/*[ name() = $event ]/*[ name() = $section ]/entry[ @position = $pos ]"/>
		    </xsl:when>

			<!-- Other event -->
		    <xsl:otherwise>
			    <xsl:copy-of select="$sform:events/*[ name() = $event ]"/>
		    </xsl:otherwise>

		</xsl:choose>
	</xsl:template>


	<func:function name="sform:entry-data">
		<xsl:param name="event" select="$sform:event"/>
		<xsl:param name="section" select="$sform:section"/>
		<xsl:param name="position" select="$sform:position"/>

		<func:result>
			<xsl:call-template name="sform:entry-data">
				<xsl:with-param name="event" select="$event"/>
				<xsl:with-param name="section" select="$section"/>
				<xsl:with-param name="position" select="$position"/>
			</xsl:call-template>
		</func:result>
	</func:function>




	<!--
		Name: sform:control-name
		Description: returns a keyed field name for use in HTML @name attributes
		Returns: string
	-->
	<xsl:template name="sform:control-name">
		<xsl:param name="prefix" select="$sform:prefix"/>
		<xsl:param name="section" select="$sform:section"/>
		<xsl:param name="position" select="$sform:position"/>
		<xsl:param name="handle"/>
		<xsl:param name="suffix" select="$sform:suffix"/>

		<!-- Gather all bits that form the name -->
		<xsl:variable name="bits_all">
			<item>
				<xsl:value-of select="$prefix"/>
			</item>
			<item>
				<xsl:value-of select="$section"/>
			</item>
			<item>
				<xsl:if test="$position != $sform:position">
					<xsl:value-of select="$position"/>
				</xsl:if>
			</item>
			<item>
				<xsl:value-of select="$handle"/>
			</item>
			<xsl:if test="$suffix != $sform:suffix and $suffix != ''">
				<xsl:call-template name="sform:control-name-recurse">
					<xsl:with-param name="string" select="$suffix"/>
				</xsl:call-template>
			</xsl:if>
		</xsl:variable>

		<!-- Remove empty ones (especially from beginning) -->
		<xsl:variable name="bits_filtered">
			<xsl:for-each select="exsl:node-set($bits_all)/*">
				<xsl:if test="normalize-space(.) != '' or position() = last()">
					<xsl:copy-of select="."/>
				</xsl:if>
			</xsl:for-each>
		</xsl:variable>

		<!-- Return array name -->
		<xsl:value-of select="exsl:node-set($bits_filtered)/*[1]"/>

		<!-- Return array keys -->
		<xsl:for-each select="exsl:node-set($bits_filtered)/*[position() > 1]">
			<xsl:value-of select="concat('[',normalize-space(.),']')"/>
		</xsl:for-each>
	</xsl:template>

	<!--
		Name: sform:control-name-recurse
		Description: traverses the handle and builds named array
		Returns: string
	-->
	<xsl:template name="sform:control-name-recurse">
		<xsl:param name="string"/>

		<item>
			<xsl:choose>
				<xsl:when test="contains($string, '/')">
					<xsl:value-of select="substring-before($string, '/')"/>
				</xsl:when>

				<xsl:when test="$string = ' '"/>

				<xsl:when test="$string != ''">
					<xsl:value-of select="$string"/>
				</xsl:when>
			</xsl:choose>
		</item>

		<xsl:if test="contains($string, '/')">
			<xsl:call-template name="sform:control-name-recurse">
				<xsl:with-param name="string" select="substring-after($string, '/')"/>
			</xsl:call-template>
		</xsl:if>
	</xsl:template>




	<!--
		Name: sform:control-variable
		Description: returns a keyed field name for use as a replaceable variable
		Returns: string
	-->
	<xsl:template name="sform:variable">
		<xsl:param name="section" select="$sform:section"/>
		<xsl:param name="position" select="$sform:position"/>
		<xsl:param name="handle" select="'system:id'"/>
		<xsl:param name="suffix" select="$sform:suffix"/>

		<xsl:variable name="name">
			<xsl:call-template name="sform:control-name">
				<xsl:with-param name="prefix" select="''"/>
				<xsl:with-param name="section" select="$section"/>
				<xsl:with-param name="position" select="$position"/>
				<xsl:with-param name="handle" select="$handle"/>
				<xsl:with-param name="suffix" select="$suffix"/>
			</xsl:call-template>
		</xsl:variable>

		<xsl:value-of select="concat('%',$name,'%')"/>
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

				<!-- Handle case when name ends with `[]` -->
				<xsl:when test="substring($name, $length - 2, 3) = '][]'">
					<xsl:value-of select="substring($name, 1, $length - 3)"/>
				</xsl:when>

				<!-- Name is OK -->
				<xsl:otherwise>
					<xsl:value-of select="$name"/>
				</xsl:otherwise>

			</xsl:choose>
		</xsl:variable>

		<xsl:value-of select="translate(translate($clean_name,'[','_'),']','')"/>
	</xsl:template>




	<!--
		Name: sform:postback-value
		Description: determines the postback value of a control if the Event has been triggered
		Returns: string
	-->
	<xsl:template name="sform:postback-value">
		<xsl:param name="event" select="$sform:event"/>
		<xsl:param name="section" select="$sform:section"/>
		<xsl:param name="position" select="$sform:position"/>
		<xsl:param name="handle"/>
		<xsl:param name="suffix" select="$sform:suffix"/>
		<xsl:param name="entry-data" select="exsl:node-set(sform:entry-data($event, $section, $position))/*"/>

		<xsl:variable name="suf">
			<xsl:if test="$suffix != $sform:suffix">
				<xsl:value-of select="$suffix"/>
			</xsl:if>
		</xsl:variable>

		<xsl:call-template name="sform:postback-value-recurse">
			<xsl:with-param name="node" select="exsl:node-set($entry-data)//post-values/*[ name() = $handle ]"/>
			<xsl:with-param name="string" select="$suf"/>
		</xsl:call-template>
	</xsl:template>

	<!--
		Name: sform:postback-value-recurse
		Description: traverses the handle and extracts post value
		Returns: string
	-->
	<xsl:template name="sform:postback-value-recurse">
		<xsl:param name="node"/>
		<xsl:param name="string"/>

		<xsl:choose>

			<!-- Keep digging -->
			<xsl:when test="contains($string, '/')">
				<xsl:call-template name="sform:postback-value-recurse">
					<xsl:with-param name="node" select="$node/*[ name() = substring-before($string, '/') ]"/>
					<xsl:with-param name="string" select="substring-after($string, '/')"/>
				</xsl:call-template>
			</xsl:when>

			<!-- An array item with auto key -->
			<xsl:when test="$string = ' '">
				<xsl:copy-of select="$node/item"/>
			</xsl:when>

			<!-- An array item with key -->
			<xsl:when test="number($string) = $string">
				<xsl:copy-of select="$node/item[ @index = number($string) + 1 ]"/>
			</xsl:when>

			<!-- Plain node value -->
			<xsl:when test="$string != ''">
				<xsl:value-of select="$node/*[ name() = $string ]"/>
			</xsl:when>

			<!-- The node itself -->
			<xsl:otherwise>
			    <xsl:value-of select="$node"/>
			</xsl:otherwise>

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
				<xsl:if test="normalize-space(.) != ''">
					<xsl:attribute name="{name()}">
						<xsl:value-of select="normalize-space(.)"/>
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
		Returns: a node-set of <option> elements
	-->
	<xsl:template name="sform:incrementor">
		<xsl:param name="start"/>
		<xsl:param name="iterations"/>
		<xsl:param name="count" select="$iterations"/>
		<xsl:param name="direction" select="'+'"/>
		<xsl:if test="$count > 0">
			<option>
				<xsl:choose>
					<xsl:when test="$direction = '-'">
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




	<!--
	Extend $default XML with $input XML. See bellow for usages of extMode attribute.


	Default:

	<root>
	    <L_1 id="elem_1_1" value="val_1_1">
			<L_2 name="elem_2_1" value="val_2_1">txt_2_1</L_2>
			<L_2 name="elem_2_2" value="val_2_2">txt_2_2</L_2>txt_1_1</L_1>

		<L_1 id="elem_1_2" value="val_1_2">
			<L_2 name="elem_2_1" value="val_2_1">txt_2_1</L_2>
			<L_2 name="elem_2_2" value="val_2_2">txt_2_2</L_2>txt_1_2</L_1>

		<L_1 id="elem_1_3" value="val_1_3">
			<L_2 name="elem_2_1" value="val_2_1">txt_2_1</L_2>
			<L_2 name="elem_2_2" value="val_2_2">txt_2_2</L_2>txt_1_3</L_1>

		<L_1 id="elem_1_4" value="val_1_4">
			<L_2 name="elem_2_1" value="val_2_1">txt_2_1</L_2>
			<L_2 name="elem_2_2" value="val_2_2">txt_2_2</L_2>txt_1_4</L_1>

		<L_1 id="elem_1_5" value="val_1_5">
			<L_2 name="elem_2_1" value="val_2_1">txt_2_1</L_2>
			<L_2 name="elem_2_2" value="val_2_2">txt_2_2</L_2>txt_1_5</L_1>
	</root>


	Input:

	<root>
	    <!** update elem_1_1 and the two child elements respectively **>
		<L_1 id="elem_1_1" value="oval_1_1" extMode="update">
			<L_2 name="elem_2_1" value="oval_2_1">otxt_2_1</L_2>
			<L_2 name="elem_2_2" value="oval_2_2">otxt_2_2</L_2>otxt_1</L_1>

		<!** update elem_1_2, since it has no children **>
		<L_1 id="elem_1_2" value="oval_1_2">otxt_2</L_1>

		<!** update children of elem_1_3 but not the element itself, since the extMode is not specified **>
		<L_1 id="elem_1_3" value="oval_1_3(ignored)">
			<L_2 name="elem_2_1" value="oval_2_1"/>
			<L_2 name="elem_2_2" value="oval_2_2"/>
			<L_2 name="elem_2_3" value="oval_2_3"/>otxt_3</L_1>

		<!** delete elem_1_4 **>
		<L_1 id="elem_1_4" extMode="delete"/>

		<!** replace elem_1_5 with the following element **>
		<L_1 id="elem_1_5" value="oval_1_2" extMode="replace">
			<L_2 name="elem_2_1" value="oval_2_1"/>otxt_5</L_1>
	</root>

	-->
	<xsl:template name="sform:extend">
		<xsl:param name="def"/>
		<xsl:param name="in"/>

		<xsl:variable name="default" select="exsl:node-set($def)"/>
		<xsl:variable name="input" select="exsl:node-set($in)"/>

		<xsl:for-each select="$default/*">
			<xsl:variable name="key" select="@*[1]"/>
			<xsl:variable name="inp" select="$input/*[local-name() = local-name(current()) and (not($key) or @*[1] = $key)]"/>

			<xsl:if test="count($inp) = 0">
				<xsl:copy-of select="."/>
			</xsl:if>

			<xsl:if test="count($inp) = 1 and (not($inp/@extMode) or $inp/@extMode != 'delete')">
				<xsl:choose>
					<xsl:when test="count($inp/*) = 0 or $inp/@extMode = 'update' or $inp/@extMode = 'replace'">
						<xsl:variable name="current" select="."/>

						<xsl:for-each select="$inp">
							<xsl:copy>
								<xsl:for-each select="@*[name() != 'extMode'] | text()[string-length(normalize-space(.))>0]">
									<xsl:copy/>
								</xsl:for-each>
								<xsl:choose>
									<xsl:when test="$inp/@extMode = 'replace'">
										<xsl:copy-of select="*"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:call-template name="sform:extend">
											<xsl:with-param name="def" select="$current"/>
											<xsl:with-param name="in" select="."/>
										</xsl:call-template>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:copy>
						</xsl:for-each>
					</xsl:when>
					<xsl:otherwise>
						<xsl:copy>
							<xsl:for-each select="@*|text()[string-length(normalize-space(.))>0]">
								<xsl:copy/>
							</xsl:for-each>
							<xsl:call-template name="xcms.extend">
								<xsl:with-param name="def" select="."/>
								<xsl:with-param name="in" select="$inp"/>
							</xsl:call-template>
						</xsl:copy>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:if>
		</xsl:for-each>

		<xsl:for-each select="$input/*">
			<xsl:variable name="key" select="@*[1]"/>

			<xsl:if test="count($default/*[local-name() = local-name(current()) and (not($key) or @*[1] = $key)]) = 0">
				<xsl:copy-of select="."/>
			</xsl:if>
		</xsl:for-each>
	</xsl:template>




</xsl:stylesheet>
