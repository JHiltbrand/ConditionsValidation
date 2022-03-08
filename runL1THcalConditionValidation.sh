#!/bin/bash

jobs_in_parallel=10
listFiles="listOfFiles.txt"
echo "==============================================="
echo "HOAsciiInput " $HOAsciiInput
echo "release_L1   " $release_L1
echo "NewLUTtag    " $NewLUTtag
echo "NewGT        " $NewGT
echo "dataset      " $dataset
echo "year         " $year
echo "nEvts        " $nEvts
echo "lumi_start   " $lumi_start
echo "tier2        " $tier2
echo "OldRun       " $OldRun
echo "lumi_end     " $lumi_end
echo "version_L1   " $version_L1
echo "OldLUTtag    " $OldLUTtag
echo "week         " $week
echo "run          " $run
echo "max_file_num " $max_file_num
echo "OldGT        " $OldGT
echo "NewRun       " $NewRun
echo "release_LUT  " $release_LUT
echo "outdir       " $outdir
echo "geometry     " $geometry
echo "arch_L1      " $arch_L1
echo "arch_LUT     " $arch_LUT
echo "jobs_in_parallel  " $jobs_in_parallel
echo "==============================================="
echo " "
echo "======================================================================================================================"
echo " LUT generation and validation"
echo "======================================================================================================================"
cd ..
scram -a $arch_LUT project $release_LUT
cd $release_LUT/src
eval `scram runtime -sh`
git cms-addpkg CaloOnlineTools/HcalOnlineDb
git cms-merge-topic -u akhukhun:xmldbformat
git cms-merge-topic -u Michael-Krohn:skip-ZDC-LUT-generation
sed -i "s/const std::map<int, std::shared_ptr<LutXml> > _zdc_lut_xml = getZdcLutXml( _tag, split_by_crate );/\/\/const std::map<int, std::shared_ptr<LutXml> > _zdc_lut_xml = getZdcLutXml( _tag, split_by_crate );/" 'CaloOnlineTools/HcalOnlineDb/src/HcalLutManager.cc'
sed -i "s/addLutMap( xml, _zdc_lut_xml );/\/\/addLutMap( xml, _zdc_lut_xml );/" 'CaloOnlineTools/HcalOnlineDb/src/HcalLutManager.cc'
scram b
cd CaloOnlineTools/HcalOnlineDb/test/
# changing the plotting parameters to zoom in on changes
echo "copying the new plotting parameters"
cp -f ../../../../../ConditionsValidation/LUTFigureParameters/PlotLUT.py PlotLUT.py
cp -f ../../../../../ConditionsValidation/LUTFigureParameters/HcalLutAnalyzer.cc ../plugins/HcalLutAnalyzer.cc
sed -n '34,35p' ../../../../../ConditionsValidation/LUTFigureParameters/PlotLUT.py
sed -n '141p' ../../../../../ConditionsValidation/LUTFigureParameters/HcalLutAnalyzer.cc
echo "finished copying the plotting parameters"
sed -n '34,35p' PlotLUT.py
sed -n '141p' ../plugins/HcalLutAnalyzer.cc
cd ../plugins
scram b clean
scram b
cd ../test

> cardPhysics.sh
echo GlobalTag=$NewGT >> cardPhysics.sh
echo Tag=$NewLUTtag >> cardPhysics.sh
echo Run=$NewRun >> cardPhysics.sh
echo OldTag=$OldLUTtag >> cardPhysics.sh
echo OldRun=$OldRun >> cardPhysics.sh
echo description='"validation"' >> cardPhysics.sh
echo HOAsciiInput=$HOAsciiInput >> cardPhysics.sh
echo O2OL1TriggerObjects=false >> cardPhysics.sh
echo O2OInputs=false >> cardPhysics.sh

