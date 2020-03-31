FROM ubuntu:18.04

# Install texlive, inotify-tools
# install libgmp-dev zlib1g-dev for pandoc
# install cabal for pandoc and pandoc-filters.
# install ghcup for cabal
# install curl, xz-urtils, build-essential for ghcup.
# install default-jre and graphviz for plantuml.
# install git for pandocfilters.
ENV DEBIAN_FRONTEND noninteractive
RUN apt update && apt install -y --no-install-recommends \
	texlive-full \
	curl \
	xz-utils \
	build-essential \
	libgmp-dev \
	zlib1g-dev \
	inotify-tools \
	default-jre \
	graphviz \
	git \
 && apt -y clean

# Setup haskell package manager.
# Intssall pandoc, pandoc-crossref.
RUN mkdir -p ~/.ghcup/bin \
 && curl https://gitlab.haskell.org/haskell/ghcup/raw/master/ghcup > ~/.ghcup/bin/ghcup \
 && chmod +x ~/.ghcup/bin/ghcup
ENV PATH "/root/.cabal/bin:/root/.ghcup/bin:$PATH"
RUN ghcup install \
 && ghcup install-cabal \
 && ghcup set recommended \
 && cabal new-update \
 && cabal new-install cabal-install \
 && cabal new-install pandoc \
 && cabal new-install pandoc-crossref

# Download / Install plantuml.
ENV PLANTUML_VERSION 1.2020.5
RUN mkdir -p /usr/share/plantuml \
 && curl -o /usr/share/plantuml/plantuml.jar -JLsS \
	http://sourceforge.net/projects/plantuml/files/plantuml.${PLANTUML_VERSION}.jar/download

# To able to use plantuml pandocfilter for Japanese files.
ENV LC_CTYPE=C.UTF-8

# Download / Install pandocfilters.
RUN git clone https://github.com/jgm/pandocfilters.git \
 && cd pandocfilters \
 && python setup.py install \
 && sed examples/plantuml.py \
	-e "s@plantuml.jar@/usr/share/plantuml/plantuml.jar@g" \
	> /usr/local/bin/plantuml.py \
 && chmod a+x /usr/local/bin/plantuml.py
