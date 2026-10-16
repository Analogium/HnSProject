# Hack'n'slash top-down — jalon 53

Suite des jalons 1 à 52. Ce document ne redit pas ce qui y est déjà écrit, et
`docs/ARCHITECTURE.md` reste le seul endroit qui décrit l'état courant.

**Ouvert le 15 octobre 2026.** Le **manuel du joueur de flûte** rempli, comme ceux de la
sorcière (jalon 41) et du Vive lame (jalon 50).

---

## 1. Ce que l'utilisateur a demandé

Une classe d'**attaques et de sorts**, aux dégâts **physiques ou nécrotiques** selon la
compétence (la conversion restant possible), avec **au moins une compétence liée aux
rats qui ne soit pas une invocation**, une petite note **musicale**, et surtout le **Roi
des Rats**, une compétence comme les autres qui le transforme. Les pistes retenues sont au
jalon 52, §8.

## 2. L'identité

Le chevalier tient ce qui pèse, la sorcière ce qui passe entre les éléments, le Vive lame
le tempo du duel. Le joueur de flûte tient **la vermine** : des rats qu'il accroche aux
ennemis, puis qu'il **fait payer**. Sa matière est ce que les autres n'ont pas :

- **les rats accrochés** — un compteur sur l'ennemi, pas un allié : ils ne se battent pas,
  ils **rongent**. Chaque rat inflige à son porteur, chaque seconde, des dégâts physiques
  égaux à **10 % du coup qui l'a accroché** (jusqu'à 10 rats, 8 s, rafraîchis à chaque rat
  posé). Lisible sur la fiche de l'ennemi. Ce n'est pas le saignement du chevalier : les
  rats se comptent un par un, la Danse macabre et le Roi des Rats les **consomment**, la
  Contagion les **transmet** ;
- **le charme** — l'attraction existe déjà en nœud (le brasier, la colonne sacrée, le
  cyclone) ; ici elle est la compétence elle-même, entretenue, et devient fuite chez le Roi ;
- **la contagion** — ce qu'un mort transmet à ses voisins.

Pas d'invocation (la nécromancie), pas d'élément, pas d'alternance (la sorcière).

## 3. Les compétences — la proposition

Chiffres de **premier réglage** ; l'équilibrage se fait en dernier (jalon 13, §7). Quatre
noms pensés au jalon 52 sont déjà pris (Morsure, Nuée, Peste, Harmonie) : renommés.

| case | niveau | type | nature | ce qu'elle fait |
|---|---|---|---|---|
| **Coup de croc** | 1 | attaque | physique | un coup d'arme sur le premier ennemi devant vous ; **accroche un rat** |
| **Marée de rats** | 2 | sort | physique | une vague de rats qui déferle au sol vers la visée ; chaque ennemi traversé prend un coup et **un rat** |
| **Air de Hamelin** | 3 | sort entretenu | nécrotique | une mélodie autour de vous : **attire** les ennemis proches, les ralentit, les ronge un peu |
| **Danse macabre** | 5 | attaque | physique, puis nécrotique | trois coups en avançant ; le dernier fait **éclater les rats** accrochés autour de la cible, chacun en dégâts nécrotiques |
| **Contagion** | 7 | sort | nécrotique | une malédiction au point visé ; un maudit qui meurt **transmet ses rats** à ses voisins, avec un éclat nécrotique |
| **Festin** | 10 | buff entretenu | physique | les rats **rongent plus fort** ; un ennemi achevé par le rongement vous rend vie et mana |
| **Roi des Rats** | 14 | sort | nécrotique | **la transformation** : consomme tous les rats accrochés à l'écran, et le change en Roi des Rats ; ses autres compétences changent de forme tant qu'il l'est |

### Coup de croc — `rat_bite`, niveau 1

Un coup d'arme (`attack_time_factor` 1,0) sur le premier ennemi de la ligne, comme l'estoc
de la Rafale. Accroche un rat. 5 mana. Par point : 10 · 13 · 16 · 20 · 25.

