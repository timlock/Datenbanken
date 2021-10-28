<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY rs 'http://www.informatik.uni-oldenburg.de/2006/EER-Designer/RelationalSchema'>
    <!ENTITY func 'http://www.informatik.uni-oldenburg.de/2006/EER-Designer/XSLT-Functions'>
    <!ENTITY newline '&#x000A;'>
    <!ENTITY indent '    '>
]>
<!--
    Das Stylesheet generiert SQL-Befehle für Microsoft SQL Server 2000.
-->
<xsl:stylesheet xmlns:rs="&rs;" xmlns:func="&func;"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:saxon="http://saxon.sf.net/" xmlns:math="http://exslt.org/math"
    xpath-default-namespace="&rs;" extension-element-prefixes="saxon math"
    exclude-result-prefixes="rs func xs" version="2.0">
    <!-- INCLUDES -->
    <xsl:include href="Relational2SQL-Server-2005.xsl"/>
    <!-- TEMPLATES -->
    <xsl:template match="datatype[@name = 'char' and not(xs:boolean(parameter[@name =
        'national']/@value))]" priority="1.2">
        <xsl:choose>
            <xsl:when test="xs:integer(parameter[@name = 'length']/@value) &lt;= 8000">
                <xsl:text>CHAR(</xsl:text>
                <xsl:value-of select="max((1, xs:integer(parameter[@name = 'length']/@value)))"/>
                <xsl:text>)</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>TEXT</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="datatype[@name = 'char' and xs:boolean(parameter[@name =
        'national']/@value)]" priority="1.2">
        <xsl:choose>
            <xsl:when test="xs:integer(parameter[@name = 'length']/@value) &lt;= 4000">
                <xsl:text>NCHAR(</xsl:text>
                <xsl:value-of select="max((1, xs:integer(parameter[@name = 'length']/@value)))"/>
                <xsl:text>)</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>NTEXT</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="datatype[@name = 'varchar' and not(xs:boolean(parameter[@name =
        'national']/@value))]" priority="1.2">
        <xsl:choose>
            <xsl:when test="xs:integer(parameter[@name = 'length']/@value) &lt;= 8000">
                <xsl:text>VARCHAR(</xsl:text>
                <xsl:value-of select="max((1, xs:integer(parameter[@name = 'length']/@value)))"/>
                <xsl:text>)</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>TEXT</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="datatype[@name = 'varchar' and xs:boolean(parameter[@name =
        'national']/@value)]" priority="1.2">
        <xsl:choose>
            <xsl:when test="xs:integer(parameter[@name = 'length']/@value) &lt;= 8000">
                <xsl:text>NVARCHAR(</xsl:text>
                <xsl:value-of select="max((1, xs:integer(parameter[@name = 'length']/@value)))"/>
                <xsl:text>)</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>NTEXT</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="datatype[@name = 'binary']" priority="1.2">
        <xsl:choose>
            <xsl:when test="xs:integer(parameter[@name = 'length']/@value) &lt;= 8000">
                <xsl:text>VARBINARY(</xsl:text>
                <xsl:value-of select="max((1, xs:integer(parameter[@name = 'length']/@value)))"/>
                <xsl:text>)</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>IMAGE</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="foreignKey/@onDelete" priority="1.2">
        <xsl:text>ON DELETE </xsl:text>
        <xsl:choose>
            <xsl:when test=". = 'restrict'">
                <xsl:text>NO ACTION</xsl:text>
            </xsl:when>
            <xsl:when test=". = 'noAction'">
                <xsl:text>NO ACTION</xsl:text>
            </xsl:when>
            <xsl:when test=". = 'cascade'">
                <xsl:text>CASCADE</xsl:text>
            </xsl:when>
            <xsl:when test=". = 'setNull'">
                <xsl:text>NO ACTION</xsl:text>
            </xsl:when>
            <xsl:when test=". = 'setDefault'">
                <xsl:text>NO ACTION</xsl:text>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="foreignKey/@onUpdate" priority="1.2">
        <xsl:text>ON UPDATE </xsl:text>
        <xsl:choose>
            <xsl:when test=". = 'restrict'">
                <xsl:text>NO ACTION</xsl:text>
            </xsl:when>
            <xsl:when test=". = 'noAction'">
                <xsl:text>NO ACTION</xsl:text>
            </xsl:when>
            <xsl:when test=". = 'cascade'">
                <xsl:text>CASCADE</xsl:text>
            </xsl:when>
            <xsl:when test=". = 'setNull'">
                <xsl:text>NO ACTION</xsl:text>
            </xsl:when>
            <xsl:when test=". = 'setDefault'">
                <xsl:text>NO ACTION</xsl:text>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
</xsl:stylesheet>
