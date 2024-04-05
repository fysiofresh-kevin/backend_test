#!/bin/bash

# Initialize reset flag and mode
reset=0
mode=""

# Check if no arguments were provided
if [ $# -eq 0 ]; then
    echo "No arguments provided. Please use --integration, --unit, or --reset flag."
    exit 1
fi

# First pass to set flags based on arguments
for arg in "$@"; do
    case $arg in
    --reset)
        reset=1
        ;;
    --integration)
        mode="integration"
        ;;
    --unit)
        mode="unit"
        ;;
    esac
done

# Handle the reset functionality
if [ $reset -eq 1 ]; then
    if [ "$mode" = "integration" ]; then
        echo "Resetting environment for integration tests..."
        # Reset actions for integration tests
        (cd automation && python3 concat-ext-and-seed-files.integration.py && cd ..)
        npx supabase db reset
    elif [ "$mode" = "unit" ]; then
        echo "Resetting environment for unit tests..."
        # Reset actions for unit tests
        (cd automation && python3 concat-ext-and-seed-files.unit.py && cd ..)
        npx supabase db reset
    else
        echo "The --reset flag requires either --integration or --unit to specify the test type."
        exit 1
    fi
fi

# Second pass to execute tests based on mode
for arg in "$@"; do
    case $arg in
    --integration)
        echo "Running integration tests..."
        deno test --allow-net --allow-env --env=.env.local --config functions/deno.integration.json
        ;;
    --unit)
        echo "Running unit tests..."
        deno test --allow-env --env=.env.local --config functions/deno.unit.json
        ;;
    esac
done
