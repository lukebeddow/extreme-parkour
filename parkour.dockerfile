FROM ubuntu:22.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive
ENV PYENV_ROOT="/.pyenv"
ENV PATH="$PYENV_ROOT/bin:$PYENV_ROOT/shims:$PATH"
ENV PATH="/.venv/bin:$PATH"

# Set the working directory
WORKDIR /workspace

# Install system dependencies (maybe can reduce these)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        curl \
        unzip \
        wget \
        git \
        software-properties-common \
        libgl1-mesa-dev \
        libgl1-mesa-glx \
        libosmesa6-dev \
        libglfw3 \
        ffmpeg \
        make \
        libssl-dev \
        zlib1g-dev \
        libbz2-dev \
        libreadline-dev \
        libsqlite3-dev \
        libncursesw5-dev \
        xz-utils \
        tk-dev \
        libxml2-dev \
        libxmlsec1-dev \
        libffi-dev \
        liblzma-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install pyenv
RUN curl https://pyenv.run | bash && \
    pyenv update && \
    rm -rf $PYENV_ROOT/.git

# Install Python and set as global version
RUN pyenv install 3.8 && \
    pyenv global 3.8

# Set up virtual environment
RUN python -m venv /.venv && \
    pip install --upgrade pip setuptools wheel

RUN pip3 install torch==1.10.0+cu113 \
    torchvision==0.11.1+cu113 \
    torchaudio==0.10.0+cu113 \
    -f https://download.pytorch.org/whl/cu113/torch_stable.html

# copy across isaacgym folder
COPY src/repos/isaacgym /workspace/isaacgym
RUN cd /workspace/isaacgym/python && pip install -e .
RUN git clone https://github.com/chengxuxin/extreme-parkour.git
RUN cd extreme-parkour/rsl_rl && pip install -e .
RUN cd extreme-parkour/legged_gym && pip install -e .
RUN pip install "numpy<1.24" pydelatin wandb tqdm opencv-python ipdb pyfqmr flask

# now install python modules for the main motion-predictor repo
RUN pip install hydra-core py_lz4framed dill elements mediapy

# Setup entry point to activate virtual environment
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]


CMD ["bash"]