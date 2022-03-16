-- Anlegen Tabellen Aufgabe 5 Probeklausur
-- zur Selbstkontrolle der SQL-Anfragen
-- mit Daten
-- ohne weitere Constraints

DROP TABLE Projekt CASCADE CONSTRAINTS;
DROP TABLE Arbeitspaket CASCADE CONSTRAINTS;
DROP TABLE Arbeit CASCADE CONSTRAINTS;

CREATE TABLE Projekt (
    PrNr INT,
    PrName VARCHAR(40),
    PrLeiter VARCHAR(40),
    PRIMARY KEY (PrNr)
);

CREATE TABLE Arbeitspaket (
    PakNr INT,
    PrNr INT,
    PakName VARCHAR(40),
    PakLeiter VARCHAR(40),
    PRIMARY KEY (PakNr),
    FOREIGN KEY(PrNr) REFERENCES Projekt(PrNr)
);

CREATE TABLE Arbeit (
    PakNr INT,
    MiName VARCHAR(40),
    Anteil INT,
    PRIMARY KEY(PakNr, MiName),
    FOREIGN KEY(PakNr) REFERENCES Arbeitspaket(PakNr)
);

INSERT INTO Projekt (PrNr, PrName, PrLeiter) VALUES (1, 'Notendatenbank', 'Wichtig');
INSERT INTO Projekt (PrNr, PrName, PrLeiter) VALUES (2, 'Adressdatenbank', 'Wuchtig');
INSERT INTO Projekt (PrNr, PrName, PrLeiter) VALUES (3, 'Fehlzeitendatenbank', 'Wachtig');

INSERT INTO Arbeitspaket (PrNr, PakNr, PakName, PakLeiter) VALUES (1, 1, 'Analyse', 'Wichtig');
INSERT INTO Arbeitspaket (PrNr, PakNr, PakName, PakLeiter) VALUES (1, 2, 'Modell', 'Wuchtig');
INSERT INTO Arbeitspaket (PrNr, PakNr, PakName, PakLeiter) VALUES (1, 3, 'Implementierung', 'Mittel');
INSERT INTO Arbeitspaket (PrNr, PakNr, PakName, PakLeiter) VALUES (2, 4, 'Modell', 'Durch');
INSERT INTO Arbeitspaket (PrNr, PakNr, PakName, PakLeiter) VALUES (2, 5, 'Implementierung', 'Mittel');
INSERT INTO Arbeitspaket (PrNr, PakNr, PakName, PakLeiter) VALUES (3, 6, 'Modell', 'Schnitt');
INSERT INTO Arbeitspaket (PrNr, PakNr, PakName, PakLeiter) VALUES (3, 7, 'Implementierung', 'Hack');

INSERT INTO Arbeit (PakNr, MiName, Anteil) VALUES (1, 'Wichtig', 50);
INSERT INTO Arbeit (PakNr, MiName, Anteil) VALUES (1, 'Klein', 30);
INSERT INTO Arbeit (PakNr, MiName, Anteil) VALUES (2, 'Winzig', 100);
INSERT INTO Arbeit (PakNr, MiName, Anteil) VALUES (3, 'Hack', 70);
INSERT INTO Arbeit (PakNr, MiName, Anteil) VALUES (4, 'Maler', 40);
INSERT INTO Arbeit (PakNr, MiName, Anteil) VALUES (4, 'Schreiber', 30);
INSERT INTO Arbeit (PakNr, MiName, Anteil) VALUES (6, 'Maler', 30);
INSERT INTO Arbeit (PakNr, MiName, Anteil) VALUES (6, 'Schreiber', 40);
INSERT INTO Arbeit (PakNr, MiName, Anteil) VALUES (7, 'Hack', 50);