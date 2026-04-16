#!/bin/bash

project=$(basename `pwd`)
echo "-----------------------------------------------------------------------------"
echo "this is project https://github.com/limalinuxos/"$project
echo "-----------------------------------------------------------------------------"
git config --global pull.rebase false
git config --global user.name "limalinuxos"
git config --global user.email "limalinuxos@proton.me"
sudo git config --system core.editor nano
git config --global push.default simple

git remote set-url origin git@github.com:limalinuxos/$project

echo "Everything set"

echo
tput setaf 6
echo "##############################################################"
echo "###################  $(basename $0) done"
echo "##############################################################"
tput sgr0
echo
