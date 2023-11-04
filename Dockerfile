# Basic MetOs container 

FROM jupyter/base-notebook:4c0c0aa1715f as miniconda

RUN mamba config --set channel_priority strict && \
    mamba install --quiet --yes --update-all -c conda-forge \
    'ipyparallel==6.3.0' \
    'jupyter-server-proxy==4.0.0' \
    'escapism==1.0.1' \
    'jupyterlab-github==4.0.0' && \
    jupyter server extension enable jupyter_server_proxy --sys-prefix && \
    mamba clean --all -f -y
FROM jupyter/base-notebook:4c0c0aa1715f


LABEL maintainer = "ovehaugv@outlook.com"
USER root

# Setup ENV for Appstore to be picked up
ENV APP_UID=999 \
	APP_GID=999 \
	PKG_JUPYTER_NOTEBOOK_VERSION=7.0.5
RUN groupadd -g "$APP_GID" notebook && \
    useradd -m -s /bin/bash -N -u "$APP_UID" -g notebook notebook && \
    usermod -G users notebook && chmod go+rwx -R "$CONDA_DIR/bin"
COPY --chown=notebook:notebook --from=miniconda $CONDA_DIR $CONDA_DIR

SHELL ["/bin/bash", "-o", "pipefail", "-c"]


RUN apt-get update && apt-get install -y --no-install-recommends \
	openssh-client \
    curl \
	less \
	net-tools \
	man-db \
	iputils-ping \
	screen \
	tmux \
	graphviz \
	cmake \
	rsync \
	p7zip-full \
	tzdata \
	vim \
	unrar \
	ca-certificates \
    sudo \
    inkscape \
    fortran \
    "openmpi-bin" && \
    apt-get -y autoremove && \
    apt-get -y clean && \
    rm -rf /var/lib/apt/lists/* && \
    ln -sf /usr/share/zoneinfo/Europe/Oslo /etc/localtime
ENV TZ="Europe/Oslo"

RUN apt update && apt install -y eatmydata apt-utils 
RUN conda config --set channel_priority strict && \
    eatmydata conda install --quiet --update-all --yes -c conda-forge \
    'nbconvert' \
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
    'jupyter-server-proxy' \
    'matplotlib' \ 
    'jupyterlab_iframe'\
    'numpy' \
    'git'  && \
     conda clean  --all -f -y



RUN groupadd -g "$APP_GID" notebook && \
	useradd -m -s /bin/bash -N -u "$APP_UID" -g notebook notebook && \
	usermod -G users notebook

COPY start-*.sh /usr/local/bin/
COPY mem_parser.py /usr/local/bin/
COPY --chown=notebook:notebook --from=miniconda $CONDA_DIR $CONDA_DIR
RUN mkdir -p "$CONDA_DIR/.condatmp" && chmod go+rwx "$CONDA_DIR/.condatmp"


RUN curl -fsSL https://code-server.dev/install.sh | sh -s -- --version=4.16.1

ADD env.yml env.yml
RUN mamba env create -f env.yml &&  mamba clean -yt --all


RUN chown notebook:notebook $CONDA_DIR "$CONDA_DIR/.condatmp"
COPY --chown=notebook:notebook .jupyter/ $HOME/.jupyter/
COPY --chown=notebook:notebook .jupyter/ /etc/default/jupyter
RUN chmod go+w -R "$HOME"


RUN fix-permissions $CONDA_DIR && \
    chmod go+rwx /usr/local/bin/start-notebook.sh

USER notebook
RUN conda init bash
    
WORKDIR $HOME

CMD ["/usr/local/bin/start-notebook.sh"]
