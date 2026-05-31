============================================================
 PROJET ALSI61 - Bases de donnees
 Gestion d'une ecole de conduite
============================================================

------------------------------------------------------------
 1. DOMAINE CHOISI
------------------------------------------------------------
Gestion d'une ecole de conduite. L'application gere la formation
des eleves au passage des differentes categories de permis
(AM, A1, A2, B, C, D). Chaque eleve souscrit un forfait lie a une
categorie. La formation pratique repose sur des lecons reunissant
un eleve, un moniteur et un vehicule (association ternaire). Les
moniteurs sont habilites a enseigner une ou plusieurs categories.
Les eleves passent des examens (code, conduite) avec un resultat
et une note.

Entites : Eleve, Moniteur, Vehicule, CategoriePermis, Forfait, Examen.
Associations : Lecon (ternaire, table Encadrer), Habiliter (n-n),
Souscrire, Concerner, Appartenir, Passer, Porter sur.

------------------------------------------------------------
 2. PREREQUIS
------------------------------------------------------------
- MySQL 8.x installe et demarre
- Python 3.9 ou superieur
- Modules Python :
      pip install mysql-connector-python streamlit pandas

------------------------------------------------------------
 3. INSTALLATION DE LA BASE
------------------------------------------------------------
1) Executer le script de creation (cree la base 'auto_ecole',
   les tables et insere le jeu de donnees) :
      mysql -u root -p < script_creation.sql
   (ou ouvrir et executer le fichier dans MySQL Workbench)

2) (Optionnel) Tester les 15 requetes :
      mysql -u root -p auto_ecole < requetes.sql

------------------------------------------------------------
 4. CONFIGURATION DE LA CONNEXION
------------------------------------------------------------
Dans app.py ET app_streamlit.py, adapter le bloc DB_CONFIG :
      host     = "localhost"
      user     = "root"
      password = ""        <-- mettre votre mot de passe MySQL
      database = "auto_ecole"
      port     = 3306

------------------------------------------------------------
 5. LANCEMENT
------------------------------------------------------------
Application console (livrable principal) :
      python app.py

Interface Streamlit (bonus, interface web) :
      streamlit run app_streamlit.py

Les deux proposent le meme menu : ajouter, lister, rechercher par
critere, modifier, supprimer, statistiques/classement, recherche
par mot-cle, et detail d'un eleve avec ses donnees associees.

------------------------------------------------------------
 6. REGLES METIER
------------------------------------------------------------
1.  Un eleve est identifie par un numero NEPH de 12 chiffres ;
    son email est egalement unique.
2.  A l'inscription, un eleve doit avoir au moins 15 ans.
3.  Un eleve souscrit exactement un forfait ; un forfait peut
    etre souscrit par plusieurs eleves.
4.  Un forfait concerne une seule categorie de permis ; une
    categorie peut faire l'objet de plusieurs forfaits.
5.  Le prix d'un forfait est strictement positif et son nombre
    d'heures est superieur a zero.
6.  Une categorie possede un code unique (AM, A1, A2, B, C, D)
    et un age minimum reglementaire.
7.  Un moniteur possede un numero d'autorisation unique et un
    email unique.
8.  Un moniteur est habilite a enseigner une ou plusieurs
    categories ; une categorie peut etre enseignee par plusieurs
    moniteurs (relation plusieurs-a-plusieurs).
9.  Un vehicule a une immatriculation unique et appartient a une
    seule categorie de permis.
10. Un vehicule a une boite manuelle ou automatique.
11. Une lecon reunit un eleve, un moniteur et un vehicule a une
    date/heure donnee (association ternaire).
12. Une lecon porte une duree (minutes, > 0) et une note
    d'evaluation comprise entre 0 et 20.
13. Un examen est de type 'code' ou 'conduite' et concerne un
    seul eleve et une seule categorie.
14. Le resultat d'un examen vaut 'reussi', 'echoue' ou 'absent' ;
    la note (sur 20) n'est renseignee que si l'eleve s'est presente.
15. L'age d'un eleve n'est jamais stocke : il est calcule a partir
    de la date de naissance (respect de la 3FN).

------------------------------------------------------------
 7. DICTIONNAIRE DES DONNEES
