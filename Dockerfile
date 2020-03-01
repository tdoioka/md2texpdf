FROM ubuntu:18.04

ENV DEBIAN_FRONTEND noninteractive
# Install texlive and ruby rake.
# intall curl, xz-urtils, build-essential for ghcup.
# install ghcup for cabal
# install cabal for pandoc and pandoc filters.
# install libgmp-dev zlib1g-dev for pandoc
RUN apt update && apt install -y --no-install-recommends \
	texlive-full \
	ruby \
	rake \
	curl \
	xz-utils \
	build-essential \
	libgmp-dev \
	zlib1g-dev \
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

# Get eisvogel template
ADD https://github.com/Wandmalfarbe/pandoc-latex-template/releases/download/v1.4.0/Eisvogel-1.4.0.tar.gz /root/eisvogel/Eisvogel-1.4.0.tar.gz
RUN mkdir -p ~/.pandoc/templates \
 && tar xf /root/eisvogel/Eisvogel-1.4.0.tar.gz -C ~/.pandoc/templates eisvogel.tex \
 && cp ~/.pandoc/templates/eisvogel.tex ~/.pandoc/templates/eisvogel.latex


# 	libffi-dev \
# 	libncurses-dev \
# 	libtinfo5 \
#	texlive-lang-cjk \
#	texlive-fonts-recommended \
#	texlive-fonts-extra \
