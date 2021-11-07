<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY eer 'http://www.informatik.uni-oldenburg.de/2006/EER-Designer/EER'>
    <!ENTITY func 'http://www.informatik.uni-oldenburg.de/2006/EER-Designer/XSLT-Functions'>
]>
<!--
    Das Stylesheet behandelt eine Generalisierung nach Option B. Die Generalisierung
    inklusive aller daran beteiligter Kanten wird entfernt. Ebenso wird der Superentitätstyp
    eliminiert. Dessen Attribute werden kopiert und an jeden Subentitätstyp angehängt. Des
    Weiteren müssen Beziehungstypen und andere Generalisierungen berücksichtigt
    werden, an denen der Superentitätstyp beteiligt ist. Beziehungstypen, auf die dies zutrifft,
    werden inklusive ihrer Attribute und Kanten vervielfältigt, so dass jeder Subentitätstyp mit
    genau einer Kopie verbunden werden kann. Mit Generalisierungen, an denen der
    Superentitätstyp der zu eliminierenden Generalisierung ebenfalls als Superentitätstyp
    teilnimmt, ist genauso zu verfahren. Ist der Superentitätstyp an anderer Stelle als
    Subentitätstyp involviert, müssen lediglich die Subentitätstypen der zu eliminierenden
    Generalisierung dort als Subentitätstypen eingetragen werden.
    
    Das Stylesheet ist darauf ausgerichtet, in das Stylesheet EER2ER.xsl eingebunden zu
    werden. Alle Templates in diesem Stylesheet werden im Modus "t2" ausgeführt, um
    Konflikte mit den anderen Stylesheets zu vermeiden.
