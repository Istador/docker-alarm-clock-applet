#!/bin/bash
set  -e
dir=$(dirname  "$0")
cd  "$dir"


# this project
registry="registry.gitlab.com"
namespace="istador/docker-alarm-clock-applet"
image="$registry/$namespace"


# current version
major="0"
minor="3"
patch="4"
release="11"
version="$major.$minor.$patch"


# version image tags
version1="$major.$minor.$patch-$release"
version2="$major.$minor.$patch"
version3="$major.$minor"
version4="$major"


# parse arguments
platform=""
platforms=""
push="--load"
all="0"
function usage {
  echo "usage: $0  [OPTIONS]"
  echo "  --all     build for all architectures"
  echo "  --arch=*  build for this architecture (e.g. linux/amd64)"
  echo "  --push    push to docker registry"
  echo "  --help    display this usage information"
}
while (( "$#" )) ; do
  case "$1" in
      --help)  usage ; exit 0 ;;
      --push)  push="--push" ; shift ;;
    --arch=*)  platforms="$platforms,${1:7}" ; shift ;;
       --all)  all="1" ; shift ;;
           *)  >&2  echo  "ERROR: unknown argument $1" ;  usage  ;  exit  1 ;;
  esac
done
if [ "$all" = "1" ] ; then
  # not: linux/s390x b/c of seg fault during build
  platforms="linux/amd64,linux/386,linux/ppc64le,linux/arm64,linux/arm/v7,linux/arm/v6"
else
  platforms="${platforms:1}"
fi
if [ "$platforms" != "" ] ; then
  platform="--platform=$platforms"
fi


# cache settings
cache_dir="./build/cache"
cache_from="--cache-from=type=local,src=$cache_dir"
cache_to="--cache-to=type=local,mode=max,dest=$cache_dir"
cache="$cache_from $cache_to"
mkdir  -p  $cache_dir


# docker settings
export DOCKER_BUILDKIT=1
export DOCKER_CLI_EXPERIMENTAL=enabled
export BUILDX_NO_DEFAULT_LOAD=0


# runtime image with deb installed
docker  buildx  build           \
  --pull                        \
  $push                         \
  $cache                        \
  $platform                     \
  --build-arg VERSION=$version  \
  --build-arg RELEASE=$release  \
  --target=runtime              \
  --tag $image:$version1        \
  --tag $image:$version2        \
  --tag $image:$version3        \
  --tag $image:$version4        \
  --tag $image:latest           \
  --file ./Dockerfile           \
  .                             \
;
echo  "### build: $image:$version1"


for  p  in  $(IFS=','  ;  echo $platforms)  ;  do
  arch="${p:6}"
  arch="${arch/\//_}"
  tag="$version1-build-$arch"

  # tag the deb builder for platform
  docker  buildx  build           \
    --pull                        \
    --load                        \
    $cache_from                   \
    --platform=$p                 \
    --build-arg VERSION=$version  \
    --build-arg RELEASE=$release  \
    --target=build                \
    --tag $image:$tag             \
    --file ./Dockerfile           \
    .                             \
  ;
  echo  "### tag: $image:$tag"

  # extract deb files
  deb="./build/$version1/alarm-clock-applet_${version1}_${arch}.deb"
  mkdir  -p  ./build/$version1/
  docker  run         \
    --rm              \
    --platform=$p     \
    --entrypoint cat  \
    $image:$tag       \
    /install.deb      \
    >$deb             \
  ;
  echo  "### extracted: $deb"

  # untag deb builder for platform
  docker  rmi  $image:$tag
  echo  "### untag: $image:$tag"
done
