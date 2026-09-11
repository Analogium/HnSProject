# Hack'n'slash top-down — jalon 7

Suite de `hack-n-slash-jalon-1.md`, qui reste la référence sur l'architecture et
les conventions, et des jalons 2 à 6. Ce document ne redit pas ce qui y est déjà
écrit, et `docs/ARCHITECTURE.md` reste le seul endroit qui décrit l'état courant.

**Décidé le 10 septembre 2026.** Le jalon 6 a donné des compétences, et chacune
porte ses nombres dans son `.tres`. Mais **rien ne peut les toucher de
l'extérieur** : un objet ne sait modifier que les champs de `CharacterStats`, et
« nombre de projectiles » n'en est pas un. Le jour où l'arbre de talents
arrivera, il n'aura aucune prise — il ne pourra que redonner des dégâts et de la
vitesse, c'est-à-dire refaire ce que les affixes font déjà.

Il manque la prise elle-même : **un mot-clé porté par la compétence, sur lequel
un modificateur peut mordre.**

---

## 1. Périmètre du jalon 7

**Dedans :**

- **Les mots-clés** : une liste fermée, portée par chaque compétence, en partie
  déclarée et en partie déduite, et **montrée au joueur sur la compétence**
- **Les statistiques de compétence** : nombre de projectiles, vitesse de
  projectile, dispersion, coût, cadence, dégâts — résolues à chaque lancer
- **Le modificateur ciblé** : « +1 projectile », « +10 % de vitesse de
  projectile », qui ne s'applique qu'aux compétences portant le mot-clé
- **Une source réelle** : les affixes d'objets gagnent une portée, pour que le
  système ne soit pas du code mort en attendant l'arbre

**Dehors :**

- **L'arbre de talents.** Il est la raison de ce jalon, il n'en fait pas partie.
  Ce qu'on construit ici est la prise sur laquelle il se branchera ; le dessiner
  maintenant, ce serait décider de sa forme avant d'avoir vu la prise tenir.
- **Les mots-clés sur les objets.** `ItemBase.tags` existe déjà et sert au
  filtrage des affixes. Les deux vocabulaires se ressemblent et ne se mélangent
  pas : l'un dit ce qu'un objet **est**, l'autre ce qu'une compétence **fait**.
- **Les modificateurs conditionnels** (« +20 % de dégâts si vous avez tué
  récemment »). Une autre mécanique, et elle demande un état dans le temps.

---

## 2. Le principe : un mot-clé est une prise, pas une catégorie

La tentation est de traiter les mots-clés comme un rangement — « les sorts de
projectile », « les sorts de zone » — et d'en faire un champ d'affichage. Ce
n'est pas à ça qu'ils servent.

**Un mot-clé n'existe que parce que quelque chose mord dessus.** Sa seule raison
d'être est qu'un modificateur puisse dire « ceci s'applique aux compétences qui
le portent ». Un mot-clé que rien ne vise est un mot inutile, et il faut le
retirer plutôt que le garder « au cas où » : la liste doit rester assez courte
pour qu'on la connaisse par cœur en la lisant.

C'est aussi pourquoi la liste est **fermée**. Une chaîne libre dans un `.tres`
donnerait un `projectiles` au pluriel qui ne serait jamais visé par le
modificateur écrit sur `projectile`, et **rien ne le dirait** — le sort marcherait,
simplement il ne recevrait pas son bonus. C'est la faute la plus coûteuse du
jalon parce qu'elle est silencieuse.

---

## 3. Le joueur les voit, donc ils sont un contrat

Un mot-clé caché serait un détail d'implémentation. **Montré, il devient une
promesse** : le joueur qui lit « Projectile » sur son sort en déduit que tout ce
qui parle de projectiles l'améliorera, et il aura raison — sinon le jeu lui a
menti.

Trois conséquences, et elles portent sur tout le reste du jalon :

**Chaque mot-clé porte un libellé**, comme un emplacement d'équipement porte le
sien dans `EquipmentSlots.SLOTS` et une statistique dans `StatMod.LABELS`. Le
code manipule `projectile`, le joueur lit « Projectile ». Les deux vivent dans la
même entrée : deux listes parallèles finiraient par ne plus se correspondre.

