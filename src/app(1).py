#!/usr/bin/env python3
# -*- coding: utf-8 -*-


import sys
import mysql.connector
from mysql.connector import Error

# ------------------------------------------------------------------
#  Configuration de la connexion à MySQL 
# ------------------------------------------------------------------
DB_CONFIG = {
    "host": "localhost",
    "user": "root",
    "password": "1@MySql",          
    "database": "auto_ecole",
    "port": 3306,
}


def get_connection():
    """Ouvre une connexion à la base (lève une exception en cas d'échec)."""
    return mysql.connector.connect(**DB_CONFIG)


# ------------------------------------------------------------------
#  Utilitaires d'affichage et de saisie
# ------------------------------------------------------------------
def afficher_tableau(colonnes, lignes):
    """Affiche une liste de tuples sous forme de tableau aligné."""
    if not lignes:
        print("  (aucun résultat)")
        return
    largeurs = [len(c) for c in colonnes]
    for ligne in lignes:
        for i, val in enumerate(ligne):
            largeurs[i] = max(largeurs[i], len(str(val)))
    entete = " | ".join(c.ljust(largeurs[i]) for i, c in enumerate(colonnes))
    print(entete)
    print("-+-".join("-" * w for w in largeurs))
    for ligne in lignes:
        print(" | ".join(str(val).ljust(largeurs[i]) for i, val in enumerate(ligne)))


def saisir(texte, obligatoire=True):
    """Lit une saisie clavier ; redemande si le champ obligatoire est vide."""
    while True:
        valeur = input(texte).strip()
        if valeur or not obligatoire:
            return valeur
        print("  ! Ce champ est obligatoire.")


# ------------------------------------------------------------------
#  Fonctionnalités du menu
# ------------------------------------------------------------------
def lister_eleves():
    print("\n=== Liste des élèves ===")
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("""SELECT id_eleve, nom_eleve, prenom_eleve, email_eleve,
                          date_inscription_eleve
                   FROM Eleve
                   ORDER BY nom_eleve, prenom_eleve""")
    afficher_tableau(["ID", "Nom", "Prénom", "Email", "Inscription"], cur.fetchall())
    cur.close()
    conn.close()


def ajouter_eleve():
    print("\n=== Ajouter un élève ===")
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("SELECT id_forfait, nom_forfait, prix_forfait FROM Forfait ORDER BY id_forfait")
    forfaits = cur.fetchall()
    print("Forfaits disponibles :")
    afficher_tableau(["ID", "Forfait", "Prix"], forfaits)
    ids_valides = [f[0] for f in forfaits]

    neph = saisir("NEPH (12 chiffres) : ")
    nom = saisir("Nom : ")
    prenom = saisir("Prénom : ")
    naissance = saisir("Date de naissance (AAAA-MM-JJ) : ")
    email = saisir("Email : ")
    tel = saisir("Téléphone (optionnel) : ", obligatoire=False)
    adresse = saisir("Adresse (optionnelle) : ", obligatoire=False)
    inscription = saisir("Date d'inscription (AAAA-MM-JJ) : ")
    while True:
        try:
            id_forfait = int(saisir("ID du forfait : "))
            if id_forfait in ids_valides:
                break
        except ValueError:
            pass
        print("  ! Choisis un ID de forfait présent dans la liste.")

    try:
        cur.execute("""INSERT INTO Eleve
            (neph, nom_eleve, prenom_eleve, date_naissance_eleve, email_eleve,
             telephone_eleve, adresse_eleve, date_inscription_eleve, id_forfait)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)""",
            (neph, nom, prenom, naissance, email,
             tel or None, adresse or None, inscription, id_forfait))
        conn.commit()
        print(f"  -> Élève ajouté (id = {cur.lastrowid}).")
    except Error as e:
        conn.rollback()
        print(f"  ! Erreur : {e}")
    finally:
        cur.close()
        conn.close()


def rechercher_par_critere():
    print("\n=== Rechercher des élèves par forfait ===")
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("SELECT id_forfait, nom_forfait FROM Forfait ORDER BY id_forfait")
    afficher_tableau(["ID", "Forfait"], cur.fetchall())
    try:
        id_forfait = int(saisir("ID du forfait recherché : "))
    except ValueError:
        print("  ! Identifiant invalide.")
        cur.close()
        conn.close()
        return
    cur.execute("""SELECT id_eleve, nom_eleve, prenom_eleve, email_eleve
                   FROM Eleve WHERE id_forfait = %s
                   ORDER BY nom_eleve""", (id_forfait,))
    afficher_tableau(["ID", "Nom", "Prénom", "Email"], cur.fetchall())
    cur.close()
    conn.close()


