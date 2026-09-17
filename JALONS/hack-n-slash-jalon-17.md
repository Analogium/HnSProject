# Hack'n'slash top-down — jalon 17

Suite des jalons 1 à 16. Ce document ne redit pas ce qui y est déjà écrit, et
`docs/ARCHITECTURE.md` reste le seul endroit qui décrit l'état courant.

**Proposé le 17 septembre 2026.** Le jalon 16 a posé l'arbre de passifs : le modèle,
les règles de prise, le panneau, la sauvegarde — et **58 nœuds pour valider le
tout**. Ces 58 nœuds mélangent les deux rôles que PoE sépare : un chemin y donne des
dégâts, et un notable y pousse au milieu d'une file. Ce jalon garde le modèle sans y
toucher et **réécrit le contenu** : des **chemins d'attributs** qui ne donnent que des
attributs, et des **clusters thématiques** branchés dessus, chacun fait de petits nœuds
et d'un ou deux notables.

---

## 1. Périmètre

**Dedans :**

- **Un squelette d'attributs** : trois axes depuis le départ et deux anneaux qui les
  croisent. Ces nœuds-là ne portent **que** de la force, de la dextérité ou de
  l'intelligence. Traverser l'arbre coûte des points et rend des attributs, jamais des
  dégâts.
- **Une quinzaine de clusters** branchés sur le squelette, un thème chacun (dégâts de
  sorts, brûlure, foudre, régénération, projectiles, critique…), faits de 4 à 7 petits
  nœuds et d'**un ou deux notables**.
- **Environ 180 nœuds**, contre 58 : à ~132 points au niveau attendu de la zone 120,
  un personnage en laisse un bon tiers. Le choix redevient un choix.
- **Le zoom du panneau** : trois crans à la molette, que le jalon 16 avait écartés à
  soixante nœuds.
- **Les chemins du banc** réécrits, et le rapport avant → après.

**Dehors :**

- **Des départs multiples et des classes.** Un seul départ au centre, ses trois
  sorties : c'est la base qu'on garde. `start()`, `connected()` et `legal()` ne bougent
  pas.
- **Des clés de voûte en plus.** Les trois du jalon 16 restent, au bout des trois axes.
  Un notable de cluster n'est pas une clé de voûte.
- **Des joyaux, une ascendance, une monnaie de respécialisation**, toujours.
- **Des clés de voûte qui changent une règle.** Ce jalon n'écrit toujours que des
  nombres, avec les lignes que le jeu sait déjà appliquer.
- **Un champ « cluster » dans les données.** Un cluster est une **forme** du graphe, pas
  une donnée : une branche en cul-de-sac accrochée au squelette. Rien à ajouter à
  `PassiveNode`.

---

## 2. La forme

### Le squelette

```
                        [clé de voûte INT]
                               |
                         anneau extérieur
                     /         |          \
                cluster    axe INT      cluster
                     \         |          /
                          anneau intérieur
                     /                     \
        axe FORCE ---------- DÉPART ---------- axe DEXTÉRITÉ
```

- **Trois axes**, depuis le départ : intelligence vers le haut, force en bas à gauche,
  dextérité en bas à droite — les directions du jalon 16, que le joueur connaît déjà.
- **Deux anneaux** qui coupent les trois axes : l'**intérieur** au tiers du chemin,
  l'**extérieur** aux deux tiers. La ceinture unique du jalon 16 devient l'anneau
  intérieur. Un anneau porte les attributs des deux axes qu'il relie (+5/+5) : il se
  traverse pour changer de région sans revenir au centre.
- **Une dizaine de nœuds d'attribut par axe**, +10 chacun ; sur les anneaux, +5/+5.
  **Rien d'autre.** Un nœud de chemin ne porte jamais un pourcentage.

