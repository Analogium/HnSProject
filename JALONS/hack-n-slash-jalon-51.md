# Hack'n'slash top-down — jalon 51

Suite des jalons 1 à 50. Ce document ne redit pas ce qui y est déjà écrit, et
`docs/ARCHITECTURE.md` reste le seul endroit qui décrit l'état courant.

**Ouvert le 14 octobre 2026.** Une troisième classe, le **joueur de flûte** (`piper`) :
d'abord le personnage seul, manuel vide, pour juger s'il plaît.

---

## 1. Ce que l'utilisateur a demandé

Une classe centrée sur les attaques et les sorts, sur le thème des rats et de la musique,
qui pourra **combiner ses rats invoqués sur sa personne pour devenir le Roi des Rats** —
deux visuels, et une animation de transformation. Son concept (une planche faite
ailleurs : manteau mi-parti moutarde / cramoisi, chapeau pointu à couronne de dents, flûte
d'os, rats) sert de référence.

Puis : **la flûte est un détail important**. Pour les compétences de **son manuel**, et
d'elles seules, il joue avec sa flûte ; pour celles des autres manuels, avec l'arme
équipée. Du dessin, rien d'autre.

## 2. Le personnage

Par `tools/character_forge.py` (`tools/characters/piper.json`) :

- **Concept** : la planche de l'utilisateur, recadrée, pastilles effacées, fond gris.
- **Vues** : le visage pâle sortait en **crâne** et le chapeau en bord large — d'où
  le champ `neg` de l'outil. Graine 2024, la seule au chapeau pointu et au dos vu de dos.
- **Gestes** : graine 4242 partout ; la 777 perdait le chapeau en capuche.
- **Taille 40** et non 34 : chapeau et manteau long écrasaient la tête. Visage retouché.
- **Le manteau mi-parti**, que SDXL ne coupe pas en deux : recoloré par moitié (`cols`,
  `val_mul`). Choisi sur planche parmi quatre : **profil moutarde** (variante 2). Les
  chausses inversées ne se voyaient pas à 40 px.

Piège payé : les `anchors` recopiés du Vive lame tassaient aussi la tête.

## 3. La flûte

Choisie sur planche parmi cinq (droite à trous, fémur, pavillon, flûte de Pan, queue de
rat) : **droite à trous**, un cas `flute` de `SpriteForge._weapon()`.

`Character.CLASSES[…]["instrument"]` → `Player.instrument` au chargement →
`Player.held_for()` (le livre de la compétence est-il le manuel de classe ?) →
`ActorSprite.attack(held)`, qui prend les planches de l'instrument le temps du geste
et rend celles de l'arme en finissant.

## 4. Les proportions des trois classes

« J'ai un problème avec les visuels et leurs proportions, sur cette classe comme sur les
précédentes. » Sur planche : **pas cohérentes entre elles**, **profils trop maigres**.
Aucun réglage de longueur ou de taille seul ne répondait.

Mesure : du cou aux chevilles, les corps faisaient 15 à 17 px — l'écart venait surtout
de `slim` (0,68 à 0,9) et du chapeau compté dans `height`. Retenu sur planche (ligne 5
de `proportions-2.png`) : **une règle commune** — `body` 16, `slim` 0,9, `squash` 0,8 —
et les profils élargis de 1,3 (`side_width`). Tailles en jeu : 34, 37, 37.

Ce que la règle ne rattrape pas : la **tête du joueur de flûte** reste plus petite, et
son **profil** plus fin — c'est son dessin source (concept adulte), pas un réglage.

## 5. Les personnages en 3D

Après les proportions, l'utilisateur a rejeté **le rendu lui-même**. Sa référence est
le rendu en jeu de Hero Siege. Le chemin 2D (des images générées, réduites puis
retouchées) **perdait trop de détails** dès que le personnage bougeait ou quittait la
face. Deux contraintes posées : « prêt à ajouter des logiciels, du moment que ça reste
clair », et **ne rien payer**.

La chaîne retenue (recette : `tools/characters/LISEZMOI.md`, « En 3D ») :

- **Le modèle** : une image « rendu 3D » en pose A (SDXL, LoRA pixel art éteint), puis
  TRELLIS.2 sur son Space Hugging Face, avec le jeton de l'utilisateur. Une image
  pixel art donnait un modèle plat. Hunyuan3D, lui, est exclu par sa licence (hors UE).
- **Le gréage** : Mixamo, à la main ; on en garde le repos et la marche.
- **Le rendu** : Blender, caméra du jeu, image par image.
- **Les gestes d'attaque sont écrits** (`gestes.json`), joués par cinématique inverse.
  C'est le choix « Scripter » de l'utilisateur, contre les animations Mixamo : elles
  ne frappent pas comme nos coups.

Choisi sur planche :

- **Le traitement pixel art** : ligne 6 sur six. Aplats en trois tons, palette de
  16 couleurs, contour du jeu. Le premier essai, rendu lissé puis réduit, était
  « bien trop gros et pas assez pixel art ».
- **L'angle** : 10° de plongée. Le visage reste tel quel.
- **La taille** : environ 36 px, comme la sorcière.
- **Les armes** sont modélisées, « formes OK, agrandir ×1,4 ». Chacune est rendue en
  couche, le corps en masque : le style de l'arme est celui du personnage, et l'arme
  suit toujours l'équipement.
- **La garde en marche** : « plus en avant » (variante 2). Au premier essai, la lame
  passait sur le buste à certaines images, « illogique et dégueulasse ».

Erreurs vues au rendu :

- **La lame sur le corps, de profil** : vu du côté de la main armée, elle ne peut que
  passer devant. Le profil se rend donc de l'autre côté et se retourne.
- **La marche de Mixamo balance le bras armé** : la main est tenue en garde par le
  bassin, dans toutes les passes.
- **Les hanches revenaient à la pose de liaison** quand on changeait le `rotation_mode`
  des os : on garde leurs quaternions de repos.
- **Le dernier temps d'un geste était le repos**, identique au premier ; et l'impact
  du lancer tombait hors de la planche. Les gestes se rendent sur [0, 1[, et chacun
  déclare son `impact`.
- **AgX** éteignait les visages.

### La rafale et le coup de grâce

Deux gestes écrits, choisis sur planche (variante 1 chacun) :

- **La rafale** : trois estocs droits, aux images 2, 4 et 6 sur 8, le dernier fendu.
- **Le coup de grâce** : un estoc à deux mains — armé en arrière, puis fendu, le
  corps porté en avant.

**L'écart entre les coups de la rafale suit le geste.** Il valait 0,12 s fixes. À
vitesse de base, ça collait au dessin (0,135 s entre deux estocs dessinés) ; mais à
+100 % de vitesse d'attaque, le geste dure 0,27 s et le troisième coup tombait à
0,31 s, l'épée déjà rangée. `FLURRY_GAP` est désormais **une part du geste** (0,25,
l'écart du dessin), ralentie par le gel comme l'animation. Le moment d'impact des
autres attaques suivait déjà la vitesse ; la rafale était l'exception. Le quatrième
estoc de l'arbre tombe à la fin du geste, que le dessin ne montre pas.

### La sorcière, sans quota ni Mixamo

TRELLIS a vidé le quota ZeroGPU sur la sorcière : environ un modèle par jour. L'utilisateur
a refusé d'attendre vingt-quatre heures par modèle. Essayés en local, sur la carte AMD :

- **TripoSR** : couleurs ternes, modèle à recaler à la main. Abandonné.
- **Stable Fast 3D** : retenu (« j'aime bien le rendu de stable »), licence acceptée
  par l'utilisateur. Il ne voit que la face : le dos de la sorcière sortait rose pâle.
  **Face et dos sont donc repeints** d'après leurs images (`blender/project.py`), ce
  que l'utilisateur a validé.

**Mixamo a refusé la sorcière** : la cape colle ses bras au buste. Le gréage se fait en
local (`blender/rig.py`) avec le squelette et les animations du Vive lame, posés sur les
points OpenPose de l'image source. Le reste de la chaîne (gestes, rendu, couches
d'arme) est celui du Vive lame ; la planche passe en 64 px, pieds à 60.

Erreurs vues au rendu :

- **Le dos bleui** : la recoloration de la face (la peau bleue) touchait le dos.
- **Les cuisses tournées de 80°**, jambes écartées : les axes des os, recalés un par
  un, se faussaient l'un l'autre. On les relève tous avant de bouger quoi que ce soit.
- **L'ourlet de la cape suivait les jambes**, puis **des barres reliaient les pieds** :
  l'ourlet suit le buste, aucun poids ne mêle gauche et droite, et les faces entre les
  jambes sont coupées.
- **Les pieds en avant**, de profil, au repos comme en marche : « comme si on marchait
  mais avec le dos en arrière ». Cinq retours de l'utilisateur. Un recul à angle fixe
  ne suffisait pas, et deux mesures étaient faussées (la baguette, puis le bord du
  chapeau). Réglé en posant chaque pied sous la nuque comme sur le Vive lame, plus
  `FEET_BACK` (0,04 hauteur) : « ok ça me va ».

Limites connues : le dessus du bord du chapeau est tacheté (aucune image ne le voit), et
à 54 px le visage et les cheveux tirent sur le gris — une planche de palettes a montré
que ce n'est pas la palette.

## 6. Reste à faire

- Le joueur de flûte en 3D, avec la flûte en couche ; puis les ennemis.
- Le manuel : ses cases, la nuée, le **Roi des Rats** et sa transformation.
- Un geste **joué** (la flûte à la bouche) pour les sorts du manuel, à générer quand
  ils existeront.
- L'icône du manuel (la forge dessine un livre générique en attendant).
