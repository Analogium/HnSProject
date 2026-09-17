# Hack'n'slash top-down — jalon 11

Suite des jalons 1 à 10. Ce document ne redit pas ce qui y est déjà écrit, et
`docs/ARCHITECTURE.md` reste le seul endroit qui décrit l'état courant.

**Décidé le 14 septembre 2026.** Les trois manuels du jalon 10 enseignent sept
compétences qui sont toutes **le même éclair** : cinq sorts qui partent en
projectile, deux attaques qui balaient en arc. « Salve d'éclairs » et
« Fulguration » sont un éclair vif à d'autres réglages, et le manuel des flammes
est celui de la foudre repeint en orange. Un arbre de talents qui change la
façon dont on joue n'a rien à orienter quand tout se joue pareil.

Ce jalon donne à chaque compétence **sa forme** — ce qu'elle pose dans le monde
— et **son dessin**.

---

## 1. Périmètre

**Dedans :**

- **Le manuel de la foudre** garde Éclair vif et Nova de foudre. Salve d'éclairs
  et Fulguration partent ; arrivent **Chaîne d'éclairs** — une décharge qui saute
  entre trois ennemis — et **Nuage d'orage** — un nuage qui reste trois secondes
  là où on le pose et frappe ce qui passe dessous.
- **Le manuel des flammes** change entièrement : **Boule de feu**, qui explose à
  l'impact ; **Immolation**, un brasier autour du personnage qui brûle les
  ennemis **et lui-même** ; **Serpent infernal**, un serpent de feu lâché au sol
  qui y rôde, et dont le corps brûle ce qu'il touche.
- **Le manuel d'armes devient le manuel du chevalier.** Il garde Frappe lourde,
  avec un dessin neuf. Lames tournoyantes part ; arrivent **Coup en croix** — deux
  coups qui se croisent — et **Épée spirale** — une épée lancée qui tourne autour
  du personnage cinq secondes, trois au plus.
- **Chaque compétence son dessin**, y compris celles qui restent : le coup lourd
  ne se lit plus comme le coup d'épée de départ.
- **Un arbre de trois nœuds** pour chaque compétence neuve, sur la forme du
  jalon 10.

- **Une icône pour chaque compétence des manuels**, générée par ComfyUI comme
  celle d'Éclair vif (§5).

**Dehors :**

- **Les icônes des passifs et des deux attaques de départ.** Ils gardent le disque
  de couleur de leur nature.
- **Les passifs.** Conducteur, Cœur de braise et Garde de fer ne bougent pas.
- **Un nouveau mot-clé.** « Zone » ou « Durée » seraient les suivants naturels,
  mais un mot-clé n'existe que si un affixe le vise (jalon 7), et ce jalon n'en
  ajoute aucun. Les nombres neufs se modifient par les nœuds seulement.
- **L'équilibrage.** Premiers réglages, comme au jalon 10.

---

## 2. La forme d'une compétence

Jusqu'ici, `Player.cast_slot()` choisissait entre deux chemins sur le mot-clé
`projectile`. Sept chemins ne tiennent plus dans un booléen, et un mot-clé est
une prise pour les affixes, pas un aiguillage : « Chaîne » ou « Aura » n'en sont
pas, et n'en deviendront pas pour que le lanceur sache quoi faire.

**`Skill.shape`** dit ce que le lancer pose dans le monde :

| Forme | Ce qui part | Compétences |
|---|---|---|
| `ARC` | le coup d'épée en arc | Attaque |
| `BOLT` | un ou plusieurs projectiles | Trait, Éclair vif, Nova de foudre |
| `STRIKE` | le coup d'arc lourd | Frappe lourde |
| `BALL` | un projectile qui explose à l'impact | Boule de feu |
| `CHAIN` | une décharge de cible en cible | Chaîne d'éclairs |
| `CLOUD` | une zone posée, qui frappe à intervalle | Nuage d'orage |
| `AURA` | un cercle entretenu autour du lanceur | Immolation |
| `SNAKE` | une créature lâchée, qui frappe au contact | Serpent infernal |
| `CROSS` | deux coups d'arc croisés | Coup en croix |
| `ORBIT` | une lame qui tourne autour du lanceur | Épée spirale |

**La forme porte le dessin avec le comportement.** `STRIKE` se comporte comme
`ARC` et ne s'en distingue que par le dessin et la secousse : c'est assumé. Un
second champ « apparence » à côté de la forme aurait donné deux choix à
accorder pour une seule chose, et la question « quel coup lourd a le dessin de
la nova » n'a pas de réponse sensée.

