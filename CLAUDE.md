# Consignes pour Claude Code

Projet Godot 4.7, GDScript, **en français** — noms de classes et de fonctions
compris pour tout ce qui est né après le jalon 3. Lire
[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) avant de toucher au code : ses huit
invariants sont les seules choses du dépôt qui cassent en silence.

## Ce qu'il ne faut jamais faire

**Ne jamais lancer Godot sur le dossier de travail.** L'utilisateur a son éditeur
ouvert dessus ; un lancement lui réimporte son cache `.godot/` sous les pieds.
Passer par `tests/run.sh` et `tools/catalogue.sh`, qui recopient d'abord le
projet dans un dossier temporaire. Pour un essai ponctuel hors de ces scripts,
refaire la copie à la main.

**Ne jamais arrêter un processus Godot par nom d'image.** `taskkill /IM godot*`
ferme l'éditeur de l'utilisateur, qui doit alors le relancer. Cibler par ligne de
commande :

```bash
powershell.exe -NoProfile -Command '
  Get-CimInstance Win32_Process |
    Where-Object { $_.Name -like "godot*" -and $_.CommandLine -match "Temp[\\/]hns-" } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force }
'
```

**Ne jamais écrire dans le `user://` du vrai projet**
(`AppData/Roaming/Godot/app_userdata/HnSProject/`) : il contient les personnages
sauvegardés. Toute copie temporaire doit tourner sous un **`config/name`
distinct**, sinon son `user://` est celui du vrai projet — même nom, même
dossier. Vérifier le `sed` avant de lancer.

**Ne jamais commiter sans que l'utilisateur le demande.**

## Valider

```bash
tests/run.sh              # tout : ~45 s, dont 33 s de tests
tests/run.sh unit         # ~15 s, dont 3 s de tests
```

**Rien ne s'annonce sans que la suite soit passée.** Du code qui compile n'est
pas du code vérifié.

Trois choses que la campagne n'attrape pas, et qu'il faut faire à la main quand
elles s'appliquent :

- **le dessin** — aucune assertion ne voit un panneau qui passe sous un autre.
  Capture réelle en **fenêtré** ; en `--headless` le pilote de rendu est un
  bouchon et les captures sortent vides ;
- **la performance** — remesurer sur `world/stress_test.tscn` et comparer au
  tableau de référence ci-dessous. Chauffer ~240 images avant de relever : le
  premier bloc mesure le démarrage (27 img/s contre 165 en régime établi) ;
- **le clavier** — aucun test ne pilote d'entrée clavier. Ce qui touche à
  `_unhandled_input` se vérifie en relisant le diff ou en jouant.

### Référence de performance

Banc `world/stress_test.tscn`, graine 4242, en fenêtré, après chauffe.

| ennemis simulés | img/s | physique |
|---|---|---|
| 142 | 165 | 4,54 ms |
| 284 | 165 | 4,41 ms |
| 562 | 165 | 6,77 ms |
| 935 | 165 | 8,62 ms |

La zone jouée en compte 69 : environ 25× de marge. Le chiffre qui compte est
**simulés**, pas **vivants** — au-delà de 700 px l'`EnemyManager` ne tick plus.

## Écrire du code ici

- **Une règle, un endroit.** Une valeur écrite deux fois finira par mentir d'un
  côté. Avant d'ajouter une constante, chercher si elle existe déjà.
- **Les commentaires disent le *pourquoi*.** Ce que fait le code se lit dans le
  code. L'utilisateur trouve qu'il y en a trop : écrire le piège, le chiffre
  mesuré et l'arbitrage — pas l'historique du fichier, que git retient déjà, ni
  la paraphrase de la ligne d'en dessous.
- **Un chiffre de performance s'écrit après l'avoir mesuré.** Jamais avant.
- **Les tableaux packés se justifient par une mesure.** Partout ailleurs, une
  petite classe aux champs nommés. `p[9]` oblige à compter les colonnes.
- **Relire son code avant de le livrer** : la passe de nettoyage — noms, morts,
  redondances, commentaires devenus faux — fait partie du travail, pas d'une
  revue ultérieure.
- **Ne jamais ajuster une valeur attendue pour faire passer un test.** Les
  chiffres mesurés à la mise en place sont des points de comparaison ; s'ils
  changent, c'est une régression à comprendre.

## Ajouter du contenu

Les gestes courants ont leur marche à suivre, avec les fichiers dans l'ordre et
le test qui refuse l'oubli : [docs/RECETTES.md](docs/RECETTES.md).

Après avoir touché un `.tres` de contenu, régénérer la référence :

```bash
tools/catalogue.sh        # écrit docs/CATALOGUE.md
```

## Skills du dépôt

- `/valider` — la démarche complète de validation après une fonctionnalité.
- `/revue-systemes` — la passe de revue : une règle, un endroit ; ce qu'on
  refuse de factoriser et pourquoi.
