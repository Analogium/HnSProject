# Hack'n'slash top-down — jalon 8

Suite de `hack-n-slash-jalon-1.md`, qui reste la référence sur l'architecture et
les conventions, et des jalons 2 à 7. Ce document ne redit pas ce qui y est déjà
écrit, et `docs/ARCHITECTURE.md` reste le seul endroit qui décrit l'état courant.

**Décidé le 11 septembre 2026.** Le jalon 7 a donné aux compétences des
mots-clés, et aux affixes une portée. Mais les dégâts, eux, sont restés ceux du
jalon 5 : **un nombre plat, sans nature**. « +6 dégâts » ne dit pas si c'est du
feu, « +5 dégâts de sort » prend la nature du sort qu'il nourrit, et un objet ne
peut pas rendre un sort de foudre dangereux pour un ennemi qui résiste à la
foudre.

Il manque ce qui fait le cœur du genre : **« ajoute 3 à 7 dégâts de froid aux
sorts »** — une fourchette, une nature, et une famille de compétences.

---

## 1. Périmètre du jalon 8

**Dedans :**

- **Le coup en plusieurs natures** : un coup porte une part par nature, et
  chacune est réduite par sa propre défense — l'armure pour le physique, sa
  résistance pour le reste
- **Les dégâts ajoutés en fourchette** : « ajoute # à # dégâts de <nature> aux
  attaques » ou « aux sorts », tirés à chaque lancer
- **La séparation attaque / sort** passe par les mots-clés du jalon 7 : une ligne
  « aux attaques » est un affixe porté sur `attaque`, « aux sorts » sur `sort`
- **Le remplacement des plats d'aujourd'hui** : `acere`, `arcanique`, les
  implicites des épées, des masses et des grimoires, et le bonus de force
  deviennent des fourchettes
- **Le retrait de `meurtrier`** (+% dégâts, armes de mêlée). `orageux` (+% dégâts
  des compétences de foudre) reste
- **La sauvegarde en version 5**, et la conversion des lignes des personnages
  existants

**Dehors :**

- **Les altérations d'état** (brûlure, gel, choc). Elles sont la suite naturelle
  des natures séparées, et une autre mécanique : un état dans le temps.
- **Le critique des sorts.** Constaté en lisant le code : un projectile du joueur
  ne critique jamais, seul le coup d'épée passe par `DamageInfo.roll()`. C'est
  vrai depuis le jalon 5, ce n'est pas l'objet de ce jalon, et le corriger
  changerait l'équilibrage de tous les sorts d'un coup.
- **Les dégâts des ennemis.** Un grunt frappe toujours d'une seule nature, avec un
  seul nombre. Rien ne change pour eux, et c'est vérifié.
- **La conversion** (« 50 % du physique converti en feu »). Une autre mécanique,
  qui suppose que celle-ci tienne d'abord.

---

## 2. Le principe : un coup est une somme de parts, et chaque part a son adversaire

Aujourd'hui `DamageInfo` porte **un** montant et **une** nature, et `Hurtbox`
choisit **une** défense. C'est ce qu'il faut casser, et c'est tout le jalon :
une fois qu'un coup sait porter du froid à côté de sa foudre, les fourchettes,
les affixes et l'affichage n'en sont que la conséquence.

**Chaque part est réduite séparément.** Un sort de foudre qui porte trois points
de froid, lancé sur un ennemi à 75 % de résistance à la foudre et 0 % au froid,
perd les trois quarts de sa foudre et **garde tout son froid**. C'est ce qui
donne un sens à l'élément écrit sur l'objet — et c'est pourquoi l'autre
solution, où le froid ajouté prendrait la nature du sort, a été écartée : l'objet
mentirait.

**Le plancher d'un coup s'applique au total**, pas à chaque part. `MIN_DAMAGE`
existe pour qu'aucune défense ne rende invincible ; appliqué part par part, un
coup en six natures ferait six points au lieu d'un.

**L'armure se calcule sur la part physique seule.** Sa règle dépend de la taille
du coup — elle protège plus des petits coups — et un sort de foudre à trois
points de physique ne doit pas être traité comme un gros coup physique.

