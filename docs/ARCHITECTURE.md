# Architecture

Ce document dit **où vit chaque règle** et **ce qu'on ne peut pas casser**. Les
`JALONS/hack-n-slash-jalon-*.md` disent ce qu'il fallait construire et pourquoi,
dans l'ordre où ça a été décidé ; celui-ci décrit l'état actuel, sans
chronologie.

## Le postulat

**Tout ce qui bouge est calculé par du code.** Les sprites d'acteurs et le
TileSet n'existent pas sur le disque : ils sont peints au premier appel, puis
gardés en cache pour la session. Une exception depuis le jalon 25 : un personnage
joueur peut venir d'une **planche de trois poses** (`art/characters/`), que la
forge anime et arme elle-même. « Calculé » ne veut pas dire « déduit d'une
formule » : les trois acteurs du jeu sont des **grilles de pixels écrites à la
main** dans `SpriteForge.ART`, que le code colorie et anime. L'assemblage de
capsules éclairées qu'on trouve dans `_draw_front` / `_draw_side` reste pour ce
qui n'est pas un personnage, et pour un archétype qu'on n'a pas encore dessiné. Une graine dérivée du nom et du numéro de
variante fait que le même personnage ressort identique à chaque lancement.

Ça a deux conséquences que rien d'autre dans le projet ne rappelle :

- **ajouter un acteur ou une tuile, c'est écrire une fonction**, pas importer un
  fichier — voir [RECETTES.md](RECETTES.md) ;
- **la génération procédurale est une règle de jeu**, pas une commodité. La
  silhouette d'un ennemi se déduit de sa case d'apparition, pas d'un tirage :
  c'est ce qui fait qu'une graine de zone redonne exactement le même combat.

La porte de sortie existe : `[S]` dans la forge (F4) exporte toutes les planches
en PNG, retouchables dans un éditeur d'image.

**Par-dessus tout ça vit une couche de lumière**, et c'est elle qui décide de
l'allure du jeu autant que les sprites : un `WorldEnvironment` par scène jouée
(`world/zone.tscn`, `world/test_arena.tscn`) portant `fx/bloom.tres`, dont le
glow fait déborder **ce qui dépasse 0,9 de luminance**. C'est un seuil de valeur
et non un calque : rien ne peut s'en exclure. Il tient parce que le plus clair
pixel d'un sprite est à **0,88** — le cristal du caster — et que le haut de la
rampe d'`ArtPalette` est plafonné pour le rester : 0,02 de marge. Les trois textures de `fx/glow.gd` existent
précisément pour donner aux effets le cœur presque blanc qui passe ce seuil.

**Ce qui ne bouge pas fait exception** : les tuiles de décor (`art/tiles/atlas.png`,
six tuiles de 32 px produites par `tools/tiles.py`) et les icônes de compétences
et d'objets sont des PNG de `resources/icons/`, branchés sur un champ du `.tres`
(`Skill.icon`, `ItemBase.icon`) et produits hors du jeu — voir
[le LISEZMOI du dossier](../resources/icons/LISEZMOI.md). Une image immobile se
juge une fois ; un sprite qui s'anime dans quatre directions et cinq variantes,
non. **Le champ vide reste un état normal dans les deux cas** : sans image, la
forge dessine l'objet et la barre dessine un disque, donc rien ne casse en
attendant l'image.

## La carte

| Dossier | Ce qu'on y met | Connaît |
|---|---|---|
| `core/` | Les règles et les données du jeu. Aucun dessin, presque aucun nœud. | rien du reste |
| `art/` | Le rendu procédural : rastériseur, forge de sprites, galerie de réglage. | `core/` |
| `world/` | La carte, le champ de chemin, le peuplement, la scène de zone. | `core/`, `art/`, `actors/` |
| `actors/` | Ce qui bouge : joueur, ennemis, projectiles, objets au sol. | `core/`, `art/` |
| `ui/` | Les panneaux et l'affichage tête haute. | `core/`, `art/` |
| `fx/` | Le retour visuel des coups. | `core/` |
| `tests/` | La campagne GUT — voir [tests/README.md](../tests/README.md). | tout |
| `tools/` | Les outils hors jeu : génération de la documentation, banc d'équilibrage. | tout |
| `resources/` | Les `.tres` : bases d'objets, affixes, fiches d'archétypes, **manuels, compétences, passifs et arbres de talents**, l'arbre de passifs (`passive_tree.tres`). | — |

**Le sens de circulation ne s'inverse jamais.** `core/` ne remonte pas vers une
scène, un nœud ou un panneau. C'est ce qui permet à la moitié de la campagne de
tourner sans arbre de scène, et c'est le premier symptôme à surveiller : un
`preload` d'une `.tscn` dans `core/` est une régression d'architecture.

**Deux exceptions assumées**, et elles sont dans `core/` parce que c'est là que
vit la règle qu'elles appliquent :

- `core/hurtbox.gd` est une `Area2D`. Elle est le **point de passage unique de
  tous les coups du jeu**, et la mitigation qu'elle applique est écrite dans
  `CharacterStats`, à côté.
- `core/settings.gd` est un autoload `Node`. Il porte les réglages du joueur, pas
  l'état de la partie — ce dernier est dans `Game`.

Les déplacer réécrirait des chemins `res://` dans quatre `.tscn` et dans les
autoloads pour zéro gain de comportement. Décidé : on ne les déplace pas.

## Les feuilles

Ces classes ne dépendent de rien. C'est volontaire : GDScript refuse les cycles
de dépendances, et chacune est née d'un cycle qu'il fallait casser.

| Classe | Pourquoi elle est seule |
|---|---|
| `DamageType` | `CharacterStats` nomme ses résistances par nature, et `DamageInfo` nomme déjà `CharacterStats`. |
| `WeightedRoll` | `ItemAffixPool` précharge les `.tres` d'`ItemAffix` ; un `ItemAffix` qui appellerait la réserve refermerait la boucle. |
| `Keys` | Sept scènes lisent le clavier, aucune n'a à connaître les six autres. |
| `ArtPalette`, `UiPalette` | Les couleurs — et le matériau additif d'`ArtPalette` — sont lues par tout le monde et ne lisent personne. |
| `Texts` | La traduction est demandée par les tables de libellés, par le contenu et par les panneaux : elle ne peut nommer aucun des trois. |
| `Keywords`, `SkillStats` | `StatMod` y lit le nom de ce qu'une ligne portée vise, et `Skill` applique des `StatMod` : qu'elles nomment l'une ou l'autre, et la boucle se referme. |
| `LegacyFrench` | `Character`, `SaveStore` et `Settings` la lisent pour relire le disque d'avant ; une table figée n'a rien à nommer. |
| `StatusEffects` | `DamageInfo` le nomme pour dire qui frappe, et `Hurtbox` pour ce que porte la victime : il reçoit des parts et un auteur, jamais un coup. |
| `SpawnSeed` | La graine d'un point d'apparition est lue par l'ennemi, le caster et le sprite : elle ne peut connaître aucun des trois. |

## Où vit chaque règle

