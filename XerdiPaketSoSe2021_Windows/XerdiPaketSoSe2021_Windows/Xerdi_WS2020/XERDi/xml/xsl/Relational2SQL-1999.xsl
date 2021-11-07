<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY rs 'http://www.informatik.uni-oldenburg.de/2006/EER-Designer/RelationalSchema'>
    <!ENTITY func 'http://www.informatik.uni-oldenburg.de/2006/EER-Designer/XSLT-Functions'>
    <!ENTITY delimiter '&quot;'>
    <!ENTITY quote '&#x0027;'>
    <!ENTITY newline '&#x000A;'>
    <!ENTITY indent '    '>
]>
<!--
    Dieses Stylesheet ist die Basis-Implementierung eines Stylesheets zur Generierung von
    SQL-Befehlen. Als Eingabe wird ein XML-Dokument erwartet, welches dem XML-Schema
    für relationale Schemata genügt. Ausgegeben wird ein SQL-Skript, das der Grammatik
    der DDL von SQL:1999 folgt. Im Wesentlichen ist die Aufgabe dieses Stylesheets, für
    jedes Relationsschema einen CREATE TABLE-Befehl zu erzeugen und Fremdschlüssel
    durch ALTER TABLE-Befehle nachträglich zu ergänzen (um zyklische Abhängigkeiten zu
    berücksichtigen).
    
    In diesem Stylesheet sind alle Templates mit (ganzzahligen) Prioritäten von 1 bis n
    versehen. Dies ist erforderlich, da in einigen Fällen mehrere Templates für ein und
    dasselbe Element existieren. Die Templates mit höherer Priorität rufen dabei in der
    Regel die Templates mit niedrigerer Priorität auf. Beispielsweise gibt es ein Template
    für attribute-, primaryKey- und unique-Elemente mit der Priorität 2. Dieses implementiert
    den Teil der Transformation, der für alle diese Elemente gleich ist. In diesem Fall ist
    dies die Einrückung am Anfang der Zeile sowie den Abschluss mit einem Komma, falls
    es sich nicht um den letzten Eintrag der Tabelle handelt. Für jedes der drei genannten
    Elemente gibt es dann zusätzlich ein Template mit der Priorität 1, welches die
    spezifischen Transformationen vornimmt.
    
    Für jeden zu unterstützenden SQL-Dialekt wird ein weiteres Stylesheet benötigt. In den
    meisten Fällen bietet es sich an, die Referenz-Implementierung als Grundlage zu
    nehmen und nur bestimmte Regeln zu überschreiben, z.B. das Mapping der Datentypen.
    Es ist hierfür zu empfehlen, dieses Stylesheet zu inkludieren und die Templates zu
    überschreiben, indem höhere Prioritäten vergeben werden. Hierbei ist folgendens zu
    beachten: Wenn z.B. ein Template mit der Priorität 1 überschrieben, Templates mit
    höherer Priorität, etwa 2, für dasselbe Element aber erhalten bleiben sollen, so ist die
    Priorität zwischen 1 und 2 zu wählen (also z.B. 1.1).
    
    @param useDelimitedIdentifierstrue, wenn Bezeichner immer in Anführungszeichen
        gesetzt werden sollen
