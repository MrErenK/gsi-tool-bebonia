#!/bin/bash

TOOLDIR=`cd $( dirname ${BASH_SOURCE[0]} ) && pwd`
HOST=$(uname)
platform=$(uname -m)
export bin=$TOOLDIR/tool_bin
export LD_LIBRARY_PATH=$bin/Linux/x86_64/lib64
