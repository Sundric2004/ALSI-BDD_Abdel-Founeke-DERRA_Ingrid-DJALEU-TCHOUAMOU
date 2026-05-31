-- ============================================================
--  15 requêtes SQL — Gestion d'une école de conduite
-- ============================================================

USE auto_ecole;

-- ============================================================
--  1  Requêtes de base (SELECT, WHERE, ORDER BY)
-- ============================================================

-- R1 : liste de tous les élèves (entité principale), par ordre alphabétique.
SELECT *
FROM Eleve
ORDER BY nom_eleve ASC, prenom_eleve ASC;

-- R2 : élèves de moins de 22 ans.
SELECT id_eleve, nom_eleve, prenom_eleve, date_naissance_eleve,
       TIMESTAMPDIFF(YEAR, date_naissance_eleve, CURDATE()) AS age
FROM Eleve
WHERE TIMESTAMPDIFF(YEAR, date_naissance_eleve, CURDATE()) < 22
ORDER BY age ASC;

-- R3 : tous les véhicules d'une catégorie passée en paramètre (ici id_categorie = 4 -> permis B).
SELECT *
FROM Vehicule
WHERE id_categorie = 4;

-- ============================================================
--  2  Requêtes avec jointures
-- ============================================================

-- R4 : chaque élève avec le nom et le prix de son forfait (INNER JOIN).
SELECT e.nom_eleve, e.prenom_eleve, f.nom_forfait, f.prix_forfait
FROM Eleve e
INNER JOIN Forfait f ON e.id_forfait = f.id_forfait
ORDER BY e.nom_eleve;

-- R5 : tous les élèves, même ceux qui n'ont pas encore passé d'examen (LEFT JOIN).
SELECT e.nom_eleve, e.prenom_eleve, x.type_exam, x.date_examen, x.resultat
FROM Eleve e
LEFT JOIN Examen x ON e.id_eleve = x.id_eleve
ORDER BY e.nom_eleve;

-- R6 : total des minutes de leçon par catégorie de permis (agrégat combinant 3 tables).
SELECT c.code, c.libelle, SUM(en.duree) AS total_minutes
FROM Encadrer en
JOIN Vehicule v ON en.id_vehicule = v.id_vehicule
JOIN CategoriePermis c ON v.id_categorie = c.id_categorie
GROUP BY c.id_categorie, c.code, c.libelle
ORDER BY total_minutes DESC;

-- ============================================================
--  3  Requêtes avec agrégats (GROUP BY, HAVING)
-- ============================================================

-- R7 : nombre de leçons données par moniteur, trié décroissant.
SELECT m.nom_moniteur, m.prenom_moniteur, COUNT(*) AS nb_lecons
FROM Moniteur m
JOIN Encadrer en ON m.id_moniteur = en.id_moniteur
GROUP BY m.id_moniteur, m.nom_moniteur, m.prenom_moniteur
ORDER BY nb_lecons DESC;

-- R8 : moniteurs ayant donné plus de 4 leçons (agrégat supérieur à un seuil).
SELECT m.nom_moniteur, m.prenom_moniteur, COUNT(*) AS nb_lecons
FROM Moniteur m
JOIN Encadrer en ON m.id_moniteur = en.id_moniteur
GROUP BY m.id_moniteur, m.nom_moniteur, m.prenom_moniteur
HAVING COUNT(*) > 4
ORDER BY nb_lecons DESC;

-- R9 : note moyenne d'examen par catégorie, limitée aux catégories de moyenne > 14 (HAVING).
SELECT c.code, c.libelle, ROUND(AVG(x.note), 2) AS moyenne_note
FROM Examen x
JOIN CategoriePermis c ON x.id_categorie = c.id_categorie
GROUP BY c.id_categorie, c.code, c.libelle
HAVING AVG(x.note) > 14
ORDER BY moyenne_note DESC;

-- R10 : meilleure note d'examen (MAX) par catégorie de permis.
SELECT c.code, c.libelle, MAX(x.note) AS meilleure_note
FROM Examen x
JOIN CategoriePermis c ON x.id_categorie = c.id_categorie
GROUP BY c.id_categorie, c.code, c.libelle
ORDER BY meilleure_note DESC;

-- ============================================================
--  4  Requêtes avancées (sous-requêtes, EXISTS, RANK)
-- ============================================================

-- R11 : examens dont la note dépasse la moyenne globale (sous-requête scalaire).
SELECT x.id_examen, x.type_exam, x.note, e.nom_eleve, e.prenom_eleve
FROM Examen x
JOIN Eleve e ON x.id_eleve = e.id_eleve
WHERE x.note > (SELECT AVG(note) FROM Examen)
ORDER BY x.note DESC;

-- R12 : élèves ayant réussi TOUS leurs examens (NOT EXISTS), en excluant ceux sans examen.
SELECT e.id_eleve, e.nom_eleve, e.prenom_eleve
FROM Eleve e
WHERE EXISTS (SELECT 1 FROM Examen x WHERE x.id_eleve = e.id_eleve)
  AND NOT EXISTS (
        SELECT 1 FROM Examen x
        WHERE x.id_eleve = e.id_eleve
          AND x.resultat <> 'réussi'
  )
ORDER BY e.nom_eleve;

-- R13 : classement des élèves par note moyenne de leçon,
--       départage par nombre de leçons (fonction de fenêtrage RANK()).
SELECT el.nom_eleve, el.prenom_eleve,
       ROUND(AVG(en.note_lecon), 2) AS moyenne_lecon,
       COUNT(*) AS nb_lecons,
       RANK() OVER (ORDER BY AVG(en.note_lecon) DESC, COUNT(*) DESC) AS rang
FROM Eleve el
JOIN Encadrer en ON el.id_eleve = en.id_eleve
GROUP BY el.id_eleve, el.nom_eleve, el.prenom_eleve
ORDER BY rang;

-- R14 : moniteurs habilités sur au moins deux catégories différentes
--       (sous-requête avec COUNT DISTINCT).
SELECT m.id_moniteur, m.nom_moniteur, m.prenom_moniteur
FROM Moniteur m
WHERE (SELECT COUNT(DISTINCT h.id_categorie)
       FROM Habiliter h
       WHERE h.id_moniteur = m.id_moniteur) >= 2
ORDER BY m.nom_moniteur;

-- R15 : pour chaque catégorie, l'examen ayant la meilleure note ;
--       en cas d'égalité, les deux sont affichés (sous-requête corrélée).
SELECT c.code, c.libelle, el.nom_eleve, el.prenom_eleve, x.note
FROM Examen x
JOIN CategoriePermis c ON x.id_categorie = c.id_categorie
JOIN Eleve el ON x.id_eleve = el.id_eleve
WHERE x.note = (
        SELECT MAX(x2.note)
        FROM Examen x2
        WHERE x2.id_categorie = x.id_categorie
  )
ORDER BY c.code, el.nom_eleve;