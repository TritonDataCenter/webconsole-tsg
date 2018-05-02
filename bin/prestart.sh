#!/bin/bash

eval `/usr/bin/ssh-agent -s`
mkdir -p ~/.ssh
echo -e "${SDC_KEY_PUB}" | tr '#' '\n' > ~/.ssh/id_rsa.pub
echo -e "${SDC_KEY}" | tr '#' '\n' > ~/.ssh/id_rsa
chmod 400 ~/.ssh/id_rsa.pub
chmod 400 ~/.ssh/id_rsa
ssh-add ~/.ssh/id_rsa
