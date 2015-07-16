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
> docker pull gdevenyi/magetdocker
```

Or build the container yourself:
```
> git clone https://github.com/CobraLab/MAGeTDocker.git
> cd MAGeTDocker
> docker build -t magetdocker .
```

Now we need to startup the docker container, and connect it to a directory on your machine to run MAGeTbrain
```
> docker run -i -v /path/to/my/working/directory:/maget -t gdevenyi/magetdocker /bin/bash
#Or if you built your own container
> docker run -i -v /path/to/my/working/directory:/maget -t magetdocker /bin/bash
```

You will now have a terminal running within the docker container, in your working directory, you must initalize the directory structure:
```
> mb init
```

Now your working directory will have the MAGeTbrain directory structure, where you can place your atlases, templates and brains.

Now we run the first stage of MAGeTbrain
```
> mb run -q parallel
```

When this is complete, we run the second stage:
```
> mb run vote -q parallel
```
