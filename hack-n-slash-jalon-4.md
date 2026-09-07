# Hack'n'slash top-down — jalon 4

Suite de `hack-n-slash-jalon-1.md`, qui reste la référence sur l'architecture et
les conventions, de `hack-n-slash-jalon-2.md` (affixes, progression, objets,
fiche de personnage) et de `hack-n-slash-jalon-3.md` (personnage persistant).
Ce document ne redit pas ce qui y est déjà écrit.

**Décidé le 6 septembre 2026.** Le jalon 3 a rendu le personnage durable. Trois
choses l'empêchent maintenant d'être intéressant : il n'a que deux endroits où
porter ce qu'il ramasse, les ennemis qui le poursuivent s'écrasent contre les
murs, et sa fiche annonce des nombres qu'il ne peut pas interpréter.

---

## 1. Périmètre du jalon 4

**Dedans :**

- **Dix emplacements d'équipement** : arme, main gauche, casque, torse, gants,
  bottes, ceinture, amulette, anneau gauche, anneau droit
- **Une base d'objet par emplacement**, avec son icône forgée et son implicite
- **Un panneau de personnage** : la silhouette animée entourée de ses
  emplacements, le sac en dessous
- **La navigation des ennemis** : ils contournent les murs au lieu de pousser
  dedans
- **Une infobulle par statistique** de la fiche, pour celles dont la valeur ne
  se lit pas toute seule

**Explicitement dehors :** les armes à deux mains (elles demandent de bloquer la
main gauche, donc une règle d'exclusion entre emplacements), les gemmes et les
châsses, les bonus d'ensemble, l'enchantement, l'enchaînement des zones, les
classes et compétences, l'audio.

**Élargissement de la réserve d'affixes : toujours dehors.** Il attend depuis le
jalon 2 et il attendra encore. Dix emplacements tirant dans la réserve actuelle
donneront des objets répétitifs — c'est acceptable pour un jalon dont le sujet
est la **place** qu'on a pour les porter. La passe de contenu qui les rendra
intéressants est un travail de tirage et d'équilibrage, pas de structure, et la
mélanger ici ferait un jalon dont on ne saurait pas dire s'il a réussi.

**Critère de réussite :** porter dix objets sur dix emplacements et voir la
fiche bouger à chaque fois ; survoler n'importe quelle ligne de la fiche et
comprendre à quoi elle sert ; et lâcher un grunt derrière un mur en U, le voir
en sortir et arriver — là où aujourd'hui il pousse contre la pierre jusqu'à ce
qu'on vienne le chercher.

---

## 2. Le principe structurant du jalon

**Une base d'objet dit à quelle famille elle appartient. Le personnage, lui, a
des emplacements.**

Ce n'est pas la même chose, et le code actuel les confond : `ItemBase.slot` vaut
`"weapon"` ou `"chest"`, et `Player.SLOTS` contient exactement ces deux
chaînes-là. Tant qu'il y a une correspondance un pour un, la confusion ne coûte
rien.

Les anneaux la font éclater. Un anneau est de famille `"ring"` et le personnage
a **deux** emplacements d'anneau. Avec la règle actuelle — `equipment[base.slot]`
— le second anneau écraserait le premier, sans que rien ne le signale.

La conséquence dans le code :

- `ItemBase.slot` devient une **famille** (`"ring"`, `"weapon"`, `"offhand"`…) ;
- `Player.SLOTS` devient une liste d'**emplacements** (`"ring_left"`,
  `"ring_right"`…), chacun sachant quelle famille il accepte ;
