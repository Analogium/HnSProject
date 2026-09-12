# Hack'n'slash top-down — jalon 10

Suite de `hack-n-slash-jalon-1.md`, qui reste la référence sur l'architecture et
les conventions, et des jalons 2 à 9. Ce document ne redit pas ce qui y est déjà
écrit, et `docs/ARCHITECTURE.md` reste le seul endroit qui décrit l'état courant.

**Décidé le 12 septembre 2026.** Le jeu a **un** manuel, celui de la foudre, et
ce qu'on y apprend est un nombre : cinq points dans une case donnent cinq lignes
d'une table de dégâts. Une compétence montée est la même compétence en plus fort.

Ce jalon ajoute **deux manuels**, **des passifs** — des cases qu'on monte et qui
agissent sans qu'on les lance — et **un arbre de talents par compétence** : trois
nœuds qui changent *la façon dont elle se joue*, pas seulement ce qu'elle
inflige.

---

## 1. Périmètre du jalon 10

**Dedans :**

- **Deux manuels neufs.** « Maître des flammes » : trois sorts de feu. « Maître
  d'armes » : deux attaques, dont une qui lance des lames. Chacun avec son passif
  et ses arbres.
- **Le passif**, une case de manuel comme les autres — un niveau requis, un
  maximum de points, un point par clic — mais dont l'effet est **permanent** :
  ses lignes entrent dans la fiche du personnage ou dans les compétences qui
  portent un mot-clé, exactement comme celles d'un objet porté.
- **L'arbre de talents** : par compétence, trois nœuds posés sur une petite
  grille, reliés à la compétence et parfois entre eux. Un nœud ajoute des dégâts,
  des projectiles, de la vitesse — ou **convertit** une part des dégâts dans une
  autre nature, ce qui change la résistance à laquelle le coup s'oppose et,
  quand le nœud le dit, le mot-clé que la compétence porte.
- **Le mot-clé Feu**, avec l'affixe qui le vise : sans lui, un manuel de feu
  entier n'aurait aucune prise pour l'équipement.
- **La reprise d'un point de nœud**, et d'un nœud seulement (§4).
- **La page des manuels en deux vues** : la grille des cases, et l'arbre d'une
  compétence ouverte.

**Dehors :**

- **Reprendre un point de case ou de passif.** La règle du jalon 3 ne bouge pas :
  ce qui décide *ce qu'on sait* est définitif. Seul l'arbre, qui décide *comment
  on le joue*, se défait — voir §4.
- **Un troisième chemin de lancer.** Les nœuds modifient le tir et le coup d'arc
  existants ; aucun n'invente une zone, une aura ou un sort persistant. Un nœud
  ne peut donc pas donner `projectile`, `sort` ni `attaque` : ces trois-là
  décident du chemin que `Player.lancer()` prend, et un nœud qui les donnerait
  ferait partir un tir depuis une compétence dont la fiche annonce un coup
  d'épée.
- **Un arbre partagé entre deux manuels.** L'arbre appartient à la **case**, pas
  à la compétence : deux manuels qui enseigneraient un jour le même sort
  l'orienteraient chacun à sa façon. Ce jalon n'en livre pas d'exemple.
- **Une nouvelle version de sauvegarde.** Les points d'un nœud et d'un passif
  entrent dans le dictionnaire `points` du manuel, qui existe depuis le jalon 6 :
  aucun champ neuf dans le fichier, donc rien à monter (§5).
- **L'équilibrage.** Les nombres de ce document sont des premiers réglages, à
  sentir en jouant. Le seul endroit où ils sont écrits est le `.tres`.

---

## 2. Trois choses dans une case

Une case de manuel porte aujourd'hui une compétence et une position. Elle portera
**l'une ou l'autre** de deux choses, plus ce qui s'accroche à la première :

| Ce que la case porte | Ce que le joueur y fait | Où l'effet arrive |
|---|---|---|
| une **compétence** | l'assigne à la barre, la lance | `Competence.resoudre()` |
| ses **talents** | ouvre son arbre, y place des points | la même résolution, par la même fonction |
| un **passif** | y place des points | `Player.recompute_stats()`, avec les objets |

