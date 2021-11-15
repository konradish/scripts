#!/bin/bash
docker_container=${1:-debian}

	#-v $(pwd)/../dotfiles:/root/dotfiles \
docker run -it -v /var/run/docker.sock:/var/run/docker.sock -e LANG=C.UTF-8 -e LC_ALL=C.UTF-8 -e TERM=$TERM --rm \
	-v $(pwd):/root/scripts \
	-w /root/scripts "$docker_container" ./setup_env.sh
