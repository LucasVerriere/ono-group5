# Changes

# 2.0.0 - 2026-05-15

## Added

### Interface graphique :

- Flag `--use-graphical-window` pour lancer le simulateur via Raylib
- Pause avec la touche espace
- Flag `--end-pause` : pause automatique sur la dernière étape
- Flag `--sleep FLOAT`

### Interface textuelle :

- Flag `--steps INT`
- Flag `--file PATH`
- `read_int` pour la saisie interactive des dimensions de la grille au démarrage
- Format de fichier `.life` pour les configurations initiales

### Interpréteur symbolique :

- Solveur de polynômes
- `constraints.wat` : primitives du Jeu de la Vie réécrites sans if symboliques (expressions i32.and/i32.or pures), 17 contraintes implémentées, initialisation symbolique de toute la grille
- `to_life.ml` : conversion de la sortie model { ... } d'Owi en fichier .life
- `gen_life.sh` : wrapper qui automatise tout le pipeline

- `REPORT.md` : rapport complet du projet

# 1.0.0 - 2026-02-19

## Added

- `CONTACTS.md`
- Pre-commit hook Git pour le formatage automatique des messages de commit
- Module Wasm `factorial` avec cram test
- Fonction OCaml `print_i64` et module Wasm `square_i64` avec cram test
- Fonction OCaml `random_i32` avec option `--seed INT`, Random.self_init en l'absence de seed
- Début interface textuelle

## Changed

- Ajout de f32 et f64 dans owi.mli

[2.0.0]: https://github.com/LucasVerriere/ono-group5/compare/1.0.0...2.0.0
[1.0.0]: https://github.com/LucasVerriere/ono-group5/releases/tag/1.0.0
