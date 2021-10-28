<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY rs 'http://www.informatik.uni-oldenburg.de/2006/EER-Designer/RelationalSchema'>
    <!ENTITY func 'http://www.informatik.uni-oldenburg.de/2006/EER-Designer/XSLT-Functions'>
    <!ENTITY newline '&#x000A;'>
    <!ENTITY indent '    '>
]>
<!--
    Das Stylesheet generiert SQL-Befehle für Microsoft SQL Server 2005.
-->
<xsl:stylesheet xmlns:rs="&rs;" xmlns:func="&func;"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:saxon="http://saxon.sf.net/" xmlns:math="http://exslt.org/math"
    xpath-default-namespace="&rs;" extension-element-prefixes="saxon math"
    exclude-result-prefixes="rs func xs" version="2.0">
    <!-- INCLUDES -->
    <xsl:include href="Relational2SQL-1999.xsl"/>
    <!-- TEMPLATES -->
    <xsl:template match="body" priority="1.1">
        <xsl:apply-templates select="(relation, relation/constraints/foreignKey)"/>
        <xsl:if test="exists(//datatype[(@name = 'char' or @name = 'varchar') and
            not(xs:boolean(parameter[@name = 'national']/@value))])">
            <xsl:text>&newline;&newline;</xsl:text>
            <xsl:text>-- The length of character string columns are specified as the maximum number of bytes in the string.&newline;</xsl:text>
            <xsl:text>-- Depending on the character set this can differ from the number of characters.</xsl:text>
        </xsl:if>
    </xsl:template>
    <xsl:template match="datatype[@name = 'char' and not(xs:boolean(parameter[@name =
        'national']/@value))]" priority="1.1">
        <xsl:choose>
            <xsl:when test="xs:integer(parameter[@name = 'length']/@value) &lt;= 8000">
                <xsl:text>CHAR(</xsl:text>
                <xsl:value-of select="max((1, xs:integer(parameter[@name = 'length']/@value)))"/>
                <xsl:text>)</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>VARCHAR(MAX)</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="datatype[@name = 'char' and xs:boolean(parameter[@name =
        'national']/@value)]" priority="1.1">
        <xsl:choose>
            <xsl:when test="xs:integer(parameter[@name = 'length']/@value) &lt;= 4000">
                <xsl:text>NCHAR(</xsl:text>
                <xsl:value-of select="max((1, xs:integer(parameter[@name = 'length']/@value)))"/>
                <xsl:text>)</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>NVARCHAR(MAX)</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="datatype[@name = 'varchar' and not(xs:boolean(parameter[@name =
        'national']/@value))]" priority="1.1">
        <xsl:choose>
            <xsl:when test="xs:integer(parameter[@name = 'length']/@value) &lt;= 8000">
                <xsl:text>VARCHAR(</xsl:text>
                <xsl:value-of select="max((1, xs:integer(parameter[@name = 'length']/@value)))"/>
                <xsl:text>)</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>VARCHAR(MAX)</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="datatype[@name = 'varchar' and xs:boolean(parameter[@name =
        'national']/@value)]" priority="1.1">
        <xsl:choose>
            <xsl:when test="xs:integer(parameter[@name = 'length']/@value) &lt;= 8000">
                <xsl:text>NVARCHAR(</xsl:text>
                <xsl:value-of select="max((1, xs:integer(parameter[@name = 'length']/@value)))"/>
                <xsl:text>)</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>NVARCHAR(MAX)</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="datatype[@name = 'integer']" priority="1.1">
        <xsl:choose>
            <xsl:when test="xs:integer(parameter[@name = 'precision']/@value) &lt;= 16">
                <xsl:text>SMALLINT</xsl:text>
            </xsl:when>
            <xsl:when test="xs:integer(parameter[@name = 'precision']/@value) &lt;= 32">
                <xsl:text>INT</xsl:text>
            </xsl:when>
            <xsl:when test="xs:integer(parameter[@name = 'precision']/@value) &lt;= 64">
                <xsl:text>BIGINT</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>DECIMAL(</xsl:text>
                <xsl:value-of select="max((1, min((38, ceiling(math:log(math:power(2,
                    parameter[@name = 'precision']/@value - 1)) div math:log(10))))))"/>
                <xsl:text>)</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="datatype[@name = 'decimal']" priority="1.1">
        <xsl:text>DECIMAL(</xsl:text>
        <xsl:value-of select="max((1, min((38, xs:integer(parameter[@name =
            'totalDigits']/@value)))))"/>
        <xsl:text>,</xsl:text>
        <xsl:value-of select="max((0, min((38, min((xs:integer(parameter[@name =
            'totalDigits']/@value), xs:integer(parameter[@name = 'fractionDigits']/@value)))))))"/>
        <xsl:text>)</xsl:text>
    </xsl:template>
    <xsl:template match="datatype[@name = 'float']" priority="1.1">
        <xsl:choose>
            <xsl:when test="xs:integer(parameter[@name = 'precision']/@value) &lt;= 24">
                <xsl:text>REAL</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>DOUBLE</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="datatype[@name = 'date']" priority="1.1">
        <xsl:text>SMALLDATETIME</xsl:text>
    </xsl:template>
    <xsl:template match="datatype[@name = 'time']" priority="1.1">
        <xsl:text>DATETIME</xsl:text>
    </xsl:template>
    <xsl:template match="datatype[@name = 'timestamp']" priority="1.1">
        <xsl:text>DATETIME</xsl:text>
    </xsl:template>
    <xsl:template match="datatype[@name = 'yearMonthInterval']" priority="1.1">
        <xsl:text>INT</xsl:text>
    </xsl:template>
    <xsl:template match="datatype[@name = 'dayTimeInterval']" priority="1.1">
        <xsl:text>INT</xsl:text>
    </xsl:template>
    <xsl:template match="datatype[@name = 'boolean']" priority="1.1">
        <xsl:text>BIT</xsl:text>
    </xsl:template>
    <xsl:template match="datatype[@name = 'binary']" priority="1.1">
        <xsl:text>VARBINARY(</xsl:text>
        <xsl:choose>
            <xsl:when test="xs:integer(parameter[@name = 'length']/@value) &lt;= 8000">
                <xsl:value-of select="max((1, xs:integer(parameter[@name = 'length']/@value)))"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>MAX</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:text>)</xsl:text>
    </xsl:template>
    <xsl:template match="autoNumber" priority="1.1">
        <xsl:text>IDENTITY(</xsl:text>
        <xsl:value-of select="@startValue"/>
        <xsl:text>,</xsl:text>
        <xsl:value-of select="@increment"/>
        <xsl:text>)</xsl:text>
    </xsl:template>
    <xsl:template match="foreignKey/@onDelete" priority="1.1">
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
                <xsl:text>SET NULL</xsl:text>
            </xsl:when>
            <xsl:when test=". = 'setDefault'">
                <xsl:text>SET DEFAULT</xsl:text>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="foreignKey/@onUpdate" priority="1.1">
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
                <xsl:text>SET NULL</xsl:text>
            </xsl:when>
            <xsl:when test=". = 'setDefault'">
                <xsl:text>SET DEFAULT</xsl:text>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
</xsl:stylesheet>
