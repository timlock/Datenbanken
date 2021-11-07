<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY eer 'http://www.informatik.uni-oldenburg.de/2006/EER-Designer/EER'>
    <!ENTITY rs 'http://www.informatik.uni-oldenburg.de/2006/EER-Designer/RelationalSchema'>
    <!ENTITY func 'http://www.informatik.uni-oldenburg.de/2006/EER-Designer/XSLT-Functions'>
]>
<!--
    Das Stylesheet wandelt ein ER-Diagramm in ein relationales Schema um. Das
    Stylesheet erwartet als Eingabe ein XML-Dokument, welches dem XML-Schema für
    (E)ER-Diagramme folgt, aber keine generalization-Elemente enthält. Dennoch
    vorhandene Elemente dieses Typs werden einfach ignoriert. Der view-Teil des
    Dokuments kann bei der Transformation komplett außer Acht gelassen werden, da
    darstellungsspezifische Informationen hier nicht von Interesse sind. Als Ausgabe
    erzeugt das Stylesheet ein XML-Dokument, das gültig ist bezüglich des XML-Schemas
    für relationale Schemata.
    
    Das Stylesheet arbeitet die Transformation in den sieben Schritten des Algorithmus
    von Elmasri und Navathe ab (mit der Änderung das Schritt 6 und 7 gegenüber dem
    ursprünglichen Algorithmus vertauscht wurden). Über den Parameter lastStep kann
    eine teilweise Abarbeitung erzielt werden. In diesem Fall ist das resultierende
    relationale Schema keine vollständige Repräsentation des Diagramms; in jedem Fall
    entsteht jedoch ein valides XML-Dokument, das für die Weiterverarbeitung geeignet ist.
    
    @param lastStep der letzte auszuführender Schritt
    @param genAutoKeys true, wenn Auto-Keys generiert werden sollen
