#!/bin/bash
make_line
echo "Constructing summary presentations"
make_line

cd $BASE_PATH/ConditionsValidation

python3 -m venv env
source env/bin/activate
python3 -m PostAnalysis configuration/post_conf.py
