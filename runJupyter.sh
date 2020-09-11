#!/bin/bash

echo

# directory with notebooks
OLDNOTEDIR=/usr/local/share/notebooks
# working directory
WORKDIR=$PWD
# directory to store notebooks on host system
NEWNOTEDIR=$WORKDIR/notebooks

# create directory for notebooks if not present
if [ ! -d "$NEWNOTEDIR" ]; then
  mkdir $NEWNOTEDIR
fi

# copy notebooks if not already present
cd $OLDNOTEDIR
cp README $NEWNOTEDIR
for notebook in $(ls *.ipynb); do
  if [ ! -f "$NEWNOTEDIR"/"$notebook" ]; then
    echo "   Copying notebook "$notebook" to "$NEWNOTEDIR"!"
    cp $notebook $NEWNOTEDIR
  else
    echo "   Notebook "$notebook" already exists in "$NEWNOTEDIR"!"
  fi
done

cd $WORKDIR

# build custom Rivet analyses
RIVETFILES=""
RIVETDATADIR="/usr/local/share/Rivet"
for ccfile in $(ls *.cc 2> /dev/null); do
  if [ $(grep -i "rivet" $ccfile | wc -l) != "0" ]; then
    echo "   Found custom Rivet analysis "$ccfile"."
    RIVETFILES=$RIVETFILES" "$ccfile
  fi
done
if [ "$RIVETFILES" == "" ]; then
  echo "   No custom Rivet analyses found!"
else
  echo "   Building library for custom Rivet analyses!"
  rivet-buildplugin RivetCustomAnalyses.so $RIVETFILES
  export RIVET_ANALYSIS_PATH=$RIVET_ANALYSIS_PATH:$WORKDIR
  export RIVET_REF_PATH=$RIVET_REF_PATH:$WORKDIR
  export RIVET_INFO_PATH=$RIVET_INFO_PATH:$WORKDIR
  export RIVET_DATA_PATH=$RIVET_DATA_PATH:$WORKDIR
  export RIVET_PLOT_PATH=$RIVET_PLOT_PATH:$WORKDIR
  echo "   Copying yoda files (assuming it is data) to"$RIVETDATADIR"."
  cp *yoda $RIVETDATADIR 2> /dev/null
fi

# export path for LHAPDF
export LHAPDF_DATA_PATH=$LHAPDF_DATA_PATH:$WORKDIR

# set home directory and export paths for Jupyter
export HOME=/home/jupyter
mkdir -p $HOME/.jupyter
export JUPYTER_CONFIG_DIR=$HOME/.jupyter
export JUPYTER_PATH=$HOME/.jupyter
export JUPYTER_RUNTIME_DIR=$HOME/.jupyter

# start jupter
echo "   Starting jupyter in location "$NEWNOTEDIR"!"
echo
jupyter notebook --allow-root --ip 0.0.0.0 --port 8888 --no-browser $NEWNOTEDIR
