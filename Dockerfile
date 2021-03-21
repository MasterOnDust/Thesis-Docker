# Basic MetOs container 

FROM jupyter/base-notebook:python-3.8.8 as miniconda
USER root
ENV DEBIAN_FRONTEND noninteractive \
    NODE_OPTIONS --max-old-space-size=4096 \
    NB_UID=999 \
    NB_GID=999

RUN apt update && apt install -y eatmydata apt-utils 
RUN conda config --set channel_priority strict && \
    eatmydata conda install --quiet --update-all --yes -c conda-forge \
    'xeus-python=0.11.3'\
    'nbconvert=6.0.7' \
    'fortran_kernel=0.1.7'\
    'tqdm' \
    'yapf' \
    'rise' \
    'nbdime' \
    'jupyterlab==3.*' \
    'ipywidgets' \
    'nodejs'\
    'dask-labextension=5.0.1' \
    'tornado' \
    'python-graphviz=0.16' \
    'nb_conda_kernels=2.3.1'\
    'jupyter-server-proxy=1.6' \
    'plotly=4.14.*'\
    'matplotlib=3.3.*' \ 
    'jupyterlab_iframe=0.3.0'\
    'numpy' \
    'git'  && \
     conda clean  --all -f -y


RUN jupyter serverextension enable --py jupyter_server_proxy jupyterlab_iframe && \
    jupyter labextension install \
    '@jupyter-widgets/jupyterlab-manager' \
    'plotlywidget' \
    'jupyterlab-plotly' \
    'jupyter-matplotlib' \
    'nbdime-jupyterlab' \
    '@jupyterlab/toc' \
    '@jupyterlab/server-proxy' \
    'jupyterlab_iframe' && \
    git clone https://github.com/paalka/nbresuse /tmp/nbresuse && pip install /tmp/nbresuse/ && \
    jupyter serverextension enable --py nbresuse --sys-prefix && \
    jupyter nbextension install --py nbresuse --sys-prefix && \
    jupyter nbextension enable --py nbresuse --sys-prefix && \
    jupyter lab build

FROM jupyter/base-notebook:python-3.8.8 

USER root
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        curl \
        libfreetype6-dev \
        libhdf5-serial-dev \
        libzmq3-dev \
        pkg-config \
        software-properties-common \
        unzip \
    	openssh-client \
    	nano \
    	htop \
    	less \
    	net-tools \
    	man-db \
    	iputils-ping \
        gfortran\ 
    	tmux \
    	graphviz \
    	vim &&\
        apt-get install -y --only-upgrade openssl && \
	apt-get clean && apt-get autoremove -y && rm -rf /var/lib/apt/lists/*  



ENV TZ="Europe/Oslo" \
	APP_UID=999 \
	APP_GID=999 \
	NB_UID=999 \
	NB_GID=999 \
    PKG_JUPYTER_NOTEBOOK_VERSION=6.3.x \
	PKG_TOREE_VERSION=0.3.0-incubating \
	PKG_R_VERSION=4.0.3 \
	PKG_VS_CODE_VERSION=2.1692-vsc1.39.2  \
	HOME=/home/notebook \
    	XDG_CACHE_HOME=/home/notebook/.cache/

RUN groupadd -g "$APP_GID" notebook && \
	useradd -m -s /bin/bash -N -u "$APP_UID" -g notebook notebook && \
	usermod -G users notebook

COPY start-*.sh /usr/local/bin/
COPY mem_parser.py /usr/local/bin/
COPY --chown=notebook:notebook --from=miniconda $CONDA_DIR $CONDA_DIR
RUN mkdir -p "$CONDA_DIR/.condatmp" && chmod go+rwx "$CONDA_DIR/.condatmp"


RUN wget -q "https://github.com/cdr/code-server/releases/download/$PKG_VS_CODE_VERSION/code-server$PKG_VS_CODE_VERSION-linux-x86_64.tar.gz"  && \
    tar zxf "code-server$PKG_VS_CODE_VERSION-linux-x86_64.tar.gz" && \
    mv "code-server$PKG_VS_CODE_VERSION-linux-x86_64/code-server" /usr/local/bin/ && \
    rm -rf "code-server$PKG_VS_CODE_VERSION-linux-x86_64/*" "$HOME/.wget-hsts" && locale-gen en_US.UTF-8

ADD env.yml env.yml
RUN conda env create -f env.yml && conda clean -yt


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
