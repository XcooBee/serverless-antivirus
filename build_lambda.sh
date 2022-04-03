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
docker exec -it -w /home/docker av-deamon-builder yumdownloader -x \*i686 --archlist=x86_64 clamav clamav-lib clamav-update clamd systemd-libs json-c pcre2 libxml2 bzip2-libs libtool-ltdl xz-libs libprelude gnutls nettle libcurl libnghttp2 libidn2 libssh2 openldap libffi krb5-libs keyutils-libs libunistring cyrus-sasl-lib nss nspr libselinux openssl-libs libcrypt

docker exec -it -w /home/docker av-deamon-builder /bin/sh -c "rpm2cpio clamav-0*.rpm | cpio -idmv"
docker exec -it -w /home/docker av-deamon-builder /bin/sh -c "rpm2cpio clamav-lib*.rpm | cpio -idmv"
docker exec -it -w /home/docker av-deamon-builder /bin/sh -c "rpm2cpio clamav-update*.rpm | cpio -idmv"
docker exec -it -w /home/docker av-deamon-builder /bin/sh -c "rpm2cpio clamd*.rpm | cpio -idmv"
docker exec -it -w /home/docker av-deamon-builder /bin/sh -c "rpm2cpio systemd*.rpm | cpio -idmv"
docker exec -it -w /home/docker av-deamon-builder /bin/sh -c "rpm2cpio json-c*.rpm | cpio -idmv"
docker exec -it -w /home/docker av-deamon-builder /bin/sh -c "rpm2cpio pcre*.rpm | cpio -idmv"
docker exec -it -w /home/docker av-deamon-builder /bin/sh -c "rpm2cpio libxml2*.rpm | cpio -idmv"
docker exec -it -w /home/docker av-deamon-builder /bin/sh -c "rpm2cpio bzip2-libs*.rpm | cpio -idmv"
docker exec -it -w /home/docker av-deamon-builder /bin/sh -c "rpm2cpio libtool-ltdl*.rpm | cpio -idmv"
docker exec -it -w /home/docker av-deamon-builder /bin/sh -c "rpm2cpio xz-libs*.rpm | cpio -idmv"
docker exec -it -w /home/docker av-deamon-builder /bin/sh -c "rpm2cpio libprelude*.rpm | cpio -idmv"
docker exec -it -w /home/docker av-deamon-builder /bin/sh -c "rpm2cpio gnutls*.rpm | cpio -idmv"
docker exec -it -w /home/docker av-deamon-builder /bin/sh -c "rpm2cpio nettle*.rpm | cpio -idmv"
docker exec -it -w /home/docker av-deamon-builder /bin/sh -c "rpm2cpio libcurl*.rpm | cpio -idmv"
docker exec -it -w /home/docker av-deamon-builder /bin/sh -c "rpm2cpio libnghttp2*.rpm | cpio -idmv"
docker exec -it -w /home/docker av-deamon-builder /bin/sh -c "rpm2cpio libidn2*.rpm | cpio -idmv"
docker exec -it -w /home/docker av-deamon-builder /bin/sh -c "rpm2cpio libssh2*.rpm | cpio -idmv"
docker exec -it -w /home/docker av-deamon-builder /bin/sh -c "rpm2cpio openldap*.rpm | cpio -idmv"
docker exec -it -w /home/docker av-deamon-builder /bin/sh -c "rpm2cpio libffi*.rpm | cpio -idmv"
docker exec -it -w /home/docker av-deamon-builder /bin/sh -c "rpm2cpio krb5-libs*.rpm | cpio -idmv"
docker exec -it -w /home/docker av-deamon-builder /bin/sh -c "rpm2cpio keyutils-libs*.rpm | cpio -idmv"
docker exec -it -w /home/docker av-deamon-builder /bin/sh -c "rpm2cpio libunistring*.rpm | cpio -idmv"
docker exec -it -w /home/docker av-deamon-builder /bin/sh -c "rpm2cpio cyrus-sasl-lib*.rpm | cpio -idmv"
docker exec -it -w /home/docker av-deamon-builder /bin/sh -c "rpm2cpio nss*.rpm | cpio -idmv"
docker exec -it -w /home/docker av-deamon-builder /bin/sh -c "rpm2cpio nspr*.rpm | cpio -idmv"
docker exec -it -w /home/docker av-deamon-builder /bin/sh -c "rpm2cpio libselinux*.rpm | cpio -idmv"
docker exec -it -w /home/docker av-deamon-builder /bin/sh -c "rpm2cpio openssl-libs*.rpm | cpio -idmv"
docker exec -it -w /home/docker av-deamon-builder /bin/sh -c "rpm2cpio libcrypt*.rpm | cpio -idmv"

docker stop av-deamon-builder
docker rm av-deamon-builder

mkdir -p ./bin
mkdir -p ./lib64

cp -r clamav/usr/sbin/clamd clamav/usr/bin/clamscan clamav/usr/bin/clamdscan clamav/usr/bin/freshclam clamav/usr/lib64/* clamav/lib64/* ./src/* ./node_modules bin/.
cp -r clamav/usr/lib64/* lib64/.
cp clamav/lib64/libcrypt-2.26.so bin/libcrypt.so.1

pushd ./bin
zip -r9 ${BUILD_FILE} * lib64
popd

cp bin/${BUILD_FILE} .

rm -rf bin lib64 clamav