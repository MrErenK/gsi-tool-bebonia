#!/bin/bash

TOOLDIR="$(readlink -f -- $(pwd))"
export bin=$TOOLDIR/tool_bin
