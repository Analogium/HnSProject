# Hack'n'slash top-down — jalon 24

Suite des jalons 1 à 23. Ce document ne redit pas ce qui y est déjà écrit, et
`docs/ARCHITECTURE.md` reste le seul endroit qui décrit l'état courant.

**Proposé et livré le 19 septembre 2026** (les quatre lots ; §9 dit ce que les
captures ont contredit). Le jeu a seize compétences, une
forge de sprites et quarante-quatre icônes, et il ne ressemble toujours pas à ce qu'il
veut être. La référence demandée est **Hero Siege** : du pixel art saturé, des sorts qui
*émettent* de la lumière, des silhouettes caricaturales qui se lisent dans une mêlée.

Ce jalon soutient que l'écart **n'est pas un écart de dessin**. Il est, dans l'ordre,
un écart de **rendu**, de **palette**, de **matière de VFX**, et seulement en dernier de
**silhouette**. D'où quatre lots qu'on peut arrêter après n'importe lequel.

---

## 1. L'état des lieux

| Ce qui se voit | Où ça vit | Sous quelle forme |
|---|---|---|
| Acteurs — joueur, grunt, caster, dummy | `art/sprite_forge.gd` sur `art/pixel_canvas.gd` | procédural, `FRAME = 32`, 4 variantes × 3 directions × (idle 2, walk 4, attack 2) = **24 images par variante** |
| Couleurs | `art/art_palette.gd` | rampes de 5 teintes, ombre vers un violet froid, lumière vers un blanc chaud |
| VFX de compétences | les 16 scripts de `actors/skills/` | **66 appels de dessin** vectoriel (`draw_circle`, `draw_line`, `draw_arc`…) en blend additif partagé (`ArtPalette.ADDITIVE`) |
| Projectiles, arc de coup, orbes, éclats de dégâts | `actors/projectiles/`, `actors/player/swing_arc.gd`, `actors/items/`, `fx/hit_feedback.gd` | même technique |
| Icônes de compétences et d'objets | `resources/icons/` | PNG hors du jeu (SDXL + `pixel-art-xl`) |
| Tuiles | `world/tileset_builder.gd` | procédural |
| **Rendu, post-process** | **nulle part** | pas de `WorldEnvironment`, `rendering/viewport/hdr_2d` absent de `project.godot` : **aucun glow, aucun bloom** |

---

## 2. Le défaut : cinq écarts, du plus payant au moins payant

**1. Rien n'émet.** Un sort de Hero Siege est une source de lumière ; ici
`holy_pulse.gd` dessine un `draw_arc` d'un pixel à alpha 0,25 sur un sol sombre. Le
blend additif est déjà là, mais sans buffer flottant il **sature à blanc et s'arrête
là** : deux couches additives empilées donnent 1,0, jamais 1,8, donc il n'y a rien
au-dessus du blanc que le rendu pourrait faire déborder. C'est l'écart le plus visible
et le moins cher à combler — il ne touche aucun script de compétence.

**2. Les VFX sont de la géométrie, pas de la matière.** Un cercle net de rayon exact se
lit comme un affichage de portée ; Hero Siege empile des blobs mous, des streaks et des
étincelles qui n'ont pas de bord. Les 66 appels de dessin sont au bon endroit et au bon
moment — c'est leur **primitive** qui est fausse, pas leur logique.

**3. La palette est celle d'un jeu sombre, pas d'un jeu saturé.** `BASE_STOP = 0.6`
place la couleur de base au-dessus du milieu de la rampe pour laisser « plus de place
aux ombres qu'aux lumières » : un sprite est majoritairement dans son ombre. C'est un
choix cohérent, et c'est l'inverse du modèle visé.

**4. Les silhouettes sont anatomiquement justes.** `config()` donne `head_r = 3.8` pour
un corps de 27 px : des proportions réalistes. Hero Siege caricature — tête grosse,
arme surdimensionnée, coiffe qui identifie la classe à dix mètres. En 32 px, il n'y a
pas la place de caricaturer *et* de garder le modelé.

**5. Le joueur a la même facture que ses ennemis.** C'est le seul sprite qu'on regarde
pendant des heures, et il est dessiné par la même fonction que le grunt.

---

## 3. La règle : la lumière est une couche, pas un dessin

Un seul principe porte les deux premiers lots, et c'est lui qui rend le jalon petit.

**Ce qui brille ne se dessine pas plus clair, il se dessine au-dessus d'un seuil.** Le
glow du `WorldEnvironment` ne fait déborder que ce qui dépasse `glow_hdr_threshold`, et
c'est la **valeur** qui trie, pas la couche : le glow s'applique au viewport entier, on
ne peut pas en exclure l'interface.

> Ce paragraphe disait d'abord *au-dessus du blanc*, avec `hdr_2d` pour rendre le
> buffer flottant et laisser l'additif empiler au-delà de 1,0. Mesuré, `hdr_2d`
> linéarise le canevas sans le réencoder : le sol passe de 71 à 14 (§9). Le jeu reste
> donc en LDR, seuil à **0,9**, et deux des trois conséquences ci-dessous ont changé.

- **les sprites ne brillent pas, l'interface si.** Le plus clair pixel d'un sprite est
  à 0,88 — le cristal du caster, 0,02 sous le seuil —, donc le pixel art reste net — c'est l'essentiel. Mais le texte blanc
  du HUD est à 1,0 : il déborde, et rien en LDR ne peut l'en empêcher. Un halo sur les
  nombres de dégâts, on s'en accommode ; l'isoler demanderait un viewport séparé ;
