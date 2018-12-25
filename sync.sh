#! /bin/bash

rsync -e ssh ./**/*.lua we@$1:~/dust/scripts/jared/