-->
<xsl:stylesheet xmlns="&rs;" xmlns:eer="&eer;" xmlns:rs="&rs;" xmlns:func="&func;"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:saxon="http://saxon.sf.net/" xpath-default-namespace="&eer;"
    extension-element-prefixes="saxon" exclude-result-prefixes="eer rs func xs" version="2.0">
    <!-- OUTPUT -->
    <xsl:output encoding="UTF-8" method="xml" saxon:indent-spaces="4"/>
    <xsl:strip-space elements="*"/>
    <xsl:preserve-space elements="name comment authorization"/>
    <!-- PARAMETERS -->
    <xsl:param name="lastStep" as="xs:integer" required="no" select="7"/>
    <xsl:param name="genAutoKeys" as="xs:boolean" required="no" select="true()"/>
    <!-- VARIABLES -->
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
        Prüft, ob eine bestimmte ID zu einem Entitätstyp gehört.
        
        @param id zu überprüfende ID
        @return true, wenn die ID zu einem Entitätstyp gehört
    -->
    <xsl:function name="func:isEntity" as="xs:boolean">
        <xsl:param name="id"/>
        <xsl:value-of select="exists($root//entity[@id = $id])"/>
    </xsl:function>
    <!--
        Prüft, ob eine bestimmte ID zu einem Beziehungstyp gehört.
        
        @param id zu überprüfende ID
        @return true, wenn die ID zu einem Beziehungstyp gehört
    -->
    <xsl:function name="func:isRelationship" as="xs:boolean">
        <xsl:param name="id"/>
        <xsl:value-of select="exists($root//relationship[@id = $id])"/>
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
        Prüft, ob eine bestimmte ID zu einem Primärschlüssel-Attribut gehört.
        
        @param id zu überprüfende ID
        @return true, wenn die ID zu einem Primärschlüssel-Attribut gehört
    -->
    <xsl:function name="func:isPrimaryKey" as="xs:boolean">
        <xsl:param name="id"/>
        <xsl:value-of select="func:isAttribute($id) and $root//attribute[@id = $id]/@key =
            'primary'"/>
    </xsl:function>
    <!--
        Prüft, ob eine bestimmte ID zu einem mehrwertigen Attribut gehört.
        
        @param id zu überprüfende ID
        @return true, wenn die ID zu einem mehrwertigen Attribut gehört
    -->
    <xsl:function name="func:isMultivalued" as="xs:boolean">
        <xsl:param name="id"/>
        <xsl:value-of select="func:isAttribute($id) and xs:boolean($root//attribute[@id =
            $id]/@multivalued)"/>
    </xsl:function>
    <!--
        Prüft, ob eine bestimmte ID zu einem komplexen Attribut gehört.
        
        @param id zu überprüfende ID
        @return true, wenn die ID zu einem komplexen Attribut gehört
    -->
    <xsl:function name="func:isComplex" as="xs:boolean">
        <xsl:param name="id"/>
        <xsl:value-of select="exists($root//attribute[@id = $id]/attributes)"/>
    </xsl:function>
    <!--
        Prüft, ob eine bestimmte ID zu einem freien Attribut gehört. Ein freies Attribut sei
        dabei ein Attribut, welches an keinen Entitätstyp oder Beziehungstyp gebunden ist
        (auch nicht indirekt über andere Attribute).
        
        @param id zu überprüfende ID
        @return true, wenn die ID zu einem freien Attribut gehört
    -->
    <xsl:function name="func:isFree" as="xs:boolean">
        <xsl:param name="id"/>
        <xsl:variable name="id_Parent" select="$root//node()[attributes/attributeRef/@idref =
            $id]/@id"/>
        <xsl:value-of select="if (exists($id_Parent)) then (if (func:isAttribute($id_Parent)) then
            func:isFree($id_Parent) else false()) else true()"/>
    </xsl:function>
    <!--
        Prüft, ob eine bestimmte ID zu einem Attribut gehört, welches Teil eines komplexen
        mehrwertigen Attributs ist.
        
        @param id zu überprüfende ID
        @return true, wenn die ID zu einem Attribut gehört, für das die Bedingung erfüllt ist
    -->
    <xsl:function name="func:hasMultivaluedAncestor" as="xs:boolean">
        <xsl:param name="id"/>
        <xsl:variable name="id_Parent" select="$root//attribute[attributes/attributeRef/@idref =
            $id]/@id"/>
        <xsl:value-of select="if (exists($id_Parent)) then (if (func:isMultivalued($id_Parent)) then
            true() else func:hasMultivaluedAncestor($id_Parent)) else false()"/>
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
        <xsl:value-of select="if (func:isAttribute($id_Parent)) then func:getOwner($id_Parent) else
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
        Liefert die IDs aller einfachen Attribute eines Objekts. Bei komplexen Attributen werden
        nur die Komponenten-Attribute mitgeliefert.
        
        @param id ID des Objekts
        @return IDs der einfachen Attribute
    -->
    <xsl:function name="func:getSimpleAttributes">
        <xsl:param name="id"/>
        <xsl:variable name="id_Children" select="func:getChildAttributes($id)"/>
        <xsl:sequence select="for $id_C in $id_Children return if (func:isComplex($id_C)) then
            func:getSimpleAttributes($id_C) else $id_C"/>
    </xsl:function>
    <!--
        Liefert die IDs aller einfachen, einwertigen Attribute eines Objekts. Bei komplexen,
        nicht-mehrwertigen Attribute werden nur die Komponenten-Attribute mitgeliefert.
        
        @param id ID des Objekts
        @return IDs der einfachen, einwertigen Attribute
    -->
    <xsl:function name="func:getNormalAttributes">
        <xsl:param name="id"/>
        <xsl:variable name="id_Children" select="for $id_C in func:getChildAttributes($id) return
            if (not(func:isMultivalued($id_C))) then $id_C else ()"/>
        <xsl:sequence select="for $id_C in $id_Children return if (func:isComplex($id_C)) then
            func:getNormalAttributes($id_C) else $id_C"/>
    </xsl:function>
    <!--
        Liefert die IDs aller mehrwertigen Attribute eines Objekts. Bei komplexen,
        mehrwertigen Attributen wird das komplexe Attribut und nicht die Komponenten-Attribute
        mitgeliefert.
        
        @param id ID des Objekts
        @return IDs der mehrwertigen Attribute
    -->
    <xsl:function name="func:getMultivaluedAttributes">
        <xsl:param name="id"/>
        <xsl:variable name="id_Children" select="func:getChildAttributes($id)"/>
        <xsl:sequence select="for $id_C in $id_Children return if (func:isMultivalued($id_C)) then
            $id_C else (if (func:isComplex($id_C)) then func:getMultivaluedAttributes($id_C) else
            ())"/>
    </xsl:function>
    <!--
        Liefert die IDs aller einfachen, einwertigen Attribute eines Objekts, die nicht als
        Primärschlüssel ausgezeichnet sind.
        
        @param id ID des Objekts
        @return IDs der einfachen, einwertigen Primärschlüssel-Attribute
    -->
    <xsl:function name="func:getNonPrimaryKeyAttributes">
        <xsl:param name="id"/>
        <xsl:variable name="id_Children" select="for $id_C in func:getChildAttributes($id) return if
            (not(func:isMultivalued($id_C)) and not(func:isPrimaryKey($id_C))) then $id_C else ()"/>
        <xsl:sequence select="for $id_C in $id_Children return if (func:isComplex($id_C)) then
            func:getNonPrimaryKeyAttributes($id_C) else $id_C"/>
    </xsl:function>
    <!--
        Liefert die IDs aller einfachen, einwertigen Attribute eines Objekts, die als
        Primärschlüssel ausgezeichnet sind.
        
        @param id ID des Objekts
        @return IDs der einfachen, einwertigen Primärschlüssel-Attribute
    -->
    <xsl:function name="func:getPrimaryKeyAttributes">
        <xsl:param name="id"/>
        <xsl:variable name="id_Children" select="for $id_C in func:getChildAttributes($id) return
            if (not(func:isMultivalued($id_C))) then $id_C else ()"/>
        <xsl:sequence select="for $id_C in $id_Children return if (func:isComplex($id_C)) then (if
            (func:isPrimaryKey($id_C)) then func:getNormalAttributes($id_C) else
            func:getPrimaryKeyAttributes($id_C)) else (if (func:isPrimaryKey($id_C)) then $id_C else
            ())"/>
    </xsl:function>
    <!--
        Prüft, ob eine bestimmte ID zu einem relevanten identifizierenden Beziehungstyp
        gehört. Für die Entscheidung, ob ein identifizierender Beziehungstyp relevant ist, gelten
        dieselben Bedingungen wie bei der Funktion func:getIdentifyingRelationships.
        
        @see func:getIdentifyingRelationships
        @param id zu überprüfende ID
        @return true, wenn die ID zu einem identifizierenden Beziehungstyp gehört
    -->
    <xsl:function name="func:isIdentifying" as="xs:boolean">
        <xsl:param name="id"/>
        <xsl:value-of select="$id = (for $e in $root//entity[xs:boolean(@weak)] return
            func:getIdentifyingRelationships($e/@id))"/>
    </xsl:function>
    <!--
        Hilfsfunktion für die Funktion func:isCycling.
        
        @see func:isCycling.
        @param id_R ID des aktuell zu behandelnden Beziehungstyps
        @param id_E ID des aktuell zu behandelnden Entitätstyps
        @param id_R0 ID des Beziehungstyps, der Ausgangspunkt der Überprüfung war
        @param id_Rs IDs der bereits behandelten Beziehungstypen
        @return true oder false
    -->
    <xsl:function name="func:isCyclingWith" as="xs:boolean">
        <xsl:param name="id_R"/>
        <xsl:param name="id_E"/>
        <xsl:param name="id_R0"/>
        <xsl:param name="id_Rs"/>
        <xsl:variable name="relationship" select="func:getObject($id_R)"/>
        <xsl:variable name="id_Parents" select="$relationship/participatingEntities/entityRef[@idref
            != $id_E]/@idref | (if (count($relationship/participatingEntities/entityRef[@id =
            $id_E]) > 1) then $id_E else ())"/>
        <xsl:value-of select="not($id_R = $id_Rs) and ($id_R = $id_R0 or (some $id_P in $id_Parents
            satisfies (some $id_R2 in func:getAllIdentifyingRelationships($id_P) satisfies
            func:isCyclingWith($id_R2, $id_P, $id_R0, ($id_Rs, $id_R)))))"/>
    </xsl:function>
    <!--
        Prüft, ob der identifizierende Beziehungstyp mit der übergebenen ID den Entitätstyp
        mit der übergebenen ID innerhalb eines Zyklus identifiziert. Ein Zyklus liegt z.B. vor,
        wenn der Entitätstyp E1 durch den Beziehungstyp R1 identifiziert wird, an R1 der
        Entitätstyp E2 beteiligt ist, E2 durch den Beziehungstyp R2 identifiziert wird und an
        R2 der Entitätstyp E1 teilnimmt.
        
        @param id_R ID des Beziehungstyps
        @param id_E ID des Entitätstyps
        @return true, wenn der Beziehungstyp den Entitätstyp zyklisch identifiziert
    -->
    <xsl:function name="func:isCycling" as="xs:boolean">
        <xsl:param name="id_R"/>
        <xsl:param name="id_E"/>
        <xsl:variable name="relationship" select="func:getObject($id_R)"/>
        <xsl:variable name="id_Parents" select="$relationship/participatingEntities/entityRef[@idref
            != $id_E]/@idref | (if (count($relationship/participatingEntities/entityRef[@id =
            $id_E]) > 1) then $id_E else ())"/>
        <xsl:value-of select="some $id_P in $id_Parents satisfies (some $id_R2 in
            func:getAllIdentifyingRelationships($id_P) satisfies func:isCyclingWith($id_R2, $id_P,
            $id_R, ()))"/>
    </xsl:function>
    <!--
        Liefert die IDs aller identifizierenden Beziehungstypen, die den Entitätstyp mit der
        übergebenen ID identifizieren. Dabei werden nur solche Beziehungstypen
        berücksichtigt, an denen der Entitätstyp total und nicht mehrfach teilnimmt. Außerdem
        müssen alle übrigen Entitätstypen mit der Kardinalität 1 an dem Beziehungstyp
        teilnehmen.
        
        @param id ID des Entitätstyps
        @return IDs der identifizierenden Beziehungstypen
    -->
    <xsl:function name="func:getAllIdentifyingRelationships">
        <xsl:param name="id"/>
        <xsl:variable name="id_All" select="$root//relationship[xs:boolean(@identifying) and
            count(participatingEntities/entityRef[@idref = $id]) = 1 and
            xs:boolean(participatingEntities/entityRef[@idref = $id]/@total) and (every $e in
            participatingEntities/entityRef[@idref != $id] satisfies $e/@cardinality = '1')]/@id"/>
        <xsl:sequence select="if (func:isEntity($id) and xs:boolean($root//entity[@id = $id]/@weak))
            then $id_All else ()"/>
    </xsl:function>
    <!--
        Liefert die IDs aller relevanten identifizierenden Beziehungstypen, die den Entitätstyp
        mit der übergebenen ID identifizieren. Als relevant gelten dabei nur solche
        identifizierende Beziehungstypen, die nicht in einen Zyklus eingebunden sind.
        
        @see func:isCycling
        @param id ID des Entitätstyps
        @return IDs der relevanten identifizierenden Beziehungstypen
    -->
    <xsl:function name="func:getIdentifyingRelationships">
        <xsl:param name="id"/>
        <xsl:variable name="id_All" select="func:getAllIdentifyingRelationships($id)"/>
        <xsl:variable name="id_Relevant" select="for $id_R in $id_All return (if
            (func:isCycling($id_R, $id)) then () else $id_R)"/>
        <xsl:sequence select="if (func:isEntity($id) and xs:boolean($root//entity[@id = $id]/@weak))
            then $id_Relevant else ()"/>
    </xsl:function>
    <!--
        Liefert die IDs aller Vater-Entitätstypen des Entitätstyps mit der übergebenen ID. Als
        Vater-Entitätstypen gelten dabei alle Entitätstypen, die mit dem Entitätstyp über einen
        relevanten identifizierenden Beziehungstyp verbunden sind. Für die Entscheidung, ob
        ein identifizierender Beziehungstyp relevant ist, gelten dieselben Bedingungen wie bei
        der Funktion func:getIdentifyingRelationships.
        
        @see func:getIdentifyingRelationships
        @param id ID des Entitätstyps
        @return IDs der Vater-Entitätstypen
    -->
    <xsl:function name="func:getParentEntities">
        <xsl:param name="id"/>
        <xsl:sequence select="$root//entity[@id != $id and @id = $root//relationship[@id =
            func:getIdentifyingRelationships($id)]/participatingEntities/entityRef/@idref]/@id"/>
    </xsl:function>
    <!-- TEMPLATES -->
    <!--
        Transformiert das Wurzelelement.
    -->
    <xsl:template match="eer">
        <schema>
            <xsl:apply-templates select="head"/>
            <xsl:apply-templates select="model"/>
        </schema>
    </xsl:template>
    <!--
        Transformiert den Kopf des Dokuments.
    -->
    <xsl:template match="head">
        <head>
            <xsl:apply-templates select="name"/>
            <xsl:apply-templates select="description"/>
        </head>
    </xsl:template>
    <!--
        Transformiert den Namen des Diagramms.
    -->
    <xsl:template match="head/name">
        <name>
            <xsl:value-of select="text()"/>
        </name>
    </xsl:template>
    <!--
        Transformiert die Beschreibung des Diagramms.
    -->
    <xsl:template match="head/description">
        <comment>
            <xsl:value-of select="text()"/>
        </comment>
    </xsl:template>
    <!--
        Transformiert den model-Teil des Dokuments. An dieser Stelle findet sich die
        Umsetzung der sieben Schritte des Algorithmus. Jeder Schritt ist durch ein eigenes
        Template realisiert, deren Ausführung hier angestoßen wird. Vor jedem Schritt wird
        geprüft, ob dieser ausgeführt werden soll. Dies erfolgt durch Auswertung des
        Parameters lastStep.
        
        Das aus der Ausführung der einzelnen Templates resultierende Ergebnis bedarf noch
        einer Nachbearbeitung. Das Ergebnis aus der Abarbeitung der einzelnen Schritte wird
        an die Template-Regel merge übergeben. Deren Aufgabe ist es, Relationsschemata
        mit gleicher ID zu einem einzigen Schema zu vereinigen. Die Existenz von
        Relationsschemata mit gleicher ID resultiert aus der getrennten Behandlung der
        einzelnen Schritte.
        
        Schließlich wird das Template resolveNameConflicts aufgerufen, um Nameskonflikte
        aufzulösen.
    -->
    <xsl:template match="model">
        <body>
            <xsl:call-template name="resolveNameConflicts">
                <xsl:with-param name="relations">
                    <xsl:call-template name="merge">
                        <xsl:with-param name="relations">
                            <!-- Schritte 1 bis $lastStep ausführen -->
                            <xsl:if test="$lastStep &gt;= 1">
                                <xsl:apply-templates select="entity[not(xs:boolean(@weak))]"/>
                            </xsl:if>
                            <xsl:if test="$lastStep &gt;= 2">
                                <xsl:apply-templates select="entity[xs:boolean(@weak)]"/>
                            </xsl:if>
                            <xsl:if test="$lastStep &gt;= 3">
                                <xsl:apply-templates
                                    select="relationship[count(participatingEntities/entityRef) = 2
                                    and (every $e in participatingEntities/entityRef satisfies
                                    $e/@cardinality = '1')]"/>
                            </xsl:if>
                            <xsl:if test="$lastStep &gt;= 4">
                                <xsl:apply-templates
                                    select="relationship[count(participatingEntities/entityRef) = 2
                                    and (some $e in participatingEntities/entityRef satisfies
                                    $e/@cardinality = '1') and (some $e in
                                    participatingEntities/entityRef satisfies $e/@cardinality !=
                                    '1')]"/>
                            </xsl:if>
                            <xsl:if test="$lastStep &gt;= 5">
                                <xsl:apply-templates
                                    select="relationship[count(participatingEntities/entityRef) = 2
                                    and (every $e in participatingEntities/entityRef satisfies
                                    $e/@cardinality != '1')]"/>
                            </xsl:if>
                            <xsl:if test="$lastStep &gt;= 6">
                                <xsl:apply-templates
                                    select="relationship[count(participatingEntities/entityRef)
                                    &gt; 2]"/>
                            </xsl:if>
                            <xsl:if test="$lastStep &gt;= 7">
                                <xsl:apply-templates select="attribute[@id = (for $x in (//entity |
                                    //relationship[count(participatingEntities/entityRef) &gt;=
                                    2]) return func:getMultivaluedAttributes($x/@id))]"/>
                            </xsl:if>
                        </xsl:with-param>
                    </xsl:call-template>
                </xsl:with-param>
            </xsl:call-template>
        </body>
    </xsl:template>
    <!--
        Schritt 1: Behandle starke Entitätstypen. Für jeden starken Entitätstyp E  wird ein
        Relationsschema R, das alle einfachen, einwertigen Attribute von E umfasst, erstellt.
        Zusammengesetzte Attribute werden auf ihre atomaren Komponenten reduziert und
        als solche ebenfalls dem Relationsschema R hinzugefügt. Der Primärschlüssel von
        R wird aus den Schlüsselattributen von E gebildet.
    -->
    <xsl:template match="entity[not(xs:boolean(@weak))]">
        <xsl:variable name="id" select="@id"/>
        <xsl:variable name="primaryKeyAttributes">
            <xsl:call-template name="makePrimaryKey">
                <xsl:with-param name="id" select="$id"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="otherAttributes">
            <xsl:apply-templates select="//attribute[@id = func:getNonPrimaryKeyAttributes($id)]">
                <xsl:sort select="@id"/>
            </xsl:apply-templates>
        </xsl:variable>
        <relation id="{$id}">
            <name>
                <xsl:value-of select="name"/>
            </name>
            <xsl:apply-templates select="//businessRule[@type = 'description' and @about = $id]"/>
            <attributes>
                <xsl:sequence select="$primaryKeyAttributes"/>
                <xsl:sequence select="$otherAttributes"/>
            </attributes>
            <constraints>
                <primaryKey id="{$id}">
                    <xsl:for-each select="$primaryKeyAttributes/rs:attribute">
                        <attributeRef idref="{@id}"/>
                    </xsl:for-each>
                </primaryKey>
            </constraints>
        </relation>
    </xsl:template>
    <!--
        Schritt 2: Behandle schwache Entitätstypen. Für jeden schwachen Entitätstyp W wird
        ein Relationsschema R, das alle einfachen, einwertigen Attribute (sowie die
        atomaren Komponenten der zusammengesetzten Attribute) von W enthält, erstellt. R
        wird für jeden Beziehungstyp, durch den W identifiziert wird, um Fremdschlüssel in die
        Relationsschema, die aus den zugehörigen Vater-Entitätstypen entstanden sind, ergänzt. Der
        Primärschlüssel von R bildet sich aus den Fremdschlüsseln sowie aus den partiellen
        Schlüsselattributen von W.
    -->
    <xsl:template match="entity[xs:boolean(@weak)]">
        <xsl:variable name="id" select="@id"/>
        <xsl:variable name="foreignKeys">
            <xsl:for-each select="func:getParentEntities($id)">
                <xsl:variable name="id_E" select="."/>
                <xsl:variable name="foreignKeyAttributes">
                    <xsl:call-template name="makeForeignKey">
                        <xsl:with-param name="id" select="$id_E"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:sequence select="$foreignKeyAttributes"/>
                <foreignKey id="{func:generate-id()}" references="{$id_E}" onDelete="cascade"
                    onUpdate="cascade">
                    <xsl:for-each select="$foreignKeyAttributes/rs:attribute">
                        <attributeRef idref="{@id}"/>
                    </xsl:for-each>
                </foreignKey>
            </xsl:for-each>
        </xsl:variable>
        <xsl:variable name="primaryKeyAttributes">
            <xsl:call-template name="makePrimaryKey">
                <xsl:with-param name="id" select="$id"/>
                <xsl:with-param name="partial" select="true()"/>
            </xsl:call-template>
            <xsl:sequence select="$foreignKeys/rs:attribute"/>
        </xsl:variable>
        <xsl:variable name="otherAttributes">
            <xsl:apply-templates select="//attribute[@id = func:getNonPrimaryKeyAttributes($id)]">
                <xsl:sort select="@id"/>
            </xsl:apply-templates>
        </xsl:variable>
        <relation id="{$id}">
            <name>
                <xsl:value-of select="name"/>
            </name>
            <xsl:apply-templates select="//businessRule[@type = 'description' and @about = $id]"/>
            <attributes>
                <xsl:sequence select="$primaryKeyAttributes"/>
                <xsl:sequence select="$otherAttributes"/>
            </attributes>
            <constraints>
                <primaryKey id="{$id}">
                    <xsl:for-each select="$primaryKeyAttributes/rs:attribute">
                        <attributeRef idref="{@id}"/>
                    </xsl:for-each>
                </primaryKey>
                <xsl:sequence select="$foreignKeys/rs:foreignKey"/>
            </constraints>
        </relation>
    </xsl:template>
    <!--
        Behandle identifizierende Beziehungstypen. Beziehungstypen, die bereits durch die
        Transformation im 2. Schritt berücksichtigt wurden, dürfen in den Schritten 3 - 6  nicht
        durch die normalen Transformationsregeln behandelt werden. Es müssen nur noch
        ihre Attribute dem richtigen Relationsschema hinzugefügt werden.
        
        Da hier das Relationsschema nicht unmittelbar erweitert werden kann, wird zunächst
        ein neues mit der gleichen ID erzeugt. Nach Abarbeitung aller Schritte müssen die
        Schemata zusammengeführt werden.
    -->
    <xsl:template match="relationship[func:isIdentifying(@id)]" priority="2">
        <xsl:variable name="id_R" select="@id"/>
        <xsl:variable name="id_E" select="for $e in participatingEntities/entityRef return (if
            ($id_R = func:getIdentifyingRelationships($e/@idref)) then $e/@idref else ())"/>
        <xsl:variable name="otherAttributes">
            <xsl:apply-templates select="//attribute[@id = func:getNormalAttributes($id_R)]">
                <xsl:sort select="@id"/>
            </xsl:apply-templates>
        </xsl:variable>
        <relation id="{$id_E}">
            <attributes>
                <xsl:sequence select="$otherAttributes"/>
            </attributes>
        </relation>
    </xsl:template>
    <!--
        Schritt 3: Behandle 1:1-Beziehungstypen. Für jeden binären 1:1-Beziehungstyp B
        werden die Relationschemata R1 und R2, deren zugehörige Entitätstypen an B
        beteiligt sind, identifiziert. Eines der Relationsschemata, bevorzugt eines, dessen
        korrespondierender Entitätstyp total an B teilnimmt, wird ausgewählt. Dieses wird
        ergänzt um einen Fremdschlüssel, der den Primärschlüssel des anderen
        Relationsschemas referenziert, sowie um die einfachen, einwertigen Attribute (sowie
        die atomaren Komponenten der zusammengesetzten Attribute) von B.
        
        Da hier das Relationsschema nicht unmittelbar erweitert werden kann, wird zunächst
        ein neues mit der gleichen ID erzeugt. Nach Abarbeitung aller Schritte müssen die
        Schemata zusammengeführt werden.
    -->
    <xsl:template match="relationship[count(participatingEntities/entityRef) = 2 and (every $e in
        participatingEntities/entityRef satisfies $e/@cardinality = '1')]" priority="1">
        <xsl:variable name="id_R" select="@id"/>
        <xsl:variable name="id_E1" select="if
            (xs:boolean(participatingEntities/entityRef[1]/@total)) then
            participatingEntities/entityRef[1]/@idref else
            participatingEntities/entityRef[2]/@idref"/>
        <xsl:variable name="id_E2" select="if
            (xs:boolean(participatingEntities/entityRef[1]/@total)) then
            participatingEntities/entityRef[2]/@idref else
            participatingEntities/entityRef[1]/@idref"/>
        <xsl:variable name="total" select="max(for $entityRef in participatingEntities/entityRef
            return xs:boolean($entityRef/@total))"/>
        <xsl:variable name="foreignKeyAttributes">
            <xsl:call-template name="makeForeignKey">
                <xsl:with-param name="id" select="$id_E2"/>
                <xsl:with-param name="notNull" select="$total"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="otherAttributes">
            <xsl:apply-templates select="//attribute[@id = func:getNormalAttributes($id_R)]">
                <xsl:sort select="@id"/>
            </xsl:apply-templates>
        </xsl:variable>
        <relation id="{$id_E1}">
            <attributes>
                <xsl:sequence select="$foreignKeyAttributes"/>
                <xsl:sequence select="$otherAttributes"/>
            </attributes>
            <constraints>
                <foreignKey id="{func:generate-id()}" references="{$id_E2}" onDelete="{if ($total)
                    then 'noAction' else 'setNull'}" onUpdate="cascade">
                    <xsl:for-each select="$foreignKeyAttributes/rs:attribute">
                        <attributeRef idref="{@id}"/>
                    </xsl:for-each>
                </foreignKey>
            </constraints>
        </relation>
    </xsl:template>
    <!--
        Schritt 4: Behandle 1:N-Beziehungstypen. Für jeden binären 1:N-Beziehungstyp B
        wird das Relationsschema R1, das aus dem N-seitigen Entitätstyp entstanden ist,
        identifiziert. R1 wird um einen Fremdschlüssel ergänzt, der den Primärschlüssel des
        Relationsschemas R2 referenziert, das den zweiten an B beteiligten Entitätstyp
        repräsentiert. Füge des Weiteren alle einfachen, einwertigen Attribute (sowie die
        atomaren Komponenten der zusammengesetzten Attribute) von B zu R1 hinzu.
        
        Da hier das Relationsschema nicht unmittelbar erweitert werden kann, wird zunächst
        ein neues mit der gleichen ID erzeugt. Nach Abarbeitung aller Schritte müssen die
        Schemata zusammengeführt werden.
    -->
    <xsl:template match="relationship[count(participatingEntities/entityRef) = 2 and (some $e in
        participatingEntities/entityRef satisfies $e/@cardinality = '1') and (some $e in
        participatingEntities/entityRef satisfies $e/@cardinality != '1')]" priority="1">
        <xsl:variable name="id_R" select="@id"/>
        <xsl:variable name="id_E1" select="participatingEntities/entityRef[@cardinality !=
            '1']/@idref"/>
        <xsl:variable name="id_E2" select="participatingEntities/entityRef[@cardinality =
            '1']/@idref"/>
        <xsl:variable name="total" select="max(for $entityRef in participatingEntities/entityRef
            return xs:boolean($entityRef/@total))"/>
        <xsl:variable name="foreignKeyAttributes">
            <xsl:call-template name="makeForeignKey">
                <xsl:with-param name="id" select="$id_E2"/>
                <xsl:with-param name="notNull" select="$total"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="otherAttributes">
            <xsl:apply-templates select="//attribute[@id = func:getNormalAttributes($id_R)]">
                <xsl:sort select="@id"/>
            </xsl:apply-templates>
        </xsl:variable>
        <relation id="{$id_E1}">
            <attributes>
                <xsl:sequence select="$foreignKeyAttributes"/>
                <xsl:sequence select="$otherAttributes"/>
            </attributes>
            <constraints>
                <foreignKey id="{func:generate-id()}" references="{$id_E2}" onDelete="{if ($total)
                    then 'noAction' else 'setNull'}" onUpdate="cascade">
                    <xsl:for-each select="$foreignKeyAttributes/rs:attribute">
                        <attributeRef idref="{@id}"/>
                    </xsl:for-each>
                </foreignKey>
            </constraints>
        </relation>
    </xsl:template>
    <!--
        Schritt 5: Behandle M:N-Beziehungstypen. Für jeden binären M:N-Beziehungstyp B wird ein
        Relationsschema R erstellt, das als Fremdschlüssel die Primärschlüssel der
        Relationsschemata, die aus den an B beteiligten Entitätstypen entstanden sind, beinhaltet.
        Zudem wird R um die einfachen, einwertigen Attribute (sowie die atomaren Komponenten der
        zusammengesetzten Attribute) von B ergänzt. Der Primärschlüssel von R bildet sich aus den
        Fremdschlüsselattributen.
    -->
    <xsl:template match="relationship[count(participatingEntities/entityRef) = 2 and (every $e in
        participatingEntities/entityRef satisfies $e/@cardinality != '1')]" priority="1">
        <xsl:variable name="id_R" select="@id"/>
        <xsl:variable name="id_E1" select="participatingEntities/entityRef[1]/@idref"/>
        <xsl:variable name="id_E2" select="participatingEntities/entityRef[2]/@idref"/>
        <xsl:variable name="foreignKeyAttributes_E1">
            <xsl:call-template name="makeForeignKey">
                <xsl:with-param name="id" select="$id_E1"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="foreignKeyAttributes_E2">
            <xsl:call-template name="makeForeignKey">
                <xsl:with-param name="id" select="$id_E2"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="primaryKeyAttributes">
            <xsl:sequence select="$foreignKeyAttributes_E1| $foreignKeyAttributes_E2"/>
        </xsl:variable>
        <xsl:variable name="otherAttributes">
            <xsl:apply-templates select="//attribute[@id = func:getNormalAttributes($id_R)]">
                <xsl:sort select="@id"/>
            </xsl:apply-templates>
        </xsl:variable>
        <relation id="{$id_R}">
            <name>
                <xsl:value-of select="name"/>
            </name>
            <xsl:apply-templates select="//businessRule[@type = 'description' and @about = $id_R]"/>
            <attributes>
                <xsl:sequence select="$foreignKeyAttributes_E1"/>
                <xsl:sequence select="$foreignKeyAttributes_E2"/>
                <xsl:sequence select="$otherAttributes"/>
            </attributes>
            <constraints>
                <primaryKey id="{$id_R}">
                    <xsl:for-each select="$primaryKeyAttributes/rs:attribute">
                        <attributeRef idref="{@id}"/>
                    </xsl:for-each>
                </primaryKey>
                <foreignKey id="{func:generate-id()}" references="{$id_E1}" onDelete="cascade"
                    onUpdate="cascade">
                    <xsl:for-each select="$foreignKeyAttributes_E1/rs:attribute">
                        <attributeRef idref="{@id}"/>
                    </xsl:for-each>
                </foreignKey>
                <foreignKey id="{func:generate-id()}" references="{$id_E2}" onDelete="cascade"
                    onUpdate="cascade">
                    <xsl:for-each select="$foreignKeyAttributes_E2/rs:attribute">
                        <attributeRef idref="{@id}"/>
                    </xsl:for-each>
                </foreignKey>
            </constraints>
        </relation>
    </xsl:template>
    <!--
        Schritt 6: Behandle n-äre Beziehungstypen. Für jeden Beziehungstyp B, dessen Grad größer als
        2 ist, wird vein Relationsschema R erstellt, das als Fremdschlüssel die Primärschlüssel
        aller Relationsschemata, die aus den an B beteiligten Entitätstypen entstanden sind,
        beinhaltet. Zudem wird R um die einfachen, einwertigen Attribute (sowie die atomaren
        Komponenten der zusammengesetzten Attribute) von B ergänzt. Der Primärschlüssel von R wird
        aus den Fremdschlüsseln in die Relationsschemata gebildet, die aus Entitätstypen entstanden
        sind, die nicht mit der Kardinalität 1 an B teilnehmen. Sind alle Entitätstypen mit der
        Kardinalität 1 beteiligt, so wird ein beliebiger Fremdschlüssel als Primärschlüssel von R
        gewählt.
    -->
    <xsl:template match="relationship[count(participatingEntities/entityRef) &gt; 2]"
        priority="1">
        <xsl:variable name="id_R" select="@id"/>
        <xsl:variable name="foreignKeys">
            <xsl:for-each select="participatingEntities/entityRef">
                <xsl:variable name="id_E" select="@idref"/>
                <xsl:variable name="foreignKeyAttributes">
                    <xsl:call-template name="makeForeignKey">
                        <xsl:with-param name="id" select="$id_E"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:sequence select="$foreignKeyAttributes"/>
                <foreignKey id="{func:generate-id()}" references="{$id_E}" onDelete="cascade"
                    onUpdate="cascade">
                    <xsl:for-each select="$foreignKeyAttributes/rs:attribute">
                        <attributeRef idref="{@id}"/>
                    </xsl:for-each>
                </foreignKey>
            </xsl:for-each>
        </xsl:variable>
        <xsl:variable name="primaryKeyAttributes">
            <xsl:for-each select="participatingEntities/entityRef[@cardinality != '1']">
                <xsl:variable name="id_E" select="@idref"/>
                <xsl:sequence select="$foreignKeys/rs:attribute[@id =
                    $foreignKeys/rs:foreignKey[@references = $id_E]/rs:attributeRef/@idref]"/>
            </xsl:for-each>
            <xsl:if test="empty(participatingEntities/entityRef[@cardinality != '1'])">
                <xsl:sequence select="$foreignKeys/rs:attribute[@id =
                    $foreignKeys/rs:foreignKey[1]/rs:attributeRef/@idref]"/>
            </xsl:if>
        </xsl:variable>
        <xsl:variable name="otherAttributes">
            <xsl:apply-templates select="//attribute[@id = func:getNormalAttributes($id_R)]">
                <xsl:sort select="@id"/>
            </xsl:apply-templates>
        </xsl:variable>
        <relation id="{$id_R}">
            <name>
                <xsl:value-of select="name"/>
            </name>
            <xsl:apply-templates select="//businessRule[@type = 'description' and @about = $id_R]"/>
            <attributes>
                <xsl:sequence select="$foreignKeys/rs:attribute"/>
                <xsl:sequence select="$otherAttributes"/>
            </attributes>
            <constraints>
                <primaryKey id="{$id_R}">
                    <xsl:for-each select="$primaryKeyAttributes/rs:attribute">
                        <attributeRef idref="{@id}"/>
                    </xsl:for-each>
                </primaryKey>
                <xsl:sequence select="$foreignKeys/rs:foreignKey"/>
            </constraints>
        </relation>
    </xsl:template>
    <!--
        Schritt 7: Behandle mehrwertige Attribute. Für jedes mehrwertige Attribut A wird ein
        Relationsschema R, das das Attribut A oder, falls A zusammengesetzt ist, die atomaren
        Komponenten von A enthält. Ergänze R außerdem um einen Fremdschlüssel, der den
        Primärschlüssel des Relationsschemas, das aus dem A besitzenden Entitäts- oder Beziehungstyp
        entstanden ist, referenziert. Der Primärschlüssel von R bildet sich als allen Attributen von R.
    -->
    <xsl:template match="attribute[xs:boolean(@multivalued)]" priority="2">
        <xsl:variable name="id_A" select="@id"/>
        <xsl:variable name="id_Relation">
            <xsl:variable name="owner" select="func:getObject(func:getOwner($id_A))"/>
            <xsl:for-each select="$owner">
                <!-- Es gibt nur einen Besitzer; Schleife wird nur zum Setzen des Kontext-Knotens benötigt  -->
                <xsl:choose>
                    <xsl:when test="func:isEntity(@id)">
                        <xsl:value-of select="@id"/>
                    </xsl:when>
                    <xsl:when test="func:isIdentifying(@id)">
                        <xsl:value-of select="for $e in participatingEntities/entityRef return
                            (if (@id = func:getIdentifyingRelationships($e/@idref)) then $e/@idref
                            else ())"/>
                    </xsl:when>
                    <xsl:when test="count(participatingEntities/entityRef) = 2 and (every $e in
                        participatingEntities/entityRef satisfies $e/@cardinality = '1')">
                        <xsl:value-of select="if
                            (xs:boolean(participatingEntities/entityRef[1]/@total)) then
                            participatingEntities/entityRef[1]/@idref else
                            participatingEntities/entityRef[2]/@idref"/>
                    </xsl:when>
                    <xsl:when test="count(participatingEntities/entityRef) = 2 and (some $e in
                        participatingEntities/entityRef satisfies $e/@cardinality = '1') and (some
                        $e in participatingEntities/entityRef satisfies $e/@cardinality != '1')">
                        <xsl:value-of select="participatingEntities/entityRef[@cardinality !=
                            '1']/@idref"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="@id"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
        </xsl:variable>
        <xsl:variable name="foreignKeyAttributes">
            <xsl:variable name="object" select="func:getObject($id_Relation)"/>
            <xsl:for-each select="$object">
                <!-- Schleife wird nur zum Setzen des Kontext-Knotens benötigt  -->
                <xsl:choose>
                    <xsl:when test="func:isEntity(@id)">
                        <xsl:call-template name="makeForeignKey">
                            <xsl:with-param name="id" select="@id"/>
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:when test="count(participatingEntities/entityRef) = 2">
                        <xsl:for-each select="participatingEntities/entityRef">
                            <xsl:call-template name="makeForeignKey">
                                <xsl:with-param name="id" select="@idref"/>
                            </xsl:call-template>
                        </xsl:for-each>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:choose>
                            <xsl:when test="exists(participatingEntities/entityRef[@cardinality !=
                                '1'])">
                                <xsl:for-each select="participatingEntities/entityRef[@cardinality
                                    != '1']">
                                    <xsl:call-template name="makeForeignKey">
                                        <xsl:with-param name="id" select="@idref"/>
                                    </xsl:call-template>
                                </xsl:for-each>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:call-template name="makeForeignKey">
                                    <xsl:with-param name="id"
                                        select="participatingEntities/entityRef[1]/@idref"/>
                                </xsl:call-template>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
        </xsl:variable>
        <xsl:variable name="theAttributes">
            <xsl:apply-templates select="//attribute[@id = (if (func:isComplex($id_A)) then
                func:getSimpleAttributes($id_A) else $id_A)]" mode="asAttribute">
                <xsl:sort select="@id"/>
            </xsl:apply-templates>
        </xsl:variable>
        <xsl:variable name="primaryKeyAttributes">
            <xsl:sequence select="$foreignKeyAttributes"/>
            <xsl:sequence select="$theAttributes"/>
        </xsl:variable>
        <relation id="{$id_A}">
            <name>
                <xsl:value-of select="name"/>
            </name>
            <xsl:apply-templates select="//businessRule[@type = 'description' and @about = $id_A]"/>
            <attributes>
                <xsl:sequence select="$foreignKeyAttributes"/>
                <xsl:sequence select="$theAttributes"/>
            </attributes>
            <constraints>
                <primaryKey id="{$id_A}">
                    <xsl:for-each select="$primaryKeyAttributes/rs:attribute">
                        <attributeRef idref="{@id}"/>
                    </xsl:for-each>
                </primaryKey>
                <foreignKey id="{func:generate-id()}" references="{$id_Relation}" onDelete="cascade"
                    onUpdate="cascade">
                    <xsl:for-each select="$foreignKeyAttributes/rs:attribute">
                        <attributeRef idref="{@id}"/>
                    </xsl:for-each>
                </foreignKey>
            </constraints>
        </relation>
    </xsl:template>
    <!--
        Transformiert einfache Attribute.
    -->
    <xsl:template match="attribute[not(func:isComplex(@id))]" mode="#default asAttribute"
        priority="1">
        <xsl:variable name="id" select="@id"/>
        <attribute id="{$id}">
            <name>
                <xsl:value-of select="name"/>
            </name>
            <xsl:apply-templates select="//businessRule[@type = 'description' and @about = $id]"/>
            <xsl:apply-templates select="domain | default"/>
        </attribute>
    </xsl:template>
    <!--
        Transformiert einfache Attribute, die als Fremdschlüssel in ein Relationsschema
        eingebunden werden sollen. In diesem Fall wird auf alle Einschränkungen bis auf
        "notNull" verzichtet. Dieses wird auf Wunsch ebenfalls unterdrückt.
        
        @param notNull true, wenn die Einschränkung "notNull" gesetzt werden soll
    -->
    <xsl:template match="attribute[not(func:isComplex(@id))]" mode="asForeignKeyAttribute"
        priority="1">
        <xsl:param name="notNull" as="xs:boolean" select="true()"/>
        <xsl:variable name="id" select="func:generate-id()"/>
        <attribute id="{$id}">
            <name>
                <xsl:value-of select="name"/>
            </name>
            <domain>
                <xsl:apply-templates select="domain/datatype"/>
                <xsl:if test="$notNull">
                    <restrictions>
                        <notNull/>
                    </restrictions>
                </xsl:if>
            </domain>
        </attribute>
    </xsl:template>
    <!--
        Kopiert die Unterelemente von Attributen unverändert ins Ergebnisdokument.
        Lediglich der Namensraum wird angepasst.
    -->
    <xsl:template match="domain | datatype | parameter | restrictions | notNull | minimum | maximum
        | pattern | enumeration | default">
        <xsl:element name="{name()}">
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates select="node()"/>
        </xsl:element>
    </xsl:template>
    <!--
        Transformiert Business Rules (Descriptions).
    -->
    <xsl:template match="businessRule[@type = 'description']">
        <comment>
            <xsl:value-of select="text"/>
        </comment>
    </xsl:template>
    <!--
        Erzeugt die Primärschlüssel-Attribute zu einem Entitätstyp. Wenn der Entitätstyp keinen
        Primärschlüssel hat, wird ein Auto-Key generiert (nur wenn Parameter genAutoKeys gesetzt).
        
        @param id ID des Entitätstyps
        @param partial true, wenn nur ein partieller Schlüssel erzeugt werden soll (bei
            schwachen Entitätstypen); andernfalls wird auch der Primärschlüssel der
            Vater-Entitätstypen berücksichtigt
    -->
    <xsl:template name="makePrimaryKey">
        <xsl:param name="id" required="yes"/>
        <xsl:param name="partial" as="xs:boolean" select="false()"/>
        <xsl:variable name="id_PK" select="func:getPrimaryKeyAttributes($id)"/>
        <xsl:if test="$genAutoKeys and empty($id_PK) and count(func:getParentEntities($id)) = 0">
            <xsl:call-template name="makeAutoKey">
                <xsl:with-param name="id" select="$id"/>
            </xsl:call-template>
        </xsl:if>
        <xsl:apply-templates select="$root//attribute[@id = $id_PK]">
            <xsl:sort select="@id"/>
        </xsl:apply-templates>
        <xsl:if test="not($partial)">
            <xsl:for-each select="func:getParentEntities($id)">
                <xsl:call-template name="makeForeignKey">
                    <xsl:with-param name="id" select="."/>
                    <xsl:with-param name="partial" select="false()"/>
                    <xsl:with-param name="notNull" select="true()"/>
                </xsl:call-template>
            </xsl:for-each>
        </xsl:if>
    </xsl:template>
    <!--
        Erzeugt Fremschlüssel-Attribute als Referenz auf den Primärschlüssel eines Entitätstyps.
        Wenn der Entitätstyp keinen Primärschlüssel hat, wird eine Referenz auf den Auto-Key
        generiert (nur wenn Parameter genAutoKeys gesetzt).
        
        @param id ID des Entitätstyps
        @param partial true, wenn nur ein partieller Schlüssel erzeugt werden soll (bei
            schwachen Entitätstypen); andernfalls wird auch der Primärschlüssel der
            Vater-Entitätstypen berücksichtigt
        @param notNull true, wenn die Einschränkung "notNull" für die Attribute gesetzt werden soll
    -->
    <xsl:template name="makeForeignKey">
        <xsl:param name="id" required="yes"/>
        <xsl:param name="partial" as="xs:boolean" select="false()"/>
        <xsl:param name="notNull" as="xs:boolean" select="true()"/>
        <xsl:variable name="id_PK" select="func:getPrimaryKeyAttributes($id)"/>
        <xsl:if test="$genAutoKeys and empty($id_PK) and count(func:getParentEntities($id)) = 0">
            <xsl:call-template name="makeAutoKeyReference">
                <xsl:with-param name="id" select="func:generate-id()"/>
                <xsl:with-param name="notNull" select="$notNull"/>
            </xsl:call-template>
        </xsl:if>
        <xsl:apply-templates select="$root//attribute[@id = $id_PK]" mode="asForeignKeyAttribute">
            <xsl:with-param name="notNull" select="$notNull"/>
            <xsl:sort select="@id"/>
        </xsl:apply-templates>
        <xsl:if test="not($partial)">
            <xsl:for-each select="func:getParentEntities($id)">
                <xsl:call-template name="makeForeignKey">
                    <xsl:with-param name="id" select="."/>
                    <xsl:with-param name="partial" select="false()"/>
                    <xsl:with-param name="notNull" select="$notNull"/>
                </xsl:call-template>
            </xsl:for-each>
        </xsl:if>
    </xsl:template>
    <!--
        Erzeugt ein Auto-Key-Attribut, das als Primärschlüssel verwendet werden kann.
        
        @param id ID des zu erzeugenden Attributs
    -->
    <xsl:template name="makeAutoKey">
        <xsl:param name="id" required="yes"/>
        <attribute id="{$id}">
            <name>ID</name>
            <comment>Automatically created ID</comment>
            <domain>
                <datatype name="integer">
                    <parameter name="precision" type="integer" value="32"/>
                </datatype>
                <restrictions>
                    <notNull/>
                </restrictions>
            </domain>
            <autoNumber startValue="1" increment="1"/>
        </attribute>
    </xsl:template>
    <!--
        Erzeugt eine Referenz auf ein Auto-Key-Attribut.
        
        @param id ID des zu erzeugenden Attributs
        @param notNull true, wenn die Einschränkung "notNull" für das Attribute gesetzt werden soll
    -->
    <xsl:template name="makeAutoKeyReference">
        <xsl:param name="id" required="yes"/>
        <xsl:param name="notNull" as="xs:boolean" select="true()"/>
        <attribute id="{$id}">
            <name>ID</name>
            <domain>
                <datatype name="integer">
                    <parameter name="precision" type="integer" value="32"/>
                </datatype>
                <xsl:if test="$notNull">
                    <restrictions>
                        <notNull/>
                    </restrictions>
                </xsl:if>
            </domain>
        </attribute>
    </xsl:template>
    <!--
        Führt Relationsschemata mit derselben ID zu einer einzigen zusammen. Es wird der Name und
        Kommentar des ersten Relationsschemas einer ID verwendet. Attribute und Constraints werden
        aus allen Relationsschematas zusammengenommen.
        
        @param relations Node-Set mit den relation-Elementen
    -->
    <xsl:template name="merge" xpath-default-namespace="&rs;">
        <xsl:param name="relations" required="yes"/>
        <xsl:for-each select="distinct-values($relations/relation/@id)">
            <xsl:variable name="id" select="."/>
            <relation id="{$id}">
                <xsl:copy-of select="subsequence($relations/relation[@id = $id]/name, 1, 1)"/>
                <xsl:copy-of select="subsequence($relations/relation[@id = $id]/comment, 1, 1)"/>
                <attributes>
                    <xsl:copy-of select="$relations/relation[@id = $id]/attributes/node()"/>
                </attributes>
                <constraints>
                    <xsl:copy-of select="$relations/relation[@id = $id]/constraints/node()"/>
                </constraints>
            </relation>
        </xsl:for-each>
    </xsl:template>
    <!--
        Löst Namenskonflikte auf. Das Template garantiert, dass nach der Ausführung keine
        Relationsschemata mit gleichem Namen sowie innerhalb eines Schemas keine Attribute mit
        gleichem Namen mehr existieren.
        
        @param Node-Set mit den relation-Elementen
    -->
    <xsl:template name="resolveNameConflicts" xpath-default-namespace="&rs;">
        <xsl:param name="relations" required="yes"/>
        <xsl:variable name="resolvedRelations">
            <xsl:apply-templates select="$relations" mode="resolveNameConflicts"/>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="count(distinct-values($resolvedRelations/relation/name)) &lt;
                count($resolvedRelations/relation/name) or max(for $r in $resolvedRelations/relation
                return count(distinct-values($r/attributes/attribute/name)) &lt;
                count($r/attributes/attribute/name))">
                <xsl:call-template name="resolveNameConflicts">
                    <xsl:with-param name="relations" select="$resolvedRelations"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="$resolvedRelations"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <!--
        Hilfstemplate für das Template resolveNameConflicts zur Behandlung der name-Elemente.
        
        @see resolveNameConflicts
    -->
    <xsl:template match="name" mode="resolveNameConflicts" xpath-default-namespace="&rs;">
        <xsl:variable name="thisName" select="."/>
        <xsl:copy>
            <xsl:choose>
                <xsl:when test="count(../../*[name = $thisName]) > 1">
                    <xsl:value-of select="concat($thisName, '_', index-of(../../*[name =
                        $thisName]/@id, ../@id))"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$thisName"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:copy>
    </xsl:template>
    <!--
        Hilfstemplate für das Template resolveNameConflicts zum Kopieren des übrigen Inhalts.
        
        @see resolveNameConflicts
    -->
    <xsl:template match="@* | node()" mode="resolveNameConflicts" xpath-default-namespace="&rs;">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>
