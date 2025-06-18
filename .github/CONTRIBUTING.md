![banner](https://github.com/user-attachments/assets/d62c8361-340c-4139-98d6-6050bff728eb)

<h1 align="center">Contributing</h1>

## Versioning

Plasma is versioned depending on its own version, but also the GPU model and driver versions.

This allows users to install pre-baked images or modify only to their needs.

Versions look like this
* `plasma:latest`: the latest version of the base image
* `plasma:v2.3.4`: v2.3.4 of the base image
* `plasma:v2.3.4-AMD-1.0`: v2.3.4 of the AMD image for `radeon` drivers
* `plasma:v2.3.4-AMD-4.0`: v2.3.4 of the AMD image for `amdgpu` drivers
* `plasma:v2.3.4-NVIDIA-570.144`: v2.3.4 of the NVIDIA image for driver version 570.144

We will certainly drop support for `radeon` drivers since they only support GCN 1.0 and 1.1, which are pretty old.

## Contributing

Feel free to contribute to Plasma!
If this repo feels "too slow" for you, feel free to fork it.
Just bear in mind our License.

### Adding direct contributions

Feel free to create Pull Requests to add direct contributions to Plasma!

Since Plasma is made out of bash scripts and config files, there's no linter
configured at the moment, but that will probably change in the future.

Make sure to leave spaces for readability and comments for future people
consulting the project (can't tell you how useful some comments in docker-steam-headless)
were for me!)

When opening a pull request a template will be provided, make sure to include
any relevant information like bug reports, feature requests, use cases and screenshots
if necessary.

For finding more information on developing locally, take a look at [Development](#development).


### Suggesting Features

You can also suggest features for Plasma. Please note that features will be added
by the community, so no dates, deadlines or releases will be communicated.

If you need a feature urgently, consider adding the contribution :)


### Reporting issues

Similar to suggesting features, Issues will be solved by the community.

Unless they are a security vulnerability, these won't be tackled as a priority, and
only handled by the community

## Development

### Environment setup

* You will need Docker in your development machine
* [Optional] You may need `node` and `npm` in your development machine (for scripting)
* You will need the code editor of your choice
* You will need a machine with a graphics card (preferably different from your development machine)
	* That machine will also need Docker

### Building Plasma locally

Some utility scripts are provided in the `package.json` file, to use with `npm`.

* `npm run build:local:base` will build the base image from the `Dockerfile`
* `npm run build:local:amd` will build the AMD `amdgpu` image from the base image built by the `build:local:base` command
* Similarly, using the base image:
	* `build:local:amd:1.0` will build the `radeon` AMD image
	* `build:local:nvidia` will build an NVIDIA image with default driver version (570.144)
	* `build:local:intel` will build an Intel image

Using `docker image ls` you will be able to see the images and tags built by those commands.
You can also inspect the `package.json` file to get more info.

All these commands need to be run from the root of the project.

### Testing your image

First things first, if your image contains changes that can be tested without
Sunshine (ie: added some config files, or installed some programs), you can run
it in your development machine and inspect.

Here's an example for an image built with `build:local:amd`:
*  `docker run -it --rm --entrypoint bash plasma:amd-test`

This will open a bash session in a new container of that image.

If your changes include visual aspecs, the easiest way is to get your image
to your "GPU machine". There are many ways to do this:
- you could commit to a branch, pull the branch in that machine and build locally
- or build in your dev machine, and transmit the image

#### Transmitting the image from your dev machine to GPU machine

You will first need to create a binary of your image, and then transfer it and load it.

Creating the binary is straightforward:
* `docker save -o plasma.tar plasma:amd-test`

This will create a .tar archive named `plasma.tar` from the image tagged `plasma:amd-test`

You can choose how to transfer the image. A very simple way is to use `scp`.

Finally, you'll need to load the image:
* `docker load -i ./plasma.tar` 
This command will load the .tar image into Docker's image list

#### Running the image in your GPU machine

You can run these commands (from README):

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
	-v <some directory>:/home/<your user> \
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
	-v <some directory>:/home/<your user> \
	plasma:amd-test
```
