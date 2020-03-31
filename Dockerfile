FROM ubuntu:18.04

# Install texlive, inotify-tools
# install libgmp-dev zlib1g-dev for pandoc
# install cabal for pandoc and pandoc-filters.
# install ghcup for cabal
# install curl, xz-urtils, build-essential for ghcup.
ENV DEBIAN_FRONTEND noninteractive
RUN apt update && apt install -y --no-install-recommends \
	texlive-full \
	curl \
	xz-utils \
	build-essential \
	libgmp-dev \
	zlib1g-dev \
	inotify-tools \
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

