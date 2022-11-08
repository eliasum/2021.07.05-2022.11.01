<!--
Change the order of
<xsl:apply-templates select="@*"/>
<xsl:variable name="name" select="name()"/>
<xsl:apply-templates select="$dictionary//*[name(.) = $name and 
										  name(.)!= 'Item' and 
										  name(.)!= 'Template' and
										  name(.)!= 'Minimum' and
										  name(.)!= 'Maximum']/@*"/>
to
-->
<xsl:variable name="name" select="name()"/>
<xsl:apply-templates select="$dictionary//*[name(.) = $name and 
										  name(.)!= 'Item' and 
										  name(.)!= 'Template' and
										  name(.)!= 'Minimum' and
										  name(.)!= 'Maximum']/@*"/>
<xsl:apply-templates select="@*"/>
<!--
that way the attributes from the input document "win" as they are
copied last.
-->

2022.04.15 10:33 IMM