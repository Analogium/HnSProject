# Hack'n'slash top-down — jalon 6

Suite de `hack-n-slash-jalon-1.md`, qui reste la référence sur l'architecture et
les conventions, de `hack-n-slash-jalon-2.md` (affixes, progression, objets), de
`hack-n-slash-jalon-3.md` (personnage persistant), de `hack-n-slash-jalon-4.md`
(dix emplacements, navigation, infobulles) et de `hack-n-slash-jalon-5.md`
(niveau d'objet, tiers, niveau de zone). Ce document ne redit pas ce qui y est
déjà écrit, et `docs/ARCHITECTURE.md` reste le seul endroit qui décrit l'état
courant.

**Décidé le 9 septembre 2026.** Le jalon 5 a donné une raison de descendre : ce
qu'on ramasse plus bas vaut mieux. Mais on descend toujours **de la même
façon** — un coup d'épée et un tir, les deux touches du jalon 1. Cent heures de
jeu ne changeraient rien à ce que le personnage *fait* ; elles changent seulement
les nombres avec lesquels il le fait. Il manque au jeu la seconde moitié de la
promesse du genre : que **ce qu'on trouve change la façon de jouer**, et pas
seulement le barème.

---

## 1. Périmètre du jalon 6

**Dedans :**

- **Le manuel** : un objet du sac qui porte un archétype, sa propre expérience,
  et les points qu'on y a placés
- **Le râtelier de trois** : une fenêtre nouvelle, où l'on équipe des manuels, et
  le seul endroit depuis lequel on investit
- **La page d'un manuel** : sa barre d'expérience, ses cases, et le point qu'on
  pose dans une case
- **La compétence** : une fiche — nature, coût, recharge, dégâts par niveau,
  attribut d'échelle — et son lancement
- **L'échelle par attribut** : « +4 % par point d'intelligence », lue sur la
  fiche du personnage, objets compris
- **La barre de cinq**, en bas à droite, ses entrées, et le menu qui propose ce
  qu'on peut y poser
- **Un archétype complet et jouable** : « Maître de la foudre », quatre
  compétences
- **Le coup d'épée et le tir versés dans le système** : ils deviennent deux
  compétences comme les autres, sans changer de valeur
- **La chute garantie** d'un manuel aux pieds d'un personnage neuf
- **La sauvegarde en version 3**, avec la lecture des versions 1 et 2

**Explicitement dehors :** les affixes sur les manuels, les manuels uniques, le
remboursement des points placés, les prérequis entre cases, les compétences
non offensives (auras, soins, déplacements), les compétences déclenchées, les
supports qui modifient une compétence voisine, le partage d'une même compétence
entre deux archétypes, plus d'un archétype, l'audio, les animations dédiées à
chaque sort, et l'équilibrage fin des quatre compétences.

**Les manuels rares méritent leur ligne.** Un archétype aura un jour des versions
plus rares, avec des cases de plus. La forme est prévue — un manuel est une base
d'objet, donc il a déjà une lignée et un palier, exactement comme l'épée et
l'épée large — mais **on n'en écrit qu'un dans ce jalon**. Écrire la deuxième
version avant d'avoir joué la première, c'est équilibrer un contenu qu'on n'a pas
encore trouvé amusant.

**Critère de réussite :** créer un personnage neuf, ramasser le manuel tombé à
ses pieds, le poser au râtelier, tuer jusqu'à ce qu'il monte d'un niveau, placer
trois points dans « Éclair vif », l'assigner à la touche `A`, le lancer et tuer
avec ; placer un point d'intelligence et voir le nombre de l'infobulle monter du
même coup ; sortir le manuel du râtelier, le remettre, retrouver ses trois
points ; fermer le jeu, le relancer, tout retrouver.

---

## 2. Le principe structurant : la compétence n'appartient pas au personnage

C'est la seule phrase du jalon qu'il faut garder en tête, et elle décide de tout
le reste.

**Ce que le personnage sait faire n'est pas écrit sur lui. C'est écrit dans les
manuels qu'il porte.** Le personnage ne retient que des *références* : trois
manuels au râtelier, cinq cases de barre qui pointent vers une compétence d'un de
ces manuels. Rien d'autre.

La chaîne n'a donc qu'un sens, et il ne s'inverse jamais :

```
archétype (.tres partagé)  →  ce qu'un manuel peut contenir
   exemplaire (Item + Manuel)  →  ce que CE manuel-là a appris
      râtelier (3)  →  ce qui est actif
         barre (5)  →  ce qui est à portée de doigt
```

Trois conséquences, et chacune est un test :

- **un manuel sorti du sac emporte sa progression avec lui.** Les points ne sont
  pas « les points du personnage dans la foudre », ce sont les points *de ce
  manuel*. Le jour où on les échangera entre personnages, rien ne sera à
  réécrire ;
- **le personnage ne gagne rien à connaître une compétence.** `Player` demande à
  la barre ce qu'il faut lancer ; il ne nomme jamais un sort, ne teste jamais un
  identifiant, et n'a pas de champ « éclair ». Ajouter une compétence ne le
  touche pas ;
- **une compétence retirée du projet ne casse pas une sauvegarde.** Le fichier ne
  contient que des identifiants ; celui qui ne se retrouve plus est ignoré, comme
  l'est déjà une base d'objet disparue.

C'est aussi ce qui interdit le raccourci qui viendra : poser `degats_eclair` sur
`CharacterStats` parce que « c'est là que vivent les nombres ». La fiche décrit un
corps ; une compétence décrit un geste. Les mélanger obligerait à ajouter un
champ à `CharacterStats` par sort du jeu.

---

## 3. Le manuel, qui est trois choses

Le mot « manuel » désigne trois objets différents, et les confondre est la
première façon de perdre une semaine.

### 3.1 L'archétype, l'exemplaire, l'état

| Ce que c'est | Où ça vit | Combien |
|---|---|---|
| **L'archétype** — le contenu du livre : ses cases, leurs compétences, leur disposition | `resources/manuels/<id>.tres`, partagé | un par version d'archétype |
| **L'exemplaire** — l'objet ramassé, avec sa base et son niveau d'objet | `Item`, dans le sac | un par manuel ramassé |
| **L'état** — l'expérience du livre et les points placés dedans | `Manuel`, porté par l'`Item` | un par exemplaire |

**L'archétype est un `.tres` du disque, donc on n'y écrit jamais** (invariant 2).
C'est le même piège qu'au jalon 5 avec la fiche d'un ennemi mis à l'échelle, en
pire : écrire les points investis sur l'archétype partagé donnerait à *tous* les
manuels de foudre du jeu — et de toutes les parties suivantes de la session — les
points du dernier livre ouvert. L'éditeur peut ensuite graver le résultat sur le
disque.

### 3.2 Pourquoi un manuel est un objet du sac

Un manuel doit tomber au sol, briller, se ramasser en marchant dessus, prendre de
la place dans le sac, s'y déplacer, et montrer une infobulle. Tout ça existe
depuis le jalon 2 et a été éprouvé depuis : `GroundItem`, `Inventory`,
`InventoryPanel`. Un manuel qui ne serait pas un `Item` demanderait d'écrire une
deuxième fois la chute, le ramassage, le rangement en rectangles et l'infobulle —
quatre systèmes, pour un objet qui se comporte exactement comme un objet.

Il est donc une **base d'objet** de plus, avec `family = "manual"`, et la seule
chose qui le distingue est un champ nouveau sur `ItemBase` :

```gdscript
## L'archétype que cette base ouvre, ou null. Non nul si et seulement si la
## famille est « manual » : c'est la base qui dit ce qu'elle est, comme elle dit
## déjà son implicite.
@export var manuel: ManuelArchetype
```

Un champ optionnel sur `ItemBase` plutôt qu'un second catalogue tenu en
parallèle : deux listes qui doivent se correspondre finissent par diverger, et
c'est le genre de divergence qui ne se voit qu'en ramassant l'objet.

**Ce que ce choix coûte, et il faut l'assumer :** la rareté d'un manuel ne se
déduit pas du nombre de ses affixes, puisqu'il n'en a pas. `Item.rarity()`
interroge donc le manuel quand il y en a un, et le nombre d'affixes sinon. Deux
branches dans **une seule fonction** — c'est encore une règle à un seul endroit,
et le jour où la deuxième branche se recopiera ailleurs, la rareté commencera à
mentir quelque part.

Un manuel ne s'équipe pas sur la silhouette : `family = "manual"` n'est pas dans
`EquipmentSlots.SLOTS`, donc `free_for()` rend une chaîne vide et `equip()` rend
l'objet intact. Le râtelier est ailleurs, et c'est voulu — voir §6.

### 3.3 L'expérience du manuel

**Un manuel ne monte que depuis le râtelier.** Celui qui dort dans le sac
n'apprend rien : c'est ce qui donne son poids au choix des trois, et c'est aussi
ce qui rend lisible le retour du joueur — la page qu'on regarde est celle qui
bouge.

**Chaque manuel du râtelier reçoit l'expérience entière, non divisée.** Diviser
par trois punirait deux fois : le choix est *déjà* dans les trois emplacements,
puisqu'on en possédera davantage. Un deuxième manuel doit être une ouverture, pas
un handicap.

**Ce n'est pas une deuxième source d'expérience pour le personnage.** La mort d'un
ennemi rapporte au personnage, comme avant, **et** aux manuels équipés. Les deux
barres partent de la même mort mais ne se parlent pas : brancher l'une sur
l'autre — « le manuel monte quand le personnage monte » — ferait disparaître la
seule décision que le râtelier apporte.

La courbe, elle, est la même fonction que celle du personnage, avec d'autres
constantes. `Player._needed_for()` calcule déjà `base × niveau^puissance` ;
écrire une deuxième exponentielle à côté ferait deux courbes qu'on croirait
identiques et qui divergeraient au premier réglage. Elle sort donc dans une
fonction que les deux appellent.

**Un niveau de manuel donne un point de manuel.** Un seul, comme le niveau de
personnage donne trois points d'attribut : la progression doit se compter sur les
doigts, sinon le joueur ne sait pas ce qu'un niveau vaut.

### 3.4 Ce que la sauvegarde retient

Le format passe en **version 3**, et `VERSIONS_LUES` devient `[1, 2, 3]`. Un
objet du sac gagne un champ facultatif :

```json
{ "base": "manuel_foudre", "niveau": 12,
  "manuel": { "exp": 340, "points": { "eclair_vif": 3, "arc_foudroyant": 1 } } }
```

Le râtelier et la barre s'écrivent à côté du sac :

```json
"ratelier": [0, 4, null],
"barre": ["attaque", "tir", "eclair_vif", null, null]
```

**Un manuel posé au râtelier quitte le sac**, comme un plastron qu'on enfile, et
il est donc écrit là et nulle part ailleurs. Écrire le manuel deux fois — une
fois dans le sac, une fois au râtelier — créerait deux vérités sur ses points, et
le rechargement en choisirait une au hasard.

**La barre retient des identifiants de compétences.** Ils partent donc sur le
disque, et l'invariant 1 s'applique mot pour mot : `eclair_vif` ne se renomme
jamais. Le nom lisible est à côté et se change librement.

Ce qu'une version 2 devient en version 3 : un sac dont aucun objet n'est un
manuel, un râtelier vide, une barre où seules l'attaque et le tir sont posées —
c'est-à-dire exactement le jeu d'avant. Le personnage n'a pas reçu son manuel de
départ, et le recevra au premier pas (§8).

---

## 4. La page du manuel : des cases, pas un arbre

### 4.1 La forme

Le dessin est net : une **barre d'expérience en haut**, et des **carrés posés
librement** sur la page, sans un trait entre eux. C'est la forme qu'on écrit.

Chaque carré est une compétence, et une compétence est ouverte par le **niveau du
manuel**, pas par sa voisine. Investir demande deux choses : que le manuel ait
atteint le niveau que la case exige, et qu'il reste un point à placer.

### 4.2 Pourquoi pas de prérequis entre les cases

Un arbre paraît plus riche et coûte beaucoup avant de rendre quoi que ce soit :
il faut dessiner les liens, prouver qu'aucun nœud n'est inatteignable, décider ce
qu'il advient d'un point placé en aval quand on retire celui d'amont — et rien de
tout ça n'ajoute une décision tant qu'il n'y a que quatre compétences. Avec quatre
cases et cinq points, **la rareté des points est déjà le choix**.

La disposition libre reste dans le `.tres` : chaque case porte sa position sur la
page. Le jour où des traits apparaîtront, ils relieront des cases déjà placées, et
la page ne sera pas à redessiner.

### 4.3 Le point placé ne se reprend pas

Comme les points d'attribut, et pour la même raison écrite au jalon 3 : une
répartition qu'on peut défaire n'est plus un choix, c'est un réglage — et rien
n'empêcherait de refaire son manuel avant chaque paquet d'ennemis. Le
remboursement est explicitement hors jalon ; s'il arrive un jour, ce sera par un
objet qu'on ramasse, pas par un bouton.

### 4.4 On n'investit que depuis le râtelier

La page ne s'ouvre pas depuis le sac. C'est une règle de jeu et non une commodité
d'interface : équiper un manuel est l'engagement, et l'engagement doit précéder
l'investissement. Un livre feuilleté dans le sac permettrait de tout monter sans
jamais rien choisir.

---

## 5. La compétence

### 5.1 La fiche

Une `Competence` est une `Resource`, un fichier par compétence, dans
`resources/competences/`.

| Champ | Ce qu'il décide |
|---|---|
| `id` | **Définitif** : il part dans les sauvegardes (invariant 1) |
| `nom` | Ce que le joueur lit ; se change librement |
| `nature` | Un `DamageType.Kind` — la foudre pour cet archétype |
| `cout_en_mana` | 0 pour un coup gratuit, comme l'épée |
| `recharge` | En secondes, avant la vitesse d'incantation |
| `degats_par_point` | La courbe : un nombre par point placé, du premier au dernier |
| `stat_de_base` | Le champ de la fiche qui s'ajoute — `attack_damage` ou `spell_damage` |
| `attribut` | Celui qui la fait monter : `intelligence` pour la foudre |
| `pourcentage_par_point` | 4.0 pour « +4 % par point d'intelligence » |
| `niveau_de_manuel_requis` | À partir de quand la case accepte son premier point |
| `case` | Sa position sur la page |

`degats_par_point` est une **table écrite à la main** et non une formule, pour la
raison qui a fait choisir des tiers écrits au jalon 5 : une courbe calculée oblige
à relire du code pour savoir ce que vaut le troisième point, et interdit de
donner un bond franc au dernier.

### 5.2 La formule, qui n'existe qu'une fois

```
dégâts = (degats_par_point[points - 1] + fiche[stat_de_base])
         × (1 + pourcentage_par_point / 100 × fiche[attribut])
```

Trois décisions sont dedans, et chacune a une raison :

**L'attribut est lu sur la fiche finale, objets compris.** Pas seulement les
points placés à la main. C'est ce qui fait qu'un anneau « +12 intelligence »
ramassé en zone 40 change une compétence — et donc que les jalons 4 et 5
nourrissent celui-ci au lieu de vivre à côté.

**La statistique de la fiche s'ajoute à plat, avant l'échelle.** C'est ce qui
garde vivants les affixes « dégâts de sort » du jalon 5 et l'implicite du
grimoire : sans ce terme, la moitié de la réserve d'affixes deviendrait morte le
jour de la sortie du jalon 6.

**Et c'est ce qui permet de verser l'épée et le tir dans le système sans changer
une valeur** : le coup de base est une compétence à `degats_par_point = [0]` et
`stat_de_base = attack_damage` ; le tir est la même chose avec `spell_damage`.
Ni l'un ni l'autre ne nomme d'attribut — la force et l'intelligence nourrissent
déjà `attack_damage` et la réserve dans `apply_attributes()`, et les compter ici
les paierait une seconde fois. Ils sortent exactement les nombres
d'aujourd'hui — le test le vérifie au dixième près, **avant le coup critique** :
celui-ci reste où il est, dans `DamageInfo.roll()`, et une compétence ne le
retire ni ne le double.

La formule vit dans **une seule fonction**, `Competence.degats(points, stats)`,
appelée par le lancement *et* par l'infobulle. C'est la leçon de l'étape 7 du
jalon 5, où `StatMod.value_label()` a dû être extraite pour que la bulle n'annonce
pas une valeur hors de sa propre fourchette : deux calculs séparés finissent par
diverger d'un arrondi, et c'est l'affichage qui passe pour un menteur.

### 5.3 Le lancement

Une compétence ne connaît ni le joueur ni la scène. C'est le joueur qui lance,
avec ce que la compétence décrit — et le point de passage reste unique :
`Projectile.spawn()` pour ce qui vole, `Hurtbox.take_damage()` pour ce qui touche.

**Rien ne naît depuis un rappel de collision** (invariant 4). Une compétence
lancée depuis l'impact d'une autre — ce que le jalon suivant voudra — passera par
`call_deferred`, comme `GroundItem.spawn()` et `Player._swing()`.

---

## 6. Le râtelier de trois

Une fenêtre nouvelle, ouverte par `M`, refermée par `M` ou `Échap` comme les
autres. Elle montre trois emplacements ; un clic sur un manuel posé ouvre sa
page.

**Trois, et pas plus, parce que c'est un choix.** Le nombre n'est pas définitif —
il vivra sur une constante, pas dans trois lignes d'interface — mais il ne doit
jamais devenir « autant qu'on en ramasse », sinon le râtelier n'est plus qu'un
rangement.

**Sortir un manuel du râtelier vide les cases de la barre qui pointaient vers ses
compétences.** L'alternative — garder la case grisée — laisse à l'écran un sort
qu'on ne peut pas lancer, et le joueur découvre le trou au pire moment. Les points
du manuel, eux, ne bougent pas : c'est toute la promesse du §2.

---

## 7. La barre de cinq

### 7.1 Où elle est, et ce qu'elle recouvre

En bas à droite, permanente. **Et c'est un problème de place à traiter d'entrée**,
pas à découvrir sur une capture : le viewport logique fait 640 × 360
(invariant 6), et le panneau du sac est ancré exactement dans ce coin — c'est
même écrit dans le HUD, dont les jauges ont été centrées pour ne pas passer
dessous.

La décision : **la barre garde le coin, et le sac remonte de sa hauteur.** Un
élément permanent ne doit pas disparaître derrière une fenêtre qu'on ouvre ; et
le sac, lui, a la place de reculer. C'est une capture qui tranchera si les deux
respirent — aucune assertion ne voit un panneau passer sous un autre.

### 7.2 Les entrées

Les deux premières cases gardent les **gestes** d'aujourd'hui : clic gauche et
clic droit. Les trois autres prennent `A`, `E` et `R` — à portée des doigts de
`ZQSD`, et sans toucher aux chiffres, qui seront des potions.

**Les cinq actions se nomment `competence_1` à `competence_5`, et les deux
anciennes sont renommées.** Garder `attack` sur une case qui peut porter
n'importe quel sort donnerait un nom qui ment : le premier emplacement lancera
l'éclair le jour où le joueur l'y met. Le renommage est bon marché — les deux
actions ne sont lues qu'à **un seul endroit**, `Player._physics_process`, et
`Settings` n'écrit aucun remappage de touches sur le disque, donc rien d'ancien
n'y survit. Attention en cherchant : `"attack"` apparaît aussi dans `art/`, où
c'est le nom d'une **animation** et non d'une action ; celui-là ne bouge pas.

Les cinq entrées passent par le **même sondage** que les deux d'aujourd'hui, dans
`_physics_process`, et sous la même garde `Game.ui_grabs_input`. Sans elle, le
clic qui choisit une compétence dans le menu d'assignation la lancerait aussi.

### 7.3 Le menu d'assignation

Un clic sur une case ouvre la liste de ce qu'on peut y poser : les compétences
des trois manuels du râtelier qui ont au moins un point, plus le coup de base et
le tir. Une compétence déjà posée ailleurs se déplace au lieu de se dédoubler —
deux cases qui lancent la même chose sont deux touches perdues.

---

## 8. Le premier manuel

Un personnage neuf n'a rien, et un jeu qui demande d'aller chercher son premier
manuel dans le butin apprendrait sa mécanique centrale par le hasard.

**Un manuel de foudre tombe donc aux pieds du personnage à son premier pas dans
une zone**, au sol et non dans le sac : c'est le geste de ramassage qu'on veut
enseigner, et un objet qui brille par terre le dit mieux qu'une ligne d'aide.

Le drapeau qui dit que c'est déjà fait vit dans la sauvegarde
(`manuel_offert`, version 3). Il n'est pas déduit de « le sac contient un
manuel » : un joueur qui jette le sien en recevrait un second, et le manuel de
départ deviendrait une monnaie.

---

## 9. Ordre de construction

Chaque étape se valide avec `tests/run.sh` avant la suivante. Les quatre
premières sont invisibles à l'écran ; les trois dernières sont l'interface.

- [x] **1. La compétence, seule.** `Competence`, la table `degats_par_point`, la
      formule du §5.2, et les deux fiches qui remplacent le coup d'épée et le
      tir. Aucun manuel, aucune interface : le joueur lance encore par ses deux
      touches, mais les nombres viennent de la nouvelle chaîne. Tests : le coup
      de base et le tir rendent **exactement** les dégâts d'avant ; la formule
      monte avec l'attribut lu sur la fiche, objets compris ; une compétence à
      zéro point ne rend rien.
- [x] **2. Le manuel comme objet.** `ManuelArchetype`, `Manuel`, le champ
      `manuel` sur `ItemBase`, la base `manuel_foudre`, son `kind` et son icône
      dans la forge, la rareté qui passe par le manuel, la chute. Tests : un
      manuel ramassé tient dans le sac et ne s'équipe sur aucun emplacement ;
      **deux manuels ramassés ont des points indépendants** — c'est le test qui
      attrape l'écriture dans le `.tres` partagé ; l'icône peint au moins un
      pixel.
- [x] **3. La sauvegarde en version 3.** Le manuel dans le sac, le râtelier, la
      barre, le drapeau du manuel offert, et la lecture des versions 1 et 2.
      **Écrite avant toute interface**, comme au jalon 5 : c'est la faute la plus
      coûteuse et elle ne se voit qu'au lancement suivant. Tests : un fichier de
      version 2 se recharge entier ; un aller-retour conserve les points de
      chaque manuel ; une compétence retirée du projet ne rend pas le fichier
      illisible.
- [x] **4. L'expérience et les points.** La courbe partagée avec le personnage,
      l'expérience versée aux seuls manuels du râtelier, le point par niveau,
      l'investissement et son refus quand le niveau ne suffit pas. Tests : un
      manuel dans le sac n'apprend rien ; trois manuels au râtelier reçoivent la
      même expérience ; le personnage gagne exactement ce qu'il gagnait avant ;
      un point ne se place pas deux fois ni au-delà du maximum d'une case.
- [x] **5. Le râtelier et sa fenêtre.** Trois emplacements, `M`, le glisser
      depuis le sac, et la page d'un manuel — barre d'expérience, cases, points.
      Captures : le râtelier avec trois manuels, la page avec une case pleine,
      une case ouverte et une case verrouillée — c'est la capture qui dit si les
      trois états se distinguent.
- [x] **6. La barre de cinq.** La place reprise sur le sac, les cinq actions —
      trois nouvelles et deux renommées — le menu d'assignation, le vidage des cases quand un manuel
      quitte le râtelier. Tests : une case pointant sur un manuel retiré se
      vide ; la même compétence ne tient pas deux cases ; un clic dans le menu ne
      lance rien. Capture du bas de l'écran, sac ouvert et sac fermé.
- [x] **7. Les quatre compétences de la foudre.** Le contenu, ses dégâts, ses
      natures, ses recharges — et le passage complet du critère de réussite, joué
      en entier. Tests : chaque compétence de l'archétype vise une statistique et
      un attribut réels ; e2e — un personnage neuf reçoit son manuel, l'équipe,
      monte, investit, assigne, lance, et retrouve tout après un aller-retour sur
      le disque. Remesure du banc de stress si une compétence touche la boucle de
      tick.

### Ce que les étapes 5 à 7 ont changé au plan

**Le râtelier et la page tiennent dans une seule fenêtre.** Le dessin du jalon
montrait la page seule ; y poser les trois dos au-dessus supprime toute
navigation — ouvrir un livre, c'est cliquer sur son dos, et l'on voit du même
coup ce qu'on étudie et ce qu'on n'étudie pas.

**Un manuel se met à l'étude au clic droit depuis le sac**, et non en le
glissant. Le glisser entre deux panneaux est une machinerie à lui seul ; le clic
droit est déjà, depuis le jalon 4, le geste « mets ça où ça va », et `_wear()`
n'avait qu'une ligne à apprendre.

**Une case ne peut pas porter son nom.** À trente-quatre pixels, deux noms
tronqués annoncent la même chose : la case porte son compte — « 3/5 » — ou son
exigence quand elle est verrouillée — « niv. 8 » — et une ligne au bas de la page
décrit celle qu'on survole. Le « 0/5 » a été écarté pour une case verrouillée :
il laisse croire qu'on a le droit de l'ouvrir.

**La capture a tranché trois fois**, et deux de ces trois ne se voyaient dans
aucune assertion : l'icône du manuel (trois dessins avant qu'elle se lise), la
fiche du bas qui touchait la ligne d'aide, et le compteur d'expérience du HUD
qui passait derrière le libellé de la cinquième touche.

