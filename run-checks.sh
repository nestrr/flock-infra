#!/bin/bash
export PYTHONPATH="./helpers:$PYTHONPATH"
DIRS_TO_CHECK=$(python -m get_tf_dirs)
echo "$DIRS_TO_CHECK"
for dir in $DIRS_TO_CHECK;
do
  just tf-checks check "$dir"
done