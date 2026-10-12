# Hack'n'slash top-down — jalon 48

Suite des jalons 1 à 47. Ce document ne redit pas ce qui y est déjà écrit, et
`docs/ARCHITECTURE.md` reste le seul endroit qui décrit l'état courant.

**Ouvert le 11 octobre 2026.** Les arbres du **manuel sacré** (Maître de la lumière) repris
comme ceux des flammes (jalon 42), de la foudre (jalon 43), du froid (jalon 44), de la
nécromancie (jalon 45) et du chevalier (jalon 46).

---

## 1. Ce que l'utilisateur a demandé

« Comme les jalons précédents avec les manuels, fais maintenant le manuel sacré. » Les
demandes du jalon 42, §1, valent telles quelles : un peu plus de nœuds, aucun nœud qui
revient d'un arbre à l'autre, des nœuds originaux par compétence, des **suites** derrière
ce qui change le jeu, quelques interactions, quelques leviers simples — et une vignette
par nœud (jalon 42, §14), arbre par arbre.

## 2. La règle du jalon

Celle du jalon 46, §2 : **aucun nom ni aucune ligne** ne revient d'un arbre à l'autre, sauf
un nœud de dégâts, de rayon et de durée par arbre, et les échanges entiers. Une suite n'a
qu'un parent et ne lit que des nombres que ce parent fait servir. Un nom ne double pas un
autre manuel.

Le sacré respecte la première moitié depuis le jalon 40. Ce qui lui manque : **six ou sept
nœuds par arbre, 21 ou 22 points**, aucune suite, et la moitié de ses nœuds sont des
leviers chiffrés. **Cible** : celle des jalons 44 à 46 — 13 à 21 nœuds par arbre, 30 à 40
points pour un pool de 20, deux à quatre nœuds que seule la compétence a, une à deux suites
par nœud qui change le jeu, une interaction dans deux arbres au plus, à l'intérieur du
manuel. **Onction** reste un passif, sans arbre.

**L'identité**, celle du jalon 40, §2 : ce qui **juge** (le trait, la colonne), ce qui
**bénit** — l'état défensif du jeu —, ce qui **monte en puissance** (la litanie) et ce qui
**protège le porteur** (la grâce, le soin). Pas de DoT, pas de critique, pas d'invocation.
Ce que la reprise ajoute : **le béni se retourne contre lui-même** (il se brûle en frappant,
il soigne en mourant), et **le sol consacré**.

Inspirations relevées : dans PoE, le *Divine Ire* qu'on tient puis qu'on lâche, le *Penance
Brand*, le sol consacré du *Purifying Flame* ; dans Diablo II, les auras du paladin —
*Redemption* (les morts soignent), *Sanctuary*, *Holy Fire*, *Conviction*, *Cleansing* — et
le *Holy Shield* ; dans Diablo III, le *Heaven's Fury* et l'*Akarat's Champion* du croisé ;
dans Last Epoch, les *Sigils of Hope* qui montent avec le temps.

## 3. Le manuel sacré — la proposition

### Noms pris ailleurs

