#!/usr/bin/env bash
# run_tests.sh — Build and run Mojo test files with AddressSanitizer enabled.
#
# Usage:
#   ./test/run_tests.sh <test_directory>   # Run all test_*.mojo files in a directory
#   ./test/run_tests.sh <test_file.mojo>   # Run a single test file
#
# Each test file is compiled with debug info, all assertions, and AddressSanitizer,
# then executed via `script` so it runs in a PTY. This preserves ASAN's colored
# output while also capturing it to check for ASAN error messages.
#
# Binaries are placed in .build/ and removed after each test run.
# The script exits with code 1 if any test fails to build, exits non-zero,
# or produces output containing both "ERROR:" and "AddressSanitizer".
#
# To disable AddressSanitizer for a specific test file, add the following
# comment anywhere in that file:
#
#   # SKIP_ASAN
set -e

# Get test directory or file from first argument
if [ -z "$1" ]; then
    echo "Error: Test directory or file not provided"
    echo "Usage: $0 <test_directory|test_file.mojo>"
    exit 1
fi

any_failed=false

# Directory for compiled test binaries; cleaned up per-test after execution.
build_dir=".build"
mkdir -p "$build_dir"

# Locate the ASAN runtime from the pixi environment. This is needed because the
# system clang's ASAN library may be a different version than the one used to
# compile the binaries, causing symbol lookup errors at link or runtime.
platform=$(uname -s)
arch=$(uname -m)
asan_lib=""
asan_preload_var=""
asan_install_hint="Install a compatible compiler-rt package in .pixi/envs/test."
asan_build_args=()

case "$platform:$arch" in
    Darwin:arm64)
        asan_lib=$(find .pixi/envs/test -name "libclang_rt.asan_osx_dynamic.dylib" 2>/dev/null | head -1 || true)
        asan_preload_var="DYLD_INSERT_LIBRARIES"
        asan_install_hint="Install it with: pixi add compiler-rt --platform osx-arm64"
        ;;
    Linux:x86_64)
        asan_lib=$(find .pixi/envs/test -name "libclang_rt.asan-x86_64.so" 2>/dev/null | head -1 || true)
        asan_preload_var="LD_PRELOAD"
        asan_install_hint="Install it with: pixi add compiler-rt --platform linux-64"
        ;;
esac

if [ -n "$asan_lib" ]; then
    asan_build_args=(--external-libasan "$asan_lib")
fi

echo "### ------------------------------------------------------------- ###"

# Collect test files: either the single file provided, or all test_*.mojo files
# found recursively under the given directory.
if [ -f "$1" ]; then
    test_files=("$1")
else
    mapfile -t test_files < <(find "$1" -name "*_test.mojo" -type f | sort)
fi

failed_tests=()

for test_file in "${test_files[@]}"; do
    echo "Running test: $test_file"
    binary="$build_dir/$(basename "${test_file%.mojo}")"

    # Check if this test opts out of AddressSanitizer via a "# SKIP_ASAN" comment.
    if grep -q "# SKIP_ASAN" "$test_file"; then
        use_asan=false
    else
        use_asan=true
    fi

    # Build the test binary, with or without AddressSanitizer instrumentation.
    if [ "$use_asan" = true ]; then
        if [ -z "$asan_lib" ]; then
            echo "Error: compatible ASAN runtime not found for $platform/$arch"
            echo "$asan_install_hint"
            failed_tests+=("$test_file")
            echo "### ------------------------------------------------------------- ###"
            continue
        fi
        build_cmd=(pixi run mojo build -g --Werror -D ASSERT=all --sanitize address "${asan_build_args[@]}" -I src "$test_file" -o "$binary")
    else
        build_cmd=(pixi run mojo build -g --Werror -D ASSERT=all -I src "$test_file" -o "$binary")
    fi
    if ! "${build_cmd[@]}" ; then
        failed_tests+=("$test_file")
        echo "### ------------------------------------------------------------- ###"
        continue
    fi

    if [ "$use_asan" = true ]; then
        # Run the binary inside `script` to allocate a PTY, so ASAN auto-enables
        # colored output. The typescript file is only used for ASAN error detection
        # and is removed immediately after.
        tmpout=$(mktemp)
        runner=$(mktemp)
        printf "#!/bin/sh\n%s='%s' pixi run '%s'\n" "$asan_preload_var" "$asan_lib" "$binary" > "$runner"
        chmod +x "$runner"
        set +e
        if [ "$platform" = "Darwin" ]; then
            script -q -e "$tmpout" "$runner"
        else
            script -q -e -c "$runner" "$tmpout"
        fi
        run_exit=$?
        set -e
        rm -f "$runner"

        # Fail if the binary exited non-zero or if ASAN reported an error.
        if [ $run_exit -ne 0 ] || { grep -q "ERROR:" "$tmpout" && grep -q "AddressSanitizer" "$tmpout"; }; then
            failed_tests+=("$test_file")
        fi
        rm -f "$tmpout"
    else
        # Run without ASAN preload.
        set +e
        pixi run "$binary"
        run_exit=$?
        set -e
        if [ $run_exit -ne 0 ]; then
            failed_tests+=("$test_file")
        fi
    fi

    rm -f "$binary"
    echo "### ------------------------------------------------------------- ###"
done

if [ ${#failed_tests[@]} -gt 0 ]; then
    echo "Failed tests:"
    for failed_test in "${failed_tests[@]}"; do
        echo " - $failed_test"
    done
    exit 1
fi
