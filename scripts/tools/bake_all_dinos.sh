#!/bin/bash
# Bake every textured Meshy dino model into an in-game 3D fighter sheet.
#
#   bash scripts/tools/bake_all_dinos.sh [dino ...]      # default: whole roster
#
# For each dino with a textured model, renders the 9 frames in Blender, packs the
# sheet to assets/sprites/<dino>_fighter_3d.png, and collects the ANIM_LAYOUTS
# blocks into /tmp/dino3d_layouts.txt to paste into dino.gd. Idempotent.
set -e
cd "$(dirname "$0")/../.."
BLENDER=/opt/homebrew/bin/blender
DINOS=("$@"); [ ${#DINOS[@]} -eq 0 ] && DINOS=(ralph raptor trike pterry bronto anky)
LAYOUTS=/tmp/dino3d_layouts.txt; : > "$LAYOUTS"

for d in "${DINOS[@]}"; do
  glb="assets/concept/$d/${d}_model.glb"
  if [ ! -f "$glb" ] || [ "$(stat -f%z "$glb")" -lt 10000000 ]; then
    echo "!! $d: no textured model -- skipping"; continue
  fi
  echo "== baking $d =="
  "$BLENDER" --background --python scripts/tools/blender_render_dino.py -- \
    --dino "$d" --out "/tmp/bake/$d" --model "$glb" 2>&1 | grep -iE "RENDERED|error|traceback" || true
  python3 scripts/tools/pack_dino_sheet.py --dino "$d" \
    --frames "/tmp/bake/$d" --out "assets/sprites/${d}_fighter_3d.png" --preview \
    | tee -a "$LAYOUTS"
done
echo ""
echo "ALL LAYOUTS collected in $LAYOUTS"
