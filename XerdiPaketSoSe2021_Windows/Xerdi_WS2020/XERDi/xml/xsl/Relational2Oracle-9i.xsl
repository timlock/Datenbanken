<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY rs 'http://www.informatik.uni-oldenburg.de/2006/EER-Designer/RelationalSchema'>
    <!ENTITY func 'http://www.informatik.uni-oldenburg.de/2006/EER-Designer/XSLT-Functions'>
    <!ENTITY newline '&#x000A;'>
    <!ENTITY indent '    '>
]>
<!--
    Das Stylesheet generiert SQL-Befehle für Oracle 9i.
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
    </xsl:template>
    <xsl:template match="relation" priority="4.1">
        <xsl:next-match/>
        <xsl:apply-templates select="attributes/attribute/autoNumber" mode="asSequenceAndTrigger"/>
        <xsl:apply-templates select="(comment, attributes/attribute/comment)"/>
    </xsl:template>
    <xsl:template match="datatype[@name = 'char']" priority="1.1">
        <xsl:if test="xs:boolean(parameter[@name = 'national']/@value)">
            <xsl:text>N</xsl:text>
        </xsl:if>
        <xsl:choose>
            <xsl:when test="xs:integer(parameter[@name = 'length']/@value) &lt;= 1000">
                <xsl:text>CHAR(</xsl:text>
                <xsl:value-of select="max((1, xs:integer(parameter[@name = 'length']/@value)))"/>
                <xsl:text> CHAR)</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>CLOB</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="datatype[@name = 'varchar']" priority="1.1">
        <xsl:if test="xs:boolean(parameter[@name = 'national']/@value)">
            <xsl:text>N</xsl:text>
        </xsl:if>
        <xsl:choose>
            <xsl:when test="xs:integer(parameter[@name = 'length']/@value) &lt;= 2000">
                <xsl:text>VARCHAR2(</xsl:text>
                <xsl:value-of select="max((1, xs:integer(parameter[@name = 'length']/@value)))"/>
                <xsl:text> CHAR)</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>CLOB</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="datatype[@name = 'integer']" priority="1.1">
        <xsl:text>NUMBER(</xsl:text>
        <xsl:value-of select="max((1, min((38, ceiling(math:log(math:power(2,
            parameter[@name = 'precision']/@value - 1)) div math:log(10))))))"/>
        <xsl:text>)</xsl:text>
    </xsl:template>
    <xsl:template match="datatype[@name = 'decimal']" priority="1.1">
        <xsl:text>NUMBER(</xsl:text>
        <xsl:value-of select="max((1, min((38, xs:integer(parameter[@name =
            'totalDigits']/@value)))))"/>
        <xsl:text>,</xsl:text>
        <xsl:value-of select="max((-84, min((127, xs:integer(parameter[@name =
            'fractionDigits']/@value)))))"/>
        <xsl:text>)</xsl:text>
    </xsl:template>
    <xsl:template match="datatype[@name = 'float']" priority="1.1">
        <xsl:text>FLOAT(</xsl:text>
        <xsl:value-of select="max((1, min((126, xs:integer(parameter[@name =
            'precision']/@value)))))"/>
        <xsl:text>)</xsl:text>
    </xsl:template>
    <xsl:template match="datatype[@name = 'date']" priority="1.1">
        <xsl:text>DATE</xsl:text>
    </xsl:template>
    <xsl:template match="datatype[@name = 'time']" priority="1.1">
        <xsl:text>TIMESTAMP(</xsl:text>
        <xsl:value-of select="max((0, min((9, xs:integer(parameter[@name =
            'fractionDigits']/@value)))))"/>
        <xsl:text>)</xsl:text>
        <xsl:if test="xs:boolean(parameter[@name = 'withTimezone']/@value)">
            <xsl:text> WITH TIME ZONE</xsl:text>
        </xsl:if>
    </xsl:template>
    <xsl:template match="datatype[@name = 'timestamp']" priority="1.1">
        <xsl:text>TIMESTAMP(</xsl:text>
        <xsl:value-of select="max((0, min((9, xs:integer(parameter[@name =
            'fractionDigits']/@value)))))"/>
        <xsl:text>)</xsl:text>
        <xsl:if test="xs:boolean(parameter[@name = 'withTimezone']/@value)">
            <xsl:text> WITH TIME ZONE</xsl:text>
        </xsl:if>
    </xsl:template>
    <xsl:template match="datatype[@name = 'yearMonthInterval']" priority="1.1">
        <xsl:text>INTERVAL YEAR TO MONTH</xsl:text>
    </xsl:template>
    <xsl:template match="datatype[@name = 'dayTimeInterval']" priority="1.1">
        <xsl:text>INTERVAL DAY TO SECOND(</xsl:text>
        <xsl:value-of select="max((0, min((9, xs:integer(parameter[@name =
            'fractionDigits']/@value)))))"/>
        <xsl:text>)</xsl:text>
    </xsl:template>
    <xsl:template match="datatype[@name = 'boolean']" priority="1.1">
        <xsl:text>NUMBER(1)</xsl:text>
    </xsl:template>
    <xsl:template match="datatype[@name = 'binary']" priority="1.1">
        <xsl:choose>
            <xsl:when test="xs:integer(parameter[@name = 'size']/@value) &lt;= 2000">
                <xsl:text>RAW(</xsl:text>
                <xsl:value-of select="max((1, xs:integer(parameter[@name = 'size']/@value)))"/>
                <xsl:text>)</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>BLOB</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="autoNumber" priority="1.1">
        <!-- Auto-Keys werden über Sequenzen und Trigger nachgebildet -->
    </xsl:template>
    <xsl:template match="autoNumber" mode="asSequenceAndTrigger">
        <xsl:text>&newline;&newline;</xsl:text>
        <xsl:text>-- Create an auto key generator for column </xsl:text>
        <xsl:apply-templates select="../name"/>
        <xsl:text>&newline;</xsl:text>
        <xsl:text>CREATE SEQUENCE </xsl:text>
        <xsl:call-template name="prepareIdentifier">
            <xsl:with-param name="identifier" select="concat(../../../name, '_Sequence')"/>
        </xsl:call-template>
        <xsl:text> START WITH </xsl:text>
        <xsl:value-of select="@startValue"/>
        <xsl:text> INCREMENT BY </xsl:text>
        <xsl:value-of select="@increment"/>
        <xsl:text>;&newline;</xsl:text>
        <xsl:text>CREATE TRIGGER </xsl:text>
        <xsl:call-template name="prepareIdentifier">
            <xsl:with-param name="identifier" select="concat(../../../name, '_Trigger')"/>
        </xsl:call-template>
        <xsl:text> BEFORE INSERT ON </xsl:text>
        <xsl:apply-templates select="../../../name"/>
        <xsl:text> FOR EACH ROW&newline;</xsl:text>
        <xsl:text>BEGIN&newline;</xsl:text>
        <xsl:text>&indent;SELECT </xsl:text>
        <xsl:call-template name="prepareIdentifier">
            <xsl:with-param name="identifier" select="concat(../../../name, '_Sequence')"/>
        </xsl:call-template>
        <xsl:text>.NEXTVAL INTO :new.</xsl:text>
        <xsl:apply-templates select="../name"/>
        <xsl:text> FROM DUAL;&newline;</xsl:text>
        <xsl:text>END;&newline;</xsl:text>
        <xsl:text>/</xsl:text>
    </xsl:template>
    <xsl:template match="foreignKey/@onDelete" priority="1.1">
        <xsl:choose>
            <xsl:when test=". = 'restrict'">
                <xsl:text/>
            </xsl:when>
            <xsl:when test=". = 'noAction'">
                <xsl:text/>
            </xsl:when>
            <xsl:when test=". = 'cascade'">
                <xsl:text>ON DELETE CASCADE</xsl:text>
            </xsl:when>
            <xsl:when test=". = 'setNull'">
                <xsl:text>ON DELETE SET NULL</xsl:text>
            </xsl:when>
            <xsl:when test=". = 'setDefault'">
                <xsl:text/>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="foreignKey/@onUpdate" priority="2.1">
        <!-- ON UPDATE gibt es bei Oracle 9i nicht -->
    </xsl:template>
    <xsl:template match="comment" priority="2">
        <xsl:if test="position() = 1">
            <xsl:text>&newline;</xsl:text>
        </xsl:if>
        <xsl:text>&newline;</xsl:text>
        <xsl:next-match/>
        <xsl:text>;</xsl:text>
    </xsl:template>
    <xsl:template match="relation/comment" priority="1">
        <xsl:text>COMMENT ON TABLE </xsl:text>
        <xsl:apply-templates select="../name"/>
        <xsl:text> IS </xsl:text>
        <xsl:call-template name="prepareLiteral">
            <xsl:with-param name="literal" select="text()"/>
        </xsl:call-template>
    </xsl:template>
    <xsl:template match="attribute/comment" priority="1">
        <xsl:text>COMMENT ON COLUMN </xsl:text>
        <xsl:apply-templates select="../../../name"/>
        <xsl:text>.</xsl:text>
        <xsl:apply-templates select="../name"/>
        <xsl:text> IS </xsl:text>
        <xsl:call-template name="prepareLiteral">
            <xsl:with-param name="literal" select="text()"/>
        </xsl:call-template>
    </xsl:template>
</xsl:stylesheet>