**La liste reste honnête.** Un mot-clé affiché que rien ne modifie est une
promesse non tenue — pire qu'un mot-clé absent, parce qu'il envoie chercher un
objet qui n'existe pas. Un mot-clé se retire donc du jour où plus rien ne le
vise, et il ne s'en ajoute pas « pour plus tard ».

**L'affichage passe en première étape**, et non en finition. C'est ce que le
joueur touche ; le reste est la tuyauterie qui le rend vrai. Le montrer d'emblée
permet aussi de juger le vocabulaire avant d'avoir bâti dessus — un mot mal
choisi se change en une ligne le premier jour et en dix le dernier.

**Où il les voit :** la fiche du bas de la page d'un manuel, celle qui dit déjà
ce que la case survolée fait vraiment. C'est le seul endroit du jeu où l'on
regarde une compétence pour la comprendre plutôt que pour la lancer.

---

## 4. Déclaré et déduit

Une compétence porte déjà deux choses qui sont des mots-clés en puissance : sa
`nature` (foudre, froid…) et sa `cadence` (arme ou incantation).

**Elles ne se redéclarent pas.** Un `.tres` qui écrirait à la fois
`nature = LIGHTNING` et `tags = ["foudre"]` porterait deux vérités sur la même
chose, et la première correction en oublierait une. `Competence.mots_cles()`
rend donc l'union de trois sources :

- les mots-clés **déclarés**, ceux que rien d'autre ne sait : `projectile`,
  `zone`, `melee` ;
- le mot-clé de la **nature**, déduit de `DamageType` ;
- `attaque` ou `sort`, déduits de la **cadence**.

C'est un écart assumé avec `ItemBase.tags`, où la famille est déclarée à la main
dans la liste et vérifiée par un test. La raison de l'écart : là-bas le filtre
des affixes lit une liste plate et la famille devait y figurer ; ici,
`mots_cles()` est une fonction, la déduction ne coûte rien, et ce qui n'est pas
écrit ne peut pas diverger.

---

## 5. Les statistiques de compétence ne sont pas des statistiques de personnage

`CharacterStats` décrit un corps : ses PV, son armure, sa vitesse. « Nombre de
projectiles » n'y a pas sa place — ce n'est pas une propriété du personnage, mais
d'un geste. Deux compétences lancées par le même personnage n'en ont pas le même
nombre, et un champ unique sur la fiche ne saurait pas les distinguer.

D'où une seconde structure, `StatsDeCompetence`, qui est **le résultat d'un
lancer** et non un état conservé : dégâts, projectiles, dispersion, vitesse de
projectile, coût en mana, intervalle. Elle naît à chaque appel et meurt avec lui.

Elle absorbe au passage un défaut du jalon 6 : la vitesse d'un tir est
aujourd'hui un `@export` de la **scène** du projectile. Deux compétences qui
partagent `player_bolt.tscn` ont donc forcément la même vitesse, et aucun
modificateur ne peut y toucher.

---

## 6. La résolution, et son ordre

`Competence.resoudre(points, stats, mods) -> StatsDeCompetence` part des valeurs
de la fiche, puis applique les modificateurs dont le mot-clé est porté.

**Les plats d'abord, les pourcentages ensuite**, exactement comme
`StatMod.apply_all` et pour la même raison : sinon un « +1 projectile » appliqué
après un « +50 % » ne vaut pas le même « +1 » appliqué avant, et deux objets
identiques donneraient deux résultats selon l'ordre d'équipement.

**Le nombre de projectiles s'arrondit à la fin, jamais en cours de route.** Un
`+50 %` sur trois projectiles donne 4,5 : arrondir à chaque étape ferait dépendre
le résultat de l'ordre des modificateurs.

---

## 7. D'où viennent les modificateurs

Le porteur est le joueur : `Player.mods_de_competence`, reconstruite d'un bloc
dans `recompute_stats()`, comme la fiche l'est déjà. Un seul endroit reconstruit,
un seul endroit à ne pas oublier.

