FROM debian:latest
MAINTAINER CNGBdb Team <CNGBdb@cngb.org>
ARG blast_version=2.11.0+
RUN apt-get -qq update && apt-get -qq -y install curl bzip2 \
    && curl -sSL  ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/LATEST/ncbi-blast-$blast_version-x64-linux.tar.gz  -o /opy/blast.tar.gz \
    && tar -xvf /opt/blast.tar.gz -C /opt/ \
    && rm -rf /opt/blast.tar.gz \
    && apt-get autoclean \
    && rm -rf /var/lib/apt/lists/* /var/log/dpkg.log 

ENV PATH /opt/ncbi-blast-$blast_version/:$PATH