**Une case, une chose.** Une case qui porterait les deux aurait deux compteurs de
points pour un seul identifiant : le jour où l'un des deux se renomme, l'autre
récupère ses points sans que rien ne le dise. Un test refuse les deux et refuse
aucune des deux.

**Les points sortent du même sac.** Un manuel gagne un point par niveau, vingt au
plafond, et la case, le passif et le nœud s'y servent tous. C'est ce qui fait du
manuel un choix : le manuel de la foudre a quarante-huit destinations pour vingt
points — `docs/CATALOGUE.md` donne le compte de chaque livre. Le commentaire de `Manuel.NIVEAU_MAX` — « vingt niveaux, donc vingt
points : de quoi remplir les quatre cases » — devient faux et se réécrit : **un
manuel ne se remplit plus**, et ce qu'on y a mis est ce qui distingue deux
exemplaires du même livre.

**Un identifiant, un espace.** Cases, passifs et nœuds partagent le dictionnaire
`points` du manuel, donc leurs identifiants partagent un espace de noms, et ils
partent tous sur le disque (invariant 1). Un nœud se nomme donc
`<compétence>_<nœud>` — `eclair_vif_surcharge` — et un test refuse deux
identifiants identiques dans un même livre.

---

## 3. Ce qu'un nœud peut faire

**Une ligne de nœud est un modificateur, pas un cas particulier.** C'est la même
forme que ce qu'un affixe donne — une statistique, un mode, une valeur — et elle
est appliquée par le même `StatMod.appliquer()`. Ce qui change, c'est qui la
reçoit : un affixe vise **toutes** les compétences portant un mot-clé, un nœud
vise **la sienne** et n'a donc pas de portée à écrire.

Ce qu'une ligne peut viser est donc ce qu'un affixe porté peut déjà viser, et pas
un champ de plus : les dégâts en pourcentage, le nombre de projectiles, leur
vitesse, et des dégâts ajoutés par nature — en fourchette, comme sur un objet.

**La conversion est la seule opération neuve.** « Convertit 60 % des dégâts en
feu » déplace cette part de la nature de la compétence vers une autre, **après**
les fourchettes ajoutées et avant les multiplicateurs :

- après les ajouts, pour que la foudre qu'un anneau ajoute à un sort de foudre
  soit convertie avec le reste — sans quoi le même objet donnerait deux résultats
  selon l'ordre dans lequel les lignes arrivent ;
- avant ou après les multiplicateurs, **c'est numériquement pareil** : l'attribut
  et les « +% dégâts » multiplient toutes les parts du même facteur. Elle est
  écrite avant parce que c'est l'ordre dans lequel la fiche les affiche.

Deux nœuds de conversion sur la même compétence prennent chacun leur part de ce
qui **reste** : deux fois 50 % convertissent 75 %, et la fiche annonce 75 %, pas
100 %.

**Le mot-clé, seulement si le nœud le dit.** Convertir ne change pas d'office ce
que la compétence est : une fulguration dont les dégâts passent au feu reste un
sort de foudre pour l'équipement, et c'est ce qu'on veut par défaut — les objets
qu'on porte pour elle continuent de la servir. Le nœud qui veut l'autre effet
l'écrit (`mots_cles_ajoutes`), et la compétence porte alors **les deux** natures :
c'est le nœud le plus cher de son arbre.

---

## 4. Reprendre un point de nœud

**Décidé le 12 septembre, sur demande** : un point de nœud se reprend, un point
de case ou de passif non.

La règle du jalon 3 — « une répartition qu'on peut défaire n'est plus un choix,
c'est un réglage » — vaut pour ce qui décide de ce qu'un personnage **sait**. Un
arbre décide de ce qu'une compétence **fait** : essayer la conversion et revenir
est la façon dont on l'apprend, et un joueur qui ne peut pas revenir ne l'essaie
pas. C'est exactement l'inverse de l'effet voulu.

Deux garde-fous, et ils sont dans `Manuel` comme les conditions d'investissement :

- **un nœud dont un enfant porte des points ne se reprend pas.** Sans ce refus,
  un enfant resterait accroché à un nœud vide — et la page montrerait un lien
  vers un nœud éteint ;
