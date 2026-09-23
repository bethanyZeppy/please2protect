#!/bin/bash
rm -rf src-tauri/target/
rm -rf ~/.cargo/registry/
rm -rf ~/.cargo/git/
rm -f package-lock.json
rm -f src-tauri/Cargo.lock
cargo tauri dev