def modifier_eleve():
    print("\n=== Modifier un élève ===")
    conn = get_connection()
    cur = conn.cursor()
    try:
        id_eleve = int(saisir("ID de l'élève à modifier : "))
    except ValueError:
        print("  ! Identifiant invalide.")
        cur.close()
        conn.close()
        return
    cur.execute("""SELECT email_eleve, telephone_eleve, adresse_eleve, id_forfait
                   FROM Eleve WHERE id_eleve = %s""", (id_eleve,))
    row = cur.fetchone()
    if not row:
        print("  ! Aucun élève avec cet ID.")
        cur.close()
        conn.close()
        return
    email, tel, adresse, id_forfait = row
    print("Laisse vide pour conserver la valeur actuelle.")
    new_email = saisir(f"Email [{email}] : ", obligatoire=False) or email
    new_tel = saisir(f"Téléphone [{tel}] : ", obligatoire=False) or tel
    new_adresse = saisir(f"Adresse [{adresse}] : ", obligatoire=False) or adresse
    new_forfait = saisir(f"ID forfait [{id_forfait}] : ", obligatoire=False) or id_forfait
    try:
        cur.execute("""UPDATE Eleve
                       SET email_eleve = %s, telephone_eleve = %s,
                           adresse_eleve = %s, id_forfait = %s
                       WHERE id_eleve = %s""",
                    (new_email, new_tel, new_adresse, int(new_forfait), id_eleve))
        conn.commit()
        print(f"  -> {cur.rowcount} ligne(s) modifiée(s).")
    except Error as e:
        conn.rollback()
        print(f"  ! Erreur : {e}")
    finally:
        cur.close()
        conn.close()


def supprimer_eleve():
    print("\n=== Supprimer un élève ===")
    conn = get_connection()
    cur = conn.cursor()
    try:
        id_eleve = int(saisir("ID de l'élève à supprimer : "))
    except ValueError:
        print("  ! Identifiant invalide.")
        cur.close()
        conn.close()
        return
    cur.execute("SELECT nom_eleve, prenom_eleve FROM Eleve WHERE id_eleve = %s", (id_eleve,))
    row = cur.fetchone()
    if not row:
        print("  ! Aucun élève avec cet ID.")
        cur.close()
        conn.close()
        return
    confirm = saisir(f"Confirmer la suppression de {row[1]} {row[0]} ? (o/n) : ",
                     obligatoire=False)
    if confirm.lower() != "o":
        print("  Annulé.")
        cur.close()
        conn.close()
        return
    try:
        cur.execute("DELETE FROM Eleve WHERE id_eleve = %s", (id_eleve,))
        conn.commit()
        print(f"  -> {cur.rowcount} ligne(s) supprimée(s) "
              f"(examens et leçons associés supprimés en cascade).")
    except Error as e:
        conn.rollback()
        print(f"  ! Erreur : {e}")
    finally:
        cur.close()
        conn.close()


def statistiques():
    print("\n=== Statistiques ===")
    conn = get_connection()
    cur = conn.cursor()

    print("\n-- Nombre d'élèves par forfait --")
    cur.execute("""SELECT f.nom_forfait, COUNT(e.id_eleve)
                   FROM Forfait f
                   LEFT JOIN Eleve e ON f.id_forfait = e.id_forfait
                   GROUP BY f.id_forfait, f.nom_forfait
                   ORDER BY COUNT(e.id_eleve) DESC""")
    afficher_tableau(["Forfait", "Nb élèves"], cur.fetchall())

    print("\n-- Classement des élèves par moyenne de note de leçon --")
    cur.execute("""SELECT e.nom_eleve, e.prenom_eleve,
                          ROUND(AVG(en.note_lecon), 2), COUNT(*)
                   FROM Eleve e
                   JOIN Encadrer en ON e.id_eleve = en.id_eleve
                   GROUP BY e.id_eleve, e.nom_eleve, e.prenom_eleve
                   ORDER BY AVG(en.note_lecon) DESC, COUNT(*) DESC""")
    afficher_tableau(["Nom", "Prénom", "Moy. leçon", "Nb leçons"], cur.fetchall())
    cur.close()
    conn.close()