- **le point revient au sac du manuel**, jamais au personnage : il se replace
  ailleurs dans le même livre, et pas dans un autre.

Ce qui n'est **pas** un garde-fou, et c'est délibéré : rien ne coûte, rien
n'attend. Un prix — de l'or, un objet — donnerait une seconde monnaie à un geste
qui n'en demande pas.

---

## 5. Ce que la sauvegarde écrit

Rien de neuf. Un manuel écrit déjà `{"exp": …, "points": {id: n}}`, et les
identifiants de passifs et de nœuds entrent dans ce dictionnaire comme ceux des
cases. Donc : **pas de version 6**, et un personnage de version 5 se relit tel
quel — ses manuels ont simplement des cases de plus à remplir.

Deux conséquences à ne pas rater :

- **le filtre de relecture doit s'élargir.** `Personnage._manuel_depuis_dict()`
  garde un point si `item.enseigne(id)`, c'est-à-dire si l'archétype a une case de
  ce nom. Laissé tel quel, il jetterait en silence tous les points de nœuds au
  premier rechargement. La question devient « ce livre connaît-il cet
  identifiant », cases, passifs et nœuds confondus ;
- **un identifiant retiré du projet perd ses points**, comme avant, et c'est
  toujours ce qu'on veut : des points placés dans un nœud qui n'existe plus ne
  sont dépensables nulle part.

---

## 6. Le contenu

**À relire** : premiers réglages. Les tables de dégâts suivent celles du manuel
de la foudre, un cran plus fort pour ce qui coûte plus cher. Elles sont toutes
dans `docs/CATALOGUE.md`, section « Manuels », avec les coûts et les cadences —
c'est là qu'on les compare, pas ici.

### Le manuel de la foudre gagne un passif

| Case | Ce que c'est | Max | Par point |
|---|---|---|---|
| **Conducteur** | passif, niveau 2 | 4 | +6 % dégâts (Foudre), +10 mana |

Et ses quatre cases se réalignent sur une seule rangée, dans l'ordre où elles
s'ouvrent : la page ne montre plus un zigzag mais une progression, le passif
dessous.

### Maître des flammes

| Case | Ce que c'est | Niveau | Ce qui la distingue |
|---|---|---|---|
| **Trait de feu** | sort, 1 projectile | 1 | le trait de base, un peu plus lent que l'éclair et un peu plus fort |
| **Gerbe de flammes** | sort, 5 projectiles sur 60° | 4 | un cône : beaucoup de traits faibles, de près |
| **Comète** | sort, 1 projectile lent | 9 | le coup lourd du livre, deux fois le prix d'une fulguration |
| **Cœur de braise** | passif, niveau 2 | 4 points | +7 % dégâts (Feu), +3 rés. feu par point |

### Maître d'armes

| Case | Ce que c'est | Niveau | Ce qui la distingue |
|---|---|---|---|
| **Frappe lourde** | attaque, arc | 1 | le seul coup d'arme qu'on apprenne : la cadence est celle de l'arme |
| **Lames tournoyantes** | attaque, 2 projectiles | 3 | des lames lancées : `attaque` **et** `projectile`, donc les deux familles d'affixes la servent |
| **Garde de fer** | passif, niveau 2 | 4 points | +12 armure, +14 PV par point |

**Ni l'une ni l'autre ne monte avec un attribut**, et pour la raison qui vaut
déjà pour les deux attaques de départ : la force ajoute ses dégâts physiques aux
attaques, les payer une seconde fois ici les compterait deux fois.

### Les arbres

Trois nœuds par compétence, la même forme partout : deux branches parties de la
compétence, et un enfant sur la première. La troisième colonne de la grille reste
libre — c'est là que passera un quatrième nœud le jour où l'on en voudra.

