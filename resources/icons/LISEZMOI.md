# Icônes

Deux familles, même tuyau et même recette : les compétences, dans ce dossier, et
les objets, dans `items/`.

## Icônes de compétences

Une image par compétence. Elle est branchée sur le champ `icon` du `.tres` de la
compétence, dans `resources/skills/` — **pas** retrouvée par son nom de
fichier : un identifiant mal tapé donnerait une case vide sans que rien ne le
dise, là où un champ vide se voit dans l'inspecteur.

### Ce que le jeu en fait

`SkillIcon` la ramène à **24 × 24**, au plus proche voisin, puis la case
l'agrandit d'un facteur **entier**. Une image plus petite que 24 est laissée
telle quelle ; une plus grande est réduite.

Les deux tailles d'affichage sont **26** (barre de compétences) et **34** (page
de manuel), en pixels logiques — le jeu tourne en 640 × 360 étiré. Une icône de
24 tient donc à l'échelle 1 dans les deux.

### Produire les images

Dessinées, générées, découpées d'une planche : le tuyau ne s'en soucie pas. Deux
choses comptent, et elles ne sont pas négociables à cette taille :

**La silhouette avant le détail.** Ce qui se lit dans 24 pixels, c'est une forme.
Un détail de deux pixels disparaît — c'est ce qui a coûté trois brouillons à
l'icône du manuel, et ce qui a fait rejeter un éclair aminci qui se lisait comme
une pointe de flèche.

**La cohérence entre les icônes.** Si elles sont générées, les produire **en une
seule planche** plutôt qu'une par une : quatre générations séparées donnent
quatre éclairages et quatre palettes, et l'ensemble se lit comme un assemblage
disparate. Le reste du jeu sort d'une seule forge, avec une seule direction de
lumière — en haut à gauche, voir `PixelCanvas.LIGHT`.

#### La recette du jalon 11

Les icônes des manuels sortent de ComfyUI, **SDXL 1.0** (`sdXL_v10VAEFix`) avec le
LoRA **`pixel-art-xl-v1.1`** à pleine force, en 1024 × 1024 :

- **un gabarit de prompt partagé** — « pixel art, 16-bit rpg ability icon, *sujet*,
  centered, single subject, bold readable silhouette, high contrast, simple solid
  *fond* background, square game icon » — où seul le sujet change, et le fond
  suit la nature : violet pour la foudre, cramoisi pour le feu, bleu pour le froid,
  vert croupi pour la nécrose, prune pour le sacré — un fond doré noierait la lumière du sujet —, bleu ardoise
  pour le physique ;
