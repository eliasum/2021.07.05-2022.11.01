<xsl:stylesheet version="1.0" 
xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>
<xsl:strip-space elements="*"/>

<xsl:template match="node()">
    <xsl:copy>
        <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
</xsl:template>

<xsl:template match="@*">
    <xsl:attribute name="{name()}">
        <xsl:call-template name="expand">
            <xsl:with-param name="text" select="."/>
        </xsl:call-template>
    </xsl:attribute>
</xsl:template>

<xsl:template name="expand">
    <xsl:param name="text"/>
    <xsl:choose>
        <xsl:when test="contains($text, '{') ">
            <!-- text before reference -->
            <xsl:value-of select="substring-before($text, '{')"/>
            <!-- recursive call with the expanded refeence-->
            <xsl:variable name="name" select="substring-before(substring-after($text, '{@'), '}')" />
            <xsl:call-template name="expand">
                <xsl:with-param name="text" select="../@*[name()=$name]"/>
            </xsl:call-template>            
            <!-- recursive call with rest of the text -->
            <xsl:call-template name="expand">
                <xsl:with-param name="text" select="substring-after($text, '}')"/>
            </xsl:call-template>            
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="$text"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

</xsl:stylesheet>