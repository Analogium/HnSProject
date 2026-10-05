# Hack'n'slash top-down — jalon 42

Suite des jalons 1 à 41. Ce document ne redit pas ce qui y est déjà écrit, et
`docs/ARCHITECTURE.md` reste le seul endroit qui décrit l'état courant.

**Ouvert le 5 octobre 2026.** Les arbres des **manuels non uniques** — flammes, foudre,
froid — repris un manuel à la fois, en commençant par les flammes.

---

## 1. Ce que l'utilisateur a demandé

« Développer encore plus le nombre de nœuds des manuels, dans un nouveau jalon qui doit
couvrir tous les manuels non uniques, manuel par manuel, en commençant par celui des
flammes. » À retenir pour chacun :

- **un peu plus de nœuds** par compétence ;
- des nœuds **reviennent d'une compétence à l'autre** : en changer, sinon l'originalité
  d'une compétence ne se voit pas ;
- **chaque compétence a ses nœuds originaux**, comme dans Last Epoch — mécanique neuve,
  transformation, effet neuf ;
- quelques nœuds d'**interaction avec une autre compétence** (rarement d'un autre
  manuel) — sans que ça devienne une habitude : le mot d'ordre est l'originalité ;
- quelques nœuds **simples et génériques** restent normaux.

Sur la première proposition : « c'est pas mal mais j'aimerais un peu plus » — des
**nœuds-suites**, reliés au nœud qu'ils prolongent et à lui seul. « Un nœud après Météore
qui ferait lâcher des mini-météorites : il n'a de sens et d'effet que si l'on prend
Météore. » Un autre chemin n'est admis que si la suite a aussi du sens par lui. Pour les
idées : Last Epoch, mais aussi PoE, Hero Siege, Torchlight Infinite, Reddit.

## 2. La règle du jalon

Les trois manuels entrent dans `UNIQUE_TREES` au fur et à mesure : **aucun nom ni aucune
ligne ne revient d'un arbre à l'autre** d'un même manuel, sauf un nœud de dégâts, de
rayon et de durée par arbre (jalons 38 à 41). Une fois le froid fini, tous les manuels y
sont et la constante disparaît : la règle devient celle de tous les arbres.

**Un échange n'est pas un second levier.** Le test ne l'exempte aujourd'hui que ligne par
ligne : Pouls lent (−50 % de cadence ⇄ +60 % plus) compterait comme un second nœud de
dégâts. Il exemptera le nœud entier dès qu'une de ses lignes est une perte
(`StatMod.is_loss()`), ce que dit déjà son commentaire.

**Les suites (↳).** Une suite n'a qu'un parent : le nœud qui change le jeu et qu'elle
prolonge. Le moteur le permet déjà (`TalentNode.parents`, un seul suffit). Un test
vérifiera qu'une suite ne lit que des nombres que la forme ou la mécanique de son parent
lit — une suite de Météore sans Météore ne ferait rien, et c'est précisément pourquoi elle
ne doit être accessible que par lui.