- **les mêmes réglages pour toutes** : `dpmpp_2m`, `karras`, 30 pas, CFG 6, et la
  graine 4242 — 777 pour les trois refaites avec un sujet plus direct (Chaîne
  d'éclairs, Frappe lourde, Boule de feu). C'est ce qui remplace la planche unique,
  que SDXL ne sait pas découper en neuf sujets distincts ;
- **la réduction à 24 px par moyenne de zone**, puis une palette ramenée à
  24 couleurs. Au plus proche voisin depuis 1024, chaque pixel est tiré au hasard
  dans un bloc de 42, et la trame devient du bruit.

L'image est **recadrée à 70 % au centre avant la réduction** : le sujet occupe
rarement plus que ce centre, et réduite entière, la tuile noyait sa silhouette
dans le fond. On génère trois images par compétence et on choisit sur une
planche où chacune est déjà réduite — juger une image de 1024 px ne dit rien de
ce qui restera à 24.

L'icône d'Éclair vif est antérieure et ne suit pas cette recette.

#### La recette du jalon 41 : plus nette, et composée

Les quatre icônes neuves de la sorcière (Trinité, Catalyse, Poupée de chiffon,
Familier) ont été jugées floues et illogiques par l'utilisateur. Deux causes, deux
remèdes, réglés par un troisième champ facultatif de `tools/skill_icons.json` :

- **`crisp`** — la réduction par **couleur dominante** (`crisp()`) : l'image est
  ramenée à 14 couleurs, puis chaque pixel prend la plus fréquente du cœur de son
  bloc. La moyenne de zone mélangeait deux couleurs voisines en une troisième ;
- **`layout` et `denoise`** — SDXL de base **ignore la composition** : « une flamme,
  un flocon et un éclair en triangle » sortait sans flocon ni éclair, la poupée de
  chiffon en fillette. Le sujet est donc posé à la main en grandes formes plates
  éclairées en haut à gauche (`tools/icon_layouts.py`), et SDXL l'habille en
  img2img à `denoise` 0,4 : au-delà de 0,5, il délave les couleurs. **Le Brasero**
  (jalon 42) fait exception : à 0,4, ses aplats de fer restaient plats à côté des
  icônes du manuel du feu, et 0,7 lui a donné leur grain sans perdre le trépied. Un
  calque a son fond (`icon_layouts.BACKGROUNDS`) : le cramoisi du feu pour lui, le
  violet de la sorcière par défaut ;
- **`violet`** — le fond qui touche les bords ramené au violet sombre de la
  sorcière : le corbeau sortait sur du blanc ou du gris.

Choisis sur planche (`Bureau\hns-captures-sorciere-jalon41\22-icones-nettes.png`).
Un corbeau sombre perd en contraste sur ce fond : à surveiller dans la barre.

### Le tuyau

`tools/skill_icons.py` depuis le jalon 20, qui va de ComfyUI jusqu'au `.tres` :

```bash
tools/skill_icons.py gen                 # la table, trois graines chacune
tools/skill_icons.py gen --only brazier  # une seule, pour la refaire
tools/skill_icons.py apply               # pose les tirages retenus
tools/skill_icons.py apply --only brazier # n'en pose qu'une
```

`--only` sur `apply` n'est pas un confort : le cache des tirages vit dans un
dossier **temporaire**, et sans lui `apply` exige les tirages de toutes les
compétences — vidés à la première nuit.

Le sujet du prompt et la graine retenue sont **la même ligne** de
`tools/skill_icons.json`, comme pour les objets. Le moteur est celui de
`tools/item_icons.py`, dont ce script importe le rendu et la quantification :
**deux différences seulement**, et elles sont la raison du second fichier — une
icône de compétence est une tuile pleine, donc recadrée au centre plutôt que
détourée, et son fond suit la nature du sort.

**Un phénomène se demande comme un sujet penché.** « a vertical beam of light
descending », « a godray onto the ground », « a cone of divine rays » sortent tous un
chandelier ou une torche : SDXL rend un objet dès qu'on lui demande une verticale.
Une diagonale — « a thin diagonal streak of light cutting across » — y échappe.
Et la graine 777 raye : sur un sujet vertical elle sort des bandes horizontales.

### Sans icône

Le champ vide est un état normal : la barre dessine alors un disque de la couleur
de la nature du sort. Une compétence sans image reste jouable et reconnaissable.


## Icônes d'objets

Une image par **base**, pas par `kind` : c'est ce qui sépare enfin les trois
paliers d'une lignée par leur silhouette, là où la forge ne pouvait les séparer
que par la couleur de leurs rampes. Branchée sur le champ `icon` du `.tres` de
`resources/items/`.

**Taillée à la case de sa famille** (jalon 31) : la place utile de son encombrement
dans le sac — 14 × 56 pour une arme, 35 × 56 pour un torse, 35 × 35 pour un casque,
14 × 14 pour un anneau —, un pixel d'image par pixel logique. Le tuyau lit ce cadre
dans le jeu (`ItemBase.GRID_SIZES`, `CELL`, `PAD` et `MARGIN` d'`InventoryPanel`) :
changer la taille des cases, c'est relancer `gen`. Dans le sac, `inventory_icon()` la
pose donc **sans l'agrandir**, emplacement d'équipement compris ; `ground_icon()` la
réduit en Lanczos. Jusqu'au jalon 30 elles faisaient 24 px et le sac les agrandissait :
quatre pixels d'écran par pixel d'image, ce que l'utilisateur trouvait trop pixelisé.

Le champ vide reste un état normal :
sans image, la forge dessine l'objet comme avant. C'est ce repli qui fait qu'une
base ajoutée sans image reste jouable.

**Le `kind` compte toujours**, même sous une image : c'est lui qui pose l'arme
dans la main du personnage. `test_each_base_has_a_non_empty_icon` vérifie les deux.

### Le tuyau

`tools/item_icons.py`, qui va de ComfyUI jusqu'au `.tres` :

```bash
tools/item_icons.py gen                 # les 61 bases, trois graines chacune
tools/item_icons.py gen --only sword    # une seule, pour la refaire
tools/item_icons.py apply               # pose les tirages retenus
tools/item_icons.py apply --only manual_necrotic  # n'en pose qu'une
```

Le sujet du prompt et la graine retenue d'une base sont **la même ligne** de
`tools/item_icons.json` : refaire une icône, c'est changer l'un des deux.

Mêmes réglages que le jalon 11 — SDXL 1.0, LoRA `pixel-art-xl-v1.1` à pleine
force, 1024 × 1024, `dpmpp_2m`, `karras`, 30 pas, CFG 6 — avec un gabarit de
prompt partagé où seul le sujet change. Le gabarit demande depuis le jalon 31 du
détail, des couleurs saturées et une lumière de bord ; et **aucun sujet n'est « plain »
ou « simple »**, même au palier 1 : c'est ce que SDXL rendait, des objets gris et
plats. Un palier 1 est en fer usé, mais il a une garde en bronze, un cuir rouge, des
rivets. Trois enseignements, tous payés d'un tirage raté :

- **le fond ne se commande pas par sa couleur.** « fond magenta plat » donne un
  fond gris, et teinte le contour de l'objet en bordeaux. On demande seulement un
  fond *plat*, et on le détoure ensuite par un remplissage depuis les bords,
  quelle que soit sa teinte. C'est aussi ce qui garde l'acier gris d'un heaume,
  qu'un simple seuil de couleur effacerait ;
- **le fond enfermé par l'objet** — l'intérieur d'une bague, la boucle d'une
  ceinture — ne touche aucun bord et survit à ce remplissage. Il se reconnaît à
  sa couleur seule, donc à un écart bien plus serré (`BG_TIGHT`) ;
- **le recadrage vient du détourage**, pas d'un pourcentage fixe comme pour les
  compétences : la boîte de l'objet détouré donne à la fois son cadre et ses
  proportions, donc une dague ressort plus courte qu'une épée sans qu'on l'ait
  demandé.

Un fond que le remplissage n'a pas mordu produit une image pleine : le script la
jette plutôt que de la rattraper, elle manque à la planche et on choisit une
autre graine. Trois sur cent trente-deux.

### Choisir

`gen` écrit une planche par famille dans le dossier de travail : une ligne par
base, une colonne par graine, déjà réduites. On choisit là, jamais sur l'image de
1024 px. Ce qu'on y regarde, dans l'ordre :

1. **l'escalade de la lignée** — palier 1 rustique, 3 ouvragé, et les trois
   distinguables d'un coup d'œil ;
2. **le sujet seul** — SDXL glisse volontiers un personnage dans une capuche ou
   une planche de neuf épées ;
3. **les miettes** — une ombre détachée au sol passe le seuil de nettoyage si
   elle pèse plus du dixième du sujet.

**Un manuel se demande comme les autres manuels** : « a closed *teinte* tome with a
*motif* emblem on its cover, front view ». Tablettes, arches et parchemins sortent en
décor ou en plusieurs morceaux, que le détourage laisse éparpillés sur la planche.


## À l'import

Les deux familles. Ces images sont du pixel art : dans l'onglet Import de Godot, filtre **désactivé**
et compression **sans perte**. Un filtre linéaire lisse la trame, et une
compression VRAM y laisse des artefacts qui ne se voient qu'à l'agrandissement.
