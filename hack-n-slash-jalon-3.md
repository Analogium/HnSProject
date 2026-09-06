# Hack'n'slash top-down — jalon 3

Suite de `hack-n-slash-jalon-1.md`, qui reste la référence sur l'architecture et
les conventions, et de `hack-n-slash-jalon-2.md`, qui a posé les affixes, la
progression, les objets et la fiche de personnage. Ce document ne redit pas ce
qui y est déjà écrit.

**Décidé le 6 septembre 2026.** Le jalon 2 s'achevait sur une contradiction :
la direction du projet est « un ARPG à **personnage persistant**, pas un
roguelite à runs qui s'effacent », et pourtant fermer la fenêtre effaçait tout.
Un personnage de niveau 10 avec son plastron cuirassé n'existait que le temps
d'une session.

---

## 1. Périmètre du jalon 3

**Dedans :**

- Un écran de sélection de personnage, première scène du jeu
- La création d'un personnage : son nom et sa silhouette
- La sauvegarde et le rechargement de ce personnage
- La suppression, avec ce qu'il faut de garde-fous

**Explicitement dehors :** l'enchaînement des zones, les classes et les
compétences, l'audio, le multijoueur, l'optimisation. Et **l'élargissement de la
réserve d'affixes**, qui attendait ce jalon mais qui n'a rien à voir avec la
persistance — il ira dans le jalon suivant, ou dans une passe de contenu à part.

**Critère de réussite :** créer un personnage, jouer, gagner deux niveaux et un
plastron, **fermer le jeu**, le relancer, retrouver son personnage dans la liste
avec son niveau et son plastron dans le sac, et reprendre.

---

## 2. Le principe structurant du jalon

**On sauvegarde le personnage, jamais la partie.**

C'est la décision qui commande tout le reste. La zone en cours, la position des
ennemis, les objets tombés au sol, les points de vie du moment : rien de tout ça
n'est écrit. Reprendre un personnage le fait renaître dans une zone neuve, en
pleine santé.

Trois raisons, dans l'ordre :

- **c'est ce que le genre fait.** Dans un ARPG on ne sauvegarde pas au milieu
  d'un combat, on quitte la partie et on retrouve son personnage ;
- **c'est ce que le code permet déjà.** Le personnage est un petit tas de nombres
  — niveau, expérience, un sac, deux emplacements. La zone, elle, est un graphe
  de nœuds vivants dont l'état complet n'a jamais été pensé pour être décrit ;
- **c'est ce qui empêche la triche par rechargement.** Une sauvegarde de zone
  transformerait chaque mort en annulation, et chaque coffre en machine à sous
  qu'on relance jusqu'au bon tirage.

La conséquence à assumer : **mourir coûte la zone en cours**, pas le personnage.
C'est exactement la règle actuelle, qui recharge la zone à la mort — le jalon ne
fait que la rendre définitive et cohérente entre deux sessions.

---

## 3. Le format de sauvegarde

### 3.1 Du JSON, pas des ressources Godot

`core/item.gd` l'annonce déjà : « le jour où il faudra sauvegarder une partie,
c'est un dictionnaire de quelques nombres à écrire — pas un fichier par épée ».
Le jalon 3 ne fait que tenir cette promesse.

**Pas de `ResourceSaver`, pas de `.tres` de sauvegarde.** Trois raisons :

- un `.tres` porte des **chemins de scripts** : renommer ou déplacer un fichier
  du projet casse toutes les sauvegardes existantes ;
- charger une ressource **exécute du code**. Une sauvegarde est un fichier que
  l'utilisateur peut échanger ; ce n'est pas un endroit où faire tourner du code
  arbitraire ;
- une ressource sauvegardée référence les `.tres` du disque. C'est le piège du
  projet — celui des stats d'ennemis, puis de celles du joueur — et il se
  reposerait ici une troisième fois.

Un fichier par personnage, `user://personnages/<id>.json`. L'identifiant est
**généré**, jamais dérivé du nom saisi : deux personnages peuvent porter le même
nom, et un nom peut contenir des caractères qu'un système de fichiers refuse.

### 3.2 Ce que contient le fichier

```json
{
  "version": 1,
  "id": "p_1788700000_4821",
  "nom": "Brenna",
  "silhouette": 2,
  "cree_le": "2026-09-06",
  "joue_le": "2026-09-06",
  "niveau": 7,
  "experience": 240,
  "attributs": {"strength": 8, "dexterity": 4, "intelligence": 6},
  "points_a_placer": 0,
  "sac": [
    {
      "base": "epee",
      "cellule": [0, 0],
      "affixes": [
        {"stat": "attack_damage", "mode": 0, "valeur": 6.0},
        {"stat": "attack_speed", "mode": 1, "valeur": 8.0}
      ]
    }
  ],
  "equipement": {
    "chest": { "base": "plastron", "affixes": [] }
  }
}
```

Rien d'autre. Pas de statistiques calculées : elles se **recalculent** à partir
de la base, des attributs et de l'équipement — c'est déjà ce que fait
`recompute_stats()`, et écrire le résultat créerait une deuxième vérité qui
finirait par contredire la première.

