# MAGeTDocker - MAGeTbrain in a docker container for portable local use

-----

This is a docker container which builds a minimal environment that can run the MAGeTbrain program.

The prerequisites for this container are to have a functioning docker install, see:
https://docs.docker.com/mac/started/
https://docs.docker.com/linux/started/
https://docs.docker.com/windows/started/

The minimal steps for using this container are the following:

Get the container from the autobuilds:
```sh
> docker pull gdevenyi/magetdocker:latest
```

Or build the container yourself:
```sh
> git clone https://github.com/CobraLab/MAGeTDocker.git
> cd MAGeTDocker
> docker build -t magetdocker .
```

We also provide a mb-container wrapper which allows you to use a singularity container built from this image
as though it were a magetbrain installation. This wrapper relies on the qbatch installed and configured appropraitely
on the host system.

Usage:
```sh
> mb-container /path/to/container/image.img <regular mb command options>
```
