#MAGeTDocker - MAGeTbrain in a docker container for portable local use

-----

This is a docker container which builds a minimal environment that can run the MAGeTbrain program.

The prerequisites for this container are to have a functioning docker install, see:
https://docs.docker.com/mac/started/
https://docs.docker.com/linux/started/
https://docs.docker.com/windows/started/

The minimal steps for using this container are the following:

Get the container from the autobuilds:
```
> docker pull gdevenyi/magetdocker:latest
```

Or build the container yourself:
```
> git clone https://github.com/CobraLab/MAGeTDocker.git
> cd MAGeTDocker
> docker build -t magetdocker .
```
