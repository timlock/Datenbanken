<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY eer 'http://www.informatik.uni-oldenburg.de/2006/EER-Designer/EER'>
    <!ENTITY func 'http://www.informatik.uni-oldenburg.de/2006/EER-Designer/XSLT-Functions'>
]>
<!--
    Das Stylesheet behandelt eine Generalisierung nach Option D. Dieses Stylesheet wird
    auch als Default für überlappende Generalisierungen verwendet. Die Generalisierung
    inklusive aller daran beteiligter Kanten wird entfernt. Ebenso werden die Subentitätstypen
    eliminiert. Deren Attribute werden an den Superentitätstyp angehängt, der zusätzlich um
    ein Typ-Attribut mit booleschem Wertebereich pro Subentitätstyp ergänzt wird.
    Beziehungstypen oder andere Generalisierungen, an denen eine der Subentitätstypen
    beteiligt ist, müssen so angepasst werden, dass stattdessen der Superentitätstyp daran
    teilnimmt.
    
    Das Stylesheet ist darauf ausgerichtet, in das Stylesheet EER2ER.xsl eingebunden zu
    werden. Alle Templates in diesem Stylesheet werden im Modus "t4" ausgeführt, um
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
    <xsl:template match="eer" mode="t4">
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
        Transformiert attribute-Elemente der Attribute, die einem der Subentitätstypen
        angehören.
    -->
    <xsl:template match="attribute[func:getOwner(@id) = $subEntities/@id]" mode="t4">
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="#current"/>
            <xsl:attribute name="key" select="if (@key = 'primary') then true() else @key"/>
            <xsl:apply-templates select="node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    <!--
        Transformiert das entity-Element des Superentitätstyps. Dieses muss um die Attribute
        der Subentitätstypen ergänzt werden. Außerdem wird ein Typ-Attribut pro Subentitätstyp
        erzeugt und dem Superentitätstyp hinzugefügt. Beachte: Auch die node- und
        attributeEdge-Elemente für die Typ-Attribute müssen erstellt werden.
    -->
    <xsl:template match="entity[@id = $superEntity/@id]" mode="t4">
        <xsl:variable name="typeAttributes">
            <xsl:for-each select="$subEntities">
                <xsl:variable name="newId" select="func:generate-id()"/>
                <attribute id="{$newId}" key="false" derived="false" multivalued="false">
                    <name>type<xsl:value-of select="position()"/></name>
                    <domain>
                        <datatype name="boolean"/>
                        <restrictions>
                            <notNull/>
                        </restrictions>
                    </domain>
                </attribute>
                <attributeRef idref="{$newId}"/>
                <node idref="{$newId}">
                    <pointAnchor x="{func:getX($superEntity/@id) + 1.0 * (position() - 1)}"
                        y="{func:getY($superEntity/@id) + 1.5}"/>
                </node>
                <attributeEdge>
                    <from>
                        <nodeAnchor idref="{$newId}" side="north" position="0.5"/>
                    </from>
                    <to>
                        <nodeAnchor idref="{$superEntity/@id}" side="south" position="0.5"/>
                    </to>
                </attributeEdge>
            </xsl:for-each>
        </xsl:variable>
        <xsl:copy>
            <xsl:apply-templates select="@* | name" mode="#current"/>
            <attributes>
                <xsl:apply-templates select="attributes/attributeRef" mode="#current"/>
                <xsl:for-each select="$subEntities">
                    <xsl:apply-templates select="attributes/attributeRef" mode="#current"/>
                </xsl:for-each>
                <xsl:copy-of select="$typeAttributes/attributeRef"/>
            </attributes>
        </xsl:copy>
        <xsl:copy-of select="$typeAttributes/attribute | $typeAttributes/node |
            $typeAttributes/attributeEdge"/>
    </xsl:template>
    <!--
        Entfernt die entity-Elemente der Subentitätstypen.
    -->
    <xsl:template match="entity[@id = $subEntities/@id]" mode="t4"/>
    <!--
        Attribute der Subentitätstypen dürfen nach der Transformation in der Regel nicht die
        Einschränkung "notNull" haben, da der null-Wert erforderlich ist, wenn die Entität nicht
        dem Subtyp angehört, zu dem das Attribut gehört. Eine Ausnahme gibt es, wenn die
        umzuwandelnde Generalisierung total ist und nur einen Subentitätstyp hat, da der
        Entitätstyp dann immer dem einen Subtyp angehört.
    -->
    <xsl:template match="notNull[func:getOwner(ancestor::attribute/@id) = $subEntities/@id]"
        mode="t4">
        <xsl:if test="xs:boolean($generalization/@total) and count($subEntities) = 1">
            <xsl:copy/>
        </xsl:if>
    </xsl:template>
    <!--
        Beteiligungen der Subentitätstypen an Beziehungstypen müssen so abgeändert
        werden, dass der Superentitätstyp anstelle eines Subentitätstyps an der Beziehung
        teilnimmt. Außerdem muss die Teilnahme in der Regel auf "partiell" abgeschwächt
        werden. Eine Ausnahme gibt es, wenn die umzuwandelnde Generalisierung total ist
        und nur einen Subentitätstyp hat.
    -->
    <xsl:template match="relationship/participatingEntities/entityRef[@idref = $subEntities/@id]"
        mode="t4">
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="#current"/>
            <xsl:attribute name="idref" select="$superEntity/@id"/>
            <xsl:attribute name="total" select="xs:boolean(@total) and
                xs:boolean($generalization/@total) and count($subEntities) = 1"/>
        </xsl:copy>
    </xsl:template>
    <!--
        Entfernt das generalization-Element der umzuwandelnden Generalisierung.
    -->
    <xsl:template match="generalization[@id = $generalization/@id]" mode="t4"/>
    <!--
        Die Beteiligung eines der Subentitätstypen der umzuwandelnden Generalisierung als
        Superentitätstyp einer anderen Generalisierung muss so abgeändert werden, dass
        der Superentitätstyp der umzuwandelnden Generalisierung anstelle des Subentitätstyps
        an der Generalisierung teilnimmt.
    -->
    <xsl:template match="generalization[@id != $generalization/@id]/superEntity[entityRef/@idref =
        $subEntities/@id]" mode="t4">
        <xsl:copy>
            <entityRef idref="{$superEntity/@id}"/>
        </xsl:copy>
    </xsl:template>
    <!--
        Die Beteiligung eines oder mehrerer der Subentitätstypen der umzuwandelnden
        Generalisierung als Subentitätstypen anderer Generalisierungen muss so abgeändert
        werden, dass der Superentitätstyp der umzuwandelnden Generalisierung anstelle der
        Subentitätstypen an der Generalisierung teilnimmt.
    -->
    <xsl:template match="generalization[@id != $generalization/@id]/subEntities[entityRef/@idref =
        $subEntities/@id]" mode="t4">
        <xsl:copy>
            <xsl:apply-templates select="entityRef[not(@idref = $subEntities/@id)]" mode="#current"/>
            <entityRef idref="{$superEntity/@id}"/>
        </xsl:copy>
    </xsl:template>
    <!--
        Entfernt alle businessRule-Elemente, die eines der Subentitätstypen referenzieren.
    -->
    <xsl:template match="businessRule[@about = $subEntities/@id]" mode="t4"/>
    <!--
        Entfernt die node-Elemente der umzuwandelnden Generalisierung und der
        Subentitätstypen.
    -->
    <xsl:template match="node[@idref = $generalization/@id or @idref = $subEntities/@id]" mode="t4"/>
    <!--
        Transformiert die node-Elemente der Attribute der Subentitätstypen. Diese werden
        in Richtung Superentitätstyp verschoben.
    -->
    <xsl:template match="node[func:getOwner(@idref) = $subEntities/@id]" mode="t4">
        <xsl:call-template name="move">
            <xsl:with-param name="nodes" select="."/>
            <xsl:with-param name="dx" select="func:getX($superEntity/@id) -
                func:getX(func:getOwner(@idref))"/>
            <xsl:with-param name="dy" select="func:getY($superEntity/@id) -
                func:getY(func:getOwner(@idref))"/>
        </xsl:call-template>
    </xsl:template>
    <!-- 
        Passt die relationshipEdge-Elemente der Beziehungstypen, an denen mindestens
        eine der Subentitätstypen beteiligt ist, an, damit sie mit den veränderten
        entityRef-Elementen des relationship-Elements konform sind.
    -->
    <xsl:template match="relationshipEdge[.//@idref = $subEntities/@id]" mode="t4">
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="#current"/>
            <xsl:attribute name="total" select="xs:boolean(@total) and
                xs:boolean($generalization/@total) and count($subEntities) = 1"/>
            <xsl:apply-templates select="node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    <!--
        Entfernt das generalizationEdge-Element der umzuwandelnden Generalisierung.
    -->
    <xsl:template match="generalizationEdge[.//@idref = $generalization/@id]" mode="t4"/>
    <!--
        Entfernt alle specializationEdge-Elemente der umzuwandelnden Generalisierung.
    -->
    <xsl:template match="specializationEdge[.//@idref = $generalization/@id]" mode="t4"/>
    <!--
        Passt die nodeAnchor-Elemente, die auf eines der Subentitätstypen verweisen, an.
        Diese müssen nun auf den Superentitätstyp verweisen.
    -->
    <xsl:template match="nodeAnchor[.//@idref = $subEntities/@id]" mode="t4">
        <xsl:copy>
            <xsl:attribute name="idref" select="$superEntity/@id"/>
            <xsl:apply-templates select="@* except @idref" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    <!--
        Kopiert den übrigen Inhalt unverändert in das Ergebnisdokument.
    -->
    <xsl:template match="@* | node()" mode="t4">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>
