# Icônes

Trois familles : les compétences, dans ce dossier, et les objets, dans `items/`, par
le même tuyau SDXL ; les nœuds d'arbre, dans `nodes/`, par Qwen-Image (jalon 42).

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

**La Boule de feu** a été refaite au jalon 42 par le tuyau des nœuds (Qwen-Image,
voir « Icônes de nœuds ») : l'option `qwen` de `tools/skill_icons.json`, où le sujet
est une phrase entière et la réduction celle des nœuds, sans découpe. Graine 4242, choisie
sur planche (`Bureau\hns-captures-noeuds-icones\14-icone-boule-de-feu.png`). Le Serpent
infernal aussi, graine 777 (`16-icone-serpent.png`). L'Immolation, graine 4242
(`18-icone-immolation.png`). La Ruée ardente, graine 4242 (`20-icone-ruee.png`) : elle
quitte le tuyau SDXL, où elle sortait sur fond gris. Le Brasero, graine 4242 (`22-icone-brasero.png`) :
**tout le manuel du feu** passe ainsi par Qwen-Image.

**Le manuel de la foudre** aussi, au jalon 43 : l'option `nature` (`"lightning"`) donne la
palette et le fond violet. Choisies sur planche (`Bureau\hns-captures-noeuds-foudre\`) :
l'Éclair vif, graine 777 (`02`) ; la Chaîne, trois crânes qu'un arc relie, graine 777 (`05`,
le premier sujet ne donnait qu'un éclair seul) ; le Nuage, un nuage **clair** isolé, graine
1337 (`07`) ; la Ruée, une silhouette noire cernée d'éclairs, graine 1337 (`10`) ; la
Statique, une main blanche cerclée d'arcs, graine 777 (`12`).

**Une boule de feu se dessine en flamme** : « une boule qui rebondit », « qui ricoche sur
un mur » sortent une flamme posée — la Mitraille garde la moins mauvaise, à refaire.

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
  img2img à `denoise` 0,4 : au-delà de 0,5, il délave les couleurs. Le Brasero y
  est passé au jalon 42 (à 0,7, ses aplats de fer restaient plats à 0,4) avant de
  rejoindre Qwen-Image avec tout le manuel du feu ;
- **`violet`** — le fond qui touche les bords ramené au violet sombre de la
  sorcière : le corbeau sortait sur du blanc ou du gris.

Choisis sur planche (`Bureau\hns-captures-sorciere-jalon41\22-icones-nettes.png`).
Un corbeau sombre perd en contraste sur ce fond : à surveiller dans la barre.

### Le tuyau

`tools/skill_icons.py` depuis le jalon 20, qui va de ComfyUI jusqu'au `.tres` :

```bash
tools/skill_icons.py gen                 # la table, trois graines chacune
tools/skill_icons.py gen --only ice_nova  # une seule, pour la refaire
tools/skill_icons.py apply               # pose les tirages retenus
tools/skill_icons.py apply --only ice_nova # n'en pose qu'une
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


## Icônes de nœuds

Une vignette par nœud d'arbre (jalon 42, l'arbre de la Boule de feu d'abord), sur le
champ `icon` du nœud dans le `.tres` de son manuel. **Déjà découpée** à la silhouette de
son rôle et à son côté — rond de 24 pour un nœud de nombres, rond de 28 pour une suite,
octogone de 32 pour ce qui change le jeu (`ManualPanel.NODE_ICONS`) : le panneau la pose
telle quelle, sans masque ni mise à l'échelle.

### Pourquoi pas SDXL

À 16 px, SDXL sortait une bouillie rouge : il ignore la composition (« une boule qui
traverse un bouclier »), et les calques faits main du jalon 41 ne lui ajoutaient qu'un
grain que la réduction effaçait. L'utilisateur voulait « plus de netteté, de compréhension
et de beauté ». D'où un autre modèle, et des vignettes plus grandes.

### Le modèle

Dans `C:\Generate\ComfyUI\ComfyUI\models` (ComfyUI 0.21, RX 7900 XTX de 24 Go) :

| Fichier | Dossier | Source |
|---|---|---|
| `qwen_image_2512_fp8_e4m3fn.safetensors` (20,4 Go) | `diffusion_models` | `Comfy-Org/Qwen-Image_ComfyUI` |
| `qwen_2.5_vl_7b_fp8_scaled.safetensors` (9,4 Go) | `text_encoders` | idem |
| `qwen_image_vae.safetensors` | `vae` | idem |
| `Qwen-Image-2512-Lightning-8steps-V1.0-bf16.safetensors` | `loras` | `lightx2v/Qwen-Image-2512-Lightning` |
| `Qwen-Image-2512-Master-Pixel-Art-LoRA.safetensors` | `loras` | `prithivMLmods/Qwen-Image-2512-Pixel-Art-LoRA` |

Lightning ramène les 45 pas du LoRA pixel art à 8 : **7 s par tirage** à 768 px.
**L'encodeur de texte tourne sur le CPU** (~100 s par sujet, gardé en cache d'une graine
à l'autre) : modèle et encodeur ne tiennent pas ensemble sur la carte, et après un
déchargement partiel le processus ComfyUI ne rendait plus que du bruit — **SDXL compris**,
jusqu'à son redémarrage. `render()` s'arrête s'il en reçoit.

**Si un tirage dépasse la minute**, c'est **le processus ComfyUI** qui est dans un mauvais
état, pas la machine. Au jalon 43 il calculait à 12 s par pas (2 min par tirage) ; au
jalon 44, 122-126 s par tirage d'un sujet déjà encodé, contre 15 s une fois **ComfyUI
relancé** — avec iCUE, Opera et Discord toujours ouverts. Le « redémarrage de la machine »
du jalon 43 n'en était pas un : Windows n'a pas redémarré depuis le 21 septembre, il se
met en veille la nuit et reprend en démarrage rapide.

Écarté au jalon 44, mesures à l'appui : la mémoire vidéo des autres applications (~7 Go,
dont 4 Go pour `QmlRenderer`, le moteur d'affichage d'iCUE), un banc Godot en fenêtré
juste avant un tirage, et 12 Go réservés par un autre processus — Windows relègue alors
12,9 Go de ComfyUI dans la RAM, mais le tirage suivant les ramène en 23 s et le suivant
retombe à 15 s. Les `LiveKernelEvent` 141 et 117 du journal Application ne sont pas des
plantages : un arriéré de rapports du 15 juin que Windows renvoie par paquets de 49, à
heures fixes. **La cause dans le processus reste inconnue** : il était rapide à 13 h 53,
lent à 18 h 24, inactif entre les deux, sans journal sur le disque.

