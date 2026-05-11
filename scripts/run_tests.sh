#!/bin/bash
set -e

# Get test directory from first argument
if [ -z "$1" ]; then
    echo "Error: Test directory not provided"
    echo "Usage: $0 <test_directory>"
    exit 1
fi
test_dir="$1"

failed_tests=()
echo "### ------------------------------------------------------------- ###"
while IFS= read -r test_file; do
    echo "Running test: $test_file"
    if ! pixi run mojo --Werror -D ASSERT=all -I src "$test_file" ; then
        failed_tests+=("$test_file")
    fi
    echo "### ------------------------------------------------------------- ###"
done < <(find "$test_dir" -name "*_test.mojo" -type f | sort)

if [ ${#failed_tests[@]} -gt 0 ]; then
    echo "Failed tests:"
    for failed_test in "${failed_tests[@]}"; do
        echo " - $failed_test"
    done
    exit 1
fi