---

## 3. La fourchette : tirée une fois par lancer

« Ajoute 3 à 7 » veut dire qu'**un lancer** tire une valeur entre 3 et 7. Un
lancer et non un impact :

- une salve de trois traits tire **trois fois**, une par trait — trois traits
  identiques au point près se liraient comme un bug ;
- un coup d'épée tire **une fois**, et touche tous les ennemis de son arc avec la
  même valeur — un balayage qui fait 3 à l'un et 7 à l'autre dans la même image
  se lit comme un bug aussi.

**Avec `Game.rng`, et un tirage par fourchette non vide, quel que soit le
résultat** (invariant 3). Le nombre de tirages dépend de l'équipement, jamais de
ce qui sort.

**Les dégâts propres d'une compétence restent un nombre fixe** — les
`degats_par_point` du jalon 6. La variance vient des objets, pas du sort : ce qui
se lit sur la page d'un manuel reste un nombre qu'on peut comparer d'un point au
suivant.

---

## 4. Ce que deviennent les plats d'aujourd'hui

**Les nombres du jeu ne bougent pas** — c'est la contrainte de ce paragraphe, et
le test de l'étape 2 la garde.

| Aujourd'hui | Devient |
|---|---|
| `attack_damage` de la fiche du joueur (12) | La table de l'**Attaque** : `[12]` |
| `spell_damage` de la fiche du joueur (7) | **+7 dans chaque table de sort**, Trait compris |
| Force → +0,2 `attack_damage` par point | Force → **ajoute 0,2 à 0,2 dégâts physiques aux attaques** par point |
| Implicite « +4 dégâts » d'une épée | « ajoute 2 à 6 dégâts physiques aux attaques » — la moyenne d'avant |
| Implicite « +5 dégâts de sort » d'un grimoire | « ajoute 3 à 7 dégâts de foudre aux sorts » |
| `acere` (+dégâts, mêlée) | un affixe « dégâts physiques aux attaques » |
| `arcanique` (+dégâts de sort) | trois affixes « dégâts de <nature> aux sorts » |
| `meurtrier` (+% dégâts, mêlée) | **retiré** |

**La force garde exactement son effet**, en changeant de forme : une fourchette
dont les deux bornes sont égales. C'est la continuité la moins surprenante ; lui
donner un pourcentage serait une règle de plus, et il vient d'en partir une.

**`spell_damage` disparaît de `CharacterStats`.** Plus rien ne le lit.

**`attack_damage` reste, pour les ennemis seulement.** Un grunt n'a pas de
compétence : il frappe avec les dégâts de son corps, que la montée de niveau
multiplie. Le joueur, lui, ne le lit plus — la ligne quitte sa fiche, et le champ
de `player_stats.tres` passe à zéro. Le renommer toucherait les fiches
d'archétypes pour un gain de lecture : décidé, on ne le renomme pas, mais son
commentaire dit à qui il sert.

**Les implicites gagnent une portée et une borne haute**, comme les affixes : un
implicite d'arme est une ligne d'objet comme une autre.

---

## 5. Les affixes

Douze affixes remplacent `acere` et `arcanique` : **chaque nature, dans les deux
familles**. Chacun porte un mot-clé — `attaque` ou `sort` — et une statistique
par nature :

| Aux attaques | Aux sorts |
|---|---|
| physique · froid · feu · foudre · nécrotique · sacré | physique · froid · feu · foudre · nécrotique · sacré |

**Une nature est une nature comme les autres** (décidé le 11 septembre, sur
demande). Aucune n'a de traitement à part dans les affixes : le physique aux
sorts, le nécrotique et le sacré existent même si aucune compétence du jeu n'en
est encore, parce qu'**ajouter** une part d'une nature ne demande pas qu'une
compétence en soit. Un sort de foudre qui reçoit du sacré frappe en foudre et en
sacré.

Conséquence sur le tirage : douze lignes de dégâts dans la réserve, là où il y en
avait deux. Leurs poids sont réglés pour que **la famille** pèse ce que pesaient
`acere` et `arcanique`, et non douze fois plus.

