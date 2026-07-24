/*IMPORTATION DES DONNEES*/

PROC IMPORT DATAFILE="/home/u64525928/CLIENTS_PROJET.csv"
    OUT=clients DBMS=CSV REPLACE;
    GETNAMES=YES;
RUN;

PROC IMPORT DATAFILE="/home/u64525928/COMPTES_PROJET.csv"
    OUT=comptes DBMS=CSV REPLACE;
    GETNAMES=YES;
RUN;

PROC IMPORT DATAFILE="/home/u64525928/CREDITS_PROJET.csv"
    OUT=credits DBMS=CSV REPLACE;
    GETNAMES=YES;
RUN;

PROC IMPORT DATAFILE="/home/u64525928/TRANSACTIONS_PROJET.csv"
    OUT=transactions DBMS=CSV REPLACE;
    GETNAMES=YES;
RUN;

/* Structure des tables importees */
PROC CONTENTS DATA=clients; 
RUN;
PROC CONTENTS DATA=comptes; 
RUN;
PROC CONTENTS DATA=credits; 
RUN;
PROC CONTENTS DATA=transactions; 
RUN;

/* PARTIE 1 - CONTROLE QUALITE DES DONNEES */

/* Vérification des valeurs manquantes */
PROC MEANS DATA=clients N NMISS;
    VAR Age Anciennete Revenu_Mensuel;
RUN;

PROC MEANS DATA=comptes N NMISS;
    VAR Solde;
RUN;

PROC MEANS DATA=credits N NMISS;
    VAR Montant Duree Taux Mensualite Retard_Paiement;
RUN;

PROC MEANS DATA=transactions N NMISS;
    VAR Montant;
RUN;

/* Variables qualitatives */
PROC FREQ DATA=clients;
    TABLES Sexe Ville Profession Agence / MISSING;
RUN;

/* Recherche des doublons */
PROC SORT DATA=clients OUT=clients_tries;
    BY ID_Client;
RUN;

PROC SQL;
    CREATE TABLE doublons_clients AS
    SELECT ID_Client, COUNT(*) AS Nb
    FROM clients
    GROUP BY ID_Client
    HAVING COUNT(*) > 1;
QUIT;

PROC SQL;
    CREATE TABLE doublons_comptes AS
    SELECT ID_Compte, COUNT(*) AS Nb
    FROM comptes
    GROUP BY ID_Compte
    HAVING COUNT(*) > 1;
QUIT;

PROC SQL;
    CREATE TABLE doublons_credits AS
    SELECT ID_Credit, COUNT(*) AS Nb
    FROM credits
    GROUP BY ID_Credit
    HAVING COUNT(*) > 1;
QUIT;

PROC SQL;
    CREATE TABLE doublons_transactions AS
    SELECT ID_Transaction, COUNT(*) AS Nb
    FROM transactions
    GROUP BY ID_Transaction
    HAVING COUNT(*) > 1;
QUIT;

/* Vérification des valeurs incohérentes */
DATA incoherences_age;
    SET clients;
    WHERE Age < 18 OR Age > 100;
RUN;

PROC SQL;
    SELECT COUNT(*) AS Nb_Incoherences_Age
    FROM incoherences_age;
QUIT;

DATA incoherences_revenu;
    SET clients;
    WHERE Revenu_Mensuel <= 0;
RUN;

PROC SQL;
    SELECT COUNT(*) AS Nb_Incoherences_Revenu
    FROM incoherences_revenu;
QUIT;

DATA incoherences_solde;
    SET comptes;
    WHERE Solde < 0;
RUN;

PROC SQL;
    SELECT COUNT(*) AS Nb_Incoherences_Solde
    FROM incoherences_solde;
QUIT;

DATA incoherences_taux;
    SET credits;
    WHERE Taux < 0 OR Taux > 30;
RUN;

PROC SQL;
    SELECT COUNT(*) AS Nb_Incoherences_Taux
    FROM incoherences_taux;
QUIT;

/* Analyse des variables qualitatives */
PROC FREQ DATA=comptes;
    TABLES Type_Compte Statut;
RUN;

PROC FREQ DATA=credits;
    TABLES Statut_Credit;
RUN;

PROC FREQ DATA=transactions;
    TABLES Nature Canal Agence;
RUN;

/* PARTIE 2 - PREPARATION DES DONNEES */

/* Suppression des doublons */
PROC SORT DATA=clients OUT=clients NODUPKEY;
    BY ID_Client;
RUN;

PROC SORT DATA=comptes OUT=comptes NODUPKEY;
    BY ID_Compte;
RUN;

PROC SORT DATA=credits OUT=credits NODUPKEY;
    BY ID_Credit;
RUN;

PROC SORT DATA=transactions OUT=transactions NODUPKEY;
    BY ID_Transaction;
RUN;

