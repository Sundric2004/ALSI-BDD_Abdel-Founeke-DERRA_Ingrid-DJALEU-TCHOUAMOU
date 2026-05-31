-- ============================================================
--  Création de la base — Gestion d'une école de conduite
--  Partie : DDL (le jeu de données DML sera ajouté à la suite)
-- ============================================================

SET NAMES utf8mb4;

CREATE DATABASE IF NOT EXISTS auto_ecole
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
USE auto_ecole;

-- Suppression dans l'ordre inverse des dépendances (ré-exécution)
DROP TABLE IF EXISTS Habiliter;
DROP TABLE IF EXISTS Encadrer;
DROP TABLE IF EXISTS Examen;
DROP TABLE IF EXISTS Eleve;
DROP TABLE IF EXISTS Forfait;
DROP TABLE IF EXISTS Vehicule;
DROP TABLE IF EXISTS CategoriePermis;
DROP TABLE IF EXISTS Moniteur;

CREATE TABLE Moniteur(
   id_moniteur INT AUTO_INCREMENT,
   num_autorisation VARCHAR(20) NOT NULL,
   nom_moniteur VARCHAR(50) NOT NULL,
   prenom_moniteur VARCHAR(50) NOT NULL,
   email_moniteur VARCHAR(100) NOT NULL,
   telephone_moniteur VARCHAR(20),
   date_embauche_moniteur DATE NOT NULL,
   PRIMARY KEY(id_moniteur),
   UNIQUE(num_autorisation),
   UNIQUE(email_moniteur)
) ENGINE=InnoDB;

CREATE TABLE CategoriePermis(
   id_categorie INT AUTO_INCREMENT,
   code VARCHAR(3) NOT NULL,
   libelle VARCHAR(100) NOT NULL,
   age_minimum INT NOT NULL,
   PRIMARY KEY(id_categorie),
   UNIQUE(code),
   CHECK (age_minimum > 0)
) ENGINE=InnoDB;

