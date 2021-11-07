<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY rs 'http://www.informatik.uni-oldenburg.de/2006/EER-Designer/RelationalSchema'>
    <!ENTITY func 'http://www.informatik.uni-oldenburg.de/2006/EER-Designer/XSLT-Functions'>
    <!ENTITY newline '&#x000A;'>
    <!ENTITY indent '    '>
]>
<!--
    Das Stylesheet generiert SQL-Befehle für IBM DB2 UDB for LUW 8.
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
    <xsl:template match="relation" priority="4.1">
        <xsl:next-match/>
        <xsl:apply-templates select="(comment, attributes/attribute/comment)"/>
    </xsl:template>
    <xsl:template match="datatype[@name = 'char' and not(xs:boolean(parameter[@name =
        'national']/@value))]" priority="1.1">
        <xsl:choose>
            <xsl:when test="xs:integer(parameter[@name = 'length']/@value) &lt;= 254">
                <xsl:text>CHAR(</xsl:text>
                <xsl:value-of select="max((1, xs:integer(parameter[@name = 'length']/@value)))"/>
                <xsl:text>)</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>CLOB(</xsl:text>
                <xsl:value-of select="min((2147483647, xs:integer(parameter[@name =
                    'length']/@value)))"/>
                <xsl:text>)</xsl:text>
                <xsl:if test="xs:integer(parameter[@name = 'length']/@value) &gt; 1073741824">
                    <xsl:text> NOT LOGGED</xsl:text>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="datatype[@name = 'char' and xs:boolean(parameter[@name =
        'national']/@value)]" priority="1.1">
        <xsl:choose>
            <xsl:when test="xs:integer(parameter[@name = 'length']/@value) &lt;= 127">
                <xsl:text>GRAPHIC(</xsl:text>
                <xsl:value-of select="max((1, xs:integer(parameter[@name = 'length']/@value)))"/>
                <xsl:text>)</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>DBCLOB(</xsl:text>
                <xsl:value-of select="min((1073741823, xs:integer(parameter[@name =
                    'length']/@value)))"/>
                <xsl:text>)</xsl:text>
                <xsl:if test="xs:integer(parameter[@name = 'length']/@value) &gt; 536870912">
                    <xsl:text> NOT LOGGED</xsl:text>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="datatype[@name = 'varchar' and not(xs:boolean(parameter[@name =
        'national']/@value))]" priority="1.1">
        <xsl:choose>
            <xsl:when test="xs:integer(parameter[@name = 'length']/@value) &lt;= 32672">
                <xsl:text>VARCHAR(</xsl:text>
                <xsl:value-of select="max((1, xs:integer(parameter[@name = 'length']/@value)))"/>
                <xsl:text>)</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>CLOB(</xsl:text>
                <xsl:value-of select="min((2147483647, xs:integer(parameter[@name =
                    'length']/@value)))"/>
                <xsl:text>)</xsl:text>
                <xsl:if test="xs:integer(parameter[@name = 'length']/@value) &gt; 1073741824">
                    <xsl:text> NOT LOGGED</xsl:text>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="datatype[@name = 'varchar' and xs:boolean(parameter[@name =
        'national']/@value)]" priority="1.1">
        <xsl:choose>
            <xsl:when test="xs:integer(parameter[@name = 'length']/@value) &lt;= 16336">
                <xsl:text>VARGRAPHIC(</xsl:text>
                <xsl:value-of select="max((1, xs:integer(parameter[@name = 'length']/@value)))"/>
                <xsl:text>)</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>DBCLOB(</xsl:text>
                <xsl:value-of select="min((1073741823, xs:integer(parameter[@name =
                    'length']/@value)))"/>
                <xsl:text>)</xsl:text>
                <xsl:if test="xs:integer(parameter[@name = 'length']/@value) &gt; 536870912">
                    <xsl:text> NOT LOGGED</xsl:text>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="datatype[@name = 'integer']" priority="1.1">
        <xsl:choose>
            <xsl:when test="xs:integer(parameter[@name = 'precision']/@value) &lt;= 16">
                <xsl:text>SMALLINT</xsl:text>
            </xsl:when>
            <xsl:when test="xs:integer(parameter[@name = 'precision']/@value) &lt;= 32">
                <xsl:text>INTEGER</xsl:text>
            </xsl:when>
            <xsl:when test="xs:integer(parameter[@name = 'precision']/@value) &lt;= 64">
                <xsl:text>BIGINT</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>DECIMAL(</xsl:text>
                <xsl:value-of select="max((1, min((31, ceiling(math:log(math:power(2,
                    parameter[@name = 'precision']/@value - 1)) div math:log(10))))))"/>
                <xsl:text>)</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="datatype[@name = 'decimal']" priority="1.1">
        <xsl:text>DECIMAL(</xsl:text>
        <xsl:value-of select="max((1, min((31, xs:integer(parameter[@name =
            'totalDigits']/@value)))))"/>
        <xsl:text>,</xsl:text>
        <xsl:value-of select="max((0, min((31, min((xs:integer(parameter[@name =
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
        <xsl:text>DATE</xsl:text>
    </xsl:template>
    <xsl:template match="datatype[@name = 'time']" priority="1.1">
        <xsl:text>TIME</xsl:text>
    </xsl:template>
    <xsl:template match="datatype[@name = 'timestamp']" priority="1.1">
        <xsl:text>TIMESTAMP</xsl:text>
    </xsl:template>
    <xsl:template match="datatype[@name = 'yearMonthInterval']" priority="1.1">
        <xsl:text>INTEGER</xsl:text>
    </xsl:template>
    <xsl:template match="datatype[@name = 'dayTimeInterval']" priority="1.1">
        <xsl:text>INTEGER</xsl:text>
    </xsl:template>
    <xsl:template match="datatype[@name = 'boolean']" priority="1.1">
        <xsl:text>DECIMAL(1)</xsl:text>
    </xsl:template>
    <xsl:template match="datatype[@name = 'binary']" priority="1.1">
        <xsl:text>BLOB(</xsl:text>
        <xsl:value-of select="min((2147483647, xs:integer(parameter[@name =
            'length']/@value)))"/>
        <xsl:text>)</xsl:text>
        <xsl:if test="xs:integer(parameter[@name = 'length']/@value) &gt; 1073741824">
            <xsl:text> NOT LOGGED</xsl:text>
        </xsl:if>
    </xsl:template>
    <xsl:template match="autoNumber" priority="1.1">
        <xsl:text>GENERATED ALWAYS AS IDENTITY (</xsl:text>
        <xsl:text>START WITH </xsl:text>
        <xsl:value-of select="@startValue"/>
        <xsl:text> INCREMENT BY </xsl:text>
        <xsl:value-of select="@increment"/>
        <xsl:text>)</xsl:text>
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
                <xsl:text>NO ACTION</xsl:text>
            </xsl:when>
            <xsl:when test=". = 'setNull'">
                <xsl:text>NO ACTION</xsl:text>
            </xsl:when>
            <xsl:when test=". = 'setDefault'">
                <xsl:text>NO ACTION</xsl:text>
            </xsl:when>
        </xsl:choose>
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
