FROM balenalib/amd64-ubuntu:latest

RUN install_packages curl git jq docker.io ntpdate bind9-dnsutils

RUN git clone https://github.com/balena-io-modules/device-diagnostics.git

COPY entry.sh /bin/

CMD /bin/entry.sh

