# Tests

```bash
tests/run.sh              # tout : ~45 s, dont 33 s de tests
tests/run.sh unit         # ~15 s, dont 3 s de tests
tests/run.sh integration
tests/run.sh e2e          # lent, mais c'est lui qui attrape les surprises
```

L'écart entre les deux colonnes est la recopie du projet et son import, payés
quelle que soit la suite. C'est pourquoi l'onglet GUT de l'éditeur reste le bon
outil pour itérer sur un seul test — le lanceur, lui, part d'une copie propre et
reste la référence.

Sortie 0 = tout passe, 1 = au moins un échec, 2 = Godot introuvable (le passer
par la variable `GODOT`).

Le lanceur **recopie le projet dans un dossier temporaire** avant de l'exécuter.
Deux raisons, apprises à leurs dépens : lancer Godot sur le dossier de travail
lui réimporte son cache `.godot/` pendant que l'éditeur y est ouvert, et un test
qui écrit dans `user://` laisse des fichiers derrière lui. Il nettoie tout seul,
y compris sur interruption, et cible ses processus par ligne de commande — jamais
par nom d'image, ce qui fermerait l'éditeur ouvert.

## Où va un test

La frontière n'est pas « petit / gros » mais **« a besoin du moteur ou non »**.
Une `Area2D` hors de l'arbre n'a pas de `global_position` et son `_ready` ne
s'exécute pas : tout ce qui touche à un nœud est de l'intégration, même pour
vérifier une seule fonction.

| Dossier | Ce qu'on y met | Exemples |
|---|---|---|
| `unit/` | Ce qui vit sans moteur : formules, formats, structures | courbes d'armure et d'esquive, grille du sac, unités d'affichage, réserve d'affixes, conversions de carte |
| `integration/` | Ce qui a besoin de l'arbre ou de la physique | mitigation dans la `Hurtbox`, mana et équipement du joueur, affixage d'un ennemi, natures des tirs |
| `e2e/` | Une boucle de jeu complète | déterminisme d'une zone, 600 images de combat dense panneaux ouverts |

## Depuis l'éditeur

Le greffon GUT est activé : onglet **GUT** en bas de l'éditeur, qui permet de
relancer un seul script ou un seul test. Utile pour itérer ; le lanceur reste la
référence, parce que lui part d'une copie propre.

## Deux règles

**Ne jamais ajuster une valeur attendue pour faire passer un test.** Les chiffres
mesurés à la mise en place (69 ennemis pour la graine 4242) sont des points de
comparaison. S'ils changent, c'est une régression à comprendre.

**Un test a besoin de son jumeau négatif.** « La même graine redonne la même
zone » passe aussi sur une génération cassée qui rendrait toujours la même chose.
D'où « deux graines donnent deux zones » juste à côté.
