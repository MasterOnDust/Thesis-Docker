# Basic MetOs container 

FROM jupyter/minimal-notebook:latest

LABEL maintainer="Ove Haugvaldstad ovehaugv@outlook.com"

USER root


RUN apt update && apt-get install --no-install-recommends -y \
    openssh-client\
    nano\
    htop\
    less \
    net-tools \
    man-db \
    iputils-ping\
    tmux \
    liblapack-dev\
    libopenblas-dev\
    graphviz \
    cmake \
    rsync \
    p7zip-full\
    unrar \
    vim && \
    apt-get clean && rm -rf /var/lib/apt/lists/*
# Remember to install nb_conda_kernels in order for kernels to show up

RUN conda config --set channel_priority strict && \
    conda install --quiet --yes --update-all -c conda-forge \
    'xeus-python'\
    'nbconvert' \
    'fortran_kernel'\
    'tqdm' \
    'yapf' \
    'rise' \
    'nbdime' \
    'jupyterlab==3.*' \
    'ipywidgets' \
    'nodejs'\
    'dask-labextension' \
    'tornado' \
    'python-graphviz' \
    'nb_conda_kernels'\
    'jupyterlab-git'\
    'nbresuse' \
    'jupyter-server-proxy' \ 
    'git'  && \
    jupyter labextension install \
    'nbdime-jupyterlab' \
    '@jupyterlab/toc' \
    '@jupyterlab/hub-extension'  && \
    git clone https://github.com/paalka/nbresuse /tmp/nbresuse &&  \
    pip install /tmp/nbresuse/ \
    pip install jupyterlab-spellchecker && \
    jupyter serverextension enable --py nbresuse --sys-prefix && \
    jupyter nbextension install --py nbresuse --sys-prefix && \
    jupyter nbextension enable --py nbresuse --sys-prefix && \
    jupyter labextension install jupyter-matplotlib && \
    jupyter lab build

ADD env.yml env.yml
RUN conda env create -f env.yml && conda clean -yt &&\
    jupyter labextension install jupyter-matplotlib

RUN ["/bin/bash" , "-c", ". /opt/conda/etc/profile.d/conda.sh && \
    conda activate dust && \
    git clone https://github.com/Ovewh/DUST.git /home/jovyan/DUST && \
    pip install -e /home/jovyan/DUST && \ 
    jupyter labextension install jupyterlab-datawidgets && \
    jupyter labextension install @jupyter-widgets/jupyterlab-manager jupyter-matplotlib && \
    jupyter labextension install @jupyterlab/toc && \
    conda deactivate && \
    conda init bash"]
ENV XDG_CACHE_HOME=/home/$NB_USER/.cache/
# RUN mkdir "$HOME/.jupyter"
COPY .jupyter/ /opt/.jupyter/ 
COPY .jupyter/ /home/$NB_USER 
COPY .jupyter/ /etc/default/jupyter

RUN fix-permissions $HOME  &&\
    fix-permissions /etc/default/jupyter

USER jovyan

WORKDIR $HOME


ENV LANG=en_US.UTF-8

CMD ["/usr/local/bin/start-notebook.sh"]
