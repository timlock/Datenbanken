<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY rs 'http://www.informatik.uni-oldenburg.de/2006/EER-Designer/RelationalSchema'>
    <!ENTITY func 'http://www.informatik.uni-oldenburg.de/2006/EER-Designer/XSLT-Functions'>
    <!ENTITY newline '&#x000A;'>
    <!ENTITY indent '    '>
]>
<!--
    Das Stylesheet generiert SQL-Befehle für MySQL 5.0.
-->
<xsl:stylesheet xmlns:rs="&rs;" xmlns:func="&func;"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:saxon="http://saxon.sf.net/" xmlns:math="http://exslt.org/math"
    xpath-default-namespace="&rs;" extension-element-prefixes="saxon math"
    exclude-result-prefixes="rs func xs" version="2.0">
    <!-- OUTPUT -->
    <xsl:output method="text" use-character-maps="MySQL"/>
    <xsl:character-map name="MySQL">
        <xsl:output-character character="&quot;" string="&#x0060;"/>
    </xsl:character-map>
    <!-- INCLUDES -->
    <xsl:include href="Relational2SQL-1999.xsl"/>
    <!-- TEMPLATES -->
    <xsl:template match="body" priority="1.1">
        <xsl:apply-templates select="(relation, relation/constraints/foreignKey)"/>
        <xsl:if test="exists(//restrictions/minimum | //restrictions/maximum |
            //restrictions/pattern | //restrictions/enumeration)">
            <xsl:text>&newline;&newline;</xsl:text>
            <xsl:text>-- There were some check constraints created. Unfortunately check constraints are ignored by this version of MySQL.</xsl:text>
        </xsl:if>
    </xsl:template>
    <xsl:template match="relation" priority="3.1">
        <xsl:next-match/>
        <xsl:text> ENGINE = InnoDB</xsl:text>
        <xsl:apply-templates select="//autoNumber[1][@startValue &gt; 1]" mode="asTableOption"/>
        <xsl:apply-templates select="comment"/>
    </xsl:template>
    <xsl:template match="attribute" priority="1.1">
        <xsl:apply-templates select="name"/>
        <xsl:apply-templates select="domain/datatype"/>
        <xsl:apply-templates select="default | autoNumber"/>
        <xsl:apply-templates select="comment"/>
        <xsl:apply-templates select="domain/restrictions"/>
    </xsl:template>
    <xsl:template match="datatype[@name = 'char' or @name = 'varchar']" priority="1.1">
        <xsl:choose>
            <xsl:when test="xs:integer(parameter[@name = 'length']/@value) &lt;= 255">
                <xsl:if test="xs:boolean(parameter[@name = 'national']/@value)">
                    <xsl:text>N</xsl:text>
                </xsl:if>
                <xsl:text>CHAR</xsl:text>
                <xsl:if test="@name = 'varchar'">
                    <xsl:text> VARYING</xsl:text>
                </xsl:if>
                <xsl:text>(</xsl:text>
                <xsl:value-of select="max((0, xs:integer(parameter[@name = 'length']/@value)))"/>
                <xsl:text>)</xsl:text>
            </xsl:when>
            <xsl:when test="xs:integer(parameter[@name = 'length']/@value) &lt;= 65535">
                <xsl:text>TEXT</xsl:text>
            </xsl:when>
            <xsl:when test="xs:integer(parameter[@name = 'length']/@value) &lt;= 16777215">
                <xsl:text>MEDIUMTEXT</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>LONGTEXT</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="datatype[@name = 'integer']" priority="1.1">
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
                <xsl:value-of select="max((1, min((64, ceiling(math:log(math:power(2,
                    parameter[@name = 'precision']/@value - 1)) div math:log(10))))))"/>
                <xsl:text>)</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="datatype[@name = 'decimal']" priority="1.1">
        <xsl:text>DECIMAL(</xsl:text>
        <xsl:value-of select="max((1, min((64, xs:integer(parameter[@name =
            'totalDigits']/@value)))))"/>
        <xsl:text>,</xsl:text>
        <xsl:value-of select="max((0, min((30, min((xs:integer(parameter[@name =
            'totalDigits']/@value) - 1, xs:integer(parameter[@name =
            'fractionDigits']/@value)))))))"/>
        <xsl:text>)</xsl:text>
    </xsl:template>
    <xsl:template match="datatype[@name = 'float']" priority="1.1">
        <xsl:choose>
            <xsl:when test="xs:integer(parameter[@name = 'precision']/@value) &lt;= 24">
                <xsl:text>FLOAT</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>DOUBLE</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="datatype[@name = 'date']" priority="1.1">
        <xsl:text>DATE</xsl:text>
    </xsl:template>
    <xsl:template match="datatype[@name = 'time']" priority="1.1">
        <xsl:text>TIME</xsl:text>
    </xsl:template>
    <xsl:template match="datatype[@name = 'timestamp']" priority="1.1">
        <xsl:text>DATETIME</xsl:text>
    </xsl:template>
    <xsl:template match="datatype[@name = 'yearMonthInterval']" priority="1.1">
        <xsl:text>INT</xsl:text>
    </xsl:template>
    <xsl:template match="datatype[@name = 'dayTimeInterval']" priority="1.1">
        <xsl:text>TIME</xsl:text>
    </xsl:template>
    <xsl:template match="datatype[@name = 'boolean']" priority="1.1">
        <xsl:text>BOOLEAN</xsl:text>
    </xsl:template>
    <xsl:template match="datatype[@name = 'binary']" priority="1.1">
        <xsl:choose>
            <xsl:when test="xs:integer(parameter[@name = 'size']/@value) &lt;= 255">
                <xsl:text>VARBINARY(</xsl:text>
                <xsl:value-of select="max((0, xs:integer(parameter[@name = 'size']/@value)))"/>
                <xsl:text>)</xsl:text>
            </xsl:when>
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
    <xsl:template match="autoNumber" priority="1.1">
        <xsl:text>AUTO_INCREMENT</xsl:text>
    </xsl:template>
    <xsl:template match="autoNumber" mode="asTableOption">
        <xsl:text> AUTO_INCREMENT = </xsl:text>
        <xsl:value-of select="@startValue"/>
    </xsl:template>
    <xsl:template match="foreignKey/@onDelete" priority="1.1">
        <xsl:text>ON DELETE </xsl:text>
        <xsl:choose>
            <xsl:when test=". = 'restrict'">
                <xsl:text>RESTRICT</xsl:text>
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
                <xsl:text>NO ACTION</xsl:text>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="foreignKey/@onUpdate" priority="1.1">
        <xsl:text>ON UPDATE </xsl:text>
        <xsl:choose>
            <xsl:when test=". = 'restrict'">
                <xsl:text>RESTRICT</xsl:text>
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
                <xsl:text>NO ACTION</xsl:text>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="comment" priority="2">
        <xsl:text> </xsl:text>
        <xsl:next-match/>
    </xsl:template>
    <xsl:template match="attribute/comment" priority="1">
        <xsl:text>COMMENT </xsl:text>
        <xsl:call-template name="prepareLiteral">
            <xsl:with-param name="literal" select="text()"/>
        </xsl:call-template>
    </xsl:template>
    <xsl:template match="relation/comment" priority="1">
        <xsl:text>COMMENT = </xsl:text>
        <xsl:call-template name="prepareLiteral">
            <xsl:with-param name="literal" select="text()"/>
        </xsl:call-template>
    </xsl:template>
</xsl:stylesheet>