> cardPhysics_gen_old.sh
echo GlobalTag=$OldGT >> cardPhysics_gen_old.sh
echo Tag=$OldLUTtag >> cardPhysics_gen_old.sh
echo Run=$OldRun >> cardPhysics_gen_old.sh
echo description='"validation"' >> cardPhysics_gen_old.sh
echo HOAsciiInput=$HOAsciiInput >> cardPhysics_gen_old.sh
echo O2OL1TriggerObjects=false >> cardPhysics_gen_old.sh
echo O2OInputs=false >> cardPhysics_gen_old.sh

echo 'cp ../../../../../ConditionsValidation/Tools/test.py .'
cp ../../../../../ConditionsValidation/Tools/test.py .
#python test.py $NewRun $NewLUTtag $NewGT $OldRun $OldLUTtag $OldGT
python test.py ${NewLUTtag} ${OldLUTtag}
echo 'eos ls /eos/cms/store/group/dpg_hcal/comm_hcal/chin/'
echo 'eos ls $outdir'
echo "======================================================"
eos ls $outdir
echo conditions/${NewLUTtag}
xrdcp -rf conditions/${NewLUTtag} $outdir/.

echo
echo " "
echo "======================================================================================================================"
echo " L1TriggerObjects Tag generation"
echo "======================================================================================================================"
ls conditions/$NewLUTtag/Deploy/
cp conditions/$NewLUTtag/Deploy/Gen_L1TriggerObjects_${NewLUTtag}.txt ../../..
cd ../../..
cp ../../ConditionsValidation/Tools/writetoSQL9x.csh .
chmod +x writetoSQL9x.csh
./writetoSQL9x.csh $geometry L1TriggerObjects Gen_L1TriggerObjects_${NewLUTtag}.txt Tag 1 HcalL1TriggerObjects.db
xrdcp -f HcalL1TriggerObjects.db $outdir/${NewLUTtag}/HcalL1TriggerObjects.db
echo 'eos ls /eos/cms/store/group/dpg_hcal/comm_hcal/chin/'
eos ls $outdir/${NewLUTtag}/.

echo " "
echo "====================================================================================================================="
echo " L1 rate validation"
echo "====================================================================================================================="
cd ../..
scram -a $arch_L1 project $release_L1

cd ${release_L1}/src
eval `scram runtime -sh`
git cms-init
git remote add cms-l1t-offline git@github.com:cms-l1t-offline/cmssw.git
git fetch cms-l1t-offline l1t-integration-${release_L1}
git cms-merge-topic -u cms-l1t-offline:l1t-integration-v${version_L1}
git clone https://github.com/cms-l1t-offline/L1Trigger-L1TCalorimeter.git L1Trigger/L1TCalorimeter/data
git cms-checkdeps -A -a
scram b -j 8
#----------------------------------------------------------------------------------------------------
git clone git@github.com:cms-hcal-trigger/Validation.git HcalTrigger/Validation
scram b -j 8
cd HcalTrigger/Validation/scripts

mkdir hcal_${run}_def
mkdir hcal_${run}_new_cond

