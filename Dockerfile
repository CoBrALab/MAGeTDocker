FROM ubuntu:18.04 as base
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    perl \
    imagemagick \
    parallel \
    locales \
    python3-minimal python3-numpy python3-scipy python3-pip python3-setuptools \
    gdebi-core curl default-jre-headless unzip patch \
  && rm -rf /var/lib/apt/lists/* \
  && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8 \
  && ln -sf /usr/bin/python3 /usr/bin/python

#Install minc-toolkit-v2
RUN curl -SL https://packages.bic.mni.mcgill.ca/minc-toolkit/Debian/minc-toolkit-1.9.17-20190313-Ubuntu_18.04-x86_64.deb \
      -o /tmp/minc-toolkit.deb \
    && gdebi -n /tmp/minc-toolkit.deb \
    && rm -f /tmp/minc-toolkit.deb \
    && cd /opt/minc/1.9.17/perl \
    && curl -sSL https://patch-diff.githubusercontent.com/raw/BIC-MNI/ILT/pull/5.patch | patch -p1 \
    && curl -sSL https://patch-diff.githubusercontent.com/raw/BIC-MNI/ILT/pull/7.diff | patch -p1

#Install bpipe
RUN curl -SL https://github.com/ssadedin/bpipe/releases/download/0.9.9.9/bpipe-0.9.9.9.tar.gz \
      -o /tmp/bpipe.tar.gz \
    && mkdir -p /opt/bpipe \
    && tar xzvf /tmp/bpipe.tar.gz -C /opt/bpipe \
    && rm -f /tmp/bpipe.tar.gz

#Install beast library
RUN curl -SL http://packages.bic.mni.mcgill.ca/minc-toolkit/Debian/beast-library-1.1.0-20121212.deb \
      -o /tmp/beast.deb \
    && gdebi -n /tmp/beast.deb \
    && rm -f /tmp/beast.deb \
    && mkdir -p /opt/quarantine/resources/BEaST_libraries \
    && ln -s /opt/minc/share/beast-library-1.1 /opt/quarantine/resources/BEaST_libraries/combined

#Install MNI priors
RUN curl -SL http://www.bic.mni.mcgill.ca/~vfonov/icbm/2009/mni_icbm152_nlin_sym_09c_minc2.zip \
    -o /tmp/mnimodel.zip \
    && mkdir -p /opt/quarantine/resources/mni_icbm152_nlin_sym_09c_minc2 \
    && unzip /tmp/mnimodel.zip -d /opt/quarantine/resources/mni_icbm152_nlin_sym_09c_minc2 \
    && rm -f /tmp/mnimodel.zip

# Download and install pyminc MAGeTBrain dependency
RUN pip3 install pyminc

# Download and install qbatch
RUN pip3 install qbatch==2.2.1

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
      libxi-dev libqt4-dev libxml2-dev ninja-build  \
    && rm -rf /var/lib/apt/lists/*

# Download MAGeTBrain
RUN git clone https://github.com/CobraLab/MAGeTbrain.git /opt/MAGeTbrain \
    && cd /opt/MAGeTbrain \
    git checkout d850944a3b1f9cf9b6c89cc6e1e05724471f1703

# Download minc-bpipe-library
RUN git clone https://github.com/CoBrALab/minc-bpipe-library.git /opt/minc-bpipe-library \
    && cd /opt/minc-bpipe-library \
    && git checkout 42b393dc8cda2310414f81f018627e7f80f61543 \
    && rm /opt/minc-bpipe-library/bpipe.config

RUN git clone https://github.com/CoBrALab/iterativeN4_multispectral.git /opt/iterativeN4 \
    && cd /opt/iterativeN4 \
    && git checkout 90765c27589b67966c73e0a99d929b4749ac2e61

RUN git clone https://github.com/CoBrALab/minc-toolkit-extras.git /opt/minc-toolkit-extras

#Download and build ANTs
RUN mkdir -p /opt/ANTs/build && git clone https://github.com/ANTsX/ANTs.git /opt/ANTs/src \
    && cd /opt/ANTs/src \
    && git checkout 5012c50dba54e734e007f005456630d0a4aec0ee \
    && cd /opt/ANTs/build \
    && cmake -GNinja -DITK_BUILD_MINC_SUPPORT=ON ../src \
    && cmake --build . \
    && cd ANTS-build \
    && cmake --install .

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
COPY --from=builder /opt/minc-bpipe-library /opt/minc-bpipe-library
COPY --from=builder /opt/iterativeN4 /opt/iterativeN4
COPY --from=builder /opt/minc-toolkit-extras /opt/minc-toolkit-extras

#Install python bits of minc-stuffs
RUN cd /opt/minc-stuffs/minc-stuffs-0.1.25/ && python3 setup.py install

#Setup Quarantine Path
ENV QUARANTINE_PATH="/opt/quarantine"

#Enable minc commands and mb commands
ENV PATH="/opt/minc-toolkit-extras:/opt/iterativeN4:/opt/ANTs/bin:/opt/bpipe/bpipe-0.9.9.9/bin:/opt/minc-stuffs/bin:/opt/MAGeTbrain/bin/:${PATH}"
ENV MB_ENV="/opt/MAGeTbrain/"

#Set QBATCH settings
ENV QBATCH_SYSTEM="container"

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
ENV MNI_DATAPATH="/opt/minc/1.9.17/../share::/opt/minc/1.9.17/share"

#Generate non-brain mask needed for bpipe
RUN minccalc -expression 'A[0]==1?0:1' \
     ${QUARANTINE_PATH}/resources/mni_icbm152_nlin_sym_09c_minc2/mni_icbm152_t1_tal_nlin_sym_09c_mask.mnc \
     ${QUARANTINE_PATH}/resources/mni_icbm152_nlin_sym_09c_minc2/mni_icbm152_t1_tal_nlin_sym_09c_antimask.mnc

#Generate headmask needed for bpipe/iterativeN4
RUN ThresholdImage 3 ${QUARANTINE_PATH}/resources/mni_icbm152_nlin_sym_09c_minc2/mni_icbm152_t1_tal_nlin_sym_09c.mnc \
     ${QUARANTINE_PATH}/resources/mni_icbm152_nlin_sym_09c_minc2/mni_icbm152_t1_tal_nlin_sym_09c_headmask.mnc \
     Otsu 4 \
    && iMath 3 ${QUARANTINE_PATH}/resources/mni_icbm152_nlin_sym_09c_minc2/mni_icbm152_t1_tal_nlin_sym_09c_headmask.mnc \
     FillHoles \
    ${QUARANTINE_PATH}/resources/mni_icbm152_nlin_sym_09c_minc2/mni_icbm152_t1_tal_nlin_sym_09c_headmask.mnc 2 \
    && iMath 3 ${QUARANTINE_PATH}/resources/mni_icbm152_nlin_sym_09c_minc2/mni_icbm152_t1_tal_nlin_sym_09c_headmask.mnc \
       ME ${QUARANTINE_PATH}/resources/mni_icbm152_nlin_sym_09c_minc2/mni_icbm152_t1_tal_nlin_sym_09c_headmask.mnc \
      3 1 ball 1

#Setup so that all commands are run in data directory
CMD mkdir -p /maget
WORKDIR /maget
