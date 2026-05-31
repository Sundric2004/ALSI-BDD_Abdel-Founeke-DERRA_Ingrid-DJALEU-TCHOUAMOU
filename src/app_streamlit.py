# -*- coding: utf-8 -*-


import streamlit as st
import pandas as pd
import mysql.connector
from mysql.connector import Error
from datetime import date

# ------------------------------------------------------------------
#  Configuration de la connexion à MySQL — À ADAPTER À TA MACHINE
# ------------------------------------------------------------------
DB_CONFIG = {
    "host": "localhost",
    "user": "root",
    "password": "1@MySql",          
    "database": "auto_ecole",
    "port": 3306,
}


def get_connection():
    return mysql.connector.connect(**DB_CONFIG)


def lire(query, params=None):
    """Exécute un SELECT et renvoie un DataFrame pandas."""
    conn = get_connection()
    cur = conn.cursor()
    cur.execute(query, params or ())
    colonnes = [d[0] for d in cur.description]
    donnees = cur.fetchall()
    cur.close()
    conn.close()
    return pd.DataFrame(donnees, columns=colonnes)


def ecrire(query, params=None):
    """Exécute un INSERT/UPDATE/DELETE et renvoie le nombre de lignes affectées."""
    conn = get_connection()
    cur = conn.cursor()
    cur.execute(query, params or ())
    conn.commit()
    n = cur.rowcount
    cur.close()
    conn.close()
    return n


st.set_page_config(page_title="École de conduite", page_icon="🚗", layout="wide")
st.title("🚗 École de conduite — Gestion des élèves")

# Vérification de la connexion
try:
    get_connection().close()
except Error as e:
    st.error(f"Connexion MySQL impossible : {e}\nVérifie le bloc DB_CONFIG.")
    st.stop()

page = st.sidebar.radio("Menu", [
    "Lister",
    "Ajouter",
    "Rechercher par critère",
    "Modifier",
    "Supprimer",
    "Statistiques",
    "Recherche mot-clé",
    "Détail élève",
])


def libelle_eleve(df, i):
    ligne = df.set_index("id_eleve").loc[i]
    return f"{ligne['prenom_eleve']} {ligne['nom_eleve']}"


def libelle_forfait(df, i):
    return df.set_index("id_forfait").loc[i, "nom_forfait"]


# ----- Lister -----
if page == "Lister":
    st.subheader("Liste des élèves")
    st.dataframe(
        lire("""SELECT id_eleve, nom_eleve, prenom_eleve, email_eleve,
                        date_inscription_eleve
                 FROM Eleve ORDER BY nom_eleve, prenom_eleve"""),
        use_container_width=True,
    )

# ----- Ajouter -----
elif page == "Ajouter":
    st.subheader("Ajouter un élève")
    forfaits = lire("SELECT id_forfait, nom_forfait, prix_forfait FROM Forfait ORDER BY id_forfait")
    st.dataframe(forfaits, use_container_width=True)
    with st.form("ajout"):
        neph = st.text_input("NEPH (12 chiffres)")
        nom = st.text_input("Nom")
        prenom = st.text_input("Prénom")
        naissance = st.date_input(
            "Date de naissance",
            value=date(2005, 1, 1),
            min_value=date(1940, 1, 1),
            max_value=date.today(),
        )
        email = st.text_input("Email")
        tel = st.text_input("Téléphone")
        adresse = st.text_input("Adresse")
        inscription = st.date_input("Date d'inscription")
        id_forfait = st.selectbox(
            "Forfait", forfaits["id_forfait"],
            format_func=lambda i: libelle_forfait(forfaits, i),
        )
        ok = st.form_submit_button("Ajouter")
    if ok:
        try:
            ecrire("""INSERT INTO Eleve
                (neph, nom_eleve, prenom_eleve, date_naissance_eleve, email_eleve,
                 telephone_eleve, adresse_eleve, date_inscription_eleve, id_forfait)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)""",
                (neph, nom, prenom, str(naissance), email,
                 tel or None, adresse or None, str(inscription), int(id_forfait)))
            st.success("Élève ajouté avec succès.")
        except Error as e:
            st.error(f"Erreur : {e}")

# ----- Rechercher par critère -----
elif page == "Rechercher par critère":
    st.subheader("Élèves d'un forfait donné")
    forfaits = lire("SELECT id_forfait, nom_forfait FROM Forfait ORDER BY id_forfait")
    fid = st.selectbox("Forfait", forfaits["id_forfait"],
                       format_func=lambda i: libelle_forfait(forfaits, i))
    st.dataframe(
        lire("""SELECT id_eleve, nom_eleve, prenom_eleve, email_eleve
                 FROM Eleve WHERE id_forfait = %s ORDER BY nom_eleve""", (int(fid),)),
        use_container_width=True,
    )

# ----- Modifier -----
elif page == "Modifier":
    st.subheader("Modifier un élève")
    eleves = lire("SELECT id_eleve, nom_eleve, prenom_eleve FROM Eleve ORDER BY nom_eleve")
    eid = st.selectbox("Élève", eleves["id_eleve"],
                       format_func=lambda i: libelle_eleve(eleves, i))
    actuel = lire("""SELECT email_eleve, telephone_eleve, adresse_eleve, id_forfait
                     FROM Eleve WHERE id_eleve = %s""", (int(eid),))
    if not actuel.empty:
        r = actuel.iloc[0]
        with st.form("modif"):
            email = st.text_input("Email", r["email_eleve"])
            tel = st.text_input("Téléphone", r["telephone_eleve"] or "")
            adresse = st.text_input("Adresse", r["adresse_eleve"] or "")
            id_forfait = st.number_input("ID forfait", value=int(r["id_forfait"]), step=1)
            ok = st.form_submit_button("Enregistrer")
        if ok:
            try:
                n = ecrire("""UPDATE Eleve
                              SET email_eleve = %s, telephone_eleve = %s,
                                  adresse_eleve = %s, id_forfait = %s
                              WHERE id_eleve = %s""",
                           (email, tel or None, adresse or None, int(id_forfait), int(eid)))
                st.success(f"{n} ligne(s) modifiée(s).")
            except Error as e:
                st.error(f"Erreur : {e}")

