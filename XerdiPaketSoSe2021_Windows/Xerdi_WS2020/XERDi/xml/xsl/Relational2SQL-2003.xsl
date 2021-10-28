<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY rs 'http://www.informatik.uni-oldenburg.de/2006/EER-Designer/RelationalSchema'>
    <!ENTITY func 'http://www.informatik.uni-oldenburg.de/2006/EER-Designer/XSLT-Functions'>
    <!ENTITY newline '&#x000A;'>
    <!ENTITY indent '    '>
]>
<!--
    Das Stylesheet generiert SQL-Befehle, deren Syntax der Grammatik von SQL:2003 folgt.
-->
<xsl:stylesheet xmlns:rs="&rs;" xmlns:func="&func;"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:saxon="http://saxon.sf.net/" xpath-default-namespace="&rs;"
    extension-element-prefixes="saxon" exclude-result-prefixes="rs func xs" version="2.0">
    <!-- INCLUDES -->
    <xsl:include href="Relational2SQL-1999.xsl"/>
    <!-- TEMPLATES -->
    <xsl:template match="body" priority="1.1">
        <xsl:apply-templates select="(relation, relation/constraints/foreignKey)"/>
    </xsl:template>
    <xsl:template match="autoNumber" priority="1.1">
        <xsl:text>GENERATED ALWAYS AS IDENTITY (</xsl:text>
        <xsl:text>START WITH </xsl:text>
        <xsl:value-of select="@startValue"/>
        <xsl:text> INCREMENT BY </xsl:text>
        <xsl:value-of select="@increment"/>
        <xsl:text>)</xsl:text>
    </xsl:template>
</xsl:stylesheet>