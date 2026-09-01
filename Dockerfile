FROM debian:trixie-slim

SHELL ["/bin/bash", "--rcfile", "~/.bashrc", "-ci" ]

RUN apt-get update -y
RUN apt-get install curl vim tmux -y

COPY ./bookworm.sources /etc/apt/sources.list.d/bookworm.sources
RUN apt-get update -y


# Install SteamCMD
#RUN apt-get install software-properties-common -y
#RUN add-apt-repository multiverse -y
RUN dpkg --add-architecture i386
RUN apt-get update -y
RUN apt-get install wget lib32gcc-s1 lib32stdc++6 libstdc++6:i386 lib32z1 -y

RUN echo steam steam/question select "I AGREE" |  debconf-set-selections 
RUN echo steam steam/license note '' | debconf-set-selections 


RUN apt-get install steamcmd -y --no-install-recommends
RUN ln -s /usr/games/steamcmd /usr/bin/steamcmd 


# Install packages
RUN apt-get install -y procps

# Clean cache
RUN apt-get autoremove -y
RUN apt-get clean -y

RUN useradd --shell /bin/bash zombie
USER zombie

WORKDIR /home/zombie

# Install conda
RUN mkdir -p ~/miniconda3
RUN curl https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -o ~/miniconda3/miniconda.sh
RUN chmod +x ~/miniconda3/miniconda.sh
RUN /home/zombie/miniconda3/miniconda.sh -b -u -p ~/miniconda3
RUN rm -rf ~/miniconda3/miniconda.sh
USER root
RUN ln -s /home/zombie/miniconda3/bin/conda /usr/bin/conda
USER zombie
RUN conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main
RUN conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r
RUN ~/miniconda3/bin/conda init 

WORKDIR /home/zombie
# Conda environment
RUN conda create -n zomboid
RUN touch ~/.bashrc
RUN conda init
RUN conda config --set auto_activate_base true
RUN echo "conda activate zomboid" >> ./.bashrc


COPY ./requirements.conda.txt ./requirements.conda.txt
COPY ./requirements.txt ./requirements.txt
RUN conda install -f ./requirements.conda.txt
RUN pip install -r ./requirements.txt



RUN echo "export PATH=$PATH:/usr/games" >> ./.bashrc
RUN echo "export PZ_INSTALLATION=~/pzserver" >> ./.bashrc
RUN echo "export ZOMBOID_FOLDER=$HOME" >> ./.bashrc

#RUN --mount=type=bind,source=/usr/games,target=/usr/games
#RUN makedirs ~/pzserver
#RUN --mount=type=bind,source=../server/pzserver/,target=~/pzserver

#RUN steamcmd +force_install_dir ~/pzserver +@sSteamCmdForcePlatformType linux +login anonymous +app_update 380870 validate +quit




COPY ./dashboard ./dashboard
COPY ./server ./server
COPY ./scripts ./scripts
COPY ./server ./server
COPY ./setup.sh ./setup.sh



CMD ["./setup.sh", "--source"]