Aucun des 27 noms actuels. Écartés en chemin : *Trinité* (une compétence de la sorcière) →
**Triptyque** ; *Conviction* (un nœud de l'arbre de passifs) → **Humilité**.

Conventions du jalon 42 : chiffres de **premier réglage**, « relié à (n) » = points demandés
dans le parent, ⇄ marque un échange, **neuf** = un nombre de `SkillStats` à écrire, 🔗 =
interaction avec une autre compétence, **↳** = suite, accessible par son seul parent.

### Frappe sacrée — la sentence *(7 → 16 nœuds, 39 points)*

| nœud | pts | effet | relié à |
|---|---|---|---|
| Percée *(gardé)* | 5 | +12 % dégâts plus | — |
| Allonge du trait *(gardé)* | 3 | +15 % rayon (la longueur) | — |
| Sanctification *(gardé)* | 4 | +15 % chance d'état (la bénédiction) | — |
| Réprobation *(gardé)* | 3 | +20 % dégâts accrus contre les bénis | Percée (1) |
| Bénédiction profonde *(gardé)* | 4 | +15 % effet de la bénédiction | Sanctification (1) |
| Réfraction *(gardé)* | 2 | au bout de sa course, le trait repart vers l'ennemi le plus proche, une fois par point | Allonge du trait (1) |
| Croix de lumière *(gardé)* | 1 | le trait part dans les quatre directions, sans viser ⇄ −30 % rayon | Percée (2) ou Réfraction (1) |
| **Diligence** | 3 | −8 % temps du geste par point | — |
| **Pénitence** *(neuf)* | 3 | **un béni qui vous frappe se brûle** : il prend 25 % du coup du trait par point, en sacré — le *Penance Brand* | Sanctification (1) |
| **Rédemption** *(neuf)* | 2 | un béni qui meurt vous rend 1 % de vos PV max par point — la *Redemption* | Bénédiction profonde (1) |
| **Faisceau** *(neuf)* | 1 | transformation : **le trait se tient** — tant que la touche est enfoncée, il brûle devant vous et frappe toutes les 0,25 s ; il draine 12 mana/s au lieu de son coût ⇄ −40 % dégâts plus — le *Divine Ire* | Percée (2) ou Diligence (2) |
| **Ostensoir** 🔗 *(neuf)* | 2 | **un trait qui traverse un Pilier sacré en repart en croix**, depuis la colonne, à 25 % du coup par point | Allonge du trait (1) |
| ↳ **Incandescence** *(neuf)* | 2 | le Faisceau tenu frappe 10 % plus fort par point et par seconde, 3 s au plus | Faisceau (1) |
| ↳ **Rosace** *(neuf)* | 1 | la Croix de lumière part aussi **sur les diagonales** : huit bras, les quatre neufs à 50 % | Croix de lumière (1) |
| ↳ **Vitrail** *(neuf)* | 2 | chaque rebond de la Réfraction frappe 15 % plus fort par point que le trait d'avant | Réfraction (1) |
| ↳ **Contrition** *(neuf)* | 1 | le béni que la Pénitence brûle est **assommé** 0,5 s — l'assommé de la Retombée (jalon 46) | Pénitence (1) |

Faisceau et Croix de lumière sont deux formes : pas de chemin de l'une à l'autre. Sous le
Faisceau, la Réfraction et le Vitrail ne servent plus (`IGNORED_BY_SHAPE`) — un rebond
toutes les 0,25 s, c'est une Croix gratuite ; l'Ostensoir, lui, sert.

### Pilier sacré — le jugement d'en haut *(7 → 14 nœuds, 36 points)*

| nœud | pts | effet | relié à |
|---|---|---|---|
| Jugement *(gardé)* | 5 | +12 % dégâts plus | — |
| Colonne *(gardé)* | 3 | +15 % rayon | — |
| Veille *(gardé)* | 4 | +20 % durée | — |
| Glas *(gardé)* | 3 | −10 % intervalle des impulsions | Jugement (1) |
| Appel céleste *(gardé)* | 3 | chaque impulsion attire les ennemis vers le cœur | Colonne (1) |
| Effondrement *(gardé)* | 3 | en s'éteignant, la colonne éclate, rayon 15 par point | Veille (1) |
| Pilier errant *(gardé)* | 1 | la colonne glisse vers l'ennemi le plus proche ⇄ −25 % rayon | Jugement (2) ou Veille (2) |
| **Verdict** *(neuf)* | 2 | **la colonne tombe** : sa première impulsion frappe 30 % plus fort par point | Jugement (1) |
| **Ascension** *(neuf)* | 3 | chaque ennemi tué dans la colonne la fait brûler 0,2 s de plus par point, 2 s au plus | Veille (1) |
| **Consécration** *(neuf)* | 3 | **la colonne consacre le sol** : tant que vous vous tenez dans son cercle, vous regagnez 1 % de vos PV max par seconde et par point — le sol consacré | Colonne (1) |
| **Triptyque** *(neuf)* | 1 | **trois colonnes** tombent en triangle autour du point visé ⇄ −40 % rayon | Colonne (2) ou Jugement (2) |
| ↳ **Sanctuaire** *(neuf)* | 1 | les ennemis dans le sol consacré sont **bénis**, sans tirage — le *Sanctuary* | Consécration (1) |
| ↳ **Apothéose** *(neuf)* | 2 | l'Effondrement frappe 3 % plus fort par point pour chaque ennemi que la colonne a frappé, 20 fois au plus | Effondrement (1) |
| ↳ **Procession** *(neuf)* | 2 | le Pilier errant glisse 30 % plus vite par point | Pilier errant (1) |

Triptyque et Pilier errant se prennent ensemble : chaque colonne suit son plus proche. Le
Triptyque triple aussi l'Effondrement et la Consécration — à remesurer.

### Pulsation sacrée — la litanie *(6 → 14 nœuds, 37 points)*

| nœud | pts | effet | relié à |
|---|---|---|---|
| Ferveur *(gardé)* | 5 | +12 % dégâts plus | — |
| Litanie *(gardé)* | 4 | +20 % durée | — |
| Rayonnement *(gardé)* | 3 | +15 % rayon | — |
| Cantique *(gardé)* | 3 | ajoute 2 à 5 dégâts sacrés par point | Ferveur (1) |
| Absolution *(gardé)* | 3 | chaque ennemi touché rend 1 PV par point | Litanie (1) |
| Exaltation *(gardé)* | 3 | chaque onde frappe 4 % plus fort par onde déjà partie, par point | Cantique (1) ou Litanie (2) |
| **Antienne** | 3 | −10 % recharge par point | — |
| **Égide** *(neuf)* | 3 | **chaque onde qui touche vous garde** : −1 % dégâts subis par ennemi touché et par point, jusqu'à l'onde suivante, 10 % au plus — le *Holy Shield* | Absolution (1) |
| **Purification** *(neuf)* | 2 | **chaque onde vous lave** : elle ôte 20 % par point de ce qui reste à vos états subis (embrasé, transi, pourri…) — le *Cleansing* | Litanie (1) |
| **Communion** 🔗 *(neuf)* | 2 | **une onde qui atteint un Pilier sacré le fait frapper aussitôt**, une impulsion de plus à 25 % de son coup par point | Rayonnement (1) |
| **Colère divine** *(neuf)* | 1 | transformation : **les ondes s'amassent** — aucune ne part avant la fin, et la dernière frappe de toutes à la fois, au rayon ×1,5 ⇄ rien ne frappe pendant la litanie | Ferveur (2) ou Exaltation (1) |
| ↳ **Extase** *(neuf)* | 2 | la dernière onde de la litanie porte au double du rayon et frappe 20 % plus fort par point | Exaltation (1) |
| ↳ **Viatique** *(neuf)* | 2 | l'Absolution rend aussi 1 mana par ennemi touché et par point | Absolution (1) |
| ↳ **Révélation** *(neuf)* | 1 | la Colère divine **bénit à coup sûr** tout ce qu'elle touche | Colère divine (1) |

Sous la Colère divine, l'Exaltation compte toujours : la dernière onde porte la somme de
celles qu'elle a amassées. L'Égide, l'Absolution et la Communion ne jouent qu'une fois.

### Lumière sacrée — la grâce *(6 → 13 nœuds, 36 points)*

La Grâce garde ses lignes ; les nœuds de buff s'y ajoutent tant que la lumière brûle.

| nœud | pts | effet | relié à |
|---|---|---|---|
| Zèle *(gardé)* | 5 | +4 % dégâts sacrés accrus (buff) | — |
| Recueillement *(gardé)* | 3 | −15 % mana drainé | — |
| Sérénité *(gardé)* | 4 | −2 % dégâts subis (buff) | — |
| Cuirasse de foi *(gardé)* | 4 | +30 armure (buff) | Sérénité (1) |
| Allégresse *(gardé)* | 3 | +4 % vitesse de lancement (buff) | Zèle (1) |
| Auréole *(gardé)* | 3 | les ennemis à 20 px par point sont bénis tant que la lumière brûle | Zèle (2) ou Sérénité (2) |
| **Pèlerin** | 3 | +4 % vitesse de déplacement (buff) | — |
| **Dévotion** *(neuf)* | 3 | **la ferveur monte** : chaque seconde de lumière ajoute 1 % de dégâts sacrés par point, 10 s au plus — les *Sigils of Hope* | Zèle (1) |
| **Intercession** *(neuf)* | 2 | tant que la lumière brûle, un coup qui vous ôte plus de 10 % de vie **bénit son auteur à coup sûr**, et son effet est accru de 25 % par point | Sérénité (1) |
| **Épiphanie** *(neuf)* | 1 | transformation : **la lumière ne draine plus** — elle s'allume 8 s, se recharge 20 s, et ses lignes valent le double pendant qu'elle brûle — l'*Akarat's Champion* | Zèle (2) ou Allégresse (1) |
| ↳ **Gloire** *(neuf)* | 2 | l'Auréole **brûle** : chaque seconde, elle frappe ce qu'elle bénit, 3 à 6 dégâts sacrés par point — le *Holy Fire* | Auréole (1) |
| ↳ **Humilité** *(neuf)* | 2 | les bénis de l'Auréole prennent 5 % de dégâts sacrés en plus par point — la *Conviction* | Auréole (1) |
| ↳ **Transfiguration** *(neuf)* | 1 | à son extinction, l'Épiphanie éclate autour de vous : rayon 60, 20 % de vos PV max en dégâts sacrés | Épiphanie (1) |

Sous l'Épiphanie, le Recueillement ne sert plus — rien n'est drainé (`IGNORED_BY_MECHANIC`) ;
la Dévotion monte sur ses 8 s.

### Récapitulatif

- **27 → 57 nœuds**, dont **13 suites** ; une trentaine de nombres neufs dans `SkillStats`.
  Deux arbres sur quatre ont une interaction, toutes deux **à l'intérieur du manuel** et
  toutes deux vers le Pilier sacré : l'Ostensoir (depuis le trait) et la Communion (depuis
  la pulsation). La colonne devient ce qui relie le sacré, comme l'Épée spirale relie le
  chevalier.
- **Chaque arbre a son rôle** : la Frappe le béni qui se retourne contre lui-même, le Pilier
  le sol qu'il consacre, la Pulsation ce qui garde et lave pendant la litanie, la Lumière la
  ferveur qui monte et l'aura qui brûle.
