# Hack'n'slash top-down — jalon 54

Suite des jalons 1 à 53. Ce document ne redit pas ce qui y est déjà écrit, et
`docs/ARCHITECTURE.md` reste le seul endroit qui décrit l'état courant.

**Ouvert le 17 octobre 2026**, sur la branche `3d`, dans un worktree à part :
`../HnSProject-3d`, `config/name="HnSProject 3D"` (jamais le `user://` du jeu, donc
jamais ses personnages). La version 2D continue sur `master`, dans `HnSProject/`.
**À la fusion, `config/name` reste celui de `master`.**

---

## 1. Ce que l'utilisateur a demandé

- Changer le style visuel : « un style 3D comme Torchlight Infinite, le tout dans un
  style se rapprochant de Torchlight Infinite ».
- Le faire dans un dossier à part, « si ça ne plaît pas, j'aurai toujours la version
  actuelle ».
- « Quelque chose de fonctionnel qui pourra évoluer, pas de bric-à-brac juste pour que
  ça ressemble à quelque chose. »

## 2. La décision : tout en 3D, le jeu sur un plan

Les entités deviennent des `Node3D` — `CharacterBody3D`, `Area3D` — **à hauteur
verrouillée à 0**. Le gameplay ne change pas : Torchlight Infinite se joue à plat, la
3D est la façon de le montrer.

**Écarté : une simulation 2D recopiée par une vue 3D.** Moins chère au départ, elle
coupe chaque entité en deux moitiés, deux arbres et deux repères, pour toujours ; et
tout ce que la vue doit apprendre à la simulation (l'os de la main pour une traînée,
une ligne de vue contre un mur 3D, du relief) devient un aller-retour. Écartée aussi,
l'astuce d'une `Camera2D` écrasée sous une caméra orthographique : elle laissait
effets et sol en 2D couchés au sol, tout à jeter.

Ce que la 3D simplifie : plus de `z_index` ni de tri en Y — le tampon de profondeur
les remplace ; le visuel d'une compétence est un nœud enfant de sa compétence.

**Unité : 1 m = 16 px** de l'ancien repère (un personnage de ~27 px fait ~1,7 m).
Toutes les distances des `.tres` (portées, rayons, vitesses) sont en pixels : on les
convertit **en un seul endroit** à la lecture, ou on les réécrit en mètres. **Tranché
le 17 octobre : la conversion à la lecture pour l'étape 1**, pour que la campagne portée
garde ses chiffres (les tests les écrivent à travers la même conversion). **Le but reste
les `.tres` en mètres** : un geste à part, une fois le gameplay prouvé intact en 3D.

## 3. Ce qui ne bouge pas

`core/` (53 `Vector2`, presque tous dans `Hurtbox`), l'interface (`ui/`, des
`Control`), les `.tres`, l'équilibrage, la génération de la carte (une grille), les
icônes, la ville dans sa logique.

## 4. Le coût, mesuré

| | à porter |
|---|---|
| `Vector2` dans le code de jeu | ~1 100 (`actors/` 504, `ui/` 294 dont une part reste 2D, `art/` 224, `fx/` 169, `world/` 106) |
| `Vector2` dans les tests | ~900, sur 25 800 lignes |
| formes de collision | 80 `CircleShape2D`, 5 capsules, 2 rectangles |
| requêtes physiques | 4 `direct_space_state` |
| dessins de compétences | 44 `Node2D` de `actors/skills/` portent leur `_draw` |
| visée à la souris | 4 appels de monde à `get_global_mouse_position()` → une seule fonction, rayon contre le plan du sol |

## 5. Les étapes

Chaque étape livre du code définitif ; aucune ne pose d'échafaudage à démonter.

0. **Export `.glb` et premier regard.** `tools/blender_sheet.py <id> --glb` écrit
   `art/models/<id>.glb` : le corps gréé, `rest`, `walk` et les gestes de
   `gestes.json` cuits en actions par `pose_anim.py`, l'image d'impact en
   métadonnée ; les armes de `weapons.py` à part, accrochées à l'os de la main en jeu.
   Le **Vive lame** (le seul gréé par Mixamo) posé dans une scène à caméra et lumière
   façon Torchlight Infinite, capture sur le Bureau. **C'est le risque n°1** — les
   modèles Stable Fast 3D tiennent-ils une caméra proche et un éclairage dynamique ? —
   et on le lève avant de porter quoi que ce soit. L'outil et la lumière restent.
1. **La simulation en 3D, des capsules pour corps.** Zone, joueur, ennemis,
   projectiles, objets au sol, `Hurtbox`, `EnemyManager`, flow field (il reste une
   grille, lue en XZ). Les compétences gardent leur logique ; leur dessin s'éteint.
   **La campagne portée doit redonner les mêmes chiffres** : on change le type des
   vecteurs, jamais une valeur attendue. C'est la preuve que le gameplay n'a pas bougé.
2. **`ActorModel`**, le pendant 3D d'`ActorSprite`, **même interface** : `set_state`,
   `attack`, `impact_of`, `flash`, `set_rim`, `show_states`, `set_archetype`,
   `set_variant`, `current_variant`, `set_weapon` — les acteurs n'en appellent pas
   d'autre. La direction devient une rotation ; flash, liseré et teinte d'état, les
   uniformes d'un matériau en `next_pass`. Tous les acteurs de `tools/characters/`.
