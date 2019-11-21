FROM centos
ENV trace=false
USER root
COPY run.sh /root
RUN yum -y --enablerepo=extras install epel-release git which wget tmux \
    && yum clean all && rm -rf /var/cache/yum \
    && chmod 777 /root/run.sh
ENTRYPOINT ["/root/run.sh"]
