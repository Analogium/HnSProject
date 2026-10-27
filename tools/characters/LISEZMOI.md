# Personnages joueurs, et ennemis en planche

Un personnage jouable, d'un prompt jusqu'au jeu — et, depuis le jalon 27, un ennemi
(`charger`, `mortar`, `bloater`, `brute`) : même tuyau, sans arme, avec les seuls
gestes qu'il joue. Le tuyau : `tools/character_forge.py`,
avec ComfyUI sur l'hôte Windows (voir `resources/icons/LISEZMOI.md` pour le joindre
depuis WSL). La sorcière du jalon 25 en est le premier exemple : `witch.json` et
`witch/`.

**Depuis le jalon 51, les personnages passent en 3D** (section « En 3D », plus bas) : le
Vive lame d'abord. Les étapes 2D qui suivent fournissent encore la vue de face dont part
le modèle, et restent le chemin de ceux qui n'ont pas migré.

## Ce que le jeu en fait

`art/characters/<id>.png` porte en rangée 0 **trois poses fixes** — face, profil
(tourné vers la droite), dos — dans des cases de `frame` pixels, pieds sur la rangée
`feet` ; puis une rangée par geste généré et par vue : marche (4 images), coup d'épée
(`attack`, 3), lancer (`cast`, 3), et les trois attaques du jalon 47 — balayage
(`sweep`), frappe de haut (`overhead`), estoc (`thrust`), 5 images chacune. **Les deux attaques pour chaque personnage** :
l'arme suit l'équipement, et le jeu joue le lancer pour un sort.
`art/characters/<id>.json` donne les repères de chaque vue et, par geste, la rangée de
chaque vue et **la main armée de chaque image** ; pour une attaque, aussi **la lame de
chaque image** (`blades`, le long de l'avant-bras du squelette, celle du repos à la
dernière) et **l'image d'impact** (`impact`), que le jeu lit pour faire tomber le coup. `SpriteForge._draw_sheet()` joue les
gestes tels quels et fait respirer la pose au repos. L'arme n'est **jamais** dans la
planche : la forge la pose à la main, et elle suit l'équipement.

