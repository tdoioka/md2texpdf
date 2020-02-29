FROM ubuntu:18.04

ENV DEBIAN_FRONTEND noninteractive
RUN apt update \
 && apt upgrade \
 && apt install -y --no-install-recommends \
	texlive-full \
    	pandoc \
	ruby \
	rake \
 && apt -y clean \
 && mkdir /workdir
COPY Rakefile /workdir
	
#	texlive-lang-cjk \
#	texlive-fonts-recommended \
#	texlive-fonts-extra \
		
		