### Marée de rats — `rat_tide`, niveau 2

Une vague (la forme `WAVE` de la Vague tranchante) de 220 px vers la visée, 40 px de large :
une fois par ennemi traversé, un coup physique et un rat. Le dessin est neuf : un tapis de
rats qui déferle (planche). 10 mana. Par point : 14 · 18 · 23 · 29 · 36.

### Air de Hamelin — `hamelin_air`, niveau 3

Entretenu, 3 mana/s : dans 90 px, les ennemis sont **attirés vers vous** (plus doucement
que le Tourbillon), ralentis de 30 %, et prennent des dégâts nécrotiques toutes les 0,5 s.
Joué à la flûte, des notes qui tournent autour de lui. Par point : 4 · 5 · 6 · 8 · 10 par
battement.

### Danse macabre — `danse_macabre`, niveau 5

Trois coups (`attack_time_factor` 1,3), chacun en avançant de 24 px vers la visée. Le
troisième fait **éclater tous les rats accrochés** aux ennemis dans 64 px de sa cible :
chaque rat éclaté inflige un coup nécrotique à son porteur, et disparaît. 9 mana. Par
point : 10 · 13 · 16 · 20 · 25 par coup ; 6 · 8 · 10 · 13 · 16 par rat éclaté.

### Contagion — `contagion`, niveau 7

Une malédiction (la forme `CURSE`) de 60 px au point visé, 6 s : les maudits subissent des
dégâts nécrotiques accrus. Un maudit qui meurt **portant des rats** les passe à ses voisins
dans 80 px, répartis, et éclate en dégâts nécrotiques. 12 mana. Par point : +15 · 20 · 25 ·
30 · 35 % de dégâts nécrotiques subis ; éclat 20 · 26 · 33 · 41 · 50.

### Festin — `feast`, niveau 10

Entretenu, 2 mana/s. Tant qu'il brûle, le rongement des rats fait des dégâts accrus, et
**un ennemi tué par le rongement** vous rend 2 % de votre vie maximale et 3 mana — le
premier de la classe à faire du rongement une ressource. Par point : +20 · 25 · 30 · 35 ·
40 % de dégâts de rongement. *Remplace Contrepoint, refusé : « alterner n'est
probablement pas ce que je recherche ». En réserve : Note stridente, Terrier.*

### Roi des Rats — `rat_king`, niveau 14

Un sort (20 mana, recharge 30 s) : il **consomme tous les rats accrochés** aux ennemis à
l'écran, et le transforme pour 8 s **+ 0,5 s par rat consommé**. Tant qu'il est Roi des
Rats :

- il prend la planche du Roi des Rats (second modèle 3D, avec une animation de
  transformation) ;
- **Coup de croc** draine : 10 % des dégâts en vie, en nécrotique ;
- **Marée de rats** ne part plus droit devant : elle tourne autour de lui ;
- **Air de Hamelin** ne charme plus, il terrifie : les ennemis fuient ;
- les nœuds-suites de son arbre (durée, sortie, couronne) ne valent que là.

Par point : +10 · 13 · 16 · 20 · 25 % de dégâts nécrotiques plus pendant la transformation.

## 4. Ce qui serait neuf au moteur

- **Les rats accrochés** : un compteur par ennemi, distinct des états (qui ont une force,
  pas des charges), qui ronge, lu par la fiche ; et ce que le rongement tue (Festin).
- La **fuite** (Roi des Rats) ; l'attraction de l'Air de Hamelin reprend celle des nœuds
  qui attirent déjà (brasier, colonne sacrée, cyclone).
- **La contagion** à la mort d'un maudit.
- **Une transformation** : une compétence qui change, le temps d'un état, la forme
  d'autres compétences et la planche du personnage.
- La Danse macabre : une suite de coups qui avance, comme la Rafale mais en mouvement.

## 5. Le dessin, les gestes, les icônes

