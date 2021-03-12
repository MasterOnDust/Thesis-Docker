if [ -d "$PVC_MOUNT_PATH" ] && [ ! -L "$HOME/data" ]; then
	ln -s "$PVC_MOUNT_PATH" "$HOME/data"
fi

# If we don't have the .jupyter config then copy it to user directory
if [ ! -d "$HOME/.jupyter/nbconfig" ]; then
	cp -r /etc/default/jupyter/nbconfig $HOME/.jupyter/
fi

if [[ ! -z "${JUPYTER_ENABLE_LAB}" ]]; then
	jupyter lab --config $HOME/.jupyter/notebook_config.py $* &
else
	jupyter notebook --config $HOME/.jupyter/notebook_config.py $* &
fi

sleep inf