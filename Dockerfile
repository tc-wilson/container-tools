FROM centos:8
USER root
COPY run.sh /root
COPY rt.repo /etc/yum.repos.d/
RUN yum -y install rt-tests rteval \
    && rm -rf /etc/yum.repos.d/rt.repo \
    && yum -y --enablerepo=extras install epel-release git which pciutils wget tmux \
      python3 net-tools libtool automake gcc gcc-c++ cmake autoconf \
      unzip python3-six numactl-devel make kernel-devel numactl-libs \
      libibverbs libibverbs-devel rdma-core-devel \
      libibverbs-utils mstflint \
    && KVER=$(uname -r) \
    && DVER=$(rpm -q kernel-devel | sed -e 's/kernel-devel-//') \
    && mkdir -p /lib/modules/${KVER} \
    && ln -fs /usr/src/kernels/${DVER} \
      /lib/modules/${KVER}/build \
    && cd /root && git clone https://github.com/DPDK/dpdk.git \
    && cd /root/dpdk && git checkout origin/releases \
    && make install RTE_SDK=`pwd` T=x86_64-native-linux-gcc \
      DESTDIR=/root/dpdk CONFIG_RTE_LIBRTE_MLX5_PMD=y \
    && cd /root && install /root/dpdk/bin/testpmd \
      /root/dpdk/sbin/dpdk-devbind '/usr/local/bin' \
    && rm -rf /root/dpdk /etc/yum.repos.d/rt.repo \
    && yum clean all && rm -rf /var/cache/yum \
    && wget -O /root/dumb-init https://github.com/Yelp/dumb-init/releases/download/v1.2.2/dumb-init_1.2.2_amd64 \
    && chmod 777 /root/dumb-init \
    && chmod 777 /root/run.sh
ENTRYPOINT ["/root/dumb-init", "--"]
CMD ["/root/run.sh"]