**Les touches sont bien `A`, `E`, `R`, mais il a fallu deux essais.** Le jeu lie
des **positions** de touches et non des lettres — c'est ce qui fait tomber ZQSD
sous les doigts d'un clavier français comme WASD sous ceux d'un clavier
américain. Lier « la position du A américain » donne donc la touche **Q** d'un
clavier français, et la barre affichait « A » : elle annonçait une touche que le
joueur ne pouvait pas trouver. Les trois cases prennent maintenant les positions
qui **portent** A, E et R en français, et le libellé est retraduit dans la
disposition du joueur par `DisplayServer.keyboard_get_keycode_from_physical()`.
`E` a donc quitté la deuxième case, où elle doublait le clic droit.

**Un panneau ne répond que des clics tombés sur lui.** Le sac consommait tout
clic dès qu'il était ouvert, y compris au-dehors : la fiche de personnage et la
page d'un manuel devenaient sourdes tant qu'il était à l'écran, sans que rien ne
le dise. Les trois panneaux qui lisent l'entrée brute portent désormais la même
règle nommée, `_possede_le_clic()`, avec deux exceptions assumées — l'objet tenu
à la main possède le geste jusqu'au lâcher, y compris hors du sac, et le menu de
la barre est modal tant qu'il est ouvert.