| Compétence | Nœuds |
|---|---|
| Éclair vif | **Surcharge** +12 % dégâts ×3 · **Fourche** +1 projectile (enfant) · **Trait de glace** convertit 50 % en froid, +20 % dégâts |
| Salve d'éclairs | **Volée** +1 projectile ×2 · **Empennage** +20 % vitesse ×2 (enfant) · **Percée** +14 % dégâts ×3 |
| Fulguration | **Amplitude** +15 % dégâts ×3 · **Embrasement** convertit 60 % en feu **et donne le mot-clé Feu** (enfant) · **Éclats** +2 projectiles, −25 % dégâts |
| Nova de foudre | **Couronne** +2 projectiles ×2 · **Déflagration** +12 % dégâts ×3 (enfant) · **Célérité** +35 % vitesse ×2 |
| Trait de feu | **Attisement** +13 % dégâts ×3 · **Double langue** +1 projectile (enfant) · **Braises** ajoute 4 à 9 dégâts de feu ×2 |
| Gerbe de flammes | **Souffle** +12 % dégâts ×3 · **Nuée** +2 projectiles ×2 (enfant) · **Cendres** convertit 50 % en nécrotique, +15 % dégâts |
| Comète | **Masse** +16 % dégâts ×3 · **Fragmentation** +3 projectiles, −35 % dégâts (enfant) · **Chute rapide** +25 % vitesse ×2 |
| Frappe lourde | **Élan** +14 % dégâts ×3 · **Lame ardente** convertit 40 % en feu **et donne le mot-clé Feu** (enfant) · **Saignée** ajoute 3 à 8 dégâts physiques ×2 |
| Lames tournoyantes | **Gerbe d'acier** +1 projectile ×2 · **Affûtage** +12 % dégâts ×3 (enfant) · **Retour de lame** +30 % vitesse ×2 |

Deux nœuds échangent des dégâts contre des projectiles (**Éclats**,
**Fragmentation**) : c'est le seul endroit du jeu où un point placé peut faire
baisser un nombre, et c'est ce qui rend le choix intéressant plutôt
qu'additionnel.

### Le mot-clé Feu et son affixe

Un mot-clé n'existe que parce qu'un modificateur mord dessus. **Ardent** — « +% dégâts
(Feu) » sur les bases d'incantateur et les bijoux — est le pendant exact
d'`orageux`, échelle comprise. Sans lui, « Feu » serait une promesse que rien ne
tient.

### Les deux livres dans le sac

Chacun sa lignée d'un seul palier, donc commun, donc sans affixe — les manuels
échappent aux règles de l'équipement et la question ne se pose qu'à un endroit,
`EquipmentSlots.famille_equipable()`. **Maître d'armes** tombe dès la zone 1,
**Maître des flammes** à partir de la zone 5.

Et chacun **son dessin** : `kind` distinct, un cas de plus dans la forge. Trois
piles de livres identiques dans un sac seraient trois objets qu'on ne peut pas
distinguer sans les survoler — le palier, qui sert à cela pour l'équipement, dit
ici la rareté.

---

## 7. La page en deux vues

La fenêtre ne change pas de taille : 210 × 196, à sa place. Ce qui change, c'est
que la page a maintenant **deux états**.

**La grille**, comme aujourd'hui : les cases à leur position, le compte de points
en bas à droite, le liseré qui dit l'état. Les passifs s'y distinguent **par la
forme** — un cadre à pans coupés — et non par la couleur, qui est déjà prise par
l'état de la case. Une compétence qui a un arbre porte un chevron dans son coin.

**L'arbre**, quand une compétence est ouverte : la compétence en racine à gauche,
ses nœuds sur une grille de trois colonnes et deux rangées, les liens tracés de
parent à enfant. C'est là — et seulement là — que se placent les points de la
compétence : la racine est sa case.

| Geste | Sur la grille | Dans l'arbre |
|---|---|---|
| clic gauche | ouvre l'arbre d'une compétence · place un point dans un passif | place un point dans la racine ou un nœud |
| clic droit | range le manuel (sur un dos) | reprend un point d'un nœud · revient à la grille ailleurs |
| Échap | ferme la fenêtre | revient à la grille |
| survol | la fiche de la case | la fiche du nœud ou de la compétence |

