#!/bin/sh

# top merlin directory
merlin_dir="/afs/inf.ed.ac.uk/group/cstr/projects/phd/s1432486/work/test/merlin"

# tools directory
world="${merlin_dir}/tools/WORLD/build"
sptk="${merlin_dir}/tools/SPTK-3.7/bin"

# input audio directory
wav_dir="${merlin_dir}/dnn_baseline_practice/cmu_us_slt_arctic/wav"

# Output features directory
out_dir="${merlin_dir}/dnn_baseline_practice/cmu_us_slt_arctic/data"

sp_dir="${out_dir}/sp"
mgc_dir="${out_dir}/mgc"
ap_dir="${out_dir}/ap"
bap_dir="${out_dir}/bap"
f0_dir="${out_dir}/f0"
lf0_dir="${out_dir}/lf0"

mkdir -p ${out_dir}
mkdir -p ${sp_dir}
mkdir -p ${mgc_dir}
mkdir -p ${bap_dir}
mkdir -p ${f0_dir}
mkdir -p ${lf0_dir}

# initializations
fs=16000

if [ "$fs" -eq 16000 ]
then
nFFTHalf=1024 
alpha=0.58
fi

if [ "$fs" -eq 48000 ]
then
nFFTHalf=2048
alpha=0.77
fi

mcsize=59
order=1

for file in $wav_dir/*.wav #.wav
do
    filename="${file##*/}"
    file_id="${filename%.*}"
   
    echo $file_id
   
    ### WORLD ANALYSIS -- extract vocoder parameters ###

    ### extract f0, sp, ap ### 
    $world/analysis ${wav_dir}/$file_id.wav ${f0_dir}/$file_id.f0 ${sp_dir}/$file_id.sp ${bap_dir}/$file_id.ap

    ### convert f0 to lf0 ###
    $sptk/x2x +da ${f0_dir}/$file_id.f0 > ${f0_dir}/$file_id.f0a
    $sptk/x2x +af ${f0_dir}/$file_id.f0a | $sptk/sopr -magic 0.0 -LN -MAGIC -1.0E+10 > ${lf0_dir}/$file_id.lf0
    
    ### convert sp to mgc ###
    $sptk/x2x +df ${sp_dir}/$file_id.sp | $sptk/sopr -R -m 32768.0 | $sptk/mcep -a $alpha -m $mcsize -l $nFFTHalf -e 1.0E-8 -j 0 -f 0.0 -q 3 > ${mgc_dir}/$file_id.mgc

     ### convert ap to bap ###
    $sptk/x2x +df ${bap_dir}/$file_id.ap | $sptk/sopr -R -m 32768.0 | $sptk/mcep -a $alpha -m $order -l $nFFTHalf -e 1.0E-8 -j 0 -f 0.0 -q 3 > ${bap_dir}/$file_id.bap

done

rm -rf $sp_dir 
rm -rf $f0_dir
rm -rf $bap_dir/*.ap
