# Fichiers de référence

`personnage_v1.json` est une sauvegarde **écrite à la main**, versionnée avec le
projet, et relue à chaque campagne par `tests/unit/test_sauvegarde.gd`.

Elle n'est pas là pour tester la sérialisation — l'aller-retour en mémoire s'en
charge, et il passerait tout aussi bien si les deux côtés changeaient de nom de
champ en même temps. Elle est là pour attraper exactement ça : le jour où
`points_a_placer` devient `points`, ce fichier-ci ne se relira plus, et c'est
toutes les sauvegardes des joueurs qui ne se seraient plus relues.

**Ne pas la régénérer pour faire passer un test.** Si elle ne se lit plus, soit
le format a changé — et il faut alors monter `Personnage.VERSION` et écrire la
conversion — soit c'est une régression.