**Cible** : 13 à 21 nœuds par compétence (9 à 12 aujourd'hui), 30 à 43 points offerts pour
un pool de 20. Dans chaque arbre : quelques leviers simples, les mécaniques gardées, **deux
à quatre nœuds que seule cette compétence a**, et **une à deux suites** derrière chaque
nœud qui change le jeu. Une interaction entre compétences dans **deux arbres sur cinq** au
plus par manuel.

Inspirations relevées : dans Last Epoch, le *Concentrated* qui troque la zone contre la
touche directe, le *Flamethrower* qui change le geste, les nœuds de Flame Rush qui lancent
une autre compétence à l'arrivée (*Magma Starter*) ou se combinent avec un sort d'une
autre école (*Gas Powered*, avec Frost Wall) ; dans Hero Siege, *IGNITE THE FLAMES!*, des
charges d'ignition qui éclatent en pulsation au maximum ; dans PoE, l'Incinerate qui monte
tant qu'on le tient.

## 3. Le manuel des flammes — la proposition

### Ce qui se répète aujourd'hui

| ligne | arbres qui la portent | où elle reste |
|---|---|---|
| Étincelles (chance d'état) | Boule de feu, Immolation, Ruée ardente | **Boule de feu** — la Réaction en chaîne en a besoin |
| sol brûlant | Boule de feu, Serpent, Immolation | **Serpent** — la Queue de flammes est son sillage |
| explosion des tués | Boule de feu, Immolation | **Boule de feu** |
| explosion finale | Serpent, Ruée ardente | **Ruée ardente** — l'Atterrissage |
| brûlure subie | Immolation, Ignition | **Immolation** — se brûler pour brûler, c'est elle |
| +1 projectile ⇄ / +1 serpent ⇄ | Boule de feu, Serpent | les deux : deux statistiques distinctes (`projectiles`, `brood`) |

Conventions des jalons précédents : chiffres de **premier réglage**, « relié à (n) » =
points demandés dans le parent, ⇄ marque un échange. **Neuf** = un nombre de `SkillStats`
à écrire ; 🔗 = interaction avec une autre compétence ; **↳** = suite, accessible par son
seul parent.

### Boule de feu — l'artillerie *(12 → 21 nœuds, 43 points)*

| nœud | pts | effet | relié à |
|---|---|---|---|
| Attisement *(gardé)* | 4 | +8 % dégâts plus | — |
| Souffle ardent *(gardé)* | 3 | +15 % rayon de l'explosion | — |
| Vélocité *(gardé)* | 2 | +20 % vitesse de projectile | — |
| Ardeur *(gardé)* | 2 | +25 % chance critique | Attisement (2) |
| Étincelles *(gardé)* | 3 | +15 % chance d'état | Souffle ardent (1) ou Ardeur (1) |
| Double langue *(gardé)* | 2 | +1 boule en éventail ⇄ −10 % plus | Vélocité (2) |
| Perforation *(gardé)* | 2 | traverse un ennemi de plus | Vélocité (1) |
| Fragmentation *(gardé)* | 3 | éclate en petites boules | Perforation (1) ou Double langue (1) |
| Réaction en chaîne *(gardé)* | 1 | un embrasé tué explose, en chaîne | Étincelles (3) |
| Givre *(gardé)* | 1 | conversion au froid | Ardeur (1) |
| Météore *(gardé)* | 1 | transformation : tombe du ciel | Attisement (3) ou Double langue (1) |
| **Noyau dense** | 1 | **la boule n'explose presque plus** : −75 % rayon ⇄ +50 % dégâts plus — la touche directe contre la zone | Attisement (2) |
| **Prise d'air** *(neuf)* | 3 | **la boule enfle en volant** : son explosion gagne 10 % de rayon et de dégâts par point, par 100 px parcourus — tirer de loin | Vélocité (1) |
| **Surchauffe** *(neuf)* | 3 | **une explosion surchauffe ce qu'elle touche pendant 3 s** : la boule suivante l'y frappe 8 % plus fort par point, jusqu'à trois fois — marteler une cible | Noyau dense (1) ou Ardeur (1) |
| **Feu nourri** 🔗 *(neuf)* | 2 | **une boule lancée pendant que votre Immolation brûle sort attisée du brasier** : +15 % dégâts plus et +15 % rayon par point | Souffle ardent (2) |
| ↳ **Pluie de météorites** *(neuf)* | 3 | **après l'impact, une mini-météorite par point retombe autour du point visé**, 0,3 s plus tard, à 30 % des dégâts et un tiers du rayon | Météore (1) |
| ↳ **Chute libre** | 1 | le météore tombe aussitôt : **le geste n'est plus allongé** | Météore (1) |
| ↳ **Givre profond** | 3 | la boule de glace transit plus fort : +15 % effet du transi par point (`chill_effect`) | Givre (1) |
| ↳ **Éclats en cascade** *(neuf)* | 1 | **les éclats éclatent à leur tour**, une fois, à moitié de leur force | Fragmentation (2) |
| ↳ **Poudrière** *(neuf)* | 1 | **l'explosion d'un tué pose à coup sûr l'état de la boule** sur ce qu'elle touche — la chaîne ne s'arrête plus faute d'embrasés | Réaction en chaîne (1) |
| ↳ **Convergence** *(neuf)* | 1 | **les boules ne partent plus en éventail : elles se rejoignent au point visé**, où une même cible les prend toutes | Double langue (1) |

*Retiré* : Braises dispersées (le sol va au Serpent).

### Serpent infernal — le chasseur *(10 → 20 nœuds, 38 points)*

| nœud | pts | effet | relié à |
|---|---|---|---|
| Mue *(gardé)* | 4 | +8 % dégâts plus | — |
| Longue vie *(gardé)* | 3 | +20 % durée | — |
| Crocs *(gardé)* | 2 | ajoute 4 à 9 dégâts de feu | — |
| Sifflement | 3 | −8 % temps du geste | — |
| Vif *(gardé)* | 2 | rampe plus vite ⇄ vit moins | Longue vie (1) ou Mue (1) |
| Queue de flammes *(gardé)* | 3 | sillon de sol brûlant — **le seul sol du manuel** | Longue vie (1) ou Chasseur (1) |
| Chasseur *(gardé)* | 1 | suit l'ennemi le plus proche | Crocs (1) |
| Couvée *(gardé)* | 2 | +1 serpent ⇄ −15 % plus (la limite de trois tient) | Mue (2) |
| Hydre *(gardé)* | 1 | des petits à sa mort | Couvée (2) ou Gloutonnerie (2) |
| Venin *(gardé)* | 1 | conversion au nécrotique | Crocs (2) |
| **Gloutonnerie** *(neuf)* | 3 | **chaque ennemi que le serpent tue le fait grossir** : +5 % dégâts plus par point et +0,5 s de vie par proie, cinq proies au plus — il grandit à l'écran (`HellSnake._size`, jalon 41) | Mue (1) |
| **Constriction** *(neuf)* | 1 | **le serpent s'enroule autour du premier ennemi qu'il mord** et ne le lâche plus : il cesse de ramper et mord deux fois plus vite jusqu'à sa mort, puis repart | Chasseur (1) |
| **Ouroboros** *(neuf)* | 1 | **le serpent se mord la queue** : il tourne en rond autour du point où il tombe, sans chasser ; avec la Queue de flammes, il trace un anneau de feu ⇄ le Chasseur ne sert plus | Queue de flammes (2) |
| **Crachat** *(neuf)* | 2 | **toutes les 1,5 s, le serpent crache une petite boule de feu** vers l'ennemi le plus proche à 100 px : 30 % d'une morsure par point | Vif (1) ou Sifflement (1) |
| ↳ **Spirale** *(neuf)* | 1 | **l'anneau se resserre en tournant** : de son rayon à son centre sur la vie du serpent, en rabattant les ennemis vers le milieu | Ouroboros (1) |
| ↳ **Étau** *(neuf)* | 1 | **l'ennemi enlacé ne bouge plus** et n'attaque plus tant que le serpent le tient | Constriction (1) |
| ↳ **Mue de croissance** *(neuf)* | 1 | **à la cinquième proie, le serpent mue** : il éclate en une gerbe de feu autour de lui, reprend sa taille et sa vie entière, et recommence à grossir | Gloutonnerie (3) |
| ↳ **Gerbe** *(neuf)* | 2 | le crachat part en éventail : **+1 boule par point** | Crachat (1) |
| ↳ **Venin d'hydre** | 2 | les petits de l'Hydre vivent 0,5 s de plus et mordent 15 % plus fort, par point | Hydre (1) |
| ↳ **Morsure nécrosante** *(neuf)* | 2 | chaque morsure sur un pourrissant **prolonge sa pourriture** de 0,5 s par point | Venin (1) |

*Retiré* : Mue explosive (l'explosion finale va à la Ruée).

### Immolation — le bûcher *(9 → 17 nœuds, 43 points)*

| nœud | pts | effet | relié à |
|---|---|---|---|
| Fournaise *(gardé)* | 5 | +8 % dégâts plus | — |
| Brasier *(gardé)* | 4 | +15 % rayon | — |
| Cœur tiède *(gardé)* | 3 | −20 % brûlure subie | — |
| Pouls lent *(gardé)* | 2 | frappe moins souvent, bien plus fort | Fournaise (2) |
| Phénix *(gardé)* | 1 | brûle deux fois plus ⇄ +40 % plus | Cœur tiède (2) |
| Flamme noire *(gardé)* | 1 | conversion au nécrotique | Pouls lent (1) |
| **Brûlure profonde** *(neuf)* | 4 | **force de l'embrasement** posé par le brasier : +15 % par point — le dernier état sans force | Fournaise (1) |
| **Tirage** | 3 | **le brasier aspire l'air** : chaque impulsion attire les ennemis vers vous (`pull`, déjà lu par `Targets.strike_circle`) | Brasier (1) |
| **Feu de camp** *(neuf)* | 3 | **immobile, le brasier monte** : +6 % de dégâts plus et +5 % de rayon par point et par seconde sans bouger, trois secondes au plus ; il retombe dès que vous marchez | Brasier (2) ou Pouls lent (1) |
| **Escarbilles** *(neuf)* | 3 | **à chaque impulsion, une escarbille par point jaillit vers un ennemi hors du cercle**, jusqu'à deux fois le rayon : 40 % d'une impulsion — les braises que l'aura dessine déjà | Brasier (1) ou Tirage (1) |
| **Offrandes** *(neuf)* | 3 | chaque ennemi tué par le brasier rend 1 mana par point | Cœur tiède (1) |
| ↳ **Fonte** *(neuf)* | 3 | **l'embrasement du brasier fait fondre les défenses** : l'embrasé perd 5 résistance au feu par point, comme le maudit perd du nécrotique (`resistance_lost()`) | Brûlure profonde (2) |
| ↳ **Renaissance** *(neuf)* | 1 | **une fois par minute, un coup fatal vous laisse à 1 PV** et le brasier explose de toute sa force, deux fois son rayon | Phénix (1) |
| ↳↳ **Cendres du phénix** *(neuf)* | 1 | après une renaissance, **4 s sans brûlure subie et +50 % dégâts plus** | Renaissance (1) |
| ↳ **Veillée** *(neuf)* | 2 | **à pleine montée du feu de camp**, vous regagnez 1 % de vos PV par seconde et par point | Feu de camp (3) |
| ↳ **Œil du brasier** *(neuf)* | 2 | les ennemis **dans le tiers central** du cercle prennent 12 % de dégâts plus par point — là où le Tirage les amène | Tirage (2) |
| ↳ **Âmes consumées** *(neuf)* | 2 | le brasier nécrotique **soigne** : chaque ennemi qu'il tue rend 1 % de vos PV max par point | Flamme noire (1) |

*Retirés* : Étincelles (Boule de feu), Cendres vivantes (le sol va au Serpent),
Contagion ardente (l'explosion des tués va à la Boule de feu).

### Ruée ardente — la traînée *(10 → 17 nœuds, 35 points)*

| nœud | pts | effet | relié à |
|---|---|---|---|
| Bûcher *(gardé)* | 4 | +8 % dégâts plus | — |
| Sillage *(gardé)* | 3 | +25 % durée de la traînée | — |
| Élan *(gardé)* | 2 | −10 % recharge | — |
| Braises *(gardé)* | 3 | +20 % rayon de la traînée | Sillage (1) |
| Brûle-pavé *(gardé)* | 2 | la traînée dure bien plus ⇄ brûle moins fort | Sillage (1) ou Bûcher (1) |
| Tison *(gardé)* | 2 | +12 % dégâts contre les embrasés | Bûcher (2) |
| Atterrissage *(gardé)* | 3 | explosion à l'arrivée — **la seule explosion finale du manuel** | Élan (1) |
| Onde de choc *(gardé)* | 2 | l'explosion d'arrivée s'élargit | Atterrissage (2) |
| Bond *(gardé)* | 1 | transformation : un saut | Atterrissage (1) ou Élan (2) |
| **Départ en trombe** *(neuf)* | 2 | **l'explosion d'arrivée éclate aussi là d'où vous partez**, à 35 % de sa force par point | Atterrissage (1) |
| **Mèche** *(neuf)* | 3 | **quand la traînée s'éteint, elle s'embrase d'un bout à l'autre** : une flamme court de votre départ à votre arrivée et chaque plaque explose à son passage, 50 % d'une impulsion par point | Brûle-pavé (1) ou Tison (1) |
| **Seconde foulée** *(neuf)* | 1 | **dans la seconde et demie qui suit une ruée, la relancer est gratuit** et ne relance pas la recharge — une fois | Élan (2) |
| **Charmeur** 🔗 *(neuf)* | 1 | **à l'arrivée, un Serpent infernal surgit des flammes**, si vous savez le lancer : avec vos points et votre arbre du serpent, sans coût, compté dans la limite de trois | Atterrissage (2) |
| ↳ **Onde brûlante** *(neuf)* | 2 | **l'atterrissage du bond projette un anneau de flammes** qui s'étend jusqu'à deux fois son rayon, 40 % des dégâts par point (l'anneau de `FrostRing`) | Bond (1) |
| ↳ **Mèche courte** | 1 | la mèche s'allume **dès votre arrivée** au lieu d'attendre l'extinction ⇄ la traînée disparaît avec elle | Mèche (1) |
| ↳ **Danse du charmeur** *(neuf)* | 1 | à l'arrivée, **vos serpents déjà en jeu se ruent vers vous** et chassent autour de votre point d'arrivée | Charmeur (1) |
| ↳ **Foulée de feu** | 2 | la seconde ruée, celle qui est gratuite, laisse une traînée 20 % plus forte par point | Seconde foulée (1) |

*Retiré* : Étincelles (Boule de feu).

### Ignition — la combustion *(9 → 15 nœuds, 33 points)*

La Combustion garde ses lignes ; les nœuds de buff s'y ajoutent tant qu'elle brûle. Elle
perd la brûlure subie, qui va à l'Immolation : son prix se gère autrement.

| nœud | pts | effet | relié à |
|---|---|---|---|
| Braise vive *(gardé)* | 4 | +6 % dégâts de feu accrus (buff) | — |
| Allure *(gardé)* | 3 | +4 % vitesse de déplacement (buff) | — |
| **Combustible** *(neuf)* | 3 | **la combustion brûle votre mana avant votre vie** : 20 % par point de sa brûlure payée en mana tant qu'il en reste | — |
| Brasier intérieur *(gardé)* | 3 | +8 chance d'embraser (buff) | Braise vive (2) |
| Peau de braise *(gardé)* | 2 | +8 résistance au feu (buff) | Combustible (1) ou Braise vive (1) |
| Emballement *(gardé)* | 2 | +4 % vitesse d'incantation (buff) | Allure (1) |
| Cendres fertiles *(gardé)* | 2 | +1,5 PV/s (buff) | Combustible (1) ou Allure (1) |
| **Corps-torche** | 1 | **+30 % dégâts de feu ⇄ −30 résistance au feu** : la combustion vous brûle en feu, elle mord d'autant plus — remplace Feu dévorant | Brasier intérieur (1) ou Peau de braise (1) |
| Holocauste *(gardé)* | 1 | +20 % dégâts de feu plus (buff) | Corps-torche (1) ou Brasier intérieur (3) |
| **Toucher brûlant** *(neuf)* | 2 | **un ennemi qui vous frappe au corps à corps s'embrase**, 50 % de chance par point | Peau de braise (1) |
| **Point d'éclair** *(neuf)* | 3 | **tant que la combustion brûle, chaque coup de feu dépose une charge sur l'ennemi** ; à la huitième, il éclate en une pulsation de feu autour de lui, 2 % de ses PV max par point (Hero Siege) | Brasier intérieur (1) |
| **Embrasement final** *(neuf)* | 2 | **quand la combustion s'éteint, vous explosez** : 25 % par point de la vie qu'elle vous a brûlée, en feu, autour de vous | Combustible (2) |
| ↳ **Étincelle jumelle** *(neuf)* | 1 | la pulsation du point d'éclair **dépose deux charges** sur ce qu'elle touche — les éclats s'enchaînent dans la meute | Point d'éclair (2) |
| ↳ **Feu bleu** *(neuf)* | 2 | tant que la combustion se paie en mana, **+8 % dégâts de feu plus par point** | Combustible (2) |
| ↳ **Brasier contenu** *(neuf)* | 2 | plus la combustion a duré, plus l'explosion finale est large : **+4 px par seconde allumée et par point**, 20 s au plus | Embrasement final (1) |

*Retirés* : Cendres froides, Feu dévorant (la brûlure subie va à l'Immolation).

### Récapitulatif

- **51 → 90 nœuds**, dont **25 suites** ; ~35 nombres neufs dans `SkillStats`. Deux
  interactions (Feu nourri, Charmeur et sa Danse), dans deux arbres sur cinq. Pas
  d'interaction avec un autre manuel ici : elle viendra plus naturellement de la foudre
  ou du froid.
- **L'embrasement prend une force** (`ignite_effect`, Brûlure profonde) : avec la Fonte,
  l'Immolation devient l'arbre de l'embrasement, comme la Boule de feu est celui de la
  zone et la Ruée celui du terrain.
- **Dessin** : la mini-météorite, l'escarbille en vol, le crachat et la charge du point
  d'éclair passent par `/dessiner-un-effet`. Le serpent qui grossit réutilise son échelle ;
  la Mèche, le Départ et la Mue de croissance réutilisent `Explosion` ; l'Onde brûlante
  l'anneau de `FrostRing`.
- **La page de l'arbre** : 21 nœuds tiennent-ils dans la grille autour de la compétence ?
  À vérifier sur capture avant d'écrire les positions — c'est elle qui décide si une suite
  pousse l'arbre au-delà de ±3 cases.
- **Livraison en deux temps** si la taille l'exige : les nœuds sans nombre neuf
  d'abord (réorganisation, leviers, suites de nombres existants), puis les mécaniques
  arbre par arbre, chacune avec son test.
- **`docs/ARBRES.md` se régénère** ; les couloirs d'équilibrage se relèvent avant →
  après, sans les corriger (jalon 13, §7).

## 4. La lecture de l'arbre — livrée

L'utilisateur : « séparer visuellement les nœuds basiques des nœuds qui transforment
fondamentalement le gameplay, ainsi que leur suite ». Jusqu'ici tous les nœuds étaient le
même carré de 28 px ; seule une pastille de 2 px dans un coin marquait une mécanique.

**Choisi sur planche** (`hns-captures-arbre-noeuds/planche-noeuds.png`, l'arbre proposé de la
Boule de feu, six variantes : l'actuel, tailles, **losanges**, double liseré, fond teinté,
octogones) : la **3**.

- nœud de nombres : **petit carré** (22 px) ;
- ce qui change le jeu : **grand losange** (rayon 15), pastille de sa sorte à la pointe ;
- suite : **petit losange** (rayon 11), relié par un **tireté** de la couleur de ce qu'elle
  prolonge, assombri tant qu'elle n'est pas prise.

Le liseré garde l'état (verrouillé, ouvert, plein) : la sorte passe par la silhouette, pas
par la couleur du contour. **Une suite se déduit des liens** (`ManualCell.is_suite()`) : tous
ses parents changent le jeu ou en sont une. Rien à déclarer dans les `.tres`, et la règle
des suites du §2 se lira sur la page sans qu'on l'écrive deux fois.

**La grille passe à ±3 × ±2** (`TREE_SPAN`) : à ±1, vingt places pour les vingt et un nœuds
de la Boule de feu. La page n'offre que **164 px** entre l'en-tête et l'aide ; cinq rangées
à 44 px en demandaient 204. D'où **32 px entre deux rangées** et les silhouettes plus petites
que sur la planche (24 / 18 / 13 px).

**Vu à la capture** (`1-arbre-boule-de-feu`, `2-arbre-ruee-ardente`) : à 2 px, le tireté
d'une suite se confondait avec les grains « ••• » des points demandés au parent ; à 4 px
(`SUITE_DASH`), il s'en distingue. Le test des liens qui passent sous un nœud mesure
désormais contre la silhouette dessinée — carré sur l'axe le plus lâche, losange en somme
des deux —, plus contre le carré de survol.