CREATE TABLE Vehicule(
   id_vehicule INT AUTO_INCREMENT,
   immatriculation VARCHAR(9) NOT NULL,
   marque VARCHAR(50) NOT NULL,
   modele VARCHAR(50) NOT NULL,
   type_boite VARCHAR(50) NOT NULL,
   date_mise_circulation DATE,
   id_categorie INT NOT NULL,
   PRIMARY KEY(id_vehicule),
   UNIQUE(immatriculation),
   FOREIGN KEY(id_categorie) REFERENCES CategoriePermis(id_categorie)
       ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE Forfait(
   id_forfait INT AUTO_INCREMENT,
   nom_forfait VARCHAR(50) NOT NULL,
   nb_heure INT NOT NULL,
   prix_forfait DECIMAL(8,2) NOT NULL,
   id_categorie INT NOT NULL,
   PRIMARY KEY(id_forfait),
   CHECK (nb_heure > 0),
   CHECK (prix_forfait > 0),
   FOREIGN KEY(id_categorie) REFERENCES CategoriePermis(id_categorie)
       ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE Eleve(
   id_eleve INT AUTO_INCREMENT,
   neph VARCHAR(12) NOT NULL,
   nom_eleve VARCHAR(50) NOT NULL,
   prenom_eleve VARCHAR(50) NOT NULL,
   date_naissance_eleve DATE NOT NULL,
   email_eleve VARCHAR(100) NOT NULL,
   telephone_eleve VARCHAR(20),
   adresse_eleve VARCHAR(150),
   date_inscription_eleve DATE NOT NULL,
   id_forfait INT NOT NULL,
   PRIMARY KEY(id_eleve),
   UNIQUE(neph),
   UNIQUE(email_eleve),
   FOREIGN KEY(id_forfait) REFERENCES Forfait(id_forfait)
       ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE Examen(
   id_examen INT AUTO_INCREMENT,
   type_exam VARCHAR(50) NOT NULL,
   date_examen DATE NOT NULL,
   resultat VARCHAR(50) NOT NULL,
   note DECIMAL(4,2),
   id_categorie INT NOT NULL,
   id_eleve INT NOT NULL,
   PRIMARY KEY(id_examen),
   CHECK (note IS NULL OR note BETWEEN 0 AND 20),
   FOREIGN KEY(id_categorie) REFERENCES CategoriePermis(id_categorie)
       ON DELETE RESTRICT ON UPDATE CASCADE,
   FOREIGN KEY(id_eleve) REFERENCES Eleve(id_eleve)
       ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE Encadrer(
   id_lecon INT AUTO_INCREMENT,
   duree INT NOT NULL,
   note_lecon DECIMAL(4,2) NOT NULL,
   type_lecon VARCHAR(50) NOT NULL,
   date_heure DATETIME NOT NULL,
   id_eleve INT NOT NULL,
   id_moniteur INT NOT NULL,
   id_vehicule INT NOT NULL,
   PRIMARY KEY(id_lecon),
   UNIQUE(id_moniteur, date_heure),
   UNIQUE(id_vehicule, date_heure),
   CHECK (duree > 0),
   CHECK (note_lecon BETWEEN 0 AND 20),
   FOREIGN KEY(id_eleve) REFERENCES Eleve(id_eleve)
       ON DELETE CASCADE ON UPDATE CASCADE,
   FOREIGN KEY(id_moniteur) REFERENCES Moniteur(id_moniteur)
       ON DELETE RESTRICT ON UPDATE CASCADE,
   FOREIGN KEY(id_vehicule) REFERENCES Vehicule(id_vehicule)
       ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE Habiliter(
   id_moniteur INT,
   id_categorie INT,
   date_habilitation DATE NOT NULL,
   PRIMARY KEY(id_moniteur, id_categorie),
   FOREIGN KEY(id_moniteur) REFERENCES Moniteur(id_moniteur)
       ON DELETE CASCADE ON UPDATE CASCADE,
   FOREIGN KEY(id_categorie) REFERENCES CategoriePermis(id_categorie)
       ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ============================================================
--  JEU DE DONNÉES (DML)
-- ============================================================

-- --- Catégories de permis ---
INSERT INTO CategoriePermis (id_categorie, code, libelle, age_minimum) VALUES
(1,'AM','Cyclomoteur / scooter léger',14),
(2,'A1','Motocyclette légère 125 cm³',16),
(3,'A2','Motocyclette intermédiaire',18),
(4,'B','Voiture / véhicule léger',17),
(5,'C','Poids lourd',21),
(6,'D','Transport en commun',24);

-- --- Moniteurs ---
INSERT INTO Moniteur (id_moniteur, num_autorisation, nom_moniteur, prenom_moniteur, email_moniteur, telephone_moniteur, date_embauche_moniteur) VALUES
(1,'AE075001','Martin','Lucas','lucas.martin@autoecole.fr','0612345601','2018-09-01'),
(2,'AE075002','Dubois','Sophie','sophie.dubois@autoecole.fr','0612345602','2019-03-15'),
(3,'AE075003','Bernard','Karim','karim.bernard@autoecole.fr','0612345603','2020-01-10'),
(4,'AE075004','Petit','Julie','julie.petit@autoecole.fr','0612345604','2021-06-01'),
(5,'AE075005','Moreau','Thomas','thomas.moreau@autoecole.fr','0612345605','2017-11-20'),
(6,'AE075006','Laurent','Nadia','nadia.laurent@autoecole.fr','0612345606','2022-02-14'),
(7,'AE075007','Garcia','Antoine','antoine.garcia@autoecole.fr','0612345607','2016-05-05'),
(8,'AE075008','Roux','Émilie','emilie.roux@autoecole.fr','0612345608','2023-09-01');

-- --- Forfaits ---
INSERT INTO Forfait (id_forfait, nom_forfait, nb_heure, prix_forfait, id_categorie) VALUES
(1,'Permis B - 20h',20,1190.00,4),
(2,'Permis B - 30h',30,1490.00,4),
(3,'Permis B Accéléré',25,1690.00,4),
(4,'Conduite accompagnée (AAC)',20,1290.00,4),
(5,'Permis A2 - 20h',20,990.00,3),
(6,'Permis A1 Scooter',15,790.00,2),
(7,'Permis AM (BSR)',8,350.00,1),
(8,'Permis C Pro',30,2490.00,5),
(9,'Permis D Transport',30,2990.00,6);

-- --- Véhicules ---
INSERT INTO Vehicule (id_vehicule, immatriculation, marque, modele, type_boite, date_mise_circulation, id_categorie) VALUES
(1,'AA-123-BC','Renault','Clio','manuelle','2021-03-01',4),
(2,'AB-456-CD','Peugeot','208','manuelle','2020-06-15',4),
(3,'AC-789-DE','Citroën','C3','automatique','2022-01-10',4),
(4,'AD-012-EF','Volkswagen','Polo','manuelle','2019-09-20',4),
(5,'AE-345-FG','Toyota','Yaris','automatique','2023-02-01',4),
(6,'AF-678-GH','Yamaha','MT-07','manuelle','2021-05-01',3),
(7,'AG-901-HI','Honda','CB125R','manuelle','2020-04-01',2),
(8,'AH-234-IJ','Piaggio','Liberty 50','automatique','2022-07-01',1),
(9,'AI-567-JK','Renault Trucks','D Wide','manuelle','2018-01-01',5),
(10,'AJ-890-KL','Iveco','Crossway','manuelle','2017-03-01',6);

-- --- Élèves ---
INSERT INTO Eleve (id_eleve, neph, nom_eleve, prenom_eleve, date_naissance_eleve, email_eleve, telephone_eleve, adresse_eleve, date_inscription_eleve, id_forfait) VALUES
(1,'100000000001','Durand','Emma','2005-04-12','emma.durand@email.fr','0708090101','12 rue de Paris, 75011 Paris','2024-01-15',1),
(2,'100000000002','Lefebvre','Hugo','2004-11-03','hugo.lefebvre@email.fr','0708090102','5 av. Victor Hugo, 75016 Paris','2024-02-01',2),
(3,'100000000003','Mercier','Léa','2006-07-22','lea.mercier@email.fr','0708090103','8 rue du Bac, 75007 Paris','2024-03-10',4),
(4,'100000000004','Blanc','Nathan','2003-02-18','nathan.blanc@email.fr','0708090104','22 bd Voltaire, 75011 Paris','2023-11-20',1),
(5,'100000000005','Guérin','Chloé','2005-09-30','chloe.guerin@email.fr','0708090105','3 rue Mouffetard, 75005 Paris','2024-01-05',3),
(6,'100000000006','Faure','Lucas','2002-12-25','lucas.faure@email.fr','0708090106','40 rue Oberkampf, 75011 Paris','2023-10-01',2),
(7,'100000000007','Rousseau','Manon','2006-01-14','manon.rousseau@email.fr','0708090107','17 rue de Rivoli, 75004 Paris','2024-04-01',4),
(8,'100000000008','Vincent','Théo','2004-05-08','theo.vincent@email.fr','0708090108','9 rue Saint-Denis, 75001 Paris','2024-02-15',5),
(9,'100000000009','Muller','Camille','2005-03-19','camille.muller@email.fr','0708090109','2 place de la Nation, 75012 Paris','2024-03-01',1),
(10,'100000000010','Lemoine','Jules','2001-08-11','jules.lemoine@email.fr','0708090110','55 rue de Vaugirard, 75015 Paris','2023-09-15',6),
(11,'100000000011','Girard','Sarah','2006-10-05','sarah.girard@email.fr','0708090111','30 av. des Gobelins, 75013 Paris','2024-05-01',7),
(12,'100000000012','André','Maxime','2003-06-27','maxime.andre@email.fr','0708090112','14 rue Lafayette, 75009 Paris','2023-12-10',2),
(13,'100000000013','Lefèvre','Inès','2005-11-29','ines.lefevre@email.fr','0708090113','7 rue de Belleville, 75019 Paris','2024-01-20',1),
(14,'100000000014','Mercier','Paul','2000-04-03','paul.mercier@email.fr','0708090114','60 bd Magenta, 75010 Paris','2023-08-01',8),
(15,'100000000015','Bonnet','Lucie','2004-07-16','lucie.bonnet@email.fr','0708090115','21 rue Montorgueil, 75002 Paris','2024-02-28',3),
(16,'100000000016','Dupont','Adam','2006-02-09','adam.dupont@email.fr','0708090116','11 rue de Charonne, 75011 Paris','2024-04-15',4),
(17,'100000000017','Lambert','Jade','2005-12-01','jade.lambert@email.fr','0708090117','4 rue Cler, 75007 Paris','2024-03-22',1),
(18,'100000000018','Fontaine','Noah','1999-10-20','noah.fontaine@email.fr','0708090118','33 av. de la République, 75011 Paris','2023-07-10',9),
(19,'100000000019','Robin','Eva','2004-09-14','eva.robin@email.fr','0708090119','18 rue des Martyrs, 75009 Paris','2024-01-08',2),
(20,'100000000020','Garnier','Tom','2006-05-30','tom.garnier@email.fr','0708090120','25 rue du Temple, 75003 Paris','2024-05-20',5),
(21,'100000000021','Petit','Louis','2006-08-15','louis.petit@email.fr','0708090121','9 rue Lecourbe, 75015 Paris','2024-05-28',1);

-- --- Examens (note sur 20 ; NULL si l'élève était absent) ---
INSERT INTO Examen (id_examen, type_exam, date_examen, resultat, note, id_categorie, id_eleve) VALUES
(1,'code','2024-03-05','réussi',18.00,4,1),
(2,'conduite','2024-05-10','réussi',15.50,4,1),
(3,'code','2024-04-02','réussi',16.00,4,2),
(4,'conduite','2024-06-01','échoué',8.00,4,2),
(5,'conduite','2024-07-15','réussi',13.00,4,2),
(6,'code','2024-04-20','échoué',9.50,4,3),
(7,'code','2024-05-18','réussi',17.00,4,3),
(8,'code','2024-01-10','réussi',19.00,4,4),
(9,'conduite','2024-03-22','réussi',16.50,4,4),
(10,'code','2024-02-15','réussi',14.00,4,5),
(11,'conduite','2024-04-30','échoué',7.50,4,5),
(12,'code','2023-12-05','réussi',19.00,4,6),
(13,'conduite','2024-02-20','réussi',17.00,4,6),
(14,'code','2024-05-12','absent',NULL,4,7),
(15,'code','2024-06-10','réussi',15.00,4,7),
(16,'code','2024-03-08','réussi',16.00,3,8),
(17,'conduite','2024-05-25','réussi',14.50,3,8),
(18,'code','2024-04-14','réussi',13.50,4,9),
(19,'code','2023-11-20','réussi',17.50,2,10),
(20,'conduite','2024-01-15','réussi',15.00,2,10),
(21,'code','2024-06-01','réussi',18.00,1,11),
(22,'code','2024-01-25','échoué',10.00,4,12),
(23,'code','2024-02-28','réussi',14.00,4,12),
(24,'conduite','2024-05-05','réussi',16.00,4,12),
(25,'code','2024-03-30','réussi',15.50,4,13),
(26,'code','2023-09-10','réussi',19.50,5,14),
(27,'conduite','2024-01-20','réussi',17.00,5,14),
(28,'code','2024-04-22','absent',NULL,4,15),
(29,'code','2024-05-20','réussi',13.00,4,16),
(30,'code','2024-04-10','réussi',16.50,4,17),
(31,'code','2023-08-15','réussi',18.00,6,18),
(32,'conduite','2023-12-10','réussi',15.50,6,18),
(33,'code','2024-02-10','réussi',14.50,4,19),
(34,'code','2024-06-05','réussi',17.00,3,20);

-- --- Leçons (association ternaire Élève × Moniteur × Véhicule) ---
INSERT INTO Encadrer (id_lecon, duree, note_lecon, type_lecon, date_heure, id_eleve, id_moniteur, id_vehicule) VALUES
(1,60,12.00,'circulation','2024-02-01 09:00:00',1,1,1),
(2,90,13.50,'circulation','2024-02-08 09:00:00',1,1,1),
(3,60,14.00,'manoeuvre','2024-02-15 14:00:00',1,2,2),
(4,90,11.00,'circulation','2024-02-02 09:00:00',2,1,1),
(5,60,12.50,'plateau','2024-02-09 10:00:00',2,2,2),
(6,120,15.00,'autoroute','2024-03-01 10:00:00',2,2,2),
(7,60,10.50,'circulation','2024-03-12 11:00:00',3,3,3),
(8,90,12.00,'manoeuvre','2024-03-19 11:00:00',3,3,3),
(9,60,16.00,'circulation','2024-01-10 08:00:00',4,1,4),
(10,90,17.00,'autoroute','2024-01-17 08:00:00',4,5,5),
(11,60,11.50,'circulation','2024-01-20 13:00:00',5,4,3),
(12,90,13.00,'circulation','2024-01-27 13:00:00',5,4,3),
(13,60,15.50,'manoeuvre','2023-12-01 09:00:00',6,6,4),
(14,120,16.50,'autoroute','2023-12-08 09:00:00',6,6,4),
(15,60,12.00,'circulation','2024-04-05 15:00:00',7,2,1),
(16,90,13.50,'circulation','2024-04-12 15:00:00',7,3,2),
(17,60,14.00,'plateau','2024-03-15 10:00:00',8,1,6),
(18,90,15.00,'circulation','2024-03-22 10:00:00',8,4,6),
(19,60,13.00,'circulation','2024-04-01 09:00:00',9,5,5),
(20,90,14.50,'manoeuvre','2024-04-08 09:00:00',9,2,3),
(21,60,16.00,'plateau','2023-11-10 14:00:00',10,7,7),
(22,90,17.50,'circulation','2023-11-17 14:00:00',10,3,7),
(23,45,18.00,'circulation','2024-05-02 16:00:00',11,3,8),
(24,60,17.00,'circulation','2024-05-09 16:00:00',11,7,8),
(25,60,11.00,'circulation','2023-12-15 11:00:00',12,6,4),
(26,90,13.00,'manoeuvre','2024-01-05 11:00:00',12,1,1),
(27,120,16.00,'autoroute','2024-04-20 11:00:00',12,2,2),
(28,60,12.50,'circulation','2024-01-25 08:00:00',13,4,3),
(29,120,18.50,'circulation','2023-09-20 07:00:00',14,5,9),
(30,120,19.00,'autoroute','2023-10-04 07:00:00',14,5,9),
(31,60,13.50,'circulation','2024-03-01 13:00:00',15,4,5),
(32,60,12.00,'manoeuvre','2024-04-18 15:00:00',16,6,4),
(33,60,14.00,'circulation','2024-03-20 09:00:00',17,1,1),
(34,120,16.00,'circulation','2023-08-20 07:00:00',18,8,10),
(35,120,17.00,'autoroute','2023-09-01 07:00:00',18,8,10),
(36,60,13.00,'circulation','2024-02-12 10:00:00',19,2,2),
(37,90,14.00,'manoeuvre','2024-02-19 10:00:00',19,6,3),
(38,60,15.00,'plateau','2024-04-25 11:00:00',20,7,6);

-- --- Habilitations (Moniteur ↔ Catégorie : relation plusieurs-à-plusieurs) ---
INSERT INTO Habiliter (id_moniteur, id_categorie, date_habilitation) VALUES
(1,4,'2018-09-01'),
(1,3,'2020-05-01'),
(2,4,'2019-03-15'),
(3,4,'2020-01-10'),
(3,2,'2020-01-10'),
(3,1,'2021-04-01'),
(4,4,'2021-06-01'),
(4,3,'2022-01-15'),
(5,4,'2017-11-20'),
(5,5,'2018-03-01'),
(6,4,'2022-02-14'),
(7,2,'2016-05-05'),
(7,3,'2017-09-01'),
(7,1,'2016-05-05'),
(8,4,'2023-09-01'),
(8,6,'2023-09-01');