`attributs` est la **répartition**, pas le total : ce que le joueur a placé, et
non ce qu'il a en tout. Le total se reconstruit en y ajoutant la fiche de départ
et l'équipement. Écrire le total figerait les valeurs de départ du jour où la
sauvegarde a été faite.

`points_a_placer` doit être sauvegardé aussi : monter de niveau puis quitter sans
répartir ne doit pas coûter les points.

### 3.3 Une base d'objet a besoin d'un identifiant

`ItemAffix` a un champ `id`. **`ItemBase` n'en a pas** : rien ne désigne une épée
autrement que par son chemin de fichier. Sauvegarder `res://resources/items/
epee.tres` marcherait, jusqu'au jour où on range les fichiers autrement.

Il faut donc ajouter `@export var id: String` à `ItemBase`, et un test qui
vérifie que **tous les identifiants sont présents et uniques** — un doublon ferait
silencieusement charger la mauvaise base.

Le même besoin existe pour les affixes d'objets, et il est déjà couvert : un
`StatMod` sauvegardé porte son champ et sa valeur, pas l'affixe qui l'a produit.
C'est suffisant, et ça survit à la suppression d'un affixe de la réserve.

### 3.4 Écrire sans corrompre

Une sauvegarde écrite pendant une coupure laisse un fichier tronqué, donc un
personnage perdu. **Écriture atomique** : écrire dans `<id>.json.tmp`, fermer,
puis renommer par-dessus. Le renommage est atomique là où l'écriture ne l'est
pas.

---

## 4. Quand on sauvegarde

Pas à chaque changement : ramasser un objet écrirait sur le disque à chaque
grappe d'ennemis tués. Pas non plus seulement à la fermeture : une coupure
perdrait la session entière.

Trois moments, et seulement trois :

- **à la montée de niveau** — c'est le progrès qu'on serait le plus fâché de
  perdre, et ça arrive rarement ;
- **au retour au menu** (Échap → Quitter) et à la fermeture de la fenêtre, via
  `NOTIFICATION_WM_CLOSE_REQUEST` avec `auto_accept_quit` désactivé ;
- **toutes les deux minutes**, en filet.

Un indicateur discret quand l'écriture a lieu. Sans lui, on ne sait pas si le jeu
a sauvegardé, et on ferme la fenêtre en croisant les doigts.

---

## 5. L'écran de sélection

`ui/selection_personnage.tscn`, et il devient la scène principale du projet —
`run/main_scene` pointe aujourd'hui sur `world/test_arena.tscn`, qui est une
scène de réglage.

Une liste, une entrée par personnage : sa silhouette animée, son nom, son niveau,
et la date de dernière partie. **La silhouette est celle du personnage**, pas une
vignette générique : la forge dessine déjà les quatre variantes, et voir son
personnage dans la liste vaut mieux que lire son nom.

Trois actions : **Jouer**, **Nouveau**, **Supprimer**.

Supprimer demande confirmation en retapant le nom. C'est agaçant exprès : c'est
la seule action du jeu qui détruit des heures de jeu, et elle est irréversible.

---

## 6. La création de personnage

Deux choix, et c'est tout : un **nom** et une **silhouette**.

Pas de classe — elles sont hors périmètre. Pas de répartition d'attributs non
plus **à la création** : les points se gagnent en montant de niveau (voir la
section 10 du jalon 2), et en distribuer avant d'avoir joué demanderait de
choisir sans rien savoir du personnage.

La silhouette est un entier, l'index de variante que `ActorSprite` accepte déjà
(`SpriteForge.VARIANTS` en compte quatre). L'écran en montre les quatre côte à
côte, animées, et on en choisit une. C'est la génération procédurale utilisée
comme **règle de jeu** et non comme pipeline d'assets, ce que le postulat du
projet réclame depuis le début : ton personnage a une silhouette parce que tu l'as
choisie, et c'est celle-là qu'on retrouve dans la liste.

Le nom : non vide, longueur bornée, et on refuse les caractères de contrôle.
Aucune contrainte d'unicité — l'identifiant du fichier ne s'en déduit pas.

---

## 7. Ordre de construction

Chaque étape doit être testée avant la suivante, avec `tests/run.sh`.

- [x] **1. Identifiants de bases d'objets.** `ItemBase.id`, renseigné sur les
      trois bases, plus un test d'unicité et de présence. Une étape courte, mais
      tout le reste en dépend : sans elle un objet sauvegardé ne sait pas ce
      qu'il est.
- [x] **2. Sérialisation, sans interface.** `core/sauvegarde.gd` : un personnage
      vers un dictionnaire et retour. C'est du `core/` sans nœud, donc des tests
      **unitaires** — et c'est là que doit vivre la garantie qui compte :
      sérialiser puis désérialiser un personnage rend un personnage identique,
      sac, affixes et répartition d'attributs compris. Y compris pour les cas
      tordus : sac plein, objet à six affixes, aucun équipement, points gagnés
      mais non placés.
