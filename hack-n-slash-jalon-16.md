# Hack'n'slash top-down — jalon 16

Suite des jalons 1 à 15. Ce document ne redit pas ce qui y est déjà écrit, et
`docs/ARCHITECTURE.md` reste le seul endroit qui décrit l'état courant.

**Proposé le 16 septembre 2026.** Le personnage ne gagne aujourd'hui, par niveau, que
3 points d'attributs : des PV, de l'esquive, de la mana, des cadences et un peu de
physique plat aux attaques. **Aucun multiplicateur de dégâts ne vient du niveau.** Ce
jalon remplace ces points par un **arbre de passifs à la PoE** : un graphe partagé, un
point par niveau, des chemins à tracer depuis le centre.

---

## 1. Périmètre

**Dedans :**

- **L'arbre** : un graphe d'une soixantaine de nœuds, trois régions (force,
  dextérité, intelligence), des petits nœuds, des notables et trois clés de voûte.
- **Un point par niveau**, déduit du niveau, jamais retenu.
- **Prendre un nœud** voisin d'un nœud pris ou du départ ; **le reprendre** gratuitement
  tant qu'il ne coupe pas du départ un autre nœud pris.
- **La fin des points d'attributs** : plus de boutons sur la fiche. Les attributs
  viennent de l'arbre, des objets et des passifs de manuel.
- **Le panneau de l'arbre** (P) : déplacement à la souris, infobulle, prise et reprise.
- **La sauvegarde** en version 7, et la relecture des versions d'avant.
- **Le banc** : les profils tracent leur chemin dans l'arbre à la place de leurs
  attributs.

**Dehors :**

- **Des classes et des départs multiples.** Un seul départ, au centre ; les
  silhouettes restent cosmétiques.
