# Hack'n'slash top-down — jalon 38

Suite des jalons 1 à 37. Ce document ne redit pas ce qui y est déjà écrit, et
`docs/ARCHITECTURE.md` reste le seul endroit qui décrit l'état courant.

**Ouvert le 3 octobre 2026.** Les arbres du **Maître de la nécromancie**.

---

## 1. Ce que l'utilisateur a demandé

Dans la continuité du jalon 36 : le manuel suivant, la nécromancie. Avec une règle de
plus, demandée le 3 octobre : **pas de nœud qui revienne d'un arbre à l'autre**. Aux
jalons 35 et 36, Étincelles et Surtension, puis Engelure, Froid mordant et Bris
figuraient dans chaque arbre : on payait le même nœud quatre fois. Ici, **chaque arbre
a sa propre identité, et ses nœuds n'existent que chez lui**.

**La règle, telle qu'appliquée** :

- aucun nom, et aucune ligne, ne figure dans deux arbres du manuel ;
- trois exceptions seulement, les leviers de base : **un** nœud de dégâts, **un** de
  rayon et **un** de durée par arbre au plus, chacun sous son propre nom — un échange
  (⇄) ou le prix d'un nœud qui change le jeu n'en compte pas pour un ;
- pas de nœud transversal (chance d'état, éclatement des tués, sol) répété : chacun
  de ces mécanismes va à **un seul** arbre, celui qu'il caractérise le mieux.

Un test la garde : `test_unique_trees_share_no_line_and_no_name`.

## 2. L'état de départ

Deux ou trois nœuds chiffrés sur cinq des six compétences, convertis tels quels au
jalon 34. **La Nécrose avancée n'a pas d'arbre.** Comme au froid avant le jalon 36,
aucun nœud ne change la façon dont un sort se joue.

| compétence | forme | ce qu'elle fait | nœuds actuels |
|---|---|---|---|
| Peste | `BOLT` | trait lent (150 px/s), pose la décomposition | Virulence, Condamnation, Contagion (+1 projectile) |
| Relève | `SUMMON` | deux morts-vivants gardent les abords | Moelle, Guet, Légion d'os |
| Déferlante toxique | `NOVA` | souffle autour de soi, flétrit une fois sur deux | Miasme, Caustique, Dessiccation |
| Porte pourrissante | `GATE` | un portail crache des créatures qui explosent | Couvée, Boursouflure, Essaim |
| Malédiction putride | `CURSE` | sceau qui maudit une zone (−20 rés. nécrotique) | Anathème, Malédiction prompte |
| Nécrose avancée | `BUFF` | ronge 1 % des PV actuels par seconde, +10 chance de pourriture par point | — |

**L'identité de la nécrose** : ce qui **ronge dans la durée** (décomposition,
flétrissement, pourriture), ce qui **se propage**, ce qui **sert** (morts-vivants,
créatures) et ce qui **se paie de sa chair**. Pas de contrôle (c'est le froid), pas de
critique (la foudre).

## 3. Ce qui se réutilise tel quel

| nombre | sur | pourquoi ça marche déjà |
|---|---|---|
| `pierce`, `projectiles` | Peste | `Projectile`, comme tout trait |
| `kill_burst` | Peste | `Player._on_slew()` : la nécrose tire la pourriture (`rolled_by()`) |
| `ground_duration` | Déferlante | la nova pose déjà son sol à sa taille (jalon 36), et `DashTrail` a déjà une matière nécrotique |
| `period`, `simultaneous`, `radius` | Relève | lus par `Minion` |
| `crawl_speed`, `seek_radius`, `hatchlings`, `brood` | Porte | les nombres du Serpent (jalon 34) ; il suffit que `RottingGate` les lise |
| `self_wither`, lignes de buff | Nécrose | lus sur le lancer résolu (jalon 35, Sobriété) ; `Skill.is_buff_line()` |
| `ORB` | Peste | `StaticOrb` prend déjà sa teinte de la nature du lancer |

## 4. Ce qui est neuf

**a. La force des états, étendue.** `State.strength`, faite pour le transi au jalon 36,
sert à trois autres états — la suite notée en mémoire. Le lancer la passe à
`StatusEffects.inflict()` par `SkillStats.strength_of()` :

| nombre | état | ce que la force change |
|---|---|---|
| `decay_effect` | décomposition | **ronge plus vite** : ce qui brûle se renforce en brûlant davantage (`per_second`), et garde la force 1 |
| `wilting_weakness` | flétrissement | **neuf** : le flétri n'inflige plus que `2 − force` de ses dégâts ; le flétrissement seul n'affaiblit pas |
| `curse_effect` | malédiction | retire `CURSE` × force de résistance |

Un seul mécanisme, comparé dans `put()` comme le transi ; trois effets, dans trois arbres.

**b. Des nombres de `SkillStats`** :

| nombre | ce qu'il fait | lu par |
|---|---|---|
| `contagion` | à l'impact, l'état posé gagne les voisins de la cible dans ce rayon, sans coup | `Projectile.contaminate()`, différé ; `StatusEffects.pass_on()` |
| `minion_life` | PV accrus des morts-vivants | `Minion.raise()` |
| `bone_wall` | points de dégâts subis retirés par mort-vivant debout | `Player.recompute_stats()`, relancé à chaque levée et chute |
| `colossus` | un seul mort-vivant, géant, qui frappe un cercle **de ce rayon** | `Minion` |
| `tribute` | mana rendu par ennemi maudit | `PutridCurse`, par `Player.gain_mana()` |
| `shared_burden` | ce que la Nécrose a rongé frappe autour de vous, dans ce rayon | `Buff`, par une `Explosion` |
| `self_wither`, `inflict_chance` | existaient ; deviennent visables par un nœud | `Buff` (sur le lancer résolu), `Hurtbox` |

La malédiction porte sa **durée sur le lancer** (`putrid_curse.tres`, 5 s, celle de
`DURATIONS`, un test les tient égales) : Longue malédiction la vise comme une durée.

**c. Des nombres déjà connus, lus par plus de formes** : `end_burst` par `Minion` (il
éclate en tombant) ; `crawl_speed`, `seek_radius` (vue en plus de `SIGHT`) et
`hatchlings` par `RottingGate`. Leurs libellés, écrits pour le serpent, deviennent
« vitesse de reptation » et « nombre de petits ».

**d. Trois transformations, deux nœuds qui changent le jeu** :

- **Nuée** (Peste → `ORB`) : le trait devient un essaim lent qui file droit, traverse
  et mord son cercle à chaque période. Le comportement existe ; **le dessin est neuf**.
- **Haleine** (Déferlante → `BREATH`, `ToxicBreath`) : un cône de 70° devant soi, deux
  fois et demie plus long que le rayon, qui frappe chacun une fois. **Dessin neuf**.
- **Nid porté** (Porte → `NEST`) : le portail s'ouvre à votre épaule et vous suit ; les
  créatures partent de vous. Même dessin.
- **Marque de mort** (Malédiction → `MARK`) : la malédiction devient transformable — elle
  ne tient rien chez le lanceur. Un seul ennemi, le plus proche du point visé, à
  `MARK_FACTOR` (2) fois la force ; elle passe au plus proche (80 px) quand il perd la
  malédiction, jusqu'au bout de la durée. L'œil ouvert au-dessus du marqué.
- **Colosse d'os** (Relève) : `SUMMON` n'est pas transformable ; c'est le nombre
  `colossus`. PV × `COLOSSUS_LIFE` (3), sprite × 1,7 — le dessin seul, un corps
  physique mis à l'échelle déforme ses collisions —, ses dégâts par une ligne du nœud.
- **Fardeau partagé** (Nécrose), par `shared_burden`.

`IGNORED_BY_SHAPE` : `contagion` sous Nuée (en plus de `pierce`) ; `ground_duration`
sous Haleine ; `radius` sous Marque.

## 5. Les arbres — validés le 3 octobre, tels que livrés

Mêmes conventions qu'aux jalons 34 à 36 : chiffres de **premier réglage** ; « relié à
(n) » = points demandés dans le parent, un seul lien payé suffit ; ⇄ marque un échange.
**21 à 23 points pour un pool de 20** dans chaque arbre.

### Peste — la contagion

| nœud | pts | effet | relié à |
|---|---|---|---|
| Virulence *(gardé)* | 5 | +13 % dégâts plus | — |
| Fléau rampant | 2 | le trait traverse un ennemi par point | — |
| Condamnation *(gardé)* | 3 | +20 % dégâts accrus contre les maudits | Virulence (1) |
| Incubation | 4 | +15 % effet de la décomposition | Virulence (1) |
| **Contagion** *(gardé, devient vrai)* | 3 | à l'impact, la décomposition gagne les voisins à 20 px par point | Fléau rampant (1) ou Incubation (1) |
| Fléaux jumeaux | 2 | +1 trait par point | Fléau rampant (2) |
| Bubons | 3 | un pourrissant tué éclate, rayon 15 par point | Incubation (2) |
| **Nuée** | 1 | **un essaim lent qui traverse et mord son cercle** ⇄ −25 % dégâts, −60 % vitesse | Virulence (2) ou Condamnation (1) |

### Relève — la légion

| nœud | pts | effet | relié à |
|---|---|---|---|
| Moelle *(gardé)* | 5 | +12 % dégâts plus | — |
| Guet *(gardé)* | 3 | +20 % rayon de garde | — |
| Ossature | 4 | +25 % PV des morts-vivants | — |
| Légion d'os *(gardé)* | 1 | +1 mort-vivant | — |
| Frénésie | 3 | −10 % intervalle des coups | Moelle (1) |
| Rempart d'os | 3 | −2 % dégâts subis par mort-vivant debout | Ossature (1) |
| Dernier souffle | 3 | un mort-vivant qui tombe éclate, rayon 15 par point | Ossature (2) |
| **Colosse d'os** | 1 | **un seul mort-vivant, géant** : PV ×3, +150 % dégâts plus, frappe un cercle de 24 px | Moelle (2) ou Dernier souffle (1) |

### Déferlante toxique — le gaz qui étouffe

| nœud | pts | effet | relié à |
|---|---|---|---|
| Caustique *(gardé)* | 5 | +14 % dégâts plus | — |
| Miasme *(gardé)* | 3 | +20 % rayon | — |
| Haleine fétide | 4 | +15 % chance de flétrir | — |
| Dessiccation *(gardé)* | 3 | +25 % dégâts accrus contre les flétris | Haleine fétide (1) |
| Asphyxie | 4 | le flétri inflige 5 % de dégâts en moins par point | Haleine fétide (2) |
| Marais | 3 | laisse un sol toxique à sa taille, 1 s par point | Miasme (1) |
| **Haleine** | 1 | **un cône devant soi, 2,5× plus long que le rayon** ⇄ −15 % dégâts | Miasme (2) ou Asphyxie (1) |

### Porte pourrissante — la couvée

| nœud | pts | effet | relié à |
|---|---|---|---|
| Essaim *(gardé)* | 5 | +12 % dégâts plus | — |
| Couvée *(gardé)* | 4 | +25 % durée | — |
| Boursouflure *(gardé)* | 3 | +20 % rayon d'explosion | Essaim (1) |
| Rampants véloces | 3 | +25 % vitesse des créatures | Couvée (1) |
| Flair | 3 | elles voient 30 px plus loin par point | Rampants véloces (1) |
| Progéniture | 3 | en éclatant, chaque créature en lâche une petite par point, à 40 % | Boursouflure (1) |
| **Nid porté** | 1 | **le portail vous suit, les créatures partent de vous** ⇄ −30 % durée | Rampants véloces (2) ou Couvée (2) |

### Malédiction putride — la marque

| nœud | pts | effet | relié à |
|---|---|---|---|
| Anathème *(gardé)* | 3 | +25 % rayon | — |
| Malédiction prompte *(gardé)* | 3 | −12 % temps du geste | — |
| Malédiction profonde | 5 | +15 % effet de la malédiction (3 points de résistance) | — |
| Longue malédiction | 4 | +20 % durée de la malédiction | Malédiction profonde (1) |
| Tribut | 5 | chaque ennemi maudit rend 1 mana par point | Anathème (1) |
| **Marque de mort** | 1 | **un seul ennemi, à double force ; la marque passe au plus proche quand il meurt** ⇄ −25 % durée | Malédiction profonde (2) ou Tribut (1) |

### Nécrose avancée — la chair qu'on paie

Le buff « Nécrose » garde sa ligne ; les nœuds de buff s'y ajoutent tant qu'il tient.

| nœud | pts | effet | relié à |
|---|---|---|---|
| Gangrène | 5 | +4 chance de pourriture (buff) | — |
| Endurcissement | 3 | −20 % de vie rongée | — |
| Sang noir | 4 | +1,5 PV/s (buff) | Gangrène (1) |
| Chair morte | 4 | +8 % rés. nécrotique (buff) | Endurcissement (1) |
| Pacte | 4 | +15 % dégâts nécrotiques accrus (buff) ⇄ +25 % de vie rongée | Gangrène (2) |
| **Fardeau partagé** | 1 | **toutes les secondes, ce que la nécrose vous a rongé frappe ×4 les ennemis à 48 px** | Pacte (1) ou Sang noir (2) |

## 5 bis. Ce que la livraison a changé à la proposition

Validée par l'utilisateur telle quelle (« ok vasy »). Ce qui a bougé en chemin :

- **Les points** : la proposition donnait 15 à 19 points par arbre, sous le pool de 20 —
  on les aurait remplis sans choisir, ce que `test_no_tree_fills_up_entirely` refuse. Les
  nœuds prennent un ou deux points de plus ; Malédiction profonde passe de 25 à **15 %**
  par point et Malédiction prompte de 15 à **12 %**, pour que le total reste mesuré.
- **La règle** compte aussi la **durée** parmi les leviers de base (Couvée et Longue
  malédiction), et ne compte pas le prix d'un nœud qui change le jeu (le +150 % du
  Colosse).