- [x] **3. Lecture et écriture sur disque.** Dossier `user://personnages/`,
      écriture atomique, liste des personnages, suppression. Tests
      d'intégration : écrire, relire, comparer ; et un fichier volontairement
      tronqué ou d'une version inconnue doit être **refusé proprement**, pas
      faire planter l'écran de sélection.
- [x] **4. L'écran de sélection et la création.** L'interface, avec les
      silhouettes animées. C'est ici qu'on bascule `run/main_scene`.
- [x] **5. Le branchement dans la zone.** La zone reçoit un personnage chargé au
      lieu de repartir des valeurs par défaut, et les trois points de sauvegarde
      sont posés. Test e2e : créer, jouer, sauvegarder, recharger, vérifier.

### Ce que les étapes 4 et 5 ont changé au plan

- **Le joueur était exclu du tirage de silhouettes.** `SpriteForge.config()`
  portait `amount = 0.0 if archetype == "player"`, avec pour raison « son
  apparence doit être stable » — décision prise quand il n'y avait qu'un
  joueur possible. L'écran de création en montrait donc quatre identiques. La
  variation aléatoire est remplacée par `PLAYER_CLOTHS`, quatre tenues franches
  (bleu, cramoisi, vert, violet) : choisies et non tirées, donc toujours
  stables, mais enfin distinguables. Le fil doré et l'acier ne bougent pas — ce
  sont eux qui font qu'on se reconnaît dans une mêlée.
- **`ui/ui_palette.gd`.** Le cadre du sac était emprunté par la fiche
  (`const BACK := InventoryPanel.BACK`), avec un commentaire qui posait le
  seuil : « le jour où un troisième panneau arrive, cette palette méritera son
  propre fichier ». L'écran de sélection est le troisième.
- **Un seul signal de départ**, `Game.sauvegarde_demandee`, plutôt que trois
  appels. Fermeture de la fenêtre, retour au menu et sortie du jeu passent tous
  par lui ; un seul de ces chemins qui oublie d'écrire suffit à perdre une
  session.

### Ce que les étapes 1 à 3 ont changé au plan

Trois écarts, tous assumés :

- **`core/item_catalog.gd`** n'était pas prévu. La table de butin tenait sa
  propre liste des trois bases ; la sauvegarde en aurait eu besoin d'une seconde
  pour retrouver une base par son identifiant. Deux listes qui divergent, c'est
  un objet qui tombe et ne se recharge pas. Le catalogue est le seul endroit où
  les bases sont listées, et la table de butin y puise désormais.
- **Le modèle est séparé du disque.** `core/personnage.gd` porte le personnage
  et sa conversion en dictionnaire, `core/sauvegarde.gd` ne fait que lire et
  écrire des fichiers. Le premier se teste sans rien toucher, le second est le
  seul à connaître `user://`.
- **`NOM_MAX` est passé de 16 à 20 caractères.** La première borne, posée au
  jugé, refusait « Jean-Luc de l'Est ». À revérifier à l'étape 4 : c'est l'écran
  de sélection qui décide de ce qui tient sur sa ligne.

Et une décision prise en chemin : **`Sauvegarde.ecrire()` date le personnage du
jour**. Laisser l'appelant le faire aurait marché deux fois sur trois — il y a
trois points de sauvegarde, et le troisième aurait fini par l'oublier.

---

## 8. Ce qui peut mal tourner

- **Sauvegarder une ressource partagée par référence.** Le piège du projet, deux
  fois déjà — les stats d'ennemis à l'affixage, celles du joueur à l'équipement.
  Ici il prendrait la forme d'un `ItemBase` sérialisé en entier au lieu de son
  seul identifiant : la sauvegarde figerait alors les valeurs d'équilibrage du
  jour, et les rejouerait des mois plus tard.
- **Une sauvegarde d'une version antérieure.** Le champ `version` existe pour
  ça. Tant qu'il n'y a qu'une version, la règle est simple : un numéro inconnu
  est refusé avec un message, et le personnage reste dans la liste, grisé. Ne
  jamais tenter de deviner.
- **Un objet dont la base a disparu du projet.** Il doit être ignoré au
  chargement, pas faire échouer tout le personnage. Perdre une épée est
  désagréable ; perdre le personnage est inacceptable.
- **Le nom du joueur utilisé comme nom de fichier.** Barres obliques, points,
  noms réservés, doublons. L'identifiant est généré, point.
- **Une écriture pendant le combat.** Sauvegarder à la montée de niveau tombe au
  milieu d'un paquet d'ennemis. L'écriture doit rester assez petite pour ne pas
  se voir — quelques kilo-octets de JSON — et surtout ne **jamais** être
  déclenchée depuis un rappel de physique, ce qui est déjà la règle du projet
  pour tout ce qui touche à l'arbre.
- **Croire qu'un test de sérialisation suffit.** Un aller-retour en mémoire ne
  prouve pas qu'un fichier écrit hier se relit aujourd'hui. Il faut au moins un
  fichier de référence versionné dans `tests/`, relu à chaque campagne : c'est
  lui qui attrapera le jour où un champ change de nom.
