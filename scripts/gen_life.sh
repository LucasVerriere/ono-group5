#!/bin/bash
# scripts/gen_life.sh
# Usage: ./scripts/gen_life.sh [> sortie.life]
#
# Lit automatiquement w et h dans constraints.wat, puis lance Owi
# et convertit le modèle en .life via to_life.ml.

set -e

SCRIPT_PATH="$(readlink -f "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
WAT_FILE="$PROJECT_ROOT/test/cram/symbolic/configuration_gen.t/constraints.wat"
TO_LIFE="$SCRIPT_DIR/to_life.ml"

# Extrait la valeur (i32.const N) déclarée pour une globale donnée
extract_global() {
  local name=$1
  grep -E "global \\\$$name " "$WAT_FILE" \
    | grep -oE "i32\.const +[0-9]+" \
    | grep -oE "[0-9]+\$" \
    | head -1
}

W=$(extract_global "w")
H=$(extract_global "h")

if [ -z "$W" ] || [ -z "$H" ]; then
  echo "Erreur : impossible d'extraire w et h depuis $WAT_FILE" >&2
  exit 1
fi

cd "$PROJECT_ROOT"
dune exec -- ono symbolic "$WAT_FILE" 2>&1 \
  | ocaml -I +str str.cma "$TO_LIFE" "$W" "$H"