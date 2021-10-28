<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY eer 'http://www.informatik.uni-oldenburg.de/2006/EER-Designer/EER'>
    <!ENTITY func 'http://www.informatik.uni-oldenburg.de/2006/EER-Designer/XSLT-Functions'>
]>
<!-- 
    Das Stylesheet behandelt einen Sonderfall. Wenn die Generalisierung keinen Super- oder
    keinen Subentitätstyp besitzt, wird die Generalisierung einfach entfernt und alle beteiligten
    Entitätstypen werden ohne Veränderung beibehalten. Diese Situation kann eintreten, wenn
    der Benutzer die Transformation für ein "unfertiges" Diagramm ausführen lässt.
    
    Das Stylesheet ist darauf ausgerichtet, in das Stylesheet EER2ER.xsl eingebunden zu
    werden. Alle Templates in diesem Stylesheet werden im Modus "t0" ausgeführt, um
    Konflikte mit den anderen Stylesheets zu vermeiden.
-->
<xsl:stylesheet xmlns="&eer;" xmlns:eer="&eer;" xmlns:func="&func;"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:saxon="http://saxon.sf.net/" xpath-default-namespace="&eer;"
    extension-element-prefixes="saxon" exclude-result-prefixes="eer func xs" version="2.0">
    <!-- TEMPLATES -->
    <!--
        Transformiert das Wurzelelement.
    -->
    <xsl:template match="eer" mode="t0">
        <xsl:variable name="objects">
            <xsl:perform-sort>
                <xsl:sort select="@id | @idref"/>
                <xsl:apply-templates select="model/node() | view/node()" mode="#current"/>
            </xsl:perform-sort>
        </xsl:variable>
        <xsl:copy-of select="head"/>
        <model>
            <xsl:copy-of select="$objects/attribute"/>
            <xsl:copy-of select="$objects/entity"/>
            <xsl:copy-of select="$objects/relationship"/>
            <xsl:copy-of select="$objects/generalization"/>
            <xsl:copy-of select="$objects/businessRule"/>
        </model>
        <view>
            <xsl:copy-of select="./view/@*"/>
            <xsl:copy-of select="$objects/node"/>
            <xsl:copy-of select="$objects/attributeEdge"/>
            <xsl:copy-of select="$objects/relationshipEdge"/>
            <xsl:copy-of select="$objects/generalizationEdge"/>
            <xsl:copy-of select="$objects/specializationEdge"/>
        </view>
    </xsl:template>
    <!--
        Entfernt das generalization-Element der umzuwandelnden Generalisierung.
    -->
    <xsl:template match="generalization[@id = $generalization/@id]" mode="t0"/>
    <!--
        Entfernt das node-Element der umzuwandelnden Generalisierung.
    -->
    <xsl:template match="node[@idref = $generalization/@id]" mode="t0"/>
    <!--
        Entfernt das generalizationEdge-Element der umzuwandelnden Generalisierung.
    -->
    <xsl:template match="generalizationEdge[.//@idref = $generalization/@id]" mode="t0"/>
    <!--
        Entfernt alle specializationEdge-Elemente der umzuwandelnden Generalisierung.
    -->
    <xsl:template match="specializationEdge[.//@idref = $generalization/@id]" mode="t0"/>
    <!--
        Kopiert den übrigen Inhalt unverändert in das Ergebnisdokument.
    -->
    <xsl:template match="@* | node()" mode="t0">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>
