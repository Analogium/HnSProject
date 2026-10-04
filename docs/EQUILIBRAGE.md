# Banc d'équilibrage

<!-- Fichier généré par tools/balance.sh — ne pas éditer à la main. -->

Ce que chaque profil type rencontre, zone par zone. Les profils sont reconstruits
par les règles du jeu à chaque lancement (`BenchProfiles`), et le calcul passe par
les vraies fonctions (`BenchCalculation`). Le banc montre les écarts ; les réglages
restent une décision — voir `JALONS/hack-n-slash-jalon-13.md`.

| verdict | coups pour tuer un grunt | survie au contact |
|---|---|---|
| 🟦 trivial | moins de 0,50 | plus de 10,0 s |
| 🟩 confortable | 0,50 à 3,00 | plus de 10,0 s |
| 🟨 tendu | 3,00 à 8,00 | 4,00 à 10,0 s |
| 🟥 mur | plus de 8,00 | moins de 4,00 s |

Le verdict est le pire des deux axes. Pour lire les nombres :

- **coups** : avec la compétence de la barre qui en demande le moins, critique en
  moyenne, après les défenses de l'ennemi ;
- **secondes** : par `average_per_second()`, *si tout touche* — les traits d'une
  nova comptent tous sur la même cible — et sans compter la réserve de mana ;
- **survie** : au contact de 3 grunts et 1 caster sans affixe, après armure,
  résistances et esquive, régénération déduite. ∞ : la régénération suffit.

Un profil équipé est tiré 9 fois : coups et survie sont les médianes, chacune
sur son axe ; le détail est celui du tirage médian en coups.

## Niveau attendu

Le niveau atteint en vidant une fois chaque zone de 1 à Z − 1, avec la population
moyenne de l'`EnemySpawner` et le retard de `Enemy.experience_factor()`.

| zone | 1 | 10 | 20 | 40 | 60 | 90 | 120 |
|---|---|---|---|---|---|---|---|
| niveau | 1 | 14 | 21 | 36 | 58 | 100 | 100 |

## Sort — Manuel de la foudre, Esprit d'orage

| profil | zone 1 | zone 10 | zone 20 | zone 40 | zone 60 | zone 90 | zone 120 |
|---|---|---|---|---|---|---|---|
| Débutant | 🟨 1,36 · 4,68 s | 🟥 2,27 · 2,20 s | 🟥 4,01 · 1,39 s | 🟥 12,6 · 0,80 s | 🟥 39,8 · 0,56 s | 🟥 226 · 0,39 s | 🟥 1310 · 0,30 s |
| Nu | 🟨 1,36 · 4,68 s | 🟥 0,64 · 2,20 s | 🟥 0,77 · 1,62 s | 🟥 1,65 · 1,21 s | 🟥 4,00 · 1,33 s | 🟥 22,7 · 2,20 s | 🟥 132 · 1,68 s |
| Sous-équipé | 🟩 1,34 · 26,0 s | 🟨 0,62 · 6,37 s | 🟥 0,75 · 3,55 s | 🟨 1,56 · 4,55 s | 🟨 3,27 · 4,67 s | 🟥 17,3 · 10,2 s | 🟥 72,8 · 7,24 s |
| Équipé | 🟩 1,35 · 22,0 s | 🟨 0,53 · 5,66 s | 🟨 0,69 · 6,93 s | 🟨 1,16 · 9,87 s | 🟩 2,53 · 11,2 s | 🟥 14,5 · 11,0 s | 🟥 72,8 · 8,61 s |
| Sur-équipé | 🟩 0,99 · ∞ s | 🟩 0,60 · 91,0 s | 🟩 0,56 · 45,0 s | 🟩 1,14 · 17,7 s | 🟨 3,13 · 10,9 s | 🟥 17,4 · 9,10 s | 🟥 83,0 · 8,84 s |

Case : verdict, coups pour tuer un grunt, secondes de survie.

<details><summary>Détail</summary>

