<?xml version="1.0" encoding="utf-8"?>

<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="xml" indent="yes" omit-xml-declaration="yes"/>
  		
	<xsl:template name="tokenize">
		<xsl:param name="text"/>
		<xsl:param name="delimiter" select="','"/>
		<xsl:variable name="token" select="substring-before(concat($text, $delimiter), $delimiter)" />
			<xsl:if test="$token and not(contains($token, '-'))">
				<Item key="{$token}"/>
			</xsl:if>
			
			<!--enumerate-->
			<xsl:if test="contains($token, '-')">
				<xsl:call-template name="enumerate">
					<xsl:with-param name="start" select="substring($token, 1, 2)"/>
					<xsl:with-param name="end" select="substring($token, 4, 5)"/>
				</xsl:call-template>
			</xsl:if>
			<xsl:text>&#10;</xsl:text>
			
			<xsl:if test="contains($text, $delimiter)">
				<!-- recursive call -->
				<xsl:call-template name="tokenize">
					<xsl:with-param name="text" select="substring-after($text, $delimiter)"/>
				</xsl:call-template>				
			</xsl:if>
	</xsl:template>
	
	<xsl:template name="enumerate">
		<xsl:param name="start"/>
		<xsl:param name="end"/>
		<xsl:if test="$start">
			<Item key="{$start}"/>
		</xsl:if>
		<xsl:if test="$start &lt; $end">
			<xsl:text>&#10;</xsl:text>
			<xsl:call-template name="enumerate">
				<xsl:with-param name="start" select="format-number($start + 1,'00')"/>
				<xsl:with-param name="end" select="format-number($end,'00')"/>
			</xsl:call-template>
		</xsl:if>
	</xsl:template>
	
	<!--Замена узлов 'Template' на 'Item'-->
	<xsl:template match="Template">
			<xsl:call-template name="tokenize">
				<xsl:with-param name="text" select="@key"/>
			</xsl:call-template>	
	</xsl:template>	
	
	<!--Identity template-->
	<xsl:template match="@*|node()">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()"/>
		</xsl:copy>
	</xsl:template>
	
</xsl:stylesheet>