**Pourquoi le clic ouvre au lieu d'investir.** Trois autres formes ont été
écartées : une bande sous la grille qui suit le survol (elle change dès qu'on
traverse une autre case pour aller cliquer un nœud), une fenêtre agrandie montrant
tout (sa fiche de survol sortirait de l'écran, et il faudrait déplacer le
panneau), et un geste neuf pour ouvrir (une chose de plus à savoir). Ouvrir sur
le clic déplace l'investissement d'un cran, mais **il n'y a rien à apprendre** :
la case qu'on clique montre ce qu'elle contient, et le point se place là où l'on
voit ce qu'il achète.

**La fiche de survol** garde sa largeur de 170 px et son cadre : celle d'un nœud
dit ce qu'il donne — une ligne par effet, la conversion comprise — et ce qu'il
demande quand il est fermé. Celle d'un passif dit « toujours actif » là où une
compétence écrit ses mots-clés.

---

## 8. Les tests

Les recettes de `docs/RECETTES.md` gagnent deux gestes (ajouter un passif,
ajouter un nœud), et chacun son test qui refuse l'oubli. Ce que la campagne doit
attraper, et qu'aucune partie ne montrerait avant plusieurs heures :

**Le contenu, dans `tests/unit/test_talents.gd`** (neuf) et
`tests/unit/test_manuels.gd` :

- une case porte **une** chose : une compétence ou un passif, jamais les deux,
  jamais aucune ;
- **les identifiants d'un livre sont uniques**, cases, passifs et nœuds
  confondus — un nœud homonyme d'une case partagerait son compteur de points ;
- un nœud vise un **parent qui existe dans le même arbre**, et aucun cycle : un
  parent qui se désigne lui-même ne s'ouvrirait jamais, et rien à l'écran ne
  dirait pourquoi ;
- une ligne de nœud vise un **nombre de lancer réel**, une ligne de passif un
  champ de fiche réel ou un nombre de lancer avec son mot-clé — la faute de
  frappe qui ne se voit pas, comme pour les affixes ;
- un nœud ne donne **aucun mot-clé de cadence ni `projectile`** (§1) ;
- une conversion vise une nature qui existe et **une part entre 0 et 1** ;
- chaque nœud est **atteignable** : ce qu'il demande en points de compétence ne
  dépasse pas ce que la case accepte ;
- chaque passif a au moins une ligne, et chaque arbre au moins un nœud sans
  parent — un arbre dont tous les nœuds ont un parent est un arbre fermé.

**Les règles, dans `test_manuels.gd` et `test_competences.gd` :**

- investir dans un nœud demande les points de compétence **et** le parent, et
  c'est `Manuel` qui refuse — jamais l'interface ;
- reprendre rend le point au livre, refuse quand un enfant porte des points, et
  refuse tout court sur une case ou un passif ;
- la résolution avec talents : chaque sorte de ligne, la conversion et son
  total, deux conversions qui se composent, le mot-clé ajouté qui fait mordre un
  affixe qui ne mordait pas — et **sans talent, exactement les nombres d'avant**,
  qui est le test qui garantit que ce jalon ne change pas le jeu existant ;
- un passif posé au râtelier entre dans la fiche du personnage, et **en sort
  quand le livre quitte le râtelier** : c'est l'oubli qui laisserait un bonus
  derrière lui.

**L'interface, dans `test_panneau_manuels.gd` :** l'arbre s'ouvre et se ferme,
les nœuds tiennent dans la fenêtre — mesurés avec **la même fonction que le
dessin** —, la fiche d'un nœud reste dans le cadrage, et le clic retrouve ce qui
est dessiné, racine comprise.

**La sauvegarde, dans `test_sauvegarde.gd` :** des points de nœud et de passif
font l'aller-retour ; un identifiant inconnu du livre est jeté ; et un fichier de
version 5 se relit sans perdre ses points de cases.

**Les largeurs et l'anglais** : les noms de passifs et de nœuds entrent dans le
relevé de `test_traductions.gd` — c'est le test qui refusera un nœud ajouté sans
son anglais — et les lignes de leurs fiches passent par `test_largeurs.gd`.

---

## 9. Ordre de construction

Chaque étape se valide par `tests/run.sh` avant la suivante. La première ne
change rien de ce qui se joue.