/* Nettoyage des données */
DATA clients;
    SET clients;
    IF Age < 18 OR Age > 100 THEN Age = .;
    IF Revenu_Mensuel <= 0 THEN Revenu_Mensuel = .;
    DROP Nom;   /* variable inutile identifiee en Partie 1 */
RUN;

DATA comptes;
    SET comptes;
    IF Solde < 0 THEN Solde = .;
RUN;

DATA credits;
    SET credits;
    IF Taux < 0 OR Taux > 30 THEN Taux = .;
RUN;

/* Vérification après nettoyage */
PROC MEANS DATA=clients N NMISS MIN MAX MEAN;
    VAR Age Revenu_Mensuel;
RUN;


/* PARTIE 3 - CONSTRUCTION DE LA TABLE CLIENT_ANALYSE */

/* Agrégation des comptes */
PROC SQL;
    CREATE TABLE agg_comptes AS
    SELECT ID_Client,
           COUNT(*)    AS Nb_Comptes,
           MEAN(Solde) AS Solde_Moyen
    FROM comptes
    GROUP BY ID_Client;
QUIT;

/* Agrégation des crédits */
PROC SQL;
    CREATE TABLE agg_credits AS
    SELECT ID_Client,
           COUNT(*)     AS Nb_Credits,
           SUM(Montant) AS Total_Credits,
           SUM(Mensualite)      AS Mensualite_Totale,
           MAX(Retard_Paiement) AS Retard_Max
    FROM credits
    GROUP BY ID_Client;
QUIT;

/* Agrégation des transactions */
PROC SQL;
    CREATE TABLE agg_transactions AS
    SELECT ID_Client,
           COUNT(*)     AS Nb_Transactions,
           SUM(Montant) AS Montant_Total_Transactions
    FROM transactions
    GROUP BY ID_Client;
QUIT;

/* Fusion des tables */
PROC SORT DATA=clients;          BY ID_Client; RUN;
PROC SORT DATA=agg_comptes;      BY ID_Client; RUN;
PROC SORT DATA=agg_credits;      BY ID_Client; RUN;
PROC SORT DATA=agg_transactions; BY ID_Client; RUN;

DATA CLIENT_ANALYSE;
    MERGE clients (IN=a) agg_comptes agg_credits agg_transactions;
    BY ID_Client;
    IF a;   /* on garde uniquement les clients de la table CLIENTS */
    IF Nb_Comptes = .                 THEN Nb_Comptes = 0;
    IF Nb_Credits = .                 THEN Nb_Credits = 0;
    IF Total_Credits = .              THEN Total_Credits = 0;
    IF Mensualite_Totale = .          THEN Mensualite_Totale = 0;
    IF Retard_Max = .                 THEN Retard_Max = 0;
    IF Nb_Transactions = .            THEN Nb_Transactions = 0;
    IF Montant_Total_Transactions = . THEN Montant_Total_Transactions = 0;
RUN;

PROC PRINT DATA=CLIENT_ANALYSE (OBS=10);
RUN;

/* PARTIE 4 - CREATION DES INDICATEURS */

/* Identification des clients en défaut */
PROC SQL;
    CREATE TABLE defaut_client AS
    SELECT ID_Client,
           MAX(CASE WHEN Statut_Credit = "Défaut" THEN 1 ELSE 0 END)
               AS Statut_Client_Defaut
    FROM credits
    GROUP BY ID_Client;
QUIT;

PROC SORT DATA=defaut_client;  BY ID_Client; RUN;
PROC SORT DATA=CLIENT_ANALYSE; BY ID_Client; RUN;

DATA CLIENT_ANALYSE;
    MERGE CLIENT_ANALYSE (IN=a) defaut_client;
    BY ID_Client;
    IF a;
    IF Statut_Client_Defaut = . THEN Statut_Client_Defaut = 0;
RUN;

DATA CLIENT_ANALYSE;
    SET CLIENT_ANALYSE;

    /* 1. Taux d'endettement = mensualites totales / revenu mensuel */
    IF Revenu_Mensuel > 0 THEN
        Taux_Endettement = ROUND(Mensualite_Totale / Revenu_Mensuel, 0.01);
    ELSE
        Taux_Endettement = .;

    /* 2. Revenu annuel */
    Revenu_Annuel = Revenu_Mensuel * 12;

    /* 3. Anciennete en categorie */
    IF Anciennete < 2 THEN Categorie_Anciennete = "Nouveau";
    ELSE IF Anciennete < 5 THEN Categorie_Anciennete = "Intermediaire";
    ELSE IF Anciennete < 10 THEN Categorie_Anciennete = "Fidele";
    ELSE Categorie_Anciennete = "Tres fidele";

    /* 4. Nombre moyen de transactions par mois (historique = 12 mois) */
    Transactions_Par_Mois = ROUND(Nb_Transactions / 12, 0.1);

    /* Score de fidélité */
    Score_Fidelite = ROUND(
        (MIN(Anciennete,15) / 15) * 50
      + (MIN(Nb_Comptes,3) / 3) * 25
      + (MIN(Nb_Transactions,60) / 60) * 25
    , 0.1);

    /* Score de risque */
    IF Taux_Endettement = . THEN Taux_Endettement_Score = 0;
    ELSE Taux_Endettement_Score = MIN(Taux_Endettement,1);

    Score_Risque = ROUND(
        Taux_Endettement_Score * 50
      + (MIN(Retard_Max,6) / 6) * 30
      + Statut_Client_Defaut * 20
    , 0.1);

    DROP Taux_Endettement_Score;
