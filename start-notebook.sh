#!/bin/bash

#!/bin/bash

set -e

# Exec the specified command or fall back on bash
if [ $# -eq 0 ]; then
    cmd=bash
else
    cmd=$*
fi
# Exec the specified command or fall back on bash
if [ $# -eq 0 ]; then
    cmd=bash
else
    cmd=$*
fi

# If we have shared data mounted, the link it to current directory to have it visible in notebook
if [ -d "$PVC_MOUNT_PATH" ] && [ ! -L "$HOME/data" ]; then
	ln -s "$PVC_MOUNT_PATH" "$HOME/data"
fi

# If we don't have the .jupyter config then copy it to user directory
if [ ! -d "$HOME/.jupyter/nbconfig" ]; then
	cp -r /etc/default/jupyter/nbconfig $HOME/.jupyter/
fi

if [ ! -d "$HOME/AGU_JGR_CLP_SOURCE_WORKFLOW" ]; then
    git clone https://github.com/MasterOnDust/AGU_JGR_CLP_SOURCE_WORKFLOW.git  --branch AGU-Haugvaldstad-et-al-2024-release --single-branch
fi

if [ ! -d "$HOME/Thesis_toolbox" ]; then
    git clone https://github.com/MasterOnDust/Thesis_toolbox.git --branch AGU-Haugvaldstad-et-al-2024-release --single-branch
fi

if [ ! -d "$HOME/flexpart_cluster" ]; then
    git clone https://github.com/MasterOnDust/flexpart_cluster.git --branch AGU-Haugvaldstad-et-al-2024-release-final --single-branch
fi

if [ ! -d "$HOME/DUST" ]; then
     git clone https://github.com/MasterOnDust/DUST.git --branch  AGU-Haugvaldstad-et-al-2024-release --single-branch
fi
OLDPATH=$PATH

/usr/bin/python3 -m venv --system-site-packages $HOME/.jupyter/sysvenv
source $HOME/.jupyter/sysvenv/bin/activate
python -m IPython kernel install --user --name=sysvenv --display-name='Python 3 (no conda)'
PATH=$OLDPATH

cd $HOME/DUST && conda run -n dust pip install --no-deps -e .
cd $HOME/Thesis_toolbox &&  conda run -n dust pip install --no-deps -e .
cd $HOME/flexpart_cluster && conda run -n dust pip install --no-deps -e .

cd $HOME

if [[ ! -z "${JUPYTER_ENABLE_LAB}" ]]; then
	jupyter lab --config $HOME/.jupyter/notebook_config.py $* &
else
	jupyter notebook --config $HOME/.jupyter/notebook_config.py $* &
fi

sleep inf