**Le compte d'expérience a fait les deux bords avant de trouver sa place.** À
droite il tombait derrière la barre de compétences, à gauche derrière la fiche de
personnage : ce sont les deux seules fenêtres qui descendent jusqu'en bas. Il est
au centre, dans la bande que rien n'occupe — la même raison qui y avait mis les
jauges au jalon 4.

**La cadence est un choix, pas un nombre.** `Competence.cadence` vaut `ARME` — et
l'intervalle vient alors de la fiche, `attack_cooldown` divisé par
`attack_speed`, donc une arme rapide accélère le geste — ou `INCANTATION`, et
c'est la `recharge` du sort divisée par `cast_speed`. C'est la question que
l'étape 1 avait laissée ouverte, et elle se répond ici parce que cinq cadences
doivent enfin coexister.

**La forme d'un sort tient en deux nombres** : combien de projectiles, et sur
quel écart. Un trait, une salve de trois sur vingt-quatre degrés, une nova de
huit sur trois cent soixante — et la prochaine compétence en éventail ne
demandera pas une branche de plus dans le joueur.

**`Player.lancer(index)` est le point de passage unique**, et il porte les quatre
refus : case vide, compétence non apprise, réserve insuffisante, recharge en
cours. Les cinq touches, la barre et les tests passent tous par là, et aucun n'a
à refaire une seule de ces vérifications.

