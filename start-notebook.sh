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
OLDPATH=$PATH
PATH="/usr/local/nvidia/bin:/usr/local/cuda/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/spark/bin"
/usr/bin/python3 -m venv --system-site-packages $HOME/.jupyter/sysvenv
source $HOME/.jupyter/sysvenv/bin/activate
python -m IPython kernel install --user --name=sysvenv --display-name='Python 3 (no conda)'
PATH=$OLDPATH

if [[ ! -z "${JUPYTER_ENABLE_LAB}" ]]; then
	jupyter lab --config $HOME/.jupyter/notebook_config.py $* &
else
	jupyter notebook --config $HOME/.jupyter/notebook_config.py $* &
fi

sleep inf