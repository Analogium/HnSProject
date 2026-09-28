# Hack'n'slash top-down — jalon 30

Suite des jalons 1 à 29. Ce document ne redit pas ce qui y est déjà écrit, et
`docs/ARCHITECTURE.md` reste le seul endroit qui décrit l'état courant.

**Ouvert le 28 septembre 2026.** Le jalon du **cheminement des scènes** : jusqu'ici,
choisir un personnage menait droit dans une zone. Désormais, on arrive en ville.

---

## 1. Ce que l'utilisateur a demandé

- Une **ville**, là où l'on arrive en se connectant, avec :
  - un **PNJ à qui vendre** ses objets — sans rien en échange pour l'instant : c'est
    un moyen de s'en débarrasser autrement qu'en les jetant ;
  - un **coffre** de **cinq onglets** où ranger ses objets, « comme PoE » ;
  - un **portail** qui mène à la zone où l'on entrait jusqu'ici, et le jeu habituel
    ensuite.
- Hors de la ville, un bouton **« portail »** qui ouvre un portail pour rentrer en ville.

## 2. Le système

- **La ville est un mode de la zone, pas une scène.** Une seconde scène aurait dû
  recopier le joueur, les sept panneaux, la sauvegarde et le bandeau. `Zone.enter_town()`
  pose une salle nue (`MapGenerator.town()`, 24 × 16 cases, sans tirage) et montre le
  nœud `Entities/Town` ; `generate_zone()` le cache. Un personnage arrive en ville ; une
  scène de réglage, sans personnage, va toujours droit en zone.
- **Ce qui se clique** : `Interactable` (`actors/town/interactable.gd`), sur le modèle du
  butin au sol — `clicked()` est le seul chemin, `takes_the_click()` retient le clic
  gauche du sondage des compétences. Dans `actors/` et non `world/` : le joueur le lit, et
  `actors/` ne connaît pas `world/`.
- **Les portails.** Celui qu'on ouvre en zone — action `town_portal`, **T**, rebindable —
  se pose devant le joueur et mène en ville. Au retour sur la première livraison :
  **il faut revenir dans la même zone**. La zone quittée se **fige** donc au lieu d'être
  détruite : ses ennemis, leurs coups au sol et son butin sont désactivés et cachés, ce
  qui les retire aussi de la physique — la ville partage ses coordonnées. En ville, un
  portail bleu y ramène, au même endroit, et se referme ; le portail doré d'en haut,
  « Nouvelle zone », en donne une neuve (`Zone.new_zone()`, le chemin de `F5`) et
  abandonne l'autre.
- **Une seconde grille dans le sac.** Le marchand et le coffre ouvrent une grille à gauche
  de l'écran, et **les gestes du sac y valent tous** : prendre, glisser, échanger,
  empiler, jeter. `InventoryPanel` ne connaît plus une grille mais deux (`_grid_at()`,
  `_from_grid`) ; Ctrl + clic passe un objet de l'une à l'autre, comme dans PoE.
- **L'étal du marchand** a la taille du sac : on y pose ce qu'on veut vendre, « Vendre »
  le vide. Refermé avant, il rend tout au sac.
- **Le coffre**, `core/stash.gd` : cinq onglets de 12 × 12, **partagés par tous les
  personnages**, dans `user://stash.json` avec son propre numéro de version. Lu par l'écran
  de sélection, écrit avec le personnage. `Character.grid_to_list()` et
  `grid_from_list()` écrivent le sac et les onglets par la même règle ; `SaveStore` écrit
  les deux fichiers par le même `.tmp` renommé.

## 3. Ce qui a été tranché sans l'utilisateur

À revoir sur pièce ; aucun n'engage la suite.

- **La zone figée ne vit plus** : ni ses ennemis ni ce qui brûle sur eux n'avancent tant
  qu'on est en ville. Les tirs en vol, eux, disparaissent. Elle ne survit pas à la
  fermeture du jeu.
- **Le portail se referme quand on le reprend**, comme dans PoE : pour repartir, en
  rouvrir un.
- **Le sol de la ville se vide quand on en part** : ce qu'on y jette ne reste pas.
- **Le coffre est partagé entre personnages**, comme dans PoE — c'est ce qui permet de
  passer un objet de l'un à l'autre.
- **Un clic suffit**, sans portée : on utilise un objet de la ville ou un portail où qu'on
  soit à l'écran. Le jeu se déplace au clavier, et il n'y a pas de marche jusqu'à la
  cible à la PoE.
- **Le bouton « portail » est une touche**, rebindable, pas un bouton à l'écran.
- **Le coffre illisible ne s'ouvre pas** : l'ouvrir vide et l'écrire à la fermeture
  écraserait tout ce que les personnages y ont rangé.
- **Depuis le coffre, ni pièce ni équipement** : on sort l'objet d'abord.
- **On peut encore lancer ses compétences en ville.** PoE les coupe ; rien ne l'exigeait.
- **Mourir en ville y ramène.** Un geste qui brûle ses PV tue même sans ennemi.

## 4. Ce qui reste à dessiner

Le marchand, le coffre et les portails ont un **dessin provisoire** : le marchand
emprunte l'archétype `player` en grilles, le coffre est un rectangle, le portail un halo de
`Glow`. Chacun passera par sa planche — `/dessiner-un-effet` pour le portail et le coffre,
`tools/character_forge.py` pour le marchand — avant d'avoir sa version.

## 5. Ce que la capture a corrigé

Captures sur le Bureau : `hns-captures-jalon30-ville` (1 à 6).

- **Le bandeau d'aide (H) passait par-dessus le coffre et l'étal**, qui s'ouvrent en haut
  à gauche : le sac est désormais après lui dans `UI` (`test_the_bag_is_drawn_over_the_help_overlay`).
- Les douze rangées du coffre tiennent au-dessus des jauges ; les dix-huit actions tiennent
  dans l'onglet des touches.
- **Le manuel de départ tombait deux fois** — au sol de la zone figée, et de nouveau en
  ville : on pouvait en ramasser deux. Il n'est plus reposé en ville quand une zone attend
  (`test_the_starting_manual_is_never_doubled`). Captures 7 et 8.
- Reste visible : l'encadré du glossaire d'un objet du coffre se pose sur la poupée du sac.
  Il ne cherche à éviter qu'un panneau.