def recherche_mot_cle():
    print("\n=== Recherche par mot-clé ===")
    mot = saisir("Mot-clé (nom, prénom ou email) : ")
    conn = get_connection()
    cur = conn.cursor()
    like = f"%{mot}%"
    cur.execute("""SELECT id_eleve, nom_eleve, prenom_eleve, email_eleve
                   FROM Eleve
                   WHERE nom_eleve LIKE %s OR prenom_eleve LIKE %s OR email_eleve LIKE %s
                   ORDER BY nom_eleve""", (like, like, like))
    afficher_tableau(["ID", "Nom", "Prénom", "Email"], cur.fetchall())
    cur.close()
    conn.close()


def detail_eleve():
    print("\n=== Détail d'un élève ===")
    conn = get_connection()
    cur = conn.cursor()
    try:
        id_eleve = int(saisir("ID de l'élève : "))
    except ValueError:
        print("  ! Identifiant invalide.")
        cur.close()
        conn.close()
        return
    cur.execute("""SELECT e.nom_eleve, e.prenom_eleve, e.neph, e.date_naissance_eleve,
                          e.email_eleve, e.telephone_eleve, e.adresse_eleve,
                          e.date_inscription_eleve, f.nom_forfait, f.prix_forfait,
                          c.code, c.libelle
                   FROM Eleve e
                   JOIN Forfait f ON e.id_forfait = f.id_forfait
                   JOIN CategoriePermis c ON f.id_categorie = c.id_categorie
                   WHERE e.id_eleve = %s""", (id_eleve,))
    e = cur.fetchone()
    if not e:
        print("  ! Aucun élève avec cet ID.")
        cur.close()
        conn.close()
        return
    print(f"\n  {e[1]} {e[0]}  (NEPH {e[2]})")
    print(f"  Né(e) le {e[3]} | {e[4]} | {e[5] or '-'}")
    print(f"  Adresse : {e[6] or '-'}")
    print(f"  Inscrit(e) le {e[7]}")
    print(f"  Forfait : {e[8]} ({e[9]} €) — catégorie {e[10]} ({e[11]})")

    print("\n  -- Examens --")
    cur.execute("""SELECT type_exam, date_examen, resultat, note
                   FROM Examen WHERE id_eleve = %s
                   ORDER BY date_examen""", (id_eleve,))
    afficher_tableau(["Type", "Date", "Résultat", "Note"], cur.fetchall())

    print("\n  -- Leçons --")
    cur.execute("""SELECT en.date_heure, en.duree, en.type_lecon, en.note_lecon,
                          m.nom_moniteur, v.immatriculation
                   FROM Encadrer en
                   JOIN Moniteur m ON en.id_moniteur = m.id_moniteur
                   JOIN Vehicule v ON en.id_vehicule = v.id_vehicule
                   WHERE en.id_eleve = %s
                   ORDER BY en.date_heure""", (id_eleve,))
    afficher_tableau(["Date/heure", "Durée", "Type", "Note", "Moniteur", "Véhicule"],
                     cur.fetchall())
    cur.close()
    conn.close()


# ------------------------------------------------------------------
#  Boucle principale
# ------------------------------------------------------------------
MENU = """
============================================================
   ÉCOLE DE CONDUITE — Gestion des élèves
============================================================
  1. Ajouter un élève
  2. Lister tous les élèves
  3. Rechercher des élèves par critère (forfait)
  4. Modifier un élève
  5. Supprimer un élève
  6. Statistiques / classement
  7. Rechercher par mot-clé
  8. Détail d'un élève (avec données associées)
  0. Quitter
============================================================"""


def main():
    try:
        get_connection().close()
    except Error as e:
        print(f"Impossible de se connecter à MySQL : {e}")
        print("Vérifie le bloc DB_CONFIG en haut du fichier "
              "(host, user, password, database).")
        sys.exit(1)

    actions = {
        "1": ajouter_eleve,
        "2": lister_eleves,
        "3": rechercher_par_critere,
        "4": modifier_eleve,
        "5": supprimer_eleve,
        "6": statistiques,
        "7": recherche_mot_cle,
        "8": detail_eleve,
    }
    while True:
        print(MENU)
        choix = input("Ton choix : ").strip()
        if choix == "0":
            print("Au revoir !")
            break
        action = actions.get(choix)
        if action:
            try:
                action()
            except Error as e:
                print(f"  ! Erreur base de données : {e}")
        else:
            print("  ! Choix invalide.")


if __name__ == "__main__":
    main()