Ça fait une soixantaine de nœuds de squelette, et **neuf jonctions** (3 axes × 2
anneaux, plus le départ et les trois bouts d'axe) où un cluster peut se brancher.

### Un cluster

Une branche en cul-de-sac accrochée à **une** jonction ou à **un** nœud de chemin :

```
  … — [chemin] — [petit] — [petit] — (NOTABLE)
                     \
                      [petit] — (notable)
```

- **4 à 7 petits nœuds** qui répètent le thème en petites parts, et **un ou deux
  notables** au bout, qui le disent plus fort et ajoutent une seconde ligne.
- Un cluster branché sur **une seule** jonction : il se prend pour lui-même, jamais en
  passant. Un cluster de bout d'axe peut en toucher deux, ce qui en fait un raccourci —
  s'en servir avec parcimonie, c'est ce qui rend un chemin gratuit.
- Les notables du jalon 16 **gardent leur identifiant** et deviennent le bout de leur
  cluster.

---

## 3. Le contenu

Les thèmes tiennent à ce que le jeu sait déjà appliquer : les champs de
`StatMod.LABELS` sans portée, et avec une portée de `Keywords` les nombres de
`SkillStats`, les dégâts ajoutés `damage_<nature>` et **les dégâts contre un état**
`damage_vs_<état>` (`StatusEffects.IDS` : brûlé, engourdi, gelé, putréfié, béni,
saignant). C'est cette dernière famille qui donne les thèmes « dégâts de brûlure » et
« dégâts de saignement » sans écrire une règle.

| Région | Cluster | Petits nœuds | Notables |
|---|---|---|---|
| INT | Sorts | +8 % dégâts accrus aux sorts | **Incantation acérée** : +20 % dégâts, +10 int |
| INT | Brasier | +10 % dégâts de feu, +12 % contre les brûlés | **Brasier intérieur**, **Cendres vives** |
| INT | Orage | +10 % dégâts de foudre, +12 % contre les engourdis | **Foudre vive**, **Fracas d'orage** |
| INT | Réserve | +8 % mana, +0,4 mana/s | **Puits de mana** |
| INT | Savoir | +4 % vitesse d'incantation | **Savoir des arcanes** (+1 niveau aux sorts) |
| INT | Onde | +6 % rayon, +8 % durée aux sorts | **Onde large** |
| FOR | Frappe | +8 % dégâts accrus aux attaques | **Force brute** |
| FOR | Chair | +8 % PV | **Sang robuste** |
| FOR | Repousse | +0,5 PV/s, +4 % PV | **Chair qui repousse** |
| FOR | Plaques | +10 % armure, +8 rés. feu / froid | **Peau de fer** |
| FOR | Armes | +4 % vitesse d'attaque, +allonge | **Maître d'armes** |
| FOR | Plaie | +12 % contre les saignants | **Plaie ouverte** |
| DEX | Volée | +8 % dégâts aux projectiles, +6 % vitesse de projectile | **Tir précis**, **Volée** (+1 projectile) |
| DEX | Souffle | +8 % esquive | **Réflexes** |
| DEX | Œil | +6 % chance critique, +8 % dégâts critiques | **Œil de lynx** |
| DEX | Course | +3 % vitesse | **Vivacité** |
| DEX | Gel | +12 % contre les gelés | **Morsure du gel** |

**Tous les nombres sont un premier réglage**, à lire sur le banc (§6). Les trois clés de
voûte — Colosse, Œil du chasseur, Esprit d'orage — gardent leurs lignes et leur place au
bout de leur axe.

**L'icône se lit sur la première ligne** (`PassiveIcon.look_of()`) : l'ordre des lignes
d'un notable n'est donc pas libre — le notable de brûlure met ses dégâts de feu en
premier pour porter la flamme. Deux statistiques n'ont aujourd'hui aucune icône,
`attack_cooldown` et `attack_range` : elles ne peuvent pas ouvrir un nœud sans une
entrée de plus dans `PassiveIcon.SHEET`. `test_each_node_has_its_icon` le refuse.

**Les noms des notables partent dans `i18n/en.po`**, et **un texte n'y a qu'une
entrée** : vérifier qu'un nom neuf n'est pas déjà celui d'un nœud de talent, comme
« Haute tension » l'était au jalon 16.

---

## 4. Le panneau

**Trois crans de zoom à la molette**, sur un `_zoom` qui multiplie `UNIT` et les rayons
dans `screen_position()` et `_radius()` :

| Cran | Pixels par case | Ce qu'on voit |
|---|---|---|
| Large | 5 | Tout l'arbre d'un coup, sans icônes — trop petites, elles tourneraient au gris |
| Normal (défaut) | 10 | Le cadrage du jalon 16 |
| Près | 15 | De quoi viser un nœud d'un cluster dense |

- **Le zoom garde le centre du cadre** : `_pan` se multiplie par le rapport. Zoomer sur
  le curseur se sent mieux mais demande de retenir un point d'ancrage ; le
  déplacement est déjà là pour recadrer.
- `node_at()` compare une distance en pixels : **sa tolérance suit le zoom**, sinon on
  rate les nœuds au cran large.
- **Rien d'autre ne change** : la prise au relâchement, le seuil de glissement,
  l'infobulle, les couleurs d'état.

---

## 5. Ce que ça change dans le code

**Presque rien, et c'est voulu** : les règles du jalon 16 n'ont pas de taille écrite
dedans.

- `ui/passive_tree_panel.gd` : le `_zoom`, la molette, la tolérance de `node_at()`,
  l'icône masquée au cran large. Une quinzaine de lignes.
- `tools/balance/profiles.gd` : les deux chemins de build, réécrits sur les nouveaux
  identifiants.
- `resources/passive_tree.tres` : réécrit. ~180 nœuds, ~2 500 lignes, par un script
  jetable comme au jalon 16 — un gabarit d'axe, un gabarit d'anneau, un gabarit de
  cluster —, puis retouché à la main.
- `core/` : **rien**. Si une règle doit bouger pour que le contenu passe, c'est le
  contenu qui est mal posé.

---

## 6. Les identifiants et les sauvegardes

**Pas de version de sauvegarde** : le format ne change pas, c'est le contenu qu'il
désigne qui change.

- Les **notables et clés de voûte gardent leur identifiant** : `inner_blaze`,
  `iron_skin`, `colossus`… Ce sont eux qu'un joueur reconnaît.
- Les **nœuds de chemin sont réécrits** : `int_2` donnait +8 % de mana, il donnera +10
  d'intelligence. Un personnage sauvegardé qui l'avait pris garde le nœud et change de
  bonus, **sans rien casser**. Les identifiants disparus sont retirés à la relecture par
  `PassiveTree.legal()`, avec leurs suivants, et les points reviennent.
- **Le jeu n'est pas sorti** : c'est la seule fenêtre où réécrire un contenu définitif
  ne coûte rien. Après, il faudra ajouter à côté (invariant 1).

---

## 7. Le banc et ce qu'on attend

- **Les deux chemins de `BenchProfiles.builds()` sont réécrits** : le Sort part vers
  l'intelligence, prend Sorts, Brasier et Savoir, puis l'Esprit d'orage ; la Mêlée vers
  la force, Frappe, Chair et Plaques, puis le Colosse.
- `test_each_path_is_taken_in_full` refuse un chemin dont un nœud ne se prendrait pas :
  c'est lui qui attrapera un lien oublié entre un cluster et son squelette.
- **Attendu** : au moins les résultats du jalon 16 — aucun mur pour l'Équipé jusqu'à la
  zone 60 —, et des chiffres **un peu meilleurs**, parce qu'un build concentre
  désormais ses points sur son thème au lieu de traverser des nœuds tièdes.
- **Non attendu** : les murs des zones 90 et 120. Un arbre reste surtout accru ; le
  jalon 16 §7 a chiffré ce qu'il manque (×27 et ×110), et ça ne se comble pas avec des
  pourcentages. Ce jalon ne prétend pas y toucher.
- **Aucun chiffre de couloir ne se change pour faire passer un couloir** (jalon 13, §4).

---

## 8. Arbitrages

**Un chemin ne donne que des attributs.** C'est le seul vrai changement de fond. Il
rend la traversée lisible — « ce détour coûte huit points et rend 80 de force » — et il
rend un cluster désirable pour lui-même. Le revers, connu : les attributs plats
remontent, donc les PV et la mana, ce que le banc dira.

**Un cluster est une forme, pas une donnée.** Écrire `cluster = "brasier"` sur un nœud
donnerait un champ que rien ne lit, et un deuxième endroit où la vérité du graphe
s'écrit. Ce qui fait un cluster, c'est qu'il est branché en cul-de-sac ; le `.tres` et
le catalogue le montrent.

**Les notables restent des notables.** La tentation, à 180 nœuds, est d'ajouter des
clés de voûte à chaque cluster. Une clé de voûte porte un « plus », qui multiplie après
tout le reste : trois suffisent à déséquilibrer, et le jalon 16 les a déjà chiffrées.

**Le zoom garde le centre.** Voir §4.

**Le modèle ne bouge pas.** Le jalon 16 a fait le travail ; si 180 nœuds cassaient une
règle écrite pour 58, ce serait la règle qui serait fausse — et ce n'est pas le cas.

---

## 9. À trancher avant de commencer

Les trois choix de fond sont faits (§11). Reste un détail, avec ce que je ferais faute
d'avis :

1. **Les noms des notables neufs** : Incantation acérée, Cendres vives, Fracas d'orage,
   Onde large, Chair qui repousse, Plaie ouverte, Volée, Morsure du gel.

---

## 10. Étapes

Chaque étape se livre seule et passe la suite.

1. **Le squelette** : les trois axes et les deux anneaux, en attributs seulement, dans
   `passive_tree.tres`. La suite passe, l'arbre est jouable et pauvre.
2. **Les clusters**, région par région : intelligence, force, dextérité. Les notables du
   jalon 16 rejoignent le leur.
3. **Les traductions** (`i18n/en.po`) et le catalogue (`tools/catalog.sh`).
4. **Le zoom** du panneau, et sa capture réelle en fenêtré, aux trois crans.
5. **Le banc** : les deux chemins, `tools/balance.sh calculation`, `tests/run.sh
   balance`, le rapport avant → après.
6. **La doc** : ARCHITECTURE (la forme de l'arbre, le zoom du panneau), RECETTES
   (« Ajouter un nœud à l'arbre de passifs » gagne la règle chemin / cluster).

---

## 11. Décidé le 17 septembre 2026

- **Un départ, trois axes.** Pas de classes, pas de départs multiples.
- **~180 nœuds**, soit environ 1,4 fois les points d'un personnage de fin de partie.
- **Le zoom**, trois crans à la molette.

---

## 12. Ce qui refusera un oubli

Les gardes du contenu existent déjà et tiennent à 180 nœuds
(`tests/unit/test_passive_tree.gd`) : identifiants uniques, un seul départ, chaque nœud
atteignable du départ, chaque lien vers un nœud réel, deux nœuds jamais sur la même
case, chaque ligne sur une statistique réelle ou un nombre de lancer, chaque notable et
clé de voûte nommé, chaque nœud avec son icône. Plus :

- **`test_the_tree_offers_more_nodes_than_points`** — l'arbre compte plus de nœuds
  qu'un personnage de zone 120 n'a de points. C'est la seule assertion qui dit
  « il faut choisir », et elle échouerait si un jalon suivant rognait l'arbre.
- `tests/integration/test_passive_tree_panel.gd` — un clic trouve son nœud **à chaque
  cran de zoom** : `screen_position()` et `node_at()` doivent rester d'accord.
- `tests/unit/test_translations.gd` — les noms des notables neufs.
- `tools/balance/profiles.gd` — `test_each_path_is_taken_in_full`.

---

## 13. Livré le 17 septembre 2026

### L'arbre

**180 nœuds** : 61 de squelette (3 axes de 10 nœuds, 3 clés de voûte, le départ, un
anneau intérieur de 9 nœuds au 3ᵉ nœud d'axe, un extérieur de 18 au 7ᵉ) et 17
clusters de 7 nœuds. Deux gabarits :

- **la roue** — six petits nœuds en anneau autour du notable, relié au nœud du fond :
  le notable coûte cinq points depuis la jonction, les deux derniers petits sont en
  option ;
- **la fourche** — un nœud commun, deux branches de deux petits nœuds et leur notable.
  Brasier, Orage et Volée, les trois clusters à deux notables.

Placement : deux clusters sur les flancs du 5ᵉ nœud d'axe, deux en dehors de l'anneau
extérieur à 34° de l'axe, et les derniers en dehors de l'anneau aux frontières des
régions ou sur le flanc du 9ᵉ nœud d'axe. Le script jetable vérifie qu'aucun nœud n'en
touche un autre et qu'aucun lien ne passe sur un nœud.

**Écarts avec le §3 :**

- Le notable **Volée** s'appelle `volley_shot` : `volley_1`… sont ses petits nœuds.
- **Œil** : les petits nœuds donnent de la chance critique et des dégâts critiques
  **accrus** (+6 %, +8 %), et non des points plats — six fois +6 points de chance, ce
  serait +36 %. Œil de lynx garde ses points plats.
- **Armes** : l'allonge est en seconde ligne (+2 % vitesse d'attaque, +5 % allonge),
  un nœud sur deux ; elle n'a pas d'icône.
- **Savoir des arcanes** devient +1 niveau aux sorts et +10 intelligence.

Les nœuds de chemin du jalon 16 ont changé de place : une sauvegarde relue perd ce qui
n'est plus relié (`character_v7.json` garde `int_1` et `int_2`).

### Le panneau

Trois crans (`ZOOMS` : 0,5, 1 et 1,5 de `UNIT`), la molette, le centre du cadre gardé,
pas d'icônes au cran large, retour au cran normal à l'ouverture. Vérifié en capture
réelle, fenêtré, aux trois crans, en français et en anglais : au cran large tout l'arbre
tient dans le cadre. Aux autres, comme au jalon 16, les nœuds passent sur le titre du
panneau.

### Le banc

**Écart avec le §7 :** le Sort prend **Orage** et non Brasier. Son manuel est celui de
la foudre ; du feu accru ne toucherait aucun de ses sorts. Chemins : 68 et 56 nœuds.

| couloirs en échec | avant | après |
|---|---|---|
| Débutant en zone 1 | 2 | 2 |
| Nu tendu dans sa zone | 9 | 8 |
| Équipé sans mur | 4 | 3 |
| Sur-équipé sans mur | 4 | 4 |
| **total** | **19** | **17** |

- **Attendu tenu** : aucun mur pour l'Équipé jusqu'à la zone 60, et de meilleurs coups
  en zones 40 et 60 (Sort 1,66 → 1,39 et 6,44 → 3,94 ; Mêlée 3,95 → 2,52).
- **La Mêlée Équipée passe la zone 90** (🟥 10,1 → 🟨 7,17), et la Mêlée Nue la zone
  60 (7,07 → 3,99).
- **Zones 90 et 120 : toujours en mur**, comme annoncé, mais les coups y baissent d'un
  tiers à la moitié (Sort Équipé 120 : 163 → 103 ; Mêlée : 173 → 95).
- **Plus lent au début** : en zones 10 et 20 le Sort tue un peu moins vite (0,52 → 0,63 ;
  0,79 → 0,97), parce que ses premiers points vont dans des attributs. Et **sa survie
  baisse en zone 40** (Équipé 7,8 → 4,8 s ; le Sous-équipé passe de 🟨 à 🟥) : l'ancienne
  ceinture donnait des résistances, l'arbre n'en donne plus qu'aux Plaques.

**Aucun chiffre de couloir n'a changé** (jalon 13, §4).