------------------------------------------------------------
Table Eleve
  id_eleve                INT            PK, AUTO_INCREMENT
  neph                    VARCHAR(12)    NOT NULL, UNIQUE
  nom_eleve               VARCHAR(50)    NOT NULL
  prenom_eleve            VARCHAR(50)    NOT NULL
  date_naissance_eleve    DATE           NOT NULL
  email_eleve             VARCHAR(100)   NOT NULL, UNIQUE
  telephone_eleve         VARCHAR(20)    NULL
  adresse_eleve           VARCHAR(150)   NULL
  date_inscription_eleve  DATE           NOT NULL
  id_forfait              INT            NOT NULL, FK -> Forfait

Table Moniteur
  id_moniteur             INT            PK, AUTO_INCREMENT
  num_autorisation        VARCHAR(20)    NOT NULL, UNIQUE
  nom_moniteur            VARCHAR(50)    NOT NULL
  prenom_moniteur         VARCHAR(50)    NOT NULL
  email_moniteur          VARCHAR(100)   NOT NULL, UNIQUE
  telephone_moniteur      VARCHAR(20)    NULL
  date_embauche_moniteur  DATE           NOT NULL

Table CategoriePermis
  id_categorie            INT            PK, AUTO_INCREMENT
  code                    VARCHAR(3)     NOT NULL, UNIQUE
  libelle                 VARCHAR(100)   NOT NULL
  age_minimum             INT            NOT NULL, CHECK (> 0)

Table Forfait
  id_forfait              INT            PK, AUTO_INCREMENT
  nom_forfait             VARCHAR(50)    NOT NULL
  nb_heure                INT            NOT NULL, CHECK (> 0)
  prix_forfait            DECIMAL(8,2)   NOT NULL, CHECK (> 0)
  id_categorie            INT            NOT NULL, FK -> CategoriePermis

Table Vehicule
  id_vehicule             INT            PK, AUTO_INCREMENT
  immatriculation         VARCHAR(9)     NOT NULL, UNIQUE
  marque                  VARCHAR(50)    NOT NULL
  modele                  VARCHAR(50)    NOT NULL
  type_boite              VARCHAR(50)    NOT NULL (manuelle/automatique)
  date_mise_circulation   DATE           NULL
  id_categorie            INT            NOT NULL, FK -> CategoriePermis

Table Examen
  id_examen               INT            PK, AUTO_INCREMENT
  type_exam               VARCHAR(50)    NOT NULL (code/conduite)
  date_examen             DATE           NOT NULL
  resultat                VARCHAR(50)    NOT NULL (reussi/echoue/absent)
  note                    DECIMAL(4,2)   NULL, CHECK (0..20)
  id_categorie            INT            NOT NULL, FK -> CategoriePermis
  id_eleve                INT            NOT NULL, FK -> Eleve

Table Encadrer (association ternaire : lecon)
  id_lecon                INT            PK, AUTO_INCREMENT
  duree                   INT            NOT NULL, CHECK (> 0)
  note_lecon              DECIMAL(4,2)   NOT NULL, CHECK (0..20)
  type_lecon              VARCHAR(50)    NOT NULL
  date_heure              DATETIME       NOT NULL
  id_eleve                INT            NOT NULL, FK -> Eleve
  id_moniteur             INT            NOT NULL, FK -> Moniteur
  id_vehicule             INT            NOT NULL, FK -> Vehicule
  UNIQUE (id_moniteur, date_heure), UNIQUE (id_vehicule, date_heure)

Table Habiliter (association n-n : moniteur <-> categorie)
  id_moniteur             INT            PK, FK -> Moniteur
  id_categorie            INT            PK, FK -> CategoriePermis
  date_habilitation       DATE           NOT NULL

------------------------------------------------------------
 8. CONTENU DU DEPOT
------------------------------------------------------------
  Livrable.pdf          Rapport (domaine, regles, dictionnaire, MCD, MLD)
  script_creation.sql   DDL + DML (creation + jeu de donnees)
  requetes.sql          Les 15 requetes SQL
  src/app.py            Application console (livrable principal)
  src/app_streamlit.py  Interface Streamlit (bonus)
  README.txt            Ce fichier
============================================================
