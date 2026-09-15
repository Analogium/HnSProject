# Hack'n'slash top-down — jalon 13

Suite des jalons 1 à 12. Ce document ne redit pas ce qui y est déjà écrit, et
`docs/ARCHITECTURE.md` reste le seul endroit qui décrit l'état courant.

**Proposé le 15 septembre 2026, à faire plus tard.** L'équilibrage se juge
aujourd'hui en jouant un personnage à la main. Le 15 septembre, « ad » (niveau 44)
tuait un grunt de zone 120 en un neuvième de coup. Il a fallu une mesure faite pour
l'occasion pour le voir, et elle ne portait que sur un seul personnage. Ce jalon
construit **un banc d'équilibrage** : des personnages types, des zones de
plusieurs niveaux, et un rapport qui dit à quel point chacun s'en sort.

---

## 1. Périmètre

**Dedans :**

- **Des profils générés par les règles du jeu**, pas des sauvegardes faites à la
  main (§2). Chaque profil combine un build, un niveau et un équipement.
- **Une grille profils × zones**, mesurée de deux façons (§3) :
  - **le calcul**, rapide et sans hasard, sur toutes les cases de la grille ;
  - **la simulation**, un robot qui joue une vraie zone, sur quelques cases
    seulement.
- **Un rapport lisible**, `docs/EQUILIBRAGE.md`, régénéré par
  `tools/balance.sh` comme le catalogue.
- **Des couloirs cibles** et les tests qui les gardent (§4), une fois les couloirs
  décidés.

**Dehors :**

- **L'équilibrage lui-même.** Le banc montre les écarts, et les réglages restent
  une décision prise après lecture du rapport.
- **Un robot qui esquive, se replace ou gère sa mana finement.** La simulation
  mesure un joueur médiocre, et c'est voulu : elle donne un plancher.
- **L'atelier et le râtelier comme sources de puissance.** Les profils portent des
  objets tirés, pas des objets retravaillés.
- **Les boss et les ennemis de zones futures.** Le banc prend les ennemis qui
  existent (grunt, caster, et leurs affixes).

---

## 2. Les profils

**Générés, jamais écrits à la main.** Une sauvegarde faite à la main se périme au
premier rééquilibrage : ses objets restent ceux du jour où elle a été créée. Un
profil se décrit par des règles et se reconstruit à chaque lancement, **avec les
fonctions du jeu** :

- **l'équipement**, par `LootTable.roll()` et `ItemAffixPool.roll()` à un niveau
  d'objet donné, avec une graine fixe par profil : le même profil redonne les
  mêmes objets ;
- **les attributs**, par les points du niveau (`Player.POINTS_PER_LEVEL`), placés
  selon le build ;
- **le manuel**, investi selon l'ordre du build, jusqu'aux points que son niveau
  donne.

**Deux builds pour commencer**, un par grande famille de manuel :

| build | manuel | attribut | barre |
|---|---|---|---|
| sort | foudre | intelligence | chaîne d'éclairs, nova de foudre, nuage d'orage |
| mêlée | chevalier | force | frappe lourde, coup en croix, épée spirale |

**Cinq profils par build :**

| profil | niveau | équipement |
|---|---|---|
| Débutant | 1 | aucun, le manuel offert |
| Nu | niveau attendu de la zone | aucun |
| Sous-équipé | niveau attendu | tiré 20 niveaux sous la zone |
| Équipé | niveau attendu | tiré au niveau de la zone |
| Sur-équipé | niveau attendu | tiré 30 niveaux au-dessus (le cas de « ad ») |

**Le niveau attendu d'une zone** se déduit lui aussi des règles : c'est le niveau
atteint en vidant une fois chaque zone de 1 à Z−1, avec l'expérience que rapporte
leur population moyenne (`Enemy.xp_value()`, `Enemy.experience_factor()`,
`Progression.level_cost()`). Il suit donc tout seul un changement de la courbe
de vie, et donc de l'expérience.

---

## 3. Les mesures

### Le calcul

Pour chaque case profil × zone, **sans simulation physique**, en passant par les
vraies fonctions : `Player.resolve()` pour ce qui part, `scale_to_level()`
pour les ennemis, `CharacterStats.mitigate()` et l'esquive pour ce qui arrive.

- **Coups pour tuer** un grunt, un caster, et un grunt Colossal, avec le meilleur
  sort de la barre ; critique compté en moyenne.
- **Secondes pour tuer**, cadence et projectiles compris.
- **Secondes de survie** au contact de trois grunts et d'un caster : leurs dégâts
  par seconde, après armure, résistances et esquive, contre les PV et la
  régénération du profil.
- **Un verdict** par case (§4).

Quelques secondes pour toute la grille : c'est la mesure qu'on relance après
chaque réglage.

### La simulation

