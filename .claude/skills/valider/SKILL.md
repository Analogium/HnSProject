---
name: valider
description: Passe de validation à lancer après chaque fonctionnalité implémentée — écrire les tests qui manquent, lancer la suite GUT complète, vérifier le rendu sur capture réelle si l'interface a bougé, remesurer si une boucle chaude a bougé, nettoyer, puis rendre un compte honnête. À invoquer quand une fonctionnalité est terminée, avant d'annoncer qu'elle marche.
---

# Valider une fonctionnalité

Le code qui compile n'est pas du code vérifié, et une suite qui passe sur du code
non couvert ne vérifie rien non plus. Cette passe se fait **avant** d'annoncer
que la fonctionnalité marche, jamais après que l'utilisateur ait demandé.

## 1. Écrire d'abord les tests qui manquent

C'est l'étape qu'on est tenté de sauter, et c'est celle qui compte. Lancer une
suite qui ne couvre pas ce qu'on vient d'écrire donne une confiance fausse.

Pour chaque chose ajoutée, se demander **où elle tombe** :

| Ce qui a été ajouté | Où le test va |
|---|---|
| Une formule, un format, une règle sans nœud | `tests/unit/` |
| Un comportement qui a besoin de l'arbre de scènes ou de la physique | `tests/integration/` |
| Une boucle de jeu complète, un déterminisme, une tenue dans la durée | `tests/e2e/` |

La frontière n'est pas « petit / gros » mais **« a besoin du moteur ou non »**.
Une Area2D hors de l'arbre n'a pas de `global_position`, un `_ready` ne s'exécute
pas : tout ce qui touche à un nœud est de l'intégration, même pour tester une
seule fonction.

Ce qui mérite un test, par ordre de rendement :

- **l'invariant qu'on vient d'établir** — « l'armure ne couvre que le physique »,
  « un objet retiré ne laisse rien derrière lui » ;
- **le garde-fou** — un plafond, un plancher, une division par zéro, une valeur
  négative. Ce sont eux qui cassent en silence ;
- **la table indexée par un enum** — une entrée oubliée donne un accès hors
  bornes en plein combat plutôt qu'ici ;
- **le contraire du test précédent.** Un test « la même graine redonne la même
  zone » passe aussi sur une génération cassée qui rend toujours la même chose ;
  il lui faut son jumeau « deux graines donnent deux zones » ;
- **ce que le joueur ne peut pas vérifier lui-même** — qu'un `.tres` du disque
  n'a pas été écrit, qu'un affixe vise un champ qui existe.

Nommer les tests en français, en phrase : `test_un_objet_retire_ne_laisse_rien`
se relit dans le rapport d'échec, `test_equip_2` non.

## 2. Lancer la suite

```bash
tests/run.sh              # tout (~22 s)
tests/run.sh unit         # unitaires seuls (<1 s), pendant qu'on itère
tests/run.sh integration
tests/run.sh e2e          # lent, mais c'est lui qui attrape les surprises
```

Le lanceur recopie le projet dans un dossier temporaire avant de l'exécuter :
l'éditeur de l'utilisateur est ouvert sur le vrai dossier, et lancer Godot
dessus lui réimporte son cache sous les pieds. Il nettoie tout seul, y compris
sur interruption, et **cible ses processus par ligne de commande** — jamais par
nom d'image, ce qui fermerait l'éditeur.

Sortie 0 = tout passe. Sortie 1 = au moins un échec. Sortie 2 = Godot introuvable.

## 3. Quand un test échoue, chercher lequel des deux a tort

Un échec ne dit pas encore qui a le défaut. Les deux cas se sont produits :

- **le code a tort** — le tirage d'esquive consommait `Game.rng` même à 0 %
  d'esquive, ce qui aurait décalé toutes les graines de zone tirées ensuite ;
- **le test a tort** — un test affirmait qu'un objet ne peut pas porter deux
  affixes visant la même statistique. C'est faux par conception : « +6 dégâts »
  et « +10 % dégâts » sont deux affixes distincts, et les avoir tous les deux
  est tout l'intérêt d'avoir les deux formes.

**Ne jamais ajuster une valeur attendue pour faire passer un test.** Un chiffre
mesuré à la mise en place (69 ennemis pour la graine 4242) est un point de
comparaison ; s'il change, c'est une régression à comprendre, pas une constante
à mettre à jour. Si le changement est voulu, le dire explicitement dans le
rapport avant de toucher au chiffre.

Trois pièges de test rencontrés sur ce projet, tous les trois écrits par moi :

- **les lambdas GDScript capturent par valeur.** Un compteur local incrémenté
  depuis un signal reste à zéro. Utiliser une variable membre ;
- **parcourir une liste qui rétrécit.** Tuer un ennemi le retire de
  `EnemyManager.enemies` pendant la boucle. Itérer sur une `duplicate()` ;
- **mesurer après coup ce qui se mesure avant.** L'empreinte d'une zone prise
  une image de physique plus tard mesure le tassement des corps, pas le
  placement — deux choses différentes, dont une seule est promise.

Et un piège de conception de test : **une métrique qu'un événement du jeu peut
remettre à zéro en silence.** Compter les morts par différence de taille de
liste annonçait tranquillement zéro après un combat entier, parce que la mort du
joueur recharge la zone et la repeuple. Compter par signal.

## 4. Si l'interface a bougé : capture réelle, et la regarder

`--headless` ne sert à rien pour juger un rendu : le pilote est un bouchon et les
captures sortent vides. Lancer **sans** `--headless` et sauver le framebuffer :

```gdscript
await RenderingServer.frame_post_draw
get_viewport().get_texture().get_image().save_png("C:/.../capture.png")
```

L'image fait 640 × 360, le framebuffer pixel art exact. Recadrer et agrandir en
NEAREST avec PIL avant de la lire, sinon les détails sont illisibles. **Ouvrir
l'image et la regarder** — c'est là qu'on voit ce qu'aucune assertion n'attrape :
un panneau qui passe sous un autre, une barre de progression masquée sur son
quart gauche, un texte sous un fond translucide.

## 5. Si une boucle chaude a bougé : remesurer

Chronométrer la boucle visée avec `Time.get_ticks_usec()`, jamais en divisant du
temps réel par un nombre d'images de physique — celles-ci tournent à 60 Hz quoi
qu'il arrive, donc le résultat vaut 16,67 ms par construction. Chauffer avant de
relever : la première passe mesure l'allocation.

Mesurer le coût **par unité** (par particule, par ennemi) et non par image : le
nombre présent à l'écran dépend du rythme du jeu, pas du code. Comparer au
tableau de référence de la scène de stress (`world/stress_test.tscn`, touche F6,
en fenêtré).

## 6. Rendre un compte honnête

- Les chiffres réellement obtenus, pas ceux attendus. « 65 tests, 0 échec » se
  vérifie ; « tout fonctionne » ne veut rien dire.
- **Ce qui n'a pas été couvert.** Une fonctionnalité livrée avec un pan non
  testé, c'est à dire, pas à taire.
- Les défauts trouvés en chemin, y compris ceux qu'on a soi-même introduits puis
  corrigés — c'est l'information la plus utile du rapport.
- L'état du dépôt à la fin, et ne rien commiter sans que l'utilisateur le
  demande.