**La barre ne se redessine que lorsque son état change.** Un panneau permanent
qui se repeint soixante fois par seconde paie ce dessin toute la partie, y
compris debout dans un couloir vide.

**Le manuel tombe après le placement du joueur, pas avant.** L'appel était posé
au milieu de `generate_zone()`, donc **avant** `_place_and_populate()`, qui pose
le joueur sur le point d'apparition de la carte neuve. À la toute première entrée
d'un personnage — le seul cas que cette règle sert — le livre atterrissait à
**1834 px** de lui, au coin de la scène. Le critère joué ne l'attrapait pas : sa
mise en place génère la zone deux fois, et le joueur est alors déjà quelque part.
Il a fallu un test qui n'engendre qu'une seule fois, comme le fait le jeu.

**Le drapeau du manuel de départ se pose au ramassage, pas à la chute.** C'est le
test qui l'a trouvé, et c'était un vrai défaut : un `F5` dans les premières
secondes effaçait le butin au sol, donc le seul manuel du personnage, **pour
toujours** et sans un mot. Le livre est désormais reposé à chaque génération tant
qu'il n'a pas été pris. La règle du §8 tient toujours — celui qui jette le sien
n'en reçoit pas un second — parce que le drapeau, une fois posé, ne retombe pas.

**Les quatre compétences ont été écrites à l'étape 5 et non à l'étape 7.** Une
page à une seule case ne se laisse pas juger : ni la capture des trois états, ni
la ligne de la case survolée n'avaient de quoi mordre.

