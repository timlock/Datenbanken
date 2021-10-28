<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY eer 'http://www.informatik.uni-oldenburg.de/2006/EER-Designer/EER'>
    <!ENTITY func 'http://www.informatik.uni-oldenburg.de/2006/EER-Designer/XSLT-Functions'>
]>
<!-- 
    Das Stylesheet behandelt eine Generalisierung nach Option A. Die Generalisierung
    inklusive aller daran beteiligter Kanten wird entfernt. Dafür wird jeder Subentitätstyp in
    einen schwachen Entitätstyp umgewandelt und über eine identifizierende Beziehung
    durch entsprechenden Kanten mit dem Superentitätstyp verbunden.
    
    Das Stylesheet ist darauf ausgerichtet, in das Stylesheet EER2ER.xsl eingebunden zu
    werden. Alle Templates in diesem Stylesheet werden im Modus "t1" ausgeführt, um
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
    <xsl:template match="eer" mode="t1">
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
        Transformiert das entity-Element des Superentitätstyps. Er wird in einen schwachen
        Entitätstyp umgewandelt.
    -->
    <xsl:template match="entity[@id = $subEntities/@id]" mode="t1">
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="#current"/>
            <xsl:attribute name="weak">true</xsl:attribute>
            <xsl:apply-templates select="node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    <!--
        Transformiert das generalization-Element der umzuwandelnden Generalisierung. Hier
        werden die Beziehungstypen erzeugt, die den Superentitätstyp mit den Subentitätstypen
        verbinden sollen.
    -->
    <xsl:template match="generalization[@id = $generalization/@id]" mode="t1">
        <xsl:for-each select="$subEntities">
            <xsl:variable name="thisSubEntity" select="."/>
            <xsl:variable name="newId" select="func:generate-id()"/>
            <relationship id="{$newId}" identifying="true">
                <name>is</name>
                <attributes/>
                <participatingEntities>
                    <xsl:if test="exists($superEntity)">
                        <entityRef idref="{$superEntity/@id}" cardinality="1"
                            total="{xs:boolean($generalization/@total) and
                            count($subEntities) = 1}"/>
                    </xsl:if>
                    <entityRef idref="{@id}" cardinality="1" total="true"/>
                </participatingEntities>
            </relationship>
            <xsl:variable name="x1" select="func:getX($superEntity/@id)"/>
            <xsl:variable name="x2" select="func:getX($thisSubEntity/@id)"/>
            <xsl:variable name="x" select="($x1+$x2) div 2"/>
            <xsl:variable name="y1" select="func:getY($superEntity/@id)"/>
            <xsl:variable name="y2" select="func:getY($thisSubEntity/@id)"/>
            <xsl:variable name="y" select="($y1+$y2) div 2"/>
            <xsl:variable name="hdir" select="abs($x1 - $x2) &gt; abs($y1 - $y2)"/>
            <node idref="{$newId}">
                <pointAnchor x="{$x}" y="{$y}"/>
            </node>
            <relationshipEdge total="{xs:boolean($generalization/@total) and
                count($subEntities) = 1}">
                <from>
                    <nodeAnchor idref="{$newId}" side="{if ($hdir) then (if ($x &lt; $x1) then
                        'east' else 'west') else (if ($y &lt; $y1) then 'south' else 'north')}"
                        position="0.5"/>
                </from>
                <to>
                    <nodeAnchor idref="{$superEntity/@id}" side="{if ($hdir) then (if ($x &lt;
                        $x1) then 'west' else 'east') else (if ($y &lt; $y1) then 'north' else
                        'south')}" position="0.5"/>
                </to>
                <over/>
                <label>
                    <text>1</text>
                    <pointAnchor x="0" y="0"/>
                </label>
            </relationshipEdge>
            <relationshipEdge total="true">
                <from>
                    <nodeAnchor idref="{$newId}" side="{if ($hdir) then (if ($x &lt; $x2) then
                        'east' else 'west') else (if ($y &lt; $y2) then 'south' else 'north')}"
                        position="0.5"/>
                </from>
                <to>
                    <nodeAnchor idref="{$thisSubEntity/@id}" side="{if ($hdir) then (if ($x &lt;
                        $x2) then 'west' else 'east') else (if ($y &lt; $y2) then 'north' else
                        'south')}" position="0.5"/>
                </to>
                <over/>
                <label>
                    <text>1</text>
                    <pointAnchor x="0" y="0"/>
                </label>
            </relationshipEdge>
        </xsl:for-each>
    </xsl:template>
    <!--
        Entfernt das node-Element der umzuwandelnden Generalisierung.
    -->
    <xsl:template match="node[@idref = $generalization/@id]" mode="t1"/>
    <!--
        Entfernt das generalizationEdge-Element der umzuwandelnden Generalisierung.
    -->
    <xsl:template match="generalizationEdge[.//@idref = $generalization/@id]" mode="t1"/>
    <!--
        Entfernt alle specializationEdge-Elemente der umzuwandelnden Generalisierung.
    -->
    <xsl:template match="specializationEdge[.//@idref = $generalization/@id]" mode="t1"/>
    <!--
        Kopiert den übrigen Inhalt unverändert in das Ergebnisdokument.
    -->
    <xsl:template match="@* | node()" mode="t1">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>
