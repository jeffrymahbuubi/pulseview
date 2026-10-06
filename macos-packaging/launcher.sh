#!/bin/bash
DIR="$(cd "$(dirname "$0")" && pwd)"
C="$(dirname "$DIR")"
export PYTHONHOME="$C/Resources/python"
export PYTHONDONTWRITEBYTECODE=1
export SIGROKDECODE_DIR="$C/Resources/decoders"
exec "$DIR/pulseview-bin" "$@"