- **l'ombre au sol des sprites ne brille pas.** Un noir à 30 % ne dépasse aucun seuil.
  Le piège du jalon des assets — `core/flash.gdshader` blanchissait l'ombre, mesuré à
  (52,48,45) au repos contre (128,124,121) pendant le flash — **ne se repose pas ici** :
  il vient d'un shader qui repeignait le sprite, pas du post-process ;
- **un impact déborde déjà.** `flash.gdshader` mélange vers `vec3(1.0)` : au-dessus de
  0,9, donc un ennemi qui encaisse brille, sans qu'on ait touché le shader. C'est le
  « pop » du modèle, obtenu gratuitement par le choix du seuil.

Le corollaire, et la découverte du jalon : **le lot A seul ne paie pas**. Les effets
existants dessinaient des aplats à alpha 0,07 à 0,45 sur un sol à 0,26 — ils ne
passaient aucun seuil praticable, et la couche de lumière n'avait rien à faire briller.
Il leur manquait un **cœur**, pas un post-process. Le lot C n'est donc pas la suite
facultative du lot A : c'est ce qui le rend visible.

---

## 4. Les lots, dans l'ordre

Chacun se juge sur une capture avant/après et s'annule d'un `git checkout`. L'ordre
n'est pas négociable : le lot A change l'aspect de tout ce que les suivants dessinent,
donc le juger après eux, c'est le juger deux fois.

### Lot A — la couche de lumière

