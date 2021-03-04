# MAGeTDocker - MAGeTbrain in a docker container for portable local use
-----

This is a docker container which builds a minimal environment that can run the MAGeTbrain program http://www.github.com/cobralab/MAGeTBrain

The prerequisites for this container are to have a functioning docker or singularity install, see:
https://docs.docker.com/mac/started/
https://docs.docker.com/linux/started/
https://docs.docker.com/windows/started/
https://github.com/hpcng/singularity/releases

The minimal steps for getting this container are the following:

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

Build a singularity image from dockerhub
```
> singularity build magetdocket.img docker://gdevenyi/magetdocker
```

We also provide a ``mb-container`` wrapper which allows you to use a singularity container built from this image
as though it were a magetbrain installation. This wrapper relies on the qbatch installed and configured appropraitely
on the host system.

Usage:
```sh
> mb-container /path/to/container/image.img <regular mb command options>
```

# Atlases

MAGeTbrain supports any combination of consistent atlas/label pairs however it has been extensively used and validated
on the atlases provided by our lab at http://www.github.com/cobralab/atlases
