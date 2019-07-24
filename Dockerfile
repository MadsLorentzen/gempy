#FROM continuumio/miniconda3
#RUN conda create -n env python=3.6
#
## ...
#ENV DEBIAN_FRONTEND noninteractive
#RUN apt-get update && \
#    apt-get -y install gcc mono-mcs && \
#    rm -rf /var/lib/apt/lists/* \
#    apt-get install git
## RUN apt-get install libc-dev
## RUN conda install gcc
#RUN git clone https://github.com/cgre-aachen/gempy.git
#WORKDIR gempy
#RUN conda install theano gdal qgrid
#RUN pip install --upgrade --force-reinstall Theano>=1.0.4
#RUN pip install gempy pandas>=0.21.0 cython pytest seaborn networkx ipywidgets scikit-image

ARG cuda_version=9.0
ARG cudnn_version=7
FROM nvidia/cuda:${cuda_version}-cudnn${cudnn_version}-devel

# Install system packages
RUN apt-get update && apt-get install -y --no-install-recommends \
      bzip2 \
      g++ \
      git \
      graphviz \
      libgl1-mesa-glx \
      libhdf5-dev \
      openmpi-bin \
      wget && \
    rm -rf /var/lib/apt/lists/*

# Install conda
ENV CONDA_DIR /opt/conda
ENV PATH $CONDA_DIR/bin:$PATH

RUN wget --quiet --no-check-certificate https://repo.continuum.io/miniconda/Miniconda3-4.2.12-Linux-x86_64.sh && \
    echo "c59b3dd3cad550ac7596e0d599b91e75d88826db132e4146030ef471bb434e9a *Miniconda3-4.2.12-Linux-x86_64.sh" | sha256sum -c - && \
    /bin/bash /Miniconda3-4.2.12-Linux-x86_64.sh -f -b -p $CONDA_DIR && \
    rm Miniconda3-4.2.12-Linux-x86_64.sh && \
    echo export PATH=$CONDA_DIR/bin:'$PATH' > /etc/profile.d/conda.sh

# Install Python packages and gempy
ENV NB_USER gempy
ENV NB_UID 1000

RUN useradd -m -s /bin/bash -N -u $NB_UID $NB_USER && \
    chown $NB_USER $CONDA_DIR -R && \
    mkdir -p /src && \
    chown $NB_USER /src

USER $NB_USER

ARG python_version=3.6
#RUN conda install theano # gdal qgrid

RUN conda config --append channels conda-forge
RUN conda install -y python=${python_version} && \
    pip install --upgrade pip && \
    pip install gempy pandas cython pytest seaborn networkx ipywidgets scikit-image && \
   # pip install --upgrade --force-reinstall Theano>=1.0.4 && \
    conda install \
      bcolz \
      h5py \
      matplotlib \
      mkl \
      nose \
      notebook \
      Pillow \
      pandas \
      pydot \
      pygpu \
      pyyaml \
      scikit-learn \
      six \
      mkdocs

RUN pip install --upgrade --force-reinstall Theano>=1.0.4
RUN cd ~/ && \
    mkdir gempy && \
    cd gempy && \
    git clone https://github.com/cgre-aachen/gempy.git

# RUN conda install theano gdal qgrid
#RUN pip install gempy pandas>=0.21.0 cython pytest seaborn networkx ipywidgets scikit-image


ADD theanorc /home/gempy/.theanorc

ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8

ENV PYTHONPATH='/src/:$PYTHONPATH'

WORKDIR /data

EXPOSE 8888

CMD jupyter notebook --port=8888 --ip=0.0.0.0