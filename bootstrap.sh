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


travis_fold start docker.env
  bootstrap_header "Set required environment variables"
  travis_cmd export\ SLIRP_HOST\=\"\$\(/sbin/ifconfig\ venet0:0\ \|\ grep\ \'inet\ addr\'\ \|\ awk\ -F:\ \'\{print\ \$2\}\'\ \|\ awk\ \'\{print\ \$1\}\'\)\" --echo
  travis_cmd export\ SLIRP_PORTS\=\"\$\(listify\ ,\ 2375\ \$\{SLIRP_PORTS:-\$\(seq\ 49153\ 49253\)\}\)\" --echo
  travis_cmd export\ DOCKER_HOST\=\"tcp://\$\{SLIRP_HOST\}:2375\" --echo
  travis_cmd export\ DOCKER_PORT_RANGE\=\"49153:49253\" --echo
  echo
  echo "SLIRP_HOST=\"${SLIRP_HOST}\""
  echo "SLIRP_PORTS=\"${SLIRP_PORTS}\""
  echo "DOCKER_HOST=\"${DOCKER_HOST}\""
  echo "DOCKER_PORT_RANGE=\"${DOCKER_PORT_RANGE}\""
travis_fold end docker.env


bootstrap_header "Disable post-install autorun"
echo exit 101 | sudo tee /usr/sbin/policy-rc.d
sudo chmod +x /usr/sbin/policy-rc.d


travis_fold start docker.deps
  bootstrap_header "Installing dependencies"
  sudo apt-get update
  sudo apt-get install -y slirp lxc aufs-tools cgroup-lite
travis_fold end docker.deps


travis_fold start docker.install
  bootstrap_header "Installing docker"
  curl -s https://get.docker.com/ | sh
  sudo usermod -aG docker $USER
  sudo chown -R $USER /etc/docker
travis_fold end docker.install


if [ -z ${NO_COMPOSE+1} ]; then
  travis_fold start compose.install
    bootstrap_header "Installing docker-compose"
    sudo curl -L https://github.com/docker/compose/releases/download/$COMPOSE_VERSION/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
  travis_fold end compose.install
fi


travis_fold start sekexe.install
  bootstrap_header "Downloading sekexe"
  git clone git://github.com/voidlock/sekexe .sekexe
travis_fold end sekexe.install


travis_fold start docker.start
  bootstrap_header "Starting Docker deamon"
  ./.sekexe/run 'docker -d -H tcp://0.0.0.0:2375' &

  bootstrap_header "Waiting for Docker to come online"
  while ! docker info; do sleep 1; done
travis_fold end docker.start


travis_fold start docker.version
  docker version
travis_fold end docker.version
