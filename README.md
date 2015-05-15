# travis-docker

Bootstraps docker into a travis build.

## Usage

The following is a sample `.travis.yml` file:

```yaml
install:
  - curl -sLo - https://raw.githubusercontent.com/voidlock/travis-docker/master/docker-bootstrap.sh | source /dev/stdin

script:
  - docker version
  - docker pull redis:latest
  - docker run --name=redis -d redis:latest
  - docker ps
  - docker port redis
  - docker run --rm --link=redis:db redis:latest redis-cli -h db info
```

## TODO

* Write more docs around customization points
* Explore level of integration with 0.0.0.0