**Remesure du banc** : **1,82 ms** de physique à 265 ennemis simulés, contre
4,41 ms à 284 au tableau de référence. Aucune régression — mais l'écart est trop
large pour être seulement du bruit, et je ne l'explique pas ; le tableau n'a donc
**pas** été récrit. À remesurer dans les conditions exactes du jalon 5 avant d'y
toucher.

**Un point resté ouvert** : dès qu'un manuel peut tomber dans le butin d'une zone
jouée, la campagne signale une trentaine d'objets non libérés **à la fermeture du
processus**. Aucune assertion n'échoue et le jeu n'est pas affecté. Écarté par la
mesure : l'objet manuel seul, sa pose au sol seule, les deux panneaux neufs, le
lancement des compétences, et le mécanisme d'entrée différée dans l'arbre — la
fuite demande la zone jouée. À reprendre.

### Le sens du plafond d'expérience, retourné

Décidé après coup, en jouant, et ça **remplace le §6.3 du jalon 5** : l'expérience
d'un ennemi suit désormais son niveau sans borne haute.

Elle en dérivait déjà — elle vient de ses PV, multipliés par huit en zone 40 —
mais le plafond du jalon 5 pénalisait la zone qui dépasse le personnage, et il
l'annulait entièrement. Mesuré sur un grunt, pour un personnage de niveau 12 :

