# HnSProject

Un hack'n'slash vu de dessus, en Godot 4.7, **sans aucun asset sur le disque** :
les sprites, les icônes d'objets et les tuiles sont dessinés par du code au
lancement.

Scène de départ : `ui/selection_personnage.tscn`.

## Lancer

Ouvrir le projet dans Godot et jouer (`F5`), ou depuis une ligne de commande :

```bash
godot --path .
```

Dans la zone : `I` sac, `C` fiche de personnage, `TAB` carte, `Échap` menu et
sauvegarde. Les écrans de réglage sont sur `F2` (arène), `F3` (génération de
carte), `F4` (forge) et `F6` (banc de mesure) ; chacun se referme par la touche
qui l'a ouvert.

## Tester

```bash
tests/run.sh              # tout : ~45 s, dont 33 s de tests
tests/run.sh unit         # ~15 s, dont 3 s de tests
```

Le lanceur recopie le projet dans un dossier temporaire avant de l'exécuter — il
ne faut jamais lancer Godot sur le dossier de travail pendant que l'éditeur y est
ouvert. Détails et frontières des suites : [tests/README.md](tests/README.md).

## Documentation

| Document | Ce qu'on y trouve |
|---|---|
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Où vit chaque règle, et **les huit invariants** qui cassent en silence |
| [docs/RECETTES.md](docs/RECETTES.md) | Ajouter une base, un affixe, une statistique, un ennemi, un passif, un nœud de talent — fichiers dans l'ordre et test qui refuse l'oubli |
| [docs/CATALOGUE.md](docs/CATALOGUE.md) | Les 44 bases, les 11 compétences, les trois manuels et les 39 affixes en tableaux. **Généré** par `tools/catalogue.sh` |
| [tests/README.md](tests/README.md) | Comment lancer la campagne, et où va un test |
| `hack-n-slash-jalon-*.md` | Les dix documents de jalon : ce qu'il fallait construire, et pourquoi — dans l'ordre où ça a été décidé |

**Commencer par les invariants** d'ARCHITECTURE.md. Ce sont les seules choses du
projet qui ne se voient ni à la compilation, ni à l'exécution, et dont la moitié
ne se voit qu'au lancement suivant — un identifiant renommé fait disparaître les
objets de toutes les sauvegardes existantes, sans erreur.

## Doctrines, en trois lignes

- **Une règle, un endroit.** Si une valeur est écrite deux fois, l'une des deux
  finira par mentir.
- **Les commentaires expliquent le *pourquoi*.** Ce que fait le code se lit dans
  le code ; ce qu'on a écarté et pour quelle raison, non.
- **Un chiffre de performance s'écrit après l'avoir mesuré**, jamais avant.
