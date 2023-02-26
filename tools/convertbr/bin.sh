#!/bin/bash

TOOLDIR="$(readlink -f -- $(pwd))"
export bin=$TOOLDIR/tool_bin
export LD_LIBRARY_PATH=$bin/Linux/x86_64/lib64