| profil | zone | niveau | compétence | coups grunt | coups caster | coups colosse | s grunt | s colosse | survie |
|---|---|---|---|---|---|---|---|---|---|
| Débutant | 1 | 1 | Éclair vif | 1,36 | 0,91 | 2,72 | 0,50 | 0,99 | 4,68 |
| Débutant | 10 | 1 | Éclair vif | 2,27 | 1,51 | 4,54 | 0,83 | 1,66 | 2,20 |
| Débutant | 20 | 1 | Éclair vif | 4,01 | 2,68 | 8,03 | 1,47 | 2,93 | 1,39 |
| Débutant | 40 | 1 | Éclair vif | 12,6 | 8,40 | 25,2 | 4,60 | 9,20 | 0,80 |
| Débutant | 60 | 1 | Éclair vif | 39,8 | 26,5 | 79,6 | 14,5 | 29,1 | 0,56 |
| Débutant | 90 | 1 | Éclair vif | 226 | 151 | 452 | 82,6 | 165 | 0,39 |
| Débutant | 120 | 1 | Éclair vif | 1310 | 873 | 2620 | 479 | 957 | 0,30 |
| Nu | 1 | 1 | Éclair vif | 1,36 | 0,91 | 2,72 | 0,50 | 0,99 | 4,68 |
| Nu | 10 | 14 | Chaîne d'éclairs | 0,64 | 0,43 | 1,29 | 0,07 | 0,15 | 2,20 |
| Nu | 20 | 21 | Éclair vif | 0,77 | 0,51 | 1,53 | 0,11 | 0,21 | 1,62 |
| Nu | 40 | 36 | Éclair vif | 1,65 | 1,10 | 3,29 | 0,19 | 0,38 | 1,21 |
| Nu | 60 | 58 | Éclair vif | 4,00 | 2,67 | 8,00 | 0,46 | 0,92 | 1,33 |
| Nu | 90 | 100 | Éclair vif | 22,7 | 15,2 | 45,5 | 2,60 | 5,21 | 2,20 |
| Nu | 120 | 100 | Éclair vif | 132 | 87,8 | 263 | 15,1 | 30,2 | 1,68 |
| Sous-équipé | 1 | 1 | Éclair vif | 1,34 | 0,90 | 2,69 | 0,48 | 0,97 | 26,0 |
| Sous-équipé | 10 | 14 | Chaîne d'éclairs | 0,62 | 0,41 | 1,24 | 0,07 | 0,14 | 6,37 |
| Sous-équipé | 20 | 21 | Éclair vif | 0,75 | 0,50 | 1,50 | 0,10 | 0,20 | 3,55 |
| Sous-équipé | 40 | 36 | Éclair vif | 1,56 | 1,04 | 3,11 | 0,18 | 0,35 | 4,55 |
| Sous-équipé | 60 | 58 | Éclair vif | 3,27 | 2,18 | 6,55 | 0,34 | 0,69 | 4,67 |
| Sous-équipé | 90 | 100 | Éclair vif | 17,3 | 11,5 | 34,6 | 1,49 | 2,99 | 10,2 |
| Sous-équipé | 120 | 100 | Éclair vif | 72,8 | 48,6 | 146 | 6,50 | 13,0 | 7,24 |
| Équipé | 1 | 1 | Éclair vif | 1,35 | 0,90 | 2,70 | 0,48 | 0,97 | 22,0 |
| Équipé | 10 | 14 | Chaîne d'éclairs | 0,53 | 0,36 | 1,07 | 0,06 | 0,12 | 5,66 |
| Équipé | 20 | 21 | Éclair vif | 0,69 | 0,46 | 1,38 | 0,08 | 0,17 | 6,93 |
| Équipé | 40 | 36 | Éclair vif | 1,16 | 0,77 | 2,32 | 0,12 | 0,23 | 9,87 |
| Équipé | 60 | 58 | Éclair vif | 2,53 | 1,69 | 5,07 | 0,24 | 0,48 | 11,2 |
| Équipé | 90 | 100 | Éclair vif | 14,5 | 9,66 | 29,0 | 1,20 | 2,40 | 11,0 |
| Équipé | 120 | 100 | Éclair vif | 72,8 | 48,6 | 146 | 6,47 | 12,9 | 8,61 |
| Sur-équipé | 1 | 1 | Éclair vif | 0,99 | 0,66 | 1,98 | 0,15 | 0,29 | ∞ |
| Sur-équipé | 10 | 14 | Chaîne d'éclairs | 0,60 | 0,40 | 1,21 | 0,06 | 0,13 | 91,0 |
| Sur-équipé | 20 | 21 | Éclair vif | 0,56 | 0,37 | 1,12 | 0,06 | 0,11 | 45,0 |
| Sur-équipé | 40 | 36 | Éclair vif | 1,14 | 0,76 | 2,27 | 0,11 | 0,21 | 17,7 |
| Sur-équipé | 60 | 58 | Éclair vif | 3,13 | 2,09 | 6,26 | 0,27 | 0,54 | 10,9 |
| Sur-équipé | 90 | 100 | Éclair vif | 17,4 | 11,6 | 34,9 | 1,72 | 3,44 | 9,10 |
| Sur-équipé | 120 | 100 | Éclair vif | 83,0 | 55,3 | 166 | 7,58 | 15,2 | 8,84 |