`rendering/viewport/hdr_2d = true` dans `project.godot`, un `WorldEnvironment` dans la
scène de zone et dans l'arène, `Environment` en `background_mode = Canvas`, glow activé,
seuil à régler à la capture (autour de 1,0, là où l'additif commence à déborder).

Trois réglages et rien d'autre. **Aucun script ne change.** Le glow est un
post-process plein écran : c'est le seul lot du jalon qui se paie en images par seconde,
donc le seul qui **oblige** à relancer le banc (§7).

### Lot B — la palette

`SHADOW_TINT`, `LIGHT_TINT`, `BASE_STOP`, `SHADOW_STRENGTH`, `LIGHT_STRENGTH` : cinq
constantes d'`art_palette.gd`, dont le fichier dit déjà qu'elles « retendent l'ambiance
du jeu entier d'un coup ». Un essai, une capture, on garde ou on jette. Le risque n'est
pas technique, il est de goût : remonter `BASE_STOP` sature les acteurs **et** les
tuiles, et un sol saturé mange les silhouettes qu'il porte. Si les deux ne peuvent pas
vivre avec la même rampe, c'est que la rampe du sol doit s'en séparer — et ça, ce n'est
plus un réglage, c'est une règle en plus. À trancher sur l'image, pas ici.

### Lot C — la matière des VFX

Quatre textures additives produites par `PixelCanvas` (une passe de gradient, pas de
nouvelle couche), mises en cache statique comme les planches de sprites, et utilisées
par `draw_texture_rect` / `draw_set_transform` à la place des primitives. On convertit
**dans l'ordre du gain visible** :

1. `explosion.gd`, `fireball.gd`, `hit_feedback.gd` — ce qu'on voit à chaque coup ;
2. les auras et zones (`immolation`, `holy_pulse`, `sacred_pillar`, `ice_vortex`,
   `storm_cloud`) — les grands aplats, là où un bord net se remarque le plus ;
3. les traits (`chain_lightning`, `holy_beam`, `static_charge`, `dash_trail`) ;
4. le reste, s'il en reste envie.

`hit_feedback.gd` tient la règle à ne pas casser : **un seul nœud dessine tout, sans
allocation par coup**. Une texture ne change rien à ça ; un nœud de particules par
impact, si — d'où l'absence de `GPUParticles2D` dans ce jalon (§5).

### Lot D — la caricature

`config()` uniquement : `head_r`, `sh_w`, `torso_r`, l'échelle de l'arme dans
`_weapon()`. Puis, si 32 px plafonne, `FRAME = 48` — avec `CX = 23.5`, car c'est l'axe
à la demie qui rend la silhouette symétrique au `flip_h`, et `FEET` à revoir dans le
même geste. Le rastériseur ne bouge pas.

Coût : une image de 32×32 coûte **0,265 ms** mesurés, soit 56 ms au premier chargement
d'une zone puis 0 par le cache statique. En 48×48 il y a 2,25 fois plus de pixels ; ce
que ça donne **n'est pas encore mesuré** et se relèvera avant d'écrire un chiffre ici.

### Lot E — le joueur à la main (facultatif, probablement pas dans ce jalon)

La porte de sortie est à moitié ouverte : `[S]` dans la galerie (F4) exporte les
planches dans `art/generated/` — les 16 planches y sont déjà — mais **rien ne les relit**.
`ActorSprite._rebuild()` appelle toujours `SpriteForge.frames()`.

Il manque un override : si `res://art/sheets/<archetype>_v<n>.png` existe, construire les
`SpriteFrames` depuis la planche, sinon forger. Une quinzaine de lignes, et la
cohabitation devient possible — joueur retouché, soixante-neuf ennemis procéduraux. Le
champ vide reste un état normal, comme pour `Skill.icon` et `ItemBase.icon`.

Ce lot est écrit ici pour être **refusé en connaissance de cause** : 24 images par
variante, 4 variantes, 4 archétypes, et il faut que les quatre directions et les deux
temps d'attaque restent cohérents entre eux. `docs/ARCHITECTURE.md` tranche déjà :
« une image immobile se juge une fois ; un sprite qui s'anime dans quatre directions et
cinq variantes, non ».

---

## 5. Arbitrages

**Pourquoi pas tout redessiner à la main.** 4 archétypes × 4 variantes × 24 images =
**384 images**, chacune à garder cohérente avec ses voisines en silhouette, en palette
et en timing. Ce n'est pas un jalon, c'est un métier. Et la forge n'est pas une
commodité qu'on remplacerait : la silhouette d'un ennemi se **déduit de sa case
d'apparition**, c'est ce qui fait qu'une graine de zone redonne le même combat. Des
planches figées gardent cette propriété, un dossier d'images tirées au hasard la perd.

**Pourquoi ComfyUI ne sert pas ici.** Le tuyau existe et il est bon pour ce qu'il fait —
des icônes, qui sont des images immobiles jugées une fois. Il est mauvais pour les deux
besoins de ce jalon :

- **les textures de VFX** : SDXL sort un *objet* dès qu'on lui demande un *phénomène*.
  « a vertical beam of light descending » donne un chandelier, « a godray onto the
  ground » une torche — constaté en ajoutant le manuel sacré. Un blob radial mou, c'est
  un gradient : dix lignes dans `PixelCanvas`, exact, gratuit, en cache ;
- **les planches d'acteurs** : le modèle n'a aucune notion de cohérence entre deux
  images d'une même animation. Chaque frame dériverait. Pour le lot E, l'outil est un
  éditeur de pixels sur les planches exportées, pas un modèle de diffusion.

Donc : **rien dans ce jalon n'a besoin de ComfyUI.** Le serveur ne sera rallumé que si
une nouvelle icône apparaît, ce que ce jalon ne prévoit pas.

**Pourquoi pas de particules GPU.** Un `GPUParticles2D` par impact, c'est un nœud par
impact, et le combat dense en produit des dizaines par seconde — exactement ce que
`HitFeedback` a été écrit pour éviter. Le jour où un effet le demandera vraiment, il se
posera **en un nœud permanent** qu'on émet, pas en un nœud par coup. Hors jalon.

**Pourquoi le glow avant la palette.** Les deux se jugent à l'œil et le premier change
la valeur apparente de toutes les couleurs. Régler la palette d'abord, c'est la régler
contre un rendu qu'on va remplacer.

**Ce qui n'est pas mesuré et qui s'écrira après l'avoir été** : le coût du glow en
images par seconde, le coût d'une image de 48×48, le seuil de glow retenu.

---

## 6. Ce qui refusera un oubli

Le dessin n'a pas d'assertion — « aucune assertion ne voit un panneau qui passe sous un
autre ». Mais trois propriétés de ce jalon sont vérifiables, et deux le sont déjà :

- `test_the_four_player_silhouettes_are_distinguishable` et
  `test_a_silhouette_always_gives_the_same_drawing` (`tests/unit/test_forge.gd`)
  gardent le lot D : une caricature qui écrase les différences entre variantes, ou qui
  réintroduit un tirage, échoue là ;
- `test_outfits_cover_the_variants` garde les quatre tenues si le lot B touche
  `PLAYER_CLOTHS` ;
- **manque, à écrire avec le lot D** : une assertion que le sprite **porte toujours son
  ombre au sol dans son alpha**. C'est l'hypothèse sur laquelle reposent le seuil
  `step(0.5, tex.a)` de `flash.gdshader` et les trois effets qui en dépendent ; un
  changement de `FRAME` ou de `FEET` peut la casser sans qu'aucun test bronche
  aujourd'hui. Forme visée : sur une image de repos, il existe des pixels d'alpha
  strictement entre 0 et 0,5 sous la ligne des pieds ;
- **manque, avec le lot E s'il est fait** : l'override de planche doit se replier sur la
  forge quand le PNG n'existe pas, et donner les mêmes noms d'animations. Un test qui
  charge un archétype sans planche et compte ses animations suffit.

Rien de tout ça ne remplace la capture. **Le lot A et le lot B ne se jugent qu'à
l'image**, en fenêtré : en `--headless`, le pilote de rendu est un bouchon et les
captures sortent vides — et un post-process ne s'y exécute même pas.

---

## 7. Ordre de travail, et ce qui se juge comment

| Lot | Ce qui bouge | Comment on juge |
|---|---|---|
| A | `project.godot`, 2 scènes | capture fenêtrée, zone + arène, un sort de chaque nature ; **banc relancé** |
| B | 5 constantes | capture fenêtrée, mêlée dense sur sol clair **et** sol sombre |
| C | 16 scripts, 1 fonction de `PixelCanvas` | capture par famille d'effet ; `tests/run.sh` (la logique de frappe est couverte, elle ne doit pas broncher) |
| D | `config()`, éventuellement `FRAME` | `tests/run.sh unit` + galerie F4, les quatre variantes des quatre archétypes ; **mesure du coût de forge** |
| E | `sprite_forge.gd`, `actor_sprite.gd` | `tests/run.sh` + galerie |

Le banc à relancer pour le lot A est `world/stress_test.tscn`, graine 4242, en fenêtré,
**après ~240 images de chauffe** — le premier bloc mesure le démarrage (27 img/s contre
165 en régime établi). Référence à battre, ou à ne pas perdre de plus de quelques
pour cent : 165 img/s à 142, 284, 562 et 935 ennemis simulés, et 165 img/s pour
11 ms de physique à 300 ennemis en attaque tenue (`[5]`), 6 % du temps figé.

Un post-process plein écran coûte **par pixel d'écran, pas par ennemi** : si le lot A
se paie, il se paiera pareil à 69 ennemis et à 935, et c'est la ligne à basse charge
qui le dira.

**Doc à mettre à jour dans le même geste**, si les lots passent : le paragraphe de
`docs/ARCHITECTURE.md` sur le rendu procédural (il ne mentionne aucune couche de
rendu), la table « où vit une règle » pour le seuil de glow, et `docs/RECETTES.md` pour
la recette « ajouter un effet visuel » si le lot C crée une primitive de texture.

---

## 8. Hors jalon

- **Les tuiles.** `world/tileset_builder.gd` n'est pas touché. Le sol de Hero Siege est
  plus détaillé et plus contrasté que le nôtre, mais il se juge après les acteurs : un
  sol qu'on regarde est un sol qui a gagné contre ce qui se bat dessus.
- **Une lumière 2D par sort** (`PointLight2D`). Vrai éclairage dynamique, vrai coût, et
  il faudrait un `CanvasModulate` et des normal maps sur les sprites pour que ça donne
  autre chose qu'un rond pâle. Le glow donne 80 % de l'effet pour 0 % de ça.
- **Le shake d'écran et le screen-space distortion d'impact.** Du même registre que le
  glow, moins universels, et le gel d'impact occupe déjà cette place.
- **Les animations en plus** (mort, dégât reçu, sort). Le jeu s'en passe ; ajouter des
  temps d'animation change le ressenti du combat, ce qui est un jalon de jeu, pas de
  visuel.

---

## 9. Livré le 19 septembre 2026

Les quatre lots, dans l'ordre annoncé, chacun jugé sur une capture réelle en fenêtré à
1 280 × 720 — banc `world/stress_test.tscn`, graine 4242, 70 ennemis, aura + nuage
d'orage + pulsation allumés.

### Ce que les captures ont contredit

- **`hdr_2d` est inutilisable.** Il linéarise le canevas et ne le réencode pas : le sol
  tombe de **(71, 66, 61) à (14, 12, 10)**, soit très exactement 0,278^2,2. Tout le jeu
  devient noir. Le réglage reste dans `project.godot` à `false`, écrit plutôt
  qu'absent, pour que personne ne le réessaie sans lire cette ligne ;
- **`glow_bloom` lave l'écran.** À 0,15, il fait entrer le sol lui-même dans le glow
  (71 → 87) : tout se lève, donc le contraste baisse, exactement l'inverse du modèle.
  Laissé à 0 ;
- **le lot B ne parlait pas de saturation mais de valeur.** Mesuré avant : 95 % des
  pixels d'un acteur sont à 0,316 et le sol à 0,29 — **la même valeur**, donc aucune
  séparation figure/fond. Le sol est descendu à 0,21 et les murs l'ont suivi ; c'est ce
  chiffre-là, pas la saturation de la rampe, qui fait ressortir les silhouettes ;
- **un maximum en pointe n'atteint jamais 1,0.** Le premier anneau plafonnait à
  **0,87** — sous le seuil de glow — parce qu'aucun pixel ne tombe pile sur sa crête.
  Les trois dégradés de `fx/glow.gd` ont donc un **plateau** au sommet. Sans le test,
  ça passait pour un choix artistique ;
- **un anneau mou déborde du rayon qu'il annonce.** La première version retombait
  symétriquement de part et d'autre de sa crête, donc son halo allait jusqu'à **1,28
  fois** le rayon où le coup mord — exactement ce que la pulsation sacrée refuse depuis
  son écriture. La retombée est devenue asymétrique : longue à l'intérieur, éteinte un
  pixel avant le bord de l'image. Trouvé à la relecture du diff contre la doc qui
  venait d'être écrite, pas à la capture ;
- **deux pixels par œil donnent un air renfrogné.** Essayé sur la tête grossie du lot D,
  rejeté sur planche : un bandeau sombre, pas un regard. Un œil d'un pixel tient, même
  sur une tête de 9 px.

### Ce qui a été fait

| Lot | Ce qui a bougé |
|---|---|
| A | `fx/bloom.tres` (additif, seuil 0,9, intensité 1,3, niveaux 1-4), un `WorldEnvironment` dans `world/zone.tscn` et `world/test_arena.tscn`, `viewport/hdr_2d=false` écrit explicitement |
| B | `TilesetBuilder.FLOOR_BASE` 0,29 → **0,21**, `WALL_BASE` et `WALL_TOP` d'autant ; `ArtPalette.BASE_STOP` 0,6 → **0,55** et `LIGHT_STRENGTH` 0,42 → **0,52**, plafonnés par le seuil de glow |
| C | `fx/glow.gd` (cœur, anneau, comète) et **17 conversions** dans 14 effets : explosion, immolation, pulsation sacrée, nuage d'orage, boule de feu, vortex, pilier, faisceau, chaîne, charge statique, traînée de ruée, buff, cyclone, pieux, serpent, et l'impact du geste de mêlée |
| D | `SpriteForge.config()` : tête de 3,8 à **4,6** (grunt 5,0, caster 4,0), épaules et buste d'autant, hanches descendues — jambes plus courtes |

**`fx/glow.gd` et non `PixelCanvas`**, contrairement à ce qu'annonçait le §4 : le
rastériseur travaille en (rampe, niveau d'éclairage) pour des silhouettes de sprite, et
un dégradé alpha ne partage rien avec ce modèle. Les textures vivent donc dans `fx/`,
avec le reste des effets.

**`fx/hit_feedback.gd` n'a pas été touché.** Ses éclats sont des carrés d'un pixel posés
sur des coordonnées entières, et son en-tête dit pourquoi : une particule à cheval sur
deux pixels trahit le rendu pixel art. Les adoucir aurait défait un arbitrage mesuré
pour appliquer une recette.

### Ce que ça coûte

**0,05 ms de GPU par image** à 1 280 × 720, glow allumé contre éteint : 0,127 ms contre
0,075, mesuré trois fois en alternance, à ±0,007. Sur les 6 ms d'un budget à 165 img/s,
c'est 0,8 %.

**Piège de mesure, à ne pas réapprendre** : les images par seconde de cette machine ne
mesurent rien — 24, 60, 70, 204, 215, 429 img/s sur la *même* configuration, selon la
place de la fenêtre et l'éditeur ouvert à côté. Seul
`RenderingServer.viewport_get_measured_render_time_gpu()` isole un post-process. Et la
fenêtre de mesure se compte en **pas de physique**, pas en images : à vsync coupée, la
configuration lente joue deux fois plus longtemps que la rapide et ne voit pas la même
scène.

### Ce qui refuse un oubli, maintenant

- `tests/unit/test_glow.gd` (neuf, 4 tests) : le cœur de chaque texture passe 0,95 —
  donc le seuil de glow —, la crête de l'anneau tombe là où `draw_ring` place la
  morsure, la tête de la comète est sur `from`, et une texture n'est construite qu'une
  fois ;
- `test_a_sprite_carries_its_ground_shadow_in_its_alpha` (neuf) : l'ombre au sol est
  toujours dans le canal alpha, ce dont dépend le `step(0.5, tex.a)` de
  `flash.gdshader`. Seize pixels sur une image de repos — les 428 du jalon des assets se
  comptaient sur la planche entière ;
- les trois tests de `test_forge.gd` ont tenu le lot D sans modification.

**829 tests, 829 passent** (824 avant, plus les cinq neufs).

### Ce qui reste

- **`FRAME` est resté à 32.** Le faire passer à 48 ne donne pas « plus de résolution » :
  les coordonnées du squelette sont en pixels de monde, donc un cadre plus grand
  agrandit le personnage **dans la zone**, face à des tuiles de 32. C'est un changement
  de jeu, pas de dessin ;
- **les armes n'ont pas grossi.** La caricature est passée par la tête seule, qui coûte
  huit nombres ; les sept armes de `_weapon()` sont sept séries de longueurs, et l'épée
  de 11 px tient déjà sa place dans la silhouette ;
- **les tuiles n'ont reçu que leur valeur.** Le sol reste un grain uniforme : c'est le
  poste suivant, et le §8 dit pourquoi il vient après les acteurs ;
- **le halo sur le texte du HUD** est le prix du seuil en LDR. Un viewport séparé pour
  l'interface l'enlèverait ; personne ne l'a encore trouvé gênant.

---

## 10. Le vrai défaut, et la deuxième livraison du 19 septembre 2026

Les quatre lots livrés, l'utilisateur a tranché : *« ça ne change pas ce que je veux, ce
que je désire c'est un style pixel art propre tel que Hero Siege »*. Il a raison, et le
§2 de ce document s'était trompé d'ordre : il rangeait la silhouette en quatrième
position derrière le rendu, la palette et la matière des effets. C'était le **premier**
poste, et aucun des trois autres ne pouvait le remplacer.

### Le diagnostic, compté sur une planche

Une image de repos du joueur, agrandie ×10 : **330 pixels opaques, 25 couleurs** —
exactement les 5 rampes × 5 niveaux. Le défaut n'était donc pas le nombre de tons.

Il était dans **qui les place** : un corps assemblé en capsules, dont chaque ton est
déduit d'une formule d'éclairage, change de valeur par pixels isolés et épars. Du
bruit, là où le pixel art propre pose des **bandes franches choisies**. Et rien de ce
qu'une formule ne sait pas déduire n'existait : pas de ceinture, pas de col, pas de
ligne de botte, pas de liseré d'armure, un visage à deux points.

Le plafond de la forge, c'était « des volumes ronds lisibles ». On y était.

### Ce qui a changé

**Les pixels sont écrits à la main, dans le code.** `PixelCanvas.stamp()` pose une
grille — une ligne par rangée, un caractère par pixel — traduite en (rampe, niveau) par
la légende `INK`. Les capsules déduisent leurs tons, une grille les **choisit** ; un
archétype passe par l'un ou l'autre, jamais les deux.

| Archétype | Ce qui est dessiné |
|---|---|
| joueur | 3 corps (face, profil, dos), 3 paires de jambes de face, 3 de profil |
| grunt | 3 corps, 6 paires de jambes — trapu, épaules larges, yeux d'ambre, mâchoire à crocs |
| caster | 3 corps, 3 ourlets de robe — capuche pointue, **aucun visage** : un creux noir et deux braises |
| mannequin | inchangé, il reste un poteau assemblé en capsules |

Trois choses ont été gardées du chemin procédural, et c'est ce qui rend la bascule
petite : le **contour** (posé après coup par `to_image()` sur la silhouette entière,
donc jamais un contour par pièce), l'**ombre au sol** dans le canal alpha, et surtout
l'**arme**, qui reste tracée par `_weapon()` — elle suit l'équipement, elle ne peut pas
être dans une grille. Chaque direction déclare donc le **poignet armé** d'où elle part.

L'animation vient du décalage des grilles : les jambes sont une grille à part posée à
`LEGS_TOP`, le buste respire d'un pixel au-dessus sans emmener les pieds, et sa première
rangée de tunique bouche le trou. `WALK_LEGS` dit quelle paire pour chaque temps de
`WALK_SWING`.

### Ce que les planches ont appris

- **la symétrie n'est pas négociable de face.** Un premier jet avait les cheveux plus
  lourds à gauche « pour la lumière » : ça se lit comme une erreur, pas comme un
  éclairage. La lumière se porte par les **tons** seuls, la silhouette reste symétrique
  — c'est aussi ce qu'impose le `flip_h` du profil ;
- **un trou noir entre deux jambes se lit comme un défaut.** L'entrejambe du grunt était
  en cuir niveau 0 : sur un sol sombre, deux pixels noirs font un accroc. Passé en ombre
  d'étoffe ;
- **une épée tenue à hauteur de ceinture traverse le visage, de profil.** Le poignet du
  profil est donc plus bas et plus en avant que celui de face — un nombre par direction,
  pas une règle générale ;
- **un couperet est plus large qu'une épée** : le grunt de profil a fallu descendre son
  poignet jusqu'à la hanche pour que la lame cesse de recouvrir sa tête ;
- **dessiner dans Godot est trop lent pour dessiner.** Les rampes d'`ArtPalette` ont été
  reproduites en Python, avec la même passe de contour : la boucle passe d'une minute à
  une seconde, et les grilles finales sont recopiées telles quelles. C'est l'atelier qui
  a permis les quinze essais, pas le talent.

### Ce que ça coûte, et ce que ça retire

**829 tests, 829 passent**, sans un test modifié : les trois tests de `test_forge.gd`
tenaient déjà la bonne promesse, et celui de l'ombre au sol écrit au §9 a validé la
bascule sans qu'on y touche.

**Les quatre variantes d'un ennemi ne diffèrent plus que par la teinte.** Le commentaire
de `VARIANTS` promet qu'un paquet de sept grunts ne ressemble pas à sept copies du même
pochoir ; avec une grille par archétype, c'est **exactement** ce que ça devient, à la
nuance de peau près. Trois marques dessinées par variante — cornes, bandeau, balafre —
le rendraient, à raison d'une petite grille posée par-dessus le corps. Laissé à
l'arbitrage : c'est une promesse affaiblie sciemment, pas un oubli.

---

## 11. Les tuiles, par ComfyUI — troisième livraison du 19 septembre 2026

Les acteurs propres, le sol devenait le poste faible. La question posée était : peut-on
**partir d'un pixel art généré** ? La réponse mesurée est oui, mais pas pour tout — et
le décor est justement l'endroit où ça marche, parce qu'il est **statique** : aucune
cohérence d'animation à tenir, aucune symétrie de `flip_h`, et une tolérance au bruit
qu'un visage de 9 px n'a pas.

`tools/tiles.py` (`gen` / `make`) reprend le moteur de `tools/item_icons.py` — SDXL +
`pixel-art-xl`, mêmes réglages qu'au jalon 11 — avec deux différences qui comptent.

**Le négatif est devenu un paramètre.** Celui des objets refuse « tiled pattern » et
« grid » : posé sur une tuile, il combat exactement ce qu'on demande.
`item_icons.workflow()` et `render()` prennent donc un `neg` optionnel, par défaut
l'ancien. *(Au passage : `skill_icons.py` déclare son propre `NEG` mais appelle le
`render` des objets — son négatif n'a jamais servi. Non corrigé, ce n'est pas ce jalon.)*

**Le modèle donne la matière, le code garde la règle.** La génération décide du grain,
des fissures, de la distribution des valeurs. Elle ne décide ni la valeur du sol, ni
quelle tuile de mur porte son dessus éclairé — ça reste peint par sept rangées de code,
comme avant, parce que c'est cette bande-là qui fait lire une masse de murs comme des
blocs et non comme un empilement de briques.

### Les deux chiffres qui ont tout décidé

- **l'échelle de la découpe.** SDXL rend un pavage de briques de ~25 px sur 1024 : réduit
  à 32, chaque pierre pèse **un pixel** et il ne reste qu'un grain gris. Six découpes
  comparées sur planche : à **10 %** du rendu, une pierre fait six pixels et le sol se
  lit. Au-delà de 24 %, c'est du bruit. Ce seul nombre sépare « une texture » de « du
  pixel art » ;
- **à moyenne égale, une texture se lit plus claire qu'un aplat.** Première intégration :
  le sol généré recentré sur la luminance exacte de `FLOOR_BASE` (0,196), c'est-à-dire
  *la même valeur moyenne* que le sol procédural. À la capture, les ennemis s'y
  noyaient : ce sont les joints clairs qui accrochent l'œil, pas la moyenne. Descendu à
  **0,150**, l'écart avec les acteurs redevient celui du §9.

Mesuré sur les trois états, sur la même bande d'image :

| | sol | acteurs (p95) | écart |
|---|---|---|---|
| avant le jalon 24 | 0,262 | 0,316 | **0,053** |
| sprites dessinés, sol procédural | 0,188 | 0,476 | **0,289** |
| sprites dessinés, sol généré | 0,146 | 0,405 | **0,259** |

Le sol généré coûte 0,03 d'écart au sol procédural, et en rend cinq fois plus que l'état
de départ. C'est le prix d'une pierre appareillée, et il est payé sciemment.

### Ce qui a aussi été appris

- **une couture ne se ferme pas par un fondu.** Deux méthodes essayées avant la bonne.
  Fondre au centre après un demi-décalage raccorde la tuile **avec elle-même**, pas avec
  sa voisine : la ligne sombre revenait tous les 32 px. Fondre la dernière bande dans la
  première ferme bien la couture, mais **bave sur cinq pixels de chaque bord**, et cette
  bavure redessine la grille de tuiles à l'écran — pire que le défaut qu'elle corrige.
  La bonne méthode ne touche aucun pixel : on **cherche** parmi quelques centaines de
  découpes celles dont le bord gauche ressemble déjà au bord droit (`best_offsets`,
  erreur de raccord 0,046 sur le sol retenu) ;
- **les quatre variantes doivent partager leur normalisation.** Étirée chacune sur ses
  propres extrêmes, une découpe sombre et une claire ressortent à la même moyenne, et le
  sol devient un patchwork dès qu'elles se touchent. La fenêtre se mesure une fois sur
  le rendu entier ;
- **faire varier la position des découpes, pas leur taille.** Quatre tailles voisines
  donnent quatre échelles de pierre, ce qui se voit immédiatement quand elles se
  touchent.

### Le défaut que l'utilisateur a vu, et la règle qui le corrige

Première intégration livrée, son verdict : *« on dirait que le sol est un mur mais peint
d'une autre couleur »*. Exact, et deux fautes se cumulaient.

La première est un prompt. « dungeon stone floor » sort **un mur de briques** à tous les
coups — le modèle n'a pas de notion de point de vue, il a une notion de maçonnerie. Il
faut la lui interdire explicitement : `brick, brickwork, masonry, mortar lines, regular
rows, running bond, wall, vertical surface` dans le négatif. Les rendus deviennent alors
de vrais sols : dalles irrégulières, pavés ronds, terre battue.

La seconde est plus intéressante, parce qu'elle ne se voit sur **aucun rendu isolé** :

> **Une texture qui couvre son cadre d'un bord à l'autre est une paroi, quelle que soit
> sa couleur.** Un mur est couvert de pierre ; un sol, c'est de la terre avec quelques
> pierres dessus.

Baisser l'amplitude ne suffit pas — ça garde le contour de chaque caillou, donc le
quadrillage. Il faut une rareté **spatiale** : on étiquette les amas de la texture
(`ndimage.label`) et on n'en garde que quelques-uns par tuile, le reste retombant à
16 % de son relief. Et **la tuile qui domine la carte est nue** : `FLOOR_PATCHES =
(0, 3, 4, 5)`. Cette dernière règle était déjà écrite dans le dessin procédural — « tuile
neutre, celle qui domine » —, elle avait juste été perdue en chemin.

Mesuré sur la même bande d'image : l'écart-type du sol passe de **0,034** (pierre
partout) à **0,024** (terre et amas). Il est devenu calme, pas seulement plus sombre.

`TilesetBuilder` charge `art/tiles/atlas.png` s'il existe et retombe sinon sur sa
peinture procédurale — le même partage que `SpriteForge.ART` et les capsules : **une
image qu'on peut juger une fois est un fichier, ce qui s'anime reste du code.**

**829 tests, 829 passent**, aucun modifié : aucune assertion ne voit une tuile, et c'est
écrit dans la recette.

---

## 12. L'arène — quatrième livraison du 19 septembre 2026

Le décor propre, la demande suivante portait sur la **forme** des zones et non plus sur
leur dessin : *« d'assez grands endroits libres de bouger et quelques obstacles ici et
là »*. C'est la définition d'une arène de Hero Siege, et l'inverse d'une caverne.

**L'algorithme n'a pas changé d'une ligne.** L'automate cellulaire de `MapGenerator`
sait déjà faire les deux : tout tient dans `fill_chance`, et il était réglé sur la
caverne. Quinze combinaisons mesurées — part de sol, nombre d'obstacles distincts qui ne
touchent pas l'enceinte, taille médiane, et **distance médiane d'une case de sol au
premier mur**, qui est la seule qui dise « place pour bouger ».

| | sol | obstacles | taille médiane | dist. médiane | **sol à ≥ 4 tuiles d'un mur** | fragments perdus |
|---|---|---|---|---|---|---|
| 0,45 / 5 (caverne) | 58,8 % | 31 | 14 | 2 | **12,7 %** | 283 |
| **0,37 / 6 (arène)** | **83,1 %** | **17** | **20** | **4** | **61,9 %** | **0** |

Le chiffre qui compte est le dernier de la ligne visible : **on passe de 13 % à 62 % du
sol où l'on peut tourner autour d'un ennemi**. Le reste en découle.

Deux réglages plutôt qu'un : à `fill` égal, **cinq passes de lissage donnent 29 cailloux
là où six en donnent 17, plus gros**. Un obstacle de 20 cases fait quatre tuiles sur
cinq — un éperon rocheux ; un de 7 cases est un caillou qu'on ne voit pas. Retenu 0,37 /
6, ce qui donne environ **1,7 obstacle par écran**.

Trois choses vérifiées avant de changer le chiffre, parce qu'elles auraient pu l'interdire :

- **le peuplement ne s'exprime pas en densité** mais en **14 paquets** de 3 à 7
  (`EnemySpawner.pack_count`). Ouvrir la carte ne change donc pas le nombre d'ennemis —
  68 à la graine 4242 contre 69 avant, l'écart d'un seul venant d'un paquet qui place un
  corps de moins. En revanche **ils s'étalent sur 41 % de sol en plus** : à paquets
  constants, on croise donc moins de monde par écran. C'est une décision de jeu, laissée
  à l'arbitrage — `pack_count` à 20 rendrait la densité d'avant ;
- **plus aucun fragment n'est perdu.** `_keep_largest_region()` bouchait 283 cases de
  poches isolées à 0,45 ; à 0,37 il n'en bouche **aucune**. La carte est d'un seul tenant
  par construction, ce qui n'était pas garanti ;
- **la valeur n'était écrite qu'à moitié au bon endroit.** `map_debug.gd` recopiait
  `0.45` et `5` pour son écran de réglage : deux valeurs qui auraient fini par mentir sur
  ce qu'on règle. Elles sont devenues `MapGenerator.DEFAULT_FILL` et
  `DEFAULT_ITERATIONS`, que l'écran lit.

**829 tests, 829 passent.** Un a dû changer : `EXPECTED_ENEMIES` passe de 69 à 68 dans
`tests/e2e/test_zone.gd`. Ce n'est pas un chiffre ajusté pour faire passer un test —
c'est une référence **attachée à un réglage de génération**, et son commentaire dit
désormais lequel, pour que la prochaine session sache à quoi elle est accrochée.

---

## 13. La foudre — cinquième livraison du 19 septembre 2026

Demandé : de **vrais** visuels pour les gestes du manuel de la foudre. Ils étaient au
jalon 11 ce que le §2 reprochait à tout le reste : de la géométrie correcte. Un trait
brisé de trois pixels, un filament d'un pixel, un disque à chaque nœud.

**Un seul endroit, `fx/lightning.gd`**, pour les cinq gestes électriques du jeu : la
chaîne, les éclairs du nuage, les bras de la charge statique, la traînée de la Ruée
d'orage et le projectile de nature foudre. `ChainLightning.broken()` y a déménagé et
disparu : un nuage qui appelait une fonction d'une *compétence* pour dessiner son éclair
disait déjà que la règle manquait d'un toit.

Ce qui fait un éclair plutôt qu'un fil électrique, et qui n'y était pas :

- **des fourches.** Deux branches mortes qui repartent de biais, parfois vers l'arrière,
  sur 16 à 34 % de la portée. Une seule chose sépare une décharge d'un câble, c'est
  qu'elle rate ;
- **trois passes au lieu de deux** : un halo large à 0,10, un corps à 0,28, un filament
  à 1. Le halo porte **la couleur**, le filament porte **la lumière** ;
- **un battement, pas un fondu.** La forme tient 1/18ᵉ de seconde (`Lightning.hold`,
  combiné à la graine du nœud pour que deux éclairs voisins ne battent pas à l'unisson)
  et l'opacité de la chaîne descend par quatre paliers. À une forme par image, l'œil ne
  voit plus un éclair mais du bruit ;
- **un éclat à l'impact**, teinté large et blanc minuscule.

### Trois chiffres, et deux d'entre eux ont demandé une capture

- **Le violet de la foudre plafonne à 0,63 de luminance** (`DamageType.COLORS[3]`), et le
  seuil de glow est à 0,9. Un éclair entièrement teinté **ne peut pas briller**, quelle
  que soit son opacité — le cœur d'avant, à 0,55 vers le blanc, arrivait à 0,79 et
  restait sous le seuil. À 0,92 vers le blanc, il passe. C'est le seul pixel de l'éclair
  qui a le droit d'être presque blanc ;
- **les passes teintées ont une largeur plancher** (4 et 2,2 px). Sans elle, un
  projectile dessiné à 0,55 d'échelle donnait un halo d'1,65 px : invisible derrière le
  filament, donc un éclair **blanc**, qui se lit comme un éclat physique. Constaté à la
  capture, pas au calcul ;
- **l'éclat d'impact est passé de 6 à 4 de rayon, et son blanc à un tiers.** Un disque
  blanchi de rayon 6 fait **26 pixels à l'écran** — le facteur 2 du cadrage se paie ici
  —, et les deux ennemis frappés disparaissaient dessous. Première capture de la chaîne :
  une tache blanche à la place du combat.

Le projectile est le seul écart par nature du jeu : `Projectile._draw()` branche sur
`nature()` et dessine un éclair couché sur sa trajectoire au lieu de la bille à
auréoles. C'est assumé, et écrit dans le code : la foudre est la seule matière qui ait
une **forme** propre, les autres sont des boules qui brillent.

**829 tests, 829 passent**, aucun modifié.

### Un piège d'atelier, pas de jeu

Trois exemplaires du même manuel dans trois cases du râtelier donnent **zéro point** :
le râtelier ne cumule pas deux copies d'un même livre. Et `Player.study()` vide la barre
de toutes les compétences du manuel qu'on pose, donc poser la case juste après chaque
étude la fait effacer par la suivante. Les deux ont coûté deux captures vides avant
qu'un `print` des points ne le dise. Pour piloter plusieurs gestes d'un même manuel :
**un seul livre, tous les `invest`, puis les cases de barre**.
