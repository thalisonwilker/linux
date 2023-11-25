#!/bin/bash
# https://www.pokemon.com/br/pokedex/spinarak
# With threads from its mouth, it fashions sturdy webs that won’t break even if you set a rock on them

BACKUP_FILE_NAME=$1

tar Jcf $BACKUP_FILE_NAME /var/log/auth.log