- [x] **1. Les trois formes.** `LigneDeTalent`, `NoeudDeTalent`, `Passif`,
      `TalentInvesti` ; `CaseDeManuel` qui porte l'une ou l'autre ;
      `ManuelArchetype` qui retrouve un passif, un nœud et la case qui le
      contient. Aucun `.tres` ne change encore. Tests : les formes, leurs lignes
      lisibles, et le catalogue qui passe toujours.
- [x] **2. Les règles.** `Manuel.peut_investir` pour les trois sortes,
      `peut_reprendre` et `reprendre` ; la conversion et les mots-clés résolus
      dans `StatsDeCompetence` ; `Competence.resoudre()` qui prend les talents ;
      `Player` qui les rassemble, qui applique les passifs et qui porte le seul
      chemin d'investissement. Tests : ceux du §8, sans contenu neuf — sur des
      archétypes fabriqués dans le test.
- [x] **3. Le contenu.** Le mot-clé Feu et l'affixe `ardent` ; les cinq
      compétences ; les trois passifs ; les vingt-sept nœuds ; les deux
      archétypes et leurs deux bases ; les deux dessins de la forge. Tests :
      contenu du §8, et le catalogue régénéré.
- [x] **4. La page.** Les deux vues, les passifs à pans coupés, l'arbre et ses
      liens, les fiches de nœud et de passif, les gestes du §7. Captures en
      fenêtré : la grille du manuel de la foudre, un arbre à moitié rempli, la
      fiche d'un nœud de conversion, un passif survolé.
- [x] **5. L'anglais et les largeurs.** Les noms des deux manuels, des cinq
      compétences, des trois passifs et des vingt-sept nœuds dans `en.po`, plus
      les textes neufs de la page ; les tests de largeur dans les deux langues ;
      `docs/CATALOGUE.md` régénéré et resté français.

### Ce que l'étape 2 a changé au plan

**La page avait besoin d'une troisième réponse.** `peut_investir()` mêlait les
conditions structurelles — le niveau du livre, les points de la compétence, le
parent — aux deux questions de comptabilité : la case est-elle pleine, reste-t-il
un point. Or le dessin doit distinguer « verrouillé » de « ouvert, mais tu n'as
plus de point », et il n'a pas le droit de refaire la règle pour y arriver. D'où
`Manuel.est_ouvert()`, qui ne porte que les conditions structurelles, et
`peut_investir()` qui l'appelle.

**`StatMod.nom()` ne savait pas nommer un nombre de lancer sans mot-clé.** Une
ligne de nœud n'a pas de portée à écrire — elle ne vise que sa compétence — et la
fonction retombait donc sur la table de la fiche, où « degats » n'existe pas :
la fiche d'un nœud affichait `degats` tel quel. Elle regarde maintenant les deux
tables, dans cet ordre.

### Ce que l'étape 3 a changé au plan

**La conversion ne se voyait pas.** Un sort de foudre entièrement converti au feu
partait encore violet : le tir prend sa couleur de sa scène, et c'était une
décision explicite du jalon 8 — « un éclair reste un éclair, le froid qu'un objet
y ajoute change ses dégâts, pas son dessin ». Elle vaut pour ce qu'un **objet**
ajoute, pas pour ce qu'un nœud **convertit**, et le nœud le plus cher de son arbre
n'aurait eu aucun effet visible.

D'où `StatsDeCompetence.nature_dominante()`, qui ne regarde que les dégâts propres
de la compétence et les conversions — jamais les fourchettes ajoutées, ce qui
laisse la décision du jalon 8 intacte —, et un argument de plus à
`Projectile.setup()`. Un test garde les deux sens : le tir converti change de
couleur, le tir d'un objet de froid non.

**Deux tests du jalon 6 affirmaient qu'une case porte une compétence.** C'est
devenu faux ; ils disent maintenant qu'un manuel enseigne au moins une
compétence, et la règle « une case, une chose » appartient à `test_talents.gd`.

### Ce que l'étape 4 a changé au plan

**La fiche de survol est devenue un objet.** Trois sortes de fiche — compétence,
passif, nœud — et un sous-titre qui dit ce que la case est : monté à part du
contenu, il aurait fini par parler d'autre chose que les lignes en dessous. D'où
`ManuelPanel.Fiche`, qui porte le titre, le sous-titre et les lignes, décidés au
même endroit.

