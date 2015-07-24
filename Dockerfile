# Use phusion/baseimage as base image. To make your builds
# reproducible, make sure you lock down to a specific version, not
# to `latest`! See
# https://github.com/phusion/baseimage-docker/blob/master/Changelog.md
# for a list of version numbers.
FROM phusion/baseimage:0.9.17

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]
ENV DEBIAN_FRONTEND noninteractive

# Install Dependencies
RUN apt-get -y update && apt-get -y install git perl graphicsmagick-imagemagick-compat libstdc++6 libc6 python-minimal python-setuptools python-numpy python-scipy parallel default-jre-headless

#Install minc-toolkit-v2
RUN curl -SL http://packages.bic.mni.mcgill.ca/minc-toolkit/Debian/minc-toolkit-1.9.10-20150710-Ubuntu_14.04-x86_64.deb -o /tmp/minc-toolkit-1.9.10-20150710-Ubuntu_14.04-x86_64.deb \
    && dpkg -i  /tmp/minc-toolkit-1.9.10-20150710-Ubuntu_14.04-x86_64.deb \
    && rm /tmp/minc-toolkit-1.9.10-20150710-Ubuntu_14.04-x86_64.deb

# Download MAGeTBrain
RUN git clone https://github.com/CobraLab/MAGeTbrain.git /MAGeTbrain

# Download and install pyminc MAGeTBrain dependency
RUN git clone https://github.com/Mouse-Imaging-Centre/pyminc.git /pyminc && cd /pyminc && python setup.py install

# Download and install bpipe
RUN curl -SL http://download.bpipe.org/versions/bpipe-0.9.8.7.tar.gz -o /tmp/bpipe-0.9.8.7.tar.gz \
    && tar -xzf /tmp/bpipe-0.9.8.7.tar.gz -C / \
    && rm /tmp/bpipe-0.9.8.7.tar.gz

# Download minc-bpipe-library
RUN git clone https://github.com/CobraLab/minc-bpipe-library.git --branch maget_preprocess /minc-bpipe-library

RUN mkdir /mni_icbm152_nlin_sym_09c_minc2 \
    && curl -SL http://cobralab.net/files/mni_icbm152_t1_tal_nlin_sym_09c_headmask.mnc -o /mni_icbm152_nlin_sym_09c_minc2/mni_icbm152_t1_tal_nlin_sym_09c_headmask.mnc \
    && curl -SL http://cobralab.net/files/mni_icbm152_t1_tal_nlin_sym_09c.mnc -o /mni_icbm152_nlin_sym_09c_minc2/mni_icbm152_t1_tal_nlin_sym_09c.mnc \
    && curl -SL http://cobralab.net/files/mni_icbm152_t1_tal_nlin_sym_09c_mask.mnc -o /mni_icbm152_nlin_sym_09c_minc2/mni_icbm152_t1_tal_nlin_sym_09c_mask.mnc


#Enable minc commands and mb commands
RUN echo "export PATH=$PATH:/bpipe-0.9.8.7/bin" >> /etc/profile
RUN echo "source /opt/minc-itk4/minc-toolkit-config.sh" >> /etc/profile
RUN echo "source /MAGeTbrain/bin/activate" >> /etc/profile
RUN ln -s /opt/minc-itk4/bin/ANTS /opt/minc-itk4/bin/mincANTS
RUN echo "umask u=rwx,g=rwx,o=rwx" >> /etc/profile
RUN echo "chmod u=rwX,g=rwX,o=rwX -R /maget" >> /etc/profile
RUN echo "echo export SHELL=/bin/bash >> /etc/profile"
COPY maget-go.sh /MAGeTbrain/bin/


#Setup so that all commands are run in data directory
WORKDIR /maget

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
