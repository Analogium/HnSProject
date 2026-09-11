# Hack'n'slash top-down — jalon 9

Suite de `hack-n-slash-jalon-1.md`, qui reste la référence sur l'architecture et
les conventions, et des jalons 2 à 8. Ce document ne redit pas ce qui y est déjà
écrit, et `docs/ARCHITECTURE.md` reste le seul endroit qui décrit l'état courant.

**Décidé le 11 septembre 2026.** Le jeu parle français, et seulement français :
chaque texte affiché est écrit en dur là où il est dessiné, dans une scène ou dans
un `.tres`. Il n'existe ni `tr()`, ni fichier de traduction, ni réglage de langue.

Ce jalon ajoute **l'anglais**, et le moyen de passer de l'un à l'autre.

---

## 1. Périmètre du jalon 9

**Dedans :**

- **Tout ce qu'un joueur lit** : l'écran des personnages, le menu pause et ses
  options, le HUD, la barre et son menu, le sac et l'infobulle d'un objet, la
  fiche de personnage et ses explications, le manuel et sa fiche de compétence,
  les nombres et libellés qui s'envolent, les noms d'affixes au-dessus des
  ennemis, le témoin de sauvegarde
- **Le contenu** : les noms des objets, des compétences, du manuel et des affixes
  d'élite ; les libellés des statistiques, des natures, des mots-clés et des
  emplacements
- **Le choix de la langue**, retenu dans `reglages.json`, dans les Options du menu
  pause **et** sur l'écran des personnages (décidé le 11 septembre, sur demande)
- **Au premier lancement, la langue du système** : français si Windows est en
  français, anglais pour toute autre langue (décidé le 11 septembre, sur demande)
- **Le changement à chaud** : changer de langue en pleine partie redessine tout ce
  qui est ouvert, sans recharger la zone

**Dehors :**

- **Les outils de développement restent en français** (décidé le 11 septembre, sur
  demande) : la forge (`F4`), l'arène (`F2`), le réglage de génération (`F3`), le
  banc (`F6`), l'établi (`B`) et le bandeau d'aide et de débogage de la zone
  (`H`). `docs/CATALOGUE.md` aussi.
- **Le code** : identifiants, commentaires et documentation restent en français,
  comme depuis le jalon 3.
- **La console** : `push_warning` et `push_error` s'adressent à qui lit la
  console, pas au joueur.
- **Les sauvegardes** : elles n'écrivent aucun texte affiché — des identifiants,
  des nombres, et une date ISO (`joue_le`). Rien à convertir, pas de version 6.
- **Une troisième langue.** Le mécanisme la permettra, mais ce jalon n'en livre
  que deux, et c'est à deux qu'on vérifie que tout tient.

---

## 2. Le principe : le texte français est la clé

**Le code continue d'écrire ses textes en français**, et les enveloppe dans `tr()`
au moment de les afficher : `tr("Reprendre")`. Le français est la langue source ;
il n'a pas de fichier de traduction. **L'anglais vit dans un seul fichier,
`i18n/en.po`**, qui associe chaque texte français à sa version anglaise.

C'est la façon de faire de gettext, et Godot la lit nativement. L'autre solution
— des clés abstraites, `tr("MENU_REPRENDRE")`, et un fichier par langue — a été
écartée : le code de ce projet se lit en français, ses commentaires citent les
textes qu'il affiche, et une clé abstraite obligerait à ouvrir un fichier de plus
pour savoir ce que dit un bouton.

**Un `.po` et non un `.csv`** : le `.po` porte les **pluriels** (« 1 point à
placer », « 3 points à placer ») et les **contextes** — le jour où un même mot
français aura deux traductions. Il s'édite à la main ou avec Poedit.

Le prix de ce choix : **modifier un texte français casse sa traduction en
silence**. L'anglais retombe alors sur le français, sans erreur. C'est le rôle
des tests de complétude du §6, et c'est la première chose du §9.

---

## 3. Choisir la langue

**Un réglage de plus dans `Settings`** : `langue`, « fr » ou « en », écrit dans
`reglages.json` sous la clé `langue`. Le poser appelle
`TranslationServer.set_locale()`, émet `changed` et écrit le fichier, comme les
autres réglages.

