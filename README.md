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

Now we need to startup the docker container, and connect it to a local directory on your machine to run MAGeTbrain:
```
> docker run -i -v /path/to/my/working/directory:/maget -t gdevenyi/magetdocker /sbin/my_init -- /bin/bash --login
#Or if you built your own container
> docker run -i -v /path/to/my/working/directory:/maget -t magetdocker /sbin/my_init -- /bin/bash --login
```
You will now have a terminal running within the docker container, connected to the working directory you specified

Now startup the automated preprocessing + MAGeTbrain pipeline, specifying the number of CPUs the computer has, and follow the prompts:
```
> maget-go.sh <NCPUS>
```

After the pipeline is complete, you will find labels in ``<WORKING_DIRECTORY>/output/fusion/majority_vote`` and
quality control images in ``<WORKING_DIRECTORY>/QC``

#Note for OSX and Windows users
Docker on OSX and Windows runs through a virtual machine (VM) which limits the amount of memory docker can use by default
to 2GB of RAM. MAGeTbrain is a memory-intensive application, approximately 3GB of RAM per parallel subject running through
the pipeline.

To increase the amount of RAM docker can use in OSX or Windows, see the help post here https://stackoverflow.com/questions/24422123/change-boot2docker-memory-assignment
