<?xml version="1.0" encoding="utf-8"?>

<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="xml" indent="yes" omit-xml-declaration="yes"/>
  
	<!--Identity template-->
	<xsl:template match="@*|node()">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()"/>
		</xsl:copy>
	</xsl:template>
	
	<!--Замена узлов 'Template' на 'Item'-->
	<xsl:template match="Template">
	  <xsl:variable name="context" select="@key" />
		<Item>
			<xsl:apply-templates select="@*|node()"/>
			<xsl:value-of select="$context"/>
		</Item>
	</xsl:template>

</xsl:stylesheet>