3. **Le monde** : sol, murs et décor bâtis depuis la grille de `MapGenerator`.
4. **Les effets**, compétence par compétence. **Une compétence sans dessin 3D montre
   le visuel générique de son élément** — le même principe que l'icône absente
   (« le champ vide reste un état normal »). `/dessiner-un-effet` est à réécrire
   pour la 3D avant la première.
5. **Lumière et post-traitement** pensés pour la 3D : le seuil de lueur de 0,9 et le
   plafond de 0,88 (`ArtPalette`, `blender_sheet.LIGHT_MAX`) tombent.

`docs/ARCHITECTURE.md` est réécrit au fil des étapes : ses invariants 2D (la lueur,
le tri en Y, `Hurtbox` en `Area2D`) mentiraient dès l'étape 1.

## 6. À trancher sur capture

- ~~Caméra perspective à focale étroite ou orthographique~~ — **tranché le 17 octobre :
  la façon Torchlight**, `proche-perspective` de `tools/look_3d.gd` : perspective, champ
  vertical de 30°, 20 m, inclinée de 45°. Elle montre moins de sol que l'écran 2D.
- L'interface, pensée à 640 × 360 en pixel art, à côté d'un monde net : à juger une
  fois le monde fait.
- La performance : remesurer `world/stress_test.tscn` après l'étape 2 (meshes
  skinnés). La zone jouée compte 69 ennemis ; les 935 du banc demanderont sans doute
  un `MultiMesh` ou des animations cuites dans les sommets.

## 7. Étape 0, faite le 17 octobre 2026

**L'outil.** `tools/blender_sheet.py <id> --glb` → `tools/blender/export_glb.py`, 4 s par
personnage. `rest` et `walk` y sont les boucles entières (la planche n'en gardait qu'une
image), chaque geste écrit dure **une seconde** : l'impact se lit en secondes, le jeu
règlera la vitesse. Deux choses ont dû bouger pour que le geste soit fait **d'os seuls** :

- `pose_anim.play()` porte maintenant le corps par les **hanches**, plus par l'objet
  armature — planche du balayage recomparée : identique au pixel, repères compris ;
- la main **tourne avec la lame** (`grip()`) : la cinématique inverse ne pliait que le
  bras, et l'arme suivait la cible, pas l'os.

**Écart avec §5 : les armes sont dans le `.glb` du personnage**, un nœud `weapon_<type>`
sous l'os de la main, pas un fichier par arme. La prise (où la main tient la poignée) et
la taille dépendent du corps ; posées dans Blender, elles arrivent justes à l'import, sans
réglage par personnage côté jeu. `set_weapon` n'aura qu'à en montrer une.

**Le regard** (`world/lighting.tscn`, `tools/look_3d.gd`, captures dans
`Bureau\hns-captures-modele-3d\`) : soleil chaud en haut à gauche côté caméra, ambiance
froide, ACES, SSAO, MSAA 4× posé par le scénario seul. Le Vive lame **et la sorcière**,
parce que le Vive lame est un modèle TRELLIS : le risque n°1 portait sur Stable Fast 3D.

- **Le Vive lame (TRELLIS) tient le gros plan** : visage, écharpe, gants lisibles.
- **La sorcière ne le tient pas** : le chapeau est un barbouillage de taches sarcelle,
  rouges et blanches, que la réduction à 38 px cachait. **Ce n'est pas Stable Fast 3D** :
  son modèle brut (`model_sf3d.glb`), posé à côté sous la même caméra, est propre. Les
  taches viennent de `blender/project.py`, qui repeint face et dos d'après deux images
  et donne au reste (le dessus du bord du chapeau, que la caméra à 45° voit en plein) la
  couleur la plus proche. Le dos deviné par Stable Fast 3D reste faux (la cape rose pâle).
- Les armes, des volumes pensés pour 36 px, font plastique sous une vraie lumière.
- Le sol est la texture 2D posée telle quelle : sa refonte est l'étape 3.

## 8. Reste à faire

- ~~Réparer `project.py`~~ — fait : il ne repeint que ce qui fait face à une image, le
  reste garde la texture de Stable Fast 3D ramenée au ton de la face. La sorcière est à
  refaire de toute façon (proportions).
- **Les proportions chibi n'ont plus de sens** dans un jeu façon Torchlight Infinite
  (remarque de l'utilisateur, 17 octobre). **Tranché sur planche le même jour** : la
  direction « Torchlight » — semi-réaliste, visage un peu anime, proportions adultes
  élancées —, parmi quatre (héroïque trapu, sombre réaliste, anime). Tirée par Qwen-Image,
  LoRA pixel art éteint. Tous les personnages sont à refaire depuis l'image source, le
  Vive lame d'abord : son image source (Qwen-Image sur fond vert, `model_3d.py image`) et
  son modèle Stable Fast 3D, face repeinte, et son gréage **local** sont faits : les
  articulations se lisent sur la silhouette en pose A (`model_3d.joints`), plus besoin de
  Mixamo. Captures dans `Bureau\hns-captures-vive-lame-adulte\`. En `.glb`, les armes
  gardent leur échelle (le ×1,4 n'était que pour 36 px).
  - **Les gestes sont à reprendre** : `gestes.json` a été écrit pour des bras chibi ; la
    garde tend le bras armé loin du corps, et les autres gestes sont à juger sur capture.
  - Les autres personnages suivent le même chemin : concept, `model_3d.py image`, `mesh
    --sf3d`, `rig`, `blender_sheet.py --glb`.
- Étape 1.
