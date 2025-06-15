<h1 align="center">Plasma</h1>

A _very_ lightweight Steam headless implementation.
Essentially a spiritual fork of [docker-steam-headless](https://github.com/Steam-Headless/docker-steam-headless)

<img alt="Plasma black hole image" src="docs/banner.png"/>

> [!TIP]
> If you're looking for the docs or configuration, please take a look
> at our [wiki in GitHub](https://github.com/jsmrcaga/plasma/wiki)

## Motivation
In short, I wanted to play KSP without installing it in my personal machine.

I was a heavy user of shadow.tech, until price hiked and I could not
justify the monthly cost.

Since then, I started homelabbing, and managed to get a Nvidia Quadro P400 for €20, which should run KSP.
Since I'm homelabbing, my setup does not have a screen, so here we are.

## Philosophy

> If it works once, it works forever

This project should work for you, _if you're willing to tinker and spend some time_.

The main idea of this project is to allow you to build a durable and running image of headless Steam.
Once that image is proven to work, you should have no more trouble getting it to run. So
if your server/computer/homelab/supercomputer dies because your little cousin tripped over the
power cable, you should be safe to jsut reboot the machine and not worry about libraries
not being up to date or getting a 404 from some driver url.

### What this is and isn't
* This is a different implementation of docker-steam-headless
* This is a "the less entropy the better" solution
* This is not a magic solution to get Steam working on your specific setup
* This is not a plug-and-play solution (ie: don't expect that running this docker image will "just work")

### Alternative solutions

#### [Steam Headless](https://github.com/Steam-Headless/docker-steam-headless)
In short: could not get it to work in ~45 minutes. At the time of writing (May 2025) the latest Docker Hub
and GitHub releases are from 2023, and mirror images had basic errors of file corruption.

#### [linuxserver/steamos](https://docs.linuxserver.io/images/docker-steamos/)
The last "NVIDIA commit" is not hopeful. I ended up trying the image with an
AMD card but I had no input at all and Steam was stuck in "webhelper is not responding" (comes pre-installed)

#### [Bazzite](https://bazzite.gg/)
Bazzite is a Linux distribution meant to look and behave like SteamOS.
it does allow you to build from Containerfiles, so it might work as a replacement 
for headless setups with some tinkering.

#### [HoloISO](https://github.com/HoloISO/releases)
Similar to Bazzite, HoloISO is a Linux distribution meant to look and behave like SteamOS.
If you want to just install this to a machine, i'd suggest trying out Bazzite or HoloISO. 

#### Main differences

The main differences with these projects is that this project is not trying
to work "easily" for everyone. This is for targeted setups (notably headless).

For example, the Nvidia Docker images come with drivers pre-installed (and you
can build your own) to prevent any driver installation issues when executing
the containers. This also allows container boot to be faster.

## Shoutouts
- Josh5
	- I'd say rouglhy 80% of this project is copied or inspired by Josh5's steam-headless
	- [Steam-headless Dockerfile](https://github.com/Steam-Headless/docker-steam-headless/blob/14c770bce61db99c56592760c73c2ba454dab648/Dockerfile.debian#L1)
	- and _a lot_ of setup for both Nvidia and Xorg
- Lizardbyte
	- [Sunshine dockerfile](https://github.com/LizardByte/Sunshine/blob/c6f36474ba9b492eea2a60930ca7304ea96176af/docker/debian-bookworm.dockerfile)
- keylase
	- [NVENC and NvFBC patches](https://github.com/keylase/nvidia-patch)
	- And enourmous shoutout to `vojtad` for commit [95dd542](https://github.com/keylase/nvidia-patch/commit/95dd542a8014578f91ffdd864a37b67b19c8948e) allowing us to pass driver version manually
- e-dong
	- Virtual display guide Reddit
	- [Virtual display docs Sunshine](https://app.lizardbyte.dev/2023-09-14-remote-ssh-headless-sunshine-setup/?lng=en-US#virtual-display-setup)
- goryny4
	- For [evdev file for X11](https://gist.github.com/goryny4/014815ab73bede4f2184)
- Gun_Demirbas
	- Figuring out the [magic udev rules to make input work](https://discuss.linuxcontainers.org/t/headless-wayland-container-streaming-via-sunshine-sway-libinput-not-finding-input-devices/18852/7)

## Getting Started

### AMD Graphic Cards
Plasma has been tested with an AMD Radeon Pro WX 2100.
Configuring Plasma to run with an AMD card is rather easy.

### Nvidia Graphic Cards
Plasma has been tested with an Nvidia Quadro P400.
Configuring for Nvidia is considerably more involved than AMD, but 
it does work well.

### Intel GPUs
Intel GPUs are untested. Use at your own discretion.

#### Test command (Docker)

NVIDIA
```sh
sudo docker run -it --rm \
	--entrypoint bash \
	--runtime nvidia  \
	--gpus all \
	--shm-size 1g \
	-v /dev/input:/dev/input \
	-v /dev/uinput:/dev/uinput \
	-p 47984-47990:47984-47990/tcp \
	-p 48010:48010 \
	-p 47998-48000:47998-48000/udp \
	--privileged \
	plasma:nvidia-570-test
```

AMD
```sh
sudo docker run -it --rm \
	--entrypoint bash \
	--shm-size 1g \
	-v /dev/input:/dev/input \
	-v /dev/uinput:/dev/uinput \
	-v /dev/dri:/dev/dri \
	-p 47984-47990:47984-47990/tcp \
	-p 48010:48010 \
	-p 47998-48000:47998-48000/udp \
	--privileged \
	plasma:amd-gcn1.0-test
```

## Docs

Check the [GitHub Wiki](https://github.com/jsmrcaga/plasma/wiki)!

