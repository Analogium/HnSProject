# Hack'n'slash top-down — jalon 5

Suite de `hack-n-slash-jalon-1.md`, qui reste la référence sur l'architecture et
les conventions, de `hack-n-slash-jalon-2.md` (affixes, progression, objets),
de `hack-n-slash-jalon-3.md` (personnage persistant) et de
`hack-n-slash-jalon-4.md` (dix emplacements, navigation, infobulles de fiche).
Ce document ne redit pas ce qui y est déjà écrit.

**Décidé le 7 septembre 2026.** Le jalon 4 a donné dix endroits où porter ce
qu'on ramasse. Ce qu'on y met n'a toujours aucune profondeur : dix affixes tirés
dans une fourchette unique, une base par emplacement, et un objet ramassé à la
première minute est exactement celui qu'on ramassera à la centième. Il manque
au jeu la seule chose qu'un hack'n'slash promet vraiment — que **descendre plus
bas rapporte mieux**.

---

## 1. Périmètre du jalon 5

**Dedans :**

- **Le niveau d'objet** (`ilvl`), posé à la chute, égal au niveau de la zone
- **Les tiers d'affixes** : plusieurs paliers de valeurs par affixe, chacun
  ouvert à partir d'un niveau d'objet minimum, T1 le meilleur
- **L'élargissement de la réserve d'affixes**, attendu depuis le jalon 2 : de
  dix à environ vingt-cinq, résistances et attributs compris
- **Le filtrage fin** de ce qu'une base peut tirer — la vitesse de déplacement
  aux bottes, les défenses aux armures, les résistances partout sauf aux armes,
  et une baguette qui ne tire jamais de dégâts d'attaque
- **Les paliers de bases** : une trentaine de bases au lieu de dix, rangées en
  lignées, chacune avec son niveau requis et son implicite
- **Le niveau de zone** : des ennemis mis à l'échelle, choisis depuis l'écran de
  réglage de génération, qui lâchent du butin au niveau de la zone
- **L'affichage Alt** : maintenir Alt en survolant un objet montre le tier de
  chaque affixe et la plage du tier

**Explicitement dehors :** les préfixes et suffixes avec leurs quotas (trois et
trois), l'artisanat et les monnaies, les objets uniques, les prérequis
d'équipement (niveau et attributs sur la fiche de l'objet), les armes à deux
mains, les gemmes, les bonus d'ensemble, l'enchaînement des zones par une carte
du monde, les classes et compétences, l'audio, et l'équipement peint sur la
silhouette.

**Les prérequis d'équipement méritent leur ligne**, parce que leur absence va se
voir : un personnage de niveau 3 pourra porter une cuirasse de niveau 32 s'il
survit assez longtemps dans une zone de niveau 32 pour la ramasser. C'est
assumé — dans ce jalon, **c'est le danger de la zone qui garde le butin**, pas
une ligne rouge sur une fiche. La barrière est meilleure : elle se joue au lieu
de se lire.

**Critère de réussite :** régler la zone sur le niveau 40, y entrer avec un
personnage de niveau 12 et se faire tuer ; y revenir plus fort, en ressortir avec
un plastron qui n'existait pas au niveau 1 ; maintenir Alt dessus et lire
« T3 (59–74) » sur sa ligne de PV ; et vérifier qu'après cent baguettes ramassées,
aucune ne porte de dégâts d'attaque.

---

## 2. Le principe structurant : le niveau d'objet est le seul robinet

Tout ce que ce jalon ajoute passe par un seul nombre.

```
niveau de la zone  →  niveau des ennemis  →  niveau des objets qui tombent
                                          →  quelles bases peuvent tomber
                                          →  quels tiers d'affixes peuvent sortir
```

**Le niveau du joueur n'entre nulle part dans cette chaîne**, et c'est la
décision de fond du jalon. Adossé au niveau du personnage, le butin s'améliorerait
en jouant longtemps ; adossé au niveau de la zone, il s'améliore en allant là où
c'est dangereux. La première règle récompense la patience, la seconde le risque —
et c'est la seule des deux qui donne une décision à prendre à chaque zone.

Conséquence directe, et elle est voulue : un personnage de niveau 40 qui retourne
dans une zone de niveau 5 n'y trouvera rien. Le butin de bas niveau ne devient
pas mauvais, il **cesse d'être là où on est fort**.

Le niveau d'objet est posé **une fois**, à la chute, et ne bouge plus jamais. Il
part sur le disque avec l'objet. C'est ce qui permettra un jour à l'artisanat
d'exister : relancer les affixes d'un objet devra rejouer le tirage dans la
réserve de *son* niveau, pas dans celle de la zone où on se trouve.

