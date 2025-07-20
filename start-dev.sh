#!/bin/bash

source /root/perl5/perlbrew/etc/bashrc

# cpanfile.snapshot が存在しない場合のみ carton install を実行
[ ! -f cpanfile.snapshot ] && carton install

carton exec plackup -r -p 5000