Sa source, dans ce jalon, est **l'affixe d'objet** : `ItemAffix` gagne un champ
de portée. Un affixe sans portée agit sur la fiche comme aujourd'hui ; un affixe
avec portée devient un modificateur ciblé. C'est ce qui empêche ce jalon d'être
du code mort en attendant l'arbre — et l'arbre, plus tard, versera dans la même
liste sans que rien d'autre ne bouge.

**Conséquence assumée : un « +1 projectile » touche aussi le tir de base**, qui
porte le mot-clé `projectile`. C'est le comportement de PoE et il est voulu — un
modificateur qui épargnerait les compétences de départ demanderait une exception
écrite quelque part, et cette exception serait la première chose qu'on oublierait
en ajoutant un sort.

---

## 8. Ordre de construction

Chaque étape se valide avec `tests/run.sh` avant la suivante.

- [x] **1. Les mots-clés, et le joueur qui les voit.** La liste fermée avec ses
      libellés, le champ déclaré sur `Competence`, la déduction depuis `nature` et
      `cadence`, `mots_cles()`, et **la ligne qui les affiche sur la fiche d'une
      case de manuel**. Rien ne les modifie encore : l'étape ne change pas le jeu,
      elle en montre le vocabulaire. C'est voulu — un mot mal choisi se change en
      une ligne maintenant, en dix une fois qu'on a bâti dessus. Tests : chaque
      mot-clé déclaré dans un `.tres` appartient à la liste — c'est le test qui
      attrape la faute de frappe silencieuse ; chaque mot-clé de la liste a un
      libellé ; une compétence de foudre porte `foudre` sans l'avoir écrit ; un tir
      porte `projectile` et un coup d'épée non.
- [x] **2. Les statistiques de compétence.** `StatsDeCompetence`,
      `ModDeCompetence`, et `resoudre()`. Toujours aucun effet : le joueur ne
      l'appelle pas encore. Tests : sans modificateur, la résolution rend
      **exactement** les nombres de la fiche — c'est le test qui garantit qu'on
      n'a rien changé au jeu ; les plats passent avant les pourcentages ; un
      modificateur dont le mot-clé n'est pas porté ne fait rien.
- [x] **3. Le lancer passe par la résolution.** `Player._tirer` et `_swing`
      lisent `StatsDeCompetence` au lieu de la fiche, la vitesse de projectile
      quitte la scène pour la compétence. Tests : les quatre sorts de foudre
      partent avec exactement les mêmes nombres qu'avant ; un tir lancé avec un
      `+1 projectile` en sort deux.
- [x] **4. L'affixe porté.** La portée sur `ItemAffix`, la reconstruction de la
      liste dans `recompute_stats()`, et deux affixes réels — un `+1 projectile`
      et une vitesse de projectile. Régénérer `docs/CATALOGUE.md`. Tests : un
      objet porté ajoute son projectile et le retirer le reprend ; un affixe
      porté n'écrit **rien** sur `CharacterStats` — c'est le test qui attrape la
      confusion entre les deux familles de modificateurs.
- [x] **5. Les nombres affichés deviennent les vrais.** La fiche d'une case
      montre les nombres **résolus** et non ceux du `.tres` : avec un « +1
      projectile » porté, elle annonce deux traits. Tests : la fiche passe par la
      **même** fonction que le lancer — deux calculs séparés divergent d'un
      arrondi, et c'est l'affichage qui passe alors pour un menteur.

### Ce que l'étape 5 a changé au plan

- **La fiche passe par `Player.resoudre()`, pas directement par
  `Competence.resoudre()`.** Partager la fonction ne suffisait pas : il fallait
  aussi la même fiche et la même liste de modificateurs. Le joueur les tient ;
  passer par lui empêche la page de résoudre « à mains nues ».
- **Les traits ne se comptent qu'à partir de deux.** « 1 trait » sur chaque sort
  droit serait une ligne qu'on apprend à ne plus lire.
- **La vitesse n'est pas affichée.** Elle se voit en jouant, et une ligne de plus
  sur la fiche la ferait remonter sur les cases.

