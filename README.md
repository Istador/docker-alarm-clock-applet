## docker-alarm-clock-applet

This projects offers a dockerized version of [alarm-clock](https://github.com/joh/alarm-clock).

Because the `alarm-clock-applet` is unmaintained and no longer in the official package repositories, someone who wants to use it has to build and install it on their own.
This docker image tries to ease that.

Just `docker pull registry.gitlab.com/istador/docker-alarm-clock-applet:0.3.4-11` and run it with docker.

In practice running a GUI application with sound is a bit more complicated.
This is where [compose.sh](./compose.sh) and [docker-compose.yml](docker-compose.yml) should help.
In the end, just call [launch.sh](./launch.sh) to start the program.

It requires `docker`, `docker-compose` and `pulseaudio` on the host system.
Though running it in theory with `/dev/snd` should work too, but I haven't tested it. I might provide a smaller docker image without pulseaudio in the future.

The image comes with some default system sounds, though you can mount your own sounds to `/usr/share/sounds/`.


### Without docker

If you don't want to use `docker`, but want to install and build it on your own, have a look at the [Dockerfile](./Dockerfile). 

There you can see how I build and install the applet on Debian 10 and which packages it requires for building and running it.

I also generate some `*.deb` files that might work on your Debian or Ubuntu system directly. I have tested them on Debian 10 and Ubuntu 20.04.
