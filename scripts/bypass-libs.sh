#!/bin/bash
# Bypass library dependency checks for precompiled binaries

if [ -f "$1/CONTROL/control" ]; then
    grep -v "libc\.so\|libm\.so\|libpthread\.so\|librt\.so" "$1/CONTROL/control" > "$1/CONTROL/control.tmp"
    mv "$1/CONTROL/control.tmp" "$1/CONTROL/control"
fi
