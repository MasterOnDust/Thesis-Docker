# Basic MetOs container 

FROM jupyter/minimal-notebook:4c0c0aa1715f as miniconda

FROM jupyter/minimal-notebook:4c0c0aa1715f as miniconda

USER root
ENV DEBIAN_FRONTEND noninteractive \
    NODE_OPTIONS --max-old-space-size=4096 \
    NB_UID=999 \
    NB_GID=999

RUN apt-get update && apt-get install -y --no-install-recommends eatmydata apt-utils && \
    mamba config --set channel_priority strict && \
    eatmydata mamba install --quiet --update-all --yes -c conda-forge \
    'jupyterlab-github==4.0.0' \
    'jupyter-server-proxy==4.0.0' \
    'ipyparallel==6.3.0' \
    'plotly==5.17.0' \
    'xarray==2023.9.0' \
    'yapf==0.40.1' \
    && mamba clean --all -f -y
RUN mamba create -n minimal -y && bash -c 'source activate minimal && conda install -y ipykernel && ipython kernel install --name=minimal --display-name="Python 3 (minimal conda)" && conda clean --all -f -y && conda deactivate'

ADD env.yml env.yml
RUN mamba env create -f env.yml &&  mamba clean -yt --all
RUN bash -c 'source activate dust && conda install -y ipykernel && ipython kernel install --name=dust --display-name="Python 3 (dust env)" && conda clean --all -f -y && conda deactivate'

USER notebook

FROM jupyter/minimal-notebook:4c0c0aa1715f


LABEL maintainer = "ovehaugv@outlook.com"
USER root

# Setup ENV for Appstore to be picked up
ENV APP_UID=999 \
	APP_GID=999 \
	PKG_JUPYTER_NOTEBOOK_VERSION=7.0.5

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
    python3-dev \
    python3-venv \
    python3-pip \
    python3-ipykernel \
    htop \
    gfortran \
    libnetcdf-dev \
    python3-netcdf4 \
    netcat \
    "openmpi-bin" && \
    apt-get -y autoremove && \
    apt-get -y clean && \
    rm -rf /var/lib/apt/lists/* && \
    ln -sf /usr/share/zoneinfo/Europe/Oslo /etc/localtime
ENV TZ="Europe/Oslo" \
	NB_UID=999 \
	NB_GID=999 \
	PKG_HADOOP_VERSION=${HADOOP_VERSION} \
	PKG_TOREE_VERSION=0.4.0-incubating \
	PKG_R_VERSION=4.3.1  \
    PKG_VS_CODE_VERSION=4.16.1 \
	HOME=/home/notebook \
    XDG_CACHE_HOME=/home/notebook/.cache/

RUN groupadd -g "$APP_GID" notebook && \
	useradd -m -s /bin/bash -N -u "$APP_UID" -g notebook notebook && \
	usermod -G users notebook



COPY mem_parser.py /usr/local/bin/
COPY --chown=notebook:notebook --from=miniconda $CONDA_DIR $CONDA_DIR
COPY --chown=notebook:notebook --from=miniconda /usr/local/share/jupyter/kernels/minimal /usr/local/share/jupyter/kernels/minimal
COPY --chown=notebook:notebook --from=miniconda /usr/local/share/jupyter/kernels/dust /usr/local/share/jupyter/kernels/dust
COPY start-*.sh /usr/local/bin/
RUN mkdir -p "$CONDA_DIR/.condatmp" && chmod go+rwx "$CONDA_DIR/.condatmp"


RUN curl -fsSL https://code-server.dev/install.sh | sh -s -- --version=4.16.1


COPY --chown=notebook:notebook .jupyter/ $HOME/.jupyter/
COPY --chown=notebook:notebook .jupyter/ /etc/default/jupyter
RUN chmod go+w -R "$HOME"


RUN fix-permissions $CONDA_DIR && \
    chmod go+rwx /usr/local/bin/start-notebook.sh

USER notebook
RUN conda init bash
    
WORKDIR $HOME


CMD ["/usr/local/bin/start-notebook.sh"]
