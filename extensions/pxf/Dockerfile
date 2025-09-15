# PXF Extension for Greenplum SNE
# Extends the base greenplum-sne container with PXF functionality

FROM greenplum-sne-base:latest

# Install Java 11 (required for PXF)
RUN dnf update -y && \
    dnf install -y java-11-openjdk java-11-openjdk-devel && \
    dnf clean all

# Set JAVA_HOME
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk

# Copy PXF RPM and installation script
COPY files/pxf-gp7-7.0.0-2.el9.x86_64.rpm /tmp/
COPY extensions/pxf/install-pxf.sh /tmp/

# Install PXF
RUN chmod +x /tmp/install-pxf.sh && \
    /tmp/install-pxf.sh && \
    rm -f /tmp/pxf-gp7-7.0.0-2.el9.x86_64.rpm /tmp/install-pxf.sh

# Copy PXF startup script
COPY extensions/pxf/startup-pxf.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/startup-pxf.sh

# Override startup to include PXF initialization
CMD ["/usr/local/bin/startup-pxf.sh"]