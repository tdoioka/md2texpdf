FROM ubuntu:18.04

# ................................................................
# Uses release versions.
# ................................................................
# pandoc version.
ENV VER_PANDOC 2.9.2
# pandoc-crossref version.
ENV VER_PANDOC_CR v0.3.6.2
# pandoc-crossref supported pandoc version.
ENV VER_PANDOC_CR_PANDOC 2_9_2
# plantuml version.
ENV VER_PLANTUML 1.2020.5

# ................................................................
# Install by package manager.
# ................................................................
# Install texlive, inotify-tools, gosu, zip.
# install curl for pandoc / pandoc-filters.
# install default-jre and graphviz for plantuml.
# install git for pandocfilters.
# install build-essential for makefile.
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
	texlive-full \
	inotify-tools \
	gosu \
	unzip \
	curl \
	default-jre \
	graphviz \
	git \
	build-essential \
 && apt-get -y clean

# ................................................................
# Install from public release image.
# ................................................................
# Downlad / Install pandoc.
RUN curl -o /tmp/pandoc.deb -JLsS \
    https://github.com/jgm/pandoc/releases/download/${VER_PANDOC}/pandoc-${VER_PANDOC}-1-amd64.deb \
 && dpkg -i /tmp/pandoc.deb

# Download / Install pandoc-crossref.
RUN curl -o /tmp/pandoc-cross.tar.gz -JLsS \
    https://github.com/lierdakil/pandoc-crossref/releases/download/${VER_PANDOC_CR}/linux-pandoc_${VER_PANDOC_CR_PANDOC}.tar.gz \
 && tar xf /tmp/pandoc-cross.tar.gz -C /usr/local/bin

# Download / Install plantuml.
RUN mkdir -p /usr/share/plantuml \
 && curl -o /usr/share/plantuml/plantuml.jar -JLsS \
      http://sourceforge.net/projects/plantuml/files/plantuml.${VER_PLANTUML}.jar/download

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

# Download and Install CJK fonts for TeX Live
RUN curl -L http://mirrors.ctan.org/fonts/haranoaji.zip -o /tmp/haranoaji.zip \
 && curl -L http://mirrors.ctan.org/fonts/haranoaji-extra.zip -o /tmp/haranoaji-extra.zip \
 && mkdir -p /tmp/haranoaji \
 && unzip /tmp/haranoaji.zip -d /tmp/haranoaji \
 && unzip /tmp/haranoaji-extra.zip -d /tmp/haranoaji \
 && mkdir -p $(kpsewhich --var-value=TEXMFLOCAL)/fonts/opentype/public/haranoaji/ \
 && cp /tmp/haranoaji/haranoaji*/*.otf $(kpsewhich --var-value=TEXMFLOCAL)/fonts/opentype/public/haranoaji/ \
 && mktexlsr

# Match user infomation to host directory
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN useradd -U -m user \
 && chmod a+x /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD /bin/bash
