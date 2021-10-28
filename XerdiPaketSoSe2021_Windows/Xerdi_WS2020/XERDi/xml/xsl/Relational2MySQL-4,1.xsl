<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY rs 'http://www.informatik.uni-oldenburg.de/2006/EER-Designer/RelationalSchema'>
    <!ENTITY func 'http://www.informatik.uni-oldenburg.de/2006/EER-Designer/XSLT-Functions'>
    <!ENTITY newline '&#x000A;'>
    <!ENTITY indent '    '>
]>
<!--
    Das Stylesheet generiert SQL-Befehle für MySQL 4.1.
-->
<xsl:stylesheet xmlns:rs="&rs;" xmlns:func="&func;"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:saxon="http://saxon.sf.net/" xmlns:math="http://exslt.org/math"
    xpath-default-namespace="&rs;" extension-element-prefixes="saxon math"
    exclude-result-prefixes="rs func xs" version="2.0">
    <!-- INCLUDES -->
    <xsl:include href="Relational2MySQL-5,0.xsl"/>
    <!-- TEMPLATES -->
    <xsl:template match="foreignKey" priority="3.2">
        <xsl:next-match/>
        <xsl:text>,&newline;</xsl:text>
        <xsl:text>&indent;ADD INDEX (</xsl:text>
        <xsl:apply-templates select="attributeRef"/>
        <xsl:text>)</xsl:text>
    </xsl:template>
    <xsl:template match="datatype[@name = 'integer']" priority="1.2">
        <xsl:choose>
            <xsl:when test="xs:integer(parameter[@name = 'precision']/@value) &lt;= 8">
                <xsl:text>TINYINT</xsl:text>
            </xsl:when>
            <xsl:when test="xs:integer(parameter[@name = 'precision']/@value) &lt;= 16">
                <xsl:text>SMALLINT</xsl:text>
            </xsl:when>
            <xsl:when test="xs:integer(parameter[@name = 'precision']/@value) &lt;= 24">
                <xsl:text>MEDIUMINT</xsl:text>
            </xsl:when>
            <xsl:when test="xs:integer(parameter[@name = 'precision']/@value) &lt;= 32">
                <xsl:text>INT</xsl:text>
            </xsl:when>
            <xsl:when test="xs:integer(parameter[@name = 'precision']/@value) &lt;= 64">
                <xsl:text>BIGINT</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>DECIMAL(</xsl:text>
                <xsl:value-of select="max((1, min((254, ceiling(math:log(math:power(2,
                    parameter[@name = 'precision']/@value - 1)) div math:log(10))))))"/>
                <xsl:text>)</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="datatype[@name = 'decimal']" priority="1.2">
        <xsl:text>DECIMAL(</xsl:text>
        <xsl:value-of select="max((1, min((253, xs:integer(parameter[@name =
            'totalDigits']/@value)))))"/>
        <xsl:text>,</xsl:text>
        <xsl:value-of select="max((0, min((30, min((xs:integer(parameter[@name =
            'totalDigits']/@value) - 1, xs:integer(parameter[@name =
            'fractionDigits']/@value)))))))"/>
        <xsl:text>)</xsl:text>
    </xsl:template>
    <xsl:template match="datatype[@name = 'binary']" priority="1.2">
        <xsl:choose>
            <xsl:when test="xs:integer(parameter[@name = 'size']/@value) &lt;= 65535">
                <xsl:text>BLOB</xsl:text>
            </xsl:when>
            <xsl:when test="xs:integer(parameter[@name = 'size']/@value) &lt;= 16777215">
                <xsl:text>MEDIUMBLOB</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>LONGBLOB</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
</xsl:stylesheet>
