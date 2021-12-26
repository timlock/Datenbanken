package com.company;

import java.sql.*;


import java.sql.*;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.Scanner;


public class Main {

    public static int id = 0;
    public static void createTables(Connection con) throws SQLException {
        PreparedStatement createKartoffel = con.prepareStatement("" +
                "create table Kartoffel (" +
                "QualitaetsSchluessel number(10)," +
                "Sorte VARCHAR2(16)," +
                "Groesse number (3)," +
                "Gewicht number (5)," +
                "StaerkeGehalt number(2)," +
                "Fleckigkeit number(2)," +
                "Gruen number(1)," +
                "PRIMARY KEY  (QualitaetsSchluessel))");

        if(createKartoffel.execute()) System.out.println("Kartoffel erstellt");
        createKartoffel.close();
        PreparedStatement createGrossraumlager = con.prepareStatement(
                "create table Grossraumlager (" +
                        "Adresse varchar2(20)," +
                        "Kapazitaet number(16)," +
                        "EinlagerungsZeitpunkt varchar2(12)," +
                        "QualitaetsSchluessel," +
                        "Groesse number (3)," +
                        "Lagerstelle varchar2(2)," +
                        "PRIMARY KEY (Adresse, QualitaetsSchluessel)," +
                        "FOREIGN KEY (QualitaetsSchluessel) references Kartoffel(QualitaetsSchluessel))");
        if (createGrossraumlager.execute()) System.out.println("KartoffelTabelle erstellt");
        createGrossraumlager.close();
        PreparedStatement createProduktionslager = con.prepareStatement(
                "create TABLE Produktionslager(" +
                        "BunkerNr number (3)," +
                        "Adresse varchar2(20)," +
                        "QualitaetsSchluessel," +
                        "Sorte VARCHAR2(16)," +
                        "Groesse number (3)," +
                        "PRIMARY Key (BunkerNr)," +
                        "FOREIGN KEY (QualitaetsSchluessel) references Kartoffel(QualitaetsSchluessel))"
        );

        if (createProduktionslager.execute()) System.out.println("KartoffelTabelle erstellt");
        createProduktionslager.close();
        /*
        PreparedStatement createBunker = con.prepareStatement(
                "create TABLE Bunker(" +
                        "QualitaetsSchluessel," +
                        "Sorte VARCHAR2(16)," +
                        "Groesse number (3)," +
                        "PRIMARY Key (Sorte, Groesse)," +
                        "FOREIGN KEY (QualitaetsSchluessel) references Kartoffel(QualitaetsSchluessel))"
        );
        if (createBunker.execute()) System.out.println("KartoffelTabelle erstellt");
*/

    }
    public static void dropTables(Connection con) throws SQLException {
        PreparedStatement dropGrossraumlager = con.prepareStatement("drop table Grossraumlager");
        if(dropGrossraumlager.execute()) System.out.println("Grossraumlager wurde gelöscht");
        PreparedStatement dropProduktionslager = con.prepareStatement("drop table Produktionslager");
        if(dropProduktionslager.execute()) System.out.println("Produktionslager wurde gelöscht");
//        PreparedStatement dropBunker = con.prepareStatement("drop table Bunker");
//        if(dropBunker.execute()) System.out.println("Bunker wurde gelöscht");
        PreparedStatement dropKartoffel = con.prepareStatement("drop table Kartoffel");
        if(dropKartoffel.execute()) System.out.println("Kartoffel wurde gelöscht");
        dropKartoffel.close();
        dropGrossraumlager.close();
        dropProduktionslager.close();
    }