Une classe se déclare dans `Character.CLASSES` (l'archétype, le nom affiché), et son
nom se traduit dans `i18n/en.po`.

## Les étapes

Chacune dépose une planche sur le Bureau ; on choisit, puis la suivante repart du
choix.

1. **Concept** — `tools/character_forge.py concept <id>` : le prompt de
   `concept.prompt`, une image par graine de `concept.seeds`. Puis
   `keep <id> concept <graine>`. Une image faite ailleurs (Leonardo, un dessin)
   se dépose directement en `tools/characters/<id>/concept.png`.
2. **Vues** — `views <id>` : face, profil et dos, une ligne par graine de
   `views.seeds`. IPAdapter tient l'identité du concept, OpenPose impose la vue
   par des squelettes chibi écrits dans l'outil. Le prompt de `views.prompt`
   décrit le personnage **mains vides**. Puis `keep <id> views <graine>`.
3. **Gestes** — `anim <id>` (`--only sweep overhead thrust` pour n'en refaire que certains) :
   la marche, le coup d'épée et le lancer, chaque cycle **en une seule image** (des
   squelettes côte à côte), pour chaque graine de `anim.seeds`, le personnage décrit
   par `anim.who`, mains vides. Un GIF par geste et par graine sur le Bureau,
   les trois vues côte à côte, la main armée marquée d'un point jaune. Puis
   `keep <id> walk all <graine>` (ou une vue : `down`, `side`, `up`).
4. **Planche** — `build <id>` : détourage, ombre générée retirée, réduction à
   `height` pixels, recolorations et retouches, contour du jeu. Écrit
   `art/characters/<id>.png` et `.json`, et `hns-<id>-planche.png` sur le Bureau.
   `build` ne demande pas ComfyUI : les images retenues sont dans
   `tools/characters/<id>/`.
5. **En jeu** — capture réelle, fenêtrée (skill `/dessiner-un-effet`, §5).

## Ce qui se règle à la main, dans `<id>.json`

- **`recolor`** : ce que le prompt n'obtient pas. SDXL ignore « peau bleue » ; la
  règle repeint une plage de teinte dans une bande de hauteur en gardant la valeur.
  `cols` la borne aussi en largeur, `val_mul` assombrit : c'est ainsi que le manteau
  du joueur de flûte devient mi-parti (moutarde / cramoisi), que SDXL ne coupe pas en deux.
- **`body`** (les classes jouables) : la taille du **corps**, du cou aux chevilles, en
  pixels — **16 pour toutes**, sinon elles ne vont pas ensemble (jalon 51). `height`, la
  taille de la silhouette chapeau compris, s'en déduit sur la vue de face retenue :
  34 pour le Vive lame, 37 pour la sorcière et le joueur de flûte. Avant, `height` était
  écrit à la main, et un grand chapeau rapetissait tout le personnage.
- **`height`** (les ennemis, qui n'ont pas `body`) : la taille en jeu, chapeau compris.
  Repères et retouches sont écrits pour `authored_height` et suivent quand la taille
  change : ne demande qu'un `build`.
- **`width`** : l'élargissement du squelette OpenPose sous la tête, pour les vues
  **et** les gestes (1,6 pour le colosse, 1,45 pour le gobelin, 1,4 pour le
  chevalier). Le prompt n'obtient pas une carrure que le squelette dément ; et y
  écrire « very bulky, wide shoulders » fait sortir le profil de face.
- **`slim`** et **`squash`** : la part de largeur et de hauteur gardée **sous la
  tête** — 0,9 et 0,8 pour les trois classes, les mêmes partout (jalon 51, choisi sur
  planche). **`side_width`** multiplie `slim` de profil seulement (1,3) : le squelette de
  profil met les épaules l'une derrière l'autre, et le torse sortait en bâton. La tête ne change pas de
  taille : le visage retouché y reste juste. Appliqués sur l'image source, avant
  réduction, aux poses comme aux gestes ; la main armée de chaque image suit. Les
  `anchors` et les `patches` s'écrivent **sur la silhouette d'origine** :
  `reshape_point()` les déplace comme le corps.
- **`patches`** : des grilles posées par-dessus, en coordonnées **de la case**,
  `.` laisse passer, couleurs dans `colors`. C'est là que vit **le visage** : réduit
  à 48, celui que dessine le modèle n'est qu'une tache de 9 × 5 pixels. Le visage,
  les runes, l'amulette de la sorcière sont des retouches.
- **`anchors`** : pour chaque vue, `hand` (où l'arme se tient au repos), `waist`
  (la taille), `legs` (le haut des pieds, sous lequel rien ne respire) et `head` (le
  bas de la tête : c'est sur elle qu'une image générée se recale). Se lisent sur la
  planche agrandie.
- **`neg`** : ajouté aux négatifs des vues et des gestes, pour ce que le concept pousse à
  tort — le visage pâle du joueur de flûte sortait en crâne, son chapeau en bord large.
- **`concept_palette`** : ramène les trois vues sur les couleurs du concept. Les vues
  tirées par IPAdapter prennent une dominante (rouge sur la Vive lame, où peau,
  écharpe et bottes tombaient dans la même teinte) ; le concept, lui, était juste.
- **`weapon`** : l'arme dessinée quand aucun équipement n'est donné (vignettes de
  création, liste des personnages).
- **`palette`** : les rampes de la forge pour ce qu'elle dessine elle-même — le
  manche de l'arme, la main à l'attaque, qui doit avoir la couleur de la peau.

## En 3D (jalons 51 et 52)

Le chemin 2D perdait trop de détails dès que le personnage bougeait ou quittait la
face. Un personnage passe donc par un **modèle 3D gréé**, dont Blender rend chaque
image directement à la taille du jeu. Tout est gratuit : Stable Fast 3D en local (ou
un Space Hugging Face), Mixamo et Blender. Le jeu lit le **même format** de planche,
plus des couches d'arme. Le Vive lame et la sorcière (jalon 54) ont suivi le chemin
TRELLIS + Mixamo ; le joueur de flûte et les six ennemis, le chemin local (Stable Fast 3D +
gréage local), qui ne dépend d'aucun quota.

0. **Concept**, pour un personnage neuf : une planche de directions en « rendu 3D »
   (LoRA éteint), **proportions adultes**, l'utilisateur choisit. Le passage aux
   proportions du jeu vient à l'étape 1 et se montre aussi avant la 3D. L'image retenue
   devient `<id>/concept.png` et `<id>/down.png`.

1. **Image source** : `tools/model_3d.py image <id>` tire trois images « rendu 3D »
   de face, en pose A, par **Qwen-Image au prompt seul** (jalon 54 ; SDXL avait besoin
   d'IPAdapter et d'OpenPose), **sur fond vert** d'incrustation. On garde la meilleure.
   - Le prompt est `blender.model_prompt` dans `<id>.json` ; `{view}` y dit la vue.
   - Le LoRA pixel art est éteint : **une image pixel art donne un modèle plat**.
   - Le fond vert se découpe à la couleur (`model_3d.silhouette`). Sur le fond gris
     d'avant, GrabCut bouchait l'entrejambe et collait l'ombre du sol aux pieds.
2. **Modèle**, par l'un des deux chemins ci-dessous. Les deux écrivent
   `<id>/3d/model.glb`, puis `<id>/3d/<id>.fbx`, allégé pour Mixamo. Un tour du
   modèle sous six angles est déposé sur le Bureau.

   **Par TRELLIS.2** (le chemin retenu au jalon 54 pour les personnages vus de près) : voir
   plus bas. **En local, Stable Fast 3D** (illimité, mais une figurine molle, mains en
   moignons) :
   - `model_3d.py back <id>` tire trois images de dos au même prompt ; on garde celle
     qui s'écarte le moins de la face. Sans image de référence, Qwen fait pendre une
     écharpe dans le dos qui pend devant : un tel dos repeint ferait une traînée ;
   - `model_3d.py mesh <id> <graine> --back <graine de dos>` fait le modèle sur la
     carte locale, puis `blender/project.py` **repeint face et dos** d'après leurs
     images. Stable Fast 3D ne voit que la face et devine le dos :
     celui de la sorcière sortait rose pâle au lieu de gris sombre ;
   - `--sf3d` au lieu de `--back` : sans image de dos, la face seule est repeinte et le
     dos reste deviné. Pour une tenue simple (le Vive lame), ou ce que le générateur ne
     sait pas tourner (le champignon garde son visage à toutes les graines).
   - La repeinture ne touche que ce qui fait face à une image ; le reste garde la
     texture de Stable Fast 3D, ramenée au ton de la face. Elle rend aussi le net : la
     texture cuite (2048 px) laisse un visage flou.

   **Par TRELLIS.2**, sans `--back` : `model_3d.py mesh <id> <graine>` lance le Space
   `microsoft/TRELLIS.2` via `tools/trellis_client.py` : une forme nette — doigts, plis,
   visage — et sa propre texture, tout autour du corps. Son modèle brut (~190 000 faces) est
   gardé dans `model_trellis.glb` (une relance ne refait pas le quota), puis réduit à 40 000
   faces et sa texture recuite sur la version réduite (`blender/bake_color.py`, normales
   remises à l'endroit : la réduction en retourne). **Un modèle par jour** (quota
   ZeroGPU).
   - TRELLIS passe par le Python **Windows** d'un venv :
     `py -3.12 -m venv C:\Generate\hns-trellis-venv` puis
     `pip install gradio_client huggingface_hub`.
   - Il faut aussi un jeton Hugging Face rangé par `huggingface-cli login` : en
     anonyme, le quota ZeroGPU ne suffit pas.
   - Hunyuan3D est exclu : sa licence exclut l'UE.
3. **Gréage**, à la main, sur **www.mixamo.com** (gratuit, compte Adobe ; libre dans un jeu,
   les fichiers d'animation ne se redistribuent pas seuls) — **le chemin retenu au jalon 54** :
   l'auto-rig donne des doigts, et ses animations, captées sur des acteurs, tombent juste :
   - envoyer le `.fbx` (repères : menton, poignets, coudes, genoux, aine ; *Standard
     Skeleton (65)*, avec les doigts) ;
   - choisir une animation par geste du jeu — repos, marche, chaque attaque, le sort — et
     les télécharger en *FBX Binary, 30 fps, Keyframe Reduction none*, la première *With
     Skin* (elle porte le personnage gréé), les autres *Without Skin*, *In Place* pour ce qui
     se déplace ;
   - les déposer dans `<id>/mixamo/`, nommées du geste (`rest.fbx`, `walk.fbx`,
     `sweep.fbx`…), et les nommer dans `blender.anims` avec `"guard": false` : l'export les
     joue telles quelles, l'image d'impact prise où la main armée va le plus vite sans que
     le bras se replie (`export_glb.impact`). Le Vive lame (jalon 54) en est l'exemple.
   - **Les bras rentrent dans le corps** : Mixamo anime un acteur plus mince. Son curseur
     *Character Arm-Space* n'a pas suffi au Vive lame (gilet, sacoches) ; `blender.arm_space`
     écarte les bras de ce nombre de degrés sur toutes les animations sauf le repos
     (`export_glb.spread`, 40° pour lui, choisi sur planche parmi 0 à 45°). Ce ne sont pas
     ses poids : vérifié os par os, la main passait derrière la hanche, dans la sacoche.
   - **Un corps qui se téléporte** : une animation prise sans *In Place* avance les hanches (la
     marche du caster, 1,52 m sur le cycle), et le corps revient d'un coup à sa place à la boucle
     ou au geste suivant. L'export ôte cette dérive horizontale, du premier au dernier pas
     (`export_glb.in_place`) ; le balancement reste. Les gestes d'attaque reviennent d'eux-mêmes.
   - **Jambes trop écartées** dans la course : `blender.walk_leg_space`, en degrés, négatif
     pour resserrer les cuisses (−12° pour le Vive lame, choisi sur planche, et la sorcière).
   - **Avant-bras trop levés** : la course de Mixamo (« Running ») est un sprint, les mains
     montent au menton. `blender.elbows` déplie les coudes de cette part de leur pli, hors
     repos (`export_glb.straighten`, 0,5 pour le Vive lame, à confirmer en jeu).
   - **L'arme suit le bras, pas le poing** : sur des attaques à mains nues, la main ne tient
     rien et l'épée partait n'importe où. L'export tourne la main à chaque image pour que la
     lame prolonge le levier épaule → main (`export_glb.wield`, hors gréage local et marche :
     le jeu range l'arme quand on se déplace ou qu'on lance, `ActorModel.SHEATHED`). La main
     ne s'écarte pas de plus de 40° de celle de l'animation (`WRIST`) : sans borne, le
     poignet cassait jusqu'à 145°, la main « posée de travers comme un lego ».
   - **Un corps sans arme** (`blender.weapons` vide, le Roi des Rats) n'a ni prise ni main
     tournée : Mixamo peut le gréer sans doigts.
   - **Une main en moufle** : quand Mixamo ne trouve pas les doigts (le grunt, doigts serrés
     dans l'image source), il ne grée que l'index. La prise se pose alors d'après les axes de
     l'os de la main (`weapons.grip_bone`), qui suivent jointures et paume à 0,99 près.
   - **Un coup répété** que Mixamo n'a pas (la Rafale, trois estocs) : nommer la source du
     coup seul (`"flurry": ["thrust.fbx", 8]`) et le geste dans `blender.repeat` ; l'export
     le répète à la cadence du jeu (`FLURRY_THRUSTS`, `FLURRY_GAP`), le retrait rejoué à
     rebours (`export_glb.repeat`).
   - **Pas dans `<id>/3d/`** : les `Breathing Idle` et `Walking` de `swiftblade/3d/` sont le
     squelette de référence du gréage local, et le restent.

   **Ou en local, sans Mixamo** (la sorcière avant le jalon 54, dont la cape collait les
   bras au buste ; refaite en pèlerine courte, elle passe par Mixamo) : `model_3d.py rig <id>` (`blender/rig.py`). Il reprend le
   squelette et les animations Mixamo de `swiftblade/3d/`, place les articulations sur
   les points de l'image source, peint les poids, et écrit `<id>/3d/rest.blend` et
   `walk.blend`, que `anims` et `rest` nomment comme un `.fbx`. Les points se lisent sur
   la silhouette en pose A (`model_3d.joints`) : poignets au bout des bras, aisselles où
   le bras rejoint le buste, chevilles dans les bottes. Une silhouette qui n'est pas en
   pose A (un monstre sans bras) n'y passe pas.
4. **Planche** : `tools/blender_sheet.py <id>` (`--cached` pour ne refaire que
   l'assemblage). Les réglages vivent dans la section `blender` de `<id>.json` :
   - `rest` : le repos ;
   - `anims` : `<geste>: [source, images]`, la source étant un `.fbx` Mixamo, un
     `.blend` du gréage local ou un **geste écrit** de `tools/blender/gestes.json` ;
   - `size` : la case de rendu ;
   - `elevation` (10°), `sun`, `ambient` ;
   - `colors` et `weapon_colors` : les palettes ;
   - `weapons` : une couche par arme.
5. **Modèle du jeu en 3D** (jalon 54) : `tools/blender_sheet.py <id> --glb` écrit
   `art/models/<id>.glb` depuis les mêmes réglages — corps, une animation par geste, les
   armes sous l'os de la main, images d'impact et arme par défaut (`weapon`) en métadonnées.
   **Dès que ce fichier existe, le jeu montre le modèle à la place de la planche**
   (`ActorModel`). S'il y a `<id>/3d/model_trellis.glb`, l'export écrit aussi
   `art/models/<id>_portrait.glb`, le modèle brut, net, pour la sélection et l'inventaire :
   il reprend les poids du corps de jeu, sans repasser par Mixamo. `tools/capture.sh tools/look_3d.gd <sujet>` filme chaque
   animation sous la lumière du jeu, et `tools/look_3d.py <sujet>` en fait des GIF sur le
   Bureau.

Les gestes d'attaque **s'écrivent**, ils ne se téléchargent pas : Mixamo n'a pas nos
coups. Chaque geste de `gestes.json` est une suite de poses-clés, et c'est
`blender/pose_anim.py` qui les joue. Un personnage gréé par Mixamo en prend aussi, nommé
dans `blender.anims` à côté de ses `.fbx`, quand Mixamo n'a pas le geste : le coup des deux
poings au sol du colosse (`smash`, jalon 54). Et la pose tenue du Cyclone (`spin`, jalon 54), nommée dans `blender.anims` de **chaque classe** (Vive lame, sorcière, joueur de flûte) : une boucle, les deux mains sur la poignée (`"lhand": "grip"`) ; c'est le jeu qui fait tourner le corps (`ActorModel.spin()`), le script ne sait pas pivoter tout le corps. `arm_space` et `elbows` ne s'y appliquent pas :
écrit pour ce corps, il n'a pas les bras trop serrés de l'acteur de Mixamo.

- la **main armée** — le creux du poing, où passe la poignée — et la **direction de la
  lame**, en hauteurs de personnage depuis l'épaule ;
- le buste qui tourne et s'incline (`twist`, `lean`), le corps qui fléchit ou se fend
  (`crouch`, `forward`) ;
- la main gauche (`lhand`, ou `"grip"` pour une arme à deux mains), les pieds
  (`lfoot`, `rfoot`) ;
- l'image d'impact (`impact`).

La cinématique inverse plie bras et jambes. `rest` est **la garde** : le repos, la
marche, et le départ et le retour de chaque geste — la garde C, « garde prête », choisie
sur planche au jalon 54 (coude plié, lame vers l'avant). Au repos et en marche, la main
gauche y est posée aussi : l'animation d'emprunt ne garde que son balancement, recentré
(`export_glb.left_hand`), sa pose propre venant d'un autre squelette.

Ce qui précède vaut pour le gréage local : ses animations viennent d'un autre squelette,
d'où la garde tenue. Un personnage gréé par Mixamo joue les siennes (`"guard": false`).

**La main tient l'arme par son os de prise** (`RightHandGrip`, au creux du poing, +Y le long
des jointures vers le pouce, +Z vers la paume ; posé par `rig.py`, ou d'après les os des
doigts d'un squelette Mixamo par `weapons.grip_bone()`) : `weapons.hold()` place le poignet pour que le poing tombe
sur la poignée, et l'arme du `.glb` est accrochée à cet os. Tenue par le poignet, la poignée
flottait à côté de la main.

Ce que la planche fait du rendu :

- **Pixel art** : ombrage en trois aplats (`stage.toon`), aucun anticrénelage, une
  palette commune à toutes les images (16 couleurs, sinon elles scintillent), le
  contour du jeu.
- **Les armes sont modélisées** dans `blender/weapons.py`, à 1,4× l'échelle : à 36 px,
  une arme à l'échelle se lit mal. Chacune est rendue **seule**, le corps en masque
  (elle passe derrière lui), dans `art/characters/<id>_<arme>.png` avec sa propre
  palette. Le jeu la pose sur la planche du corps, rendue sans arme.
- **Main, lame, tête, taille, pieds** viennent des os, image par image.

Installer Stable Fast 3D (une fois, sous Windows, carte AMD) :

- Accepter la licence du dépôt `stabilityai/stable-fast-3d` sur Hugging Face (dépôt
  restreint, jeton de `huggingface-cli login`).
- Cloner ses sources dans `C:\Generate\hns-local3d\src\stable-fast-3d`, et créer un venv
  `C:\Generate\hns-local3d\venv` (Python 3.12). Le PyTorch ROCm vient de ComfyUI : un
  fichier `zz_comfy.pth` dans les `site-packages` du venv contient
  `C:\Generate\ComfyUI\python_embeded\Lib\site-packages`.
- `pip install -r requirements.txt` sans `texture_baker` ni `uv_unwrapper`, puis
  `transformers==4.42.3 numpy==1.26.4` : les versions récentes ne chargent plus le
  modèle.
- `texture_baker` et `uv_unwrapper` se compilent **sur CPU** avec Visual Studio :
  `vcvars64`, puis `USE_CUDA=0`, `USE_NATIVE_ARCH=0`, `DISTUTILS_USE_SDK=1` et
  `pip install --no-build-isolation`. Il faut d'abord copier un `c10_shim.cpp` dans
  leurs `csrc` : le PyTorch AMD pour Windows n'exporte pas un constructeur de
  `c10::ValueError` que ses en-têtes appellent. Le shim le remplace par un arrêt
  (`/alternatename`). Le script et le shim sont dans `C:\Generate\hns-local3d\run\`.

Pièges payés :

- **Stable Fast 3D** : `rembg` est remplacé par un module vide (le détourage est déjà
  fait), et le baker de texture tourne sur CPU (`sf3d_client.py`, `on_cpu`). Le
  modèle sort tourné vers l'arrière de la caméra du jeu : demi-tour sur Y.
- **TripoSR**, essayé avant : couleurs ternes, abandonné.
- **Le dos des monstres sortait de face** : leurs yeux lumineux l'emportaient. Le
  dos se tire avec la vue en tête de prompt, l'image de face à 0,25 et le visage
  interdit (`model_3d.renders`).
- **Le détourage** : un rendu « studio » a un fond en dégradé (halo clair au
  centre, sol). La médiane des bords ne le reconnaît pas, et le joueur de flûte
  sortait avec une plaque au-dessus du chapeau et sous les pieds. À l'inverse, les
  jambes gris pâle du Roi des Rats, sur un sol gris pâle, partaient avec le fond, et
  son modèle 3D sortait sans jambes (jalon 53). Aucun tri par couleur ne tenait les
  deux cas : `model_3d.silhouette` passe par **GrabCut** (OpenCV), dans un cadre qui
  ne laisse que les bords au fond (`pip install opencv-python-headless`, dans le
  Python de WSL).
- **Le gréage local d'un corps élargi** (`width`) : la pose A écrite pour lui est
  celle des images, élargie elle aussi, sinon les articulations tombent au centre.
- **Le concept** : « chibi » dans le prompt donne des bébés ; le mot « rat » donne des
  hommes-rats, même en accessoire ; un prompt trop long noie la description (la
  mettre en tête). Un rat posé sur l'épaule a été refusé : illisible à 26 px.
- **La taille** (jalon 52) : `blender.size` à 70 % de la taille d'origine, `scale`
  0,7. Réduire au rendu, jamais étirer en jeu : les pixels resteraient inégaux.
- **La palette est plafonnée à 0,88 de luminance** (`LIGHT_MAX`) : les reflets des
  lames passaient le seuil de glow du jeu.
- **La réduction fend les visages** (jalon 54) : ramené de 200 000 à 40 000 faces
  (`bake_color.py`), le maillage de TRELLIS.2 garde ses boucles de cheveux et écrase le
  visage en éclats, fendu de noir au zoom — la sorcière nettement, le Vive lame moins. Un
  remaillage en voxels d'abord réparait la sorcière et perçait le Vive lame (surfaces
  ouvertes : écharpe, mèches) : écarté. Le Space réduit lui-même à l'extraction, mais pas
  sous 100 000 faces. **Tranché avec l'utilisateur** : en zone, le corps réduit, vu de loin ;
  de face, le portrait garde le modèle brut (étape 5 ci-dessous).
- **La recuisson noircit le métal** (jalon 54) : TRELLIS.2 pose une carte métallique sur
  tout le corps, et la couleur diffuse que Blender cuit d'une surface métallique est noire.
  Le joueur de flûte (métal 0,88 en moyenne) sortait en habits noirs ; `bake_color.py`
  éteint le métal de la source avant de cuire. La sorcière (0,73) et le Vive lame (0,51),
  cuits avant, ont été **recuits sans regréer** : `bake_color.py` sur `3d/model.glb` pour
  forme garde son dépliage (`blender -b -P bake_color.py -- model.glb model_trellis.glb
  model.glb`), qui est celui que Mixamo a reçu et rendu tel quel (vérifié : maillage, UV et
  texture identiques) ; l'export reprend la couleur de `model.glb` (`color`).
- **Gréage local, le haut du crâne** (jalon 54) : sans point OpenPose, `HeadTop_End`
  gardait la tête chibi du squelette d'emprunt et dépassait le Vive lame adulte d'un tiers
  de sa taille. Gestes et armes se mesurent à lui : le bras se tendait à fond, l'épée était
  trop grande. `rig.py` le pose sur le haut du maillage.
- **Gréage local, les mains** : elles sortent ouvertes, sans os aux doigts. `rig.py` les
  replie en poings dans le maillage, **autour de la ligne des jointures, vers la paume** :
  en pose A, bras à 45°, les doigts s'étalent dans le plan de face, le pouce au dedans, la
  paume vers l'arrière (mesuré sur TRELLIS.2). Replier autour de l'autre axe couchait les
  doigts les uns sur les autres et déchirait le maillage. Sur les moignons de Stable Fast 3D,
  le résultat reste grossier.
- **Les candidats écartés** (jalon 54) : Hunyuan3D (licence hors UE, sorties comprises),
  TripoSG et Step1X-3D (ils en reprennent du code sous licence hors UE), SPAR3D (pas mieux
  que Stable Fast 3D). **Lire la licence d'un générateur avant de le lancer.**
- **Gréage local, les jambes** :
  - leurs os sont posés devant le maillage puis reculés d'un rayon de jambe ;
  - aucun poids ne mêle gauche et droite, et les faces qui joignent les deux jambes
    sont coupées, sinon des barres relient les pieds en marche ;
  - l'ourlet de la cape suit le buste, pas les jambes ;
  - **les pieds se posent sous la nuque** comme ceux du Vive lame, plus `FEET_BACK` :
    tirés de la pose A, ils partaient en avant, comme un personnage qui marche le dos
    cambré. Plusieurs mesures « à l'œil » avaient été faussées par la baguette et le
    bord du chapeau ;
  - la marche empruntée est raccourcie (`STEP`).
- **Le quota gratuit de ZeroGPU** tient quelques modèles par jour, compte et anonyme
  compris : les essais du Vive lame l'ont vidé pour la journée. Choisir l'image source
  avant de lancer TRELLIS. Il ne tourne pas sur la carte locale, une AMD : ses
  extensions sont écrites pour CUDA.
- **Le profil se rend du côté gauche, puis se retourne** (`stage.VIEWS`). Vue du côté
  de la main armée, la lame passait forcément sur le corps.
- **En marche, le bras armé reste en garde**, porté par le bassin
  (`weapons.carry()`), dans toutes les passes, celle du corps comprise. Laissée au
  balancement de Mixamo, la lame traversait le buste.
- **La transformation AgX**, celle de Blender par défaut, éteint les visages :
  `Standard`.
- **Un geste se rend sur [0, 1[** : sa dernière clé est le repos, que le jeu rejoue
  déjà, et deux images identiques font échouer
  `test_every_animation_of_a_sheet_moves`.
- **Vider l'animation du repos** (`animation_data_clear`) laisse les os où ils sont ;
  changer leur `rotation_mode` les renvoie à la pose de liaison.

## Les gestes d'attaque (jalon 47)

`STRIKES`, dans l'outil : pour chaque geste, coude et poignet armés en cinq temps (face et
profil ; le dos est le miroir de face), le buste penché (`lean`, profil), tassé
(`crouch`), la fente (`lunge`, profil) et l'image d'impact. **Le corps doit s'engager** :
à 34 px, un bras qui bouge seul ne se lit pas, et l'ancien coup d'épée ne se voyait pas.
**La règle de l'utilisateur** : une classe neuve reçoit tous les gestes de `STRIKES`
(`anim <id> --only sweep overhead thrust`, environ 5 minutes pour deux graines, 17 s
l'image, puis `keep` et `build`) ; une attaque à **mouvement neuf** se génère pour chaque
classe, sauf si elle vit dans un manuel de classe — pour sa classe seule. Voir RECETTES,
« Ajouter une compétence » §5 et « Ajouter une classe jouable ». Le GIF trace la lame et tient l'image
d'impact deux fois plus longtemps ; un `.png` du même nom montre les images une à une.

## Les pièges déjà payés

- **Les `anchors` d'un autre personnage** : `head` borne le tassement (`squash`) ; recopiée
  d'ailleurs, elle tassait aussi la tête du joueur de flûte. Les relever sur une planche
  construite `squash` 1.

- **Des proportions adultes ne survivent pas à 48 px** : la tête retombe à quatre
  pixels. Tout passe par le chibi, dans le prompt comme dans les squelettes.
- **Trop de détails font du bruit** : une référence chargée (runes partout,
  fioles, broderie) sort en masse sombre sans contraste. Peu de détails, mais très
  contrastés — et les petits se posent en retouches.
- **Redonner une image générée comme référence** amplifie sa dominante de
  couleur : le tirage suivant vire au magenta.
- **La marche image par image ne tient pas** : le modèle ignore les petits écarts
  de pose et la couleur dérive d'une image à l'autre. **Un cycle en une seule image,
  si** : d'où `anim`. Et une animation faite en décalant des bandes de la pose reste
  raide, quel que soit le réglage — trois versions refusées au jalon 25.
- **La couleur d'un cycle généré dérive** : chaque image est ramenée sur la palette
  de la pose validée. La peau est recolorée **avant**, sinon le rose part au rouge.
- **L'ombre des cycles est rosée**, pas grise : `silhouette()` retire aussi, dans le
  bas, ce qui est proche du fond.
- **De dos, pas de nez ni d'yeux dans le squelette**, sinon le modèle dessine un
  visage.
- **Les retouches sont dessinées pour `authored_height`** ; leur place suit `height`,
  pas leur grille. Le visage se cale donc sur le crâne de chaque image (`put_patches()` :
  centré de face, contre le bord avant de profil, mesuré aux rangées des yeux) et ne
  s'écrit que dans la silhouette — sinon il sortait du crâne, sans contour (jalon 47).
- **Une graine peut perdre le chapeau de dos** (la sorcière, graine 777, jalon 47) :
  regarder les trois vues de chaque geste avant de retenir.
- **L'ombre que dessine le modèle** entre dans le cadrage et écrase le personnage :
  `silhouette()` la retire (grise, peu saturée, dans le bas).
