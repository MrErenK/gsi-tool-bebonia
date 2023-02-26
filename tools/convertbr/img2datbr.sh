#!/bin/bash

# Copyright (C) 2020 Xiaoxindada <2245062854@qq.com>

LOCALDIR=`cd "$( dirname ${BASH_SOURCE[0]} )" && pwd`
cd $LOCALDIR
source ./bin.sh

image="$1"
image_name=$(echo ${image##*/} | sed 's/\.img//')
make_br="false"

[ ! -e $image ] && echo "Couldnt find gsi image: $image" && exit

function img2simg() {
  rimg_file="$image"
  simg_file=$(echo "${image%%.*}" | sed 's/$/&s\.img/')
  $bin/img2simg "$rimg_file" "$simg_file"
  if [ $? != "0" ];then
   echo "Error!"
  else
    mv -f $simg_file $bin/img2sdat/${image_name}.img
  fi
}

function simg2sdat() {
  if [ ! -f $bin/img2sdat/${image_name}.img ];then
    cp -frp $image $bin/img2sdat/${image_name}.img
  fi
  cd $bin/img2sdat
  rm -rf ./output
  mkdir ./output
  file ${image_name}.img
  python3 ./img2sdat.py "${image_name}.img" -o "output" -v "4" -p "$image_name"
  if [ $? != "0" ];then
    echo "Error!"
    rm -rf ${image_name}.img
    exit
  else
    rm -rf ${image_name}.img
    cd $LOCALDIR
    rm -rf ./new_dat
    mkdir ./new_dat
    mv $bin/img2sdat/output/* ./new_dat/
  fi
}

function sdat2sdat_br() {
  $bin/brotli -q 0 $LOCALDIR/new_dat/${image_name}.new.dat -o $LOCALDIR/new_dat/${image_name}.new.dat.br
  if [ $? != "0" ] ;then
    echo "Error!"
    exit
   else
    echo "Created dat.br! Path: $LOCALDIR/new_dat/${image_name}.new.dat.br. Cleaning up..."
    cd $LOCALDIR/new_dat/
    rm -f ${image_name}.new.dat
    cd $LOCALDIR
  fi
}

if ! (file $image | grep -qo "sparse") ;then
  img2simg
fi

simg2sdat
sdat2sdat_br