| zone | l'ennemi vaut | avant | après |
|---|---|---|---|
| 1 | 11 | 11 | 4 |
| 10 | 28 | 28 | 28 |
| 20 | 46 | 32 | 46 |
| 40 | 84 | **4** | **84** |
| 60 | 122 | 6 | 122 |

Une zone de niveau 40 rapportait donc **moins que la zone de départ** — quatre
contre onze. La crainte du jalon 5 était fondée mais visait le mauvais bout : ce
qu'il fallait empêcher n'est pas d'aller trop bas, c'est de **rester trop haut**.

Le plafond n'a pas disparu, il a changé de sens : il fond quand la zone est
laissée loin **derrière** soi, cinq niveaux de retard restant gratuits. Moudre la
première zone à niveau 60 ne rapporte donc presque plus rien, et descendre plus
bas paie tout ce que ça vaut — la promesse que le jalon 5 tenait déjà pour le
butin, tenue maintenant pour l'expérience. Les manuels en héritent, puisqu'ils
reçoivent le même montant.

### Ce que l'étape 4 a changé au plan

- **La courbe est sortie en classe-feuille, `Progression`.** Le §3.3 disait « la
  même fonction avec d'autres constantes » ; ce qui n'était pas prévu, c'est que
  les deux modèles diffèrent. Le personnage retient l'expérience de son niveau
  **en cours** et la défalque à chaque montée — c'est ce que sa barre affiche —
  là où le manuel retient son **total**, puisque son niveau se déduit. La courbe
  dessous est la même ; ce sont deux lectures d'un même coût par niveau.
- **Un point par niveau, le premier compris.** Un livre tout juste ramassé a donc
  déjà un point à placer. Le contraire se lit comme une panne : on ouvre la page
  de son premier manuel et rien ne s'y passe.
- **Un manuel reçoit exactement ce que le personnage reçoit**, bornes comprises.
  Le plafond d'expérience du jalon 5 — l'écart de niveau avec la zone — s'applique
  donc une fois, en amont, et non deux ; et le montant n'est pas divisé entre les
  trois emplacements, pour la raison du §3.3.
- **Les constantes sont réglées sur un chiffre réel** : un grunt de niveau 1 vaut
  onze points d'expérience, donc `XP_BASE = 90` et `XP_PUISSANCE = 1.25` font
  monter un livre neuf d'un niveau en huit ennemis et de trois en une zone, puis
  ralentissent. `NIVEAU_MAX = 20` — de quoi remplir quatre cases à cinq points, et
  pas une de plus : un manuel qu'on finit est un manuel qu'on remplace. Premier
  réglage, à sentir en jouant.
- **Les quatre conditions de l'investissement sont dans `Manuel`, pas dans
  l'interface.** Une page qui referait le test finirait par en oublier un, et
  c'est le clic qui donnerait le point de trop.
- **Un test d'intégration a fait fuir des objets, et c'était instructif.** Tuer un
  ennemi fait tomber du butin par `add_child.call_deferred()` (invariant 4) : un
  test qui se termine dans la même image laisse un `GroundItem` instancié et
  jamais attaché, donc jamais libéré. La campagne le dit à la sortie — « ObjectDB
  instances were leaked » — et c'est une image d'attente qui le corrige.

### Ce que l'étape 3 a changé au plan

- **Le manuel posé au râtelier quitte le sac.** Le §3.4 en faisait un objet
  rangé auquel le râtelier renvoyait. Trois livres de deux cases sur deux, c'est
  **douze cases d'un sac qui en compte cinquante**, immobilisées à demeure — un
  quart du sac, pour un jeu dont la place est déjà la contrainte. Le geste est
  aussi celui que le joueur connaît : on retire un plastron du sac pour le
  porter. Et surtout la règle du §3.3 devient nette — un livre est **rangé ou à
  l'étude**, jamais les deux, donc « celui qui dort dans le sac n'apprend rien »
  n'a plus de cas limite. La duplication que le §3.4 redoutait est écartée de la
  même façon qu'`equipement` l'écarte depuis le jalon 3 : il n'est écrit qu'à un
  seul endroit.
