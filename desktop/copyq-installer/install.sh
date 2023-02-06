#!/bin/bash

sudo add-apt-repository ppa:hluk/copyq
sudo apt update
sudo apt install copyq
echo "Setting Up config"
cp -r copyq ~/.config/copyq
alias tekab='echo "test"'