| La question | La réponse |
|---|---|
| Combien un coup fait-il vraiment ? | `CharacterStats` (armure, esquive, résistances ; la défense d'une part, `mitigate()`), appliqué **part par part** par `Hurtbox` : l'armure sur la part physique, sa résistance à chaque autre nature — moins ce qu'une malédiction retire, **avant le plafond** (`StatusEffects.resistance_lost()`, lu au coup et jamais écrit dans la fiche) —, puis `damage_taken` sur toutes — l'abri du Tombeau de glace, qui n'est pas une résistance et ne choisit donc pas sa nature —, et le plancher sur le total |
| Quels objets tombent dans une zone ? | `ItemCatalog.available()` |
| Comment un ennemi monte-t-il avec la zone ? | `CharacterStats.scale_to_level()` : la vie **composée** de `HEALTH_PER_LEVEL` par niveau ; les dégâts, l'armure et les cinq résistances linéaires ; l'esquive jamais. `Enemy.sheet_of()` y ajoute les affixes, sur une copie. L'expérience suit la vie (`Enemy.xp_from_health()`) |
| Jusqu'à quand une base tombe-t-elle ? | `ItemCatalog.drop_window()` |
| Quels affixes une base peut-elle porter ? | `ItemAffix.fits()` via `ItemAffixPool.compatibles()` : les étiquettes, puis **une pièce d'armure ne tire que sa propre défense** (`ItemBase.defense_stat()`) — pas d'esquive sur une cuirasse |
| Comment un implicite se tire-t-il ? | `Item.rolled()`, par où passent le butin et le banc : les affixes, puis `ItemBase.roll_implicit()` — une position de 0 à 1 dans `implicit_value`–`implicit_roll_max`, aucun tirage pour une base fixe (invariant 3). **L'objet garde la position, pas la valeur** (`Item.implicit_roll`, sauvegardé sous `base_roll`) : `ItemBase.implicit_at()` la relit, si bien qu'un rééquilibrage de la plage atteint les objets déjà tombés. Absente, 0 : le bas, l'ancienne valeur fixe. Pas pour les dégâts ajoutés. L'établi pose le haut. L'infobulle détaillée écrit l'implicite et sa plage ; pour une défense, dont la propriété montre le total, l'implicite n'apparaît qu'en détails |
| Quels paliers un objet atteint-il ? | `ItemAffix.unlocked_tiers()` |
| Combien d'affixes sur un objet neuf ? | `ItemAffixPool.COUNT_WEIGHTS` |
| Quelle rareté ? | `Item.rarity()`, **déduite** du nombre d'affixes |
| Comment se lit la fiche d'une compétence ? | `ManualPanel._skill_sheet()` monte **une seule liste** de `SheetLine` groupées, `_sheet_height()` la mesure et `_draw_sheet()` la dessine : le nom, les mots-clés du geste résolu, **le paragraphe de `Skill.description`** — ce qu'elle fait, jamais ses nombres —, puis, **si elle frappe** (`Skill.strikes()`, sa table de dégâts et rien d'autre), les blocs : ceux de `GROUP_TITLES`, et **un par `SkillBuff` posé, sous son nom** (`SheetLine.heading`, qui ouvre un bloc comme le fait un changement de groupe). Chaque intitulé prend sa majuscule dans `SheetLine._init()`, **à la construction et non au dessin** : c'est ce que les tests de largeur mesurent. Tout y est **serré d'un pixel** (`SHEET_LINE`, `SHEET_PROSE`, `TITLE_BAND`) : la plus haute du jeu tient à trois pixels près au-dessus des jauges, et `test_the_sheet_stays_in_frame` le vérifie sur chaque case |
| Comment se lit l'infobulle d'un objet ? | `InventoryPanel._tip_lines()` monte la liste des blocs — nom sur bandeau de rareté, propriétés de la base, niveau, implicite, affixes —, `_draw_tooltip()` la mesure puis la dessine. **Une seule liste** : deux passes écrites à la main divergeaient à chaque ligne ajoutée. Les lignes d'implicite et d'affixe prennent une majuscule par `RichText.capitalized()`, qui saute la marque du glossaire |
| Comment un objet s'appelle-t-il ? | `Item.display_name()` : le nom de la base, plus le `suffix` de l'affixe au **meilleur palier** — « Épée de l'Agilité ». Rien sans affixe de provenance connue |
| Où va un objet équipé ? | `EquipmentSlots.free_for()` |
| Ce qui tient dans le sac ? | `Inventory.fits()` |
| Que devient l'objet déjà en place ? | `InventoryPanel._swap_in()` : **ils permutent** si le délogé entre dans la case que l'autre vient de quitter, sinon il passe en main. Deux objets sous la pose (`Inventory.lone_blocker()` rend `EMPTY`) : rien ne bouge — on ne déloge pas deux objets pour en poser un |
| Comment jeter sans passer par la main ? | **Ctrl + clic droit** dans le sac ou sur un emplacement, `InventoryPanel._drop_hovered()` |
| À quoi ressemble un objet ? | `SpriteForge.inventory_icon(base, place)` dans le sac, `ground_icon(base)` au sol (`GROUND`, sous le cadre de travail : c'est le nom au-dessus qui identifie) : l'image de `ItemBase.icon` si la base en a une, sinon le dessin de la forge d'après son `kind` et son palier. `ghost_icon(kind, place)` est le troisième chemin, celui d'un **emplacement vide** — il n'y a pas d'objet, donc pas d'image. Les trois passent par `_fit()` : agrandissement d'un facteur **entier**, réduction au ratio exact |
| À quoi ressemble un personnage joueur ? | (jalon 25) Les deux classes, **Vive lame** et **sorcière**, sont des **planches** : `art/characters/<archétype>.png` et ses repères dans `.json`, produits hors du jeu par `tools/character_forge.py`. L'archétype `player`, en grilles, ne sert plus qu'aux icônes d'objets et à la galerie. Rangée 0 : trois poses fixes (face, profil, dos) — ComfyUI (IPAdapter pour l'identité, OpenPose pour la vue), détourage, recoloration, **retouches à la main** (le visage). Puis une rangée par geste et par vue : **la marche (4 images), le coup d'épée (3) et le lancer (3) sont générés** — l'arme suit l'équipement, donc chaque classe a les deux attaques —, chaque cycle en une seule image pour que le personnage reste le même, ramenées sur la palette de la pose et retouchées pareil. `SpriteForge._draw_sheet()` les joue telles quelles, avec **la main armée de chaque image** (`anims.<geste>.hands`, calculée sur le squelette), et n'anime lui-même que le souffle du repos (`SHEET_BREATH`). Case de 48, remontée de 10 px par `SpriteForge.offset_of()` pour que les pieds tombent sur la collision. **Ce qui se cale sur la tête** — barre de vie, nombres de dégâts, nom d'état, butin — monte de `SpriteForge.head_room()`, ce que le corps dépasse le guerrier par le haut, lu sur l'image de repos : `HealthBar.lift` et `Hurtbox.feedback_lift`, posés par `Player.load_character()`, et `Hurtbox.overhead()` d'où partent les textes. La collision ne change pas. Les écrans qui montrent un personnage (vignettes de création, liste, poupée du sac) le posent **par les pieds** et ont la hauteur d'une case de 48. Mesuré en jeu, avant l'ajout du lancer : 33 images en 13,9 ms, contre 5,2 ms pour les 24 de l'ancien guerrier en grilles — une fois par arme et par silhouette. Recette : [tools/characters/LISEZMOI.md](../tools/characters/LISEZMOI.md) |
| Quelle classe a un personnage ? | `Character.character_class`, une clé de `Character.CLASSES` — qui donne l'archétype de la forge (`Character.archetype()`, appliqué par `Player.load_character()` via `ActorSprite.set_archetype()`) et le nom affiché : **Vive lame** (`swiftblade`) et **sorcière** (`witch`). Choisie à la création (`CharacterSelect.LOOKS`, une tenue par classe) ; **rien d'autre ne change encore** qu'`SaveStore.create()`, qui met la baguette en main de la sorcière et l'épée au sac. Sauvegardée en `class` (v8) ; absente, une Vive lame ; `warrior`, le nom des premières v8, aussi (`LEGACY_CLASSES`) ; inconnue, le fichier est refusé |
| À quoi ressemble un acteur ? | `SpriteForge.ART[archétype][direction]` quand il y est — un corps, trois paires de jambes et le poignet armé, en caractères traduits par `INK` (minuscule = ombre, majuscule = base, troisième lettre = lumière) —, sinon l'assemblage de capsules de `_draw_front` / `_draw_side`. Dans les deux cas le **contour** est posé après coup par `PixelCanvas.to_image()` sur la silhouette entière, et **l'arme reste procédurale** (`_weapon()`), parce qu'elle suit l'équipement. **Les quatre ennemis du jalon 27** — chevalier bélier (`charger`), gobelin cuivré (`mortar`), champignon (`bloater`), colosse (`brute`) — sont des **planches**, comme les classes jouables : même outil (`tools/character_forge.py`), case de 48, sans arme (`weapon` `none`) et avec les seuls gestes dont leur attaque a besoin. Une planche ne varie pas : `SpriteForge.frames()` ramène toute variante à 0, une fabrication par archétype. Leur barre de vie, leurs nombres et leurs affixes montent de `SpriteForge.head_room()`, posé par `Enemy._ready()` |
| À quoi ressemble une zone ? | `MapGenerator`, un automate cellulaire réglé par `DEFAULT_FILL` **0,37** et `DEFAULT_ITERATIONS` **6** — une grande aire dégagée, 17 éperons rocheux de 20 cases de médiane, **62 % du sol à quatre tuiles ou plus du premier mur**. C'est ce dernier chiffre qui dit « on peut tourner autour d'un ennemi » ; il valait 13 % du temps des cavernes (`fill` 0,45). Le même automate donne les deux : tout est dans `fill_chance`. L'écran de réglage (`F3`) part de ces constantes, il ne les recopie pas |
| Combien d'ennemis dans une zone ? | `EnemySpawner`, **14 paquets** de 3 à 7, et non une densité : ouvrir la carte ne change donc pas la population (68 à la graine 4242, `test_a_seed_gives_the_same_zone_again`), seulement son étalement |
| Qui peuple une zone ? | `EnemySpawner.POPULATION`, la seule table : scène → poids. Grunt 50, caster 17, chargeur 9, gonfle 9, mortier 8, colosse 7 (jalon 27), dès la zone 1. Le banc d'équilibrage la lit pour l'expérience d'une zone (`BenchProfiles.zone_experience()`) ; ses couloirs, eux, ne modèlent encore que le grunt et le caster |
| À quoi ressemble le sol ? | `TilesetBuilder._texture()` : l'atlas de `art/tiles/atlas.png` s'il existe, sinon la peinture procédurale de `_atlas()`, qui reste la **référence des couleurs**. Quatre sols, un mur, un mur à dessus éclairé — et c'est le code, pas l'image, qui décide lequel est éclairé et de combien. `tools/tiles.py` ramène la matière d'un rendu ComfyUI aux valeurs du jeu : `FLOOR_LUM` **0,150**, plus bas que les 0,196 de la couleur de base, parce qu'à moyenne égale une pierre appareillée se lit plus claire qu'un aplat |
| Qu'est-ce qui brille à l'écran ? | Le glow de `fx/bloom.tres` (un `WorldEnvironment` par scène jouée), **au-dessus de 0,9 de luminance** : les cœurs d'effets, les éclairs, le texte blanc. Le jeu reste en LDR — `rendering/viewport/hdr_2d` linéarise le canevas et divise le sol par 5 (mesuré 71 → 14), voir `JALONS/hack-n-slash-jalon-24.md` §5. Le coût est de **0,05 ms de GPU par image** |
| À quoi ressemble la foudre ? | **Dessinée**, plus tracée (jalon 25) : `fx/lightning.gd` **et lui seul** — la chaîne, les éclairs du nuage, la charge statique, le projectile. Le **fil cerné**, choisi sur planche : un corps de trois pixels poussé en haut de sa rampe (`Holy.LIT`, une lumière n'a pas de dessous), un filament d'un pixel presque blanc (`PixelCanvas.line()`, sans trou en biais), deux fourches, et l'éclat d'impact `EffectForge.STRIKE` estampé **dans** la silhouette. Le violet plafonne à **0,63 de luminance** : seul le filament (0,92 vers le blanc) passe le seuil de glow. Un éclair part dans n'importe quelle direction : `Lightning.chain()` le **rastérise à l'angle exact**, **une planche par saut** — d'une pièce, une chaîne en zigzag faisait balayer à `to_image()` le vide entre ses sauts, 2,2 ms pour trois sauts contre **1,3 ms** découpée (2,1 au pire : quatre sauts à portée maximale, en diagonale). Refait à chaque battement (`Lightning.hold`, 18 Hz : une forme par image n'est plus un éclair, c'est du bruit), et **dissous** sur son dernier tiers (`Lightning.gone`), jamais pâli. Ce qui a une taille fixe est fabriqué une fois et gardé : le projectile au cap le plus proche (`Lightning.dart`, trente-deux caps × quatre formes, 0,12 ms), qui **ne tourne plus** ; la charge statique, étoile brisée à six bras jusqu'au rayon qui mord, six formes qui bouclent (`Lightning.charge`, 0,14 ms). Le **corps du nuage** est à `StormCloud.body()` : sept bosses rastérisées d'un coup, gardées par rayon ; sa zone est le halo tramé `EffectForge.scorch()`. Le buff (Électricité statique, Appel du tonnerre) est celui du sacré, avec `EffectForge.lightning_speck()` pour grain. Rien de la foudre n'est plus additif |
| À quoi ressemble la nécrose ? | **Dessinée** (jalon 26), choisie sur planche geste par geste : `fx/necrotic.gd` pour la couleur — la teinte, un cœur **jaune maladif** (`Necrotic.SICK`), et une troisième rampe (`EffectForge.R_SHADE`, encre `INK_SHADE`) pour ce qui a un dedans : l'ombre des orbites, la chair d'une faille. **La nécrose ronge, elle n'éclaire pas.** Planches dans `EffectForge` : le **crâne de fumée** de la Peste (9×8, quatre temps, orbites qui palpitent) et sa traînée de fumées déjà dissoutes (`fumes()`), la **faille de chair** debout de la Porte (9×16, trois temps, qui s'ouvre et se referme en se **découpant**), la **bulle à yeux** qui en sort (7×7, deux temps), l'**œil** de la Malédiction (21×9 : fermé, entrouvert, ouvert), la **spore** de la Nécrose. Deux anneaux se **rastérisent** et se gardent par rayon et par cran : le **mur de gaz** bosselé de la Déferlante et des créatures qui explosent (`Necrotic.miasma()`, huit crans pour toute l'onde), le **cercle épais** de la Malédiction (`ring()`) sur sa nappe tramée. Tous deux passent par `_band()` : des capsules d'un point au suivant — des disques prenaient chacun leur éclairage, un collier de perles —, peintes **en quatre quadrants** coupés aux axes, chacun un pixel plus large puis rogné, pour ne pas balayer le vide du milieu sans laisser de couture. Mesuré au premier passage d'un rayon : **2,1 ms** le pire cran du mur au rayon 48 (12,5 ms l'onde entière, sur ses 0,3 s), **1,1 ms** un cran du cercle ; rien ensuite. Le mort-vivant est un squelette en grilles (`SpriteForge.UNDEAD_*`, archétype `undead`) : l'os le sépare du grunt vert |
| À quoi ressemble le feu ? | **Dessiné**, plus tracé (jalon 24) : les grilles dans `EffectForge` — la langue (9×13, quatre temps), la petite (5×8), la boule (13×13, six temps), la bouffée, l'éclat en étoile, la brûlure au sol — et `fx/fire.gd` pour ce qui reste de couleur : `WARM`, `heart()`, et la braise d'Ignition, **seul geste du feu encore tracé**. Le cœur d'une flamme est le seul endroit où le feu a le droit d'être presque blanc (0,92 de luminance, le seuil de glow est à 0,9) ; son orange seul plafonne à 0,57 et ne déborde jamais |
| À quoi ressemble la glace ? | **Dessinée**, plus tracée (jalon 24) : les grilles dans `EffectForge` — le cristal (9×15 et 5×9), l'éclat en huit orientations, le flocon, le bloc du Tombeau (21×29) —, et `fx/frost.gd` pour **la poser** : `raise_spike`, `chip`, `drift`, plus la règle de couleur. Un cristal est **deux flancs et une arête** : la teinte à deux paliers de rampe et le givre entre les deux. **Le froid ne se blanchit pas, il s'ombre** — son cyan porte déjà 0,81 de luminance, la matière la plus claire du jeu, et déborde sans qu'on y ajoute rien ; l'éclaircir lui retire sa teinte. Et **un cristal ne pâlit pas, il redescend** : posé à demi-transparent sur un sol sombre, le cyan sort gris — le même piège que l'orange peu opaque du feu, qui sortait brun. Ce qui s'efface, c'est le givre au sol et les flocons, faits pour ça ; un tourbillon, lui, **se vide** de ses éclats un à un |
| À quoi ressemble le sacré ? | **Dessiné** (jalon 24) : `fx/holy.gd` pour la couleur et la pose, `EffectForge` pour les grilles — le grain de trois pixels, la tranche de colonne du Pilier et sa pointe. Un seul blanc, **mesuré** : à 0,70 vers le blanc le rose monte à 0,91 de luminance et passe le seuil de glow, en dessous il n'éclaire rien ; il vivait avant dans trois fichiers à trois valeurs (0,55, 0,60, 0,80), le même désordre que les quatre blancs chauds du feu. Le trait de Frappe sacrée est le seul geste **rastérisé à la volée** — il part dans n'importe quelle direction, et une planche ne pivote pas —, une fois à sa naissance et jamais plus, 1,16 ms mesurées pour le pire cas. **Une lumière n'a pas de dessous** : ses volumes sont poussés en haut de la rampe (`Holy.LIT`), sans quoi la capsule leur donne un flanc mauve sombre et le trait se lit comme un os |
| À quoi ressemble le coup d'arme ? | **Dessiné** (jalon 24) : `fx/slash.gd` fabrique chaque forme **au cap où on la demande** — trente-deux caps —, une fois, et la garde : le croissant (`crescent`, lourd en tête quand il balaie, épais au milieu quand il vole), l'entaille droite (`stroke`), l'épée tournée (`sword`, grille `EffectForge.SWORD`). **Tout ce manuel pivote**, et une planche tournée se rééchantillonne : les formes géométriques se rastérisent donc au cap, l'épée dessinée à la main s'y tourne par `EffectForge.rotated()` — neuf échantillons par pixel et un vote, sans quoi une lame d'un pixel se casse en pointillés en biais. Mesuré au premier passage par un cap : croissant 0,9 ms, lame du cyclone 0,6, épée 0,8, entaille 0,3 ; les suivants ne coûtent rien. Le temps d'un coup est arrondi à l'un de ses huit temps, sans quoi rien ne se retrouverait dans le cache. `SwingArc` et `SlashWave` défont leur rotation et posent le dessin du cap le plus proche |
| Un effet est-il dessiné ou fabriqué ? | Les deux. **Tracé** en polygones dans son `_draw()` pour ce qui reste du sacré et du physique hors de leurs manuels ; **dessiné** pixel par pixel dans `EffectForge` pour les manuels de **feu**, de **glace**, du **sacré** et du **maître d'armes**, entiers (jalon 24), de la **foudre** (jalon 25) et de la **nécrose** (jalon 26). **Trois chemins**, et c'est la *taille* qui tranche : une **planche d'animation** image par image (la boule de feu, six temps ; l'éclat d'un souffle, trois) pour ce qui a une taille fixe et ne tourne pas ; des **planches uniques** replacées à la main (langue, cristal, éclat, flocon, brûlure, halo tramé) pour ce qui se répète à toute taille — brasier, couronne d'explosion, sillon de Ruée, bras de tourbillon, dont le rayon ou la longueur sont des statistiques ; une **rastérisation par image** dans `PixelCanvas` pour ce qui change de forme — le corps du serpent, 0,58 ms mesurées, donc refaite à 30 Hz et non 60. Mesuré dans le même carré de 18×26 : 82 couleurs et **aucun pixel de contour** pour la langue en polygones, 40 et 4,3 % pour la planche forgée, quand un ennemi en compte 29 et 12,5 %. Trois règles tiennent tout : une planche se pose sur une coordonnée **entière** (`EffectForge.snap()`, le seul endroit) ; elle **ne peut pas être additive**, puisqu'un contour sombre n'ajoute rien ; elle **ne tourne ni ne se redimensionne** — ce qui doit s'orienter est dessiné dans chaque sens (`EffectForge.chips()`, huit) ou fabriqué au cap (`Slash`, trente-deux), ce qui doit croître se **découpe** au lieu de s'étirer (`Frost.raise_spike()`). Et rien de dessiné ne **pâlit** : ce qui s'efface se dissout en damier après son contour (`EffectForge.dissolve()`, par un masque de Bayer natif — un `set_pixel()` par pixel coûtait 1,1 ms sur un anneau de 113 px), rentre sous terre ou se résorbe |
| Comment un effet de compétence est-il dessiné ? | Dans son `_draw()`, en blend additif partagé (`ArtPalette.ADDITIVE`), avec les trois textures de `fx/glow.gd` — `draw_blob` un cœur, `draw_ring` un bord mou dont la crête tombe sur le rayon qui mord, `draw_streak` une comète dont la tête est sur `from`. Le dégradé de chacune a un **plateau** au maximum : sans lui aucun pixel n'atteint 1,0 et l'effet passe sous le seuil de glow |
| Où l'arme d'un personnage est-elle dessinée ? | `SpriteForge._weapon()`, d'après `ItemBase.kind` — **le même champ** que le dessin de repli de l'icône. Une image d'objet ne le remplace pas : `test_each_base_has_a_non_empty_icon` vérifie les deux |
| Comment s'écrit une valeur à l'écran ? | `StatMod.format()` / `gauge()` / `range_label()` ; des dégâts résolus, `SkillStats.readable_range()` ; un pourcentage, `StatMod.percentage()`, dont la typographie suit la langue |
| En quelle langue s'écrit un texte ? | `Texts.t()`, dans la fonction qui **lit** le libellé — jamais chez celui qui le dessine. Le texte français est la clé ; l'anglais vit dans `i18n/en.po`, et `Settings.language` choisit |
| Jusqu'où descend une fenêtre flottante ? | `Hud.gauges_top()` : les jauges sont dessinées après les panneaux, et passeraient par-dessus. **« Niv. » et l'indicateur de points d'arbre compris** |
| Ce que rapporte un ennemi ? | `Enemy.experience_of()`, dérivé de ses PV donc du niveau de sa zone — **sans borne haute** |
| Quel niveau a un personnage qui arrive dans une zone ? | `BenchProfiles.expected_level()` : chaque zone d'avant vidée une fois, avec la population moyenne de l'`EnemySpawner`, borné par `Player.MAX_LEVEL`. Une mesure du banc, pas une règle du jeu ; une case équipée y lit la médiane de `BenchCalculation.ITEM_DRAWS` tirages (`measure_profile()`) |
| À quel point un personnage type s'en sort-il ? | `BenchCalculation.measure()`, sur un vrai `Player` : `Player.resolve()` pour ce qui part, `Hurtbox.mitigate_part()` pour ce qui arrive. Les couloirs sont ses constantes, gardés par `tests/run.sh balance` ; le rapport, `tools/balance.sh` → [EQUILIBRAGE.md](EQUILIBRAGE.md) |
| Quand l'expérience fond-elle ? | `Enemy.experience_factor()` : sur une zone laissée **derrière** soi, jamais sur une zone trop haute |
| Par où passe un ennemi ? | `FlowField`, à défaut la ligne droite. La marche d'approche — champ vers le joueur, ligne droite vers un mort-vivant, séparation — est `Enemy._close_in()`, partagée par le grunt et les quatre du jalon 27 |
| Comment un ennemi prévient-il de son attaque ? | (jalon 27) Par une **`DangerZone`** au sol, un seul signal pour toutes les attaques, choisi sur planche : le plein monte du départ jusqu'au bord, et **quand il l'atteint, elle frappe elle-même** — l'obus tombe même si le mortier est mort. Trois formes : disque (obus du mortier, éclatement du gonfle), couloir (charge du chevalier, qui ne frappe pas : c'est la charge qui touche) et cône (colosse). Un disque frappe par `Explosion.put()` — le souffle dessiné de sa nature, feu ou nécrose —, un cône par sa propre requête. Dessinée par `fx/danger_zone.gdshader`, **au pixel du monde** : le nœud ne tourne pas, la forme se calcule dans le sens de `facing`, et `DangerZone.contains()` en est le miroir côté jeu — ce qui est dessiné est ce qui est frappé. Liée à son ennemi (`bound`), elle tombe avec lui. Posée dans `EnemyManager.ground()` — le nœud `Ground` de la zone et de l'arène, entre le sol et les corps —, en différé : le gonfle la pose en mourant |
| Ce qui survit à la fermeture ? | `Character.to_dict()` et `Settings.to_dict()` |
| Quelle touche déclenche une action ? | La table du moteur, jamais un `KEY_*` écrit dans un `if`. Les défauts sont dans `project.godot`, le choix du joueur dans `Settings.key_binds`, et `Keybinds` les réunit. `Keybinds.ACTIONS` liste ce qui se rebinde, avec le libellé de l'onglet |
| Pourquoi deux formes de touche clavier ? | `Keybinds.to_text()` : `key:` est un code de **disposition** — la lettre que le joueur voit —, `pos:` un code de **position**, dont `project.godot` se sert pour que ZQSD tombe où tombe WASD. Tout ramener à `key:` déplacerait un déplacement sur un AZERTY |
| Que devient une touche déjà prise ? | `Keybinds.rebound()` **échange** : l'autre action reçoit celle qu'on quitte. Aucune ne devient muette, et deux n'ont jamais la même |
| Combien de touches par action ? | **Une seule qui compte** : `Keybinds.text_of()` rend la première que `to_text()` sait écrire, et c'est elle que l'onglet montre et que l'échange compare. Un second déclencheur est donc invisible et inéchangeable — les flèches des déplacements sont le seul doublon voulu, et `test_a_skill_slot_has_a_single_trigger` refuse les autres |
| Comment une sauvegarde aux noms français se relit-elle ? | `LegacyFrench` : clés et identifiants des versions 1 à 5, ancien dossier, anciens réglages |
| Ce qu'un lancer fait vraiment ? | `Skill.resolve()`, par `Player.resolve()` — **appelée par le lancement, la page du manuel et la fiche de personnage** : dégâts par nature en fourchette et leur décomposition, projectiles, dispersion, vitesse, coût, intervalle |
| Quelle chance critique a un coup ? | `Skill.resolve()` : **la fiche** (`CharacterStats.crit_chance`), qui ne porte que **la base de l'arme** — `Item.crit_chance()` : `ItemBase.crit_chance` (10 % à l'attaque, 5 % à l'incantation) plus ses plats locaux, fois ses accrus locaux —, fois les accrus du reste — sans portée ou portés. **Hors d'une arme, une chance critique n'est jamais plate** (`test_no_flat_crit_outside_a_weapon`) : implicites d'anneaux, `keen`, nœuds de l'arbre ; une ligne plate relue sur autre chose qu'une arme est retirée par `Character._current_line()`. Les accrus sans portée ne touchent jamais la fiche : `Player.recompute_stats()` les envoie au lancer. Le multiplicateur reste celui de la fiche. Tiré à chaque coup par `DamageInfo.roll()` — coup d'arc, tir, `Targets.strike()` ; un coup sans lancer ne critique pas. La page du manuel lit la chance et le multiplicateur sur ce même lancer |
| Combien une compétence inflige-t-elle en moyenne ? | `SkillStats.average_per_cast()` et `average_per_second()` : si tout touche, avant défenses, sans critique |
| Combien fait un coup parti ? | `SkillStats.roll()` : une fois par projectile, une fois par coup d'épée pour tout son arc, une fois pour une chaîne entière, une fois par impulsion d'un nuage ou d'une aura, une fois par contact d'un serpent ou d'une épée — avec `Game.rng` et **un tirage par fourchette ouverte** |
| Quels mots-clés porte une compétence ? | `Skill.keywords()` : les déclarés, plus ceux que donnent la nature (`KEYWORD_OF_NATURE`, les six — toute attaque est donc « Physique »), la cadence et **la forme** — `KEYWORD_OF_SHAPE` : tir et boule sont `projectile`, frappe, croix, orbite, vague et cyclone `melee`, nuage, aura, serpent, ruée, pics, nova, vortex, pilier et pulsation `area`, relève et portail `summon`, malédiction `curse`. **Le faisceau n'en donne aucun** : ni un tir ni une surface, et lui prêter `area` promettrait un bonus qu'aucun affixe ne tient. `ARC` étant la forme par défaut, le coup d'arme déclare `melee` lui-même. Sur la liste fermée de `Keywords`, et **un mot-clé affiché doit être visé par un affixe** (`test_each_keyword_is_targeted_by_something`). Ceux d'un **lancer** sont dans `SkillStats.keywords`, nœuds d'arbre compris |
| Dans quel ordre se lisent-ils ? | `Keywords.sort_in_order()`, et nulle part ailleurs : ils arrivent de trois sources et deux compétences voisines doivent se lire colonne contre colonne |
| Une ligne d'affixe vise-t-elle la fiche ou un mot-clé ? | `StatMod.scope` — vide pour la fiche. **Un ou deux mots-clés** : `fire spell` exige les deux (`Keywords.covered()`, lu par `Skill.resolve()`) ; les deux qualifient le nom ensemble — « dégâts de sort de feu accrus », « fire spell damage » (`Keywords.qualifier()`). `StatMod.apply_all()` écarte le reste, `Player.recompute_stats()` le range dans `skill_mods`, avec la force changée en dégâts physiques aux attaques |
| Comment des pourcentages se combinent-ils ? | `StatMod.apply()` pour la fiche et les nombres d'un lancer, `Skill.resolve()` pour ses dégâts : plats, puis **la somme des accrus** (`Mode.PERCENT`) d'un champ, puis **chaque « plus »** (`Mode.MORE`) à la suite. Les affixes et les passifs de manuel donnent de l'accru ; le « plus » vient d'une `TalentLine.more` : les lignes `damage` des nœuds de talent et les clés de voûte de l'arbre de passifs. `SkillStats.increased` et `more` gardent les deux facteurs pour la page du manuel |
| Comment s'écrit un pourcentage ? | `StatMod.label()` : « +10 % d'armure **accrue** » — valeur, nom, **terme**, complément (« contre les embrasés »). Le terme dit le calcul et le sens (`StatMod.term_of()` : accru, réduit, amplifié, atténué) et s'accorde par `StatMod.AGREEMENT` / `SkillStats.AGREEMENT`. Une ligne de fiche nommée par son terme : `StatMod.term_label()` |
| Où le mot-clé d'une ligne se place-t-il ? | **Dans la phrase, jamais entre parenthèses au bout.** Les dégâts et les niveaux de compétence le prennent comme **qualificatif** (`Keywords.QUALIFIERS`, par le gabarit `{stat} {qualificatif}` — l'anglais le met avant le nom) : « +25 % de dégâts de feu accrus contre les embrasés ». Tout le reste dit **à qui** il s'adresse (`Keywords.RECIPIENTS`) : « +10 % de rayon accru aux compétences de zone ». `StatMod._qualifies()` tranche entre les deux, et `test_no_content_line_ends_in_parentheses` refuse le repli. **Un mot-clé qui forme avec les dégâts un seul nom** (`Keywords.DAMAGE_NOUNS`, « dégâts continus » → « damage over time ») est traduit d'un bloc : le gabarit anglais le poserait devant le nom |
| Comment un terme du glossaire s'écrit-il ? | `Glossary.term()` **seulement** : le mot accordé et traduit, entouré d'une marque invisible (`Glossary.START`…`END`). Aucune clé de `en.po` n'en contient. `Glossary.plain()` la retire pour ce qui ne se dessine pas en jeu (catalogue, forge, messages de test) |
| Qui dessine une ligne qui peut porter un terme ? | `RichText` — `draw()`, `draw_right()`, `width()`, `fold()` : le terme en gras (la police épaissie), la marque sans largeur. **Toute mesure d'une telle ligne passe par lui**, `test_widths` compris |
| Quand un encadré du glossaire apparaît-il ? | `GlossaryBoxes.draw()`, appelé en dernier par ce qui montre le texte — l'infobulle du sac, la fiche du manuel, l'aide de la fiche — **dès que le texte est affiché**, un encadré par sens. `layout()` cherche à droite, à gauche, dessous puis dessus une place qui ne couvre pas le panneau, dans le cadrage et au-dessus des jauges. L'établi met le terme en gras sans encadré : c'est un outil |
| À quelle cadence se lance-t-elle ? | **Deux nombres que rien ne change ensemble** (jalon 22). `Skill.use_time()`, le temps du geste : celui de l'arme (`CharacterStats.attack_interval()` — `attack_time` / `attack_speed`) à la cadence `WEAPON`, `cast_time` / `cast_speed` à la cadence `CAST`. `Skill.recharge()`, la recharge propre de la compétence : `cooldown` divisée par `CharacterStats.cooldown_recovery` **et par rien d'autre** — ni la vitesse d'attaque ni celle d'incantation n'y peuvent rien. `Skill.interval()` rend **le plus long des deux**, ce que la case attend, et `SkillStats.interval` le recalcule sans le ranger. La plupart des sorts n'ont pas de recharge ; elle est là pour ce qu'on ne doit pas enchaîner — une ruée, un vortex — et pour l'anti-rebond d'un geste entretenu. **Un nœud de talent atteint les deux** depuis le jalon 23 (`use_time` et `recharge` dans `SkillStats.LABELS`) : « Sans répit » efface la recharge de la Ruée d'orage par un accru de −100 % et rallonge son geste, ce qui fait passer la case de la récupération à la vitesse d'incantation. `interval` n'est jamais visé : il se déduit des deux |
| Que pose un lancer dans le monde ? | `Skill.shape`, lue par `Player.cast_slot()` **sur la compétence** : aucun nœud ne la change. Elle porte le comportement et le dessin ensemble, et `projectile` s'en déduit |
| Qui se bat pour le joueur ? | (jalon 26) Les `Minion` de la Relève (`actors/skills/minion.tscn`, archétype `undead`) : `Minion.raise()` relève ce qui manque jusqu'à `simultaneous`, avec `Minion.LIFE` des PV max du lanceur. Ils gardent le **`radius` autour du joueur** — rien hors de la zone n'est poursuivi —, frappent à la `period`, et rejoignent le joueur d'un coup au-delà de `LEASH`. **Leur coup est un coup du joueur** : `cast.roll()`, auteur = `Player.states`, lancer = celui de la Relève — critique, pourriture qui soigne le joueur, compteur de DPS suivent sans une ligne de plus. Leur hurtbox est sur le **calque du joueur** : les tirs de caster les touchent, et leurs blessures ne comptent pas au DPS. Les ennemis frappent **le plus proche** du joueur et d'eux (`Enemy.foe()`, sur `Minion.living`), mais marchent toujours au champ, qui mène au joueur. Un livre rangé les fait tomber. Les **créatures d'une Porte pourrissante** n'en sont pas : de simples positions que `RottingGate` fait avancer et dessine, que personne ne cible, qui explosent par `Explosion.put()` au `radius` du lancer et tombent avec le portail |
| Combien de coups porte un lancer, si tout touche ? | `SkillStats.average_per_cast()` : projectiles × cibles × coups de la forme × `strikes_over_duration()` — **la fonction même qui compte les impulsions du nuage**. Une aura n'a que `average_per_second()` |
| Quels chiffres de dégâts s'affichent ? | `Settings.shows_damage()`, lue par `HitFeedback` pour le coup, l'esquive et la brûlure : une case pour ce que subit le joueur, une pour ce que subissent les ennemis. Le chiffre seulement — la gerbe d'éclats reste |
| Combien le joueur inflige-t-il, par compétence ? | Le signal `Game.damage_dealt(source, état, montant)`, **après mitigation**. Un coup : émis par `Hurtbox.take_damage()` pour tout coup qui a un auteur, hors du joueur, avec `Game.HIT` et `SkillStats.skill_id` (posé par `Skill.resolve()`, vide sans lancer — la charge statique). Ce qui brûle : chaque `StatusEffects.State` retient la compétence qui l'a posé (`source`, passée par `suffer()`), et un porteur `reports_dealt` — les ennemis — l'annonce **par paquets d'une demi-seconde** (`report()`, aussi à la mort) : une annonce par image triplait le coût de `advance()`. `DpsMeter` (option `Settings.dps_meter_visible`, place `dps_meter_position`) en fait une moyenne glissante de 5 s, une ligne par couple compétence × état, l'icône par `SkillIcon.draw_into()` réduite de moitié, l'état dans sa couleur |
| Qui se dessine par-dessus qui ? | L'ordre des enfants de `UI` dans `world/zone.tscn`, et rien d'autre. L'arbre de passifs est **le premier** : il peint un fond plein sur tout l'écran, et le sac, la fiche, les manuels et l'établi doivent se lire par-dessus (`test_zone_ui.gd`). Le bandeau reste dernier |
| Que ferme Échap ? | `Zone.close_interfaces()`, dans `_input` : ce qui est **visible** — sac, fiche, manuels, arbre de passifs, établi, menu de la barre —, et le menu de pause seulement quand rien ne l'était. Par la visibilité et non par `Game.ui_grabs_input`, que la fiche ne prend jamais |
| Qu'est-ce qu'on peut lancer ? | `Player.cast_slot()`, qui porte les sept refus — case vide, non apprise, mauvaise arme, réserve, case en attente (`Player._recharges`, le plus long du geste et de la recharge), orbite pleine, morts-vivants au complet. Le voile de la case se mesure sur l'intervalle **du lancer** (`Player.cooldown_ratio()`, qui garde ce que valait la recharge au départ) : `Skill.interval()` ignore les nœuds de la case. Un **geste entretenu** allumé — l'aura, un buff, le cyclone — s'y **éteint** sans coût, et la touche tenue ne le rallume pas. Un geste qui **enferme** son lanceur (`Skill.binds_caster`, le Tombeau de glace) n'y laisse partir que lui-même, et `Player._physics_process()` cloue les pieds |
| Quand le personnage joue-t-il son attaque ? | À **tout lancer** accepté par `Player.cast_slot()` — sauf la ruée, où le corps traverse l'écran. `ActorSprite.attack(spell)` joue le **lancer** (`cast_<vue>`) pour une compétence de cadence `CAST`, le **coup** (`attack_<vue>`) sinon ; un corps sans lancer (les grilles, les ennemis) joue le coup. Avant le jalon 25, seuls les coups d'arme (`_swing()`) l'animaient. La direction est verrouillée jusqu'à la fin du geste |
| Combien de monde voit-on à l'écran ? | `Game.WORLD_ZOOM` (85 %), posé sur la caméra par `Player._ready()` : la zone logique reste 640 × 360 — les panneaux, calculés à la main dessus, n'ont pas bougé —, seul le monde rétrécit. **Le texte posé dans le monde** — objet au sol, nom d'affixe, nombre de dégâts — passe par `Game.world_font()`, qui compense sa police pour garder la taille d'un zoom de 1 ; par la police et non par l'échelle du nœud, pour que les cadres mesurés sur le texte (survol, clic) suivent. Choisi sur captures à 100, 85, 75 et 67 % (jalon 25). Mesuré au banc, 300 ennemis en combat, en alternance : 165 img/s à 85 % comme à 100 % |
| Qu'est-ce qui brûle en ce moment ? | `Player._lit`, un nœud par identifiant de compétence, et `Player.lit(id)` qui le dit. **`Player.extinguish(id)` est le seul chemin de l'extinction** — touche, réserve vide, livre rangé, mort —, parce qu'un buff éteint doit reprendre ses lignes à la fiche |
| Comment sait-on ce qui brûle ? | `Hud._draw_buffs()`, une icône par geste entretenu **à gauche des jauges** — la bande y est déjà réservée par `gauges_top()`, donc rien n'a à reculer pour elles. `Player.lit_skills()` donne la liste dans l'ordre d'allumage, `lit_ratio()` ce qu'il reste : un voile descend sur un buff à durée, rien sur ce qu'on entretient. La barre, elle, cerne la case allumée de la couleur de sa nature |
| Qui dessine l'icône d'une compétence ? | `SkillIcon.draw_into()` **seulement** : le cadre, le facteur entier, et le disque de la nature à défaut d'image. La barre, son menu et le bandeau montraient sinon trois marques écrites trois fois |
| Ce qu'un buff allumé change ? | `Skill.buffs`, des `SkillBuff` nommés dont les lignes sont **celles d'un passif** par point placé, versées par `Player.buff_mods()` dans la même liste que les objets portés. Tous ceux d'une compétence s'allument et s'éteignent ensemble, sous un seul nœud `Buff`. Un buff ne frappe pas : ses nombres ne sont pas dans `SkillStats`. Le nœud `Buff` porte le prix et le dessin, et **une durée de vie facultative** — zéro tant qu'on l'entretient, deux secondes pour celui qu'une ruée laisse |
| Où va-t-on quand on se rue ? | `Player._dash()` : au curseur, à `PLACEMENT_RANGE` au plus — **la portée de pose du nuage et du serpent**. Murs et ennemis sont **traversés** ; seule l'arrivée doit être libre, et `_landing()` recule de `LANDING_STEP` en `LANDING_STEP` le long de la visée jusqu'au premier point où le corps tient, le départ fermant la marche. `_fits_at()` n'interroge que le **décor** : un ennemi sous les pieds se repousse de lui-même à l'image suivante |
| Ce qu'une ruée laisse derrière ? | **Jamais les deux** : un `DashTrail` — une file de cercles le long du segment, une frappe par période — quand elle a un rayon et une période ; un `Buff` de `duration` secondes quand elle a des lignes. La Ruée ardente brûle son couloir, la Ruée d'orage presse le pas |
| Quelle arme une compétence veut-elle ? | (jalon 18) `Skill.usable_with()` : le mot-clé de sa cadence contre `ItemBase.allowed_keyword()` — les sorts pour une arme `caster`, les attaques pour les autres, rien sans arme. La main gauche ne compte pas. L'arme de départ est posée par `SaveStore.create()` (épée en main, baguette au sac), et par la zone sans personnage |
| Une ligne d'objet est-elle locale ? | `ItemBase.is_local()` : la chance critique d'une arme, plate (`cruel`, « +4 % de chance critique de base ») ou accrue (`precise`) ; **la défense d'une pièce d'armure** — l'armure ou l'esquive de son implicite (`ItemBase.defense_stat()`), plate (`cuirassed`, `elusive`) ou accrue (`plated`). `Item.mods()` ne les verse pas à la fiche ; elles font `Item.crit_chance()` et `Item.defense()` (l'implicite tiré, plus les plats, fois les accrus, arrondi), que `mods()` verse chacune en une seule ligne plate — l'implicite de défense n'y entre pas à part. L'infobulle l'écrit « (local) » par `Item.explicit_line()`, et la base en propriété d'en-tête |
| Qui atteint un coup qui ne naît pas d'une collision ? | `Targets.in_circle()`, sur le calque des hurtbox ennemies : la chaîne, le nuage, l'aura, le serpent, l'épée, l'explosion, la vague, le cyclone, les pics, le vortex, le pilier et la pulsation, la malédiction, et ce que cherchent les morts-vivants et les créatures d'un portail ; `Targets.in_capsule()` pour le **faisceau**, qui mord un segment épais et ne s'arrête pas au premier corps. Les deux passent par `Targets._touched()`, la requête unique. **Jamais depuis un rappel de collision** — l'espace y est verrouillé. Les attaques de zone des ennemis y passent aussi, avec `mask` = `Targets.PLAYER_SIDE` : le joueur **et ses morts-vivants**, sur le même calque |
| Qu'est-ce qui fige le jeu parmi les compétences ? | Ce qui frappe d'un geste : coups d'arc, tirs, chaîne. **Ce qui dure ne fige jamais** — un nuage gèlerait l'image à chaque impulsion |
| Ce que coûte un geste entretenu ? | Des PV, `Player.burn()` — en part des PV max (`Skill.self_burn`, mortelle) ou des PV **actuels** (`self_wither`, la Nécrose avancée, que `Buff` y ramène et qui ne tue donc jamais) ; du mana **à plat**, `Player.drain()` (`Skill.mana_per_second`, un prix qu'on lit sur la jauge sans calcul), qui rend **faux** quand la réserve est vide ; et il peut en **rendre**, `Player.mend()` (`Skill.self_heal`, une part des PV max par seconde, sans mitigation : un soin ne se résiste pas) — et le buff s'éteint là où les PV épuisés tuent. Ce que coûte l'Immolation : `Player.burn()` : répartie entre les natures comme les dégâts de l'aura (`SkillStats.distribution()`), chaque part atténuée par `CharacterStats.mitigate()` — **la règle d'un coup reçu**, donc objets et passifs compris, et l'engourdissement. Pas un coup pour le reste : ni esquive, ni plancher d'un point. **Mortelle** |
| Quand le jeu se fige-t-il ? | `Game.hit_stop()` : **un gel par geste et non par cible**, et `hit_stop_period` entre deux. Sans elle, une compétence tenue sur une nuée figeait le jeu 12 % du temps sans qu'aucune image ne se perde |
| Qui secoue la caméra ? | `Game.shake_camera()`, **une seule secousse à la fois** : relancée, elle reprend la plus forte des deux amplitudes au lieu d'en empiler une seconde |
| Quand une touche de compétence part-elle ? | Le sondage de `Player._physics_process()` : **tenue, elle relance à chaque fin de recharge**, et ne s'arme qu'au passage à l'état enfoncé — un bouton encore baissé quand un panneau rend la souris ne lance rien |
| Combien de points une case accepte-t-elle ? | `Skill.points_max()` : la longueur de la table de dégâts, ou `declared_points_max` pour ce qui n'inflige rien — un buff, comme un passif, déclare son nombre de points |
| Combien de points dans une compétence ? | `Player.skill_points()` : le manuel du râtelier qui l'enseigne, ou un seul pour ce que liste `SkillCatalog.STARTING`. **Les niveaux en bonus** (`SkillStats.LEVELS`, toujours portés par un mot-clé) s'y ajoutent dans `Skill.resolve()` seulement, et seulement si un point est placé : `Manual` ne les voit jamais, ils n'ouvrent aucun nœud. Au-delà de la table, `Skill.damage()` la prolonge par `GROWTH_PER_EXTRA_LEVEL`, composé |
| Une ligne se donne-t-elle en fourchette ? | `StatMod.ranged_stat()` ; la ligne qu'un affixe ou un implicite donne, `StatMod.from_definition()` |
| Quel niveau a un manuel ? | `Manual.level()`, **déduit** de son expérience par `Progression` |
| Peut-on y placer un point ? | `Manual.can_invest()` — les quatre conditions, jamais dans l'interface |
| Où un manuel apprend-il ? | Au râtelier seulement, par `Player.reward()` — le chemin d'une mort **et** d'une boule d'expérience de l'établi, avec le retard sur la zone |
| Que porte une case de manuel ? | `ManualCell` : une compétence **ou** un passif — jamais les deux —, sa position, et l'arbre de talents de la première |
| D'où viennent les talents d'un lancer ? | `Player.talents_of()`, qui passe par le livre du râtelier qui enseigne la compétence. Ils entrent dans `Skill.resolve()` **sans être filtrés** : un nœud ne vise que sa propre compétence, et c'est tout ce qui le distingue d'un modificateur d'objet |
| Que rapporte un attribut ? | `CharacterStats.apply_attributes()` **seule**, une fois par recalcul, entre les modificateurs d'attributs et les autres. Chacun en gouverne **exactement deux** (`test_each_attribute_governs_two_stats`) : force → PV et dégâts aux attaques (`strength_damage()`, versé dans `skill_mods` par `Player.recompute_stats()`), dextérité → esquive et vitesse d'attaque, intelligence → mana max et régénération de mana. **Aucun attribut ne donne de vitesse d'incantation** (`test_no_attribute_gives_cast_speed`, 20 septembre 2026) : elle ne vient que des armes d'incantation et de l'arbre, parce que la cadence est la statistique que font monter les sorts sans recharge — la voir monter toute seule avec un axe de l'arbre la rendait sans objet |
| D'où viennent les attributs placés ? | De l'**arbre de passifs** seulement, avec les objets et les passifs de manuel : plus aucun point d'attribut. `PassiveTree.mods()` des nœuds pris (`Player.passives`), versé par `Player.recompute_stats()` dans **la même liste** que les objets — attributs avant la dérivation, mots-clés dans `skill_mods` |
| Combien de points d'arbre ? | `PassiveTree.points_gained()` : niveau − 1, **déduit**, jamais retenu ; les restants, `remaining_points()`. Le bandeau les annonce au-dessus du niveau tant qu'il en reste (`Hud._refresh_points()`, sur `passives_changed` et `xp_changed`) |
| Quel niveau maximal pour un personnage ? | `Player.MAX_LEVEL` (100) : au plafond, `xp_to_next` vaut zéro et l'expérience ne s'accumule plus. Les zones, elles, montent jusqu'à `Game.MAX_LEVEL` (120) |
| Peut-on prendre un nœud de l'arbre, le reprendre ? | `PassiveTree.can_take()` — un point restant, voisin d'un nœud pris ou du départ — et `can_release()` — **tous les autres nœuds pris restent reliés au départ** sans lui, par `connected()`. Gratuit. Le panneau (P) n'en vérifie aucune ; `Player.take_passive()` / `release_passive()` sont les seuls chemins |
| Quelle forme a l'arbre de passifs ? | `resources/passive_tree.tres`, 496 nœuds (jalon 19, étendu aux jalons 23 et 26). Un **squelette** : trois axes depuis le départ — intelligence en haut, dextérité en bas à droite, force en bas à gauche —, une clé de voûte au bout de chacun, et trois anneaux qui les croisent (`inner_*`, `outer_*`, `far_*`). Un nœud de squelette ne porte **que** des attributs : +10 sur un axe, +5/+5 sur un anneau. Le troisième anneau passe **au-delà** des clés de voûte, qui ne sont donc jamais un passage : on l'atteint par les trois ponts `*_bridge`, qui contournent la clé de voûte depuis le dernier nœud d'axe. Les **clusters** sont des culs-de-sac branchés sur une seule jonction, faits de petits nœuds et de leurs notables — un hexagone autour de son notable, ou une chaîne qui finit sur lui. Deux nœuds ne s'approchent jamais à moins de **deux cases** (`test_two_nodes_never_crowd_each_other`) : en dessous les pastilles se touchent. La couronne des clusters était pleine au jalon 26 : la **route nécrotique** passe par le seul couloir restant, entre « Paratonnerre » et « Souffle élargi » depuis `far_int_dex_1`, longe le haut de l'arbre à trois cases au-delà de l'ancien bord (y = −49) et descend dans les deux poches du coin supérieur droit. Au-delà, l'arbre ne tient plus au zoom large. Une **forme** du graphe, jamais un champ de `PassiveNode` |
| Combien vaut un nœud de dégâts ? | L'**échelle de spécificité** (jalon 23), sur les petits nœuds seuls : 8 % pour une portée large (`attack`, `spell`), 10 % pour une nature ou une forme, 12 % pour des dégâts contre un état — plus la portée est étroite, plus la valeur est forte, parce qu'elle sert moins souvent. Écrite une fois, dans `test_each_small_damage_line_sits_on_the_specificity_scale` ; un notable répartit environ deux petits et demi sur deux lignes, et elle ne lui dit rien |
| Le zoom du panneau de l'arbre ? | `PassiveTreePanel.ZOOMS` (0,35, 1 et 1,5), trois crans à la molette, qui multiplient `UNIT` dans `screen_position()` et les rayons dans `_radius()` — donc la tolérance de `node_at()`. `zoom_by()` garde le centre du cadre. Pas d'icône au cran large ; retour au cran normal à l'ouverture |
| Ce qu'une sauvegarde peut porter dans l'arbre ? | `PassiveTree.legal()`, à la relecture : les identifiants inconnus et les nœuds coupés du départ sont retirés, et pas plus de nœuds que de points |
| Ce qu'un passif de manuel change, et quand ? | `Manual.passive_mods()`, versé par `Player.recompute_stats()` dans **la même liste** que les objets portés — donc trié par la même règle entre la fiche et les mots-clés. Seulement au râtelier : un livre du sac ne donne rien |
| Peut-on placer un point ? | `Manual.can_invest()`, pour les trois sortes de destination. `is_open()` porte les conditions **structurelles** seules, pour que la page distingue « verrouillé » de « plus de point à placer » |
| Peut-on le reprendre ? | `Manual.can_refund()`, pour les trois sortes : pas un nœud sous un enfant qui porte des points, pas une compétence sous les points qu'un de ses nœuds investis demande. `Player.refund()` vide la barre d'une compétence retombée à zéro |
| Où convertit-on des dégâts ? | `SkillStats.apply_conversion()`, appelée par `resolve()` **après les fourchettes ajoutées**, sur **toutes les natures** du coup : entière, il n'en reste qu'une, donc qu'un état possible. `conversions` en garde la part pour la fiche |
| Dans quelle nature un tir se dessine-t-il ? | `SkillStats.dominant_nature()` : celle de la compétence, ou celle où une conversion a emmené le plus gros de ses dégâts **propres** — ce qu'un objet ajoute ne change pas la couleur |
| Un coup pose-t-il un état ? | Deux chemins, tous deux dans `Hurtbox.take_damage()` **après** l'esquive, la mitigation et le signal. **Ce que pose un lancer** (jalon 26) : `Skill.inflicted_state` à `inflict_chance`, par `StatusEffects.inflict()` — la décomposition de la Peste, le flétrissement de la Déferlante —, sur la part du coup dans la nature de l'état, **un tirage** quel que soit le résultat. **Ce que tire une nature** — les six de `StatusEffects.ROLLED`, un par nature — : `StatusEffects.suffer()` : 20 % pour un coup entièrement d'une nature, partagés selon ses parts, **plus la part des PV max de la cible que la nature retire** (`StatusEffects.chance()`), **un tirage par nature présente**, physique compris, **fois deux facteurs** : celui de l'auteur, par sorte (`StatusEffects.chance_factors`, écrit par `Player.recompute_stats()` d'après `CharacterStats.ignite_chance`, `chill_chance` et `blessing_chance`), et celui du **lancer** (`Skill.status_chance_increase`, en points de pourcentage, ce qui fait de la Nova de glace un sort qui transit — hors de portée des nœuds). Les deux **s'additionnent** avant de multiplier la chance de base, comme tous les accrus du jeu : +50 porté et +50 du lancer font 20 → 40 %, pas 45. `StatusEffects.CHANCE_STATS` est le seul endroit qui lie une sorte à la statistique qui l'accroît — le porteur y écrit ses facteurs, la page du manuel y lit son libellé. Chance, durées et forces sont les constantes de `StatusEffects` |
| Qu'est-ce qu'un coup réussi déclenche chez son auteur ? | Le signal `StatusEffects.struck`, émis par `Hurtbox.take_damage()` sur `info.author` : où, ce qui est passé, les états de la cible. `core/` ne fait naître aucun nœud et le coup arrive dans un rappel de collision, donc ce qui réagit vit ailleurs — `Player._on_struck()`, **le seul endroit** qui tire la charge statique (`CharacterStats.static_charge_chance`, sur un engourdi) |
| Qui a porté un coup ? | `DamageInfo.author` — les états de l'attaquant, jamais son nœud —, posé par ce qui fabrique le coup ; un tir le lit sur son lanceur par `StatusEffects.of()`. `DamageInfo.cast`, le lancer du joueur, voyage à côté : `Targets.strike()` et `Explosion.put()` l'exigent, `Projectile.spawn()` et le coup d'arc le posent |
| Quand un bonus contre un état s'applique-t-il ? | Résolu par `Skill.resolve()` dans `SkillStats.against_increased` / `against_more` (statistiques `damage_vs_<id>` sur `StatusEffects.IDS`), appliqué par `Hurtbox.take_damage()` **avec la bénédiction, avant l'esquive et l'armure**, par `SkillStats.against_factor()` sur les états **déjà présents**. L'accru s'ajoute aux accrus du lancer, le « plus » multiplie. La page du manuel le montre à part du total « par coup » ; le banc ne le compte pas |
| Qu'est-ce qui brûle par à-coups ? | `StatusEffects.TICKING`, la décomposition et le flétrissement (jalon 26) : ils brûlent comme l'embrasement — une part du coup nécrotique **après** défenses, donc au niveau du sort —, et **tous les `DOT_TICK`** chacun tire la pourriture comme un coup entièrement nécrotique, à la chance de base fois celle de l'auteur (`CharacterStats.rot_chance`). Un tirage par à-coup (`_rot_from()`) |
| Ce qu'un état change, et où ? | Les facteurs de `StatusEffects`, lus **là où vit déjà la règle** : la malédiction dans `Hurtbox.mitigate_part()`, la bénédiction de l'auteur avant la mitigation, l'engourdissement après ; le gel dans `Enemy.movement_speed()`, `Enemy._cool_down()` et la cadence de `Player._physics_process()`. Ce qui brûle sort d'`StatusEffects.advance()` et s'ôte par `_set_health()`, chez l'ennemi depuis l'`EnemyManager`, avec la régénération |
| Comment un état se voit-il ? | Dans la couleur de sa nature, sauf `StatusEffects.OWN_COLORS` — le saignement, et les quatre nécrotiques qui sinon se confondraient —, sur le signal `StatusEffects.change` : `HealthBar.show_states()`, qui dessine l'icône de chacun (`StatusIcon`, un masque 7×7 par état), et `ActorSprite.show_states()`. Le nom au-dessus du **joueur seul**, par `HitFeedback.state()` ; ce qui brûle, par `HitFeedback.damage_without_hit()` — **statique**, elle porte le test de nullité que ses trois appelants écrivaient — et les paquets d'`StatusEffects.Pack` |

## Les invariants

Ce sont les huit choses qui cassent silencieusement. Aucune ne se voit à la
compilation, et la moitié ne se voit qu'au lancement suivant.

### 1. Les identifiants écrits sur le disque ne changent jamais

`ItemBase.id`, `ItemAffix.id`, les clés de `EquipmentSlots.SLOTS`, les
identifiants de `Keywords` — la portée d'un affixe en nomme un —, ceux de
`DamageType.IDS` — ils forment le nom des dégâts ajoutés, `damage_cold` —, ceux de
`StatusEffects.IDS` — le nom des dégâts contre un état, `damage_vs_ignite` —, ceux
de `Skill`, `Passive` et `TalentNode` — les trois partagent le
dictionnaire de points d'un manuel, et **deux identiques dans un même livre
partageraient un compteur** —, ceux de `PassiveNode` — la liste des nœuds pris
d'un personnage —, l'entier de `StatMod.Mode` — une valeur ne s'ajoute
qu'à la fin — et les noms de champs de `Character.to_dict()`
sont **dans les sauvegardes des joueurs**.
Renommer `chest` en `torso` fait disparaître le plastron de tout le monde — au
prochain chargement seulement, sans erreur.

Ils ont changé **une fois**, quand le code est passé en anglais : les noms français
d'avant sont figés dans `LegacyFrench`, qui les traduit à la lecture des versions 1 à 5.
Un renommage futur fait pareil — une version de plus et sa table — ou ne se fait pas.

Le nom lisible est à côté (`display_name`, `label`) et se change librement.
`test_milestone_4_ids_survive` et
`test_former_slots_keep_their_name` gardent la porte.

### 2. Un `.tres` du disque ne s'écrit jamais

Aucune ressource du projet n'est `resource_local_to_scene`. Écrire dans
`base_stats`, dans un `ItemBase` ou dans une fiche d'archétype touche **le
fichier**, donc toutes les parties suivantes de la session — et l'éditeur peut
graver le résultat.

`duplicate()` avant toute écriture. C'est la séparation `ItemBase` / `Item`,
`base_stats` / `stats`, et c'est pourquoi `Enemy._ready` ne copie sa fiche que
si quelqu'un va réellement y écrire.

### 3. Le hasard du monde passe par le tirage de la zone

Une même graine doit redonner exactement la même zone : mêmes murs, mêmes tuiles,
mêmes ennemis, mêmes silhouettes, mêmes affixes. `Game.rng` est le fil des
tirages de la partie — son état dépend de tout ce qui a été tiré avant, donc il
ne peut rien reproduire.

| Ce qu'on tire | Avec quoi |
|---|---|
| La carte, les paquets d'ennemis | le RNG de zone, réamorcé sur la graine |
| La silhouette, les affixes, le sens de rotation d'un ennemi | `SpawnSeed.at()`, le `hash()` du point d'apparition — **les trois passent par elle**, un arrondi qui divergerait casserait la reproductibilité sans rien dire |
| **Le butin** | `Game.rng`, **et c'est voulu** |
| Qu'un coup pose un état | `Game.rng` : un tirage par nature présente dans le coup, physique compris |
| La gerbe d'éclats, la secousse de caméra | leur tirage à eux — `HitFeedback._rng`, `Game._rng_camera` |

Le butin est l'exception : il récompense une action, pas un lieu. Adossé à la
case, tuer le même ennemi dans une zone qu'on revisite redonnerait toujours le
même objet, et recharger suffirait à garantir une chute.

Corollaire moins évident : **une fonction doit consommer le même nombre de
tirages quel que soit son résultat.** C'est pourquoi `Hurtbox` teste
`evade > 0.0` avant d'appeler `randf()` — sans ça, chaque coup du jeu décalerait
les graines de zone tirées ensuite.

### 4. Rien ne naît depuis un rappel de collision

Godot refuse qu'on ajoute une `Area2D` à l'arbre pendant qu'il résout les
collisions : *« Can't change this state while flushing queries »*. Or un ennemi
meurt presque toujours depuis un `area_entered`.

- `GroundItem.spawn()`, `ExperienceOrb.put()` et `Explosion.put()` passent
  par `DeferredTree.add_deferred()` : ajout puis position, dans cet ordre, une
  position globale ne voulant rien dire hors de l'arbre. **Un parent libéré avant
  l'appel différé libère le nœud** — sinon il fuit hors de l'arbre avec ce qu'il
  porte, comme le manuel de départ d'une zone fermée dans la même image. Un objet
  au sol n'est plus une `Area2D` depuis qu'il se ramasse au clic, mais il naît du
  même rappel et garde le garde-fou du parent libéré ;
- `Player._swing()` passe par `set_deferred("monitoring", …)`, et **attend une
  image de physique** avant de rouvrir la hitbox pour le second coup d'une croix :
  fermée puis rouverte dans la même image, elle ne coupe rien, et un ennemi déjà
  dedans n'y *entre* pas une seconde fois ;
- `Explosion.put()` naît en différé et ne frappe qu'à sa première image de
  physique : la boule qui l'appelle est dans son rappel de collision, où l'espace
  refuse les requêtes ;
- la mort du joueur et la montée de niveau repassent par `call_deferred`, sinon
  la liste de l'`EnemyManager` rétrécit sous ses propres pieds.

Et : **`is_instance_valid()` avant tout `as`** sur une référence conservée.
Convertir un objet déjà libéré est en soi une erreur, qui interrompt la fonction
avant son `queue_free()` — c'est ce qui faisait traverser le joueur par le tir
d'un caster abattu à distance, en le blessant à chaque image.

### 5. Un seul pilote, un seul point de passage

| Ce qui est unique | Où |
|---|---|
| Le tick des ennemis | `EnemyManager._physics_process` — aucun ennemi n'a de `_physics_process` |
| L'écriture de la vie | `_set_health()` chez le joueur comme chez l'ennemi : la barre y est mise à jour |
| Tous les coups reçus | `Hurtbox.take_damage()` |
| La pose d'un état | `Hurtbox.take_damage()`, par `StatusEffects.suffer()` et `inflict()` — **sauf la malédiction**, qui ne frappe pas : `PutridCurse` pose l'état directement, un coup de zéro prenant le plancher d'un point |
| La naissance d'un ennemi | `EnemyManager.spawn()` |
| La naissance d'un tir | `Projectile.spawn()` |
| La recherche des cibles d'un coup sans collision | `Targets.in_circle()` |
| La résolution d'un lancer | `Player.resolve()` — le lancer et la fiche du manuel |
| L'extinction d'un geste entretenu | `Player.extinguish()` : la fiche perd les lignes du buff au même moment |
| Le placement d'un point de manuel | `Player.invest()` / `refund()` : un passif change la fiche, et la page ne peut pas oublier le recalcul |
| La prise d'un nœud de l'arbre de passifs | `Player.take_passive()` / `release_passive()`, pour la même raison |
| La pose d'un objet au sol | `GroundItem.spawn()` |
| Le ramassage d'un objet | `GroundItem.clicked()` — le clic sur le nom, et **rien d'autre** : le contact ne prend plus rien |
| Ce qu'un nom sous le curseur coûte | `GroundItem.takes_the_click()` : **le clic gauche, et lui seul**. Le joueur sonde ses touches hors de l'arbre d'entrées, donc sans ce refus il attaquerait à chaque objet ramassé ; retenir la souris entière (ce que faisait `Game.grab_ui_input`) empêchait de lancer un sort au clic droit en visant un tas |
| Où se pose l'étiquette d'un objet au sol ? | `GroundItem._relayout()`, sur la liste statique de tous les objets au sol : chacune part de sa place et **monte** jusqu'à trouver de l'air, bornée par le haut de l'écran. Recalculé quand la liste change ou qu'une position bouge, jamais à chaque image. `show_labels()` (touche L) les éteint et les rallume ; le rallumage range depuis la position du joueur à cet instant, et c'est ce qui démêle une pile qui débordait. Éteints, plus rien ne se ramasse : l'étiquette **est** le bouton |
| Le retour visuel d'un coup | `HitFeedback.current` |
| Le tirage pondéré | `WeightedRoll.weighted()` |

Écrire `health = …` à la main plutôt que `_set_health()` ne casse rien de
visible : la barre ment, c'est tout.

### 6. Le viewport logique fait 640 × 360

`stretch/mode` vaut `canvas_items` : le 2D est rendu à la résolution de la
fenêtre — d'où du texte net — mais **le viewport logique reste 640 × 360**. Les
mises en page calculées à la main (panneaux, infobulles, HUD) comptent dessus.

Deux tests gardent l'invariant, parce qu'aucune assertion n'attrape un panneau
qui passe sous un autre : `test_the_sheet_fits_its_height` et
`test_the_item_sheet_fits_its_height`. Ils comparent la hauteur du
contenu à celle du cadrage en passant par la **même** fonction que le dessin
(`StatsPanel.content_height()`, `ForgeGallery.sheet_height()`) — sinon ils
valideraient leur propre copie du calcul.

`stretch/scale_mode` reste **fractionnaire** : le jeu remplit exactement la
fenêtre, bandes noires exclues, au prix d'une ligne de pixels doublée aux
facteurs non entiers. Arbitré en essayant les deux ; ne pas remettre `integer`
sans redemander.

### 7. Le format de sauvegarde se lit en arrière

`Character.VERSION` est le numéro **écrit** ; `READABLE_VERSIONS` est la liste de
ce qu'on sait **lire**. Monter le premier sans ajouter l'ancien à la seconde fait
passer tous les personnages existants en « illisible » d'un coup, alors que leurs
fichiers sont intacts — et ça ne se voit qu'au premier lancement après la mise à
jour.

Un champ absent reprend sa valeur par défaut ; un numéro **inconnu** est refusé.
Jamais deviner.

### 8. Les nombres mesurés sont des points de comparaison

Les chiffres de performance dans les commentaires (`PixelCanvas.to_image` à
0,265 ms/image, `FlowField` à 1,67 ms, la génération de carte à 78,8 ms) ont été
mesurés, pas estimés. Ils justifient les seuls endroits du projet où l'on écrit
des tableaux packés plutôt que des structures lisibles. **Remesurer avant de
toucher à ces boucles**, et remesurer après.

Les tableaux packés autorisés : `FlowField` (`_walkable`, `_dx`, `_dy`),
`HitFeedback._p` (les particules), `PixelCanvas` (`_ramp`, `_level`). Partout
ailleurs, une petite classe nommée.

## Les scènes et leurs touches

| Scène | Rôle | Depuis la zone |
|---|---|---|
| `ui/character_select.tscn` | L'accueil : choisir, créer, supprimer un personnage | — |
| `world/zone.tscn` | La partie | — |
| `world/test_arena.tscn` | Régler le game feel à chaud | `F2` |
| `world/map_debug.tscn` | Régler la génération de carte et le niveau de zone | `F3` |
| `art/forge_gallery.tscn` | Juger les sprites, et la fiche d'une base d'objet | `F4` |
| `world/stress_test.tscn` | Banc de mesure | `F6` |

Dans la zone : `I` sac, `C` fiche, `M` manuels, `P` arbre de passifs, `TAB` carte, `H` bandeau,
`F5` nouvelle zone, `G` paquet, `K` tout tuer, `Page haut/bas` niveau de la
prochaine zone, `Échap` ferme ce qui est ouvert, puis ouvre le menu et la
sauvegarde. Les cinq cases de la barre se lancent par `skill_1` à `skill_5` — clic gauche, clic droit, `A`, `R`,
`F` — et **la barre lit ses libellés dans la carte d'entrées**, jamais dans une
liste réécrite à côté. Chaque aperçu se referme par la touche qui l'a
ouvert, et par `Échap`.

## Sauvegarde

Un fichier JSON par personnage dans `user://characters/`, plus
`user://settings.json` pour les réglages de la machine.

Rien de **calculé** n'est écrit : ni PV, ni statistiques, ni états. Elles se reconstruisent
à partir de la fiche de base, des nœuds pris de l'arbre et de l'équipement. Les
écrire créerait une seconde vérité qui figerait l'équilibrage du jour de la
sauvegarde, et un rééquilibrage n'atteindrait jamais les personnages existants.

L'arbre de passifs s'écrit en **liste d'identifiants** (`passives`, version 7), jamais
en points : les restants se déduisent du niveau. Les attributs placés des versions 1
à 6 sont **abandonnés** à la relecture, sans conversion — trois points libres n'ont
pas d'équivalent juste en nœuds — et le joueur retrouve ses niveau − 1 points.

Les points d'un passif et d'un nœud de talent voyagent dans le **même**
dictionnaire que ceux des cases (`manual.points`) : le jalon 10 n'a donc ajouté
aucun champ, et aucun numéro de version. En revanche, la relecture demande à
l'archétype s'il **connaît** l'identifiant (`ManualArchetype.knows`) et non
s'il l'enseigne : la question d'avant aurait jeté tous les arbres au premier
rechargement, sur des fichiers intacts.

Les versions 1 à 5 et les réglages d'avant parlent français — `nom`, `epee`,
`degats_feu`, `user://personnages`, `user://reglages.json`. `LegacyFrench` traduit
le fichier avant `Character.from_dict()`, renomme l'ancien dossier au premier accès,
et l'écriture suivante part en version 6. Les fichiers de référence v1 à v5 gardent
leurs noms français exprès : voir `tests/fixtures/LISEZMOI.md`.

Une ligne d'objet qui vise une statistique **disparue** est convertie à la
lecture, dans `Character._current_line()`, et seulement par une équivalence
exacte avec le jeu d'avant : les dégâts plats des versions 1 à 4 deviennent des
dégâts ajoutés aux attaques ou aux sorts. Ce qui n'a pas d'équivalent est retiré
**avec un avertissement**, jamais deviné.

L'écriture passe par un `.tmp` renommé : une coupure laisse un fichier inutile
plutôt qu'un personnage tronqué. Trois déclencheurs — la croix de la fenêtre, le
retour au menu, la montée de niveau — plus un filet toutes les deux minutes.