### Ce que l'étape 4 a changé au plan

- **Un troisième affixe, `orageux`, vise `foudre`.** Le plan n'en prévoyait que
  deux, tous deux sur `projectile`, et laissait « Foudre » affiché sur cinq sorts
  sans que rien ne le vise — exactement le mot-clé décoratif du §9.
  `test_chaque_mot_cle_est_vise_par_quelque_chose` le refuse désormais. Il prouve
  au passage que la résolution n'est pas écrite pour les seuls projectiles : c'est
  un pourcentage de dégâts, sur un autre mot-clé.
- **`sort` et `attaque` sont atteints par construction**, sans affixe porté :
  `intervalle()` divise la recharge par la vitesse d'incantation ou d'attaque, deux
  affixes de fiche qui existent déjà. Le test les exempte, et dit pourquoi.
- **Une nature ne donne un mot-clé que si quelque chose la vise.** Le §4 déduisait
  « le mot-clé de la nature » pour toutes ; `MOT_CLE_DE_NATURE` n'en contient
  qu'une, et un sort de froid n'affichera pas « Froid » tant que rien ne le vise.
- **La sauvegarde passe en version 4**, contrairement à ce qu'annonce le §9. Une
  ligne portée écrit sa `portee` : relue sans elle, un « +1 projectile »
  deviendrait une ligne de fiche visant un champ que la fiche n'a pas. Elle n'est
  **jamais déduite de l'affixe d'origine**, qu'un objet sans provenance n'a pas.
  Une v3 se relit telle quelle — toutes ses lignes visent la fiche — et
  `personnage_v4.json` rejoint les fichiers de référence.
- **`fourchu` a deux paliers : +1, puis +2 au niveau 50.** Une échelle d'un seul
  palier est refusée par `test_chaque_echelle_est_monotone`, et à raison. Le
  libellé est donc « nombre de projectiles » : « +2 projectile » serait faux.
- **Une ligne portée dit ce qu'elle vise** — « +20 % dégâts (Foudre) » — avec le
  libellé exact de la page du manuel, pour que le joueur rapproche l'objet du sort
  sans traduire. `StatMod.nom()` est le seul endroit qui l'écrit ; l'infobulle,
  l'établi, la forge et le catalogue y passent.
- **`ItemAffix.modificateur()` fabrique la ligne.** Le tirage et l'établi
  construisaient chacun leur `StatMod`, et l'un des deux aurait oublié la portée.
- **L'établi taisait les affixes qui ne tenaient pas dans son cadre** : sa liste
  s'arrête au bas du panneau sans rien dire. `test_chaque_affixe_accepte_a_sa_ligne`
  lit sa taille dans `zone.tscn` et vérifie chaque base.

### Ce que l'étape 3 a changé au plan

- **Tir ou coup d'arme se décide par le mot-clé `projectile`, et non plus par la
  cadence.** C'est ce que le mot-clé dit — ce que la compétence fait — et un sort
  de zone sera une incantation sans être un tir. « Projectile » sur la fiche est
  ainsi **exactement** ce qui fait partir un projectile.
- **`player_bolt.tscn` ne déclare plus de vitesse.** Toujours écrasée, elle
  laisserait croire qu'on règle le tir en l'y changeant. Les tirs ennemis gardent
  celle de leur scène : `spawn()` n'en impose une que si on la lui donne. La durée
  de vie reste sur la scène, donc un bonus de vitesse porte aussi plus loin.
- **Les recharges se comparent à la précision d'un réel sur 32 bits** : c'est
  celle de `_recharges`, et la valeur rangée n'a jamais été, même avant, celle
  calculée au bit près.

### Ce que l'étape 2 a changé au plan

- **`ModDeCompetence` n'existe pas : `StatMod` gagne une `portee`.** Une seconde
  classe aurait demandé au tirage, à l'infobulle, à l'établi et à la sauvegarde de
  connaître deux formes pour une même chose, une ligne d'affixe. La confusion des
  deux familles, que le §9 redoutait, est gardée à un seul endroit :
  `StatMod.apply_all()` écarte ce qui est porté, et c'est la seule fonction qui
  écrit une liste sur la fiche.