-->
<xsl:stylesheet xmlns="&eer;" xmlns:eer="&eer;" xmlns:func="&func;"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:saxon="http://saxon.sf.net/" xpath-default-namespace="&eer;"
    extension-element-prefixes="saxon" exclude-result-prefixes="eer func xs" version="2.0">
    <!-- VARIABLES -->
    <!-- IDs der Attribute des Superentitätstyps -->
    <xsl:variable name="superEntityAttributes" select="func:getAttributes($superEntity/@id)"/>
    <!-- TEMPLATES -->
    <!-- 
        Transformiert das Wurzelelement.
    -->
    <xsl:template match="eer" mode="t2">
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
        Entfernt alle attribute-Elemente der Attribute, die dem Superentitätstyp oder einem
        Beziehungstyp, an dem der Superentitätstyp beteiligt ist, angehören.
    -->
    <xsl:template match="attribute[@id = $superEntityAttributes or @id =
        func:getAttributes(//relationship[$superEntity/@id =
        participatingEntities/entityRef/@idref]/@id)]" mode="t2"/>
    <!--
        Transformiert attribute-Elemente der Attribute, die einem der Subentitätstypen
        angehören.
    -->
    <xsl:template match="attribute[func:getOwner(@id) = $subEntities/@id]" mode="t2">
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="#current"/>
            <xsl:attribute name="key" select="if (@key = 'primary') then true() else @key"/>
            <xsl:apply-templates select="node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    <!--
        Entfernt das entity-Element des Superentitätstyps.
    -->
    <xsl:template match="entity[@id = $superEntity/@id]" mode="t2"/>
    <!--
        Transformiert die entity-Elemente der Subentitätstypen. Diese müssen um die
        Attribute des Superentitätstyps ergänzt werden. Diese werden hierzu kopiert und mit
        neuen IDs versehen. Beachte: Auch die node- und attributeEdge-Elemente müssen
        kopiert und angepasst werden.
    -->
    <xsl:template match="entity[@id = $subEntities/@id]" mode="t2">
        <xsl:variable name="attributes">
            <xsl:copy-of select="func:replace-id(func:replace-all-ids(//attribute[@id =
                $superEntityAttributes] | $superEntity/attributes/attributeRef | //node[@idref =
                $superEntityAttributes] | //attributeEdge[.//@idref = $superEntityAttributes]),
                $superEntity/@id, ./@id)"/>
        </xsl:variable>
        <xsl:copy>
            <xsl:apply-templates select="@* | name" mode="#current"/>
            <attributes>
                <xsl:apply-templates select="attributes/attributeRef" mode="#current"/>
                <xsl:apply-templates select="$attributes/attributeRef" mode="#current"/>
            </attributes>
        </xsl:copy>
        <xsl:copy-of select="$attributes/attribute | $attributes/attributeEdge"/>
        <xsl:call-template name="move">
            <xsl:with-param name="nodes" select="$attributes/node"/>
            <xsl:with-param name="dx" select="func:getX(@id) - func:getX($superEntity/@id)"/>
            <xsl:with-param name="dy" select="func:getY(@id) - func:getY($superEntity/@id)"/>
        </xsl:call-template>
    </xsl:template>
    <!--
        Transformiert relationship-Elemente von Beziehungstypen, an denen der
        Superentitätstyp beteiligt ist. Diese werden kopiert und mit neuen IDs versehen.
        Beachte: Auch die node- und relationshipEdge-Elemente sowie die attribute-, node-
        und attributeEdge-Elemente der Attribute des Beziehungstyps müssen kopiert und
        angepasst werden.
    -->
    <xsl:template match="relationship[$superEntity/@id = participatingEntities/entityRef/@idref]"
        mode="t2">
        <xsl:variable name="thisRelationship" select="."/>
        <xsl:for-each select="$subEntities">
            <xsl:variable name="thisSubEntity" select="."/>
            <xsl:variable name="copy">
                <xsl:copy-of select="func:replace-id(func:replace-all-ids($thisRelationship |
                    //attribute[@id = func:getAttributes($thisRelationship/@id)] | //node[@idref =
                    $thisRelationship/@id or @idref = func:getAttributes($thisRelationship/@id)] |
                    //relationshipEdge[.//@idref = $thisRelationship/@id] |
                    //attributeEdge[.//@idref = func:getAttributes($thisRelationship/@id)]),
                    $superEntity/@id, $thisSubEntity/@id)"/>
            </xsl:variable>
            <relationship>
                <xsl:apply-templates select="$copy/relationship/@* | $copy/relationship/node()"
                    mode="#current"/>
            </relationship>
            <xsl:copy-of select="$copy/attribute | $copy/relationshipEdge | $copy/attributeEdge"/>
            <xsl:call-template name="move">
                <xsl:with-param name="nodes" select="$copy/node"/>
                <xsl:with-param name="dx" select="1.0 * (position() - 1)"/>
                <xsl:with-param name="dy" select="1.0 * (position() - 1)"/>
            </xsl:call-template>
        </xsl:for-each>
    </xsl:template>
    <!--
        Entfernt das generalization-Element der umzuwandelnden Generalisierung.
    -->
    <xsl:template match="generalization[@id = $generalization/@id]" mode="t2"/>
    <!--
        Transformiert generalization-Elemente von Generalisierungen, an denen der
        Superentitätstyp der umzuwandelnden Generalisierung als Superentitätstyp beteiligt
        ist (außer der umzuwandelnden Generalisierung). Die Generalisierungen werden
        kopiert und mit neuen IDs versehen. Beachte: Auch die node-, generalizationEdge-
        und specializationEdge-Elemente müssen kopiert und angepasst werden.
    -->
    <xsl:template match="generalization[@id != $generalization/@id and $superEntity/@id =
        superEntity/entityRef/@idref]" mode="t2">
        <xsl:variable name="thisGeneralization" select="."/>
        <xsl:for-each select="$subEntities">
            <xsl:variable name="thisSubEntity" select="."/>
            <xsl:variable name="copy">
                <xsl:copy-of select="func:replace-id(func:replace-all-ids($thisGeneralization |
                    //node[@idref = $thisGeneralization/@id] | //generalizationEdge[.//@idref =
                    $thisGeneralization/@id] | //specializationEdge[.//@idref =
                    $thisGeneralization/@id]), $superEntity/@id, $thisSubEntity/@id)"/>
            </xsl:variable>
            <generalization>
                <xsl:apply-templates select="$copy/generalization/@* | $copy/generalization/node()"
                    mode="#current"/>
            </generalization>
            <xsl:copy-of select="$copy/generalizationEdge | $copy/specializationEdge"/>
            <xsl:call-template name="move">
                <xsl:with-param name="nodes" select="$copy/node"/>
                <xsl:with-param name="dx" select="0.5 * (position() - 1)"/>
                <xsl:with-param name="dy" select="0.5 * (position() - 1)"/>
            </xsl:call-template>
        </xsl:for-each>
    </xsl:template>
    <!--
        Transformiert generalization-Elemente von Generalisierungen, an denen der
        Superentitätstyp der umzuwandelnden Generalisierung als Subentitätstyp beteiligt
        ist. Den Generalisierungen müssen die Subentitätstypen der umzuwandelnden
        Generalisierung als Subentitätstypen hinzugefügt werden.
    -->
    <xsl:template match="generalization[@id != $generalization/@id and $superEntity/@id =
        subEntities/entityRef/@idref]" mode="t2">
        <xsl:variable name="thisGeneralization" select="."/>
        <xsl:choose>
            <!-- direkte Spezialisierungskante zwischen Super- und Subentitätstyp --> 
            <xsl:when test="exists(//specializationEdge/generalizationRef[@idref =
                $thisGeneralization/@id])">
                <xsl:for-each select="$subEntities">
                    <xsl:variable name="thisSubEntity" select="."/>
                    <xsl:variable name="copy">
                        <xsl:copy-of
                            select="func:replace-id(func:replace-all-ids($thisGeneralization |
                            //specializationEdge[.//@idref = $thisGeneralization/@id]),
                            $superEntity/@id, $thisSubEntity/@id)"/>
                    </xsl:variable>
                    <generalization>
                        <xsl:apply-templates select="$copy/generalization/@* |
                            $copy/generalization/node()" mode="#current"/>
                    </generalization>
                    <xsl:copy-of select="$copy/specializationEdge"/>
                </xsl:for-each>
            </xsl:when>
            <!-- Generalisierung mit Generalisierungspunkt --> 
            <xsl:otherwise>
                <xsl:copy>
                    <xsl:apply-templates select="@* | superEntity" mode="#current"/>
                    <subEntities>
                        <xsl:apply-templates select="subEntities/entityRef[@idref !=
                            $superEntity/@id]" mode="#current"/>
                        <xsl:for-each select="$subEntities">
                            <xsl:variable name="thisSubEntity" select="."/>
                            <xsl:copy-of
                                select="func:replace-id($thisGeneralization/subEntities/entityRef[@idref
                                = $superEntity/@id], $superEntity/@id, $thisSubEntity/@id)"/>
                        </xsl:for-each>
                    </subEntities>
                </xsl:copy>
                <xsl:for-each select="$subEntities">
                    <xsl:variable name="thisSubEntity" select="."/>
                    <xsl:copy-of select="func:replace-id(//specializationEdge[.//@idref =
                        $thisGeneralization/@id], $superEntity/@id, $thisSubEntity/@id)"/>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <!--
        Entfernt alle businessRule-Elemente, die zu entfernende Objekte referenzieren.
    -->
    <xsl:template match="businessRule[@about = $superEntity/@id or @about = $superEntityAttributes
        or @about = //relationship[$superEntity/@id = participatingEntities/entityRef/@idref]/@id or
        @about = func:getAttributes(//relationship[$superEntity/@id =
        participatingEntities/entityRef/@idref]/@id)]" mode="t2"/>
    <!--
        Entfernt alle node-Elemente der zu entfernenden Objekte.
    -->
    <xsl:template match="node[@idref = $generalization/@id or @idref = $superEntity/@id or
        @idref = $superEntityAttributes or @idref = //relationship[$superEntity/@id =
        participatingEntities/entityRef/@idref]/@id or @idref =
        func:getAttributes(//relationship[$superEntity/@id =
        participatingEntities/entityRef/@idref]/@id) or @idref =
        //generalization[superEntity/entityRef/@idref = $superEntity/@id]/@id]" mode="t2"/>
    <!--
        Entfernt alle attributeEdge-Elemente der zu entfernenden Attribute.
    -->
    <xsl:template match="attributeEdge[.//@idref = $superEntityAttributes or .//@idref =
        func:getAttributes(//relationship[$superEntity/@id =
        participatingEntities/entityRef/@idref]/@id)]" mode="t2"/>
    <!--
        Entfernt alle relationship-Elemente der zu entfernenden Beziehungstypen.
    -->
    <xsl:template match="relationshipEdge[.//@idref = //relationship[$superEntity/@id =
        participatingEntities/entityRef/@idref]/@id]" mode="t2"/>
    <!--
        Entfernt alle generalizationEdge-Elemente der zu entfernenden Generalisierungen.
    -->
    <xsl:template match="generalizationEdge[.//@idref = $generalization/@id or .//@idref =
        //generalization[$superEntity/@id = superEntity/entityRef/@idref]/@id]" mode="t2"/>
    <!--
        Entfernt alle specialization-Elemente der zu entfernenden Generalisierungen.
    -->
    <xsl:template match="specializationEdge[.//@idref = $generalization/@id or .//@idref =
        //generalization[$superEntity/@id = superEntity/entityRef/@idref]/@id or .//@idref =
        //generalization[$superEntity/@id = subEntities/entityRef/@idref]/@id]" mode="t2"/>
    <!--
        Kopiert den übrigen Inhalt unverändert in das Ergebnisdokument.
    -->
    <xsl:template match="@* | node()" mode="t2">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>
