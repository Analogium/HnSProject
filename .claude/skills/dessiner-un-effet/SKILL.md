---
name: dessiner-un-effet
description: La méthode visuelle du projet pour tout effet, geste de compétence ou icône — planche de variantes rendue hors du jeu et choisie par l'utilisateur, puis dessin pixel par pixel dans EffectForge (jamais en polygones tracés), captures réelles déposées sur le Bureau, coût mesuré, doc à jour. À invoquer dès qu'on crée ou refait le visuel d'une compétence, d'un manuel, d'un effet ou d'une icône, ou qu'on ajoute une compétence qui en a besoin.
---

# Dessiner un effet

C'est la méthode du jalon 24, qui a redessiné les manuels de feu, de glace, du
sacré et du maître d'armes. L'utilisateur l'a validée et veut qu'elle serve
**à chaque fois**. Son principe : **l'utilisateur choisit sur pièce, jamais sur
description**. Il choisit vite quand on lui montre des images. Quand on lui
demande ce qui manque, il a du mal à le dire.

Le raisonnement complet et les chiffres sont dans
`JALONS/hack-n-slash-jalon-24.md`. Les règles en vigueur sont dans les lignes
« À quoi ressemble… » et « Un effet est-il dessiné ou fabriqué ? » de
`docs/ARCHITECTURE.md`. Les lire avant de commencer : ce skill dit **dans quel
ordre** faire les choses, il ne remplace pas ces documents.

## 1. Lire l'existant

- Trouver les gestes concernés : `resources/skills/*.tres` (`shape`, `nature`),
  puis le nœud qui les dessine dans `actors/skills/` ou `actors/player/`.
- Repérer la **matière** de ces gestes et le fichier qui la pose : `fx/fire.gd`,
  `fx/frost.gd`, `fx/holy.gd`, `fx/slash.gd`. Une matière nouvelle a droit à son
  propre fichier `fx/`, qui tient **son** blanc (mesuré au-dessus de 0,9 de
  luminance) et ses fonctions de pose.
- Chercher les couleurs écrites plusieurs fois. Le blanc du feu, puis celui du
  sacré, vivaient chacun dans trois ou quatre fichiers avec des valeurs
  différentes.

## 2. La planche d'abord

Rendre **4 à 7 variantes aux partis pris francs**. Une variante timide ne se
remarque pas sur la planche. Montrer **le geste**, pas le dessin isolé : sept
pics en couronne, un croissant en cinq temps, un trait en biais. Le serpent
avait été jugé immobile, alors qu'en mouvement il sortait comme un tube.

- Écrire un script `extends SceneTree` dans le dossier de travail. Il dessine
  avec `PixelCanvas` et les grilles de `EffectForge`, puis appelle
  `Image.save_png("user://….png")`. Poser les variantes sur le sol du jeu
  (`Color(0.21, 0.19, 0.21)`), les numéroter avec des chiffres en pixels, et
  agrandir le tout ×4 à ×6 au plus proche voisin.
