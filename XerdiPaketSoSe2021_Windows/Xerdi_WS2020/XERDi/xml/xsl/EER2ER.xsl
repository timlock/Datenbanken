<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY eer 'http://www.informatik.uni-oldenburg.de/2006/EER-Designer/EER'>
    <!ENTITY func 'http://www.informatik.uni-oldenburg.de/2006/EER-Designer/XSLT-Functions'>
]>
<!--
    Das Stylesheet wandelt eine Generalisierung in einem EER-Diagramm in entsprechende
    Konstrukte des einfachen ER-Modells um. Als Eingabe erwartet das Stylesheet ein
    XML-Dokument, welches gültig ist bezüglich des XML-Schemas für (E)ER-Diagramme;
    als Ausgabe liefert es ein XML-Dokument desselben Schemas. Da das resultierende
    Diagramm nicht nur als Eingabe für weitere Transformationsschritte genutzt, sondern
    dem Benutzer auf Wunsch auch angezeigt werden soll, muss das Stylesheet auch den
    view-Teil des Dokuments korrekt bearbeiten.
    
    Über den Parameter generalizationId wird die ID der umzuwandelnden Generalisierung
    übergeben. Das Stylesheet prüft zunächst, welche Option für die Restrukturierung
    verwendet werden soll, und verzweigt auf Grund dessen in eines der inkludierten
    Stylesheets.
    
    @param generilzationId die ID der umzuwandelnden Generalisierung