**Deux retouches que seule la capture a montrées** (§8 n'en prévoyait aucune) :
la plaque du compte de points dépassait du pan coupé d'un passif, et le dessin du
manuel de feu — un livre ouvert en étoffe — sortait gris sur gris et se lisait
comme un oiseau. Ses pages prennent maintenant la rampe du métal, la plus claire
des trois.

### Ce que l'étape 5 a changé au plan

**« 2 points dans Lames tournoyantes » débordait de la fiche** de dix-sept pixels,
en français. Le nom de la compétence est écrit juste au-dessus, dans l'en-tête de
l'arbre : la ligne dit donc « 2 points dans la compétence ». C'est le test de
largeur qui l'a vu, et aucune capture française ne l'aurait montré — la fiche
mesurée était celle d'un livre neuf, qu'on ne regarde pas deux fois.

**Le catalogue a gagné une section « Manuels »**, ce que le §10 ne prévoyait pas.
Vingt-sept nœuds répartis dans trois `.tres` ne se comparent pas en ouvrant trois
fichiers : la référence générée en donne les tables, avec le budget de points de
chaque livre contre les vingt qu'il gagne.

---

## 10. Ce que devient la documentation

`docs/ARCHITECTURE.md` gagne quatre lignes à « Où vit chaque règle » : ce qu'une
case porte, d'où viennent les talents d'un lancer, ce qu'un passif change et
quand, et ce qui se reprend. `docs/RECETTES.md` gagne **deux recettes** — ajouter
un passif, ajouter un nœud de talent — et la recette « ajouter une compétence »
gagne son arbre. Aucun invariant ne bouge : ce jalon n'en ajoute pas un neuvième,
il se range sous ceux qui existent — identifiants définitifs (1), `.tres` jamais
écrit (2), un seul point de passage pour la résolution (5).

---

## 11. Ce qui peut mal tourner

**Le nœud qui partage son identifiant avec une case.** Les deux lisent le même
dictionnaire : le point placé dans l'un s'affiche sur l'autre. Rien ne plante, et
ça se découvre en jouant. D'où le test d'unicité par livre.

**Le point de nœud jeté au rechargement.** Si le filtre de relecture reste
`enseigne()`, tous les arbres se vident à la première sauvegarde relue — et les
fichiers sont intacts, donc rien ne le signale. C'est le §5, et le test de
l'aller-retour.

**Le passif qui reste après le livre.** Un passif est appliqué au moment du
recalcul ; le rangement d'un manuel doit donc recalculer. Oublié, le bonus
persiste jusqu'au prochain changement d'équipement — et à la sauvegarde suivante
il aura disparu sans que le joueur ait rien fait.

**Le double compte.** Un passif dont la ligne vise un mot-clé ne doit pas
atteindre la fiche, et l'inverse : c'est la règle de `StatMod.apply_all()`, et le
même piège qu'au jalon 7. Passer par le même tri que les objets est la seule
façon de ne pas l'écrire deux fois.

**La conversion qui dépend de l'ordre.** Convertie avant les ajouts, une part
d'objet échapperait à la conversion, et deux objets identiques donneraient deux
résultats selon l'ordre d'équipement. C'est le §3, et le test le vérifie sur la
somme.

**La fiche qui ment.** Tous les nombres de la page passent par
`Player.resoudre()` depuis le jalon 7. Un nœud lu directement dans le dessin — par
commodité, pour afficher un « +1 projectile » — rouvrirait exactement la faille
que cette règle a fermée.

**L'arbre ouvert sur un livre rangé.** Le clic droit sur un dos peut vider
l'emplacement dont l'arbre est ouvert. La vue doit alors retomber sur la grille,
sinon elle dessine les nœuds d'un livre qui n'est plus là.

**Le manuel qui noie le butin.** Trois manuels dans la réserve de bases au lieu
d'un, tirée uniformément : un ramassage sur dix devient un livre de deux cases sur
deux. C'est le premier nombre à regarder si le sac paraît encombré — et la réponse
serait un poids dans `ItemCatalog.disponibles()`, qui n'en a pas encore.