cp ../../../../../ConditionsValidation/Tools/ntuple_maker_template.sh ./
cp ../../../../../$release_LUT/src/HcalL1TriggerObjects.db .
cp ../../../../../$release_LUT/src/HcalL1TriggerObjects.db ./hcal_${run}_def
cp ../../../../../$release_LUT/src/HcalL1TriggerObjects.db ./hcal_${run}_new_cond
ls
if [[ $lumiblock == \#* ]]
then
  :
else
  echo "{\"$run\": [[$lumi_start,$lumi_end]]}" > ./lumimask.txt
  lumimask="../../lumimask.txt"
fi

dasgoclient -query="file dataset=${dataset} run=${run}" > $listFiles
n=0
for file in `less ./${listFiles}`
do
  n=$[$n+1]
  echo "$n. $file"
  if (( "$n" <= "$max_file_num" )) || (( "$max_file_num" < 0 ))
  then
    numfolder=(`find ./hcal_${run}_def/  -maxdepth 1 -name "ntuple_maker_*" -type d | wc -l`)
    mkdir -p ./hcal_${run}_def/ntuple_maker_$numfolder && mkdir -p ./hcal_${run}_new_cond/ntuple_maker_$numfolder
    sh ./ntuple_maker_template.sh default $n $nEvts Run3 $NewGT root://cms-xrd-global.cern.ch//$file $lumimask && mv ntuple_maker_def_$n.py ./hcal_${run}_def/ntuple_maker_$numfolder
    sh ./ntuple_maker_template.sh new_con $n $nEvts Run3 $NewGT root://cms-xrd-global.cern.ch//$file $lumimask && mv ntuple_maker_new_$n.py ./hcal_${run}_new_cond/ntuple_maker_$numfolder
    ( cd ./hcal_${run}_def/ntuple_maker_$numfolder && cmsRun ntuple_maker_def_$n.py && mv L1Ntuple.root ../L1Ntuple_$n.root ) & ( cd ./hcal_${run}_new_cond/ntuple_maker_$numfolder && cmsRun ntuple_maker_new_$n.py && mv L1Ntuple.root ../L1Ntuple_$n.root ) &
#    wait
    if [ $(jobs | wc -l) -ge $jobs_in_parallel ]; then
      echo "Waiting for background processes to finish ..."
      wait
      rm -r ./hcal_${run}_def/ntuple_maker_*
      rm -r ./hcal_${run}_new_cond/ntuple_maker_*
    fi
  else
    break
  fi
done

echo "Waiting for background processes to finish ..."
wait

cp ../../../../../ConditionsValidation/Tools/runcrab3.csh .
source runcrab3.csh

#------------------------------------------------------------------------------------
#Submit and retrieve jobs from CRAB
cp ../../../../../ConditionsValidation/Tools/ntuple_maker_def.py .
cmsRun ntuple_maker_def.py
cp submit_def.py $outdir
crab submit submit_def.py
crab preparelocal --dir='crab_hcal_325170_def'
cp -r crab_hcal_325170_def $outdir

cp ntuple_maker_def.py $outdir
source /cvmfs/cms.cern.ch/crab3/crab.sh


crab submit submit_def.py
crab submit submit_new_cond.py
cp crab_hcal_325170_new_cond/crab.log ${outdir}/${NewLUTtag}
cp crab_hcal_325170_def/crab.log ${outdir}/${NewLUTtag}
crab status -d crab_hcal_${run}_def
crab status -d crab_hcal_${run}_def > status_def.log
while ! grep -q "finished" status_def.log; do
   if grep -q "failed" status_def.log; then
       crab resubmit -d crab_hcal_${run}_def
   fi
   sleep 180
   crab status -d crab_hcal_${run}_def > status_def.log
done

crab status -d crab_hcal_${run}_new_cond > status_new_cond.log
while ! grep -q "finished" status_new_cond.log; do
   if grep -q "failed" status_new_cond.log; then
       crab resubmit -d crab_hcal_${run}_new_cond
   fi
   sleep 180
   crab status -d crab_hcal_${run}_new_cond > status_new_cond.log
done

crab getoutput -d crab_hcal_${run}_def --checksum=no > retrieve_def.log
while ! grep -q "All files successfully retrieved" retrieve_def.log; do
   crab getoutput -d crab_hcal_${run}_def --checksum=no > retrieve_def.log
done

crab getoutput -d crab_hcal_${run}_new_cond --checksum=no > retrieve_new_cond.log
while ! grep -q "All files successfully retrieved" retrieve_new_cond.log; do
   crab getoutput -d crab_hcal_${run}_new_cond --checksum=no > retrieve_new_cond.log
done

# ------------------------------------------------------------------------------------

rates.exe def ./hcal_${run}_def/
rates.exe new ./hcal_${run}_new_cond/
mkdir plots
draw_rates.exe
xrdcp -rf plots ${outdir}/${NewLUTtag}/.