Chaque visuel passe par une planche (`/dessiner-un-effet`) : la Marée de rats, l'Air de
Hamelin, l'éclat des rats, la Contagion, le Roi des Rats (modèle 3D, choisi sur planche,
et sa transformation). Les sorts du manuel se jouent à la flûte : les **gestes joués**
(la flûte à la bouche) viennent ici. Les attaques neuves (Coup de croc, Danse macabre) ont
chacune leur geste. Une icône par compétence et par nœud.

## 6. Les arbres — la proposition

La règle, précisée par l'utilisateur à ce jalon : **l'originalité plutôt que la
répétition**, mais un nœud basique (coût, vitesse, dégâts, rayon, durée) peut revenir d'un
arbre à l'autre quand il y a sa place — ce n'est pas un interdit. Les noms, eux, restent
uniques. 12 à 13 nœuds, 30 à 34 points pour un pool de 20 ; une à deux suites derrière ce
qui change le jeu.
Conventions du jalon 42 : « relié à (n) » = points demandés dans le parent, ⇄ marque un
échange, *(neuf)* = un nombre de `SkillStats` à écrire, 🔗 = interaction avec une autre
compétence, **↳** = suite, accessible par son seul parent.

**Les interactions** : le Coup de croc lance une Marée (Rat d'égout) ; l'Air de Hamelin
accroche des rats (Rats charmés) et la Marée en accroche plus sous lui (Rats de cale) ;
la Danse macabre transmet sur les maudits de la Contagion (Rats pesteux) ; le Roi des
Rats renforce le drain du Coup de croc (Usurpateur).

### Coup de croc — la morsure *(12 nœuds, 30 points)*

| nœud | pts | effet | relié à |
|---|---|---|---|
| Mâchoire | 5 | +12 % dégâts plus | — |
| Long museau | 3 | +15 % rayon : le coup porte plus loin | — |
| Maigre pitance | 3 | −10 % coût en mana | — |
| Dents longues *(neuf)* | 3 | les rats qu'il accroche rongent +15 % plus fort par point | Mâchoire (1) |
| Double ration *(neuf)* | 2 | +1 rat accroché par point | Mâchoire (2) |
| Croc-en-jambe *(neuf)* | 2 | la cible mordue est ralentie de 10 % par point, 2 s | Long museau (1) |
| Appétit *(neuf)* | 3 | +5 % dégâts plus par point, par rat déjà accroché à la cible | Dents longues (1) |
| Dent vive | 3 | −8 % temps du geste | Maigre pitance (1) |
| **Gueule béante** *(neuf)* | 1 | **le coup mord tout l'arc devant vous** ⇄ −25 % dégâts plus | Long museau (2) |
| ↳ Mâchoires de fer *(neuf)* | 2 | sous la Gueule béante, +1 rat par point au premier ennemi mordu | Gueule béante (1) |
| **Rat d'égout** 🔗 *(neuf)* | 1 | **mordre un ennemi qui porte 5 rats lance une Marée de rats** depuis lui, droit devant | Appétit (2) |
| ↳ Crue *(neuf)* | 2 | cette marée accroche +1 rat par point | Rat d'égout (1) |

### Marée de rats — la déferlante *(13 nœuds, 30 points)*

| nœud | pts | effet | relié à |
|---|---|---|---|
| Fourmillement | 5 | +10 % dégâts plus | — |
| Longue course | 3 | +15 % rayon : la marée court plus loin | — |
| Large front *(neuf)* | 3 | +20 % de largeur par point | — |
| Prolifique *(neuf)* | 3 | un ennemi qui porte déjà des rats en reçoit un de plus par point | Fourmillement (1) |
| Remous *(neuf)* | 2 | la marée repousse de 12 px par point ce qu'elle traverse | Large front (1) |
| Faux pas *(neuf)* | 2 | les ennemis traversés sont étourdis 0,2 s par point | Remous (1) |
| Seconde vague *(neuf)* | 2 | +1 vague par point, 0,3 s après la précédente ⇄ +15 % temps du geste | Fourmillement (2) |
| Égout | 3 | +1 mana par ennemi traversé | Seconde vague (1) |
| **Trois rigoles** *(neuf)* | 1 | **la marée part en trois branches** écartées de 25° ⇄ −20 % dégâts plus | Large front (2) |
| ↳ Delta *(neuf)* | 1 | cinq branches au lieu de trois | Trois rigoles (1) |
| **Contre-courant** *(neuf)* | 1 | **au bout de sa course, la marée revient vers vous** et refrappe | Longue course (2) |
| ↳ Mascaret *(neuf)* | 2 | le retour frappe +15 % plus fort par point | Contre-courant (1) |
| Rats de cale 🔗 *(neuf)* | 2 | un ennemi sous l'Air de Hamelin reçoit +1 rat par point | Prolifique (1) |

### Air de Hamelin — le charme *(12 nœuds, 30 points)*

| nœud | pts | effet | relié à |
|---|---|---|---|
| Envoûtement | 5 | +12 % dégâts plus | — |
| Écho lointain | 3 | +15 % rayon | — |
| Souffle court | 3 | −15 % mana par seconde | — |
| Ensorcellement *(neuf)* | 3 | l'attraction est 20 % plus forte par point | Écho lointain (1) |
| Torpeur *(neuf)* | 3 | +10 % de ralentissement par point | Envoûtement (1) |
| Mélopée *(neuf)* | 3 | un ennemi qui reste sous l'air prend +4 % de dégâts par point et par seconde, jusqu'à 5 s | Envoûtement (2) |
| Pavane *(neuf)* | 2 | +8 % vitesse de déplacement par point tant que l'air joue | Souffle court (1) |
| Rats charmés 🔗 *(neuf)* | 2 | toutes les 2 s, un ennemi sous l'air reçoit un rat, un de plus par point | Torpeur (1) |
| **Carrousel** *(neuf)* | 1 | **les ennemis ne sont plus attirés vers vous : ils tournent autour de vous** | Ensorcellement (2) |
| ↳ Farandole *(neuf)* | 2 | sous la Carrousel, ceux qui tournent se heurtent : 10 % des dégâts par point à leurs voisins | Carrousel (1) |
| **Sérénade** *(neuf)* | 1 | **l'air se joue au point visé** au lieu de vous suivre, deux fois plus large | Écho lointain (2) |
| ↳ Requiem *(neuf)* | 2 | un ennemi qui meurt sous l'air pose une note qui frappe ses voisins, 20 % par point | Sérénade (1) |

### Danse macabre — la fin *(13 nœuds, 30 points)*

| nœud | pts | effet | relié à |
|---|---|---|---|
| Funèbre | 5 | +10 % dégâts plus | — |
| Grand écart | 3 | +15 % rayon : l'éclat prend les rats plus loin | — |
| Glissade *(neuf)* | 3 | +8 px par point à chaque pas | — |
| Ossuaire *(neuf)* | 3 | chaque rat éclaté inflige +12 % par point | Funèbre (1) |
| Temps de plus *(neuf)* | 2 | +1 coup par point ⇄ +15 % temps du geste | Glissade (1) |
| Pirouette *(neuf)* | 2 | le dernier coup frappe tout le cercle autour de la cible, à 40 % par point | Grand écart (1) |
| Fossoyeur *(neuf)* | 2 | +1 mana par point et par rat éclaté | Ossuaire (1) |
| Sauve-qui-peut *(neuf)* | 2 | les ennemis pris dans l'éclat fuient 0,5 s par point | Grand écart (2) |
| Chassé-croisé *(neuf)* | 2 | après la danse, vous reculez de 40 px par point | Glissade (2) |
| **Danse des morts** *(neuf)* | 1 | **l'éclat n'emporte plus les rats** : ils restent accrochés ⇄ −50 % dégâts de l'éclat | Ossuaire (2) |
| ↳ Ritournelle *(neuf)* | 1 | les rats restés rongent +30 % plus fort jusqu'à leur fin | Danse des morts (1) |
| **Totentanz** *(neuf)* | 1 | **chaque coup de la danse fait éclater un rat**, pas seulement le dernier | Funèbre (2) |
| ↳ Charnier *(neuf)* | 3 | chaque rat éclaté laisse 2 s un sol nécrotique, à 8 % par point | Totentanz (1) |

### Contagion — l'épidémie *(12 nœuds, 30 points)*

| nœud | pts | effet | relié à |
|---|---|---|---|
| Puanteur | 5 | +15 % effet de la malédiction | — |
| Foyer | 3 | +15 % rayon | — |
| Latence | 3 | +20 % durée | — |
| Accès de fièvre *(neuf)* | 3 | l'éclat d'un maudit qui meurt, +15 % par point | Puanteur (1) |
| Propagation *(neuf)* | 2 | les rats d'un mort vont à un voisin de plus par point | Foyer (1) |
| Lazaret *(neuf)* | 2 | les maudits infligent 6 % de dégâts en moins par point | Latence (1) |
| Porteur sain *(neuf)* | 2 | un maudit sans rat en reçoit un à la pose, un de plus par point | Latence (2) |
| Bubons noirs *(neuf)* | 3 | les rats d'un maudit rongent +10 % plus fort par point | Puanteur (2) |
| **Peste galopante** *(neuf)* | 1 | **la malédiction se transmet aussi** à la mort d'un maudit, avec sa durée restante | Propagation (1) |
| ↳ Grande peste *(neuf)* | 2 | chaque transmission prolonge la malédiction de 0,5 s par point | Peste galopante (1) |
| **Peste noire** *(neuf)* | 1 | **la malédiction tombe sur tous les ennemis porteurs de rats** à l'écran, au lieu du point visé ⇄ −40 % effet | Accès de fièvre (2) |
| Rats pesteux 🔗 *(neuf)* | 3 | un rat que la Danse macabre fait éclater sur un maudit en accroche un à son voisin, par point | Bubons noirs (1) |

### Festin — la faim *(12 nœuds, 30 points)*

| nœud | pts | effet | relié à |
|---|---|---|---|
| Voracité | 5 | +12 % dégâts de rongement | — |
| Ripaille *(neuf)* | 3 | +1 % de vie rendue par point, par mort | — |
| Table ouverte *(neuf)* | 3 | +1 mana rendu par point, par mort | — |
| Grignotage | 3 | +1 s de durée des rats par point | — |
| Insatiable *(neuf)* | 3 | +1 rat au plus par ennemi, par point | Voracité (1) |
| Ventre creux *(neuf)* | 2 | sous la moitié de votre vie, +20 % de rongement par point | Ripaille (1) |
| Embonpoint *(neuf)* | 2 | +3 % de vie maximale par point tant que le festin brûle | Ripaille (2) |
| Mastication *(neuf)* | 3 | les rats rongent 10 % plus souvent par point | Voracité (2) |
| Indigestion *(neuf)* | 2 | un ennemi tué par le rongement éclate sur ses voisins, 15 % de sa vie maximale par point | Mastication (1) |
| **Banquet** *(neuf)* | 1 | **chaque rat qui ronge vous rend 0,2 % de vie par seconde** ⇄ le festin coûte 2 mana/s de plus | Table ouverte (2) |
| ↳ Agapes *(neuf)* | 2 | sous le Banquet, le mana rendu par mort est doublé, puis +25 % par point | Banquet (1) |
| **Disette** *(neuf)* | 1 | **les rats ne meurent plus avec leur porteur** : ils sautent sur le plus proche à 64 px ⇄ −20 % de rongement | Insatiable (2) |

### Roi des Rats — le règne *(13 nœuds, 31 points)*

| nœud | pts | effet | relié à |
|---|---|---|---|
| Majesté | 5 | +10 % dégâts plus pendant le règne | — |
| Règne | 3 | +1 s de durée par point | — |
| Sceptre d'os *(neuf)* | 3 | −10 % de recharge par point | — |
| Cour des miracles *(neuf)* | 3 | +0,1 s de règne par point et par rat consommé | Règne (1) |
| Gabelle *(neuf)* | 2 | chaque rat consommé rend 1 % de vie par point | Majesté (1) |
| Trône *(neuf)* | 2 | +10 % de vie maximale par point pendant le règne | Sceptre d'os (1) |
| Peuple grouillant *(neuf)* | 2 | la Marée qui tourne autour du Roi frappe +15 % plus fort par point | Majesté (2) |
| Terreur *(neuf)* | 2 | la fuite de l'Air de Hamelin dure +0,5 s par point | Trône (1) |
| Usurpateur 🔗 *(neuf)* | 2 | le drain du Coup de croc, +5 % par point pendant le règne | Gabelle (1) |
| **Abdication** *(neuf)* | 1 | **à la fin du règne, une marée de rats jaillit tout autour** de vous | Règne (2) |
| ↳ Régicide *(neuf)* | 2 | cette marée frappe +20 % plus fort par point | Abdication (1) |
| **Couronne de queues** *(neuf)* | 1 | **chaque ennemi tué pendant le règne le prolonge de 0,5 s** | Cour des miracles (1) |
| ↳ Légende *(neuf)* | 3 | +0,1 s de plus par point et par mort, et le Roi grandit à chaque mort | Couronne de queues (1) |

## 7. Le moteur — ce qui est fait

Arbres validés tels quels (« ok je valide les arbres »). Le moteur est branché, sans dessin
neuf : la Marée et l'Air n'ont pas encore de visuel, la Danse et la morsure reprennent l'arc
d'épée et l'estoc. Les planches viennent ensuite (§5).

- **Les rats** sont un état, `StatusEffects.Kind.RATS` (« rongé »), et non un compteur à part :
  la fiche de l'ennemi, le compteur de DPS, l'auteur et le lancer qu'un état garde servaient
  tels quels. Leur nombre est sa force ; au plafond, un rat neuf remplace un rat moyen. Les
  règles de l'auteur (`StatusEffects.RatRules` : rongement, plafond, durée, Disette) sont
  écrites par le joueur et relues à chaque image : le Festin allumé change les rats déjà
  accrochés. Icône provisoire, à repasser sur planche.
- **`Vermin`** tient ce que deviennent les rats hors du coup qui les accroche : la mort d'un
  porteur (Contagion, Disette) et l'éclat de la Danse.
- **La fuite** : `Enemy.frighten()`, que l'EnemyManager fait courir (`flee()`) à la place du
  tick.
- **La règle des arbres** du §6 dans le test : `BASIC_LINES` — coût, temps du geste,
  recharge, vie, vitesse — reviennent d'un arbre à l'autre (Trône et Embonpoint donnent tous
  deux de la vie).

Écarts avec la proposition :

- **La Contagion** pose la malédiction nécrotique existante (−20 de résistance, que la
  Puanteur renforce) : ses points montent l'éclat à la mort (20 → 50), pas la malédiction.
- **La Légende** ne fait pas grandir le Roi : étirer sa planche irait contre la règle du pixel
  art. Elle prolonge seulement ; la taille viendra du modèle du Roi, rendu à plusieurs tailles.
- **L'éclat d'un maudit** ne maudit pas ses voisins : seule la Peste galopante passe la
  malédiction.

Trouvé en route : **l'Ouverture du jalon 50 ne s'éteignait jamais** sur un ennemi sans autre
état — l'EnemyManager n'avance que les ennemis dont `is_clear` est faux, et un minuteur sans
état n'y comptait pas. Le ralenti du jalon aurait eu le même défaut ; `is_clear` compte
désormais les deux, et l'Équilibre du jalon 49. Test : `test_a_lone_opening_or_hobble_wears_off`.

Suite : 1540 tests, tous passés, dont quinze neufs pour le joueur de flûte (dix en intégration, cinq unitaires).

## 8. Le dessin — ce qui est fait

Chaque choix a été fait sur planche, puis vu en jeu (`Bureau\hns-captures-<sujet>\`). La
matière vit dans `fx/piper.gd` (`Piper`), les grilles dans `EffectForge` (`RAT`, `RAT_DIAG`,
`NOTES`). Un rat se dessine de profil et de trois quarts, en deux images de trot ; les huit
caps viennent de ces deux grilles retournées, jamais tournées.

- **L'état rongé** (`hns-captures-rat-icone`) : une **tête de rat** de face, oreilles rondes.
  Un compteur en chiffres pixel (`StatusIcon.count()`) dit combien de rats la cible porte, posé
  à gauche de l'icône. Il ne mord que sur son contour : posé dessus, il cachait la tête.
- **La Marée** (`hns-captures-maree`) : le **tapis serré**, quinze rats au sol sous les corps
  (`DashTrail.layer`). Trois défauts vus à la capture :
  - tirées au hasard, leurs places laissaient un tapis bancal ; elles sont désormais réparties
    **par couloirs** ;
  - née sur le lanceur, la marée le recouvrait : elle part 16 px devant lui (`RatTide.START`) ;
  - pour la même raison, la traîne s'arrête à la distance déjà courue.
- **L'Air de Hamelin** (`hns-captures-air`) : la **ronde de notes**, croches et doubles
  croches qui tournent sur le bord du cercle, à la couleur de la nature du sort. Leur cœur
  reste sous 0,9 de luminance : ce n'est pas une lumière.
- **L'éclat des rats** (`hns-captures-eclat`) : des **rats qui jaillissent** en éventail du
  porteur avant de crever (`RatBurst`, cinq au plus). Les bouffées sont nécrotiques
  (`EffectForge.rot_puffs`), pas celles du feu.
- **La Contagion** (`hns-captures-contagion`) : la malédiction garde l'**œil putride**
  existant. Ce qui est neuf, ce sont **les rats qui courent** d'un mort à son héritier
  (`RatRun`, trois au plus, une bouffée à l'arrivée).

### Le Roi des Rats

Un second personnage, `rat_king`, que le règne pose à la place du joueur de flûte
(`Player._reign()`), comme un archétype. Il est passé par le tuyau 3D du jalon 51
(`Bureau\hns-roi-des-rats\`, 1 à 7).

Quatre directions de concept ont été refusées. L'utilisateur voulait **« un gros rat sur
deux pattes, bodybuildé »**, puis **« une tête de rat, bien musclé »**. Retenus : la brute
couronnée (ligne 1, graine 777) pour le concept et la graine 1337 pour la pose A. Le corps
fait 1,5 fois la largeur du joueur de flûte, en gris beige et or. Il a été accepté en jeu tel
quel (`hns-captures-roi`).

**Le Roi sortait sans jambes** : gris pâle sur un sol gris pâle, elles partaient avec le
fond. Le détourage de `tools/model_3d.py` passe donc à **GrabCut** (OpenCV), dans un cadre qui
ne laisse au fond que les bords de l'image. Repassé sur le joueur de flûte, il ne change rien
à son modèle.

### Les gestes

Trois gestes neufs, écrits dans `tools/blender/gestes.json`, cinq temps chacun, sur les deux
planches (`hns-gestes-piper`) :

- `bite` : le bond de la morsure ;
- `danse` : les trois temps de la danse ;
- `play` : la flûte à la bouche.

**`play` remplace `cast`** pour les sorts du manuel de classe : la main tient alors la flûte
(`Player` → `ActorSprite.attack(held)`). Un sort venu d'un autre manuel garde l'arme et
`cast`. Le Roi n'a pas de `play` : il n'a pas de flûte.

Bite et danse sont des **frappes** : la planche leur donne une image d'impact et l'orientation
de l'arme image par image. `character_forge.STRIKES_3D` les déclare. Sans cela, `STRIKES` ne
connaissait que les gestes du tuyau 2D, et le test des gestes de classe échouait.

Suite : 1543 tests, tous passés.

### Reste à faire

- La Légende : rendre le Roi à plusieurs tailles (§7).
- Les icônes des sept compétences, des 87 nœuds et du manuel.