    public static void definiereKartoffel(Connection con) throws SQLException {
        if(false) {
            PreparedStatement insert = con.prepareStatement("insert into Kartoffel(QualitaetsSchluessel,Sorte,Groesse,Gewicht,Staerkegehalt,Fleckigkeit,Gruen)" +
                    "values (?,?,?,?,?,?,?)");
            insert.setInt(1, 0); //QualitaetsSchluessel number(10)
            insert.setString(2, "Landkartoffel"); //Sorte VARCHAR2(16)
            insert.setInt(3, 2); //Groesse number (3)
            insert.setInt(4, 3); //Gewicht number (5)
            insert.setInt(5, 50); //StaerkeGehalt number(2)
            insert.setInt(6, 10); //Fleckigkeit number(2)
            insert.setInt(7, 0); //Gruen number(1)
            insert.execute();
            insert.close();
        }
        if(true) {
            PreparedStatement insert = con.prepareStatement("insert into Kartoffel(QualitaetsSchluessel,Sorte,Groesse,Gewicht,Staerkegehalt,Fleckigkeit,Gruen)" +
                    "values (?,?,?,?,?,?,?)");
            insert.setInt(1, 1); //QualitaetsSchluessel number(10)
            insert.setString(2, "Stadtkartoffel"); //Sorte VARCHAR2(16)
            insert.setInt(3, 1); //Groesse number (3)
            insert.setInt(4, 2); //Gewicht number (5)
            insert.setInt(5, 40); //StaerkeGehalt number(2)
            insert.setInt(6, 12); //Fleckigkeit number(2)
            insert.setInt(7, 1); //Gruen number(1)
            insert.execute();
            insert.close();
        }
    }

    public static void einlagern(Connection con) throws SQLException {
        if(true) {
            PreparedStatement insert = con.prepareStatement("insert into Grossraumlager(Adresse,Kapazitaet,EinlagerungsZeitpunkt,QualitaetsSchluessel,Groesse,Lagerstelle) " +
                    "values(?,?,?,?,?,?)");
            insert.setString(1, "Kleine Strasse 2"); //Adresse varchar2(20)
            insert.setInt(2, 1000); //Kapazitaet number(16)
            insert.setDate(3, new Date(System.currentTimeMillis())); //EinlagerungsZeitpunkt varchar2(12)
            insert.setInt(4, 1); //QualitaetsSchluessel
            insert.setInt(5, 1); //Groesse number (3)
            insert.setString(6, "A1"); //Lagerstelle varchar2(2)
            insert.execute();
            insert.close();
        }
        if (false) {
            PreparedStatement insert = con.prepareStatement("insert into Produktionslager(BunkerNr,Adresse,QualitaetsSchluessel,Sorte,Groesse)" +
                    "values (?,?,?,?,?)");
            insert.setInt(1, 1); //"BunkerNr number (3)," +
            insert.setString(2, "Grosse Strasse 1"); //Adresse varchar2(20)
            insert.setInt(3, 0); //QualitaetsSchluessel
            insert.setString(4, "Landkartoffel"); //Sorte VARCHAR2
            insert.setInt(5, 2); //Groesse number (3)
            insert.execute();
            insert.close();
        }
    }