</details>

## Mêlée — Manuel du chevalier, Colosse

| profil | zone 1 | zone 10 | zone 20 | zone 40 | zone 60 | zone 90 | zone 120 |
|---|---|---|---|---|---|---|---|
| Débutant | 🟨 0,94 · 4,68 s | 🟥 1,94 · 2,20 s | 🟥 4,13 · 1,39 s | 🟥 16,8 · 0,80 s | 🟥 62,7 · 0,56 s | 🟥 415 · 0,39 s | 🟥 2583 · 0,30 s |
| Nu | 🟨 0,94 · 4,68 s | 🟨 0,27 · 4,77 s | 🟨 0,46 · 7,91 s | 🟨 0,97 · 6,86 s | 🟨 2,39 · 6,28 s | 🟥 12,8 · 4,04 s | 🟥 68,2 · 2,97 s |
| Sous-équipé | 🟩 0,84 · 22,0 s | 🟦 0,26 · 12,1 s | 🟦 0,45 · 17,0 s | 🟩 0,84 · 24,2 s | 🟩 1,99 · 38,5 s | 🟨 7,26 · 26,3 s | 🟥 38,6 · 20,9 s |
| Équipé | 🟩 0,97 · 20,0 s | 🟦 0,25 · 13,8 s | 🟦 0,43 · 32,8 s | 🟩 0,74 · 71,3 s | 🟩 1,60 · 47,1 s | 🟥 8,65 · 35,0 s | 🟥 49,9 · 19,3 s |
| Sur-équipé | 🟩 0,71 · ∞ s | 🟦 0,19 · 85,8 s | 🟦 0,32 · 234 s | 🟩 0,51 · 83,4 s | 🟩 2,10 · 59,3 s | 🟥 9,13 · 29,3 s | 🟥 35,9 · 18,8 s |

Case : verdict, coups pour tuer un grunt, secondes de survie.

<details><summary>Détail</summary>

