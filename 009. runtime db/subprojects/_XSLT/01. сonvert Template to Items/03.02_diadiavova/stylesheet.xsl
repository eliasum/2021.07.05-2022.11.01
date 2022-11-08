<?xml version="1.0" encoding="utf-8"?>
 
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output method="xml" indent="yes" omit-xml-declaration="yes"/>
 
    <!--Identity template-->
    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>
 
 
    <xsl:template name="enumerate">
        <xsl:param name="start"/>
        <xsl:param name="end"/>
        <xsl:param name="template"/>
        <Item key="{format-number($start,'00')}">
            <xsl:copy-of select="$template/@*[name() != 'key']"/>
            <xsl:apply-templates/>
        </Item>
        <xsl:if test="$start &lt; $end">
            <xsl:call-template name="enumerate">
                <xsl:with-param name="start" select="$start + 1"/>
                <xsl:with-param name="end" select="$end"/>
                <xsl:with-param name="template" select="$template"/>
            </xsl:call-template>
        </xsl:if>
 
    </xsl:template>
 
    <xsl:template name="tokenize">
        <xsl:param name="template"/>
        <xsl:param name="delimiter" select="','"/>
        <xsl:param name="text"/>
        <xsl:variable name="token">
            <xsl:choose>
                <xsl:when test="contains($text, $delimiter)">
                    <xsl:value-of select="substring-before($text, $delimiter)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$text"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="contains($token, '-')">
                <xsl:call-template name="enumerate">
                    <xsl:with-param name="start" select="number(substring-before($token, '-'))"/>
                    <xsl:with-param name="end" select="number(substring-after($token, '-'))"/>
                    <xsl:with-param name="template" select="$template"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <Item key="{$token}">
                    <xsl:copy-of select="$template/@*[name() != 'key']"/>
                    <xsl:apply-templates/>
                </Item>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:if test="contains($text, $delimiter)">
            <xsl:call-template name="tokenize">
                <xsl:with-param name="template" select="$template"/>
                <xsl:with-param name="text" select="substring-after($text, $delimiter)"/>
            </xsl:call-template>
        </xsl:if>
 
    </xsl:template>
 
    <xsl:template match="Template">
        <xsl:call-template name="tokenize">
            <xsl:with-param name="template" select="."/>
            <xsl:with-param name="text" select="./@key"/>
        </xsl:call-template>
    </xsl:template>
 
</xsl:stylesheet>