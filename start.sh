#!/bin/bash

if [ -z $SCA_SERVICE_DIR ]; then SCA_SERVICE_DIR=/tmp; fi

#make sure jq is installed on $SCA_SERVICE_DIR
if [ ! -f $SCA_SERVICE_DIR/jq ];
then
        echo "installing jq"
        wget https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 -O $SCA_SERVICE_DIR/jq
        chmod +x $SCA_SERVICE_DIR/jq
fi


echo "creating symlink for each input directories"
for key in `jq -r '.inputs | keys[]' config.json`; do
    src=$(jq -r ".inputs[\"$key\"]" config.json)
    ln -s $src $key
done

#pull parameters
container=`jq -r '.container' config.json`
arguments=`jq -r '.arguments' config.json`
uid=`id -u`
gid=`id -g`

#TODO - it's very important to validate the container and arguments so that user won't escape out of docker command line
#TODO - like disallow any character except alpha, number and '/' in container name, and no ';' '>', etc.. in arguments

#echo "writing out preprocessing script"
#$SCA_SERVICE_DIR/jq -r '.bash' config.json > pre.sh
#chmod +x pre.sh 
#echo "executing preprocessing script"
#./pre.sh

#mount for input directories
mount=""
for key in `jq -r '.inputs | keys[]' config.json`; do
    src=$(jq -r ".inputs[\"$key\"]" config.json)
    mount="$mount -v `pwd`/$src:/input/$key:ro"
done

#mount for output directories
mkdir output #need to do this so that docker(root) won't end up creating this for me
mount="$mount -v `pwd`/output:/output"

cmd="docker run --rm -t -u $uid:$gid $mount $container $arguments"
echo $cmd

rm -f finished
(
eval $cmd > stdout.log 2> stderr.log
echo $? > finished 
echo "[]" > products.json
) &