-->
<xsl:stylesheet xmlns="&eer;" xmlns:eer="&eer;" xmlns:func="&func;"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:saxon="http://saxon.sf.net/" xpath-default-namespace="&eer;"
    extension-element-prefixes="saxon" exclude-result-prefixes="eer func xs" version="2.0">
    <!-- OUTPUT -->
    <xsl:output encoding="UTF-8" method="xml" saxon:indent-spaces="4"/>
    <xsl:strip-space elements="*"/>
    <xsl:preserve-space elements="name description text"/>
    <!-- INCLUDES -->
    <xsl:include href="EER2ER0.xsl"/>
    <xsl:include href="EER2ER1.xsl"/>
    <xsl:include href="EER2ER2.xsl"/>
    <xsl:include href="EER2ER3.xsl"/>
    <xsl:include href="EER2ER4.xsl"/>
    <!-- PARAMETERS -->
    <xsl:param name="generalizationId" as="xs:nonNegativeInteger" required="yes"/>
    <!-- VARIABLES -->
    <!-- generalization-Element der umzuwandelnden Generalisierung -->
    <xsl:variable name="generalization" select="//generalization[@id = $generalizationId]"/>
    <!-- entity-Element des Superentitätstyps der umzuwandelnen Generalisierung -->
    <xsl:variable name="superEntity"
        select="//entity[@id=$generalization/superEntity/entityRef/@idref]"/>
    <!-- entity-Elemente der Subentitätstypen der umzuwandelnden Generalisierung -->
    <xsl:variable name="subEntities"
        select="//entity[@id=$generalization/subEntities/entityRef/@idref]"/>
    <!-- XPath-Dokumentknoten -->
    <xsl:variable name="root" select="/"/>
    <!-- Nächste freie ID -->
    <xsl:variable name="nextId" select="xs:integer(max(//@id) + 1)" as="xs:integer"
        saxon:assignable="yes"/>
    <!-- FUNCTIONS -->
    <!--
        Generiert eine neue ID. Die Funktion garantiert, dass die ID noch nicht vergeben ist.
        Die Rückgabe erfolgt bereits in formatierter Form (0-Padding auf 5 Stellen).
        
        @return neue ID in formatierter Form
    -->
    <xsl:function name="func:generate-id" as="xs:string">
        <xsl:value-of select="format-number($nextId, '00000')"/>
        <saxon:assign name="nextId" select="$nextId+1"/>
    </xsl:function>
    <!--
        Ersetzt eine bestimmte ID in einem Node-Set durch eine andere. Auch Referenzen
        auf diese ID werden ersetzt.
        
        @param nodes Node-Set
        @param id zu ersetzende ID
        @param newId neue ID
        @return Node-Set
    -->
    <xsl:function name="func:replace-id">
        <xsl:param name="nodes"/>
        <xsl:param name="id"/>
        <xsl:param name="newId"/>
        <xsl:for-each select="$nodes">
            <xsl:choose>
                <xsl:when test="(name() = 'id' or name() = 'idref') and . = $id">
                    <xsl:attribute name="{name()}">
                        <xsl:value-of select="$newId"/>
                    </xsl:attribute>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:copy>
                        <xsl:copy-of select="func:replace-id(@* | node(), $id, $newId)"/>
                    </xsl:copy>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
    </xsl:function>
    <!--
        Ersetzt in einem Node-Set alle IDs, die kleiner oder gleich der angegebenen
        maximalen ID sind, durch neue. Referenzen werden dabei korrekt berücksichtigt.
        Die Funktion dient als Hilfsfunktion für die Funktion func:replace-all-ids, damit die
        Rekursion abbricht, wenn alle IDs einmal ersetzt wurden.
        
        @param nodes Node-Set
        @param maxId maximale zu ersetzende ID
        @return Node-Set
    -->
    <xsl:function name="func:replace-ids">
        <xsl:param name="nodes"/>
        <xsl:param name="maxId"/>
        <xsl:choose>
            <xsl:when test="min($nodes//@id) > $maxId">
                <xsl:copy-of select="$nodes"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy-of select="func:replace-ids(func:replace-id($nodes, min($nodes//@id),
                    func:generate-id()), $maxId)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    <!--
        Ersetzt in einem Node-Set alle IDs durch neue. Referenzen werden dabei
        korrekt berücksichtigt.
        
        @param nodes Node-Set
        @return Node-Set
    -->
    <xsl:function name="func:replace-all-ids">
        <xsl:param name="nodes"/>
        <xsl:choose>
            <xsl:when test="empty($nodes//@id)">
                <xsl:copy-of select="$nodes"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy-of select="func:replace-ids($nodes, max($nodes//@id))"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    <!--
        Liefert die x-Koordinate eines Diagramm-Objekts.
        
        @param id ID des Objekts
        @return x-Koordinate des Objekts
    -->
    <xsl:function name="func:getX" as="xs:double">
        <xsl:param name="id"/>
        <xsl:value-of select="$root//node[@idref = $id]/pointAnchor/@x"/>
    </xsl:function>
    <!--
        Liefert die y-Koordinate eines Diagramm-Objekts.
        
        @param id ID des Objekts
        @return y-Koordinate des Objekts
    -->
    <xsl:function name="func:getY" as="xs:double">
        <xsl:param name="id"/>
        <xsl:value-of select="$root//node[@idref = $id]/pointAnchor/@y"/>
    </xsl:function>
    <!--
        Liefert zu einer ID den model-Elementknoten.
        
        @param id ID des Objekts
        @return model-Elementknoten
    -->
    <xsl:function name="func:getObject">
        <xsl:param name="id"/>
        <xsl:sequence select="$root//node()[@id = $id]"/>
    </xsl:function>
    <!--
        Prüft, ob eine bestimmte ID zu einem Attribut gehört.
        
        @param id zu überprüfende ID
        @return true, wenn die ID zu einem Attribut gehört
    -->
    <xsl:function name="func:isAttribute" as="xs:boolean">
        <xsl:param name="id"/>
        <xsl:value-of select="exists($root//attribute[@id = $id])"/>
    </xsl:function>
    <!--
        Liefert die ID des "Besitzers" des Objekts mit der übergebenen ID. Diese Funktion
        ist dafür gedacht, zu einem Attribut den zugehörigen Entitäts- oder Beziehungstyp
        ausfindig zu machen.
        
        @param id ID des Attributs
        @return ID des "Besitzers"
    -->
    <xsl:function name="func:getOwner">
        <xsl:param name="id"/>
        <xsl:variable name="id_Parent" select="$root//node()[attributes/attributeRef/@idref =
            $id]/@id"/>
        <xsl:value-of select="if(func:isAttribute($id_Parent)) then func:getOwner($id_Parent) else
            $id_Parent"/>
    </xsl:function>
    <!--
        Liefert die IDs aller direkten Kind-Attribute eines Objekts. Kind-Attribut meint dabei,
        dass das Objekt direkt mit dem Attribut verbunden ist.
        
        @param id ID des Objekts
        @return IDs der Kind-Attribute
    -->
    <xsl:function name="func:getChildAttributes">
        <xsl:param name="id"/>
        <xsl:sequence select="$root//node()[@id = $id]/attributes/attributeRef/@idref"/>
    </xsl:function>
    <!--
        Liefert die IDs aller Attribute eines Objekts. Bei komplexen Attribute werden (im
        Gegensatz zur Funktion func:getChildAttributes) auch die Komponenten-Attribute
        mitgeliefert.
        
        @param id ID des Objekts
        @return IDs der Attribute
    -->
    <xsl:function name="func:getAttributes">
        <xsl:param name="id"/>
        <xsl:variable name="id_Children" select="func:getChildAttributes($id)"/>
        <xsl:sequence select="if(exists($id_Children)) then ($id_Children, for $id_C in $id_Children
            return func:getAttributes($id_C)) else ()"/>
    </xsl:function>
    <!-- TEMPLATES -->
    <!--
        Transformiert das Wurzelelement. Für die weitere Verarbeitung wird eines der
        inkludierten Stylesheets ausgewählt, je nachdem nach welcher Option die
        Generalisierung behandelt werden soll.
    -->
    <xsl:template match="eer">
        <xsl:copy>
            <xsl:choose>
                <xsl:when test="empty($superEntity) or empty($subEntities)">
                    <xsl:apply-templates select="." mode="t0"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:choose>
                        <xsl:when test="$generalization/@transform = '1'">
                            <xsl:apply-templates select="." mode="t1"/>
                        </xsl:when>
                        <xsl:when test="$generalization/@transform = '2'">
                            <xsl:apply-templates select="." mode="t2"/>
                        </xsl:when>
                        <xsl:when test="$generalization/@transform = '3'">
                            <xsl:apply-templates select="." mode="t3"/>
                        </xsl:when>
                        <xsl:when test="$generalization/@transform = '4'">
                            <xsl:apply-templates select="." mode="t4"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:choose>
                                <xsl:when test="$generalization/@type = 'disjoint'">
                                    <xsl:apply-templates select="." mode="t3"/>
                                </xsl:when>
                                <xsl:when test="$generalization/@type = 'overlapping'">
                                    <xsl:apply-templates select="." mode="t4"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:apply-templates select="." mode="t1"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:copy>
    </xsl:template>
    <!--
        Verschiebt Objekte um eine bestimmte Anzahl an Pixeln in x- und y-Richtung.
        
        @param nodes zu verschiebende Objekte
        @param dx Verschiebung in x-Richtung
        @param dy Verschiebung in y-Richtung
    -->
    <xsl:template name="move">
        <xsl:param name="nodes" required="yes"/>
        <xsl:param name="dx" required="yes"/>
        <xsl:param name="dy" required="yes"/>
        <xsl:for-each select="$nodes">
            <xsl:copy>
                <xsl:copy-of select="@*"/>
                <pointAnchor x="{pointAnchor/@x + $dx}" y="{pointAnchor/@y + $dy}"/>
            </xsl:copy>
        </xsl:for-each>
    </xsl:template>
</xsl:stylesheet>