---

## 3. Ce qu'un affixe peut viser : des étiquettes, pas des familles

### 3.1 Le défaut

`ItemAffix.families` liste des familles, et `fits()` compare à `base.family`.
Une baguette et une épée sont toutes deux de famille `weapon` : **aucun filtre
écrit dans le système actuel ne peut donner des dégâts d'attaque à l'une et pas
à l'autre.** C'est le cas qui fait éclater la règle, exactement comme les deux
anneaux ont fait éclater `slot` au jalon 4.

Descendre le filtre au niveau de la base (`families` devient une liste d'`id`)
serait pire : chaque nouvelle base obligerait à rouvrir les vingt-cinq `.tres`
d'affixes pour l'y ajouter, et un oubli donnerait une base qui ne tire rien sans
que personne le voie.

### 3.2 La règle

**Une base porte des étiquettes. Un affixe dit celles qu'il exige et celles
qu'il refuse.**

- `ItemBase.tags: PackedStringArray` — ce que la base *est*, au-delà de son
  emplacement : `["weapon", "melee", "blade"]` pour une épée,
  `["weapon", "caster"]` pour une baguette, `["armour", "heavy"]` pour une
  cuirasse ;
- `ItemAffix.families` devient `ItemAffix.tags` : au moins une doit être portée
  par la base. Vide = partout ;
- `ItemAffix.exclut` : une seule suffit à refuser, et **elle l'emporte** sur
  `tags`. C'est elle qui écrit « partout sauf sur les armes » en une ligne au
  lieu de neuf.

**La migration est mécanique** : chaque base reçoit sa famille comme première
étiquette, donc les dix affixes existants gardent leur liste telle quelle et
continuent de tomber sur exactement les mêmes objets. Le renommage du champ est
le seul changement à relire.

### 3.3 Les étiquettes

| Base | Étiquettes |
|---|---|
| lames (dague, épée…) | `weapon` `melee` `blade` |
| contondantes (masse…) | `weapon` `melee` `blunt` |
| baguettes et sceptres | `weapon` `caster` |
| boucliers | `offhand` `armour` `heavy` |
| grimoires | `offhand` `caster` |
| casque, torse, gants, bottes lourds | `<famille>` `armour` `heavy` |
| casque, torse, gants, bottes légers | `<famille>` `armour` `light` |
| ceinture | `belt` |
| amulette, anneau | `<famille>` `jewellery` |

`heavy` et `light` ne servent à rien dans ce jalon **sauf à distinguer deux
lignées d'armure** : la lourde donne de l'armure, la légère de l'esquive, et
c'est ce que leurs implicites disent déjà. Les affixes s'en servent pour ne pas
mettre d'esquive sur une cuirasse.

### 3.4 Ce que la demande devient, ligne par ligne

| Règle voulue | Écriture |
|---|---|
| vitesse de déplacement aux bottes | `tags = ["boots"]` |
| vie et armure sur les armures | `tags = ["armour", "belt"]` |
| esquive sur les armures légères | `tags = ["light"]` |
| résistances partout sauf aux armes | `tags = []`, `exclut = ["weapon"]` |
| anneaux et ceintures tirent presque tout | rien à écrire : ils portent `jewellery` / `belt`, et la plupart des affixes les listent |
| une baguette ne tire ni dégâts ni vitesse d'attaque | `tags = ["melee", "gloves", "jewellery"]` sur ces deux affixes-là |

**Changement par rapport au jalon 4 :** `preste` (vitesse de déplacement) passe
des bottes *et* de la ceinture aux **bottes seules**. C'est la demande, et elle
est juste : une statistique qui ne se trouve qu'à un endroit fait de cet
endroit une décision.

### 3.5 Le trou que la baguette révèle

Une fois les dégâts d'attaque et la vitesse d'attaque retirés de la baguette, il
ne lui reste **aucun affixe offensif**. Elle n'est plus une arme, c'est un
bijou tenu dans la main.

La cause n'est pas le filtre, elle est plus ancienne : **il n'existe pas de
statistique de dégâts de sort.** Le tir lit `Player.bolt_damage`, un `@export`
du nœud joueur, qui n'est pas dans `CharacterStats` et qu'aucun objet ne peut
donc toucher.

Ce jalon ajoute `spell_damage` à `CharacterStats`, et le tir le lit. C'est trois
lignes, c'est ce qui rend l'exclusion de la baguette honnête, et ça ouvre la
moitié incantation de l'arbre d'objets qui n'existait que sur le papier :
`cast_speed` pilotait déjà la cadence sans que rien ne pilote la force du coup.
Une entrée dans `StatMod.LABELS` et une dans `StatHelp.TEXTS` vont avec —
le test de couverture des infobulles du jalon 4 les réclamera de lui-même.

---

## 4. Les tiers d'affixes

### 4.1 La forme

Un affixe n'est plus une fourchette, c'est une **échelle de fourchettes**.

```
vigoureux — PV plats — tags: armour, belt, jewellery

  T8   niveau  1    +8 à +14
  T7   niveau  6   +15 à +22
  T6   niveau 12   +23 à +32
  T5   niveau 19   +33 à +44
  T4   niveau 26   +45 à +58
  T3   niveau 34   +59 à +74
  T2   niveau 43   +75 à +92
  T1   niveau 52   +93 à +112
```

**T1 est le meilleur, et le dernier numéro dépend de l'affixe** : huit tiers ici,
onze pour une résistance qui progresse par petits pas, cinq pour un affixe rare
qu'on ne veut pas voir s'étaler. C'est la demande, et c'est aussi ce qui donne
son grain au butin : deux affixes ne se lisent pas à la même échelle.

Le tier le plus bas exige toujours le niveau 1. Sans cette règle, un affixe
n'existerait pas du tout dans les premières zones, et sa première apparition
ressemblerait à un ajout de contenu plutôt qu'à une progression.

### 4.2 Le tirage

**Tous les tiers dont le niveau requis est atteint peuvent sortir**, le meilleur
comme les moins bons — c'est la demande, et c'est ce qui fait qu'un objet de
niveau 60 avec un T7 dessus existe et déçoit. Sans les mauvais tiers, le niveau
d'objet ne serait plus une chance mais une garantie, et il n'y aurait plus rien
à espérer en regardant tomber un objet.

Poids **égal entre tiers disponibles** par défaut, avec un champ `poids` par
tier pour l'exception. Un affixe à huit tiers ouverts sort donc T1 une fois sur
huit à niveau 52. C'est volontairement généreux pour une première calibration :
on serre en jouant, et le champ est là pour ça.

Un affixe dont **aucun** tier n'est ouvert n'est pas dans la réserve. C'est le
mécanisme entier : le niveau d'objet ne change pas les probabilités par une
formule, il **ouvre des lignes dans une table**.

### 4.3 Pourquoi une table écrite à la main

La tentation est de dériver les tiers d'une formule — valeur de départ, facteur
de croissance, nombre de paliers. Elle donnerait cent cinquante lignes gratuites
et un équilibrage que personne n'a choisi : tous les affixes auraient la même
courbe, et l'écart entre deux tiers serait le même partout, ce qui est
exactement ce qu'on cherche à ne pas avoir.

Les tiers sont donc **écrits dans les `.tres`**, un par ligne. C'est le contenu
du jalon, pas sa plomberie. Le coût — deux cents lignes à saisir — est réel et
c'est le poste le plus long après les icônes.

Ce qui remplace la formule, c'est un test : dans une échelle, **le tier n est
strictement meilleur que le tier n+1 et exige un niveau strictement supérieur**.
Une faute de frappe qui inverse deux fourchettes se voit là, jamais en jeu.

Le commentaire d'`ItemBase` dit qu'une sous-ressource dans un `.tres` est pénible
à relire, et il a raison — pour un implicite, dont il y a exactement un. Ici il y
en a huit à onze et ils *sont* l'affixe. `ItemAffixTier` est donc une Resource, et
`ItemAffix.tiers` un `Array[ItemAffixTier]` ordonné du meilleur au pire.

### 4.4 Ce que l'objet doit retenir

Aujourd'hui, `Item.explicits` est un `Array[StatMod]` : une statistique, un mode,
une valeur. **De quel affixe cette valeur vient-elle, et de quel tier ?** Rien ne
le dit, et l'infobulle Alt ne peut pas l'inventer.

`Item.explicits` devient donc une liste d'affixes tirés — l'identifiant de
l'affixe, l'indice du tier, et le `StatMod` déjà résolu. Le `StatMod` reste la
seule chose que le calcul des statistiques consomme : `Item.mods()` ne change pas
de signature, et `StatMod.apply_all` ne connaît toujours que des modificateurs.
C'est l'infobulle, et elle seule, qui a besoin de la provenance.

### 4.5 Ce que la sauvegarde doit retenir, et le piège de la version

`Personnage._item_vers_dict` écrit aujourd'hui `{stat, mode, valeur}` par affixe.
Il faut y ajouter l'identifiant de l'affixe et le tier, et le niveau de l'objet à
côté de sa base.

**`Personnage.VERSION` passe à 2, et `depuis_dict` doit accepter les deux.**
Le code actuel refuse tout ce qui n'est pas exactement `VERSION` — c'était la
bonne règle tant qu'il n'existait qu'un format. Monter le numéro sans écrire la
lecture de l'ancien **ferait disparaître tous les personnages existants de
l'écran de sélection**, grisés comme illisibles, alors que leurs fichiers sont
intacts.

Ce qu'un personnage de version 1 devient en version 2 :

- ses objets prennent le niveau d'objet **1** — on ne sait pas où ils sont
  tombés, et prétendre le contraire serait inventer ;
- leurs affixes gardent leur valeur exacte, sans identifiant ni tier. L'infobulle
  Alt doit alors afficher la valeur **sans colonne de tier**, jamais un « T? »
  ni un tier deviné à partir de la valeur : deux tiers se chevauchent, la
  déduction serait fausse une fois sur trois.

Un test de non-régression écrit un fichier de version 1 à la main, le relit, et
vérifie que les objets sont là avec leurs valeurs.

---

## 5. Les bases : des lignées et des paliers

### 5.1 La forme

`ItemBase` gagne trois champs :

- `lignee: String` — à quelle suite de bases celle-ci appartient
  (`"lame"`, `"cuirasse"`, `"bottes_lourdes"`…) ;
- `palier: int` — son rang dans la lignée, 1 le plus modeste ;
- `niveau_requis: int` — le niveau d'objet à partir duquel elle peut tomber.

L'implicite monte avec le palier : c'est lui qui fait qu'une cuirasse vaut mieux
qu'une tunique **avant même** de regarder les affixes. Un test garde la monotonie
d'une lignée — palier supérieur, niveau requis supérieur, implicite supérieur —
parce qu'une lignée où le troisième palier donne moins que le deuxième est un
piège que personne ne remarque avant de comparer deux objets en jeu.

### 5.2 La trentaine de bases

Trois paliers par lignée, une ou deux lignées par emplacement. Les niveaux sont
une première calibration, à serrer en jouant.

| Emplacement | Lignée | Paliers (niveau requis) |
|---|---|---|
| arme | lame | Dague (1) · **Épée** (1) · Épée large (16) · Lame de guerre (34) |
| arme | contondante | Masse (6) · Masse d'armes (22) · Marteau de guerre (40) |
| arme | focus | **Baguette** (1) · Sceptre (18) · Sceptre runique (36) |
| main gauche | bouclier | **Bouclier** (1) · Écu (15) · Pavois (33) |
| main gauche | grimoire | Grimoire (10) · Codex (28) |
| casque | lourd | **Casque** (1) · Heaume (14) · Armet (32) |
| casque | léger | Capuche (1) · Capuche de maître (20) |
| torse | lourd | **Plastron** (1) · Cuirasse (17) · Harnois (35) |
| torse | léger | Tunique (1) · Justaucorps (19) |
| gants | — | **Gants** (1) · Gantelets (13) · Gantelets de siège (31) |
| bottes | — | **Bottes** (1) · Grèves (12) · Grèves de plates (30) |
| ceinture | — | **Ceinture** (1) · Ceinturon (11) · Baudrier (29) |
| amulette | — | **Amulette** (1) · Talisman (17) · Pendentif (35) |
| anneau | — | **Anneau** (1) · Bague ouvragée (16) · Chevalière (34) |

En gras, les dix bases actuelles. **Elles gardent leur `id`**, quoi qu'il arrive
à leur nom lisible : `plastron` reste `plastron` même s'il s'appelle « Plastron
de fer » et devient le premier palier d'une lignée lourde. Le `display_name` est
libre, l'identifiant est gravé (jalon 3, §3.3).

Si l'étape déborde, **c'est le nombre de paliers qu'on réduit, pas le nombre de
lignées** : deux paliers par lignée gardent la variété d'un emplacement à
l'autre, une lignée en moins la supprime pour toute la partie.

### 5.3 Ce qui peut tomber

**Les deux meilleurs paliers disponibles de chaque lignée**, et rien en dessous.

Sans cette règle, chaque nouvelle base dilue les autres : à niveau 40, une chute
sur trois serait une dague de niveau 1, et le rythme de récompense s'effondrerait
au moment précis où il devrait s'améliorer. Avec elle, entrer dans une zone de
niveau 34 fait **disparaître les épées larges au profit des lames de guerre** en
deux ou trois chutes, et ça se sent sans qu'on ait rien à lire.

Une constante, `LootTable.PALIERS_VISIBLES := 2`, et un seul endroit qui l'applique.
`LootTable.roll` prend désormais le niveau de la zone en argument — il ne peut
plus tirer uniformément dans `ItemCatalog.ALL`, qui reste la liste unique des
bases mais n'est plus la liste de ce qui tombe.

Le taux de chute (`BASE_CHANCE`) ne bouge pas. Il a déjà été noté au jalon 4 que
l'étalement du tirage le rendrait suspect : c'est ici qu'on le remesure, et
c'est cette règle-ci qui est censée le sauver.

### 5.4 Les icônes

Nouveaux `kind` à forger : `dagger`, `axe` ou `mace`, `staff`, `tome`, et les
variantes légères d'armure si elles ne peuvent pas réemployer le dessin existant.
`SpriteForge.GEAR` sert déjà d'aiguillage, et le test « chaque base peint au
moins un pixel » attrapera un `kind` oublié.

**Le vrai problème est ailleurs : trois paliers d'une même lignée partagent leur
`kind`.** Un plastron, une cuirasse et un harnois se dessineraient identiques, et
le sac deviendrait illisible — c'est exactement ce que le jalon 4 a interdit à
propos de l'anneau et de l'amulette.

Deux façons de s'en sortir, dans cet ordre :

- **la palette.** La forge peint déjà avec des rampes nommées (`R_METAL`,
  `R_LEATHER`) ; un palier supérieur pris dans une rampe plus claire ou plus
  froide se distingue à la taille d'une case, sans redessiner quoi que ce soit ;
- **un détail de silhouette**, quand la palette ne suffit pas : une pointe, une
  garde, une bordure. C'est du dessin, donc c'est la galerie (`F4`) qui tranche,
  pas une assertion.

Ce qu'il ne faut pas faire : distinguer les paliers **uniquement** par le nom.
On ne lit pas le nom d'un objet au sol.

---

## 6. Le niveau de zone

### 6.1 Ce que c'est

Un entier, de 1 à 60 pour ce jalon, qui vaut pour toute la zone : c'est le niveau
de chaque ennemi qui y naît, et le niveau d'objet de tout ce qui y tombe.

Il vit sur `Game` — comme `Game.personnage`, et pour la même raison : il doit
survivre au changement de scène, ce qu'un changement de scène détruit. Défaut :
**1**. L'arène de réglage, le banc de stress et la galerie n'y touchent pas et
n'ont rien à savoir de lui.

### 6.2 La mise à l'échelle

Un seul endroit, une fonction statique qui prend une fiche et un niveau :

```
vie     ×= 1 + 0.18 × (niveau - 1)
dégâts  ×= 1 + 0.12 × (niveau - 1)
```

Linéaire et non exponentiel : une courbe exponentielle demande un exposant qu'on
ne saura pas régler avant d'avoir joué, et se trompe d'un facteur dix à la
soixantième marche. À niveau 40, un grunt a huit fois sa vie et cinq fois ses
dégâts — c'est brutal, c'est réglable, et c'est mesurable en une partie.

Ni l'armure ni les résistances ne montent dans ce jalon. Le joueur n'a aucun
moyen de percer une armure ; la faire croître transformerait une zone profonde
en mur au lieu d'un danger.

**La fiche doit être dupliquée avant d'être écrite.** C'est le piège que
`Enemy._apply_affixes` documente déjà : aucun `.tres` du projet n'est
`resource_local_to_scene`, donc multiplier `stats.max_health` en place multiplie
la vie de **tous** les grunts de la session — et l'éditeur peut graver le
résultat dans `grunt_stats.tres`. La mise à l'échelle et les affixes doivent donc
partager la même duplication, faite une fois, pas deux.

### 6.3 L'expérience, qui va exploser si on ne fait rien

`Enemy.xp_value()` dérive l'expérience de `max_health` (`XP_PER_HEALTH`). C'est
une bonne règle — et elle donne huit fois l'expérience à niveau 40. Un personnage
de niveau 12 qui survit à trois paquets dans une zone de niveau 40 gagnerait dix
niveaux, et le niveau de zone cesserait d'être un choix de risque pour devenir un
raccourci.

L'expérience est donc **bornée par l'écart de niveau** :

```
écart   = niveau_zone - niveau_joueur
facteur = clampf(1.0 - 0.10 × maxi(0, écart - 5), 0.05, 1.0)
```

Cinq niveaux d'avance sans pénalité — c'est la marge dans laquelle on veut que le
joueur pousse. Au-delà, la récompense fond, et à quinze niveaux d'écart il ne
reste presque rien. Le butin, lui, n'est **pas** borné : c'est tout l'intérêt
d'aller trop loin, et c'est la seule chose qu'on rapporte d'une zone où l'on
n'apprend rien.

C'est le seul endroit du jalon où le niveau du joueur entre en jeu (§2). Il
plafonne une récompense ; il n'ouvre jamais rien.

### 6.4 Où on le choisit

Dans l'écran de réglage de génération (`F3`, `map_debug.tscn`), à côté de
`fill_chance` et des itérations : deux touches pour monter et descendre, la
valeur au bandeau, et `F1` lance la zone avec. C'est provisoire et c'est dit —
l'endroit définitif est une carte du monde, qui est hors périmètre.

Cet écran est déjà **l'endroit d'où l'on règle une zone avant d'y entrer**.
Ajouter un menu ailleurs pour un réglage temporaire, c'est deux interfaces à
retirer le jour où la vraie arrive.

Ce que ça change à la zone : le bandeau (`H`) annonce le niveau à côté de la
graine, et `F5` regénère **au même niveau** — changer de carte n'est pas changer
de danger.

### 6.5 Le déterminisme, qui ne bouge pas

Le niveau de zone n'entre pas dans la graine. Deux zones de même graine et de
niveaux différents ont **les mêmes murs, les mêmes paquets aux mêmes cases, les
mêmes silhouettes** — seule l'échelle des ennemis change. C'est ce qui permet de
comparer deux niveaux sans changer une seule autre variable, et c'est
exactement ce dont l'équilibrage aura besoin.

Le butin continue de tirer sur `Game.rng` et non sur le tirage de la zone, pour
la raison écrite dans `LootTable` : recharger une zone ne doit pas garantir une
chute.

---

## 7. Alt : les tiers à l'écran

Sans Alt, l'infobulle d'objet gagne **une seule ligne** : le niveau de l'objet,
sous son nom. C'est l'information qui décide si on le garde, et elle doit être
là tout le temps.

Avec Alt maintenu, chaque ligne d'affixe gagne son tier et la plage de ce tier :

```
Lame de guerre
niveau d'objet 42
+11 dégâts                          ← implicite
─────────────────────────────
+63 PV                     T4  (45–58)
+9 % vitesse d'attaque     T5  (8–11)
+18 rés. feu               T3  (16–20)
```

Trois choses à ne pas rater :

- **lire l'état réel de la touche**, pas un booléen mémorisé sur l'événement.
  Alt est intercepté par le gestionnaire de fenêtres sur les trois systèmes ;
  perdre le focus la touche enfoncée ne rend jamais le relâchement, et
  l'infobulle resterait ouverte en mode détaillé jusqu'au prochain appui ;
- **redessiner sur l'appui**, sinon rien ne change tant que la souris ne bouge
  pas — et on maintient Alt précisément parce qu'on ne bouge plus ;
- **la largeur**. L'infobulle est dessinée à gauche du panneau
  (`-w - TIP_GAP`) et le mode détaillé l'élargit d'un tiers. Le jalon 4 a borné
  sa hauteur pour qu'elle ne sorte pas par le bas ; il faut la même borne à
  gauche, ou elle sortira du cadrage de 640 pixels au premier objet à six
  affixes.

L'implicite n'a ni tier ni plage : il ne se tire pas. Rien à afficher là, et
surtout pas une colonne vide qui laisserait croire à un tirage raté.

Le jalon 4 s'était posé la question de partager le dessin des deux infobulles et
avait tranché : deux appelants ne le paient pas. **La réponse ne change pas** —
celle-ci reste l'infobulle d'objet, elle gagne des colonnes, elle ne devient pas
une troisième sorte.

---

## 8. Ordre de construction

Chaque étape se valide avec `tests/run.sh` avant la suivante. Les trois premières
sont de la structure et ne changent presque rien à ce qu'on voit ; les trois
suivantes sont le contenu ; la dernière est l'écran.

- [x] **1. Les étiquettes.** `ItemAffix.families` devient `tags`, `exclut`
      apparaît, les dix bases reçoivent leurs étiquettes, `preste` passe aux
      bottes seules, `spell_damage` entre dans `CharacterStats` et le tir le
      lit. Aucun affixe nouveau. Tests : une baguette ne tire jamais de dégâts ni
      de vitesse d'attaque sur mille tirages ; la vitesse de déplacement ne sort
      que sur des bottes ; chaque base garde au moins deux affixes possibles.
- [x] **2. Le niveau d'objet.** `ItemBase.niveau_requis`, `Item.item_level`,
      `Game.niveau_de_zone` à 1, la chute qui l'estampille, la ligne dans
      l'infobulle, la sauvegarde en version 2 avec la lecture de la version 1.
      Tests : un fichier de version 1 se recharge avec ses objets et leurs
      valeurs ; un objet neuf porte le niveau de la zone ; un aller-retour sur le
      disque conserve le niveau.
- [ ] **3. Les tiers.** `ItemAffixTier`, le tirage par niveau, l'affixe tiré qui
      retient son identifiant et son tier, la sauvegarde des deux. Les dix
      affixes existants passent en échelles. Tests : monotonie de chaque échelle ;
      un objet de niveau 1 ne sort jamais un tier verrouillé ; à niveau 60 tous
      les tiers sont atteignables ; un objet rechargé retrouve ses tiers.
- [ ] **4. La réserve élargie.** Une vingtaine d'affixes de plus — résistances,
      esquive, mana et régénérations, attributs, dégâts de sort — chacun avec ses
      tiers et ses étiquettes. Tests : chaque statistique qui doit être
      atteignable l'est par au moins un affixe ; chaque base a au moins quatre
      affixes disponibles à niveau d'objet 1, sinon les premières zones ne
      lâchent que du blanc ; les règles du §3.4 vérifiées base par base.
- [ ] **5. Les paliers de bases.** Les `.tres`, les lignées, les niveaux requis,
      les implicites croissants, la règle des deux meilleurs paliers, les icônes
      des nouveaux `kind` et la distinction visuelle entre paliers. Tests :
      monotonie d'une lignée ; chaque emplacement a au moins une base disponible
      à tous les niveaux de zone de 1 à 60 ; chaque base peint au moins un pixel.
      Capture de la galerie, et une capture du sac avec trois paliers d'une même
      lignée côte à côte — c'est elle qui dit si on les distingue.
- [ ] **6. Le niveau de zone.** La mise à l'échelle et sa duplication de fiche,
      l'expérience bornée, le choix depuis l'écran de génération, l'affichage au
      bandeau. Tests : un ennemi de niveau 40 a la vie attendue **et le `.tres`
      partagé n'a pas bougé** ; l'expérience d'un écart de vingt niveaux est
      bornée ; e2e — une zone de niveau 30 ne lâche que des objets de niveau 30,
      et deux zones de même graine et de niveaux différents ont la même carte.
      Remesure du banc de stress.
- [ ] **7. Alt.** Les colonnes de tier et de plage, la borne de largeur, la
      lecture de l'état réel de la touche. Capture avec Alt maintenu sur un objet
      à quatre affixes, et une capture d'un objet chargé depuis une sauvegarde de
      version 1 — celui qui n'a pas de tiers à montrer.

### Ce que l'étape 2 a changé au plan

- **Le filtre de disponibilité vit dans le catalogue**, pas dans la table de
  butin : `ItemCatalog.disponibles(niveau)`. C'est le catalogue qui sait ce
  qu'il contient, et `LootTable` n'a qu'à tirer dans ce qu'on lui donne — c'est
  là que la règle des deux meilleurs paliers viendra se poser à l'étape 5, sans
  toucher au tirage.
- **Un fichier de référence par version, pas un seul.** La v1 prouve qu'on lit
  encore les sauvegardes déjà sur les disques ; il fallait une v2 pour continuer
  de prouver ce que la v1 prouvait — qu'un champ n'a pas été renommé des deux
  côtés à la fois, ce que l'aller-retour en mémoire ne voit jamais. Le LISEZMOI
  des fixtures dit maintenant quand en ajouter un, et que retirer le plus ancien
  est une décision et non un nettoyage.
- **Aucune branche de version dans la lecture d'un objet.** « Niveau 1 pour une
  sauvegarde de version 1 » s'écrit sans tester le numéro : un champ absent vaut
  son défaut, ici comme partout ailleurs dans `depuis_dict`. Le numéro ne sert
  qu'à refuser ce qu'on ne sait pas lire — c'est ce qu'il a toujours fait, il
  compare maintenant à une liste au lieu d'une égalité.
- **`Game.niveau_de_zone` existe et vaut 1 partout** : personne ne le pose
  encore. C'est voulu — le consommateur avant le réglage, sinon l'étape 6
  arriverait avec un écran de choix branché sur rien.
- **Le niveau s'affiche toujours**, sous le nom et au-dessus de l'implicite,
  dans un gris plus effacé que celui-ci : c'est une étiquette, pas une ligne de
  statistique. Vérifié sur capture — la bulle d'une épée à trois affixes tient
  et se lit.

### Ce que l'étape 1 a changé au plan

- **`armour` est posée, `heavy` et `light` ne le sont pas.** Le §3.3 les
  annonçait toutes les trois ; aucun affixe existant ne lit les deux dernières,
  et une étiquette que personne ne lit est une règle qu'on croit appliquée.
  Elles arriveront avec l'esquive, à l'étape 4, en même temps que les lignées
  légères de l'étape 5.
- **La baguette tombe à deux affixes possibles**, `cruel` et `sanglant` — et les
  tirs ne critiquent pas : `Projectile` construit son `DamageInfo` avec
  `is_crit` à faux, en dur. C'est donc à cette étape la base la plus pauvre du
  jeu : deux affixes, tous deux sans effet sur elle. C'est le prix de
  l'exclusion, il est temporaire, et c'est l'étape 4 qui la repeuple — vitesse
  d'incantation, dégâts de sort, mana, résistances. Faire critiquer les sorts
  est une décision à part, qui n'est dans aucun périmètre pour l'instant.
- **`spell_damage` naît avec la valeur qui était dans le nœud** (7), déplacée
  dans `player_stats.tres`. `bolt_damage` a disparu ; `bolt_cooldown` et
  `bolt_mana_cost` restent des `@export` du joueur, parce que rien ne demande
  encore qu'un objet les touche.
- **`fits(null)` rend désormais faux.** Il rendait vrai dès que la liste était
  vide, ce qui faisait passer « pas de base du tout » pour « partout ». Aucun
  appelant ne s'y appuyait, et le test l'écrit maintenant noir sur blanc.
- **`preste` a quitté la ceinture**, comme prévu. Celle-ci garde `vigoureux` et
  `robuste` : deux affixes, exactement le minimum que le test du catalogue
  exige. Elle attend l'étape 4 elle aussi.

---

## 9. Ce qui peut mal tourner

- **Monter `Personnage.VERSION` sans écrire la lecture de l'ancien format.**
  C'est la faute la plus coûteuse du jalon : tous les personnages existants
  passent « illisibles » d'un coup, alors que leurs fichiers sont intacts. À
  écrire à l'étape 2, avec son test, avant tout le reste.
- **Écrire la mise à l'échelle dans la fiche partagée.** Le `.tres` d'un
  archétype est partagé par tous ses exemplaires, et l'éditeur peut graver le
  résultat sur le disque. Un grunt de niveau 40 dans une zone, puis retour au
  niveau 1 : tous les grunts gardent leurs huit fois la vie, y compris dans les
  tests.
- **Une échelle de tiers dont le plus bas exige plus que le niveau 1.** L'affixe
  disparaît des premières zones, et sa première sortie ressemble à un ajout de
  contenu. Le test de couverture à niveau 1 est là pour ça.
- **Le niveau d'objet déduit du niveau du joueur.** La chaîne du §2 n'a qu'une
  entrée. Le jour où « le joueur est niveau 40, donnons-lui de bons objets »
  paraîtra raisonnable, tout le jalon aura été annulé.
- **La dilution des bases.** Trente bases tirées uniformément, c'est une chute
  utile sur cinq. La règle des deux meilleurs paliers est ce qui empêche ça, et
  elle doit être écrite en même temps que les bases — pas après avoir constaté
  que le butin ne veut plus rien dire.
- **Trois paliers qui se ressemblent dans le sac.** Le nom ne suffit pas : on ne
  lit pas le nom d'un objet au sol, et à la taille d'une case on reconnaît une
  forme et une couleur. C'est la capture qui tranche, pas l'intention.
- **L'expérience non bornée.** Huit fois la vie, c'est huit fois l'expérience :
  sans le plafond du §6.3, la zone profonde devient la façon rapide de monter, et
  plus personne ne joue les niveaux intermédiaires.
- **Deux vérités sur ce que vaut une base.** L'implicite dit ce que la base
  apporte, le palier dit qu'elle est meilleure. S'ils se contredisent — un
  troisième palier dont l'implicite est plus faible — rien ne le signale en jeu.
  D'où le test de monotonie de lignée.
- **L'infobulle Alt qui invente un tier.** Un objet chargé d'une sauvegarde de
  version 1 n'a pas de tier. Le déduire de sa valeur serait faux une fois sur
  trois, les fourchettes de deux tiers voisins se chevauchant. Pas de colonne
  vaut mieux qu'une colonne fausse.
- **Le filtre par étiquettes qui redevient un filtre par identifiants.** La
  tentation viendra à la première base qui doit tirer « presque comme les
  autres ». Une base qui a besoin de son propre `id` dans un affixe est une base
  à qui il manque une étiquette.
- **Le nombre de `.tres` à saisir.** Deux cents lignes de tiers et trente bases,
  c'est le vrai coût du jalon, et il tombe sur les étapes 4 et 5. Si l'une des
  deux déborde, on réduit le nombre de paliers ou de tiers — jamais le nombre
  d'étapes validées.
