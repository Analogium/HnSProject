# Fichiers de référence

`personnage_v1.json`, `personnage_v2.json` et `personnage_v3.json` sont des
sauvegardes **écrites à la main**, versionnées avec le projet, et relues à chaque
campagne par `tests/unit/test_sauvegarde.gd`.

La v1 est le format d'avant le jalon 5 : elle représente les fichiers déjà sur
les disques des joueurs, et elle doit continuer de se lire — ses objets prennent
alors le niveau 1. La v2 est celui du jalon 5, avec le niveau d'objet : relue
aujourd'hui, elle arrive avec un râtelier vide et la barre de départ. La v3 est
le format qu'on écrit, avec les manuels, le râtelier et la barre.

Elle n'est pas là pour tester la sérialisation — l'aller-retour en mémoire s'en
charge, et il passerait tout aussi bien si les deux côtés changeaient de nom de
champ en même temps. Elle est là pour attraper exactement ça : le jour où
`points_a_placer` devient `points`, ce fichier-ci ne se relira plus, et c'est
toutes les sauvegardes des joueurs qui ne se seraient plus relues.

**Ne pas les régénérer pour faire passer un test.** Si l'une ne se lit plus,
soit le format a changé — et il faut alors monter `Personnage.VERSION`, ajouter
le numéro à `Personnage.VERSIONS_LUES` et écrire un fichier de référence de plus
— soit c'est une régression.

Le fichier de la version la plus ancienne ne se supprime que le jour où l'on
décide de ne plus lire ses sauvegardes, et ce jour-là c'est une décision, pas un
nettoyage.
