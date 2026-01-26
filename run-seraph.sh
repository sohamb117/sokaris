#!/usr/bin/env bash

# Run Seraph viewer with optional image path argument
# Usage: ./run-seraph.sh [image_path]
# Default: ./run-seraph.sh (uses output.png)

julia --project=. run-seraph.jl "$@"