**`projectile` se déduit de la forme**, comme `lightning` se déduit de la nature et
`spell` de la cadence : `BOLT` et `BALL` le donnent, les autres non. Il sort
donc de `declared_keywords` dans tous les `.tres` — une forme et une
déclaration seraient deux vérités sur la même chose.

**Un nœud ne change pas la forme.** C'est la règle du jalon 10 — « un nœud ne
donne ni `projectile`, ni `spell`, ni `attack` » — dite une fois de plus : la
forme est lue sur la compétence, et aucun champ de `TalentNode` ne la vise.

---

## 3. Les nombres neufs

Une chaîne a un nombre de cibles, un nuage une durée et un rayon. Ce sont des
**nombres de lancer**, donc des champs de `SkillStats` que la résolution
copie de la compétence et que les nœuds modifient par le même
`StatMod.apply()` que les projectiles :

| Champ | Nom à l'écran | Qui s'en sert | Un nœud peut-il le viser |
|---|---|---|---|
| `targets` | nombre de cibles | Chaîne | oui |
| `duration` | durée | Nuage, Serpent, Orbite | oui, en pourcentage |
| `radius` | rayon | Boule (l'explosion), Nuage, Aura | oui, en pourcentage |
| `simultaneous` | maximum simultané | Orbite | oui |
| `period` | — | Nuage, Aura (entre deux frappes) ; Serpent, Orbite (entre deux touches d'une même cible) | non |
| `self_burn` | — | Aura : la part des PV max perdue par seconde | non |

**La période et la brûlure ne se modifient pas.** La période change le nombre de
coups sans changer ce que la fiche appelle « dégâts », et une brûlure qu'un nœud
réduirait à zéro ferait de l'Immolation un sort sans prix. Ce sont des réglages
de la compétence, lus par la fiche, et c'est tout.

**Les coups par geste** : Coup en croix frappe deux fois. C'est la forme qui le
dit (`Skill.HITS_PER_SHAPE`), pas un champ : un nœud qui ajouterait un
troisième coup en croix n'a pas de dessin à montrer.

### Ce que la fiche estime

`SkillStats.average_per_cast()` multipliait un coup par les
projectiles. Elle multiplie maintenant **par les coups qu'un lancer porte si tout
touche** : projectiles × cibles × coups, et, pour ce qui dure, le nombre de
frappes dans la durée. Une aura n'a pas de fin, donc pas de « par lancer » : sa
fiche ne donne que « par seconde », un coup divisé par la période.

Ces estimations supposent une cible **au contact pendant toute la durée**, ce que
la note « si tout touche, avant défenses » dit déjà.

---

## 4. Chaque forme

### Qui est touché

Les coups qui ne naissent pas d'une collision — la chaîne, le nuage, l'aura, le
serpent, l'épée, l'explosion — cherchent leurs cibles **par une requête de
forme** sur le calque des hurtbox ennemies (`Targets.in_circle`). Une seule
fonction : six copies de la même requête finiraient par ne pas viser le même
calque.

Et tous passent par `Hurtbox.take_damage()` : esquive, résistances et retour
visuel ne s'écrivent pas une seconde fois (invariant 5).

**Le tirage** : une fois par geste pour ce qui frappe tout d'un coup (la chaîne
entière, une croix par coup), une fois par frappe pour ce qui dure (une impulsion
du nuage ou de l'aura pour tout son cercle, un contact du serpent ou de l'épée).

**Le gel d'impact** : la chaîne, la boule et les coups d'arc figent — un gel par
geste, `Game.hit_stop_period` fait le reste. **Ce qui dure ne fige jamais** : un
nuage qui gèle à chaque impulsion hacherait le jeu tant qu'il est posé, et ce
serait exactement les 12 % de temps figé que le jalon 10 a chassés.

### Chaîne d'éclairs

La première cible est **l'ennemi le plus proche dans un cône de 45° autour de la
visée**, à 150 px au plus. Chaque saut va à l'ennemi le plus proche de la
dernière cible, à 90 px au plus, qui n'a pas encore été touché. **Un mur coupe
un saut** : une décharge qui traverse la pierre se lit comme un bug.

Sans cible, la décharge part quand même dans le vide, sur les deux tiers de la
portée, et le mana est dépensé : un sort qui refuserait de partir faute de cible
se lirait comme une touche morte.

### Nuage d'orage et Serpent infernal : où ils tombent

**Au curseur, à 140 px au plus du personnage** ; à la manette, 140 px devant
lui. « Là où on le laisse » peut se lire « à ses pieds » — c'était moins utile :
un nuage posé sur soi oblige à se jeter dans le paquet pour s'en servir.

Le serpent **rôde** : il avance à vitesse constante en changeant de cap, et tourne
vers son point de chute dès qu'il s'en écarte de plus de 44 px. Son corps fait
seize anneaux ; chacun brûle ce qu'il touche, une fois toutes les 0,4 s par cible.

### Immolation

**Le lancer allume, le lancer suivant éteint** — sans coût pour éteindre. Tenir la
touche **n'alterne pas** : une aura qui s'allume et s'éteint à chaque fin de
recharge serait inutilisable. Allumée, elle frappe tous les ennemis de son cercle
toutes les 0,5 s et brûle le personnage de 3 % de ses PV max par seconde.

**La brûlure n'est pas un coup** : ni esquive, ni armure, ni chiffre flottant à
chaque image — c'est une régénération à l'envers. **La résistance au feu s'y
applique**, lue par `CharacterStats.resistance()`, et elle **peut tuer**. C'est le
contrat du sort : on le tient par la régénération et les résistances, pas par un
plancher qui le rendrait gratuit.

Elle s'éteint seule à la mort du personnage et quand son livre quitte le
râtelier : **elle se résout à chaque impulsion** par `Player.resolve()`, donc un
anneau retiré ou un point placé changent la brûlure suivante, et une compétence
qu'on ne sait plus lancer ne brûle plus rien.

### Épée spirale

Le lancer envoie une épée tourner autour du personnage **cinq secondes**. Chaque
épée a sa propre durée ; elles se répartissent régulièrement sur le cercle, et
glissent vers leur nouvelle place quand l'une disparaît. **Trois au plus** : le
quatrième lancer est **refusé**, sans mana ni recharge — c'est le cinquième refus
de `cast_slot()`, après la case vide, la compétence non apprise, la réserve et la
recharge. Remplacer la plus ancienne aurait fait payer du mana à la touche tenue
pour ne rien changer à l'écran.

C'est une **attaque** : sa cadence est celle de l'arme, et c'est cette cadence
qui sert de « recharge » entre deux lancers.

### Coup en croix

Deux coups, la hitbox rouverte entre les deux : **une même cible peut être touchée
deux fois**, et c'est ce qui le distingue d'un arc plus large.

### Boule de feu

Un projectile qui **explose** au premier ennemi ou au premier mur, et blesse
tout ce qui est dans le rayon **sauf la cible directe**, qui a déjà reçu le coup.
Les mêmes parts, sans nouveau tirage : l'explosion est le même coup, qui
s'étale.

**L'explosion naît en différé** (invariant 4) : l'impact arrive dans un rappel de
collision, où l'espace physique est verrouillé et où aucun nœud ne doit entrer
dans l'arbre.

---

## 5. Les dessins

Tous en code, comme le reste du projet — aucun fichier image.

| Compétence | Le dessin |
|---|---|
| Éclair vif, Nova | inchangé : le glyphe de l'éclair du jalon 9 |
| Chaîne d'éclairs | un trait brisé de cible en cible, qui regigote à chaque image et s'éteint en un quart de seconde |
| Nuage d'orage | un nuage sombre, sa zone marquée au sol, et un éclair vers chaque cible frappée |
| Boule de feu | un noyau clair dans une boule orange, trois langues de flamme derrière ; à l'impact, une onde et des étincelles |
| Immolation | un disque de braise au sol, une couronne de flammes qui dansent sur son bord, des escarbilles qui montent |
| Serpent infernal | seize anneaux du jaune au rouge, un sur deux plus sombre, une tête plus grosse, deux yeux, une langue |
| Frappe lourde | un croissant plus épais et plus lent, qui finit sur un impact : onde, fissures et poussière |
| Coup en croix | deux entailles droites qui se tracent l'une après l'autre, un éclat à leur croisement |
| Épée spirale | une épée — lame, garde, poignée — tangente au cercle, suivie de deux images rémanentes |

La couleur reste celle de la **nature montrée** (`dominant_nature()`) pour ce
qui est de la magie ; l'acier de l'épée et du coup en croix garde sa couleur de
métal, et seule sa traînée prend celle de la nature.

---

## 6. Le contenu

**À relire** : premiers réglages.

### Manuel de la foudre — « Maître de la foudre »

| Case | Forme | Niveau | Ce qui la distingue |
|---|---|---|---|
| Éclair vif | trait | 1 | inchangée |
| **Chaîne d'éclairs** | chaîne, 3 cibles | 3 | le seul sort qui ne peut pas rater une cible visible |
| **Nuage d'orage** | nuage, 3 s, rayon 34 | 5 | tient une zone pendant qu'on se bat ailleurs |
| Nova de foudre | trait, 8 sur 360° | 8 | inchangée |
| Conducteur | passif | 2 | inchangé |

### Manuel des flammes — « Maître des flammes »

| Case | Forme | Niveau | Ce qui la distingue |
|---|---|---|---|
| **Boule de feu** | boule, rayon 20 | 1 | le trait du livre, qui touche aussi les voisins |
| **Serpent infernal** | serpent, 4 s | 4 | des dégâts qu'on lâche et qu'on laisse travailler |
| **Immolation** | aura, rayon 40 | 9 | des dégâts permanents, payés en vie |
| Cœur de braise | passif | 2 | inchangé |

### Manuel du chevalier — « Maître chevalier »

| Case | Forme | Niveau | Ce qui la distingue |
|---|---|---|---|
| Frappe lourde | frappe | 1 | inchangée, dessin neuf |
| **Coup en croix** | croix, 2 coups | 3 | deux touches par geste sur une même cible |
| **Épée spirale** | orbite, 5 s, 3 au plus | 6 | une défense qui frappe en tournant |
| Garde de fer | passif | 2 | inchangé |

### Les arbres neufs

| Compétence | Nœuds |
|---|---|
| Chaîne d'éclairs | **Ramification** +1 cible ×2 · **Haute tension** +12 % dégâts ×3 (enfant) · **Court-circuit** −1 cible, +35 % dégâts |
| Nuage d'orage | **Front orageux** +20 % rayon ×2 · **Orage durable** +25 % durée ×2 (enfant) · **Grêle** convertit 60 % en froid, +15 % dégâts |
| Boule de feu | **Attisement** +13 % dégâts ×3 · **Souffle ardent** +30 % rayon ×2 (enfant) · **Double langue** +1 projectile |
| Serpent infernal | **Longue vie** +25 % durée ×2 · **Crocs** ajoute 4 à 9 dégâts de feu ×2 (enfant) · **Mue** +12 % dégâts ×3 |
| Immolation | **Brasier** +20 % rayon ×2 · **Fournaise** +14 % dégâts ×3 (enfant) · **Flamme noire** convertit 50 % en nécrotique, +15 % dégâts |
| Coup en croix | **Taille** +12 % dégâts ×3 · **Estoc** ajoute 2 à 6 dégâts physiques ×2 (enfant) · **Lame sainte** convertit 50 % en sacré |
| Épée spirale | **Ronde** +1 maximum simultané ×2 · **Tranchant** +12 % dégâts ×3 (enfant) · **Endurance** +30 % durée ×2 |

**Court-circuit** est le pendant d'Éclats au jalon 10 : un point qui fait baisser
un nombre pour en monter un autre.

---

## 7. Ce que la sauvegarde écrit

Rien de neuf, et **pas de version 7** : aucun champ n'entre dans le fichier.

Les identifiants retirés — `salve_d_eclairs`, `fulguration`, `trait_de_feu`,
`gerbe_de_flammes`, `comete`, `lames_tournoyantes` et leurs nœuds — sont écartés
à la relecture par le filtre du jalon 10 (`ManualArchetype.knows`). **Les points
qu'ils portaient reviennent au livre** : `remaining_points()` se déduit de ce qui
est placé, et ce qui n'est plus placé nulle part redevient disponible. Une case
de barre qui les désignait se relit vide.

**Aucun identifiant neuf ne réemploie un ancien.** Donner `lames_tournoyantes` à
l'Épée spirale aurait gardé les points et la case de barre des personnages
existants — mais sur une autre compétence, avec d'autres nœuds, et le joueur se
serait retrouvé avec un sort qu'il n'a pas choisi.

`manual_weapons` garde son identifiant (invariant 1) : seul son nom lisible devient
« Manuel du chevalier », et les livres déjà ramassés changent de nom avec lui.

---

## 8. Les tests

**Le contenu, dans `test_skills.gd` :**

- chaque forme a les nombres dont elle a besoin — une durée et une période pour ce
  qui dure, un rayon pour ce qui couvre une zone, deux cibles au moins pour une
  chaîne, un maximum pour une orbite, une brûlure pour une aura ;
- `projectile` se déduit de la forme et **ne se déclare plus** ;
- la résolution copie les nombres neufs, un nœud les modifie, `finalize()` borne
  les cibles à une et le maximum à un ;
- l'estimation compte les coups d'un lancer : cibles, coups de la forme, frappes
  dans la durée, et « par seconde » seulement pour une aura.

**Les formes, dans `tests/integration/test_shapes.gd`** (neuf) — sur des cibles
posées à la main :

- la chaîne touche trois ennemis alignés et pas le quatrième, ne saute pas plus
  loin que sa portée, et part quand même sans cible ;
- le nuage frappe l'ennemi dessous et pas celui d'à côté, puis disparaît ;
- l'aura s'allume, s'éteint au second lancer sans coûter, **ne clignote pas sous
  la touche tenue**, brûle le personnage moins fort avec de la résistance au feu,
  et s'éteint quand le livre quitte le râtelier ;
- le serpent brûle ce qu'il touche, pas plus d'une fois par période ;
- l'épée spirale refuse la quatrième, sans mana ni recharge, et disparaît après
  sa durée ;
- la croix touche la même cible deux fois ;
- la boule blesse le voisin de sa cible, et la cible une seule fois.

**Ce qui existait** : les tests qui citaient la salve et la fulguration passent
sur la nova, le nuage et la frappe lourde, **sans changer ce qu'ils vérifient**.

---

## 9. Ordre de construction

- [x] **1. La forme.** `Skill.shape`, `projectile` déduit, les nombres neufs
      dans la résolution et l'estimation. Les `.tres` existants reçoivent leur
      forme ; rien ne change en jeu.
- [x] **2. Les formes dans le monde.** `Targets`, puis une forme à la fois dans
      `Player.cast_slot()`, chacune avec son nœud et son dessin.
- [x] **3. Le contenu.** Les sept compétences, leurs arbres, les trois livres
      réécrits, l'anglais, le catalogue régénéré.
- [x] **4. La fiche.** Les lignes des nombres neufs, dans les deux langues.
- [x] **5. Les captures.** Chaque dessin en fenêtré — c'est l'étape qu'aucun test
      ne remplace.
- [x] **6. Les icônes.** Neuf icônes générées par ComfyUI, choisies sur une planche
      où chacune est déjà réduite à 24 px — la recette est dans
      `resources/icons/LISEZMOI.md`.

### Ce que les captures ont changé

**Trois dessins se lisaient comme autre chose.** L'impact de la frappe lourde — un
cercle parfait traversé de fissures droites et régulières — était une **roue à
rayons** : il est maintenant posé au sol, en ellipse qui ne tourne pas avec la
visée, et ses fissures sont brisées et inégales. L'explosion de la boule de feu
était une **flaque brune** : un orange peu opaque, en mélange additif sur le sol
sombre, ne sort pas orange ; le disque plein a disparu au profit d'un cœur chaud
bref. Le serpent, neuf anneaux épais, était une **larve** : il en a douze, plus
fins, un sur deux plus sombre.

**Les fissures et la poussière de l'impact étaient invisibles**, foncées sur un sol
foncé, et les entailles de la croix trop fines : éclaircies, et épaissies.

**La trace d'un coup ne se capture pas en comptant des images** : elle avance au
rythme du rendu, et l'écriture d'un PNG la fait sauter d'un bond. Les captures des
coups fixent donc sa progression à la main.

### Ce que le premier essai a changé

**Le serpent, allongé et épaissi**, sur demande : seize anneaux de 3,8 à 1,4 px au
lieu de douze de 2,8 à 0,9. Les douze anneaux fins, qui avaient remplacé la larve,
se perdaient à l'écran.

**Échap ferme d'abord ce qui est ouvert** — sac, fiche, manuels, établi, menu de
la barre — et n'ouvre le menu de pause que si rien ne l'était. Le jalon 10
l'annonçait déjà pour la page des manuels ; la touche ouvrait en fait le menu
par-dessus. C'est la zone qui décide, dans `_input` : le menu de pause, dernier de
ses enfants, lit la touche avant elle dans `_unhandled_input`.

**L'établi lâche des boules d'expérience**, par une ou par dix, en couronne autour
du joueur. Une boule vaut ce que rapportent cinq grunts de la zone en cours, et se
ramasse en marchant dessus. Elle récompense par `Player.reward()`, le chemin
d'une mort — sorti d'`EnemyManager.report_kill()` pour cela : le retard sur la zone
la fait fondre, et les manuels à l'étude apprennent avec le personnage.

Un premier essai réglait le niveau d'un clic, et reprenait des attributs placés
pour descendre. Il a été retiré sur demande : avec les boules, on monte comme en
jeu, manuels compris, et rien ne se défait.

**La brûlure de l'Immolation a son chiffre**, en rouge au-dessus du personnage
comme un coup reçu. Elle ne passe pas par la `Hurtbox`, et un chiffre par image en
ferait soixante par seconde, chacun à « 0 » : elle s'affiche par paquets d'une
demi-seconde, la période de l'aura.

**Deux cases dans les options** — « Dégâts subis » et « Dégâts infligés » —
coupent les chiffres de chaque côté, esquives comprises, sans toucher à la gerbe
d'éclats : c'est elle qui dit qu'un coup a porté et par quelle nature.

**La brûlure passe par la défense d'un coup reçu.** Elle lisait la résistance de sa
nature dominante par une règle recopiée à côté de la `Hurtbox`. Elle se répartit
maintenant comme les dégâts de l'aura — une Immolation convertie à moitié en
nécrotique brûle à moitié en nécrotique — et chaque part passe par
`CharacterStats.mitigate()`, que la `Hurtbox` appelle aussi : un bonus de
résistance ne peut plus servir contre l'un et oublier l'autre. L'esquive et le
plancher d'un point restent hors de la brûlure, qui n'est pas un coup ; l'armure
s'y compte sur la seconde, et non sur la tranche d'une image où elle annulerait
presque tout.

**Tout point de manuel se reprend**, sur demande, contre le §4 du jalon 10 qui ne
rendait que les points d'arbre. Le clic droit est le pendant du clic gauche : un
point de moins sur une case ou un passif de la grille, sur la racine ou un nœud de
l'arbre. Il ne revient à la grille que dans le vide de l'arbre — sur la racine,
il ramenait à la grille au lieu de reprendre. Une compétence ne descend pas sous
les points que demande un de ses nœuds investis, et retombée à zéro elle sort de
la barre.

### Ce que les tests ont changé

**Un maximum simultané ramené à zéro par un nœud devenait « sans limite ».**
`finalize()` ne pouvait pas le borner — zéro y veut dire les deux choses — et la
borne est passée dans `Skill.resolve()`, qui sait si la compétence en
déclare un.

**Deux tests de mots-clés ne vérifiaient plus rien** : aucune compétence ne
déclare plus de mot-clé depuis que la forme donne `projectile`, et un test qui
parcourt une liste vide n'affirme rien. Ils comptent maintenant leurs fautes.

**Grêle convertit 60 % et non 50 %** : à égalité, la nature montrée reste celle
d'origine, et le nuage converti se serait dessiné en violet.

---

## 10. Ce qui peut mal tourner

**Le nuage qui fige le jeu.** Voir §4 : ce qui dure n'appelle jamais
`Game.hit_stop()`. Un test le garde.

**L'aura qui survit à son livre.** Elle se résout à chaque impulsion : sans
points, elle s'éteint. L'oublier laisserait une aura brûler le joueur au nom
d'une compétence qu'il ne connaît plus.

**La requête depuis un rappel de collision.** L'espace physique est verrouillé
pendant `area_entered` : l'explosion interrogée à cet endroit rendrait une erreur
et aucun dégât. D'où l'explosion différée, et le test qui la regarde toucher.

**La hitbox rouverte trop vite.** `set_deferred("monitoring", false)` puis `true`
dans la même image ne coupe rien, et le second coup en croix ne toucherait
personne : les ennemis déjà dans la zone n'y *entrent* pas une seconde fois. La
croix attend donc une image de physique entre ses deux coups.

**Le serpent qui s'enfuit.** Un cap tiré au hasard sans rappel l'emmène hors de
l'écran en quatre secondes. D'où la laisse de 44 px, et le test qui vérifie
qu'il reste près de son point de chute.