- `equip(item)` prend l'emplacement en argument quand l'appelant en connaît un
  (le panneau sait sur quel emplacement l'objet a été lâché), et le choisit
  sinon : **le premier emplacement libre de la bonne famille**, à défaut le
  premier de la bonne famille tout court. Un anneau ramassé alors qu'on en porte
  déjà un doit aller au doigt libre, pas remplacer celui qu'on a.

C'est la seule règle de ce jalon qui touche à du code déjà écrit et testé. Le
reste s'ajoute à côté.

---

## 3. Les dix emplacements

| Emplacement | Famille | Ce qu'il apporte, en principe |
|---|---|---|
| `weapon` | `weapon` | les dégâts et la cadence |
| `offhand` | `offhand` | l'armure ou le sort — bouclier, grimoire |
| `helmet` | `helmet` | les PV, une résistance |
| `chest` | `chest` | l'armure, les PV |
| `gloves` | `gloves` | la vitesse d'attaque |
| `boots` | `boots` | la vitesse de déplacement |
| `belt` | `belt` | les PV, la régénération |
| `amulet` | `amulet` | les résistances, le mana |
| `ring_left` | `ring` | au choix — c'est l'emplacement le plus libre |
| `ring_right` | `ring` | idem |

**`chest` et `weapon` gardent leur nom.** Ils sont déjà écrits dans les
sauvegardes des personnages existants ; les renommer en `torse` et `arme` ferait
disparaître le plastron de tous les personnages déjà créés au premier
rechargement. Le nom lisible est déjà séparé (`Player.SLOT_NAMES`), c'est lui
qui se traduit.

### 3.1 Une base par emplacement

Dix bases, une par emplacement, chacune avec :

- son `id` de sauvegarde, qui ne changera plus jamais (jalon 3, §3.3) ;
- son `kind`, qui décide de son dessin dans la forge ;
- son encombrement dans le sac, en cases ;
- son implicite : ce que porte **toute** la famille, sans tirage. C'est lui qui
  dit à quoi sert la base et qui rend une amulette nue préférable à un anneau nu
  quand on cherche du mana.

L'encombrement fait partie de l'équilibrage, pas de la décoration : un plastron
mange six cases, un anneau une seule. C'est ce qui fait qu'on rentre au marchand
avec trois anneaux ou une armure, jamais les deux.

### 3.2 Les icônes

La forge sait dessiner une épée, une baguette et un torse. Il lui manque sept
formes : bouclier, casque, gants, bottes, ceinture, amulette, anneau.

C'est le poste le plus long du jalon, et c'est du dessin par code — voir
`SpriteForge._icon` et `PixelCanvas`. Deux exigences, apprises sur les trois
premières :

- **la silhouette d'abord.** Une icône de 24 pixels se reconnaît à sa forme
  avant sa couleur. Un anneau et une amulette qui se ressemblent en petit sont
  deux objets qu'on confondra dans un sac plein ;
- **la forge reste la source.** Aucun PNG dessiné à la main : ce projet génère
  ses assets, et la galerie (`F4`) est l'endroit où on les règle.

Une arme portée modifie déjà le sprite du personnage (`ActorSprite.set_weapon`).
Les neuf autres emplacements **ne changent pas la silhouette** dans ce jalon :
peindre une armure et un casque sur trente-six images par variante, c'est un
jalon à soi tout seul.

---

## 4. Le panneau de personnage

Le sac devient une fenêtre de personnage : la **silhouette animée au centre**,
ses dix emplacements disposés autour comme sur un corps — casque en haut,
bottes en bas, armes de part et d'autre, anneaux aux deux mains — et la grille
du sac en dessous.

Deux raisons de préférer ça à deux colonnes étiquetées :

- **ça se lit sans étiquette.** On sait où va un casque parce qu'il va sur la
  tête. Avec dix emplacements en liste, on lit dix mots à chaque objet ramassé ;
- **la silhouette est déjà là.** Le personnage a une apparence choisie depuis le
  jalon 3, et c'est le seul endroit du jeu où on la voit en grand.

La contrainte est la place : le cadrage fait 640 × 360, la fiche occupe déjà le
quart gauche, et les deux panneaux doivent pouvoir être ouverts ensemble — c'est
tout l'intérêt d'équiper en regardant ses statistiques changer. Le panneau prend
donc la moitié droite, et **sa hauteur se vérifie par un test**, comme celle de
la fiche : le groupe des attributs ajouté après coup avait déjà fait déborder la
fiche d'une ligne, et personne ne l'avait vu avant la capture.

Ce qui existe déjà et ne doit pas régresser : glisser-déposer et clic-clic, le
clic droit qui équipe et retire, l'objet lâché hors du panneau qui tombe au sol,
l'infobulle d'objet avec sa couleur de rareté.

---

## 5. La navigation des ennemis

### 5.1 Le défaut

Il n'y a pas de navigation. `Grunt.tick` calcule `target.global_position -
global_position`, normalise, ajoute une séparation des voisins au contact, et
appelle `move_and_slide()`. Les murs n'existent que comme surface de glissement.

En terrain ouvert ça se voit à peine. Dans une carte creusée par automate
cellulaire — la nôtre — un ennemi séparé du joueur par une concavité pousse
contre la pierre jusqu'à ce qu'on vienne le chercher. Le caster fait un peu
mieux par accident : il inverse son sens d'orbite quand il touche un mur, ce qui
le décolle mais ne le fait pas contourner.

### 5.2 Un champ de flux, partagé

**Un seul parcours en largeur depuis la case du joueur, sur toute la carte
praticable. Chaque case retient la direction vers laquelle il faut partir pour
se rapprocher.** Un ennemi lit la direction de sa case et l'emploie comme il
employait `to_target.normalized()`.

C'est la solution qui va avec ce projet, pour des raisons qui lui sont propres :

- **le coût ne dépend pas du nombre d'ennemis.** Soixante-dix ennemis lisent le
  même champ ; sept cents aussi. Un A* par ennemi ferait exactement l'inverse —
  et c'est le nombre d'ennemis que la mesure de référence surveille ;
- **l'EnemyManager est déjà le pilote unique.** Le champ se calcule à un endroit
  et se lit dans la boucle qui existe, sans donner à chaque ennemi un état de
  navigation à tenir à jour ;
- **la grille existe déjà** : `MapGenerator.grid`, `is_walkable`, `cell_at`,
  `cell_center`. Le champ n'introduit pas de représentation du monde, il en
  dérive une ;
- **c'est déterministe.** Un parcours en largeur sur une grille donnée dans un
  ordre fixe donne toujours le même champ. C'est la doctrine du projet, et c'est
  ce qui permettra de reproduire un défaut de poursuite à partir d'une graine.

**Ce qu'on y perd, et qu'il faut assumer :** tous les ennemis d'une même case
partent dans la même direction. À soixante-dix, ça se voit — un cortège plutôt
qu'une meute. Deux correctifs, dans cet ordre : la séparation existante, qui les
écarte déjà au contact ; et, si ça ne suffit pas à la lecture, un léger décalage
angulaire propre à chaque ennemi, tiré une fois à sa naissance et non par image.

### 5.3 Quand on le recalcule

Quand le joueur **change de case**, pas à chaque image. Il traverse une case en
une fraction de seconde à 90 de vitesse, mais reste immobile la plupart du temps
en combat.

Le piège est le joueur posé sur une frontière : deux cases alternées à chaque
image donneraient un recalcul complet par image. Il faut donc, en plus, un
**délai minimal entre deux recalculs**, et le champ précédent sert dans
l'intervalle. Un champ vieux de quelques dizaines de millisecondes ne trompe
personne : il pointe vers l'endroit où le joueur était, à une case près.

Le budget : un parcours en largeur sur les 5 700 cases praticables d'une carte
96 × 96, en entiers, sans allocation par case. À mesurer et à écrire dans le
code, comme le coût de `_count_wall_neighbours` — la mesure vaut mieux que
l'intention.

### 5.4 Ce qui reste au pilotage local

Le champ dit **où aller**, pas comment. Restent au niveau de l'ennemi :

- la séparation des voisins, inchangée ;
- l'orbite du caster, qui n'est pas une poursuite : il veut tenir sa distance.
  Le champ lui sert quand il est trop loin ou qu'il n'a pas la ligne de vue ;
  passé ce seuil, il tourne comme aujourd'hui ;
- le recul encaissé, qui doit continuer à pousser contre la direction du champ.

### 5.5 Les scènes sans carte

L'arène de réglage, le banc de stress et la galerie n'ont pas de
`MapGenerator`. Le champ doit donc être **facultatif** : sans lui, l'ennemi
retombe exactement sur le comportement actuel. Ce n'est pas une concession, ces
scènes n'ont pas de murs — mais un champ obligatoire les ferait planter, et ce
sont les scènes dans lesquelles on règle le jeu.

---

## 6. Les infobulles de statistiques

La fiche annonce « armure 40 (44 %) », « esquive 15 (20 %) », « vitesse
d'attaque 104 % ». Un joueur qui découvre le jeu ne peut pas savoir que l'armure
protège proportionnellement plus des petits coups, que les résistances plafonnent
à 75 %, ni laquelle des deux vitesses gouverne son tir.

**Survoler une ligne de la fiche ouvre une infobulle** qui dit trois choses, dans
cet ordre :

1. **à quoi sert la statistique**, en une phrase ;
2. **comment elle se calcule**, quand ce n'est pas évident — les rendements
   décroissants de l'armure, le plafond des résistances, ce que la force dérive ;
3. **ce qu'elle vaut en ce moment**, pour ce personnage-ci. « 40 d'armure, soit
   44 % contre un coup de 10 » en apprend plus que n'importe quelle formule.

Les textes vivent dans **une seule table**, indexée par les mêmes noms de champs
que `StatMod.LABELS`. Et un test vérifie que **chaque statistique affichée par la
fiche a son entrée** : une table indexée par une liste de champs, c'est une
entrée oubliée qui donne une infobulle vide en plein jeu plutôt qu'un échec ici.

Toutes n'en méritent pas. `move_speed` n'a rien à expliquer. Celles qui en ont
besoin : armure, esquive, les cinq résistances, vitesse d'attaque, vitesse
d'incantation, chance et dégâts critiques, les deux régénérations, et les trois
attributs — ceux-là surtout, puisqu'ils ne servent à rien par eux-mêmes et
n'existent que par ce qu'ils dérivent.

Le panneau du sac dessine déjà une infobulle d'objet. À l'implémentation, la
question se posera de partager ce dessin : **deux appelants ne le paient pas**,
et les deux infobulles n'ont pas le même contenu ni la même largeur. Si un
troisième arrive, la question se reposera.

---

## 7. Ordre de construction

Chaque étape se valide avec `tests/run.sh` avant la suivante.

- [x] **1. Emplacements et familles.** Séparer `ItemBase.slot` (la famille) de
      la liste des emplacements du personnage, avec la règle du premier
      emplacement libre. Aucune interface, aucune nouvelle base : uniquement le
      code d'équipement et ses tests, y compris « deux anneaux ne s'écrasent
      pas » et « un personnage sauvegardé avant ce jalon retrouve son plastron ».
- [x] **2. Les dix bases.** Les `.tres`, leurs identifiants, leurs implicites,
      leur encombrement. Le test du catalogue vérifie déjà la présence et
      l'unicité des identifiants ; y ajouter que **chaque emplacement a au moins
      une base**, sinon un emplacement restera vide sans que personne le voie.
- [x] **3. Les icônes.** Sept formes à forger, réglées dans la galerie. C'est du
      dessin : la validation est une capture, pas une assertion.
- [x] **4. Le panneau de personnage.** La silhouette et ses dix emplacements, le
      sac en dessous, les gestes existants préservés. Test de tenue en hauteur,
      et capture réelle avec la fiche ouverte à côté.
- [ ] **5. Le champ de flux.** Le calcul, sa mise à jour, sa lecture par les
      ennemis, le repli quand il n'y a pas de carte. Tests : un ennemi placé
      derrière un mur en U rejoint le joueur ; une case isolée ne fait pas
      boucler le parcours ; deux calculs sur la même carte et la même case
      donnent le même champ. Et une remesure du banc de stress.
- [ ] **6. Les infobulles.** La table de textes, le survol, le test de
      couverture des champs, une capture.

### Ce que l'étape 4 a changé au plan

- **La fenêtre est plus large que le sac**, et c'est la grille du personnage
  qui fixe sa largeur : trois colonnes larges séparées par une gouttière, où
  logent les deux bagues. Le sac, plus étroit, est centré dedans — d'où un
  `_grid_left()` que le dessin **et** le calcul de la case sous le curseur
  partagent, sinon on cliquerait à côté de ce qu'on voit.
- **Les emplacements ont la forme de ce qu'ils reçoivent**, et non une taille
  unique : l'arme trois cases de haut, le plastron deux sur trois, la bague une
  colonne étroite — la même grille que le sac, donc la place qu'un objet prend
  en haut est celle qu'il prendra en bas. Une grille de carrés identiques
  donnait dix cases interchangeables où plus rien n'annonçait ce qui allait où.
- **Le fond d'un emplacement porte la couleur de rareté**, très assombrie.
  C'est l'information du cadre d'un objet rangé et du halo au sol, lisible ici
  sans survoler, d'un bout à l'autre de la fenêtre.
- **Un emplacement vide montre la silhouette de ce qu'il attend**, peinte
  presque effacée, au lieu de son nom. La forge sait déjà dessiner une botte et
  un anneau ; « BAGUE G. » ne tenait pas dans sa case, et deux libellés tronqués
  au même endroit annonçaient deux emplacements qu'on ne distinguait plus.
- **La silhouette est dessinée, pas montée en nœud.** Un `AnimatedSprite2D`
  enfant se peint au-dessus du Control, donc au-dessus de l'objet qu'on traîne à
  la souris : il aurait disparu derrière elle en traversant le panneau. Le
  panneau lit les planches de la forge et peint l'image lui-même, en la
  choisissant sur l'horloge — c'est le « pilote unique » appliqué au dessin.
- **Les emplacements sont carrés et plus petits qu'un plastron** (40 pixels
  contre 41 × 62). Dix emplacements à la taille du plus gros objet équipable ne
  tiennent pas dans un cadrage de 360 pixels de haut. L'icône est donc bornée au
  rectangle qui l'accueille — dans le sac les deux coïncident, l'ancien
  comportement est intact.
- **La disposition est une table**, `InventoryPanel.DOLL` : un emplacement, une
  case. Trois tests la gardent — chaque emplacement a sa case, deux
  emplacements n'en partagent pas une, et aucun ne tombe sur la silhouette.
- **Le panneau occupe désormais presque toute la hauteur à droite**, comme la
  fiche à gauche. C'est ce que demande une fenêtre de personnage ; les deux
  s'ouvrent toujours ensemble, et le combat reste visible entre les deux.

### Ce que les étapes 2 et 3 ont changé au plan

- **Les affixes existants visent enfin les dix familles.** Ce n'est pas
  l'élargissement de la réserve, qui reste hors périmètre : aucun affixe n'a été
  ajouté. Les dix qui existaient ne visaient que `weapon` et `chest`, donc sept
  familles sur dix n'auraient jamais lâché que des objets blancs — un
  emplacement qui existe mais ne récompense jamais rien. `preste` (vitesse) est
  passé du torse aux bottes, où il a un sens ; les autres se sont ouverts aux
  familles qui leur vont. Un test exige au moins deux affixes possibles par
  base.
- **Le taux de chute n'a pas bougé.** Le nombre d'objets par mise à mort est le
  même ; c'est la variété qui augmente. À remesurer en jouant : si un objet
  précis se fait trop attendre, c'est `LootTable.BASE_CHANCE` qu'on relève,
  comme le prévoit la section 8.
- **`SpriteForge.GEAR` sert d'aiguillage** entre pièce d'équipement et arme, et
  un test vérifie que chaque base du catalogue peint au moins un pixel. Une
  icône vide ne se découvre autrement qu'en ramassant l'objet.

### Ce que l'étape 1 a changé au plan

- **Deux champs renommés, pas un.** `ItemBase.slot` devient `ItemBase.family`,
  comme prévu — mais `ItemAffix.slots` désignait lui aussi des familles et
  filtrait sur `base.slot`. Renommer l'un sans l'autre aurait laissé le mot
  « slot » vouloir dire deux choses selon le fichier. Les `.tres` des deux
  familles ont suivi.
- **`Player.SLOTS` et `Player.SLOT_NAMES` ont disparu** au profit de
  `core/equipment_slots.gd`. Les emplacements ne sont pas une affaire d'acteur :
  la sauvegarde et le panneau en ont besoin autant que lui.
- **Le panneau montre les dix en deux rangées de cinq**, à titre provisoire.
  `_slot_rect` est l'unique endroit qui décide où se trouve un emplacement :
  c'est par là que la fenêtre de personnage arrivera à l'étape 4.
- **« ANNEAU G. » est devenu « BAGUE G. »** : les deux libellés en ANNEAU
  débordaient de leur case et se faisaient tronquer au même endroit, donnant
  deux emplacements qui s'annonçaient pareil.

---

## 8. Ce qui peut mal tourner

- **Confondre l'emplacement et la famille.** C'est le piège central du jalon.
  Son symptôme : le second anneau qu'on équipe fait disparaître le premier —
  silencieusement, puisque rien dans le code ne dit qu'un emplacement était déjà
  occupé.
- **Renommer un emplacement existant.** `chest` et `weapon` sont écrits dans les
  sauvegardes. Un renommage est une perte d'objet pour tout le monde, et elle ne
  se verra qu'au prochain chargement d'un vieux personnage.
- **Le champ de flux recalculé trop souvent.** Le joueur immobile sur une
  frontière de cases suffit à le déclencher chaque image. Le délai minimal n'est
  pas une optimisation, c'est ce qui empêche le pire cas.
- **Le champ de flux qui devient obligatoire.** L'arène, le banc de stress et
  les tests d'intégration créent des ennemis sans carte. Le repli doit être écrit
  dès la première ligne, pas ajouté quand une scène plante.
- **Les corps ne sont pas dans la grille.** Le champ contourne les murs, pas les
  autres ennemis ni le joueur. Un couloir bouché par trois grunts reste un
  couloir praticable pour le champ ; c'est la séparation locale qui doit s'en
  charger. Ne pas tenter de mettre les corps mobiles dans le champ : il faudrait
  le recalculer à chaque image.
- **Un ennemi hors de la carte.** Le culling ne tick pas les ennemis lointains,
  mais un ennemi repoussé dans un mur lirait une case non praticable, donc une
  direction absente. Ce cas doit rendre une direction vers la case praticable la
  plus proche, jamais un vecteur nul qui le figerait là définitivement.
- **Dix emplacements dans 640 × 360.** Le panneau va être serré. La tentation
  sera de rogner sur la taille des icônes jusqu'à ce qu'on ne les distingue plus
  — c'est exactement ce que la capture doit trancher.
- **Une infobulle qui masque ce qu'on survole.** Elle doit s'ouvrir du côté où
  il y a de la place, comme celle des objets, et jamais recouvrir la ligne qui
  l'a déclenchée.
- **Sept bases ajoutées à la réserve de butin sans toucher aux affixes.** Le
  tirage va s'étaler sur dix familles au lieu de trois : chaque objet précis
  devient trois fois plus rare. Si le rythme de récompense s'effondre, c'est le
  taux de chute qu'il faut relever dans ce jalon — pas la réserve d'affixes,
  qui reste hors périmètre.
