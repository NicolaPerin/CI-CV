#!/bin/bash
set -e

LANG="$1"
PHOTO="$2"
VARIANT_DIR="${LANG}-${PHOTO}"

# Make PHOTO_FILE an absolute path for rendercv to find it
if [ -n "$PHOTO_FILE" ]; then
    export PHOTO_FILE="/cv/${PHOTO_FILE}"
fi

# Use unique temp directory per variant to avoid collisions
WORK_DIR="/tmp/build_${VARIANT_DIR}"
mkdir -p "$WORK_DIR"

TMP_YAML="${WORK_DIR}/cv.yaml"
FINAL_YAML="${WORK_DIR}/cv.final.yaml"

# Start with base
cp cv/base.yaml "$TMP_YAML"

# Merge content for this language
yq eval-all 'select(fileIndex == 0) * select(fileIndex == 1)' \
    "$TMP_YAML" "cv/overlays/content-${LANG}.yaml" > "${TMP_YAML}.tmp"
mv "${TMP_YAML}.tmp" "$TMP_YAML"

# Merge language/locale overlay
yq eval-all 'select(fileIndex == 0) * select(fileIndex == 1)' \
    "$TMP_YAML" "cv/overlays/lang-${LANG}.yaml" > "${TMP_YAML}.tmp"
mv "${TMP_YAML}.tmp" "$TMP_YAML"

# Merge photo overlay if needed
if [ "$PHOTO" = "with-photo" ]; then
    yq eval-all 'select(fileIndex == 0) * select(fileIndex == 1)' \
        "$TMP_YAML" cv/overlays/photo.yaml > "${TMP_YAML}.tmp"
    mv "${TMP_YAML}.tmp" "$TMP_YAML"
fi

# Substitute environment variables
envsubst < "$TMP_YAML" > "$FINAL_YAML"

# Debug: show what we're rendering
echo "=== Building ${VARIANT_DIR} ==="
echo "PHOTO_FILE=${PHOTO_FILE}"
grep -E "^  photo:" "$FINAL_YAML" || echo "No photo field found"

# Render - output to /cv which is the mounted volume
mkdir -p "/cv/rendercv_output/${VARIANT_DIR}"
rendercv render "$FINAL_YAML" \
    --pdf-path "/cv/rendercv_output/${VARIANT_DIR}/Nicola_Perin_CV.pdf" \
    --dont-generate-html \
    --dont-generate-markdown \
    --dont-generate-png

# Cleanup
rm -rf "$WORK_DIR"