FROM centos:7
ENV trace=false
USER root
COPY run.sh /root
RUN yum -y --enablerepo=extras install epel-release git which wget tmux \
    && yum clean all && rm -rf /var/cache/yum \
    && wget -O /root/dumb-init https://github.com/Yelp/dumb-init/releases/download/v1.2.2/dumb-init_1.2.2_amd64 \
    && chmod 777 /root/dumb-init \
    && chmod 777 /root/run.sh
ENTRYPOINT ["/root/dumb-init", "--"]
CMD ["/root/run.sh"]
