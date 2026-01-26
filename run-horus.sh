#!/usr/bin/env bash

# Run Horus viewer with optional image path argument
# Usage: ./run-horus.sh [image_path]
# Default: ./run-horus.sh (uses output.png)

julia --project=. run-horus.jl "$@"
