DROP TABLE Spieler;
DROP TABLE Verein;

CREATE TABLE Verein (
    VereinsName VARCHAR2(15),
    Kuerzel VARCHAR2(5),
    Trainer VARCHAR2(15),
    PRIMARY KEY(Kuerzel),
    CHECK((Trainer = 'Heiko Tapken' AND VereinsName = 'BV Garrel') OR Trainer != 'Heiko Tapken')
);

CREATE TABLE Spieler (
    RueckenNummer INT,
    VereinsName,
    Vorname VARCHAR2(10) NOT NULL,
    Nachname VARCHAR2(10) NOT NULL,
    Positoin VARCHAR2(10) NOT NULL,
    PRIMARY KEY(RueckenNummer, VereinsName),
    FOREIGN KEY(VereinsName) REFERENCES Verein (Kuerzel),
    CHECK(RueckenNummer > 0),
    CHECK(RueckenNummer < 24 OR VereinsName = 'VFL'),
    CHECK((Nachname = 'Tapken' AND VereinsName != 'VFL') OR Nachname != 'Tapken')
);

INSERT INTO Verein 
VALUES ('BV Garrel', 'BVG', 'Heiko Tapken');
INSERT INTO Verein 
VALUES ('BV Cloppenburg', 'BVC', 'Phil Lipplahm');
INSERT INTO Verein 
VALUES ('VFL Onsabrück', 'VFL', 'Miros Lavklose');

INSERT INTO Spieler 
VALUES (1, 'BVG', 'Willi', 'Lustig', 'Tor');
INSERT INTO Spieler 
VALUES (6, 'BVG', 'Jonas', 'Tapken', 'Sturm');
INSERT INTO Spieler 
VALUES (1, 'VFL', 'Karl', 'May', 'Tor');
INSERT INTO Spieler 
VALUES (2, 'BVG', 'David', 'Grotjan', 'Abwehr');
INSERT INTO Spieler 
VALUES (3, 'BVC', 'Jan', 'Bäcker', 'Abwehr');

INSERT INTO Spieler 
VALUES (23, 'VFL', 'Jan', 'Tapken', 'Abwehr');


SELECT * FROM Verein;
SELECT * FROM Spieler;