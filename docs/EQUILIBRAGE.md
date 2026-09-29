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
| Débutant | 🟨 0,92 · 4,68 s | 🟥 1,90 · 2,20 s | 🟥 4,03 · 1,39 s | 🟥 16,3 · 0,80 s | 🟥 60,9 · 0,56 s | 🟥 403 · 0,39 s | 🟥 2502 · 0,30 s |
| Nu | 🟨 0,92 · 4,68 s | 🟨 0,30 · 4,77 s | 🟨 0,53 · 7,91 s | 🟨 1,10 · 6,86 s | 🟨 2,74 · 6,28 s | 🟥 14,8 · 4,04 s | 🟥 79,4 · 2,97 s |
| Sous-équipé | 🟩 0,83 · 22,0 s | 🟦 0,30 · 12,1 s | 🟩 0,51 · 17,0 s | 🟩 0,96 · 24,2 s | 🟩 2,28 · 38,5 s | 🟥 8,31 · 26,3 s | 🟥 44,4 · 20,9 s |
| Équipé | 🟩 0,95 · 20,0 s | 🟦 0,28 · 13,8 s | 🟦 0,49 · 32,8 s | 🟩 0,84 · 71,3 s | 🟩 1,82 · 47,1 s | 🟥 9,94 · 35,0 s | 🟥 57,7 · 19,3 s |
| Sur-équipé | 🟩 0,70 · ∞ s | 🟦 0,21 · 85,8 s | 🟦 0,36 · 234 s | 🟩 0,58 · 83,4 s | 🟩 2,40 · 59,3 s | 🟥 10,5 · 29,3 s | 🟥 41,3 · 18,8 s |

Case : verdict, coups pour tuer un grunt, secondes de survie.

<details><summary>Détail</summary>

| profil | zone | niveau | compétence | coups grunt | coups caster | coups colosse | s grunt | s colosse | survie |
|---|---|---|---|---|---|---|---|---|---|
| Débutant | 1 | 1 | Frappe lourde | 0,92 | 0,61 | 1,84 | 0,40 | 0,80 | 4,68 |
| Débutant | 10 | 1 | Frappe lourde | 1,90 | 1,27 | 3,80 | 0,82 | 1,65 | 2,20 |
| Débutant | 20 | 1 | Frappe lourde | 4,03 | 2,69 | 8,06 | 1,74 | 3,49 | 1,39 |
| Débutant | 40 | 1 | Frappe lourde | 16,3 | 10,9 | 32,6 | 7,06 | 14,1 | 0,80 |
| Débutant | 60 | 1 | Frappe lourde | 60,9 | 40,6 | 122 | 26,3 | 52,7 | 0,56 |
| Débutant | 90 | 1 | Frappe lourde | 403 | 268 | 805 | 174 | 349 | 0,39 |
| Débutant | 120 | 1 | Frappe lourde | 2502 | 1668 | 5005 | 1083 | 2165 | 0,30 |
| Nu | 1 | 1 | Frappe lourde | 0,92 | 0,61 | 1,84 | 0,40 | 0,80 | 4,68 |
| Nu | 10 | 14 | Frappe lourde | 0,30 | 0,20 | 0,61 | 0,13 | 0,26 | 4,77 |
| Nu | 20 | 21 | Frappe lourde | 0,53 | 0,35 | 1,06 | 0,23 | 0,46 | 7,91 |
| Nu | 40 | 36 | Frappe lourde | 1,10 | 0,74 | 2,21 | 0,49 | 0,99 | 6,86 |
| Nu | 60 | 58 | Frappe lourde | 2,74 | 1,83 | 5,49 | 1,01 | 2,02 | 6,28 |
| Nu | 90 | 100 | Frappe lourde | 14,8 | 9,87 | 29,6 | 5,46 | 10,9 | 4,04 |
| Nu | 120 | 100 | Frappe lourde | 79,4 | 52,9 | 159 | 29,3 | 58,5 | 2,97 |
| Sous-équipé | 1 | 1 | Frappe lourde | 0,83 | 0,55 | 1,66 | 0,35 | 0,71 | 22,0 |
| Sous-équipé | 10 | 14 | Frappe lourde | 0,30 | 0,20 | 0,59 | 0,13 | 0,25 | 12,1 |
| Sous-équipé | 20 | 21 | Frappe lourde | 0,51 | 0,34 | 1,03 | 0,22 | 0,44 | 17,0 |
| Sous-équipé | 40 | 36 | Frappe lourde | 0,96 | 0,64 | 1,92 | 0,40 | 0,79 | 24,2 |
| Sous-équipé | 60 | 58 | Frappe lourde | 2,28 | 1,52 | 4,55 | 0,69 | 1,38 | 38,5 |
| Sous-équipé | 90 | 100 | Frappe lourde | 8,31 | 5,54 | 16,6 | 2,25 | 4,51 | 26,3 |
| Sous-équipé | 120 | 100 | Frappe lourde | 44,4 | 29,6 | 88,9 | 11,8 | 23,6 | 20,9 |
| Équipé | 1 | 1 | Frappe lourde | 0,95 | 0,63 | 1,90 | 0,37 | 0,74 | 20,0 |
| Équipé | 10 | 14 | Frappe lourde | 0,28 | 0,19 | 0,56 | 0,12 | 0,24 | 13,8 |
| Équipé | 20 | 21 | Frappe lourde | 0,49 | 0,33 | 0,98 | 0,21 | 0,42 | 32,8 |
| Équipé | 40 | 36 | Frappe lourde | 0,84 | 0,56 | 1,69 | 0,32 | 0,64 | 71,3 |
| Équipé | 60 | 58 | Frappe lourde | 1,82 | 1,22 | 3,65 | 0,47 | 0,93 | 47,1 |
| Équipé | 90 | 100 | Frappe lourde | 9,94 | 6,63 | 19,9 | 2,77 | 5,55 | 35,0 |
| Équipé | 120 | 100 | Frappe lourde | 57,7 | 38,5 | 115 | 17,3 | 34,6 | 19,3 |
| Sur-équipé | 1 | 1 | Frappe lourde | 0,70 | 0,47 | 1,40 | 0,26 | 0,52 | ∞ |
| Sur-équipé | 10 | 14 | Frappe lourde | 0,21 | 0,14 | 0,42 | 0,09 | 0,17 | 85,8 |
| Sur-équipé | 20 | 21 | Frappe lourde | 0,36 | 0,24 | 0,72 | 0,13 | 0,26 | 234 |
| Sur-équipé | 40 | 36 | Frappe lourde | 0,58 | 0,38 | 1,15 | 0,19 | 0,37 | 83,4 |
| Sur-équipé | 60 | 58 | Frappe lourde | 2,40 | 1,60 | 4,80 | 0,67 | 1,34 | 59,3 |
| Sur-équipé | 90 | 100 | Frappe lourde | 10,5 | 7,00 | 21,0 | 2,75 | 5,51 | 29,3 |
| Sur-équipé | 120 | 100 | Frappe lourde | 41,3 | 27,5 | 82,5 | 10,5 | 20,9 | 18,8 |

</details>

## Simulation

Non relancée : `tools/balance.sh calculation`.