Un robot dans une vraie zone, **à la graine fixe**, sur une sélection de cases :
chaque profil dans sa zone attendue, plus deux cases à ±20 niveaux. Il avance vers
l'ennemi le plus proche et lance sa barre dès que la recharge le permet.

- **Ennemis tués par minute** de jeu.
- **Morts**, et le temps passé sous 30 % de vie.
- **Le temps de vider la zone**, borné à un plafond.

Elle attrape ce que le calcul ne voit pas : les paquets, les casters à distance,
les états, le gel d'impact. Plus lente, elle ne tourne pas à chaque réglage.

---

## 4. Les couloirs

Un verdict par case, sur la mesure du calcul :

| verdict | coups pour tuer un grunt | survie au contact |
|---|---|---|
| trivial | moins de 0,5 | — |
| confortable | 0,5 à 3 | plus de 10 s |
| tendu | 3 à 8 | 4 à 10 s |
| mur | plus de 8 | moins de 4 s |

**Chiffres à trancher avant de commencer**, comme les attentes par profil
ci-dessous. Une fois décidés, ils deviennent les tests :

- Débutant en zone 1 : confortable.
- Équipé dans sa zone attendue : confortable ou tendu, **jamais trivial ni mur**.
- Nu dans sa zone attendue : tendu, car les niveaux seuls ne suffisent pas.
- Sur-équipé dans sa zone attendue : trivial toléré, mur interdit.
- Tout profil en zone attendue +20 : jamais trivial.

**Ces tests ne se corrigent pas en changeant leurs chiffres.** Un couloir qui casse
après un réglage est l'alerte que le banc existe pour donner. Soit le réglage est
à revoir, soit le couloir change par décision, écrite ici avec sa date.

**Une suite à part** : `tests/run.sh balance`, hors de la suite par défaut. Un
réglage en cours ne doit pas bloquer une livraison qui n'a rien à voir.

---

## 5. Arbitrages

**Les vraies fonctions du jeu, jamais une copie des formules.** Un banc qui
recalcule les dégâts à sa façon mesure sa propre copie, et il resterait vert le
jour où le jeu change. Le calcul instancie un vrai `Player` et de vraies fiches.

**Le calcul d'abord, la simulation ensuite.** La simulation coûte cher et varie
d'une graine à l'autre. Le calcul répond à la plupart des questions et se relance
à chaque réglage.

**Des graines propres au banc** (invariant 3). Les objets se tirent sur un
`RandomNumberGenerator` par profil, pas sur `Game.rng`, sinon un rapport change
quand un autre système consomme un tirage de plus.

**Hors du vrai `user://`.** Le banc tourne sur une copie du projet sous un
`config/name` distinct, comme `tools/catalog.sh`.

---

## 6. Étapes

Chaque étape se livre seule et passe la suite.

1. **Les profils.** Le générateur, et un test : un profil est reproductible, ses
   objets sont portables à son niveau et ses points sont tous placés.
2. **Le calcul et le rapport.** `tools/balance.sh` écrit
   `docs/EQUILIBRAGE.md` : une grille par build, les cases colorées par verdict.
3. **La simulation.** Le robot, la sélection de cases, et sa section dans le
   rapport. Mesurer d'abord ce qu'elle coûte.
4. **Les couloirs.** La suite `balance`, une fois les chiffres du §4 décidés.

---

## 7. Décidé le 15 septembre 2026

- **Les couloirs et les attentes du §4** sont pris tels qu'écrits. Le verdict d'une
  case est le pire des deux axes ; au-delà de 10 s, la survie ne contraint plus rien.
  L'attente du Nu ne vaut **pas en zone 1**, où le Nu et le Débutant sont le même
  personnage.
- **Les zones de la grille** : 1, 10, 20, 40, 60, 90, 120.
- **Le niveau attendu** : vider une fois chaque zone de 1 à Z−1. Le retard
  (`experience_factor`) est pris à l'entrée de chaque zone, pas ennemi par ennemi.
- **Pas de troisième build** dans ce jalon.
- **Pas de photo de « ad »** : le banc ne mesure que des profils générés.
- **La simulation** joue chaque profil en zone 40 (le Débutant en zone 1), plus
  l'Équipé de la zone 40 joué en zones 20 et 60. Plafond : 180 s de jeu.

## 8. Ce qui a été fait, et comment

- **`LootTable.roll()` n'est pas appelé** : il tire sur `Game.rng` et décide d'abord
  s'il y a chute. Les profils refont son geste — base au hasard parmi
  `ItemCatalog.available()`, puis `ItemAffixPool.roll()` — sur leur propre tirage.
  Une base marquée pour l'autre build est écartée (pas d'épée pour le sort).