- **La Marque de mort** devient une vraie transformation (`MARK`) plutôt qu'un drapeau :
  la fiche dit ainsi « sans effet avec » sur Anathème. Et elle a un prix, −25 % de durée :
  un nœud sans ligne est refusé (`test_each_node_has_a_name_and_effects`), et toutes les
  autres transformations en ont un.
- **Le Colosse** est un nombre, `colossus`, qui vaut le rayon de son coup : « +24 rayon
  de frappe du colosse » se lit, là où un drapeau aurait écrit « +1 colosse ».
- **Sang noir** rend des PV/s au lieu d'accroître ce que rend la pourriture : une
  statistique de fiche neuve arrive avec un affixe, ou n'arrive pas (RECETTES, « Ajouter
  une statistique »).
- **Portée double** (Porte, deux créatures par naissance) est retirée : elle doublait
  Couvée, et son nombre, `brood`, se lit « nombre de serpents ».
- **Fléaux jumeaux** perd son « ⇄ +10° d'écart » : `MIN_SPREAD` écarte déjà les traits.
- **Les liens** de la Nuée, du Colosse, de l'Haleine et du Fardeau ont changé de parent :
  les premiers auraient traversé la compétence ou un autre nœud sur la page.
- **Une seule force par état** (`decay_effect`, `wilting_weakness`, `curse_effect`) et
  non un « effet de l'état posé » commun : il aurait figuré dans trois arbres.
