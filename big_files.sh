#!/bin/bash

d=$1
f=$2
sudo du -a $1 | sort -n -r | head -n 10  > $2

echo "top 10 big files in  $1  directory is stored in $2 file"