- **Le manuel gagne l'expérience du personnage**, comme `Player.reward()` la
  lui verse. Ses points vont dans l'ordre du build, chaque entrée remplie avant la
  suivante ; la barre reprend ses compétences dans cet ordre.
- **Trois accès ouverts dans le jeu pour ne rien recopier** : `Enemy.sheet_of()` et
  `Enemy.experience_of()`, statiques, et `Hurtbox.mitigate_part()`, rendue publique.
- **Les secondes pour tuer passent par `average_per_second()`**, si tout touche :
  les huit traits d'une nova comptent sur la même cible, et la mana ne limite rien.
- **La simulation tourne en `--fixed-fps 60`**, une image de physique par image et
  aussi vite que la machine le permet. Son temps est du temps de jeu : un gel
  d'impact n'en compte que sa part ralentie. `Game.hit_stop()` espace pourtant ses
  gels en millisecondes réelles, donc accélérée, la simulation en voit plus que le
  joueur — ils coûtent du temps de calcul, pas du temps de jeu.

### Premier réglage, décidé le 15 septembre 2026 après lecture du rapport

Le premier rapport montrait un sort qui tue tout en moins d'un coup jusqu'en zone 60,
et une mêlée qui survit mais ne tue plus : 16 coups par grunt en zone 90, 86 en
zone 120 pour l'Équipé. Deux réglages :

- **Aucune compétence ne monte plus avec un attribut.** `Skill.attribute` et
  `pourcentage_par_attribut` sont retirés, avec la ligne de la fiche du manuel. La
  force et l'intelligence gardent leurs réserves, leurs cadences, et la force ses
  dégâts physiques ajoutés aux attaques. Essayé d'abord dans l'autre sens — 3 % par
  point de force pour le chevalier — : la mêlée équipée devenait triviale en zones
  20 et 40, un niveau 34 portant une centaine de points de force.
- **Les ennemis gagnent de l'armure et des résistances avec la zone** :
  `CharacterStats.ARMOR_PER_LEVEL` (5) et `RESISTANCE_PER_LEVEL` (0,33), soit
  195 d'armure et 13 % en zone 40, 595 et 39 % en zone 120. L'esquive ne monte pas.

Coups pour tuer un grunt, profil Équipé, avant → après les deux :

| build | zone 40 | zone 60 | zone 90 | zone 120 |
|---|---|---|---|---|
| Sort | 0,46 → 2,27 | 1,75 → 13,0 | 5,02 → 79,9 | 13,9 → 327 |
| Mêlée | 1,77 → 2,28 | 4,89 → 6,88 | 16,5 → 24,3 | 85,8 → 136 |

La survie ne bouge pas : rien de ce que subit le joueur n'a changé. Les deux builds
heurtent maintenant un mur de dégâts dès la zone 60 : sans le multiplicateur
d'attribut, plus rien ne suit la vie composée des ennemis que les objets.

### Ce que ça coûte

Mesuré le 15 septembre 2026 : **le calcul, 137 ms** pour les 70 cases. **La
simulation, 2 min 20 s** pour ses 14 cases, de 7 à 12 s chacune, import compris
dans le total.

### Limites connues

- **La simulation n'est pas reproductible**, malgré sa graine. Deux lancements
  consécutifs du 15 septembre : les cases du sort bougent d'environ 10 %, et le
  Sur-équipé de mêlée passe de 8 à 21 tués par minute. `Game.hit_stop()` espace ses
  gels en millisecondes réelles et la fenêtre d'un coup d'épée tient à une minuterie :
  accélérée, la partie dépend de la vitesse de la machine, puis `Game.rng` diverge. Le
  remède est une horloge de jeu dans `Game.hit_stop()` — une retouche du jeu, à
  décider. D'ici là, ne comparer deux rapports que sur le calcul.
- **« Tués par minute » récompense le robot qui meurt.** Une mort repeuple la zone
  autour de l'apparition, où les ennemis sont à deux pas ; celui qui survit doit
  traverser la carte. Le Sur-équipé de mêlée, zéro mort, tue 8 à 21 ennemis par
  minute, et le Débutant, seize morts, 54. Lire les tués avec les morts, jamais seuls.
- **Aucune zone n'est vidée en 180 s**, par aucun profil : le robot marche vers
  l'ennemi le plus proche et perd son temps entre les paquets. La colonne ne dira
  quelque chose qu'avec un plafond plus long ou un robot moins bête.

- **Un tirage par emplacement fait du bruit.** En zone 40, le Sur-équipé du sort
  tue un grunt en 0,91 coup et l'Équipé en 0,46 : la chance d'un tirage pèse plus
  que trente niveaux d'objet. Moyenner plusieurs graines par profil est le remède ;
  à faire si un couloir se met à clignoter d'un réglage à l'autre.
- **Aucun nœud de talent n'est investi** en dehors du dernier point de chaque
  build. Un joueur réel en place.
