#!/bin/bash
set -e

# This script builds the Rust library for macOS and copies it to the correct location.

# 1. Build the Rust library
(cd flutter_rust_lib && cargo build --release)

# 2. Define source and destination paths
RUST_LIB_NAME="libflutter_rust_lib.dylib"
RUST_LIB_SRC_PATH="flutter_rust_lib/target/release/$RUST_LIB_NAME"
DEST_PATH="$BUILT_PRODUCTS_DIR/$FRAMEWORKS_FOLDER_PATH"

# 3. Ensure the destination directory exists
mkdir -p "$DEST_PATH"

# 4. Copy the library to the app's Frameworks directory
cp "$RUST_LIB_SRC_PATH" "$DEST_PATH/"

# 5. Fix the library's install name so the app can find it at runtime
# This tells the dynamic linker to look for the library in the same directory as the executable.
install_name_tool -id "@rpath/$RUST_LIB_NAME" "$DEST_PATH/$RUST_LIB_NAME"