- **Des clés de voûte qui changent une règle** (« l'esquive protège des sorts »). Ce
  jalon n'écrit que des nombres, avec les lignes que le jeu sait déjà appliquer.
- **Des joyaux sertis, une ascendance, une monnaie de respécialisation.**
- **Le zoom** de l'arbre : à soixante nœuds, un déplacement suffit.
- **Les murs des zones 90 et 120** : voir §7.

---

## 2. Le modèle

### Les données

- **`PassiveTree`** (`resources/passive_tree.tres`, une Resource) : la liste des nœuds.
  **Partagée**, jamais écrite (invariant 2).
- **`PassiveNode`** (sous-ressource) :

  | Champ | Rôle |
  |---|---|
  | `id` | **Définitif** (invariant 1), écrit dans les sauvegardes |
  | `name` | Clé française, pour les notables et clés de voûte ; vide pour un petit nœud |
  | `kind` | `START`, `SMALL`, `NOTABLE`, `KEYSTONE` — **ajouter à la fin** |
  | `position` | En cases de la grille de l'arbre, comme `TalentNode.position` |
  | `links` | Les identifiants voisins. **Un lien s'écrit d'un seul côté** ; le graphe le rend symétrique au chargement |
  | `lines` | Des `TalentLine`, **les mêmes que les passifs de manuel** : `stat`, `scope`, `percentage`, `more` |

- **Le personnage garde la liste des nœuds pris**, un tableau d'identifiants dans
  `Player.passives` et `Character.passives`. Rien d'autre : ni compteur de points, ni
  attributs placés.

### Les règles, dans `PassiveTree` et nulle part ailleurs

- `points_gained(level) = level − 1` : **déduit**, comme `Manual.points_gained()`.
- `can_take(taken, id, level)` : un point restant, le nœud existe, n'est pas pris, n'est
  pas le départ, et **un de ses voisins est pris ou est le départ**.
- `can_release(taken, id)` : le nœud est pris, et **tous les autres nœuds pris restent
  reliés au départ sans lui** (un parcours en largeur). C'est la règle « gratuit, tant
  qu'il ne coupe rien » : une feuille se reprend toujours, un nœud du milieu seulement
  s'il existe un autre chemin.
- `mods(taken)` : les lignes de tous les nœuds pris, **dans la forme d'un objet porté**.

### Où l'arbre entre dans la fiche

`Player.recompute_stats()` verse `PassiveTree.mods()` **dans la même liste** que les
objets et les passifs de manuel. Il ne crée aucun chemin à part : les attributs passent
avant la dérivation, les lignes portées vont dans `skill_mods`, et la règle accru / plus
du jalon 14 s'applique telle quelle.

Les attributs de départ de `player_stats.tres` (10 partout) ne bougent pas.

---

## 3. Ce qui disparaît

- `Player.POINTS_PER_LEVEL`, `unspent_points`, `allocated`, `spend_point()` et le signal
  `points_changed` deviennent `Player.passives`, `take_passive()`, `release_passive()`
  et un signal `passives_changed`.
- **La fiche (C) ne prend plus jamais la souris** : elle ne fait que lire. Son titre
  garde « (+N) » pour les points d'arbre restants.
- `BenchProfiles` ne répartit plus `(niveau − 1) × 3` points dans un attribut.

**Ce que ça coûte au personnage.** Un niveau 34 portait 99 points d'attributs placés,
un niveau 133 en portait 396. Un petit nœud d'attribut donnera +10 ; un chemin de force
en croisera une dizaine. **La force et l'intelligence, donc les PV, la mana et le
physique plat des attaques, baissent nettement.** C'est voulu : l'arbre rend en
pourcentages ce qu'il retire en plats. Le banc dira si le compte y est (§7).

---

## 4. Le panneau

- **P ouvre et ferme** ; Échap le ferme, par `Zone.close_interfaces()`.
- **Plein cadre**, par-dessus la zone. Il prend la souris tant qu'il est ouvert.
- **Glisser** déplace la vue ; elle s'ouvre centrée sur le départ.
- **Clic gauche** prend un nœud, **clic droit** le reprend : les gestes des manuels.
- **Dessin** : un lien entre deux nœuds pris est clair, les autres sont sombres. Un
  petit nœud est un rond, un notable un rond plus grand, une clé de voûte un losange ;
  les couleurs d'état sont celles des manuels (`FULL`, `OPEN`, `WAIT`, `LOCK`).
- **Infobulle** : le nom s'il en a un, puis chaque ligne par `StatMod.label()`, **la
  même fonction que l'infobulle d'un objet**.
- **En-tête** : « ARBRE DE PASSIFS — N points restants ».

---

## 5. Le contenu

Soixante nœuds environ, en trois régions autour du départ :

| Région | Petits nœuds | Notables | Clé de voûte |
|---|---|---|---|
| Force, en bas à gauche | +10 force, +8 % de PV accrus, +10 % d'armure accrue, +8 % de dégâts accrus aux attaques | 4 : attaque et PV, armure et régénération… | **Colosse** : +25 % de dégâts amplifiés aux attaques, −15 % de vitesse d'attaque réduite |
| Dextérité, en bas à droite | +10 dextérité, +8 % d'esquive accrue, +4 % de vitesse d'attaque accrue, +8 % de dégâts accrus aux projectiles | 4 : critique, vitesse, esquive | **Œil du chasseur** : +25 % de dégâts amplifiés aux projectiles, −20 % de PV atténués |
| Intelligence, en haut | +10 intelligence, +8 % de mana accru, +4 % de vitesse d'incantation accrue, +8 % de dégâts accrus aux sorts | 4 : sorts de feu, sorts de foudre, mana | **Esprit d'orage** : +30 % de dégâts amplifiés aux sorts, −25 % d'armure réduite |

Et une ceinture de petits nœuds entre les régions : résistances, chance critique,
vitesse de déplacement. **Tous les nombres sont un premier réglage**, à lire sur le
banc.

**Lignes utilisables** : les champs de `StatMod.LABELS` sans portée, et avec une portée
de `Keywords`, `damage` et les nombres de `SkillStats.LABELS`. Pas de « dégâts » sans
portée : la fiche n'a pas de champ de dégâts, et `StatMod.apply_all()` écarterait la
ligne.

**Ce qui s'écrit en anglais** : les noms des notables et des clés de voûte, relevés par
`test_translations.gd` comme ceux des nœuds de talent.

---

## 6. La sauvegarde

- **Version 7** : `Character.passives`, un tableau d'identifiants ; `attributes` et
  `unspent_points` ne s'écrivent plus.
- **Versions 1 à 6** : l'arbre est vide, et tous les points sont à placer. **Les
  attributs placés sont abandonnés**, sans conversion : aucune correspondance juste
  n'existe entre 3 points libres et 1 point de graphe. Le joueur retrouve ses
  `niveau − 1` points à la première ouverture de P.
- **Un identifiant inconnu** est ignoré à la lecture, comme une base d'objet disparue.
  Un nœud relu qui n'est plus relié au départ est **retiré avec ses suivants**, pour
  qu'une sauvegarde ne contourne jamais la règle de prise.

---

## 7. Le banc et ce qu'on attend

- **Chaque build porte un chemin** : une liste ordonnée d'identifiants, prise tant qu'il
  reste des points, comme `build.order` pour le manuel.
- **Le Sort** part vers l'intelligence et va chercher l'Esprit d'orage ; **la Mêlée**
  vers la force et le Colosse.
- **Attendu** : dans la zone attendue, jusqu'à la zone 60, aucun mur pour l'Équipé ; le
  Nu y reste tendu.
- **Limite connue, écrite d'avance.** Pour revenir à « confortable », il faudrait
  multiplier les dégâts du Sort Équipé par ~4,5 en zone 60, ~27 en zone 90 et ~110 en
  zone 120 (Mêlée : ~2,3, ~5, ~53). Un arbre surtout accru donne ×6 à ×12 : **il ne
  comble pas les zones 90 et 120**. Ce sera le rôle des objets, des niveaux de
  compétence, ou d'une vie d'ennemi moins composée au-delà de 60 — un jalon à part.

---

## 8. Arbitrages

**Un tableau d'identifiants, pas un dictionnaire de points.** Un nœud d'arbre se prend
une fois ; `Manual.points` compte des rangs parce qu'une case en a plusieurs.

**Les points se déduisent du niveau.** Un compteur retenu à côté finirait par mentir ;
c'est la leçon de `Manual.points_gained()`.

**La reprise vérifie tout le graphe**, pas seulement « est-ce une feuille ». Une feuille
seule interdirait de reprendre un nœud du milieu d'une boucle, et le joueur verrait un
nœud visiblement inutile refusé.

**Les `TalentLine` des manuels**, et pas une troisième forme de ligne : ce qui s'écrit
pour un passif de manuel s'écrit pareil dans l'arbre, et `test_talents.gd` en garde déjà
le libellé.

**Un seul fichier de contenu.** Soixante sous-ressources liées se relisent mal dans
l'inspecteur ; le `.tres` est écrit une fois par un script jetable, puis retouché à la
main. Le catalogue en donne la lecture (`tools/catalog.sh`).

---

## 9. À trancher avant de commencer

Rien de bloquant : les quatre choix de fond sont faits (§11). Deux détails, avec ce que
je ferais faute d'avis :

1. **La touche** : P, libre aujourd'hui, et la touche de PoE.
2. **Les noms des trois clés de voûte** : Colosse, Œil du chasseur, Esprit d'orage.

---

## 10. Étapes

Chaque étape se livre seule et passe la suite.

1. **Le modèle** : `PassiveTree`, `PassiveNode`, les trois règles, `mods()`, et leurs
   tests unitaires sur un petit graphe écrit dans le test.
2. **Le personnage** : `Player.passives`, prise et reprise, la fin des points
   d'attributs, la fiche en lecture seule, la sauvegarde v7 et sa relecture.
3. **Le contenu** : `passive_tree.tres`, les traductions, le catalogue.
4. **Le panneau** : P, dessin, déplacement, infobulle, prise et reprise, Échap. Capture
   réelle en fenêtré.
5. **Le banc** : les chemins des builds, le rapport avant → après, la décision sur les
   couloirs au §12.
6. **La doc** : ARCHITECTURE (où vit la règle de prise, l'arbre dans la fiche,
   l'invariant 1), RECETTES (« Ajouter un nœud à l'arbre de passifs »).

---

## 11. Décidé le 16 septembre 2026

- **L'arbre remplace les points d'attributs**, comme PoE.
- **Un point par niveau.**
- **Reprise gratuite, tant qu'elle ne coupe rien.**
- **Une première version d'une soixantaine de nœuds**, pour valider le système,
  l'interface et l'équilibrage avant de l'agrandir.

---

## 12. Ce qui refusera un oubli

- `tests/unit/test_passive_tree.gd` — prise voisine seulement, jamais le départ, jamais
  deux fois, pas sans point ; reprise d'une feuille, refus d'un nœud qui coupe, accord
  d'un nœud d'une boucle ; liens symétriques ; `mods()` des seuls nœuds pris.
- **Le contenu** : identifiants uniques, un seul départ, **chaque nœud atteignable** du
  départ, chaque lien vers un nœud qui existe, chaque ligne sur une statistique réelle
  ou un nombre de lancer, chaque notable et clé de voûte nommé.
- `tests/unit/test_save.gd` — l'aller-retour des nœuds pris ; une v6 relue a un arbre
  vide et ses `niveau − 1` points ; un nœud orphelin relu est retiré avec ses suivants.
- `tests/integration/test_player.gd` — un nœud pris change la fiche, sa reprise la
  rend ; une clé de voûte « plus » multiplie après les accrus des objets.
- `tests/integration/test_escape.gd` — Échap ferme l'arbre.
- `tests/unit/test_translations.gd` — les noms des nœuds.

---

## 13. Ce qui a été fait, et comment

*À remplir à la livraison.*