**Avant de le relancer**, relever ce qui manque : `/internal/logs/raw` (un « loaded
partially » au chargement de `QwenImage` ?), la mémoire dédiée et partagée de `python`
(`\GPU Process Memory(*)`), et essayer `POST /free` (`{"unload_models": true,
"free_memory": true}`), qui force un chargement neuf sans tuer le processus.

**Une mémoire partagée non nulle dit que la VRAM déborde.** Le second arrêt du jalon 44
(117 s, ComfyUI pourtant relancé) : 20 Go dédiés et 3 Go partagés pour ComfyUI, 8 Go pour
les autres applications dont 4,9 Go pour `QmlRenderer`. Un redémarrage de Windows l'a réglé.

### La recette

- **Le prompt demande de gros pixels et deux ou trois formes** (`TMPL`) : un tirage
  ordinaire était beau à 768 px et boueux à 32 (le bouclier de la Perforation) ;
- **recadré sur le sujet**, pas au centre : Qwen remplit le cadre ;
- **le fond ramené à une teinte** — cramoisi, bleu nuit pour le Givre et sa suite —,
  reconnu à ce qu'il touche le bord ;
- réduit par **couleur dominante** (`skill_icons.crisp()`), puis découpé.
- **un seul sujet, rien autour** : un serpent orange cerné de flammes orange se fondait
  en une tache à 24 px. Un serpent se demande **de profil, en S**, avec un seul accessoire
  qui dit le nœud (le sablier, le cadenas, l'œuf) — vu de face, enroulé, il ne se lit plus.
- **pas de personnage** : une silhouette humaine sort détaillée et devient une bouillie à
  24-32 px (Satellite, Orage portatif, Choc en retour au jalon 43). Un objet le remplace — un
  chapeau de mage sous son nuage —, ou le sujet lui-même court sur deux jambes (le nuage du
  Front mobile, l'éclair du Trait d'éclair) ;
- **un nuage se demande clair et isolé** (« pale grey-white », « no sky, no ground, no
  horizon ») : sombre, Qwen le pose dans un ciel violet à l'horizon, que le détourage ne
  reconnaît pas, et il se fond dans le fond.

**Une nature** autre que le feu se dit dans la ligne du nœud, `{"nature": "cold"}` ou
`"necrotic"` ou `"lightning"` : palette, fond demandé et teinte du fond (`NATURES`). **Un nœud qui fait à peu
près la même chose qu'un autre en reprend le tirage**, `{"from": "fireball_wide_blast"}` —
l'utilisateur préfère reprendre que refaire ; il est réduit au côté de son propre rôle.
Au Serpent : la Queue de flammes reprend la Déflagration, la Gerbe la Double langue, la
Mue de croissance la Fragmentation. À l'Immolation : la Fournaise reprend l'Attisement, le
Brasier le Souffle ardent, la Brûlure profonde les Étincelles, le Feu de camp le Feu nourri.
À la Ruée ardente : le Sillage reprend la Longue vie (le sablier), les Braises le Souffle
ardent, l'Onde de choc la Déflagration, la Mèche la Poudrière, le Charmeur la Couvée, la
Danse du charmeur l'Ouroboros, l'Onde brûlante les Escarbilles.
Au Brasero : le Tisonnier reprend l'Attisement, les Bûches le Bûcher, la Vigie l'Œil du
brasier, la Salve la Double langue, les Dernières braises la Fragmentation, le Brasier
ravivé la Vélocité.
À la foudre : le Trait de glace reprend le Givre, le Verglas le Gel intense, l'Orbe
statique l'Électrisé du Brasero ; Haute tension et Potentiel la Surcharge, la Bifurcation la
Fourche, la Vivacité le Vif-argent, la Persistance et la Capacité l'Orage durable (le
sablier), le Réamorçage l'Impulsion, la Haute fréquence le Réarmement (le chronomètre),
l'Influx le Retour par la masse, l'Arc brûlant le Point chaud.
Au froid (jalon 44) : l'Engelure reprend le Gel intense du feu (le flocon).

