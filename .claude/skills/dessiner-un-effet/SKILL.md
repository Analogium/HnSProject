---
name: dessiner-un-effet
description: La méthode visuelle du projet pour tout effet, geste de compétence ou icône, en 3D depuis le jalon 54 — planche de variantes posées dans une vraie zone et choisie par l'utilisateur, puis l'effet en shaders, particules ou modèle sous la lumière du jeu, captures réelles déposées sur le Bureau, coût mesuré, doc à jour. À invoquer dès qu'on crée ou refait le visuel d'une compétence, d'un manuel, d'un effet ou d'une icône, ou qu'on ajoute une compétence qui en a besoin.
---

# Dessiner un effet

La méthode est née au jalon 24, qui a redessiné en pixel art les manuels de feu, de glace,
du sacré et du maître d'armes. Elle est passée en 3D au jalon 54. L'utilisateur veut
qu'elle serve **à chaque fois**, et son principe tient toujours : **l'utilisateur choisit
sur pièce, jamais sur description**. Il choisit vite quand on lui montre des images. Quand
on lui demande ce qui manque, il a du mal à le dire.

Les règles en vigueur sont dans `docs/ARCHITECTURE.md`, aux lignes « Que montre une
compétence en 3D ? », « Comment un ennemi prévient-il de son attaque ? » et « Comment voiler
les sorts… ». Le raisonnement et les chiffres sont au jalon 54, §13. Lire ces documents
avant de commencer : ce skill dit **dans quel ordre** faire les choses, il ne les remplace
pas.

## 1. Lire l'existant

- Trouver les gestes concernés dans `resources/skills/*.tres` (`shape`, `nature`), puis le
  nœud qui les montre dans `actors/skills/` ou `actors/player/`.
- Ce nœud montre déjà le **visuel générique** de sa nature : une ligne `ElementFx.trail`,
  `burst`, `sweep`, `area`, `line` ou `keep` à sa naissance. Le dessin propre **remplace
  cette ligne**, sauf si la planche garde les étincelles en plus.
- **Le parti pris de la 2D** (jalons 24 à 53) reste la référence de ce que l'utilisateur
  a déjà choisi sur planche : la comète du projectile, la croix gravée du coup de grâce,
  le cercle runique des glyphes… Il est écrit dans les lignes « À quoi ressemble… »
  d'ARCHITECTURE. On le porte en 3D, on ne le redécide pas sans planche. Les grilles
  d'`EffectForge` et les fichiers `fx/` en 2D ne tournent plus depuis l'étape 1.
- **« Ça ne marche pas » peut être un visuel** : compter d'abord ce qui naît, image par image
  (`is` et non `find_children()` avec un nom de classe de script, qui ne le reconnaît pas). La
  Fragmentation lâchait bien ses éclats, mais ils avaient l'allure de la boule et naissaient
  dans l'éclair de l'explosion.
- **« Trop pauvre » se corrige en habillant le geste**, pas en changeant de matière : des
  Pics de glace lisses qui rentraient sous terre ont été refusés ; avec un éclair de lumière
  portée, le sol touché (les fissures de la Ruée, en givre) et une fin qui se brise en
  esquilles, ils ont plu — dans le cercle qui frappe, éteints en moins d'une seconde. Un sort
  qu'on lance sans cesse garde la version sobre : la brume a été écartée.
  La matière peut être changée quand même.
- **Une aura qui dure reste sobre** : elle tourne sous les yeux pendant tout le combat.
  L'Immolation en couronne de flammes et en brasier plein a été jugée trop chargée ; un liseré
  et quelques flammèches ont été retenus.
- **Demander une référence** si l'utilisateur en a une : au jalon 54, cinq variantes de
  boule de feu (particules, plasma, couronne, toon, lave) lui ont paru « pas assez
  parlantes » ; une capture de Path of Exile a tranché, et la planche suivante en a décliné
  quatre façons.
