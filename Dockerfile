# Use phusion/baseimage as base image. To make your builds
# reproducible, make sure you lock down to a specific version, not
# to `latest`! See
# https://github.com/phusion/baseimage-docker/blob/master/Changelog.md
# for a list of version numbers.
FROM phusion/baseimage:0.9.16

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]
ENV DEBIAN_FRONTEND noninteractive

# Install Dependencies
RUN apt-get -y update && apt-get -y install git perl graphicsmagick-imagemagick-compat libstdc++6 libc6 python-minimal python-setuptools python-numpy python-scipy parallel

#Install minc-toolkit-v2
RUN curl -SL http://packages.bic.mni.mcgill.ca/minc-toolkit/Debian/minc-toolkit-1.9.10-20150710-Ubuntu_14.04-x86_64.deb -o /tmp/minc-toolkit-1.9.10-20150710-Ubuntu_14.04-x86_64.deb \
    && dpkg -i  /tmp/minc-toolkit-1.9.10-20150710-Ubuntu_14.04-x86_64.deb

# Download MAGeTBrain
RUN git clone https://github.com/CobraLab/MAGeTbrain.git

# Download and install pyminc MAGeTBrain dependency
RUN git clone https://github.com/Mouse-Imaging-Centre/pyminc.git && cd /pyminc && python setup.py install

#Enable minc commands and mb commands
RUN echo "source /opt/minc-itk4/minc-toolkit-config.sh" >> /etc/bash.bashrc
RUN echo "source /MAGeTbrain/bin/activate" >> /etc/bash.bashrc
RUN ln -s /opt/minc-itk4/bin/ANTS /opt/minc-itk4/bin/mincANTS

#Setup so that all commands are run in data directory
WORKDIR /maget

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
