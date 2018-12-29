#! /bin/bash
emacsclient -e '(progn (find-file "./sequencer/sequencer.org") (org-babel-tangle))'

rsync -e ssh ./**/*.lua we@$1:~/dust/scripts/jared/