- **Le niveau d'un manuel ne s'écrit pas.** Il se déduit de son expérience, et la
  sauvegarde n'écrit rien de calculé — ni PV, ni statistiques, ni total
  d'attributs. Le champ posé à l'étape 2 a donc disparu de `Manuel` ; la
  déduction revient à l'étape 4, avec la courbe. Un champ stocké qui n'est pas
  sauvegardé est un piège : on l'écrit, et il s'efface au rechargement suivant.
- **Deux petites classes plutôt que deux tableaux sur le personnage.**
  `Ratelier` et `BarreDeCompetences` portent leurs constantes — trois
  emplacements, cinq cases — là où une mise en page de panneau les aurait
  écrites en dur, et le râtelier hérite de la règle de `Player.equip()` : un
  objet refusé est **rendu**, jamais perdu.
- **Une case de barre vide s'écrit `null`.** Le projet a choisi le JSON pour que
  la sauvegarde se lise à l'œil ; « rien » doit donc y ressembler à rien, pas à
  une chaîne vide.
- **Clé `barre` absente : la barre de départ. Présente : ce qu'elle dit**, cases
  vides comprises. C'est la règle du format — un champ absent vaut son défaut —
  mais son défaut n'est pas « vide » : c'est le coup d'épée et le tir, sans quoi
  une sauvegarde de version 2 reviendrait avec un personnage incapable de
  frapper.
- **Les points placés dans une case que l'archétype n'enseigne plus sont
  oubliés**, et c'est l'archétype qui tranche, pas le catalogue des compétences :
  la question n'est pas « ce sort existe-t-il » mais « ce livre-là l'enseigne-t-il ».
  Les garder ferait un manuel qui doit des points à personne.
- **Le garde-fou des champs de sauvegarde comptait sans nommer.**
  `test_remplir_n_ecrit_aucune_statistique` vérifiait « douze champs, ni plus ni
  moins » : il annonce désormais lesquels. Un total seul dit qu'il y en a un de
  trop sans dire lequel, et c'est le moment où on aimerait le savoir.

### Ce que l'étape 2 a changé au plan

- **Cinq règles présumaient qu'une base est de l'équipement, pas une.** Le §10
  n'en annonçait qu'une. Aux affixes par famille se sont ajoutés les résistances
  « partout sauf sur les armes », les attributs « partout », les familles qui
  doivent avoir un emplacement, et surtout `test_chaque_lignee_est_monotone` —
  qui exige **deux paliers par lignée**, et non l'implicite croissant qu'on
  redoutait. La question est désormais posée à un seul endroit,
  `EquipmentSlots.famille_equipable()`, et les cinq règles l'appellent.
- **L'exemption a sa garde.** Exempter « ce qui ne se porte pas » ouvrait la
  porte à une faute de frappe : `family = "manaul"` aurait échappé à toutes les
  règles en silence. `test_un_archetype_va_avec_la_famille_du_manuel` ferme la
  porte dans les deux sens — une base porte un archétype **si et seulement si**
  elle est de la famille des manuels, et toute autre base doit s'équiper quelque
  part. La famille est nommée une fois, `ItemBase.FAMILLE_MANUEL`.
- **La rareté vient du palier de la base, pas d'un champ sur l'archétype.**
  L'archétype ne peut pas nommer `Item.Rarity` : `Item` connaît `ItemBase`, qui
  connaîtrait `ManuelArchetype`, qui connaîtrait `Item` — un cycle, que GDScript
  refuse. Extraire l'énumération en classe-feuille, comme `DamageType`, aurait
  été le geste habituel du projet, mais le palier disait déjà « quelle version de
  ce livre » : c'est la même information, et elle était déjà là.
- **`Manuel` ne connaît pas son archétype.** L'objet porte les deux — sa base
  sait quel livre c'est, son manuel sait ce qu'il en a tiré — et les règles qui
  ont besoin des deux recevront l'archétype en argument, comme
  `Competence.degats()` reçoit la fiche. Une référence en retour aurait fait un
  second chemin vers la même information, et l'un des deux aurait fini par mentir.
- **« Éclair vif » est écrite avec quatre étapes d'avance.** Un archétype sans
  une seule case ne se laisse pas éprouver : ni la page, ni l'investissement, ni
  ce test-ci n'auraient eu de quoi mordre. Les trois autres compétences de la
  foudre restent à l'étape 7, avec leur équilibrage.
- **La référence de contenu annonçait une chose que le tirage refuse.**
  `tools/generer_catalogue.gd` comptait les bases éligibles à un affixe avec
  `ItemAffix.fits()`, c'est-à-dire le filtre par étiquettes seul, alors que la
  règle complète vit dans `ItemAffixPool.compatibles()`. `docs/CATALOGUE.md`
  affirmait donc qu'un manuel pouvait recevoir de la dextérité — 42/42 au lieu de
  41/42. L'outil passe maintenant par la règle. Une référence qui décrit autre
  chose que le jeu est pire que pas de référence.
- **Les icônes se vérifient en headless.** Le §« Valider » de `CLAUDE.md` dit que
  le dessin demande une capture en fenêtré : c'est vrai des **panneaux**, dont le
  pilote de rendu est un bouchon. Une icône d'objet, elle, est du code processeur
  — `PixelCanvas` peint dans une `Image` — et se rend donc en PNG depuis une copie
  temporaire, sans fenêtre. Le manuel y a gagné : les deux premiers dessins, un
  livre ouvert puis un livre couché, sortaient comme une paire d'ailes et comme un
  maillet. C'est une **pile de deux volumes** qui se lit, et sa silhouette large
  la sépare du tome de la main gauche, qui est haut.

### Ce que l'étape 1 a changé au plan

- **`pourcentage_par_point` s'appelle `pourcentage_par_attribut`.** Le §5.1
  écrivait « point » pour deux choses dans la même fiche — le point investi dans
  une case, et le point d'attribut du personnage. Deux sens du même mot à trois
  lignes d'écart, c'est la faute de lecture assurée le jour du réglage.
