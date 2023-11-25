#!/bin/bash
TODAY=$(date +%Y%m%d%H%m%S)

USER= # usuário
SERVER= #host

BACKUP_FILE_NAME="backup.$TODAY.txz"

ssh $USER@$SERVER ./spinarak.sh $BACKUP_FILE_NAME

scp $USER@$SERVER:$BACKUP_FILE_NAME $BACKUP_FILE_NAME