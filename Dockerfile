# Base Image
FROM fedora:latest

# Labels
LABEL maintainer "bpetkov13@gmail.com"

# Updates package lists and installs Tahoe-LAFS
RUN dnf -y update && \
    dnf -y install python-devel \
    	   	   gcc \
		   gcc-c++ \
		   libffi-devel \
		   openssl-devel \
		   redhat-rpm-config

RUN pip install -U pip

#
RUN mkdir /app && \
    cd /app

#
RUN useradd director && \
    chown -R director /app
USER director

#
RUN pip install --user tahoe-lafs

#
CMD ["/bin/bash", "lafs_setup.sh"]