**Un « +% dégâts des sorts », `ensorcele`, sur les armes et les main gauche de
lanceur** (décidé le 11 septembre, sur demande, après l'étape 7). Un pourcentage
porté sur `sort`, à l'échelle et au poids d'`orageux` : il multiplie toutes les
parts d'un sort, comme lui. Il ne sort que sur ce qui porte l'étiquette
`caster` — baguettes, sceptres, grimoires, codex — et jamais sur un bijou : c'est
l'objet qu'on tient pour lancer qui rend les sorts plus forts. Son identifiant ne
reprend pas `arcanique`, retiré (invariant 1).

**Deux fourchettes par palier**, et non une : « ajoute (3–4) à (7–9) ». La borne
basse et la borne haute se tirent chacune dans la sienne. Un seul tirage avec un
écart fixe donnerait des objets qui ne diffèrent que d'un facteur, et c'est la
comparaison de deux fourchettes qui fait regarder deux objets.

**Les nouveaux identifiants ne reprennent pas les anciens** (invariant 1). Une
sauvegarde qui porte `acere` au palier 7 parle de l'échelle d'`acere` ; donner ce
nom à une autre échelle rendrait son palier faux.

---

## 6. L'affichage

**Sur la page du manuel, survoler une case ouvre la fiche complète de la
compétence** (décidé le 11 septembre, sur demande). Elle remplace la fiche de
trois lignes du bas de la page, qui ne pouvait plus rien contenir : une fenêtre
flottante, bien plus grande, à côté de la case, qui liste **tout** ce que la
compétence fait — une caractéristique par ligne :

- le nom, les mots-clés, les points placés ;
- le coût en mana et la recharge ;
- les dégâts de base, dans la nature de la compétence ;
- **les dégâts ajoutés, une ligne par nature** ;
- ce que l'attribut rapporte ;
- pour un projectile : le nombre de traits, l'écart, la vitesse ;
- pour une case verrouillée, le niveau de manuel qu'elle demande.

Une ligne qui ne dit rien ne s'écrit pas : pas de « 0 froid », pas de « 1 trait »,
pas de vitesse sur un coup d'épée. **Tous ses nombres viennent de la résolution**,
par `Player.resoudre()` — la fiche est la preuve de ce que le lancer fera, pas une
description du `.tres`.

**La fiche se termine par une estimation** (décidé le 11 septembre, sur demande,
après l'étape 7) : la moyenne d'un lancer entier et sa valeur par seconde, **si
tout touche et avant les défenses** de la cible — la fiche le dit. Les bornes d'un
projectile ne disent pas ce que vaut une salve de quatre, et c'est ce nombre qu'on
cherche pour comparer deux sorts. Sans critique : un projectile du joueur n'en fait
pas.

**Dans le menu d'assignation de la barre, chaque entrée montre l'icône de la
compétence à côté de son nom** (décidé le 11 septembre, sur demande), avec le
disque de sa nature quand elle n'a pas d'icône — la même règle que la case de la
barre. On choisit un sort à sa silhouette avant de lire son nom.

**Sur la fiche de personnage**, les deux lignes « dégâts » et « dégâts de sort »
disparaissent — elles n'existent plus. Elles sont remplacées par **les deux
compétences de départ résolues** : « attaque » et « tir », avec leurs fourchettes.
C'est la séparation attaque / sort à l'endroit où le joueur la cherche, et ce sont
les seules compétences qu'aucune page de manuel ne décrit.

**Le nombre qui s'envole est le total, en blanc** (décidé le 11 septembre, sur
demande, après l'étape 7 — il prenait d'abord la couleur de la part la plus
forte). Six nombres par coup rendraient une mêlée illisible, et teindre le total
d'une seule de ses parts ferait lire un sort de foudre chargé de froid comme un
sort de froid. **Le trait garde la couleur de sa scène**, pour la même raison : un
éclair reste un éclair. Le critique garde son or et le coup encaissé par le
joueur son rouge — ce ne sont pas des natures —, et seule la gerbe d'éclats de
l'impact dit encore la part dominante.

**Dans l'infobulle**, une ligne se lit « ajoute 3 à 7 dégâts de froid aux sorts ».
Le « (Sort) » du jalon 7 ne s'écrit pas en plus : « aux sorts » dit déjà la
portée, en français, et deux fois la même chose sur une ligne se lit mal.

---

## 7. La sauvegarde, et les personnages qui existent déjà

**Version 5.** Une ligne d'affixe écrit sa borne haute (`valeur_max`) quand elle
en a une. Absente, la ligne est un nombre seul, comme toutes celles d'avant.

**Les lignes des versions 1 à 4 sont converties**, parce que les statistiques
qu'elles visent n'existent plus pour le joueur. La règle du format est « jamais
deviner » ; chaque conversion ci-dessous est donc une **équivalence exacte avec
le jeu d'aujourd'hui**, et non une supposition :

| Ligne relue | Devient | Pourquoi c'est exact |
|---|---|---|
| `attack_damage` plat X | ajoute X à X physique aux attaques | la seule attaque du jeu est physique |
| `spell_damage` plat X | ajoute X à X foudre aux sorts | **tous** les sorts du jeu sont de foudre |
| `attack_damage` en % (meurtrier) | **retirée**, avec un avertissement | plus rien ne multiplie les dégâts d'une attaque |

**La provenance des lignes converties est oubliée** : un palier 7 d'`acere` n'est
pas un palier 7 du nouvel affixe. La ligne s'applique ; c'est l'infobulle sous
Alt qui n'a rien à montrer, comme pour un objet d'avant les paliers.

**La perte de `meurtrier` est la seule perte du jalon**, et elle touche de vrais
personnages. Elle est annoncée au chargement plutôt que silencieuse.

---

## 8. Ordre de construction

Chaque étape se valide avec `tests/run.sh` avant la suivante. Les trois premières
ne changent **aucun nombre** du jeu.

- [x] **1. Le coup en plusieurs natures.** `DamageInfo` porte une part par nature,
      `Hurtbox` réduit chacune par sa défense, le plancher s'applique au total,
      le nombre qui s'envole prend la couleur de la part dominante. Les ennemis
      frappent en une seule part. Tests : un coup d'une seule nature est réduit
      **exactement** comme avant, armure et résistance comprises — c'est le test
      qui garantit que l'étape ne change pas le jeu ; un coup en deux parts perd
      sa foudre et garde son froid ; l'armure ne voit que la part physique ; le
      plancher porte sur le total.
- [x] **2. Les dégâts d'un lancer, par nature.** `StatsDeCompetence` porte ses
      dégâts par nature, en fourchette ; les bases de 12 et 7 entrent dans les
      tables ; `stat_de_base` et `spell_damage` disparaissent ; la force ajoute du
      physique aux attaques. Tests : sans objet, chaque compétence du catalogue
      rend **exactement** les nombres d'avant ; une fourchette tire entre ses
      bornes ; un lancer consomme un tirage par fourchette non vide, quel que soit
      le résultat.
- [x] **3. Le lancer porte ses parts.** Le coup d'épée et chaque projectile
      tirent leurs fourchettes au départ et portent leurs parts jusqu'à l'impact.
      Tests : chaque sort part avec les dégâts d'avant ; trois traits d'une salve
      tirent trois fois ; les ennemis d'un même coup d'épée reçoivent la même
      valeur.
- [x] **4. Les affixes en fourchette.** La seconde fourchette des paliers, la
      borne haute des lignes, les implicites portés, les douze affixes, le retrait
      d'`acere`, `arcanique` et `meurtrier`. Régénérer `docs/CATALOGUE.md`.
      Tests : la borne basse d'une ligne ne dépasse jamais sa borne haute ;
      chaque échelle reste monotone sur ses deux bornes ; une épée ajoute ses
      dégâts physiques à l'Attaque et pas au Trait.
- [x] **5. La sauvegarde en version 5.** La borne haute, la conversion des lignes
      anciennes, `personnage_v5.json`. **Avant toute interface**, comme aux jalons
      5 et 6. Tests : les fichiers de référence v1 à v4 se relisent, leurs lignes
      converties ; un personnage relu frappe exactement comme avant la mise à
      jour ; une ligne de `meurtrier` est retirée et le dit.
- [x] **6. La fiche de compétence au survol.** La fenêtre flottante de la page du
      manuel, qui remplace la fiche du bas. Capture en fenêtré : un sort à trois
      natures et plusieurs traits, et une case verrouillée. Tests : chaque ligne
      vient de la même résolution que le lancer ; une nature sans dégâts n'a pas
      de ligne ; la fenêtre reste dans le cadrage de 640 × 360, quelle que soit
      la case survolée.
- [x] **7. Le reste de ce que le joueur lit.** Le menu de la barre avec icône et
      nom, la fiche de personnage et ses deux compétences de départ, l'infobulle
      et l'établi. Captures : le menu ouvert, la fiche, l'infobulle d'une épée.
      Tests : le clic du menu retombe sur l'entrée dessinée, icône comprise ; la
      fiche tient dans sa hauteur.

### Ce que l'étape 7 a changé au plan

- **La ligne du tir s'appelle « trait »**, et non « tir » : c'est le nom que la
  compétence porte à l'écran, celui que le joueur lit sur la barre.
- **Les deux lignes ont leur explication au survol**, dans
  `StatHelp.COMPETENCES` et non dans la table des statistiques, qui est vérifiée
  champ par champ contre `CharacterStats`. Sans nombre : la ligne montre déjà la
  valeur résolue. Les deux tests d'honnêteté de la fiche les traitent pour ce
  qu'elles sont : une explication reste exigée, et elles comptent comme atteintes
  par les dégâts ajoutés qui visent leurs mots-clés.
- **Une entrée du menu fait vingt-six pixels de haut** : l'icône à la taille de sa
  grille, plus un pixel d'air. Une icône ne se réduit qu'en facteur entier, et une
  entrée de dix pixels l'aurait fait déborder sur sa voisine. Le livre entier
  appris, le menu tient encore au-dessus de la barre ;
  `test_le_menu_tient_dans_le_cadrage` le mesure depuis la place de la barre
  dans `zone.tscn`.
- **`StatsDeCompetence.fourchette_lisible()`** écrit les dégâts résolus pour la
  page du manuel comme pour la fiche : arrondis, et un seul nombre quand les deux
  bornes s'arrondissent au même.
- **L'infobulle et l'établi n'ont rien demandé de plus** : leurs lignes avaient
  été réécrites à l'étape 4. Les captures les montrent justes.

### Ce que l'étape 6 a changé au plan

- **La fiche compte les projectiles d'un trait droit.** Le §6 écartait « 1
  trait » ; la demande disait « le nombre de projectiles si projectile il y a »,
  et c'est le nombre qu'un « +1 projectile » modifie. Ce qui ne dit rien reste
  tu : pas d'écart pour un trait droit, pas d'accroissement sans objet qui en
  donne, pas de ligne pour une nature absente.
- **`StatsDeCompetence` garde sa décomposition** — la ligne de la table, les
  ajouts par nature, le facteur d'attribut, le produit des accroissements —,
  écrite par les appels mêmes qui calculent les bornes.
  `test_la_decomposition_refait_les_degats` vérifie qu'elle les recompose. Les
  multiplications gardent leur ordre : aucun nombre du jeu ne bouge.
- **Sans point placé, la fiche montre le premier**, et le dit.
- **La fiche s'arrête au-dessus des jauges du HUD**, dessinées après les
  panneaux. La limite est sortie en `Hud.haut_des_jauges()` : l'infobulle de la
  fiche de personnage la calculait déjà de son côté.
- **La page du manuel raccourcit de 230 à 196 pixels** : sans la fiche du bas,
  elle gardait une bande vide. Ses tests lisent désormais sa place dans
  `zone.tscn` au lieu d'une taille recopiée.

### Ce que l'étape 5 a changé au plan

- **Elle a été faite avant l'étape 4.** La conversion devait être prouvée contre
  l'ancien calcul **avant** qu'on le retire : les dégâts d'un personnage relu ont
  été comparés à ceux du code d'avant, puis figés en valeurs mesurées dans
  `test_personnage_joueur`.
- **Une borne haute plus basse que la valeur est redressée** à la lecture plutôt
  que refusée : `test_une_fourchette_a_l_envers_est_redressee`.

### Ce que l'étape 4 a changé au plan

- **`stat_de_base` et `spell_damage` sont partis ici**, et non à l'étape 2 : tant
  qu'`acere` et `arcanique` existaient, l'ancien terme gardait leurs lignes
  vivantes.
- **La force est une ligne portée que fabrique `recompute_stats()`** — « ajoute F
  à F dégâts physiques aux attaques » — à côté de celles des objets.
  `CharacterStats.degats_de_force()` en garde la règle.
- **Les poids ne tiennent qu'à moitié la promesse du §5.** Chaque affixe de dégâts
  ajoutés pèse 2. Aux attaques, la famille pèse 12, comme `acere` — mais
  `meurtrier`, qui pesait 10, est parti sans remplaçant. Aux sorts, elle pèse 12
  contre 10 pour `arcanique`. À reprendre avec le reste de l'équilibrage.
- **L'établi pagine ses affixes** : douze lignes de plus ne tenaient plus dans
  son cadre. Une ligne s'y lit par le nom court de `StatMod.nom()`, et changer de
  base ramène à la première page.
- **La fiche d'objet de la forge serre son interligne de 11 à 10 pixels** : les
  plages « 3–4 à 7–9 » la faisaient déborder de sa hauteur.
- **Le tir du joueur a d'abord pris la couleur de sa part dominante.** Retiré
  après l'étape 7, sur demande, avec la couleur du nombre : voir le §6.

### Ce que les étapes 2 et 3 ont changé au plan

- **Elles ont été faites ensemble** : la résolution par nature et le lancer qui
  porte ses parts ont été validés par la même campagne.
- **`DamageInfo` garde `amount` et `type`**, calculés depuis les parts : le total
  et la nature dominante. Les ennemis et les tirs ennemis frappent d'une seule
  part, par `Projectile.spawn_d_une_nature()`.

---

## 9. Ce qui peut mal tourner

**Le personnage qui perd sa force en se rechargeant.** Une conversion oubliée —
une ligne `attack_damage` relue sans être convertie — ne plante pas : elle écrit
dans un champ que le joueur ne lit plus, et le personnage frappe moins fort sans
que rien ne le dise. C'est le test de l'étape 5 qui compare avant et après.

**Le tirage qui dépend du résultat.** Tirer une fourchette seulement quand elle
n'est pas nulle *après* un modificateur, ou sauter le tirage d'un critique raté,
décale les tirages suivants de `Game.rng`. La règle est la même qu'au jalon 3 :
le compte ne dépend que de l'équipement.

**L'armure calculée sur le total.** Elle protège plus des petits coups : calculée
sur un sort à cinquante points dont trois physiques, elle traiterait ces trois
points comme un gros coup et ne les réduirait presque pas. Le test de l'étape 1
le vise.

**La mêlée illisible.** Un nombre par part ferait six chiffres par coup sur une
nova. Le total seul, en blanc.

**`orageux` sur un sort qui porte du froid.** « +12 % dégâts (Foudre) » vise les
compétences qui portent le mot-clé `foudre` : il multiplie **toutes** leurs
parts, froid ajouté compris. C'est la lecture du jalon 7 — le mot-clé désigne la
compétence, pas la part — et elle est gardée. Un « +% dégâts de froid » qui ne
multiplierait que les parts de froid serait une autre statistique, et elle n'est
pas dans ce jalon.

**L'équilibrage.** Sept affixes de dégâts au lieu de deux, et un sort qui peut
désormais contourner une résistance : le jeu va devenir plus facile contre les
ennemis résistants. C'est voulu, et c'est le premier réglage à reprendre en
jouant.