- **La double passe est sortie en `StatMod.appliquer()`**, qui sert la fiche comme
  le résultat d'un lancer : « les plats d'abord » n'est écrit qu'une fois.
- **Deux traits ne partent jamais l'un sur l'autre.** Pas prévu : un « +1
  projectile » sur un trait droit en faisait partir deux au même angle — on en
  voyait un, qui frappait deux fois. `StatsDeCompetence.ECART_MINIMAL` ouvre huit
  degrés par trait de plus ; une salve déjà plus large garde la sienne. La borne
  au tour complet du §9 vit au même endroit, dans `conclure()`.
- **Seuls trois nombres se modifient** : les dégâts, le nombre et la vitesse des
  projectiles. Le coût et l'intervalle ont déjà leurs voies ; la dispersion n'a pas
  d'affixe, donc pas de nom.
- **`MotsCles` et `StatsDeCompetence` sont des feuilles.** `StatMod` lit leurs
  libellés et `Competence` applique des `StatMod` : les nommer l'une dans l'autre
  refermerait la boucle.

### Ce que l'étape 1 a changé au plan

- **La liste vit dans une classe-feuille, `MotsCles`, et la déduction dans
  `Competence`** : deux tables, `MOT_CLE_DE_CADENCE` et `MOT_CLE_DE_NATURE`. La
  liste ne peut pas nommer `Competence.Cadence` sans que `Competence`, qui la lit,
  ne se referme sur elle.
- **L'ordre d'affichage est celui de la liste** — ce que la compétence fait, sa
  nature, sa famille — et non celui de la déclaration : deux sorts voisins se
  lisent colonne contre colonne.
- **La fiche passe de quatre à cinq lignes.** Les cases descendent jusqu'à 172
  pixels et la fiche commence à 180 ; le test des cases le vérifie avec la même
  fonction que le dessin.

---

## 9. Ce qui peut mal tourner

**La faute de frappe silencieuse.** Un `projectiles` au pluriel dans un `.tres`,
et le sort ne reçoit jamais son bonus sans qu'aucune erreur ne sorte. C'est la
raison d'être de la liste fermée et du test de l'étape 1.

**La confusion des deux familles de modificateurs.** Un affixe porté qui
écrirait quand même sur `CharacterStats` donnerait le bonus **deux fois**, et
seulement pour certaines compétences. Le test de l'étape 4 le vise directement.

**Le vocabulaire qui se dédouble.** `ItemBase.tags` et les mots-clés de
compétence se ressemblent assez pour qu'on soit tenté de les fusionner. Ils
répondent à deux questions différentes — ce qu'un objet est, ce qu'une compétence
fait — et les réunir donnerait une liste où « bottes » et « projectile »
cohabitent sans qu'on sache ce qui vise quoi.

**La nova.** Sa dispersion vaut le tour complet, et la répartition divise l'écart
par le nombre de traits plutôt que par les intervalles. Un « +1 projectile »
change donc l'espacement de la couronne, ce qui est correct — mais un
« +50 % de dispersion » sur un cercle déjà fermé ne veut rien dire. La dispersion
se **borne** au tour complet.

**Le mot-clé décoratif.** Le jour où l'on affiche `zone` sur un sort alors
qu'aucun modificateur ne vise `zone`, le joueur cherchera un objet qui n'existe
pas. Un mot-clé montré est une promesse, et la liste doit rester **honnête** :
elle ne contient que ce que quelque chose peut réellement modifier.

**L'équilibrage.** « +1 projectile » est le modificateur le plus fort du genre :
sur une salve de trois, c'est un tiers de dégâts en plus. Il est ici pour prouver
la mécanique, pas pour être bien réglé, et c'est le premier endroit où revenir
quand le jeu paraîtra trop facile.

**Ce que la sauvegarde retient : rien de neuf.** Les mots-clés vivent dans les
`.tres` partagés et les modificateurs se recalculent depuis l'équipement. Le
format ne bouge pas — c'est l'arbre de talents, plus tard, qui aura des points
alloués à écrire.