-->
<xsl:stylesheet xmlns:rs="&rs;" xmlns:func="&func;"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:saxon="http://saxon.sf.net/" xpath-default-namespace="&rs;"
    extension-element-prefixes="saxon" exclude-result-prefixes="rs func xs" version="2.0">
    <!-- OUTPUT -->
    <xsl:output method="text"/>
    <!-- PARAMETERS -->
    <xsl:param name="useDelimitedIdentifiers" as="xs:boolean" required="no" select="true()"/>
    <!-- TEMPLATES -->
    <xsl:template match="/" priority="1">
        <xsl:apply-templates select="schema"/>
    </xsl:template>
    <xsl:template match="schema" priority="1">
        <xsl:apply-templates select="head"/>
        <xsl:apply-templates select="body"/>
    </xsl:template>
    <xsl:template match="head" priority="1">
        <xsl:text>-- SQL script for </xsl:text>
        <xsl:apply-templates select="name"/>
    </xsl:template>
    <xsl:template match="body" priority="1">
        <xsl:apply-templates select="(relation, relation/constraints/foreignKey)"/>
        <xsl:if test="exists(//autoNumber)">
            <xsl:text>&newline;&newline;</xsl:text>
            <xsl:text>-- There should be some auto key columns created. Unfortunately auto key columns are not supported by SQL:1999.</xsl:text>
        </xsl:if>
    </xsl:template>
    <xsl:template match="relation | foreignKey" priority="4">
        <xsl:text>&newline;&newline;</xsl:text>
        <xsl:next-match/>
        <xsl:text>;</xsl:text>
    </xsl:template>
    <xsl:template match="relation" priority="3">
        <xsl:text>CREATE TABLE </xsl:text>
        <xsl:apply-templates select="name"/>
        <xsl:text> (&newline;</xsl:text>
        <xsl:apply-templates select="(attributes/attribute, constraints/primaryKey,
            constraints/unique)"/>
        <xsl:text>)</xsl:text>
    </xsl:template>
    <xsl:template match="foreignKey" priority="3">
        <xsl:choose>
            <xsl:when test="exists(attributeRef)">
                <xsl:text>ALTER TABLE </xsl:text>
                <xsl:apply-templates select="../../name"/>
                <xsl:text>&newline;</xsl:text>
                <xsl:next-match/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>-- FOREIGN KEY for table </xsl:text>
                <xsl:apply-templates select="../../name"/>
                <xsl:text> could not be created because referenced table </xsl:text>
                <xsl:variable name="ref" select="@references"/>
                <xsl:apply-templates select="//constraints/*[@id = $ref]/../../name"/>
                <xsl:text> has no primary key</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="attribute | primaryKey | unique" priority="2">
        <xsl:text>&indent;</xsl:text>
        <xsl:next-match/>
        <xsl:if test="position() != last()">
            <xsl:text>,</xsl:text>
        </xsl:if>
        <xsl:text>&newline;</xsl:text>
    </xsl:template>
    <xsl:template match="foreignKey" priority="2">
        <xsl:text>&indent;ADD </xsl:text>
        <xsl:next-match/>
    </xsl:template>
    <xsl:template match="datatype | default | autoNumber | restrictions/notNull | foreignKey/@*"
        priority="2">
        <xsl:text> </xsl:text>
        <xsl:next-match/>
    </xsl:template>
    <xsl:template match="attribute" priority="1">
        <xsl:apply-templates select="name"/>
        <xsl:apply-templates select="domain/datatype"/>
        <xsl:apply-templates select="default | autoNumber"/>
        <xsl:apply-templates select="domain/restrictions"/>
    </xsl:template>
    <xsl:template match="datatype[@name = 'char']" priority="1">
        <xsl:if test="xs:boolean(parameter[@name = 'national']/@value)">
            <xsl:text>N</xsl:text>
        </xsl:if>
        <xsl:text>CHAR(</xsl:text>
        <xsl:value-of select="max((1, xs:integer(parameter[@name = 'length']/@value)))"/>
        <xsl:text>)</xsl:text>
    </xsl:template>
    <xsl:template match="datatype[@name = 'varchar']" priority="1">
        <xsl:if test="xs:boolean(parameter[@name = 'national']/@value)">
            <xsl:text>N</xsl:text>
        </xsl:if>
        <xsl:text>CHAR VARYING(</xsl:text>
        <xsl:value-of select="max((1, xs:integer(parameter[@name = 'length']/@value)))"/>
        <xsl:text>)</xsl:text>
    </xsl:template>
    <xsl:template match="datatype[@name = 'integer']" priority="1">
        <xsl:text>INT</xsl:text>
    </xsl:template>
    <xsl:template match="datatype[@name = 'decimal']" priority="1">
        <xsl:text>DECIMAL(</xsl:text>
        <xsl:value-of select="max((1, xs:integer(parameter[@name = 'totalDigits']/@value)))"/>
        <xsl:text>,</xsl:text>
        <xsl:value-of select="max((0, min((xs:integer(parameter[@name = 'totalDigits']/@value),
            xs:integer(parameter[@name = 'fractionDigits']/@value)))))"/>
        <xsl:text>)</xsl:text>
    </xsl:template>
    <xsl:template match="datatype[@name = 'float']" priority="1">
        <xsl:text>FLOAT(</xsl:text>
        <xsl:value-of select="max((1, xs:integer(parameter[@name = 'precision']/@value)))"/>
        <xsl:text>)</xsl:text>
    </xsl:template>
    <xsl:template match="datatype[@name = 'date']" priority="1">
        <xsl:text>DATE</xsl:text>
    </xsl:template>
    <xsl:template match="datatype[@name = 'time']" priority="1">
        <xsl:text>TIME(</xsl:text>
        <xsl:value-of select="max((0, xs:integer(parameter[@name = 'fractionDigits']/@value)))"/>
        <xsl:text>)</xsl:text>
        <xsl:if test="xs:boolean(parameter[@name = 'withTimezone']/@value)">
            <xsl:text> WITH TIME ZONE</xsl:text>
        </xsl:if>
    </xsl:template>
    <xsl:template match="datatype[@name = 'timestamp']" priority="1">
        <xsl:text>TIMESTAMP(</xsl:text>
        <xsl:value-of select="max((0, xs:integer(parameter[@name = 'fractionDigits']/@value)))"/>
        <xsl:text>)</xsl:text>
        <xsl:if test="xs:boolean(parameter[@name = 'withTimezone']/@value)">
            <xsl:text> WITH TIME ZONE</xsl:text>
        </xsl:if>
    </xsl:template>
    <xsl:template match="datatype[@name = 'yearMonthInterval']" priority="1">
        <xsl:text>INTERVAL YEAR TO MONTH</xsl:text>
    </xsl:template>
    <xsl:template match="datatype[@name = 'dayTimeInterval']" priority="1">
        <xsl:text>INTERVAL DAY TO SECOND(</xsl:text>
        <xsl:value-of select="max((0, xs:integer(parameter[@name = 'fractionDigits']/@value)))"/>
        <xsl:text>)</xsl:text>
    </xsl:template>
    <xsl:template match="datatype[@name = 'boolean']" priority="1">
        <xsl:text>BOOLEAN</xsl:text>
    </xsl:template>
    <xsl:template match="datatype[@name = 'binary']" priority="1">
        <xsl:text>BLOB(</xsl:text>
        <xsl:value-of select="max((1, xs:integer(parameter[@name = 'size']/@value)))"/>
        <xsl:text>)</xsl:text>
    </xsl:template>
    <xsl:template match="default" priority="1">
        <xsl:text>DEFAULT </xsl:text>
        <xsl:apply-templates select="@value"/>
    </xsl:template>
    <xsl:template match="autoNumber" priority="1">
        <xsl:text>/* AUTO KEY */</xsl:text>
    </xsl:template>
    <xsl:template match="restrictions" priority="1">
        <xsl:apply-templates select="notNull"/>
        <xsl:if test="exists(* except notNull)">
            <xsl:text> CHECK (</xsl:text>
            <xsl:apply-templates select="* except (notNull | enumeration)"/>
            <xsl:if test="exists(enumeration)">
                <xsl:if test="exists(* except (notNull | enumeration))">
                    <xsl:text> AND </xsl:text>
                    <xsl:if test="count(enumeration) > 1">
                        <xsl:text>(</xsl:text>
                    </xsl:if>
                </xsl:if>
                <xsl:apply-templates select="enumeration"/>
                <xsl:if test="exists(* except (notNull | enumeration)) and count(enumeration) > 1">
                    <xsl:text>)</xsl:text>
                </xsl:if>
            </xsl:if>
            <xsl:text>)</xsl:text>
        </xsl:if>
    </xsl:template>
    <xsl:template match="restrictions/notNull" priority="1">
        <xsl:text>NOT NULL</xsl:text>
    </xsl:template>
    <xsl:template match="restrictions/minimum" priority="1">
        <xsl:apply-templates select="../../../name"/>
        <xsl:text> &gt;= </xsl:text>
        <xsl:apply-templates select="@value"/>
        <xsl:if test="position() != last()">
            <xsl:text> AND </xsl:text>
        </xsl:if>
    </xsl:template>
    <xsl:template match="restrictions/maximum" priority="1">
        <xsl:apply-templates select="../../../name"/>
        <xsl:text> &lt;= </xsl:text>
        <xsl:apply-templates select="@value"/>
        <xsl:if test="position() != last()">
            <xsl:text> AND </xsl:text>
        </xsl:if>
    </xsl:template>
    <xsl:template match="restrictions/pattern" priority="1">
        <xsl:apply-templates select="../../../name"/>
        <xsl:text> LIKE </xsl:text>
        <xsl:apply-templates select="@value"/>
        <xsl:if test="position() != last()">
            <xsl:text> AND </xsl:text>
        </xsl:if>
    </xsl:template>
    <xsl:template match="restrictions/enumeration" priority="1">
        <xsl:apply-templates select="../../../name"/>
        <xsl:text> = </xsl:text>
        <xsl:apply-templates select="@value"/>
        <xsl:if test="position() != last()">
            <xsl:text> OR </xsl:text>
        </xsl:if>
    </xsl:template>
    <xsl:template match="primaryKey" priority="1">
        <xsl:choose>
            <xsl:when test="exists(attributeRef)">
                <xsl:text>PRIMARY KEY (</xsl:text>
                <xsl:apply-templates select="attributeRef"/>
                <xsl:text>)</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>/* PRIMARY KEY is needed for this table */</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="unique" priority="1">
        <xsl:text>UNIQUE (</xsl:text>
        <xsl:apply-templates select="attributeRef"/>
        <xsl:text>)</xsl:text>
    </xsl:template>
    <xsl:template match="foreignKey" priority="1">
        <xsl:text>FOREIGN KEY (</xsl:text>
        <xsl:apply-templates select="attributeRef"/>
        <xsl:text>)</xsl:text>
        <xsl:apply-templates select="@references"/>
        <xsl:apply-templates select="@onDelete"/>
        <xsl:apply-templates select="@onUpdate"/>
    </xsl:template>
    <xsl:template match="foreignKey/@references" priority="1">
        <xsl:variable name="id" select="."/>
        <xsl:text>REFERENCES </xsl:text>
        <xsl:apply-templates select="//constraints/*[@id = $id]/../../name"/>
        <xsl:text> (</xsl:text>
        <xsl:apply-templates select="//constraints/*[@id = $id]/attributeRef"/>
        <xsl:text>)</xsl:text>
    </xsl:template>
    <xsl:template match="foreignKey/@onDelete" priority="1">
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
                <xsl:text>SET DEFAULT</xsl:text>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="foreignKey/@onUpdate" priority="1">
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
                <xsl:text>SET DEFAULT</xsl:text>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="attributeRef" priority="1">
        <xsl:variable name="idref" select="@idref"/>
        <xsl:apply-templates select="../../../attributes/attribute[@id = $idref]/name"/>
        <xsl:if test="position() != last()">
            <xsl:text>, </xsl:text>
        </xsl:if>
    </xsl:template>
    <xsl:template match="name" priority="1">
        <xsl:call-template name="prepareIdentifier">
            <xsl:with-param name="identifier" select="text()"/>
        </xsl:call-template>
    </xsl:template>
    <xsl:template match="@value" priority="1">
        <xsl:call-template name="prepareLiteral">
            <xsl:with-param name="literal" select="."/>
        </xsl:call-template>
    </xsl:template>
    <xsl:template name="prepareIdentifier">
        <xsl:param name="identifier" required="yes"/>
        <xsl:if test="$useDelimitedIdentifiers or contains($identifier, ' ')">
            <xsl:text>&delimiter;</xsl:text>
        </xsl:if>
        <xsl:value-of select="$identifier"/>
        <xsl:if test="$useDelimitedIdentifiers or contains($identifier, ' ')">
            <xsl:text>&delimiter;</xsl:text>
        </xsl:if>
    </xsl:template>
    <xsl:template name="prepareLiteral">
        <xsl:param name="literal" required="yes"/>
        <xsl:text>&quote;</xsl:text>
        <xsl:variable name="quote">&quote;</xsl:variable>
        <xsl:value-of select="replace($literal, $quote, concat($quote, $quote))"/>
        <xsl:text>&quote;</xsl:text>
    </xsl:template>
</xsl:stylesheet>
