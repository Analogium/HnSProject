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
| Sous-équipé | 🟩 1,35 · 24,1 s | 🟨 0,62 · 6,18 s | 🟥 0,75 · 3,51 s | 🟨 1,60 · 4,37 s | 🟨 3,36 · 5,75 s | 🟥 14,7 · 11,2 s | 🟥 84,6 · 7,17 s |
| Équipé | 🟩 1,31 · 22,2 s | 🟨 0,57 · 5,60 s | 🟨 0,69 · 7,52 s | 🟨 1,30 · 8,28 s | 🟩 2,55 · 12,4 s | 🟥 14,1 · 11,9 s | 🟥 71,2 · 8,08 s |
| Sur-équipé | 🟩 1,07 · ∞ s | 🟩 0,63 · 153 s | 🟦 0,41 · 32,9 s | 🟩 1,04 · 17,0 s | 🟨 3,14 · 11,0 s | 🟥 14,1 · 8,70 s | 🟥 127 · 12,4 s |

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
| Sous-équipé | 1 | 1 | Éclair vif | 1,35 | 0,90 | 2,70 | 0,46 | 0,92 | 24,1 |
| Sous-équipé | 10 | 14 | Chaîne d'éclairs | 0,62 | 0,42 | 1,25 | 0,07 | 0,14 | 6,18 |
| Sous-équipé | 20 | 21 | Éclair vif | 0,75 | 0,50 | 1,50 | 0,10 | 0,20 | 3,51 |
| Sous-équipé | 40 | 36 | Éclair vif | 1,60 | 1,07 | 3,21 | 0,18 | 0,36 | 4,37 |
| Sous-équipé | 60 | 58 | Éclair vif | 3,36 | 2,24 | 6,72 | 0,33 | 0,65 | 5,75 |
| Sous-équipé | 90 | 100 | Éclair vif | 14,7 | 9,78 | 29,3 | 1,38 | 2,76 | 11,2 |
| Sous-équipé | 120 | 100 | Éclair vif | 84,6 | 56,4 | 169 | 7,99 | 16,0 | 7,17 |
| Équipé | 1 | 1 | Éclair vif | 1,31 | 0,88 | 2,63 | 0,44 | 0,88 | 22,2 |
| Équipé | 10 | 14 | Chaîne d'éclairs | 0,57 | 0,38 | 1,14 | 0,07 | 0,13 | 5,60 |
| Équipé | 20 | 21 | Éclair vif | 0,69 | 0,46 | 1,38 | 0,09 | 0,17 | 7,52 |
| Équipé | 40 | 36 | Éclair vif | 1,30 | 0,87 | 2,60 | 0,13 | 0,26 | 8,28 |
| Équipé | 60 | 58 | Éclair vif | 2,55 | 1,70 | 5,11 | 0,22 | 0,44 | 12,4 |
| Équipé | 90 | 100 | Éclair vif | 14,1 | 9,39 | 28,2 | 1,33 | 2,65 | 11,9 |
| Équipé | 120 | 100 | Éclair vif | 71,2 | 47,5 | 142 | 6,58 | 13,2 | 8,08 |
| Sur-équipé | 1 | 1 | Éclair vif | 1,07 | 0,72 | 2,15 | 0,36 | 0,72 | ∞ |
| Sur-équipé | 10 | 14 | Chaîne d'éclairs | 0,63 | 0,42 | 1,26 | 0,06 | 0,13 | 153 |
| Sur-équipé | 20 | 21 | Éclair vif | 0,41 | 0,27 | 0,82 | 0,03 | 0,07 | 32,9 |
| Sur-équipé | 40 | 36 | Éclair vif | 1,04 | 0,69 | 2,08 | 0,10 | 0,20 | 17,0 |
| Sur-équipé | 60 | 58 | Éclair vif | 3,14 | 2,09 | 6,28 | 0,29 | 0,59 | 11,0 |
| Sur-équipé | 90 | 100 | Éclair vif | 14,1 | 9,42 | 28,3 | 1,14 | 2,29 | 8,70 |
| Sur-équipé | 120 | 100 | Éclair vif | 127 | 85,0 | 255 | 12,5 | 25,0 | 12,4 |

</details>

## Mêlée — Manuel du chevalier, Colosse

| profil | zone 1 | zone 10 | zone 20 | zone 40 | zone 60 | zone 90 | zone 120 |
|---|---|---|---|---|---|---|---|
| Débutant | 🟨 0,94 · 4,68 s | 🟥 1,94 · 2,20 s | 🟥 4,13 · 1,39 s | 🟥 16,8 · 0,80 s | 🟥 62,7 · 0,56 s | 🟥 415 · 0,39 s | 🟥 2583 · 0,30 s |
| Nu | 🟨 0,94 · 4,68 s | 🟨 0,27 · 4,77 s | 🟨 0,46 · 7,91 s | 🟨 0,97 · 6,86 s | 🟨 2,39 · 6,28 s | 🟥 12,8 · 4,04 s | 🟥 68,2 · 2,97 s |
| Sous-équipé | 🟩 0,88 · 23,0 s | 🟦 0,26 · 12,9 s | 🟦 0,45 · 17,0 s | 🟩 0,87 · 24,9 s | 🟩 1,89 · 38,0 s | 🟨 5,82 · 25,0 s | 🟥 40,6 · 17,8 s |
| Équipé | 🟩 0,97 · 18,6 s | 🟦 0,26 · 13,2 s | 🟦 0,43 · 29,0 s | 🟩 0,73 · 57,3 s | 🟩 1,79 · 47,1 s | 🟥 8,67 · 32,5 s | 🟥 42,9 · 21,7 s |
| Sur-équipé | 🟩 0,69 · ∞ s | 🟦 0,18 · 104 s | 🟦 0,30 · 188 s | 🟩 0,70 · 116 s | 🟩 1,70 · 68,0 s | 🟨 7,08 · 27,8 s | 🟥 34,7 · 20,5 s |

