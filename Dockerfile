FROM amazonlinux:2

WORKDIR /home/build

RUN set -e

RUN echo "Prepping ClamAV"

RUN rm -rf bin
RUN rm -rf lib

RUN yum update -y
RUN amazon-linux-extras install epel -y
RUN yum install -y cpio yum-utils tar.x86_64 gzip zip

RUN yumdownloader -x \*i686 --archlist=x86_64 clamav
RUN rpm2cpio clamav-0*.rpm | cpio -vimd

RUN yumdownloader -x \*i686 --archlist=x86_64 clamav-lib
RUN rpm2cpio clamav-lib*.rpm | cpio -vimd

RUN yumdownloader -x \*i686 --archlist=x86_64 clamav-update
RUN rpm2cpio clamav-update*.rpm | cpio -vimd

RUN yumdownloader -x \*i686 --archlist=x86_64 json-c
RUN rpm2cpio json-c*.rpm | cpio -vimd

RUN yumdownloader -x \*i686 --archlist=x86_64 pcre2
RUN rpm2cpio pcre*.rpm | cpio -vimd

RUN yumdownloader -x \*i686 --archlist=x86_64 libtool-ltdl
RUN rpm2cpio libtool-ltdl*.rpm | cpio -vimd

RUN yumdownloader -x \*i686 --archlist=x86_64 libxml2
RUN rpm2cpio libxml2*.rpm | cpio -vimd

RUN yumdownloader -x \*i686 --archlist=x86_64 bzip2-libs
RUN rpm2cpio bzip2-libs*.rpm | cpio -vimd

RUN yumdownloader -x \*i686 --archlist=x86_64 xz-libs
RUN rpm2cpio xz-libs*.rpm | cpio -vimd

RUN yumdownloader -x \*i686 --archlist=x86_64 libprelude
RUN rpm2cpio libprelude*.rpm | cpio -vimd

RUN yumdownloader -x \*i686 --archlist=x86_64 gnutls
RUN rpm2cpio gnutls*.rpm | cpio -vimd

RUN yumdownloader -x \*i686 --archlist=x86_64 nettle
RUN rpm2cpio nettle*.rpm | cpio -vimd

RUN mkdir -p bin
RUN mkdir -p lib
RUN mkdir -p var/lib/clamav
RUN chmod -R 777 var/lib/clamav

RUN yum install shadow-utils.x86_64 -y

RUN groupadd clamav
RUN useradd -g clamav -s /bin/false -c "Clam Antivirus" clamav
RUN useradd -g clamav -s /bin/false -c "Clam Antivirus" clamupdate
COPY ./freshclam.conf bin/freshclam.conf

RUN cp usr/bin/clamscan usr/bin/freshclam /usr/bin/curl bin/.
RUN mkdir -p /opt/var/lib/clamav ; chown clamupdate:clamav /opt/var/lib/clamav 

# symlinks to hard links
RUN cd /lib64 ; ls -la | grep -v libc\.so | egrep ' lib.* -> lib' | sed -e 's/.* \(lib.*\) -> \(lib.*\)/rm \1 ; ln \2 \1/' | bash
# then copy the curl dependancies
RUN cd /lib64 ; for i in $(ldd /usr/bin/curl | awk '{ print $1 }'); do [ -f $i ]&&cat $i > /home/build/lib/$i ; done; true

RUN cp -a usr/lib64/* lib/
RUN cd lib ; ls -la | egrep ' lib.* -> lib' | sed -e 's/.* \(lib.*\) -> \(lib.*\)/rm \1 ; mv \2 \1/' ; cd ..
RUN LD_LIBRARY_PATH=./lib  ./bin/freshclam --config-file=bin/freshclam.conf
RUN chmod -R a+rwX /opt/var/lib/clamav
RUN cp -av /opt/var/lib/clamav/* var/lib/clamav

RUN zip -r0 clamav_lambda_layer.zip bin
RUN zip -r0 clamav_lambda_layer.zip lib
RUN zip -r0 clamav_lambda_layer.zip var
RUN zip -r0 clamav_lambda_layer.zip etc