**Un nœud repris dont le tirage a disparu** reprend la vignette déjà posée, si elle est à
son côté (`vignette()`) ; sinon `gen --only <source>` refait le tirage. Et **un tirage déjà
fait ne se refait pas** : ComfyUI inscrit son prompt dans chaque PNG de son dossier de
sortie (`COMFY_OUT`), que `done_before()` relit avant de calculer — le cache temporaire
s'est vidé à un redémarrage de la machine, le dossier de ComfyUI non.

```bash
tools/node_icons.py gen --only fireball_meteor   # trois graines, planche sheet_nodes.png
tools/node_icons.py apply --only fireball_meteor # PNG dans nodes/, champ icon dans le .tres
```

Sujet, graine retenue et rôle dans `tools/node_icons.json`. Choisis sur planche
(`Bureau\hns-captures-noeuds-icones\`, 06 à 12) ; **certaines se ressemblent encore**
(beaucoup de flammes) et Chute libre, Déflagration et Double langue ratent leur sujet :
gardées telles quelles, à retoucher.

La foudre (jalon 43) : 79 nœuds, dont 13 qui en reprennent un autre, choisis arbre par arbre
sur planche et en jeu (`Bureau\hns-captures-noeuds-foudre\`, 01 à 12). Trois restent
faibles, gardés : le Rebond (un éclair qui tombe sur un ennemi, sans rebond), le Satellite
(une planète cerclée, sans la lune) et le Vif-argent (une main floue).


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
