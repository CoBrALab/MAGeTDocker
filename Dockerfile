FROM ubuntu:18.04 as base
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    perl \
    imagemagick \
    parallel \
    locales \
    python3-minimal python3-numpy python3-scipy python3-pip python3-setuptools \
    gdebi-core curl \
  && rm -rf /var/lib/apt/lists/* \
  && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8 \
  && ln -s /usr/bin/python3 /usr/bin/python

#Install minc-toolkit-v2
RUN curl -sSL https://packages.bic.mni.mcgill.ca/minc-toolkit/Debian/minc-toolkit-1.9.17-20190313-Ubuntu_18.04-x86_64.deb \
      -o /tmp/minc-toolkit.deb \
    && gdebi -n /tmp/minc-toolkit.deb \
    && rm -f /tmp/minc-toolkit.deb

# Download and install pyminc MAGeTBrain dependency
RUN pip3 install pyminc

# Download and install qbatch
RUN pip3 install qbatch

####################################################################################################
FROM base as builder
RUN apt-get update && apt-get install -y gnupg software-properties-common --no-install-recommends \
    && curl -sSL https://apt.kitware.com/keys/kitware-archive-latest.asc | apt-key add - \
    && apt-add-repository 'deb https://apt.kitware.com/ubuntu/ bionic main' \
    && apt-get update && apt-get install -y \
      git cmake \
      build-essential automake libtool bison \
      libz-dev libjpeg-dev libpng-dev libtiff-dev \
      liblcms2-dev flex libx11-dev freeglut3-dev libxmu-dev \
      libxi-dev libqt4-dev libxml2-dev  \
    && rm -rf /var/lib/apt/lists/*

# Download MAGeTBrain
RUN git clone -b allants https://github.com/CobraLab/MAGeTbrain.git /opt/MAGeTbrain

#Download and build ANTs
RUN mkdir -p /opt/ANTs/build && git clone https://github.com/ANTsX/ANTs.git /opt/ANTs/src \
    && cd /opt/ANTs/src \
    && git checkout b99b84051c5ada43995f37a73ef2715ddbf6a856 \
    && cd /opt/ANTs/build \
    && cmake -DITK_BUILD_MINC_SUPPORT=ON ../src \
    && make \
    && cd ANTS-build \
    && make install

RUN mkdir -p /opt/minc-stuffs
RUN curl -sSL https://github.com/Mouse-Imaging-Centre/minc-stuffs/archive/v0.1.25.tar.gz \
    -o /opt/minc-stuffs/v0.1.25.tar.gz && tar xzvf /opt/minc-stuffs/v0.1.25.tar.gz -C /opt/minc-stuffs
RUN cd /opt/minc-stuffs/minc-stuffs-0.1.25 \
    && ./autogen.sh \
    && ./configure --prefix /opt/minc-stuffs --with-build-path=/opt/minc/1.9.17 \
    && make && make install


####################################################################################################
FROM base
#We only copy the ANTs commands we use, otherwise the container is huge
COPY --from=builder /opt/ANTs/bin/antsRegistration /opt/ANTs/bin/antsApplyTransforms \
    /opt/ANTs/bin/ANTS /opt/ANTs/bin/ImageMath /opt/ANTs/bin/iMath /opt/ANTs/bin/
COPY --from=builder /opt/MAGeTbrain /opt/MAGeTbrain
COPY --from=builder /opt/minc-stuffs /opt/minc-stuffs

#Install python bits of minc-stuffs
RUN cd /opt/minc-stuffs/minc-stuffs-0.1.25/ && python3 setup.py install

#Enable minc commands and mb commands
ENV PATH="/opt/ANTs/bin:${PATH}:/opt/bpipe-0.9.9.8/bin:/opt/minc-stuffs/bin:/opt/MAGeTbrain/bin/"
ENV MB_ENV="/opt/MAGeTbrain/"

#Variables set by minc-toolkit-config.sh
ENV LD_LIBRARY_PATH="/opt/minc/1.9.17/lib:/opt/minc/1.9.17/lib/InsightToolkit"
ENV MINC_FORCE_V2=1
ENV MINC_TOOLKIT_VERSION=1.9.17-20190313
ENV MINC_TOOLKIT=/opt/minc/1.9.17
ENV MINC_COMPRESS=4
ENV VOLUME_CACHE_THRESHOLD=-1
ENV PERL5LIB="/opt/minc/1.9.17/perl:/opt/minc/1.9.17/pipeline"
ENV MANPATH="/opt/minc/1.9.17/man"
ENV PATH="${PATH}:/opt/minc/1.9.17/bin:/opt/minc/1.9.17/pipeline"
ENV MNI_DATAPATH="/opt/minc/1.9.17/../share"

#Setup so that all commands are run in data directory
CMD mkdir -p /maget
WORKDIR /maget