- `tools/planche.sh <script.gd> <sujet>` le rend en headless et dépose le
  résultat dans `C:\Users\Theo\Desktop\hns-captures-<sujet>\`.
- **Regarder la planche soi-même d'abord** avec l'outil Read. Remplacer toute
  variante manifestement ratée avant de la montrer : le prisme sortait en sapin,
  le croissant en feuille.
- Numéroter le fichier dans l'ordre du récit, donner son chemin Windows, puis
  poser la question avec `AskUserQuestion` : une option par variante, et la
  description dit ce qu'on y voit. **Ne rien implémenter avant la réponse.**
- **Une icône** suit le même principe, avec `tools/skill_icons.py` et la recette
  de `resources/icons/LISEZMOI.md`. Faire une planche de 4 sujets × 3 graines, à
  côté des icônes déjà posées du manuel. Puis inscrire sujet et graine dans
  `tools/skill_icons.json` et lancer `apply --only <id>`. ComfyUI tourne sur
  l'hôte Windows (`ip route`) : le lancer avec le bac à sable désactivé.

## 3. Dessiner dans la langue du décor

Les règles qui ne se discutent plus :

1. **Dessiné, pas tracé.** Des grilles à la main dans `EffectForge` (`1` à `5`
   pour la rampe de la teinte, `w` pour le cœur), cuites par `_sheet()` pour
   chaque teinte. Pas de `draw_colored_polygon`, pas de `Glow` pour une matière
   dessinée.
2. **Pas d'additif** : un contour sombre n'ajoute rien en lumière ajoutée. Le
   nœud ne pose `ArtPalette.ADDITIVE` que pour les natures encore tracées.
3. **Calé sur le pixel** : toujours passer par `EffectForge.snap()` ou
   `EffectForge.Piece.put()`.
4. **Ni rotation ni étirement d'une planche.** Selon le cas :
   - planche d'animation, si la taille est fixe ;
   - planches replacées une à une, si la forme se répète à toute taille ;
   - orientations dessinées à la main (`EffectForge.chips()`, huit) ;
   - fabrication à la direction demandée, avec cache (`Slash`, trente-deux
     directions) ;
   - rastérisation à l'angle exact, une fois par geste (`Holy.lance`,
     `Slash.cleave`) — quand arrondir la direction ferait mentir la portée ;
   - découpage au lieu d'étirement (`Frost.raise_spike`).
5. **Rien ne pâlit.** Une planche à demi transparente sur un sol sombre sort
   grise, ou brune pour le feu. Ce qui disparaît se coupe, rentre sous terre, se
   résorbe, ou se dissout en damier **après** le contour
   (`EffectForge.dissolve()`). Seuls les halos tramés au sol ont le droit de
   s'effacer en fondu.
6. **La régularité fait la palissade**, pas le nombre d'éléments : alterner
   grand et petit, écarter de l'axe.
7. **Une lumière n'a pas de dessous** : ce qui *est* la lumière se pousse en haut
   de sa rampe (`Holy.LIT`).

## 4. Mesurer ce qui se fabrique en jeu

Toute rastérisation qui a lieu **pendant la partie** (au lancer, ou au premier
passage par une direction) se mesure au banc headless avant d'écrire un
chiffre. Passer par `tools/planche.sh` avec un script qui chronomètre par
`Time.get_ticks_usec()`. Au-delà d'environ 1 ms par événement, chercher ce qui
balaie du vide : c'est ainsi que `PixelCanvas` a gagné son balayage par rangée,
et la rotation son saut hors de la lame.

## 5. Capturer en jeu

- Recopier `tools/capture_scenario.gd` dans le dossier de travail et n'éditer
  que ses constantes (manuel, compétences, nœuds, baguette, direction, frise).
  Lancer ensuite `tools/capture.sh <copie>.gd <sujet>`, en fenêtré.
- Recadrer et agrandir les captures avec PIL (×3 à ×5) et les regarder
  **soi-même**. Les défauts de ce jalon ne se sont vus qu'à la capture : cristaux
  gris, tombeau en caillou, trait « os », croissant qui se trame en finissant.
- Corriger et recapturer tant que ça ne tient pas. Puis copier les images
  retenues sur le Bureau, numérotées à la suite.

## 6. Livrer

- Tests : les grilles rectangulaires, ce qui tourne (un quart de tour ne perd
  aucun pixel), le cache (deux demandes, une seule fabrication), la luminance du
  cœur. Voir `tests/unit/test_effect_forge.gd` et `test_slash.gd`.
- Supprimer ce que la livraison rend mort : fonctions de tracé sans appelant,
  couleurs doublées, avec leurs tests.
- `tests/run.sh` complet. La suite unitaire seule ne charge pas les nœuds de
  compétence : elle peut passer alors que le jeu ne compile plus.
- Doc dans le même geste :
  - la ligne « À quoi ressemble… » de `docs/ARCHITECTURE.md` ;
  - `docs/RECETTES.md` si un fichier `fx/` apparaît ;
  - une section au jalon en cours, avec **le choix fait sur planche**, **les
    erreurs vues à la capture** et **les chiffres mesurés**.
- Contenu touché (`.tres`) : lancer `tools/catalog.sh`, puis
  `tools/balance.sh calculation`.
- Rendre compte : les chemins des images sur le Bureau, ce qui a été choisi, ce
  que les captures ont corrigé. Ne pas commiter.