- **Une compétence se dessine en textures vraies**, elle et ses variantes d'arbre (décision de
  l'utilisateur, 20 octobre) : une Ruée ardente toute en shader (bruit, langues, flammèches) a
  été jugée « cheap » ; refaite d'un scan de terre craquelée (Poly Haven, CC0), elle a été
  retenue, puis le Serpent a pris une peau photographiée. La planche compare des textures, et
  `tools/fx_textures.py` tire celle choisie. Qwen-Image peint de bonnes
  **flammes photographiques sur fond noir** (additionnées, le noir disparaît ; tournées vers la
  caméra en entier, debout elles sortaient tassées), mais un sol « vu de dessus » lui sort en
  étoile de lave, pas en texture qui se répète.
- **La barre est Last Epoch** (décision de l'utilisateur, 25 octobre) : « un jeu beau », pas un
  sort qui se lit. Un sort y est **une pile de couches**, chacune une technique — la Nova de glace
  (`IceNovaFx`) en est le gabarit : une onde maillée dont une texture vraie défile, **rongée**
  (dissolve à liseré, plutôt qu'un fondu ou un rétrécissement) ; une distorsion sur le front ; des
  éclats qui se rongent ; **un `Decal`** au sol, qui épouse le relief ; des scintillements ; une
  lumière. La planche oppose la pile à l'actuelle, et une pile privée d'une couche à la pile entière :
  c'est ainsi que la brume en flipbook a été écartée. **Une texture recyclée d'un autre sort se dit**,
  et la planche de textures ComfyUI se propose d'office. Le flipbook (fumée, explosion) se rend dans
  Blender, `tools/blender/mist_flipbook.py`. Qwen sort le « givre au sol » en feuilles de fougère :
  une glace craquelée vue de dessus lui réussit. Un décal se teinte au cyan (le soleil blanchit un
  albédo clair) et reste bas, sinon il se projette sur les corps.
  Au feu (26 octobre) : **une distorsion se dessine avant le feu** (`render_priority`) — l'écran qu'elle
  relit n'a pas les effets, posée après elle effaçait les flammes ; **un liseré brûlant prend le milieu de la
  rampe**, pas son cœur multiplié, qui sortait blanc ; et ce qui naît au fil du temps (des braises) se
  sème **par seconde**, pas par image — l'écran tourne à 165 Hz. **Un dessin ne promet pas une
  mécanique absente** : la glace au sol se lit « sol gelé », et l'utilisateur l'a fait retirer de tout
  sort qui ne gèle pas le sol (26 octobre). Ce qui couvre large reste sous 0,75
  d'opacité : un tourbillon de 104 px, plus opaque, sortait en disque blanc. Des éclats qui doivent se
  montrer à un instant précis (planche, tests) volent en `MultiMesh` balistique, pas en particules
  (`IceSpikesFx.Flight`). Une brume photographiée derrière des cristaux se trie derrière eux
  (`sorting_offset`), sinon elle les grise. Un grand cristal à demi rongé sort en papier déchiré
  blanc : le ronger vite.
- **La silhouette d'abord, la matière ensuite.** Étirée en dard de 34 px, une photo d'arc
  électrique sortait en plume ou en fumée : « ça ne ressemble pas à un éclair ». Le zigzag est
  venu d'un ruban que le shader casse, qui porte la photo — comme la peau du Serpent sur son
  corps ; puis une capture de Kinetic Bolt (Path of Exile) a tranché, comme celle de la boule de
  feu : un orbe qui zigzague autour de sa trajectoire et une traînée qui en garde la forme. Qwen sort des arcs plumeux au tronc droit, même quand on demande des
  angles vifs. Une photo au cœur blanc, passée par la rampe de sa nature, perd ce cœur : le
  garder en haut de la rampe (`fx/lightning_common.gdshaderinc`).
- La teinte vient de `DamageType.COLORS[nature]`. Un sort qui change d'élément a **un
  dessin par élément** quand une simple teinte n'a pas de sens, comme un éclair en feu.

## 2. La planche d'abord

Rendre **4 à 7 variantes aux partis pris francs**. Une variante timide ne se remarque pas
sur la planche. Montrer **le geste**, pas le dessin isolé : à deux instants au moins (30 et
80 % pour ce qui se remplit), et dans les trois natures qu'il prend.

- **Une planche 3D se rend dans le vrai jeu, en fenêtré.** En `--headless`, le pilote de
  rendu est un bouchon et les captures sortent vides. On écrit un scénario `extends Node`
  dans le scratchpad, sur le modèle de `tools/capture_scenario.gd` : il entre en zone
  (`enter_area(1)`), cache l'interface (`overlay`), vide les ennemis (`kill_all()`), puis
  pose ses variantes autour du joueur. Chacune est un `MeshInstance3D` au shader écrit
  dans le script, des `GPUParticles3D`, ou les deux. Il capture
  (`get_viewport().get_texture().get_image().save_png("user://<n>-<nom>-<instant>.png")`)
  puis quitte. On le lance par `tools/capture.sh <scénario>.gd <sujet>`, qui dépose les
  images dans `C:\Users\Theo\Desktop\hns-captures-<sujet>\`.
- **Le joueur naît au bord de la carte** : ce qui est posé trop loin tombe dans la falaise.
  Recentrer, et assombrir le rouge clair, qui se fond dans l'ocre. Un effet au sol lancé
  contre la falaise sort **coupé en carré** — le plateau, plus haut que lui, le masque case
  par case : `warp` le joueur vers un coin dégagé avant de capturer (Nova de glace). Figer la zone
  (`Game.rng.seed` avant `enter_area`) pour que deux rendus se comparent.
- **L'horloge d'une planche lit le vrai `delta`** (plafonné, une prise fige le jeu) : à un soixantième
  par image, elle courait 2,75 fois trop vite à 165 Hz et les fins n'étaient jamais atteintes.
- **Faire un premier passage à blanc** : chaque matière neuve se compile ~100 ms à sa
  première image, et ce qui vole saute d'autant (des perles dans une traînée).
- **Montrer une boule en vol avec sa traînée entière** : elle part assez tôt pour avoir
  parcouru sa longueur à l'instant de la capture.
- **Regarder la planche soi-même d'abord**, avec l'outil Read, recadrée et agrandie par PIL.
  Remplacer toute variante manifestement ratée avant de la montrer : au jalon 54,
  « l'énergie » sortait en rond blanc déchiqueté.
- Numéroter les fichiers dans l'ordre du récit, donner le chemin Windows, puis poser la
  question avec `AskUserQuestion`. Mettre une option par variante, dont la description dit
  ce qu'on y voit. **Ne rien implémenter avant la réponse.**
- **Une icône** reste en 2D. Elle suit le même principe avec `tools/skill_icons.py` et la
  recette de `resources/icons/LISEZMOI.md` : une planche de 4 sujets × 3 graines, à côté
  des icônes déjà posées du manuel, rendue par `tools/planche.sh` (pur calcul, headless).
  Inscrire ensuite sujet et graine dans `tools/skill_icons.json` et lancer
  `apply --only <id>`. ComfyUI tourne sur l'hôte Windows (`ip route`) : le lancer avec le
  bac à sable désactivé.
- **Un personnage, une créature ou un objet qui a un corps** ne se dessine pas en shader :
  joueur, ennemi, rat, corbeau, invocation, marmite. Il passe par un modèle :
  `tools/model_3d.py`, TRELLIS.2 au quota du jour, gréage Mixamo, puis
  `tools/blender_sheet.py --glb`. On montre ses animations sous la lumière du jeu
  (`tools/look_3d.gd`). Recette et pièges : `tools/characters/LISEZMOI.md`, « En 3D ».
  **Une forme simple qui suit des points du jeu** (le Serpent infernal le long de ses
  anneaux) se construit plutôt : une grille fixe que le shader courbe (`SerpentBody`). Une
  silhouette d'abord — un ruban de feu « ne disait pas serpent », un corps à tête en losange,
  cou pincé et queue effilée, si.

## 3. Dessiner dans la langue du monde

Les règles qui ne se discutent plus, toutes payées d'une capture ratée :

1. **Une couleur mêlée reste sous 1.** Le tonemapping ACES et la lueur, au seuil de 1,
   blanchissent tout ce qui le dépasse : feu, froid et foudre sortaient du même blanc. Mais
   mêlée vers le blanc, une teinte sort **beige sur l'ocre** : une rampe par élément,
   saturée (cœur, milieu, profond, bord), comme `FlameFx.RAMPS`. **Ce qui est de la
   lumière s'additionne** (`blend_add`, couches à moitié de leur couleur) : sous le soleil
   du sol ocre, une flamme mêlée sortait peinte et terne. Saturée, la somme qui passe 1
   monte au jaune et la lueur garde sa teinte. **La glace n'est pas de la lumière** : additionné à l'ocre,
   le cyan sortait blanc ; ses photos se mêlent au sol, l'alpha tiré de leur clarté (`fx/frost_photo.gdshader`).
2. **L'opacité du menu passe par le shader.** `Settings.veil(nœud, groupe)` se pose à la
   naissance. Tout shader d'effet déclare `instance uniform float opacity = 1.0;` et la
   multiplie dans `ALPHA`, parce que `transparency` ne fait rien sur un shader qui écrit
   `ALPHA` (mesuré). Ce qu'un nœud fait naître hors de lui reprend ses groupes, comme
   `ElementFx._make()`.
3. **Shader d'effet** : `unshaded`, `depth_draw_never`, `cull_disabled`, ombres coupées. Un
   effet au sol flotte d'un rien au-dessus du relief (`DangerZone.LIFT`). Une géométrie
   **à la taille de sa forme**, tournée vers son cap (`rotation.y = -Flat.angle(cap)`) :
   un couloir de charge dans un carré aurait couvert 340 px, presque tout jeté. Un contour
   d'épaisseur égale se calcule en distance au bord, forme par forme (`danger_zone.gdshader`).
4. **Une flamme posée se dresse** : vue d'en haut, une flammèche ronde qui monte ne se voit
   pas monter — des bulles. Une langue de feu est un quad debout, tourné vers la caméra autour
   de la verticale, posé par sa base (`fx/flame_tongue.gdshader`).
5. **Particules** : `fixed_fps = 0`, sinon les tirs rapides laissent des perles. Ce qui bouge
   au pas de physique, l'interpolation du moteur le lisse (ARCHITECTURE, « Le mouvement entre deux
   pas ») ; ce qui ne bouge que pour se montrer (un météore qui tombe, le zigzag de `BoltFx`)
   **bouge dans `_process()`**, en `PHYSICS_INTERPOLATION_MODE_OFF`, et ce qui y suit un corps lit
   `get_global_transform_interpolated()` — sinon il traîne d'un pas et « ça lag » ;
   `local_coords = false` pour une traînée ; un point doux, pas un carré. Quelques pièges :
   - `finished` ne vient jamais sans rendu, donc ce qui se libère passe par une minuterie ;
   - changer `amount` relance l'émetteur, donc on change la matière (`ElementFx.keep()`) ;
   - un émetteur posé parmi les projectiles fausse les tests qui en comptent les enfants :
     il vit à la racine du viewport et suit son porteur.
6. **Les matières se gardent**, par teinte et par forme (`ElementFx._process_material`). Une
   matière fabriquée à chaque tir repart au GPU à chaque fois. **Et elles se chauffent** :
   la première apparition d'une matière gèle le jeu ~100 ms ; elle entre dans
   `ElementFx.warm()`, qui la fait paraître invisible au chargement de la zone.
   **Le bruit se calcule dans le shader** (`fx/flame_common.gdshaderinc`) : une
   `NoiseTexture2D` se génère en différé, la première boule partait sans.
7. **Un effet ne se colle pas à la lumière** : il ne prend pas d'ombre et n'en jette pas.
   **Mais il peut en porter** : une `OmniLight3D` sans ombre sur ce qui brûle éclaire le
   sol autour (la boule de feu, l'éclair de son explosion), et c'est ce qui le fait vivre.
8. **Un maillage fabriqué montre ses faces dans le bon sens** : retournées, la caméra voit le
   dedans du fond, et rien ne lui donne de volume — le serpent sortait « dessin plat » à
   chaque retouche de matière. Le vérifier avant de régler la lumière. **Godot tient pour
   face avant l'ordre horaire vu de devant** : des Pics de glace enroulés à l'inverse
   sortaient en silhouettes blanches, le reflet de bord au maximum sur le dedans.
   Et `Basis.scaled()` étire en repère **global** : ce qu'on a vu sur planche, il faut le
   refaire dans le même ordre (`Basis.from_scale(s) * rotation`).
9. **1 unité = 1 px du jeu 2D** (`Flat.PX_PER_M` = 16 pour Blender) : une portée de
   compétence se lit telle quelle comme une taille d'effet.

## 4. Mesurer ce qui coûte

On n'écrit un chiffre de performance qu'après l'avoir mesuré, sur un **banc A/B** :
`world/stress_test.tscn` sur deux copies, A l'effet coupé et B l'arbre courant, avec 300
ennemis en combat, sans vsync, 240 images de chauffe puis 1 440 mesurées, cinq paires au
moins **en alternant l'ordre**. La machine varie : le 19 octobre, la même configuration
allait de 3,2 à 9,5 ms l'image. On compare les moyennes de B − A, jamais une paire seule.

## 5. Capturer en jeu

- Recopier `tools/capture_scenario.gd` dans le scratchpad et n'éditer que ses constantes :
  manuel, compétences, nœuds (avec leurs parents, dans l'ordre), baguette, cap, frise —
  `["area"]` d'abord pour jouer en zone, `["pack"]` pour avoir sur quoi exploser. Puis
  lancer `tools/capture.sh <copie>.gd <sujet>`. Ce script tue les processus `hns-` : ne
  jamais capturer pendant que les tests tournent.
- **Une capture fige le jeu ~110 ms** : le gabarit garde les images en mémoire et les écrit
  à `quit`. Écrites au fil de la frise, elles cassaient la traînée en bouffées.
- Recadrer et agrandir les captures avec PIL, et les regarder **soi-même**. Au jalon 54,
  des étincelles de 4 px ne se voyaient pas en combat, et les tirs rapides laissaient des
  perles : ces défauts ne se sont vus qu'à la capture.
- Corriger et recapturer tant que ça ne tient pas. Puis laisser les images retenues sur le
  Bureau, numérotées à la suite.

## 6. Livrer

- **Tests**, comme `tests/integration/test_element_fx.gd` : l'effet suit son porteur et lui
  survit le temps de retomber, ce qui finit se libère, le voile atteint le shader, et ce
  qui se garde est repris plutôt que refait.
- **Supprimer ce que la livraison rend mort**, avec ses tests : l'appel `ElementFx` remplacé,
  et le morceau 2D de ce geste dans `EffectForge` ou `fx/`.
- `tests/run.sh` complet. La suite unitaire seule ne charge pas les nœuds de compétence :
  elle peut passer alors que le jeu ne compile plus.
- **La doc dans le même geste** :
  - la ligne « Que montre une compétence en 3D ? » de `docs/ARCHITECTURE.md`, et la ligne
    « À quoi ressemble… » du geste ;
  - `docs/RECETTES.md`, si un fichier `fx/` apparaît ;
  - une section au jalon en cours, avec **le choix fait sur planche**, **les erreurs vues
    à la capture** et **les chiffres mesurés**.
- Contenu touché (`.tres`) : lancer `tools/catalog.sh`, puis `tools/balance.sh calculation`.
- Rendre compte : les chemins des images sur le Bureau, ce qui a été choisi, ce que les
  captures ont corrigé. Ne pas commiter.
