#!/bin/bash

ANSI_YELLOW="\033[33;1m"

listify() {
  local IFS="$1"; shift; echo "$*";
}

bootstrap_header() {
  echo -e "${ANSI_YELLOW}$1${ANSI_RESET}"
}

# version numbers
COMPOSE_VERSION=${COMPOSE_VERSION:-1.2.0}

bootstrap_header "Set required environment variables"
travis_cmd export\ SLIRP_HOST\=\"\$\(/sbin/ifconfig\ venet0:0\ \|\ grep\ \'inet\ addr\'\ \|\ awk\ -F:\ \'\{print\ \$2\}\'\ \|\ awk\ \'\{print\ \$1\}\'\)\" --echo
travis_cmd export\ SLIRP_PORTS\=\"\$\(listify\ ,\ 2375\ \$\{SLIRP_PORTS:-\$\(seq\ 49153\ 49253\)\}\)\" --echo
travis_cmd export\ DOCKER_HOST\=\"tcp://\$\{SLIRP_HOST\}:2375\" --echo
travis_cmd export\ DOCKER_PORT_RANGE\=\"2400:2500\" --echo
echo

bootstrap_header "Disable post-install autorun"
echo exit 101 | sudo tee /usr/sbin/policy-rc.d
sudo chmod +x /usr/sbin/policy-rc.d


set +x
echo "Installing dependencies" >&2
set -x
sudo apt-get update
sudo apt-get install -y slirp lxc aufs-tools cgroup-lite


set +x
echo "Installing docker" >&2
set -x
curl -s https://get.docker.com/ | sh
sudo usermod -aG docker $USER
sudo chown -R $USER /etc/docker


if [ -z ${NO_COMPOSE+1} ]; then
  set +x
  echo "Installing docker-compose" >&2
  set -x
  sudo curl -L https://github.com/docker/compose/releases/download/$COMPOSE_VERSION/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose
fi


set +x
echo "Downloading sekexe" >&2
set -x
git clone git://github.com/voidlock/sekexe .sekexe

set +x
echo "Starting Docker deamon" >&2
set -x
./.sekexe/run 'docker -d -H tcp://0.0.0.0:2375' &

set +x
echo "Waiting for Docker to come online" >&2
set -x
while ! docker info; do sleep 1; done

docker version
set +xe