- **Le guide** : la décomposition, le flétrissement et la malédiction disent que des
  nœuds du Maître de la nécromancie les renforcent.
- **Le banc des arbres** mesure la nécromancie (`TREE_MANUALS`) et ne prend plus que ce
  qui frappe (`Skill.strikes()`), ce qui écarte la Malédiction comme les buffs.

## 5 ter. Les dessins, les captures, les bancs

**Choisis sur planche** (`Bureau\hns-captures-nuee-haleine\`, deux images, six partis
pris à trois temps chacune) :

- **la Nuée** : « spores en orbite » — douze spores qui tournent dans les deux sens dans
  le cercle qu'elle mord (`StaticOrb._swarm()`), contre un crâne cerné de mouches ou de
  volutes, une ronde de petits crânes, une spirale et un nuage de mouches à traînée ;
- **l'Haleine** : « mur de gaz en arc » — le mur bosselé de la Déferlante, sur les 70° du
  cône seulement (`Necrotic.breath()`), contre des spores semées, des langues de fumée,
  des volutes, des bouffées et des crânes hurlants.

Refaites avant de montrer la planche : les cellules de l'Haleine étaient trop basses (le
cône débordait sur la variante voisine) ; les spores semées tombaient **sur un arc** —
0,618 et 0,382 sont complémentaires, la profondeur et l'écart étaient liés ; la nappe
tramée sortait en dalle sombre (chaque point prenait son contour) ; la boule de gaz de la
Nuée se lisait comme un buisson.

**Le mur de l'Haleine se rastérise à l'angle exact** du geste, huit crans par lancer
gardés par le geste : **1,5 ms** le pire cran à 120 px de portée, 3,4 ms à 192 (Miasme
3). C'est l'éclairage des capsules (0,8 ms pour 38 formes, mesuré à part), le même prix
que le mur de la Déferlante — pas le vide : peindre le seul rectangle de l'arc au lieu
de quadrants n'a rien gagné, et a été retiré.

**Vu à la capture** (`Bureau\hns-captures-necro-jalon38\`, seize images, en ville puis
dans la première zone) : l'Haleine avance en arc vers le point visé et se dissout ; le
Colosse dépasse le joueur d'une tête ; la Marque pose son œil au-dessus d'un ennemi ; le
Nid porté se tient à l'épaule, ses créatures autour ; la Nuée reste discrète, quelques
spores. **Le Fardeau partagé emprunte l'explosion**, donc le mur de la Déferlante en anneau
autour du joueur à chaque seconde : il se confond avec une Déferlante. Un dessin à lui
passerait par une planche.

**Le banc des arbres** (`docs/ARBRES.md`, la nécromancie mesurée pour la première fois) :
les meilleurs builds rendent ×5 à ×12,5 au paquet, dans la fourchette des trois autres
manuels. **Trois transformations sortent des critères du jalon 37** : la Nuée ×1,13 au
paquet mais **×1,43 au duel** ; l'Haleine **×0,75 · ×0,68** ; le Nid porté **×0,69 · ×0,83**
— le banc tient sa cible à distance fixe, et le portail qui suit le joueur la cherche de
plus loin. Jamais pris : Condamnation et Contagion (Peste) — la Contagion recopie un état
que la Peste pose déjà sur tout ce qu'elle traverse —, Ossature, Rempart d'os et Dernier
souffle (Relève), que le banc ne voit pas.

**Le banc de combat** (300 ennemis tenus, la case lancée sans relâche, 240 images de
chauffe puis 1 440, cinq passes alternées) : Peste nue 5,85 ms contre 6,03 avec Virulence,
Fléau rampant, Fléaux jumeaux, Incubation, Contagion et Bubons — dans le bruit (écart type
0,3 à 0,7) ; Porte nue 5,26 contre 5,71 avec Progéniture 3 ; Déferlante nue 5,65 contre
**6,52 en Haleine** (Miasme 2 : un cercle de requête de 150 px à chaque image du cône).
**165 img/s partout, au plus 5,7 % du temps figé.**

**Relevé d'équilibrage** : `tests/run.sh balance`, 4 couloirs sur 5 en échec, sur les
personnages fixes du jalon 13, qui ne prennent aucun nœud. Pas de relevé « avant »
comparable : le jalon 37, non commité, est dans le même arbre.

## 5 quater. Après la livraison — demandé par l'utilisateur le 3 octobre

- **Le multiplicateur d'effet se lit** : sur la fiche, la ligne de l'état posé le porte
  (« décomposé · 100 % · ×1.30 ») ; la fenêtre des déclenchements (Alt) détaille l'état
  sous son nom — durée, brûlure par seconde, résistance retirée, affaiblissement,
  contagion — et donne la force du transi d'un sort de froid. Un seul calcul,
  `SkillStats.strength_of()`, que le coup, le sceau et la fiche lisent : un objet qui
  accroîtra un jour l'effet d'un état passera par là et se verra.
- **La Nuée** ne s'ouvrait que par Fléau rampant, qu'elle rend inopérant : elle s'ouvre
  par Virulence (2) ou Condamnation (1), qui servent sous elle. Et elle filait à la vitesse
  du trait, 150 px/s, trop vite pour mordre plusieurs fois : −60 %, 60 px/s.
- **Les créatures se lisent** dans la fenêtre Alt : les morts-vivants (debout, PV, rythme,
  garde, colosse, éclat, abri par tête), les créatures de la Porte (naissances, explosion,
  vue, course, petits) — Flair et Rampants véloces ne se voyaient nulle part.
- **La malédiction dit ce qu'elle fait** : sa fiche porte le bloc de son état — durée,
  résistance nécrotique retirée, effet. Elle ne frappe pas, la place y est.

**Au banc des arbres, la Nuée ralentie passe de ×1,13 · ×1,43 à ×1,37 · ×2,13** du
meilleur build sans elle : ses cibles immobiles sont le meilleur cas d'un essaim lent,
mais l'écart sort de la fourchette du jalon 37. Ses builds prennent aussi Fléau rampant,
seul chemin vers Fléaux jumeaux — des points payés pour une perforation qu'elle ignore.
À régler, avec l'Haleine et le Nid porté, quand l'utilisateur le demandera.

Les fiches qui frappent n'avaient pas la place du détail : le bloc complet sur la fiche
faisait sortir la Peste et la Porte du cadre de 25 px (`test_the_sheet_stays_in_frame`).
Vu à la capture (`Bureau\hns-captures-necro-jalon38\`, images 20 à 25).

## 6. Le déroulé

**Fait** : 1 à 5. **Reste** : le réglage des trois transformations hors critères (§5
ter), au banc des arbres comme au jalon 37 ; un dessin propre au Fardeau partagé, si
l'utilisateur le veut.

1. **Ce document**, et la validation du §5 par l'utilisateur.
2. **Le moteur** : la force des trois états (§4a), les nombres (§4b et c), les trois
   formes et le colosse — chacun avec son test de forme ; et
   `test_unique_trees_share_no_line_and_no_name`.
3. **Les arbres** dans `necrotic.tres`, descriptions comprises (relues contre le code).
4. **La Nuée et l'Haleine** sur planche (`/dessiner-un-effet`) ; capture fenêtrée du
   Colosse, du Nid porté, de la Marque et du Fardeau partagé.
5. **`/valider`** : la campagne ; le banc de combat (contagion, progéniture et éclats
   des morts-vivants multiplient les coups) ; `tools/catalog.sh` ;
   `tools/balance.sh trees` ; `tests/run.sh balance` relevé, sans correction.
   ARCHITECTURE et RECETTES dans le même geste.
