#!/usr/bin/env bash
set -e
BUILD_FILE="lambda.zip"

rm -f ${BUILD_FILE}

mkdir -p clamav

docker pull amazonlinux
docker create -i -t -v ${PWD}/clamav:/home/docker  --name av-deamon-builder amazonlinux
docker start av-deamon-builder

docker exec -it -w /home/docker av-deamon-builder yum install -y cpio yum-utils
docker exec -it -w /home/docker av-deamon-builder yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
docker exec -it -w /home/docker av-deamon-builder yum-config-manager --enable epel
docker exec -it -w /home/docker av-deamon-builder yumdownloader -x \*i686 --archlist=x86_64 clamav clamav-lib clamav-update json-c pcre2 clamd systemd-libs lz4 procps elfutils-libs elfutils-libelf libxml2 bzip2-libs libtool-ltdl xz-libs libgcrypt libgpg-error
docker exec -it -w /home/docker av-deamon-builder /bin/sh -c "rpm2cpio procps*.rpm | cpio -idmv"
docker exec -it -w /home/docker av-deamon-builder /bin/sh -c "rpm2cpio clamav-0*.rpm | cpio -idmv"
docker exec -it -w /home/docker av-deamon-builder /bin/sh -c "rpm2cpio clamav-lib*.rpm | cpio -idmv"
docker exec -it -w /home/docker av-deamon-builder /bin/sh -c "rpm2cpio clamav-update*.rpm | cpio -idmv"
docker exec -it -w /home/docker av-deamon-builder /bin/sh -c "rpm2cpio clamd*.rpm | cpio -idmv"
docker exec -it -w /home/docker av-deamon-builder /bin/sh -c "rpm2cpio systemd*.rpm | cpio -idmv"
docker exec -it -w /home/docker av-deamon-builder /bin/sh -c "rpm2cpio lz4*.rpm | cpio -idmv"
docker exec -it -w /home/docker av-deamon-builder /bin/sh -c "rpm2cpio json-c*.rpm | cpio -idmv"
docker exec -it -w /home/docker av-deamon-builder /bin/sh -c "rpm2cpio pcre2*.rpm | cpio -idmv"
docker exec -it -w /home/docker av-deamon-builder /bin/sh -c "rpm2cpio elfutils-libs*.rpm | cpio -idmv"
docker exec -it -w /home/docker av-deamon-builder /bin/sh -c "rpm2cpio elfutils-libelf*.rpm | cpio -idmv"
docker exec -it -w /home/docker av-deamon-builder /bin/sh -c "rpm2cpio libxml2*.rpm | cpio -idmv"
docker exec -it -w /home/docker av-deamon-builder /bin/sh -c "rpm2cpio bzip2-libs*.rpm | cpio -idmv"
docker exec -it -w /home/docker av-deamon-builder /bin/sh -c "rpm2cpio libtool-ltdl*.rpm | cpio -idmv"
docker exec -it -w /home/docker av-deamon-builder /bin/sh -c "rpm2cpio xz-libs*.rpm | cpio -idmv"
docker exec -it -w /home/docker av-deamon-builder /bin/sh -c "rpm2cpio libgcrypt*.rpm | cpio -idmv"
docker exec -it -w /home/docker av-deamon-builder /bin/sh -c "rpm2cpio libgpg-error*.rpm | cpio -idmv"

docker stop av-deamon-builder
docker rm av-deamon-builder

mkdir -p ./bin
mkdir -p ./lib64

cp -r clamav/usr/sbin/clamd clamav/usr/bin/clamscan clamav/usr/bin/clamdscan clamav/usr/bin/freshclam clamav/usr/lib64/* clamav/lib64/* ./src/* ./node_modules bin/.
cp -r clamav/usr/lib64/* lib64/.

pushd ./bin
zip -r9 ${BUILD_FILE} * lib64
popd

cp bin/${BUILD_FILE} .

rm -rf bin lib64 clamav