- **Ce qui se réutilise** : `DamageInfo.author` (Pénitence, Intercession : l'état de celui qui
  frappe dit s'il est béni) ; l'état qui garde son lancer (jalon 45 — la Pénitence frappe du
  lancer qui a béni) ; `Enemy.stun()` (Contrition) ; `SURE_STATE` (Sanctuaire, Révélation,
  Intercession) ; `Explosion.put()` (Transfiguration) ; `Player.heal()` et `gain_mana()`
  (Rédemption, Consécration, Viatique) ; le signal `slew` (Ascension, Rédemption) ;
  `Skill.SUSTAINED_SHAPES` et le drain du Cyclone (Faisceau) ; `wave_factor()` (Colère divine,
  Extase) ; la requête de cercle de l'Auréole (Gloire, Humilité) ; `Player.buff_mods()`
  (Pèlerin, Dévotion, Épiphanie).
- **Le neuf qui touche au joueur** : la **Purification** est le premier nœud qui raccourcit
  les états que porte le joueur ; la **Consécration** le premier sol qui agit sur lui.
- **Dessin** (`/dessiner-un-effet`) : le Faisceau tenu (rastérisé par cap, gardé comme le trait
  de la foudre, `Lightning.dart`), le sol consacré, l'éclat de l'Ostensoir et de la Rosace (le
  trait existant, pas de planche), l'onde amassée de la Colère divine. Les vignettes des 57
  nœuds passent par `tools/node_icons.py` ; la palette `holy` existe (jalon 46).
- **Ce qui se multiplie** : le Faisceau (un coup toutes les 0,25 s), la Rosace (huit traits
  rastérisés, dont quatre en diagonale, le pire cas mesuré au jalon 40), le Triptyque, la
  Communion, l'Ostensoir. À remesurer sur `world/stress_test.tscn`.
- **Livraison** arbre par arbre, chacun avec ses tests et ses vignettes : Frappe, Pilier,
  Pulsation, Lumière. `docs/ARBRES.md` se régénère ; les couloirs d'équilibrage se relèvent
  avant → après, sans les corriger (jalon 13, §7).

### Les questions

1. **Le Faisceau** est la plus grosse pièce : une forme neuve, tenue, qui se rastérise à
   chaque cap. Proposé : **32 caps fabriqués une fois et gardés**, comme le projectile de la
   foudre — ou pas de Faisceau, et la Frappe garde un seul geste.
2. **La Purification** touche aux états que porte le joueur — aucun nœud ne le fait
   aujourd'hui. D'accord ?
3. **L'Épiphanie** : 8 s allumée, 20 s de recharge, lignes doublées, sans drain. D'accord sur
   ces chiffres de premier réglage ?
4. **Le manuel reste le plus mince** : quatre compétences contre six au chevalier et à la
   nécromancie. Une cinquième (un marteau béni, à la *Blessed Hammer*) serait un jalon à
   part — la vouloir ?

## 4. Les réponses

L'utilisateur, sur la proposition : « j'accepte, le nouveau skill tu peux l'intégrer aussi
dans ce jalon ».

- **le Faisceau** est fait, ses caps fabriqués une fois et gardés ;
- **la Purification** touche aux états que porte le joueur ;
- **l'Épiphanie** : 8 s allumée, 20 s de recharge, lignes doublées ;
- **une cinquième compétence**, le marteau béni, entre **dans ce jalon** — §4 bis.

Livraison arbre par arbre, en commençant par la Frappe sacrée ; le marteau en dernier, avec
sa planche.

### 4 bis. Le Marteau béni — la proposition

Le *Blessed Hammer* de Diablo II : un marteau de lumière qui part du lanceur **en spirale qui
s'élargit**, frappe ce qu'il croise et s'éteint. Ce qu'aucun sort du manuel ne fait : il
couvre le cercle autour de soi **en temps**, pas d'un coup — la Pulsation frappe tout le
cercle d'un coup, le Pilier un point visé, le trait une ligne.

| | |
|---|---|
| sort sacré | niveau 3 du manuel, 5 points |
| coût, geste | 12 mana, 0,6 s |
| forme | `HAMMER`, neuve : 1,2 s de vol, la spirale s'ouvre jusqu'à 70 px, un même ennemi frappé au plus toutes les 0,5 s |
| dégâts par point | 10 · 13 · 16 · 20 · 25 |

**Son arbre — le marteau** *(13 nœuds, 33 points)*

| nœud | pts | effet | relié à |
|---|---|---|---|
| **Aplomb** | 5 | +12 % dégâts plus | — |
| **Envolée** | 3 | +15 % rayon (où la spirale finit) | — |
| **Ferrure** | 4 | +20 % durée (des tours en plus) | — |
| **Allègement** | 3 | −10 % coût en mana par point | — |
| **Prestesse** *(neuf)* | 3 | le marteau tourne 10 % plus vite par point | Envolée (1) |
| **Carillon** *(neuf)* | 2 | +1 marteau par point, partis en étoile | Aplomb (1) |
| **Martèlement** *(neuf)* | 3 | chaque coup d'un marteau sur un même ennemi frappe 10 % plus fort par point que le précédent | Aplomb (1) |
| **Tocsin** *(neuf)* | 3 | un ennemi tué par un marteau en lâche un petit, qui part en spirale à 40 %, 10 % de plus par point | Ferrure (1) |
| **Gravitation** *(neuf)* | 1 | transformation : **le marteau ne s'éloigne plus** — il tourne autour de vous à rayon fixe, toute sa durée ⇄ −30 % dégâts plus | Envolée (2) ou Prestesse (2) |
| ↳ **Bourdon** *(neuf)* | 1 | un marteau du Carillon sur trois est un bourdon : il frappe 50 % plus fort et plus large | Carillon (1) |
| ↳ **Battage** *(neuf)* | 2 | au cinquième coup du Martèlement sur un ennemi, un éclat sacré frappe autour de lui, 40 % du coup par point | Martèlement (1) |
| ↳ **Branle** *(neuf)* | 1 | les petits marteaux du Tocsin en lâchent à leur tour, une fois | Tocsin (1) |
| ↳ **Éclipse** *(neuf)* | 2 | sous la Gravitation, l'orbite s'élargit de 10 % par seconde et par point | Gravitation (1) |

Pas d'interaction : deux arbres sur cinq en ont déjà une. Le marteau se dessine
(`/dessiner-un-effet`, planche choisie par l'utilisateur) ; un dessin provisoire en attendant.
Son icône de compétence et ses 13 vignettes passent par le tuyau Qwen avec les autres.

## 5. Les cinq arbres — livrés

Les quatre arbres du §3 et le Marteau béni du §4 bis d'un tenant. Le manuel compte **70
nœuds** (27 → 57, plus les 13 du marteau), dont 17 suites ; trente-cinq nombres neufs dans
`SkillStats`, de `PENANCE` à `ECLIPSE`.

### Ce qui est neuf au moteur

- **Le Faisceau** (`Skill.Shape.RAY`, `HolyRay`) : le premier **geste entretenu qu'on
  atteint par transformation** — il est à la fois dans `SUSTAINED_SHAPES` et dans
  `TRANSFORMABLE`. Il se relit à chaque frappe (`Player.resolve()`), donc s'éteint seul si le
  nœud est repris, et frappe par `HolyBeam.burn()`, ce que mord une ligne, extrait du trait.
  Sa période (0,25 s) et son drain (12 mana/s) viennent de `Skill.SHAPE_NUMBERS`. Son dessin est
  le trait de la Frappe, gardé par cap (`Slash.TURNS`) et par longueur (`Holy.ray()`).
- **Le Marteau béni** (`Skill.Shape.HAMMER`, `BlessedHammer`), la compétence neuve : une
  spirale qui s'ouvre du point de lancer jusqu'au rayon (`HAMMER_SPEED`), un même ennemi au
  plus une fois par période (`Targets.Contacts`). Le Familier la rejoue (`Familiar.ECHOED`).
- **La Pénitence** passe par le chemin des Ronces : `StatusEffects.landed()` émet `smitten`
  quand le porteur béni frappe, et l'ennemi se frappe (`Enemy._on_smitten()`) d'une part du
  lancer qui l'a béni, au nom de son auteur. **La Rédemption** passe par `fell`, qui porte
  désormais la sorte de l'état : un lancer en pose parfois deux, et elle aurait soigné deux fois.
- **L'Ostensoir** et **la Communion** trouvent les piliers du lanceur par
  `SacredPillar.standing_for()`, sur le patron de `IceVortex._live`.
- **L'Égide** est un abri du joueur comme l'Accalmie (`Player.guard()`, `_aegis`) ; **la
  Purification** raccourcit tous les états qu'il porte (`StatusEffects.shorten()`).
- **L'Humilité** fond la résistance au sacré par le champ `melt` de la bénédiction : la Fonte
  du feu, généralisée (`StatusEffects.melt(amount, kind)`).
- **L'Épiphanie** se résout dans `SkillStats.finalize()` (durée, recharge et drain fixes) et
  double les lignes dans `Player.buff_mods()`. **La Dévotion** est `Player.devoted()`, lue au
  lancer et à chaque frappe du Faisceau. **L'Intercession** pose l'état sans frapper, la
  troisième exception de l'invariant 5 avec la malédiction et l'Auréole.

### Les écarts avec la proposition

- **Le Faisceau s'allume et s'éteint à la touche**, comme le Cyclone, au lieu de brûler tant
  qu'on la tient : aucun geste du jeu ne se tient, et tenir n'alterne pas (`cast_slot()`). Il
  ne s'ouvre que par la Percée (2) : depuis la Diligence, le lien serait passé sous la
  Réprobation. La Diligence, la Réfraction et le Vitrail sont sans effet sous lui
  (`IGNORED_BY_SHAPE`).
- **La Colère divine ne s'ouvre que par l'Exaltation (1)** : depuis la Ferveur, le lien rasait
  l'Exaltation.
- **Le Sanctuaire bénit par le coup**, à `SURE_STATE`, et non sans coup : l'invariant 5 n'a
  pas d'exception de plus, et c'est l'impulsion de la colonne qui touche le sol consacré.
- **La Gloire frappe d'une part des PV max** (1 % par point à chaque passage de l'Auréole,
  toutes les 0,5 s) plutôt que de 3 à 6 dégâts ajoutés : le Cantique de la Pulsation porte déjà
  la ligne `damage_holy`, et deux arbres ne la partagent pas.
- **Le Viatique est `mana_on_hit`**, le nombre de la Fauche vorace, et non un nombre neuf.
- **Le Tocsin vaut 40 % au premier point** (`first_point_bonus`), puis +10 % par point.
- **Le Marteau fait deux tours et demi** sur sa durée, et non un et demi : au banc des arbres,
  la spirale nue s'ouvrait de 47 px par tour pour une morsure de 16 px, et **un ennemi seul au
  contact n'était jamais touché** (0/s au duel, 9,9/s au paquet). À deux tours et demi : 38/s
  et 149/s, la hauteur de la Frappe sacrée.
- **Libellés raccourcis** : quatre débordaient de la fiche du nœud
  (`test_passive_and_node_sheets_fit_in_both_languages`).
- **L'icône du Marteau** est provisoirement celle de la Frappe, jusqu'au tuyau Qwen.

### Les tests

Vingt-deux tests de plus dans `test_shapes.gd`, par arbre (« La Frappe sacrée (jalon 48) » et
suivants), sur le vrai chemin du lancer ou sur de vrais grunts : le Faisceau qui refrappe et
s'éteint, la Rosace, le Vitrail, l'Ostensoir, la Pénitence et la Contrition, la Rédemption ;
le Verdict, le Triptyque, la Consécration et le Sanctuaire, l'Ascension, l'Apothéose ; la
Colère divine, l'Égide, le Viatique, la Purification et la Communion ; l'Épiphanie et la
Transfiguration, la Gloire et l'Humilité, l'Intercession, la Dévotion ; la spirale du marteau,
le Carillon et le Bourdon, la Gravitation, le Martèlement et le Battage, le Tocsin. Le Faisceau
s'ajoute à `test_the_holy_transformations_carry_their_shapes`, le marteau à
`test_each_shape_has_the_numbers_it_needs`.

La campagne : **1 453 tests, tous verts**.

### Le banc

Relevé sans correction (jalon 13, §7), `tools/balance.sh trees only=…`.

| compétence | | avant | après |
|---|---|---|---|
| Frappe sacrée | paquet | ×3,21 | ×4,79 (Croix, Rosace, Diligence, Réfraction) ; ×4,92 en Croix |
| | duel | ×2,52 | **×5,12** (Faisceau, Incandescence) |
| Pilier sacré | paquet | ×5,08 ; ×8,27 errant | **×17,3** (Triptyque, Ascension) |
| | duel | ×4,27 | **×13,7** (Triptyque, Apothéose) ; ×14,4 errant |
| Pulsation sacrée | paquet | ×2,20 | ×5,04 (Colère divine, Extase) |
| | duel | ×6,06 | **×10,8** (Colère divine, Extase, Exaltation) |
| Marteau béni | paquet | — | ×10,6 (Carillon, Bourdon, Tocsin, Branle) |
| | duel | — | **×16,6** (Carillon, Bourdon, Martèlement) |

**Le Triptyque est hors d'échelle au duel** : ses trois cercles touchent tous le point visé, et
une cible seule y prend trois colonnes — la forme promettait une zone plus large, pas un coup
triple. À reprendre à l'équilibrage, en premier, en écartant les colonnes. Le Marteau au duel
cumule les marteaux du Carillon sur la même cible. La Frappe a été relevée deux fois : avant que ses traits ne
se calent sur les caps (§ « La performance »), la Croix au paquet rendait ×6,72 ; après, ×4,92,
et la recherche n'y prend plus qu'une Réfraction — le calage ou la recherche gloutonne, ce n'est
pas tranché. Jamais pris — le banc ne voit ni les coups
reçus, ni le soin, ni les piliers posés à côté : Bénédiction profonde, Pénitence, Contrition,
Rédemption, Ostensoir (la Pénitence et la Contrition prises au second relevé, une fois : les
grunts du banc frappent) ; Appel céleste, Consécration, Sanctuaire, Procession ; Rayonnement,
Cantique, Absolution, Égide, Purification, Communion, Viatique, Révélation ; Allègement,
Gravitation, Battage, Éclipse. La Lumière ne frappe pas et n'est pas mesurée.

Les couloirs de `tests/run.sh balance` ne sont pas relevés : aucun des personnages fixes du
jalon 13 ne porte le manuel sacré (jalon 40, §5 ter), l'avant et l'après sont les mêmes par
construction.

### La performance

Banc `world/stress_test.tscn` patché sur une copie : **300 grunts serrés** (4 cases autour du
joueur) et increvables, la case 0 relancée à chaque image — un geste entretenu seulement s'il
est éteint, sinon le Faisceau s'allumerait et s'éteindrait sans fin —, 240 images de chauffe puis
1 440, cinq scénarios alternés sur cinq tours. Plus lourd que le tableau de référence, qui
mêle les ennemis sur un large rayon : la Frappe nue y coûte 10,7 ms de physique.

| scénario | physique |
|---|---|
| Frappe nue | 10,7 ms |
| Croix, Rosace, Réfraction 2, Vitrail 2 | 13,2 ms |
| Faisceau, Incandescence | 11,1 ms |
| Marteau, Carillon 2, Bourdon, Battage | 11,9 ms |
| Pilier, Triptyque, Consécration, Apothéose | 11,1 ms (un tir isolé à 16,8) |

**Le trait se rastérisait à chaque naissance** : au premier relevé, la Croix sous Rosace,
Réfraction et Vitrail coûtait 20,9 ms. Découpé scénario par scénario, la Croix seule ne coûtait
presque rien ; la Rosace (+6,5 ms) et la Réfraction (+7 ms, **du jalon 40**) posent des traits
en biais, à 1,16 ms chacun. Essayé sur la copie avec des traits gardés par cap : 15,2 et
16,1 ms contre 21 et 21,6. **Retenu** : tout trait se cale sur l'un des 32 caps
(`Slash.TURNS`) et se fabrique une fois par cap et par longueur (`Holy.ray()`), et il frappe
le long de ce cap — 5,6° au plus de la visée, 8 px au bout d'un trait de 80, moins que sa
largeur et le corps d'une cible. Le Tocsin ne se voit pas ici : les grunts du banc ne meurent
pas.

### Ce qui reste au jalon

- ~~**les planches**~~ — faites, §6 ;
- ~~**les vignettes**~~ — faites, §11 ;
- **l'équilibrage**, en dernier — d'abord le Triptyque.

## 6. Les planches — le marteau, le sol consacré, la Colère, le Faisceau

Par `/dessiner-un-effet`. Planches sur le Bureau, `hns-captures-planches-sacre\`, six partis pris
chacune, montrés dans leur geste (trois temps de la spirale, de la litanie, du trait tenu) ;
captures en jeu dans `hns-captures-sacre-jalon48\`.

- **Le marteau** (`1-planche-marteau.png`) : marteau de guerre, maillet, tau, étoile qui tourne,
  marteau et traîne de grains, marteau et croissant. **Choisi : le marteau de guerre.** Refaits
  avant de montrer : tous sortaient en taches de 9 px — agrandis à 13, **manche plus sombre que
  la tête** (tout clair, tourné en biais, il redevenait une tache) ; le croissant ne suivait pas
  son marteau.
- **Le sol consacré** (`2-planche-sol-consacre.png`, seul puis sous la colonne) : le halo actuel,
  des dalles, une croix pattée, des rayons, deux cercles et quatre croix, des grains qui
  scintillent. **Choisi : les dalles.** Refaite avant de montrer : la croix pattée, trop large,
  se lisait comme un X sombre.
- **La Colère divine** (`3-planche-colere-divine.png`, début et milieu de la litanie, puis
  l'onde) : rien, des grains aspirés, une couronne, un anneau qui se resserre, des croix en
  orbite, une colonne qui monte. **Choisi : les grains aspirés.** Refaites avant de montrer : les
  croix (3 px, des points) et la colonne, qui flottait au-dessus de la tête.
- **Le Faisceau** (`4-planche-faisceau.png`) : le trait de la Frappe, un trait qui pulse, des
  anneaux qui avancent, un éclat au bout, une tresse, une poussière qui tombe. **Choisi par
  l'utilisateur hors des quatre options proposées : les anneaux.** Refait avant de montrer :
  l'éclat, cuit dans le trait, s'y fondait.

**Vu à la capture, corrigé dans le jeu** :
- **le Faisceau tenu couvrait le buste du joueur** de l'éclat de départ du trait — fait pour un
  coup de 0,16 s ; il part désormais à `LEAD` (8 px) du corps, sans éclat, et ses anneaux ont
  grossi d'un pixel (`RING_RADIUS`), qui ne dépassaient le trait que d'un ;
- **l'onde lâchée de la Colère** était l'onde ordinaire, une rangée ; elle porte la seconde
  rangée de la planche (`WRATH_ROW`).

Corrigé dans le scénario et non dans le jeu : sans coup pendant six secondes de litanie, le
joueur mourait sous les grunts avant l'onde ; la capture le rend invulnérable.

**Mesuré** (banc headless, `tools/planche.sh`) : le trait à anneaux 0,86 ms par cap et par temps
la première fois, 1,17 ms en diagonale ; le marteau 1,15 ms par orientation ; le sol consacré
0,80 ms au rayon 32, 1,34 ms au rayon 41 — une fois par rayon, qui ne change qu'avec un nœud.
Tout se relit ensuite en quelques µs.

Quatre tests de plus (`test_effect_forge.gd` : la grille du marteau, ses huit orientations
gardées, le sol cerné et gardé, les anneaux cuits par temps et distincts du trait de la Frappe).
La campagne : **1 457 tests, tous verts**.

## 7. Les Chaînes du jugement — la proposition

L'utilisateur, une fois les planches faites : « en vrai je n'aime pas du tout frappe sacrée comme
skill, je voudrais le remplacer par un nouveau ». Entre une invocation (l'ange gardien), un
bouclier lancé et un coup de bouclier en mêlée, **il choisit les Chaînes du jugement**.

**Ce qui part avec la Frappe** : son arbre de 16 nœuds — le Faisceau, la Croix de lumière et la
Rosace, la Pénitence et la Contrition, la Rédemption, l'Ostensoir, le Vitrail, la Réfraction —,
`HolyBeam`, `HolyRay`, le trait de `Holy`, le signal `smitten` et une dizaine de nombres de
`SkillStats`. Les entrées `BEAM`, `HOLY_CROSS` et `RAY` de `Skill.Shape` restent (les `.tres`
écrivent l'entier), sans plus rien derrière. **Les personnages qui avaient des points dans la
Frappe** les perdraient : un identifiant inconnu compte comme dépensé (`Manual.points_spent`).
Le chargement oublie donc ce que le manuel ne connaît plus, et le point revient au livre.

### La compétence

Ce qu'aucun manuel ne fait : **des ennemis qui partagent leur sort**. Un trait de fer béni part
vers le point visé ; au premier ennemi touché, il l'enchaîne à ses plus proches voisins. Tant
que les chaînes tiennent, **une part de chaque coup que prend un enchaîné passe à tous les
autres** — quelle qu'en soit la source : le Pilier, le Marteau, la Pulsation. Ce qui juge l'un
juge les autres.

| | |
|---|---|
| sort sacré | niveau 1 du manuel (la case de la Frappe), 5 points |
| coût, geste | 10 mana, 0,5 s |
| forme | `CHAINS`, neuve : un trait à 420 px/s, jusqu'à 220 px ; au premier touché, enchaîne ses **2** plus proches voisins à 90 px (le rayon), pour **4 s** |
| partage | **30 %** de chaque coup subi par un enchaîné frappe chacun des autres, en sacré. Un coup partagé ne se repartage pas, ne critique pas et ne pose pas d'état |
| dégâts par point | 9 · 11 · 14 · 18 · 22 (ceux de la Frappe) — le coup du trait, sur le premier touché et sur chaque enchaîné au moment du lien |

Un ennemi ne porte **qu'un faisceau de chaînes** : relancées sur lui, les chaînes neuves
remplacent les anciennes. Un enchaîné qui s'éloigne de plus de deux rayons du premier touché
rompt son lien.

### Son arbre — le jugement partagé *(15 nœuds, 37 points)*

| nœud | pts | effet | relié à |
|---|---|---|---|
| **Réquisitoire** | 5 | +12 % dégâts plus | — |
| **Ampleur** | 3 | +15 % rayon (jusqu'où la chaîne cherche ses voisins) | — |
| **Geôle** | 4 | +20 % durée des liens | — |
| **Aspersion** | 4 | +15 % chance d'état (la bénédiction) | — |
| **Maillons** *(neuf)* | 3 | +1 enchaîné par point | Ampleur (1) |
| **Solidarité** *(neuf)* | 3 | +6 points de part partagée par point (30 → 48 %) | Réquisitoire (1) |
| **Resserrement** *(neuf)* | 2 | les chaînes tirent les enchaînés vers le premier touché, 20 px/s par point | Geôle (1) |
| **Rupture** *(neuf)* | 3 | un enchaîné qui meurt éclate : 25 % du coup de la chaîne par point, autour de lui | Réquisitoire (1) |
| **Pilori** 🔗 *(neuf)* | 2 | les enchaînés sont tirés vers le Pilier sacré qui brûle le plus près, 25 px/s par point | Ampleur (1) |
| **Martyre** *(neuf)* | 1 | transformation : **les chaînes partent de vous**. Elles vous lient aux ennemis les plus proches, autant que le trait en enchaînerait, dans deux rayons ; la part partagée des coups **que vous prenez** passe à eux au lieu de vous ⇄ −30 % dégâts plus | Geôle (2) ou Solidarité (2) |
| ↳ **Carcan** *(neuf)* | 1 | un enchaîné que le Resserrement amène au contact du premier touché est assommé 0,5 s, une fois par lien | Resserrement (1) |
| ↳ **Passation** *(neuf)* | 2 | les chaînes d'un enchaîné qui meurt sautent sur l'ennemi libre le plus proche, une fois par point | Maillons (1) |
| ↳ **Absoute** *(neuf)* | 1 | l'éclat de la Rupture bénit à coup sûr ce qu'il touche | Rupture (1) |
| ↳ **Unisson** *(neuf)* | 1 | les coups partagés posent les états de celui qui les a causés | Solidarité (1) |
| ↳ **Stigmates** *(neuf)* | 2 | sous le Martyre, chaque coup détourné vous rend 1 % de vos PV max par point | Martyre (1) |

Sous le Martyre, le Resserrement et le Carcan ne servent plus (`IGNORED_BY_SHAPE`) : tirer
les ennemis vers soi est l'inverse de ce que veut un porteur. Le Pilori sert.

**Le Pilori remplace l'Ostensoir** comme interaction avec le Pilier sacré : deux arbres sur
cinq en ont toujours une (le Pilori et la Communion), toutes deux vers la colonne.

**Ce qui se réutilise** : le signal `Hurtbox.damaged` (le partage, comme l'Intercession lit les
coups du joueur) ; `Explosion.put()` (Rupture) ; `Enemy.stun()` (Carcan, comme la Contrition
qui s'en va) ; `SURE_STATE` (Absoute) ; `SacredPillar.standing_for()` (Pilori) ;
`Targets.nearest()` (Passation) ; le recul négatif de l'Appel céleste (Resserrement, Pilori).

**Ce qui se multiplie** : un coup sur un enchaîné en donne autant qu'il a de compagnons. Sous
la Pulsation, chaque onde qui couvre un faisceau de cinq fait vingt coups partagés. À
remesurer sur `world/stress_test.tscn`. Les nombres affichés des coups partagés se regroupent
peut-être, à juger à la capture.

**Dessin** (`/dessiner-un-effet`, planche choisie par l'utilisateur) : le trait lancé, et la
chaîne **posée maillon par maillon** le long du lien (une forme qui se répète à toute
longueur, sans étirement ni rotation de planche). L'icône de la compétence et les 15
vignettes passent par Qwen avec celles des autres arbres.

### Les questions

1. **Le Martyre** détourne vers les ennemis une part des coups que prend le joueur. C'est le
   premier nœud qui le fait. D'accord ?
2. **Le partage passe en sacré**, quelle que soit la nature du coup d'origine. Il est donc
   bloqué par la résistance sacrée de chaque enchaîné, et il se lit en jaune pâle à l'écran.
   Ou bien il garde les natures du coup d'origine ?
3. **Ce qui part avec la Frappe** : le Faisceau et ses anneaux, à peine dessinés, la Pénitence
   et la Rédemption. Les laisser partir, ou en greffer une sur un autre arbre du sacré ?

## 8. Les Chaînes du jugement — livrées

L'utilisateur, sur la proposition : « oui pour tout ». Le Bouc émissaire détourne des coups du
joueur, le partage frappe en sacré, la Pénitence et la Rédemption partent avec la Frappe.

### Ce qui part, ce qui vient

- **Parti** : `resources/skills/holy_strike.tres`, ses 16 nœuds, `HolyBeam`, `HolyRay`, le trait
  de `Holy` (`ray()`, `_lance()`, les anneaux), le signal `smitten` et `Enemy._on_smitten()`, la
  sorte d'état que `fell` portait pour la seule Rédemption, sept nombres de `SkillStats`, leurs
  textes anglais et leurs tests. `BEAM`, `HOLY_CROSS` et `RAY` restent dans `Skill.Shape`, vides.
- **Venu** : `judgment_chains.tres` dans la case de la Frappe, `JudgmentChains`
  (`actors/skills/judgment_chains.gd`), les formes `CHAINS` et `SCAPEGOAT`, dix nombres
  (`LINKS` à `STIGMATA`), `Enemy.tug()`, l'appel `JudgmentChains.divert()` dans
  `Player._on_damaged()`. Le Familier rejoue les chaînes.
- **Les sauvegardes** : `Manual.points_spent()` ne compte plus un identifiant que le manuel ne
  connaît pas ; les points placés dans la Frappe reviennent au livre.

### Les écarts avec la proposition

- **Un coup partagé peut bénir** : c'est un coup sacré, et le sacré bénit par la règle commune
  (`StatusEffects.suffer()`). Il ne critique pas et ne se repartage pas, comme proposé.
- **Le trait frappe tout ce qu'il prend, n'enchaîne que des ennemis** : le mannequin de l'arène
  et les cibles du banc des arbres sont des hurtbox nues, sans mort à écouter. Écrit d'abord
  « n'enchaîne et ne frappe que des ennemis », le banc donnait 0/s au Bouc émissaire.
- **L'Unisson** passe les états que porte l'enchaîné frappé (`StatusEffects.pass_on()`), pas
  ceux du coup : le partage part en différé, et `Hurtbox.damaged` sonne avant que le coup ne
  pose ses états.
- **Le trait a la largeur d'un tir** (6 px, le rayon 3 des `player_bolt`) : il se vise.

### Les tests

Huit dans `test_shapes.gd` (préfixe `test_judgment_chains_`) : le lien et le partage, qui ne
revient pas, et la fin des liens ; les Maillons ; la Rupture ; la Passation, qui garde le
faisceau vivant ; le Resserrement et le Carcan ; le Pilori ; l'Unisson ; le Bouc émissaire et
les Stigmates. Un dans `test_manuals.gd` : les points d'une compétence disparue. Retirés : les
neuf de la Frappe, du Faisceau, de la Croix et de l'anneau du trait.

**Vu aux tests, corrigé** : la Passation pouvait redonner les chaînes **au mort lui-même**,
encore dans l'espace physique pendant l'image de sa mort ; libéré ensuite, il restait enchaîné.
Le mort est écarté, et un enchaîné libéré sans mourir quitte le faisceau à l'image suivante.

La campagne : **1 455 tests sur 1 456** au passage complet. Le dernier, la Rupture, comptait le
coup du trait sur le passant, que le trait frappe désormais (écart 2) : il compte maintenant ce
que la mort ajoute, et les huit tests des chaînes passent seuls.

### Le banc

`docs/ARBRES.md`, Chaînes du jugement : **113/s** au paquet sans arbre, ×2,48 au mieux
(Réquisitoire 5, Ampleur 1, Maillons 3) ; 38,3/s au duel, ×1,60. Le Bouc émissaire ×1,55 au
paquet. **Le banc ne voit pas le partage** : ses cibles sont des hurtbox nues, qui ne
s'enchaînent pas, et une seule compétence y frappe. Solidarité, Rupture, Passation, Unisson et
Stigmates n'y sont jamais pris, faute d'y servir.

### La performance

Banc de combat sur `world/stress_test.tscn`, 300 grunts serrés et immortels, fenêtré, cinq
passages alternés, moyennes de la physique :

| scénario | physique | coups/s |
|---|---|---|
| chaînes nues | 8,8 ms | 7 |
| arbre complet (Maillons 3, Solidarité 2, Unisson, Resserrement, Carcan, Passation 2) | 9,0 ms | 13 |
| Bouc émissaire, Maillons 3 | 9,0 ms | 10 |
| marteau (Carillon 2) en alternance avec les chaînes nues | 10,0 ms | 293 |
| le même avec Maillons 3 et Solidarité 3 : chaque coup du marteau sur un enchaîné en donne cinq | 10,5 ms | 379 |

165 img/s partout, aucun gel. Le partage coûte un demi-milliseconde au pire cas mesuré.

### Ce qui reste

- ~~**la planche des chaînes**~~ — faite, §9 ;
- ~~**les vignettes**~~ et les icônes du marteau et des chaînes — faites, §11 ;
- **l'équilibrage**, en dernier.

## 9. La planche des chaînes

Par `/dessiner-un-effet`, `5-planche-chaines.png` dans `hns-captures-planches-sacre\` : six
partis pris, chacun en trois temps (le trait en vol, un faisceau de trois, le Bouc
émissaire) — des maillons roses en alternance, un chapelet de grains et de croix, un ruban de
lumière noué, du fer béni à éclats, des losanges pointe à pointe, une chaîne lâche qui pend.
**Choisi : les maillons roses.**

En jeu, `Holy.link()` fabrique une pièce — anneau, maillon de chant, anneau de tête — par cap
(`Slash.TURNS`, 32) et par teinte ; `JudgmentChains._links()` les pose un à un tous les
`Holy.LINK_PITCH` px. Les pièces se touchent, et leurs contours font les jointures.

**Vu à la capture, corrigé** : mené jusqu'au centre du corps, le lien **barrait le torse des
enchaînés** ; il s'arrête à `BODY` (8 px) de chaque centre.

**Signalé par l'utilisateur** : « la chaîne disparaît quasiment dès que je la mets ». Le
faisceau vivait ses 4 s — tracé à la capture, ni mort, ni rupture, ni fin anticipée —, mais
**son dessin s'effaçait** : les grunts marchent sur le joueur et finissent à 14 px l'un de
l'autre ; ôté 8 px de chaque bout, il ne restait pas deux pas de maillon, et `_links()` ne
dessinait rien. C'est la correction précédente qui l'avait introduit. Un lien garde désormais
**au moins un anneau** (`JudgmentChains.pieces()`, testé), et la marge aux corps ne prend plus
que `BODY_PART` (30 %) de l'écart entre deux corps serrés.

**Mesuré** (banc headless) : 0,036 ms par pièce la première fois, 0,055 au pire ; relue,
moins d'une microseconde. 96 pièces au plus par teinte.

Captures dans `hns-captures-sacre-jalon48\`, à la suite : 13 et 14 le trait en vol, 15 un
faisceau de trois, 16 le Bouc émissaire. Les captures 10 à 12 montrent le Faisceau, parti
avec la Frappe.

Deux tests de plus : les pièces gardées par cap et par sorte, le trou de l'anneau
(`test_effect_forge.gd`) ; un anneau au moins entre deux corps serrés (`test_shapes.gd`).

**Signalé par l'utilisateur, ensuite** : « Invalid type in function '_release' … (previously
freed) ». La Passation, en différé, pouvait prendre un voisin **tué dans la même image** — par
le même coup, ou par l'éclat de la Rupture : son signal de mort était passé, rien ne l'a délié,
et il a été libéré sous ses chaînes. Quand ce corps était l'ancre, la fin du faisceau tombe en
haut de l'image, avant le ménage, et déliait un corps libéré. `_take()` refuse un mort, et
`_end()` oublie d'abord les corps libérés (`_purge()`). Le test
`test_judgment_chains_survive_a_freed_member` reproduit l'erreur sans la correction.


**Demandé par l'utilisateur** : la part que la chaîne fait partager, sur la fiche. Les deux
enchaînés et les 30 % de base, qui étaient deux constantes à côté des nœuds, sont portés par le
lancer (`Skill.SHAPE_NUMBERS`, `links` et `solidarity`) : la fiche lit « enchaînés : 3 · 30 % partagés » (le
premier touché compris), Maillons et Solidarité ajoutés — sur une ligne : deux sortaient la
fiche du cadre de 3 px (`test_the_sheet_stays_in_frame`)
(`test_the_chains_sheet_shows_what_they_share`).

La campagne : **1 460 tests, tous verts**.

## 10. Le Battage — il n'éclatait jamais, et son éclat ne se voyait pas

L'utilisateur : « pour le marteau béni, j'ai l'impression que le nœud battage ne marche pas (si
il marche, alors ça veut dire qu'on ne voit pas assez bien l'éclat) ». Les deux.

**Il ne marchait pas.** Le Martèlement et le Battage comptaient les coups **d'un même
marteau**. Mesuré sur un vrai marteau, grunts immobiles de 15 à 60 px : **deux coups au plus**
sur un même ennemi — un marteau vit 1,2 s, ne refrappe qu'après 0,5 s, et sa spirale ne passe
sur un ennemi qu'une ou deux fois. Le Battage, au cinquième, n'éclatait jamais ; le test
appelait `_blow()` cinq fois à la main et ne l'a pas vu. Les coups se comptent désormais **par
ennemi, tous les marteaux du lanceur confondus** (`BlessedHammer._count()`), oubliés après
`MARTELLING_FORGET` (1,5 s) sans coup, sur l'horloge de la physique ; le gain du Martèlement
s'arrête à `MARTELLING_MOST` (10) coups, sans quoi une pluie de marteaux montait sans fin.
Textes des deux nœuds refaits (« vos marteaux »). Test en conditions réelles :
`test_hammers_together_reach_the_threshing` — trois marteaux, relancés, sur un grunt immortel.

**On ne le voyait pas.** `Explosion` peignait le feu, la glace et la nécrose ; le sacré tombait
dans l'onde tracée en additif — un anneau rose pâle de 30 px pendant 0,3 s, perdu sur le sol
sous les marteaux. Planche `6-planche-eclat-sacre.png` : l'onde d'avant (pour comparer), une
étoile et un sol tramé, une couronne de grains, une croix pattée qui part sur les axes, des
rayons de gloire, des éclats et un sol, une colonne brève. **Choisi : les rayons de gloire** —
pour tous les souffles sacrés : le Battage, l'Effondrement, la Transfiguration, la Rupture.
`Holy.glory()` les fabrique en `GLORY_FRAMES` (6) temps, une fois par rayon ; l'étoile du
souffle (`EffectForge.flashes()`) tient le cœur.

**Mesuré** : 0,20 ms par temps à 30 px (0,38 au pire), 0,27 à 40, 0,44 à 60, 0,69 à 83 —
une fois par rayon. **Vu à la capture** (`17-battage-rayons.png`, `18-battage-rayons-suite.png`) :
lisible, et fréquent dès trois marteaux sur un ennemi au contact ; deux éclats qui se
chevauchent font un fouillis de rayons sur le joueur, à garder en tête pour l'équilibrage.

**Le banc** (`docs/ARBRES.md`, relevé, rien corrigé — l'équilibrage vient en dernier) : le
Marteau passe de ×16,6 à **×50,0 au duel** et ×18,3 au paquet. Le Martèlement compte enfin ses
dix coups, à +30 % chacun sous trois points, sur tous les marteaux du Carillon : c'est le
premier levier à reprendre à l'équilibrage, avec le Triptyque.

La campagne : **1 462 tests, tous verts**.

## 11. Une vignette par nœud — le manuel sacré

Demandé par l'utilisateur : « occupe-toi des icônes + arbres des skills de ce manuel, fais-le
skill par skill et demande-moi entre chaque skill ». Le tuyau Qwen-Image (jalon 42 ; recette :
`resources/icons/LISEZMOI.md`), palette `holy` (or et blanc, fond prune). Arbres capturés en jeu
dans `Bureau\hns-captures-noeuds-sacre\`.

**Le rôle d'une vignette suit le panneau** (`ManualPanel._role()`) : suite, sinon **majeure dès
qu'une ligne touche un nombre de mécanique** — les Maillons et la Solidarité, posés d'abord en
nœuds de nombres, sortaient en ronds de 24 dans un octogone. Réduits de nouveau à 32 depuis le
même tirage.

**Les Chaînes du jugement** : quinze vignettes, et l'icône de la compétence (une chaîne en biais
et son crochet blanc, graine 4242) — elle portait celle de la Frappe. Trois sujets refaits :
l'**Aspersion** (un goupillon sorti en arrosoir → un bol d'eau bénite qui éclabousse), le
**Pilori** (un banc sous une pierre tombale → un poteau et sa planche à trois trous) et
l'**Unisson** (deux diapasons lus comme des lettres → deux cierges qu'une flamme relie). Arbre en
jeu : `01-arbre-chaines.png`.

**Le Pilier sacré** : quatorze vignettes, et l'icône quitte SDXL (une colonne de lumière qui
s'écrase au sol dans une gerbe d'or, graine 4242). Deux sujets refaits : le **Pilier errant**,
deux fois (une jarre de lumière, puis **une colonne qui sautille, sortie avec des jambes** →
une colonne d'où part une flèche d'or vers une cible), et la **Procession** (un petit porteur
de croix, personnage en bouillie → la croix sur sa hampe et sa bannière, « no person »). Le
**Glas** prend la cloche : les nœuds-cloches du Marteau (Carillon, Tocsin, Bourdon, Branle)
devront trouver d'autres objets. Arbre en jeu : `02-arbre-pilier.png`.

**La Pulsation sacrée** : quatorze vignettes, et l'icône quitte SDXL (trois anneaux d'or autour
d'un cœur blanc, graine 777). Aucun sujet refait. La Colère divine est la vague retenue par une
digue — les ondes qui s'amassent ; l'Antienne, une flèche qui boucle, se lit plus faiblement.
Arbre en jeu : `03-arbre-pulsation.png`.

**La Lumière sacrée** : treize vignettes, et l'icône quitte SDXL (une auréole d'or et de blanc,
graine 777). Un sujet refait : l'**Humilité** (« une couronne renversée » sortait à l'endroit,
le double de l'Apothéose → une couronne tombée sur le flanc, sur une dalle). Deux ressemblances
gardées : le **Zèle** et l'**Épiphanie**, deux étoiles voisines dans l'arbre (la seconde a son
rayon vers le bas), et le chapelet du **Recueillement**, un anneau comme l'icône. Arbre en jeu :
`04-arbre-lumiere.png`.

**Le Marteau béni** : treize vignettes, et l'icône qu'il attendait (un marteau de guerre qui
tourne dans sa traînée, graine 777) — il portait celle de la Frappe, supprimée avec elle
(`holy_strike.png` et ses lignes dans `tools/skill_icons.*`). **La cloche est prise par le
Glas** du Pilier : les nœuds-cloches ont d'autres objets — quatre marteaux en étoile pour le
Carillon, un grand et deux petits pour le Bourdon, un crâne qui lâche un marteau pour le Tocsin,
un pendule pour le Branle. Deux sujets refaits : le **Branle** (trois marteaux décroissants, le
double du Bourdon → un pendule) et, par contrecoup, l'**Aplomb** (un fil à plomb, lu comme une
boule de Noël et devenu le jumeau du pendule → une tête de marteau sur des pierres fendues).
Arbre en jeu : `05-arbre-marteau.png`.

Le manuel compte ainsi **69 vignettes, aucune reprise**, et ses cinq icônes de compétence en
Qwen.

La campagne : **1 462 tests, tous verts**.