RUN;

/* Controle des indicateurs */
PROC MEANS DATA=CLIENT_ANALYSE N NMISS MIN MAX MEAN;
    VAR Taux_Endettement Revenu_Annuel Transactions_Par_Mois
        Score_Fidelite Score_Risque;
RUN;

PROC FREQ DATA=CLIENT_ANALYSE;
    TABLES Categorie_Anciennete;
RUN;


/* PARTIE 5 - SEGMENTATION DES CLIENTS */

/* Segmentation des clients */
DATA CLIENT_ANALYSE;
    SET CLIENT_ANALYSE;

    IF Score_Risque >= 60 THEN Segment = "A risque";
    ELSE IF Score_Fidelite >= 70 AND Revenu_Annuel >= 8000000 THEN Segment = "Premium";
    ELSE IF Score_Fidelite >= 40 THEN Segment = "Gold";
    ELSE Segment = "Standard";
RUN;

PROC FREQ DATA=CLIENT_ANALYSE;
    TABLES Segment;
RUN;

PROC TABULATE DATA=CLIENT_ANALYSE;
    CLASS Segment Sexe;
    VAR Revenu_Mensuel Score_Risque;
    TABLE Segment*Sexe, (Revenu_Mensuel Score_Risque)*(MEAN);
RUN;

/* PARTIE 6 - ANALYSE STATISTIQUE ET VISUALISATIONS */

/* 1. Histogramme des revenus */
PROC SGPLOT DATA=CLIENT_ANALYSE;
    HISTOGRAM Revenu_Mensuel;
    TITLE "Distribution des revenus mensuels";
RUN;

PROC UNIVARIATE DATA=CLIENT_ANALYSE;
    VAR Revenu_Mensuel;
    HISTOGRAM Revenu_Mensuel;
RUN;

/* 2. Barplot des segments */
PROC SGPLOT DATA=CLIENT_ANALYSE;
    VBAR Segment;
    TITLE "Repartition des clients par segment";
RUN;

/* 3. Repartition Homme / Femme */
PROC SGPLOT DATA=CLIENT_ANALYSE;
    VBAR Sexe;
    TITLE "Repartition des clients par sexe";
RUN;

PROC FREQ DATA=CLIENT_ANALYSE;
    TABLES Sexe;
RUN;

/* 4. Credit total par agence */
PROC SQL;
    CREATE TABLE credit_par_agence AS
    SELECT Agence, SUM(Total_Credits) AS Total_Credits_Agence
    FROM CLIENT_ANALYSE
    GROUP BY Agence;
QUIT;

PROC SGPLOT DATA=credit_par_agence;
    VBAR Agence / RESPONSE=Total_Credits_Agence;
    TITLE "Montant total des credits par agence";
RUN;

/* 5. Top 10 clients (par montant total de transactions) */
PROC SORT DATA=CLIENT_ANALYSE OUT=top_clients;
    BY DESCENDING Montant_Total_Transactions;
RUN;

PROC PRINT DATA=top_clients (OBS=10);
    VAR ID_Client Agence Segment Montant_Total_Transactions Revenu_Mensuel;
    TITLE "Top 10 des clients par montant total de transactions";
RUN;

/* 6. Boxplot des soldes */
PROC SGPLOT DATA=CLIENT_ANALYSE;
    VBOX Solde_Moyen;
    TITLE "Dispersion des soldes moyens des clients";
RUN;

TITLE;


/* PARTIE 7 - INDICATEURS DE PERFORMANCE DES AGENCES */

PROC SQL;
    CREATE TABLE performance_agence AS
    SELECT Agence,
           COUNT(*)            AS Nb_Clients,
           MEAN(Revenu_Mensuel) AS Revenu_Moyen,
           MEAN(Score_Risque)   AS Risque_Moyen,
           SUM(Total_Credits)   AS Total_Credits_Agence
    FROM CLIENT_ANALYSE
    GROUP BY Agence;
QUIT;

PROC PRINT DATA=performance_agence;
    TITLE "Performance des agences";
RUN;
TITLE;
