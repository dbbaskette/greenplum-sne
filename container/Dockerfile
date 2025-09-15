FROM --platform=linux/amd64 rockylinux/rockylinux:9

# Install required system packages for Greenplum
RUN dnf update -y && \
    dnf install -y --allowerasing \
        sudo \
        openssh-server \
        openssh-clients \
        wget \
        curl \
        which \
        less \
        rsync \
        tar \
        gzip \
        unzip \
        net-tools \
        iproute \
        iputils \
        procps-ng \
        util-linux \
        passwd \
        cronie \
        python3 \
        python3-pip \
        python3-psutil \
        python3-psycopg2 \
        python3-pyyaml \
        python3.11 \
        python3-devel \
        java-11-openjdk \
        java-11-openjdk-devel \
        ed \
        zip \
        unzip \
        sshpass \
        expect \
        hostname \
        initscripts \
        systemd \
        apr \
        apr-util \
        bzip2 \
        krb5-devel \
        libevent-devel \
        libuv \
        perl \
        perl-libs \
        readline-devel \
        libicu \
        git \
        make \
        gcc \
        gcc-c++ && \
    dnf clean all

# Set up SSH service
RUN ssh-keygen -A && \
    systemctl enable sshd

# Set hostname for Greenplum
RUN echo "greenplum-sne" > /etc/hostname

# Create gpadmin user with required settings
RUN groupadd gpadmin && \
    useradd -g gpadmin -m -d /home/gpadmin -s /bin/bash gpadmin && \
    echo 'gpadmin:VMware1!' | chpasswd && \
    echo 'root:VMware1!' | chpasswd && \
    echo 'gpadmin ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

# Create Greenplum data directories
RUN mkdir -p /home/gpdata/coordinator /home/gpdata/primary && \
    chown -R gpadmin:gpadmin /home/gpdata && \
    chmod 755 /home/gpdata /home/gpdata/coordinator /home/gpdata/primary

# Set up SSH for gpadmin (passwordless SSH to localhost)
USER gpadmin
WORKDIR /home/gpadmin

RUN ssh-keygen -t rsa -N '' -f ~/.ssh/id_rsa && \
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys && \
    chmod 600 ~/.ssh/authorized_keys && \
    chmod 700 ~/.ssh && \
    echo "Host *" >> ~/.ssh/config && \
    echo "    StrictHostKeyChecking no" >> ~/.ssh/config && \
    echo "    UserKnownHostsFile /dev/null" >> ~/.ssh/config && \
    echo "    LogLevel ERROR" >> ~/.ssh/config && \
    chmod 600 ~/.ssh/config

# Switch back to root for installation
USER root

# Copy Greenplum RPM and scripts
COPY files/greenplum-db-*.rpm /tmp/
COPY scripts/install-greenplum.sh /tmp/
COPY scripts/startup.sh /usr/local/bin/
COPY scripts/startup-installed.sh /usr/local/bin/
RUN chmod +x /tmp/install-greenplum.sh /usr/local/bin/startup.sh /usr/local/bin/startup-installed.sh

# Set environment variables
ENV GPHOME=/usr/local/greenplum-db
ENV COORDINATOR_DATA_DIRECTORY=/home/gpdata/coordinator/gpseg-1
ENV PGPORT=5432
ENV PGUSER=gpadmin
ENV PGDATABASE=postgres

# Expose Greenplum ports (5432 will be mapped externally to 15432)
EXPOSE 5432 6000-6010 22

# Set the startup command
CMD ["/usr/local/bin/startup.sh"]