| profil | zone | niveau | compétence | coups grunt | coups caster | coups colosse | s grunt | s colosse | survie |
|---|---|---|---|---|---|---|---|---|---|
| Débutant | 1 | 1 | Frappe lourde | 0,94 | 0,62 | 1,87 | 0,41 | 0,81 | 4,68 |
| Débutant | 10 | 1 | Frappe lourde | 1,94 | 1,29 | 3,88 | 0,84 | 1,68 | 2,20 |
| Débutant | 20 | 1 | Frappe lourde | 4,13 | 2,75 | 8,25 | 1,79 | 3,57 | 1,39 |
| Débutant | 40 | 1 | Frappe lourde | 16,8 | 11,2 | 33,5 | 7,25 | 14,5 | 0,80 |
| Débutant | 60 | 1 | Frappe lourde | 62,7 | 41,8 | 125 | 27,1 | 54,2 | 0,56 |
| Débutant | 90 | 1 | Frappe lourde | 415 | 277 | 831 | 180 | 359 | 0,39 |
| Débutant | 120 | 1 | Frappe lourde | 2583 | 1722 | 5165 | 1117 | 2235 | 0,30 |
| Nu | 1 | 1 | Frappe lourde | 0,94 | 0,62 | 1,87 | 0,41 | 0,81 | 4,68 |
| Nu | 10 | 14 | Frappe lourde | 0,27 | 0,18 | 0,53 | 0,12 | 0,23 | 4,77 |
| Nu | 20 | 21 | Frappe lourde | 0,46 | 0,31 | 0,93 | 0,20 | 0,40 | 7,91 |
| Nu | 40 | 36 | Frappe lourde | 0,97 | 0,64 | 1,93 | 0,48 | 0,96 | 6,86 |
| Nu | 60 | 58 | Frappe lourde | 2,39 | 1,59 | 4,78 | 0,88 | 1,76 | 6,28 |
| Nu | 90 | 100 | Frappe lourde | 12,8 | 8,54 | 25,6 | 4,72 | 9,44 | 4,04 |
| Nu | 120 | 100 | Frappe lourde | 68,2 | 45,5 | 136 | 25,1 | 50,3 | 2,97 |
| Sous-équipé | 1 | 1 | Frappe lourde | 0,84 | 0,56 | 1,69 | 0,36 | 0,72 | 22,0 |
| Sous-équipé | 10 | 14 | Frappe lourde | 0,26 | 0,17 | 0,52 | 0,11 | 0,22 | 12,1 |
| Sous-équipé | 20 | 21 | Frappe lourde | 0,45 | 0,30 | 0,90 | 0,19 | 0,38 | 17,0 |
| Sous-équipé | 40 | 36 | Frappe lourde | 0,84 | 0,56 | 1,68 | 0,35 | 0,70 | 24,2 |
| Sous-équipé | 60 | 58 | Frappe lourde | 1,99 | 1,33 | 3,98 | 0,60 | 1,21 | 38,5 |
| Sous-équipé | 90 | 100 | Frappe lourde | 7,26 | 4,84 | 14,5 | 2,17 | 4,34 | 26,3 |
| Sous-équipé | 120 | 100 | Frappe lourde | 38,6 | 25,8 | 77,3 | 11,1 | 22,2 | 20,9 |
| Équipé | 1 | 1 | Frappe lourde | 0,97 | 0,65 | 1,94 | 0,37 | 0,75 | 20,0 |
| Équipé | 10 | 14 | Frappe lourde | 0,25 | 0,17 | 0,50 | 0,11 | 0,22 | 13,8 |
| Équipé | 20 | 21 | Frappe lourde | 0,43 | 0,29 | 0,86 | 0,18 | 0,37 | 32,8 |
| Équipé | 40 | 36 | Frappe lourde | 0,74 | 0,49 | 1,48 | 0,32 | 0,64 | 71,3 |
| Équipé | 60 | 58 | Frappe lourde | 1,60 | 1,06 | 3,19 | 0,43 | 0,86 | 47,1 |
| Équipé | 90 | 100 | Frappe lourde | 8,65 | 5,77 | 17,3 | 2,48 | 4,96 | 35,0 |
| Équipé | 120 | 100 | Frappe lourde | 49,9 | 33,2 | 99,7 | 15,0 | 29,9 | 19,3 |
| Sur-équipé | 1 | 1 | Frappe lourde | 0,71 | 0,48 | 1,43 | 0,26 | 0,53 | ∞ |
| Sur-équipé | 10 | 14 | Frappe lourde | 0,19 | 0,12 | 0,37 | 0,08 | 0,16 | 85,8 |
| Sur-équipé | 20 | 21 | Frappe lourde | 0,32 | 0,21 | 0,63 | 0,11 | 0,23 | 234 |
| Sur-équipé | 40 | 36 | Frappe lourde | 0,51 | 0,34 | 1,01 | 0,19 | 0,37 | 83,4 |
| Sur-équipé | 60 | 58 | Frappe lourde | 2,10 | 1,40 | 4,19 | 0,58 | 1,17 | 59,3 |
| Sur-équipé | 90 | 100 | Frappe lourde | 9,13 | 6,09 | 18,3 | 2,46 | 4,92 | 29,3 |
| Sur-équipé | 120 | 100 | Frappe lourde | 35,9 | 23,9 | 71,8 | 9,45 | 18,9 | 18,8 |

</details>

## Simulation

Non relancée : `tools/balance.sh calculation`.
