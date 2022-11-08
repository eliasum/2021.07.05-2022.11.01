<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output method="xml" indent="yes" omit-xml-declaration="yes"/>
    
    <xsl:template match="Template">
        <xsl:call-template name="tokenize">
            <xsl:with-param name="text" select="concat(@key, ',')"/>
            <xsl:with-param name="delimiter" select="','"/>
        </xsl:call-template>    
    </xsl:template> 
    
    <!-- Skip process Template/@key -->
    <xsl:template match="Template/@key"/>
    
    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template name="tokenize">
        <xsl:param name="text"/>
        <xsl:param name="delimiter" select="','"/>
        <xsl:variable name="token" select="substring-before($text, $delimiter)" />
        <xsl:if test="$token != ''">
            <xsl:choose>
                <xsl:when test="contains($token, '-')">
                    <xsl:call-template name="enumerate">
                        <xsl:with-param name="start" select="substring-before($token, '-')"/>
                        <xsl:with-param name="end" select="substring-after($token, '-')"/>
                    </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:call-template name="enumerate">
                        <xsl:with-param name="start" select="$token"/>
                        <xsl:with-param name="end" select="$token"/>
                    </xsl:call-template>
                </xsl:otherwise>
            </xsl:choose>
            <!-- recursive call -->
            <xsl:call-template name="tokenize">
                <xsl:with-param name="text" select="substring-after($text, $delimiter)"/>
                <xsl:with-param name="delimiter" select="$delimiter"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="enumerate">
        <xsl:param name="start"/>
        <xsl:param name="end"/>
        <xsl:if test="$start &lt;= $end">
			<Item key="{number($start)}">
			  <!-- Copy attributes -->
			  <xsl:apply-templates select="@*"/>
			  <!-- Process childs -->
			  <xsl:apply-templates/>
			</Item>
            <xsl:call-template name="enumerate">
                <xsl:with-param name="start" select="$start + 1"/>
                <xsl:with-param name="end" select="$end"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>
</xsl:stylesheet>