# ----- Supprimer -----
elif page == "Supprimer":
    st.subheader("Supprimer un élève")
    eleves = lire("SELECT id_eleve, nom_eleve, prenom_eleve FROM Eleve ORDER BY nom_eleve")
    eid = st.selectbox("Élève", eleves["id_eleve"],
                       format_func=lambda i: libelle_eleve(eleves, i))
    st.warning("La suppression retire aussi les examens et leçons associés (ON DELETE CASCADE).")
    if st.button("Supprimer définitivement"):
        try:
            n = ecrire("DELETE FROM Eleve WHERE id_eleve = %s", (int(eid),))
            st.success(f"{n} ligne(s) supprimée(s).")
        except Error as e:
            st.error(f"Erreur : {e}")

# ----- Statistiques -----
elif page == "Statistiques":
    st.subheader("Statistiques")

    st.markdown("**Nombre d'élèves par forfait**")
    df1 = lire("""SELECT f.nom_forfait AS forfait, COUNT(e.id_eleve) AS nb_eleves
                  FROM Forfait f
                  LEFT JOIN Eleve e ON f.id_forfait = e.id_forfait
                  GROUP BY f.id_forfait, f.nom_forfait
                  ORDER BY nb_eleves DESC""")
    st.dataframe(df1, use_container_width=True)
    st.bar_chart(df1.set_index("forfait"))

    st.markdown("**Classement des élèves par moyenne de note de leçon**")
    df2 = lire("""SELECT CONCAT(e.prenom_eleve, ' ', e.nom_eleve) AS eleve,
                         ROUND(AVG(en.note_lecon), 2) AS moyenne, COUNT(*) AS nb_lecons
                  FROM Eleve e
                  JOIN Encadrer en ON e.id_eleve = en.id_eleve
                  GROUP BY e.id_eleve, eleve
                  ORDER BY moyenne DESC, nb_lecons DESC""")
    st.dataframe(df2, use_container_width=True)

# ----- Recherche mot-clé -----
elif page == "Recherche mot-clé":
    st.subheader("Recherche par mot-clé")
    mot = st.text_input("Mot-clé (nom, prénom ou email)")
    if mot:
        like = f"%{mot}%"
        st.dataframe(
            lire("""SELECT id_eleve, nom_eleve, prenom_eleve, email_eleve
                     FROM Eleve
                     WHERE nom_eleve LIKE %s OR prenom_eleve LIKE %s OR email_eleve LIKE %s
                     ORDER BY nom_eleve""", (like, like, like)),
            use_container_width=True,
        )

# ----- Détail élève -----
elif page == "Détail élève":
    st.subheader("Détail d'un élève")
    eleves = lire("SELECT id_eleve, nom_eleve, prenom_eleve FROM Eleve ORDER BY nom_eleve")
    eid = st.selectbox("Élève", eleves["id_eleve"],
                       format_func=lambda i: libelle_eleve(eleves, i))
    info = lire("""SELECT e.nom_eleve, e.prenom_eleve, e.neph, e.date_naissance_eleve,
                          e.email_eleve, e.telephone_eleve, e.adresse_eleve,
                          e.date_inscription_eleve, f.nom_forfait, f.prix_forfait,
                          c.code, c.libelle
                   FROM Eleve e
                   JOIN Forfait f ON e.id_forfait = f.id_forfait
                   JOIN CategoriePermis c ON f.id_categorie = c.id_categorie
                   WHERE e.id_eleve = %s""", (int(eid),))
    if not info.empty:
        r = info.iloc[0]
        st.markdown(f"### {r['prenom_eleve']} {r['nom_eleve']}")
        col1, col2 = st.columns(2)
        col1.write(f"**NEPH :** {r['neph']}")
        col1.write(f"**Naissance :** {r['date_naissance_eleve']}")
        col1.write(f"**Email :** {r['email_eleve']}")
        col1.write(f"**Téléphone :** {r['telephone_eleve'] or '-'}")
        col2.write(f"**Adresse :** {r['adresse_eleve'] or '-'}")
        col2.write(f"**Inscription :** {r['date_inscription_eleve']}")
        col2.write(f"**Forfait :** {r['nom_forfait']} ({r['prix_forfait']} €)")
        col2.write(f"**Catégorie :** {r['code']} — {r['libelle']}")

        st.markdown("**Examens**")
        st.dataframe(
            lire("""SELECT type_exam, date_examen, resultat, note
                     FROM Examen WHERE id_eleve = %s ORDER BY date_examen""", (int(eid),)),
            use_container_width=True,
        )
        st.markdown("**Leçons**")
        st.dataframe(
            lire("""SELECT en.date_heure, en.duree, en.type_lecon, en.note_lecon,
                            m.nom_moniteur AS moniteur, v.immatriculation AS vehicule
                     FROM Encadrer en
                     JOIN Moniteur m ON en.id_moniteur = m.id_moniteur
                     JOIN Vehicule v ON en.id_vehicule = v.id_vehicule
                     WHERE en.id_eleve = %s ORDER BY en.date_heure""", (int(eid),)),
            use_container_width=True,
        )