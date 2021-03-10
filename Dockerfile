# Basic MetOs container 

FROM jupyter/datascience-notebook:python-3.8.8 as miniconda
USER root
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ENV DEBIAN_FRONTEND noninteractive \
    NODE_OPTIONS --max-old-space-size=4096 \
    NB_UID=999 \
    NB_GID=999

RUN apt update && apt install -y eatmydata apt-utils 
RUN conda config --set channel_priority strict && \
    conda install --quiet --update-all --yes -c conda-forge \
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
    'plotly'\
    'matplotlib' \ 
    'jupyterlab_iframe'\
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

FROM jupyter/datascience-notebook:python-3.8.8 

USER root

ENV TZ="Europe/Oslo" \
	APP_UID=999 \
	APP_GID=999 \
	NB_UID=999 \
	NB_GID=999 \
    PKG_JUPYTER_NOTEBOOK_VERSION=6.2.x \
	PKG_TOREE_VERSION=0.3.0-incubating \
	PKG_R_VERSION=4.0.3 \
	PKG_VS_CODE_VERSION=2.1692-vsc1.39.2  \
	HOME=/home/notebook \
    	PATH=$PATH:$SPARK_HOME/bin \
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
RUN conda env create -f env.yml && conda clean -yt &&\
    jupyter labextension install jupyter-matplotlib


RUN chown notebook:notebook $CONDA_DIR "$CONDA_DIR/.condatmp"
COPY --chown=notebook:notebook .jupyter/ $HOME/.jupyter/
COPY --chown=notebook:notebook .jupyter/ /etc/default/jupyter
RUN chmod go+w -R "$HOME"


RUN fix-permissions $CONDA_DIR

USER notebook
RUN conda init bash
    
WORKDIR $HOME

RUN pip install jupyterlab_github && jupyter serverextension enable --sys-prefix jupyterlab_github

CMD ["/usr/local/bin/start-notebook.sh"]