    public static void info(Connection con) throws SQLException {
            {
                System.out.println("Großraumlager");

                DatabaseMetaData metaData = con.getMetaData();
                System.out.println(metaData.getDatabaseProductName());
                System.out.println(metaData.getDefaultTransactionIsolation());
            PreparedStatement statement = con.prepareStatement("select * from Grossraumlager");
            ResultSet resultSet = statement.executeQuery();

            // Ergebnis verarbeiten
            while (resultSet.next()) {
                System.out.print(resultSet.getInt("QualitaetsSchluessel")+ " ");
                System.out.print(resultSet.getString("Adresse") + " ");
                System.out.print(resultSet.getInt("Kapazitaet")+ " ");
                System.out.print(resultSet.getString("EinlagerungsZeitpunkt")+ " ");
                System.out.print(resultSet.getInt("Groesse")+ " ");
                System.out.print(resultSet.getString("Lagerstelle")+ " ");
            }
            statement.close();
        }
            {
                System.out.println("\nProduktionslager");

                DatabaseMetaData metaData = con.getMetaData();
                System.out.println(metaData.getDatabaseProductName());
                System.out.println(metaData.getDefaultTransactionIsolation());
            PreparedStatement statement = con.prepareStatement("select * from Produktionslager");
            ResultSet resultSet = statement.executeQuery();

            // Ergebnis verarbeiten
            while (resultSet.next()) {
                System.out.print(resultSet.getInt("QualitaetsSchluessel")+ " ");
                System.out.print(resultSet.getInt("BunkerNr")+ " ");
                System.out.print(resultSet.getString("Adresse")+ " ");
                System.out.print(resultSet.getString("Sorte")+ " ");
                System.out.print(resultSet.getInt("Groesse")+ " ");
            }
            statement.close();
        }

    }
    public static void umlagern(Connection con) throws SQLException {
        PreparedStatement auslagern = con.prepareStatement("select * from Grossraumlager where QualitaetsSchluessel = 1");
        ResultSet resultSet = auslagern.executeQuery();
        resultSet.next();
        PreparedStatement einlagern = con.prepareStatement("insert into Produktionslager(BunkerNr,Adresse,QualitaetsSchluessel,Sorte,Groesse)" +
                "values (?,?,?,?,?)");
        einlagern.setInt(1, 0); //"BunkerNr number (3)," +
        einlagern.setString(2, "Grosse Strasse 1a"); //Adresse varchar2(20)
        einlagern.setInt(3, resultSet.getInt("QualitaetsSchluessel")); //QualitaetsSchluessel

        PreparedStatement sorte = con.prepareStatement("select sorte from Kartoffel where QualitaetsSchluessel = ?");
        int schluessel = resultSet.getInt("QualitaetsSchluessel");
        sorte.setInt(1,schluessel);
        ResultSet sorteSet = sorte.executeQuery();
        sorteSet.next();

        einlagern.setString(4, sorteSet.getString(1)); //Sorte VARCHAR2
        einlagern.setInt(5, resultSet.getInt("Groesse")); //Groesse number (3)
        einlagern.execute();
        PreparedStatement loeschen = con.prepareStatement("delete from Grossraumlager where QualitaetsSchluessel = 1 ");
        loeschen.execute();
        auslagern.close();
        einlagern.close();
        sorteSet.close();
        loeschen.close();
    }

    public static void main(String[] args) {
        // Treiber in IDE laden
        // Variante 1: maven: Pom.xml ausfüllen, maven tool -> Install
        // Variante 2:Teiber koperen

        // Treiber bekannt machen

        Connection con;

        try {
            Class.forName("oracle.jdbc.driver.OracleDriver"); // Treiber bekanntgemacht
// Verbindung zur DB herstellen
            con = DriverManager.getConnection("jdbc:oracle:thin:@oracle-srv.edvsz.hs-osnabrueck.de:1521/oraclestud",
                    "otimnlock", "otimnlock");
//            dropTables(con);
//            createTables(con);
//            definiereKartoffel(con);
//            einlagern(con);
            info(con);
            umlagern(con);
            info(con);



            /*
            // Statement erstellen
            Statement statement = con.createStatement();
            ResultSet resultSet = statement.executeQuery("select gehalt from angestellter where gehalt > 40000");

            // Ergebnis verarbeiten
            while(resultSet.next()){
                System.out.println(resultSet.getInt("gehalt"));
            }

            ArrayList <String> al = new ArrayList();
            Iterator iterator = al.iterator();
            while (iterator.hasNext()){
                String next = (String) iterator.next();
            }


            PreparedStatement preparedStatement = con.prepareStatement("select gehalt from angestellter where gehalt > ?");
            preparedStatement.setInt(1,40000);
            resultSet = preparedStatement.executeQuery();

            ResultSetMetaData metaData1 = resultSet.getMetaData();
            metaData1.getColumnCount();


            // Ergebnis verarbeiten
            while(resultSet.next()){
                System.out.println(resultSet.getInt("gehalt"));
            }

            DatabaseMetaData metaData = con.getMetaData();
            System.out.println(metaData.getDatabaseProductName());
            System.out.println(metaData.getDefaultTransactionIsolation());
            con.setAutoCommit(false);

            resultSet.close();
            statement.close();
            preparedStatement.close();
             */
            con.close();

        } catch (ClassNotFoundException | SQLException e) {
            e.printStackTrace();
        }


        // Verbindung zur Datenbank
    }
}