Case : verdict, coups pour tuer un grunt, secondes de survie.

<details><summary>Détail</summary>

| profil | zone | niveau | compétence | coups grunt | coups caster | coups colosse | s grunt | s colosse | survie |
|---|---|---|---|---|---|---|---|---|---|
| Débutant | 1 | 1 | Frappe lourde | 0,94 | 0,62 | 1,87 | 0,53 | 1,05 | 4,68 |
| Débutant | 10 | 1 | Frappe lourde | 1,94 | 1,29 | 3,88 | 1,09 | 2,19 | 2,20 |
| Débutant | 20 | 1 | Frappe lourde | 4,13 | 2,75 | 8,25 | 2,32 | 4,64 | 1,39 |
| Débutant | 40 | 1 | Frappe lourde | 16,8 | 11,2 | 33,5 | 9,43 | 18,9 | 0,80 |
| Débutant | 60 | 1 | Frappe lourde | 62,7 | 41,8 | 125 | 35,3 | 70,5 | 0,56 |
| Débutant | 90 | 1 | Frappe lourde | 415 | 277 | 831 | 234 | 467 | 0,39 |
| Débutant | 120 | 1 | Frappe lourde | 2583 | 1722 | 5165 | 1453 | 2905 | 0,30 |
| Nu | 1 | 1 | Frappe lourde | 0,94 | 0,62 | 1,87 | 0,53 | 1,05 | 4,68 |
| Nu | 10 | 14 | Frappe lourde | 0,27 | 0,18 | 0,53 | 0,15 | 0,30 | 4,77 |
| Nu | 20 | 21 | Frappe lourde | 0,46 | 0,31 | 0,93 | 0,26 | 0,52 | 7,91 |
| Nu | 40 | 36 | Frappe lourde | 0,97 | 0,64 | 1,93 | 0,49 | 0,99 | 6,86 |
| Nu | 60 | 58 | Frappe lourde | 2,39 | 1,59 | 4,78 | 1,15 | 2,29 | 6,28 |
| Nu | 90 | 100 | Frappe lourde | 12,8 | 8,54 | 25,6 | 6,13 | 12,3 | 4,04 |
| Nu | 120 | 100 | Frappe lourde | 68,2 | 45,5 | 136 | 32,7 | 65,4 | 2,97 |
| Sous-équipé | 1 | 1 | Frappe lourde | 0,88 | 0,59 | 1,76 | 0,50 | 0,99 | 23,0 |
| Sous-équipé | 10 | 14 | Frappe lourde | 0,26 | 0,17 | 0,52 | 0,13 | 0,25 | 12,9 |
| Sous-équipé | 20 | 21 | Frappe lourde | 0,45 | 0,30 | 0,90 | 0,25 | 0,49 | 17,0 |
| Sous-équipé | 40 | 36 | Frappe lourde | 0,87 | 0,58 | 1,74 | 0,42 | 0,83 | 24,9 |
| Sous-équipé | 60 | 58 | Frappe lourde | 1,89 | 1,26 | 3,78 | 0,85 | 1,70 | 38,0 |
| Sous-équipé | 90 | 100 | Frappe lourde | 5,82 | 3,88 | 11,6 | 2,01 | 4,02 | 25,0 |
| Sous-équipé | 120 | 100 | Frappe lourde | 40,6 | 27,1 | 81,2 | 15,4 | 30,7 | 17,8 |
| Équipé | 1 | 1 | Frappe lourde | 0,97 | 0,65 | 1,94 | 0,46 | 0,92 | 18,6 |
| Équipé | 10 | 14 | Frappe lourde | 0,26 | 0,17 | 0,52 | 0,15 | 0,29 | 13,2 |
| Équipé | 20 | 21 | Frappe lourde | 0,43 | 0,29 | 0,86 | 0,23 | 0,46 | 29,0 |
| Équipé | 40 | 36 | Frappe lourde | 0,73 | 0,49 | 1,47 | 0,32 | 0,64 | 57,3 |
| Équipé | 60 | 58 | Frappe lourde | 1,79 | 1,19 | 3,58 | 0,82 | 1,63 | 47,1 |
| Équipé | 90 | 100 | Frappe lourde | 8,67 | 5,78 | 17,3 | 2,84 | 5,68 | 32,5 |
| Équipé | 120 | 100 | Frappe lourde | 42,9 | 28,6 | 85,8 | 17,7 | 35,4 | 21,7 |
| Sur-équipé | 1 | 1 | Frappe lourde | 0,69 | 0,46 | 1,37 | 0,32 | 0,65 | ∞ |
| Sur-équipé | 10 | 14 | Frappe lourde | 0,18 | 0,12 | 0,36 | 0,08 | 0,16 | 104 |
| Sur-équipé | 20 | 21 | Frappe lourde | 0,30 | 0,20 | 0,60 | 0,12 | 0,24 | 188 |
| Sur-équipé | 40 | 36 | Frappe lourde | 0,70 | 0,47 | 1,41 | 0,31 | 0,62 | 116 |
| Sur-équipé | 60 | 58 | Frappe lourde | 1,70 | 1,13 | 3,40 | 0,47 | 0,94 | 68,0 |
| Sur-équipé | 90 | 100 | Frappe lourde | 7,08 | 4,72 | 14,2 | 2,32 | 4,63 | 27,8 |
| Sur-équipé | 120 | 100 | Frappe lourde | 34,7 | 23,1 | 69,4 | 11,5 | 22,9 | 20,5 |

</details>

## Simulation

Non relancée : `tools/balance.sh calculation`.
