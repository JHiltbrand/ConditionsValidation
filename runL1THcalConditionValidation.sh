#!/bin/bash 

cd ..
export CMSREL=CMSSW_10_4_0_pre1
export SCRAM_ARCH=slc6_amd64_gcc630
scram -a $SCRAM_ARCH project $CMSREL
cd CMSSW_10_4_0_pre1/src
cmsenv
git cms-addpkg CaloOnlineTools/HcalOnlineDb
scram b -j 16
cd CaloOnlineTools/HcalOnlineDb/test
cp /afs/cern.ch/user/c/cawest/public/forGilson/test.py .
python test.py
