DROP TABLE Bestellung;
DROP TABLE Anruf;
DROP TABLE Pizza;
DROP TABLE Besteller;

/*
CREATE TABLE Besteller (
    Telefon NUMBER(5),
    KundenName VARCHAR(25),
    Ort VARCHAR(25)
);
CREATE TABLE Pizza (
    PizzaNummer NUMBER(2),
    PizzaName VARCHAR2(25),
    Preis NUMBER(3,1)
);
CREATE TABLE Anruf  (
    Nummer NUMBER(3),
    Telefon VARCHAR(5),
    Datum VARCHAR(10),
    Uhrzeit VARCHAR(5)
);
CREATE TABLE Bestellung (
    ANummer  NUMBER(2),
    PNummer NUMBER(2),
    Menge NUMBER(3)
);

*/

CREATE TABLE Besteller (
    Telefon NUMBER(5),
    KundenName VARCHAR(25),
    Ort VARCHAR(25),
    PRIMARY KEY(Telefon)
);
CREATE TABLE Pizza (
    PizzaNummer NUMBER(2),
    PizzaName VARCHAR2(25),
    Preis NUMBER(3,1),
    PRIMARY KEY(PizzaNummer)
);
CREATE TABLE Anruf  (
    Nummer NUMBER(3),
    Telefon,
    Datum VARCHAR(10),
    Uhrzeit VARCHAR(5),
    PRIMARY KEY(Nummer),
    FOREIGN KEY(Telefon) REFERENCES Besteller(Telefon)
);
CREATE TABLE Bestellung (
    ANummer,
    PNummer,
    Menge NUMBER(3),
    PRIMARY KEY(ANummer,PNummer),
    FOREIGN KEY(ANummer) REFERENCES Anruf(Nummer),
    FOREIGN KEY(PNummer) REFERENCES Pizza(PizzaNummer)
    
);
INSERT INTO Besteller (Telefon, KundenName,Ort) VALUES ('04321','Ronny','Itzehoe');
INSERT INTO Besteller (Telefon, KundenName,Ort) VALUES ('03456','Bonny','Elmshorn');
INSERT INTO Besteller (Telefon, KundenName,Ort) VALUES ('02345','Johnny','Horst');

INSERT INTO Pizza (PizzaNummer, PizzaName,Preis) VALUES ('1','Mafiosa','6,5');
INSERT INTO Pizza (PizzaNummer, PizzaName,Preis) VALUES ('2','Tofu','5,5');
INSERT INTO Pizza (PizzaNummer, PizzaName,Preis) VALUES ('3','Western','8,3');

INSERT INTO Anruf (Nummer, Telefon, Datum, Uhrzeit) VALUES ('1','04321','01.11.2006', '16:45');
INSERT INTO Anruf (Nummer, Telefon, Datum, Uhrzeit) VALUES ('2','03456','01.11.2006', '16:50');
INSERT INTO Anruf (Nummer, Telefon, Datum, Uhrzeit) VALUES ('3','03456','01.11.2006', '18:30');
INSERT INTO Anruf (Nummer, Telefon, Datum, Uhrzeit) VALUES ('4','04321','01.11.2006', '18:45');

INSERT INTO Bestellung (ANummer, PNummer, Menge) VALUES ('1','1','2');
INSERT INTO Bestellung (ANummer, PNummer, Menge) VALUES ('1','2','3');
INSERT INTO Bestellung (ANummer, PNummer, Menge) VALUES ('2','2','4');
INSERT INTO Bestellung (ANummer, PNummer, Menge) VALUES ('3','1','1');
INSERT INTO Bestellung (ANummer, PNummer, Menge) VALUES ('4','1','2');
INSERT INTO Bestellung (ANummer, PNummer, Menge) VALUES ('4','2','3');

--a) Doppelter Eintrag ist möglich
--b) doppelter Eintrag ist nicht möglich, da Primärschlüssel nicht doppelt sein dürfen
/*
INSERT INTO Bestellung (ANummer, PNummer, Menge) VALUES ('4','2','3');
DESCR Bestellung
SELECT * FROM Bestellung;
*/

--Versuchen Sie in Anruf einen Eintrag für eine nicht in Besteller eingetragene
--Telefonnummer zu machen
--a) ist möglich
--b) nicht möglich, da kein passender Fremdschlüssel existiert
/*
INSERT INTO Anruf (Nummer, Telefon) VALUES ('5','22222');
SELECT * FROM Anruf;
*/

--Versuchen Sie in Anruf einen Eintrag zu machen, dabei ist die Telefonnummer unbekannt
--(NULL)
--a) möglich
--b) möglich
/*
INSERT INTO Anruf (Nummer,Telefon, Datum, Uhrzeit) VALUES ('5', NULL, '01.11.2006', '18:45');
SELECT * FROM Anruf;
*/

--Versuchen Sie eine Zeile der Tabelle Besteller zu löschen 
--a) möglich
--b) nur möglich wenn der Primärschlüssel der Zeile nicht referenziert wird
/*
SELECT * FROM Besteller;
SELECT * FROM Anruf;
DELETE FROM Besteller WHERE Ort='Itzehoe';
SELECT * FROM Besteller;
SELECT * FROM Anruf;
*/

--Versuchen Sie eine Zeile der Tabelle Bestellung zu löschen
--a) möglich
--b) möglich da keine Schlüssel von außerhalb referenziert werden
/*
SELECT * FROM Bestellung;
DELETE FROM Bestellung WHERE Menge='4';
SELECT * FROM Bestellung;
*/

--Versuchen Sie die Telefonnummer eines Bestellers zu ändern 
--a) möglich
--b) nicht möglich, da die alte Nummer von außerhalb referenziert wird
/*
SELECT * FROM Besteller;
UPDATE Besteller SET Telefon='11111' WHERE Telefon='04321';
SELECT * FROM Besteller;
*/

--Versuchen Sie den Namen einer Pizza zu ändern
--a) möglich
--b) möglich
/*
SELECT * FROM Pizza;
UPDATE Pizza SET PizzaName='MegaPizza' WHERE PizzaName='Tofu';
SELECT * FROM Pizza;
*/

--Versuchen Sie die Tabelle Besteller mit CASCADE ... zu löschen
--a) möglich
--b) möglich
/*
SELECT * FROM Besteller;
DROP TABLE Besteller CASCADE CONSTRAINTS;
*/ 

--Versuchen Sie die Tabelle Pizza mit CASCADE ... zu löschen
--a) möglich
--b) möglich
--/*
SELECT * FROM Pizza;
DROP TABLE Pizza CASCADE CONSTRAINTS;
--*/ 