- **La position sur la page n'est pas sur la compétence.** Le §5.1 la lui
  donnait ; elle appartient à la **case** du manuel. Une compétence est ce qu'elle
  fait, pas l'endroit où on la trouve — et le jour où deux manuels partageront un
  sort, ils le poseront chacun où ils veulent sans se contredire.
- **`recharge` n'est pas encore écrite.** Le coup d'épée suit `attack_speed` et
  le tir `cast_speed` : ce sont deux règles, pas deux valeurs, et une compétence
  ne sait pas encore dire laquelle elle suit. Inventer le champ maintenant, ce
  serait deviner ; il arrive avec la barre, quand cinq cadences devront coexister.
  Les deux cadences restent donc des réglages du nœud joueur, et le commentaire
  qui l'explique est passé sur `bolt_cooldown`.
- **`DamageInfo.roll()` demande le montant** au lieu de le lire sur
  `stats.attack_damage`. Un seul appelant à changer, et c'est ce qui empêche la
  prochaine compétence de sortir physique sans que personne ne s'en aperçoive.
  Le coup critique, lui, ne bouge pas : il reste dans cette fonction, une
  compétence ne le retire ni ne le double.
- **La nature du tir est écrite à deux endroits**, et c'est provisoire : la
  compétence l'annonce, la bille la porte encore sur sa scène. Un test les tient
  d'accord (`test_la_nature_du_tir_ne_diverge_pas_de_celle_de_la_bille`) jusqu'à
  ce que l'étape 7 fasse de la compétence la seule à décider. Une duplication
  qu'on assume et qu'un test surveille vaut mieux qu'un détour d'architecture au
  milieu d'une étape qui ne parle pas de ça.
- **Le coût en mana a quitté l'export du nœud** pour la fiche de la compétence.
  C'était le seul des trois nombres du tir — dégâts, coût, cadence — à n'avoir
  aucune ambiguïté de règle.

---

## 10. Ce qui peut mal tourner

- **Écrire les points dans l'archétype partagé.** La faute la plus chère du
  jalon, et l'exacte reprise de celle du jalon 5 sur les fiches d'ennemis : tous
  les manuels de foudre du jeu partageraient les points du dernier ouvert, y
  compris dans les tests, et l'éditeur peut graver le résultat. Le test « deux
  manuels ramassés ont des points indépendants » est là pour ça, et il s'écrit à
  l'étape 2.
- **Monter `Personnage.VERSION` sans écrire la lecture des anciens formats.**
  Tous les personnages existants passent « illisibles » d'un coup, fichiers
  intacts. À l'étape 3, avec son test, avant toute interface.
- **La famille « manual » qui casse un test du catalogue.**
  `test_chaque_famille_a_de_quoi_tirer_des_affixes` exige de **chaque** base au
  moins quatre affixes tirables au niveau d'objet 1 ; un manuel n'en reçoit
  aucun. **Ce n'est pas une valeur attendue à ajuster** : c'est la règle qui doit
  apprendre qu'il existe des bases qui ne s'équipent pas et ne reçoivent pas
  d'affixes, et le dire — sinon le seuil de quatre se trouvera abaissé pour tout
  le monde, et les premières zones se rempliront de blanc sans que personne
  n'ait rien décidé.
  Deux voisins qu'on croira touchés ne le sont pas :
  `test_chaque_emplacement_a_au_moins_une_base` vérifie que chaque *emplacement*
  a une base, pas l'inverse, et `test_les_implicites_visent_des_statistiques_reelles`
  laisse déjà passer un implicite vide. Celui qui mordra plus tard est
  `test_chaque_lignee_est_monotone` : il exige d'un palier supérieur un implicite
  supérieur, et un manuel n'en a pas — c'est le jour de la version rare qu'il
  faudra le régler, pas maintenant.
- **L'icône vide.** Un `kind` nouveau qui n'est ni dans `_weapon()` ni dans
  `_gear()` + `GEAR` sort un dessin sans un pixel. Personne ne le voit avant de
  ramasser l'objet — d'où le test.
- **Deux formules de dégâts.** L'infobulle qui recalcule ce que le lancement
  calcule déjà finira par annoncer autre chose que ce qui sort. Une fonction,
  deux appelants.
- **L'expérience du manuel branchée sur celle du personnage.** « Le manuel monte
  quand le personnage monte » paraîtra une simplification raisonnable, et
  supprimera la seule décision que le râtelier apporte.
- **La barre qui recouvre le sac, ou l'inverse.** Les deux veulent le même coin
  d'un écran de 640 × 360. Aucune assertion ne le verra ; c'est une capture, et
  elle se fait en fenêtré.
- **Le clic d'assignation qui lance le sort.** Les attaques sont lues par
  sondage, hors du système d'entrées de l'interface. La garde
  `Game.ui_grabs_input` existe depuis le jalon 4 ; les cinq actions
  doivent passer dessous, et le menu d'assignation doit prendre la souris comme
  le sac le fait.
- **Une compétence qui tire au hasard.** `Game.rng` est le fil des tirages de la
  partie (invariant 3) : un sort qui appelle `randf()` une fois sur deux — pour
  une dispersion, un ricochet — décale toutes les graines de zone tirées ensuite,
  et deux parties identiques cessent de l'être. C'est la raison pour laquelle
  `Hurtbox` teste `evade > 0.0` avant de tirer. Une compétence consomme le même
  nombre de tirages quel que soit son résultat, ou n'en consomme aucun.
- **Un identifiant de compétence renommé.** Il est dans les sauvegardes au même
  titre qu'un `ItemBase.id`. Renommer `eclair_vif` vide la barre de tout le
  monde, au prochain chargement seulement.
- **Le manuel de départ qui retombe à chaque zone.** Le drapeau est dans la
  sauvegarde, pas déduit du contenu du sac.
- **Quatre compétences qui se ressemblent.** Un projectile, un projectile plus
  gros, un projectile qui perce et un projectile en éventail, c'est une seule
  compétence à quatre réglages. Si l'archétype doit se réduire, on réduit le
  **nombre** de compétences, jamais le nombre d'étapes validées.