**Au premier lancement**, sans fichier de réglages, `Settings` lit la locale que
Godot a posée — celle du système, ou celle de la ligne de commande — et **la
ramène à « fr » ou « en »** : tout ce qui commence par `fr` donne le français,
tout le reste l'anglais. Sans cette étape, un Windows en allemand ne trouverait
aucune traduction allemande, et Godot afficherait… la clé, c'est-à-dire le
français.

**À l'écran**, un bouton qui tourne, comme celui de la fenêtre : « Langue :
Français » / « Language: English ». Il est dans les Options du menu pause, et sur
l'écran des personnages. Le libellé d'une langue s'écrit **dans cette langue**, et
pas traduit : un joueur perdu dans une langue qu'il ne lit pas doit reconnaître la
sienne.

**Le changement à chaud.** Godot envoie `NOTIFICATION_TRANSLATION_CHANGED` à tous
les nœuds quand la locale change. Les `Label` et `Button` des scènes se retraduisent
seuls. Les panneaux dessinés à la main doivent **redessiner** en la recevant, et
ceux qui **mesurent un texte une fois pour toutes** doivent le re-mesurer :
`AffixTag` (les noms d'affixes au-dessus des ennemis), le titre du sac, celui de la
fiche de personnage. Les nombres qui s'envolent vivent six dixièmes de seconde :
ils finissent dans leur langue.

---

## 4. Ce qui se traduit, et où

**Les tables de libellés gardent leurs valeurs françaises**, et c'est leur
**lecture** qui passe par `tr()` : `StatMod.LABELS`, `StatsDeCompetence.LABELS`,
`DamageType.NAMES` et `LIBELLES_DE_DEGATS`, `MotsCles.LIBELLES` et
`DESTINATAIRES`, les libellés d'`EquipmentSlots`, les titres de groupes de la
fiche. Chaque table a déjà une fonction de lecture (`StatMod.nom()`,
`MotsCles.libelle()`, `EquipmentSlots.label()`…) : le `tr()` va **là, et nulle part
ailleurs**.

**Le contenu passe par un accesseur.** `display_name` et `nom` restent les champs
français des `.tres` ; ce qu'on affiche passe par `Item.display_name()` et par un
`nom_affiche()` sur `Competence`, `ManuelArchetype` et `Affix`. Un `competence.nom`
lu directement dans une interface est un texte qui ne se traduira jamais.

**Les explications de `StatHelp` deviennent des gabarits.** Elles sont aujourd'hui
formatées **dans la constante** — « Chaque point donne 6 points de vie » — et la
clé contiendrait donc le nombre : le jour où la règle change, la traduction casse.
Elles gardent leurs `%` et sont formatées à la lecture.

**Une phrase se traduit entière, jamais par morceaux.** « ajoute 3 à 7 dégâts de
froid aux sorts » ne se construit plus en collant « ajoute », « à », « dégâts de
froid » et « aux sorts » : l'ordre des mots n'est pas le même en anglais, et un
traducteur ne peut rien faire d'un morceau. Dès qu'un gabarit porte **deux valeurs
ou plus**, elles sont **nommées** : `tr("ajoute {bas} à {haut} {degats}")`. Les
fragments qui restent composés — la nature d'une ligne, sa famille — sont des
groupes nominaux entiers (« dégâts de froid », « aux sorts »), qui se traduisent
d'un bloc.

**La typographie suit la langue** : « 20 % » en français, « 20% » en anglais ;
les guillemets « » deviennent " ". Le format des pourcentages de
`StatMod.format()` est donc lui-même un texte traduit.

**Ce qui ne se traduit pas** : les nombres, les noms de touches que le système
fournit (`OS.get_keycode_string`), les noms de personnages. « clic G » et « clic
D », eux, sont écrits par le jeu : « LMB », « RMB ».

**Le mot à taper pour supprimer un personnage** (« SUPPRIMER ») se traduit
(« DELETE ») : la consigne et le mot attendu viennent **de la même clé**, sinon
l'écran demanderait de taper un mot que la vérification refuse.

---

## 5. Les noms anglais proposés

**À relire** : ce sont des propositions. Anglais américain (« Armor », « Scepter »).

| Français | Anglais |
|---|---|
| **Armes** | |
| Épée · Épée large · Lame de guerre | Sword · Broadsword · War Blade |
| Dague · Miséricorde | Dagger · Misericorde |
| Masse · Masse d'armes · Marteau de guerre | Mace · Battle Mace · War Hammer |
| Baguette · Sceptre · Sceptre runique | Wand · Scepter · Runic Scepter |
| **Main gauche** | |
| Bouclier · Écu · Pavois | Shield · Kite Shield · Pavise |
| Grimoire · Codex | Grimoire · Codex |
| **Armures** | |
| Casque · Armet · Heaume | Helmet · Armet · Great Helm |
| Capuche · Capuche de maître | Hood · Master's Hood |
| Tunique · Justaucorps | Tunic · Jerkin |
| Plastron · Cotte de mailles · Harnois | Breastplate · Chainmail · Full Plate |
| Gants · Gants renforcés · Gants de maître | Gloves · Reinforced Gloves · Master's Gloves |
| Bottes · Bottes cloutées · Bottes de marche | Boots · Studded Boots · Travel Boots |
| Ceinture · Ceinturon · Baudrier | Belt · Girdle · Baldric |
| **Bijoux** | |
| Anneau · Chevalière · Bague ouvragée | Ring · Signet Ring · Ornate Ring |
| Amulette · Pendentif · Talisman | Amulet · Pendant · Talisman |
| **Manuel et compétences** | |
| Manuel de la foudre · Maître de la foudre | Manual of Lightning · Master of Lightning |
| Attaque · Trait | Attack · Bolt |
| Éclair vif · Salve d'éclairs · Fulguration · Nova de foudre | Swift Bolt · Bolt Volley · Fulmination · Lightning Nova |
| **Affixes d'élite** | |
| Blindé · Brutal · Colossal · Véloce · Vorace | Armored · Brutal · Colossal · Swift · Ravenous |
| **Natures** | |
| physique · froid · feu · foudre · nécrotique · sacré | physical · cold · fire · lightning · necrotic · holy |
| **Mots-clés** | |
| Projectile · Foudre · Sort · Attaque | Projectile · Lightning · Spell · Attack |
| **Emplacements** | |
| ARME · MAIN G. · CASQUE · TORSE · GANTS | WEAPON · OFF-HAND · HELMET · CHEST · GLOVES |
| BOTTES · CEINTURE · AMULETTE · BAGUE G. · BAGUE D. | BOOTS · BELT · AMULET · RING L. · RING R. |

---

## 6. Les tests

**La campagne tourne en français, quelle que soit la machine.** `tests/run.sh` et
`tools/catalogue.sh` lancent Godot avec `--language fr` : les tests affirment des
textes français, et le catalogue est un document français. Sans ça, la campagne
échouerait sur un Windows anglais, et le catalogue s'y régénérerait en anglais.
Un test qui passe à l'anglais **remet le français avant de rendre la main**.

**La complétude**, la garde du §2 :

- **chaque texte traduisible a son anglais** : les valeurs des tables du §4, les
  noms de tout le contenu, les textes des scènes vues par le joueur, et chaque
  littéral `tr("…")` des scripts qui dessinent pour le joueur — relevé en lisant
  les sources, comme `test_atelier` lit la scène de zone ;
- **aucune traduction orpheline** : un texte de `en.po` que plus rien n'affiche
  est un texte français qui a changé, et dont la nouvelle version n'est plus
  traduite ;
- **les gabarits gardent leurs valeurs** : chaque `%d`, `%s` et `{nom}` d'un
  texte français se retrouve dans son anglais, ni plus ni moins.

**Le filet** : en anglais, les lignes que produisent la fiche de compétence, la
fiche de personnage, le menu de la barre et l'infobulle ne contiennent **aucune
lettre accentuée**. Il n'attrape pas tout — « recharge » s'écrit pareil dans les
deux langues —, mais un `tr()` oublié sur un texte français s'y voit presque
toujours.

**La largeur** : ce qui est dessiné dans une largeur fixe tient **dans les deux
langues**, mesuré avec la police du jeu — la fiche de compétence (170 px), les
lignes de la fiche de personnage, les entrées du menu de la barre, les libellés
d'emplacements du sac. « si tout touche, avant défenses » devient « if everything
hits, before defenses » : plus long.

---

## 7. Ordre de construction

Chaque étape se valide avec `tests/run.sh` avant la suivante. La première ne
change **aucun texte** du jeu.

- [x] **1. La mécanique.** `i18n/en.po` avec son en-tête et ses règles de pluriel,
      déclaré dans `project.godot` ; `Settings.langue`, sa lecture, son écriture,
      la normalisation du premier lancement ; `--language fr` dans `tests/run.sh`
      et `tools/catalogue.sh`. Tests : sans fichier, une locale `fr_CA` donne le
      français et une locale `de` l'anglais ; un choix écrit se relit au
      démarrage ; une valeur inconnue dans le fichier retombe sur la normalisation.
- [x] **2. Les tables et le contenu.** Le `tr()` dans les fonctions de lecture des
      tables, les accesseurs `nom_affiche()`, les gabarits de `StatHelp`, les
      phrases entières de `StatMod.label()`, le format des pourcentages ; les
      traductions du §5. Tests : complétude et orphelins sur les tables et le
      contenu ; les gabarits gardent leurs valeurs ; en anglais, « ajoute 3 à 7
      dégâts de froid aux sorts » donne « adds 3 to 7 cold damage to spells ».
- [x] **3. Les textes dessinés.** Chaque panneau vu par le joueur, les scènes du
      menu pause et de l'écran des personnages, le retour de coup, le témoin de
      sauvegarde, le mot à taper pour supprimer. Tests : complétude des littéraux
      relevés dans les sources ; le filet des lettres accentuées ; la consigne de
      suppression et le mot attendu sont le même.
- [x] **4. Le choix à l'écran et le changement à chaud.** Le bouton des Options et
      celui de l'écran des personnages, la notification dans les panneaux, la
      re-mesure d'`AffixTag`. Captures en fenêtré, en anglais : l'écran des
      personnages, les Options, la fiche de compétence, l'infobulle d'une épée, la
      fiche de personnage, le menu de la barre, un ennemi d'élite. Tests : changer
      de langue retraduit un panneau déjà ouvert sans le recréer ; le choix
      survit à un redémarrage.
- [x] **5. Ce qui tient dans les deux langues.** Les tests de largeur du §6, et les
      retouches de mise en page qu'ils demandent. Régénérer `docs/CATALOGUE.md` et
      vérifier qu'il est resté français.

### Ce que l'étape 1 a changé au plan

**Le repli de Godot était l'anglais**, et le plan ne le disait pas. Les clés de
traduction étant les textes français eux-mêmes, un texte affiché en français n'y
trouve aucune traduction française — il n'en existe pas — et serait donc reparti
sur le repli : le jeu aurait parlé anglais **en français**.
`internationalization/locale/fallback` vaut maintenant `fr`, et un test le garde.

La langue du système est lue **en mode chargement**, sans rien écrire : sinon un
premier lancement créerait `reglages.json`, et la taille de fenêtre par défaut
passerait pour un choix du joueur dès le lancement suivant.

### Ce que l'étape 2 a changé au plan

**`tr()` ne pouvait pas servir.** C'est une méthode d'objet, et la moitié des
lectures de libellés du jeu sont des fonctions **statiques** — `StatMod.nom()`,
`MotsCles.libelle()`, `EquipmentSlots.label()`. La traduction passe donc par une
feuille, `Textes`, qui appelle `TranslationServer`. Le nom est court parce qu'il
enveloppe chaque texte affiché, et c'est aussi la marque que les tests relèvent
dans les sources : `Textes.t("…")` se grep, `tr()` se serait confondu avec le
reste.

`StatMod.pourcentage()` est né du même besoin : trois endroits écrivaient
« %d %% » à la main, et l'espace avant le signe est une règle française. La plage
(« 8–11 % ») demande son unité au gabarit plutôt que de la réécrire, puisqu'elle
change avec la langue.

### Ce que l'étape 3 a changé au plan

**Les textes des scènes n'ont demandé aucun code** : Godot retraduit seul le
`text` d'un `Label` et d'un `Button`. Le test de complétude les relève donc
directement dans les `.tscn`.

**Deux mots français ont eu besoin d'un contexte**, comme le §2 le prévoyait sans
savoir lesquels : « vitesse » (déplacement sur la fiche, vitesse d'un trait sur la
fiche de compétence) et « esquive » (la statistique, et le mot qui s'envole quand
un coup est évité).

### Ce que l'étape 4 a changé au plan

**`NOTIFICATION_TRANSLATION_CHANGED` arrive aussi à l'entrée dans l'arbre**, avant
que les `@onready` soient posés. Sans garde, le menu de pause écrivait dans un
bouton qui n'existait pas encore : quatre tests e2e sont tombés d'un coup, sur une
erreur qui ne nommait pas la langue. D'où le `is_node_ready()` des deux écrans qui
ont des boutons à réécrire.

### Ce que l'étape 5 a changé au plan

**Rien à retoucher** : les trois largeurs fixes — la fiche de compétence, les
lignes de la fiche de personnage, les entrées du menu de la barre — tiennent déjà
dans les deux langues. Le test reste, parce que c'est le prochain texte ajouté qui
débordera, et qu'aucune capture ne montre deux langues à la fois.

---

## 8. Ce que devient la documentation

`docs/ARCHITECTURE.md` gagne une ligne à « Où vit chaque règle » : un texte
affiché passe par `tr()` dans la fonction qui le lit, et l'anglais vit dans
`i18n/en.po`. `docs/RECETTES.md` gagne une recette — **ajouter un texte affiché** —
et chaque recette de contenu (base d'objet, affixe, compétence, manuel, nature)
gagne sa ligne : **le nom anglais dans `en.po`**, avec le test qui refuse l'oubli.

---

## 9. Ce qui peut mal tourner

**Le texte français retouché.** Corriger une faute dans « Nom vide ou trop long »
change la clé : l'anglais retombe sur le français, sans erreur ni avertissement.
C'est le test des orphelins qui le voit — l'ancienne clé est encore dans `en.po`,
et plus rien ne l'affiche.

**Le `tr()` oublié.** Un texte dessiné sans `tr()` reste en français en anglais.
La complétude ne peut pas le voir : elle ne connaît que ce qui passe par `tr()`.
C'est le filet des lettres accentuées, et les captures de l'étape 4.

**La campagne qui dépend de la machine.** Sans `--language fr`, les tests qui
affirment « 3–7 froid » échouent sur un Windows anglais, et passent sur celui de
l'auteur.

**Le test qui oublie de remettre le français**, ou qui écrit la langue dans
`reglages.json` : les suivants tournent en anglais, et échouent loin de la cause.
Le même piège que `Game.niveau_de_zone` au jalon 5.

**Le texte mesuré une fois.** `AffixTag` mesure ses noms à la création : après un
changement de langue, un nom anglais plus long déborderait de sa largeur centrée,
et un nom qui ne se re-mesure pas reste dans l'ancienne langue.

**La phrase en morceaux.** « ajoute » + « à » + « dégâts de froid » donne un
anglais dans l'ordre du français. D'où les gabarits nommés du §4.

**Les pluriels.** Le français met le singulier à zéro (« 0 point »), l'anglais le
pluriel (« 0 points »). `tr_n()` sans traduction applique la règle anglaise :
un texte français au pluriel doit donc passer par `en.po` **et** garder, côté
français, le cas zéro qu'il a déjà — « aucun point à placer ».

**Le catalogue régénéré en anglais.** `tools/catalogue.sh` lance lui aussi Godot :
sans `--language fr`, `StatMod.nom()` y écrirait « cold damage to spells ».

**Les noms.** Le §5 est une proposition, écrite sans que personne ait joué en
anglais. Ils se changent dans `en.po` sans toucher au code.
