# MADlib Extension for Greenplum SNE
# Extends the PXF-enabled container with MADlib machine learning capabilities

FROM greenplum-sne-pxf:latest

# Copy MADlib archive and installation script
COPY files/madlib-2.2.0-gp7-el9-x86_64.tar.gz /tmp/
COPY extensions/madlib/install-madlib.sh /tmp/

# Install MADlib
RUN chmod +x /tmp/install-madlib.sh && \
    /tmp/install-madlib.sh && \
    rm -f /tmp/madlib-2.2.0-gp7-el9-x86_64.tar.gz /tmp/install-madlib.sh

# Copy startup script that includes both PXF and MADlib
COPY extensions/madlib/startup-full.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/startup-full.sh

# Override startup to include MADlib initialization
CMD ["/usr/local/bin/startup-full.sh"]