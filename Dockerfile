FROM registry.redhat.io/openshift4/ose-jenkins-agent-base:latest
USER 0:0

RUN PACKAGES="openssl jq" \
 && yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm \
 && yum -y install $PACKAGES \
 && yum clean all \
 && rm -rf /var/cache/yum

WORKDIR /tmp
RUN ver=1.2.3 \
 && curl -fsSLO https://releases.hashicorp.com/vault/${ver}/vault_${ver}_linux_amd64.zip \
 && unzip vault_${ver}_linux_amd64.zip \
 && cp vault /usr/bin

# in OpenShift the actual user/UID will be randomly assigned
USER 1001:0
