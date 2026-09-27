# Hack'n'slash top-down — jalon 29

Suite des jalons 1 à 28. Ce document ne redit pas ce qui y est déjà écrit, et
`docs/ARCHITECTURE.md` reste le seul endroit qui décrit l'état courant.

**Ouvert le 27 septembre 2026.** Le jalon des **pièces de monnaie** : jusqu'ici un
objet était ce qu'il était en tombant. Les pièces, comme les orbes de PoE, le
retravaillent.

---

## 1. Ce que l'utilisateur a demandé

- Des « objets » qui tombent, les **Pièces de …**, d'**une case** chacune.
- **Clic droit** sur la pièce, puis **clic gauche** sur la cible ; chaque pièce a ses
  cibles permises.
- Six pièces, de la plus commune à la plus rare :

| Pièce | Cible | Effet |
|---|---|---|
| **de cuivre** | normal | le rend magique, un affixe |
| **de bronze** | magique | tire à nouveau tous ses affixes |
| **d'argent** | magique | le rend rare en lui ajoutant un affixe |
| **d'or** | rare | tire à nouveau tous ses affixes, plus ou moins qu'avant |
| **de platine** | rare | lui ajoute un affixe |
| **de diamant** | tout objet affixé | tire à nouveau les valeurs de ses affixes |

Au retour sur la première livraison : **l'argent n'ajoute qu'un affixe**, quitte à
faire un rare de deux ; l'or garde ses 3 à 6 ; **les pièces s'empilent**.

## 2. Le système

- **Une pièce est une base d'objet**, famille `currency`, dans `ItemCatalog.ALL` :
  sauvegarde, ramassage, sac, établi et catalogue la servent sans une ligne de plus.
  Elle ne porte que son nom et son image ; **ce qu'elle fait n'est écrit que dans
  `core/currency.gd`**, par identifiant — `accepts()` pour la surbrillance et le
  refus, `apply()` pour l'effet, `effect()` pour l'infobulle.
- **La chute.** `ItemCatalog.available()` écarte les pièces : parmi les bases, elles
  tomberaient chacune aussi souvent que l'épée, le diamant autant que le cuivre. À la
  place, `LootTable.roll()` change `CURRENCY_SHARE` (25 %) des chutes en une pièce,
  tirée par `Currency.DROP_WEIGHTS` (100, 50, 20, 8, 4, 1). Sur `Game.rng`, comme le
  butin, et l'application aussi.
- **Les tirages ne sont pas refaits.** `ItemAffixPool.roll()` est coupé en deux :
  `roll_count()` accepte une plage de rareté, et `draw()` tire N affixes distincts
  dans une réserve. Le butin tire dans le même ordre qu'avant. `ItemAffix.roll_tier()`
  sort du tirage pour que le diamant garde le palier.
- **Le geste**, dans `InventoryPanel` : clic droit sur une pièce du sac, qui y reste
  (`_coin`) ; le clic suivant l'applique à l'objet visé. Acceptée, elle est retirée du
  sac ; dans tous les cas le geste se termine. Pendant le geste, l'objet survolé se
  teinte vert ou rouge et la pièce suit le curseur, à côté. Un clic droit ou la
  fermeture du sac l'annule ; un clic hors du sac aussi, sans lancer d'attaque.
- **Un rare à deux affixes existe** : `Item.rare`, posé par la pièce d'argent, force la
  rareté que `rarity()` déduit sinon du nombre d'affixes.
- **Les piles** : `ItemBase.stack_max` (20 pour une pièce, 1 ailleurs), `Item.count`, et
  une seule règle de versement, `Item.absorb()`. Le ramassage verse sur les piles du sac
  avant de chercher une case ; une pile posée sur sa jumelle s'y verse ; appliquer une
  pièce n'en dépense qu'une (`Inventory.spend_one()`). Le nombre s'écrit dans le coin de
  l'icône, l'infobulle dit « Pile : 7 / 20 », le nom au sol « 7 × Pièce de cuivre ».
- **La sauvegarde passe en v10** : `count` au-delà de 1, `rare` quand il est posé. Un
  objet ordinaire s'écrit comme en v9 ; relue, une v1 à v9 a des piles d'un et des
  raretés déduites.

## 3. Ce qui a été tranché sans l'utilisateur

À revoir sur pièce ; aucun n'engage la suite.

- **Les nombres tirés à nouveau suivent la chute** : le bronze donne 1 ou 2 affixes, l'or
  3 à 6, chacun aux poids de `COUNT_WEIGHTS` restreints à sa rareté — l'or sort donc
  3 affixes une fois sur deux, 6 une fois sur seize. « Totalement au hasard » pris
  comme « au hasard du butin », pas comme une loi uniforme.
- **Le platine s'arrête à six**, le plafond de la chute (`ItemAffixPool.MAX_COUNT`).
- **Le diamant ne touche que les affixes** : ni l'implicite, qui a pourtant une plage,
  ni une ligne sans provenance, dont on ne sait pas le palier.
- **Seul un objet du sac se vise** : un objet porté se retire d'abord. PoE fait pareil,
  et ça évite de recalculer la fiche au milieu du geste.
- **Pas de séparation de pile** (le Maj + clic de PoE) : on ne dépense qu'une pièce à
  la fois, rien ne l'exigeait encore.
- **Une pile de 20**, la même pour toutes les pièces.
- **Aucune pièce ne vise un manuel** : sa rareté vient de son palier, pas d'affixes.
- **Les chiffres de chute** sont provisoires : l'équilibrage se fait en dernier
  (jalon 13, §7).
- **La couleur du nom** : le beige des monnaies de PoE, hors de la gamme des raretés
  (`Item.CURRENCY_COLOR`).

## 4. Ce qui s'est choisi sur planche

Planches et captures sur le Bureau : `hns-captures-jalon29-pieces` (1 à 9).

- **Les icônes**, par `tools/item_icons.py` (groupe `monnaie`) : quatre formules × six
  pièces × trois graines (planche 1). La pile de pièces (B) sort éparpillée, le détourage
  la laisse en morceaux ; le trou carré (C) et l'étoile (D) ratent des tirages. Retenue :
  **la couronne (A)**, graine 1337 pour les cinq métaux. Le diamant, demandé plus bleu,
  a été retiré sur une formule de cristal bleu glacé (planche 7), graine 777.
- **L'argent et le platine** restent les plus proches : le platine est demandé
  « bleuté » et c'est ce reflet qui les sépare dans une case.

## 5. Ce que la capture a corrigé

- **La pièce au curseur portait le nombre de sa pile** (« 7 ») alors qu'on n'en
  applique qu'une : elle se dessine désormais sans (captures 3 et 4 contre la première
  série).
- Rien d'autre : refus en rouge, accord en vert, argent passé de 3 à 2 et anneau doré à
  deux affixes (5), « 3 × Pièce d'or » au sol (6, 9).
