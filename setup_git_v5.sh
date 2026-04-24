#!/bin/bash

project=$(basename `pwd`)
echo "-----------------------------------------------------------------------------"
echo "this is project https://github.com/limalinuxos/"$project
echo "-----------------------------------------------------------------------------"
git config  pull.rebase false
git config  user.name "limalinuxos"
git config  user.email "limalinuxos@proton.me"
sudo git config --system core.editor nano
git config  push.default simple

git remote set-url origin git@github.com:limalinuxos/$project

echo "Everything set"

echo
tput setaf 6
echo "##############################################################"
echo "###################  $(basename $0) done"
echo "##############################################################"
tput sgr0
echo
