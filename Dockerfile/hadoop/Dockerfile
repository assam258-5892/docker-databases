FROM ubuntu:22.04

ARG TARGETARCH
ENV DEBIAN_FRONTEND noninteractive

RUN ["apt-get", "update"]
RUN ["apt-get", "install", "-y", "locales"]
RUN ["locale-gen", "ko_KR.UTF-8"]
ENV LC_ALL ko_KR.UTF-8

RUN ["apt-get", "install", "-y", "openssh-server"]
RUN ["apt-get", "install", "-y", "openjdk-8-jdk-headless"]
RUN ["apt-get", "install", "-y", "postgresql"]
RUN ["apt-get", "install", "-y", "vim", "jed"]

RUN ["sh", "-c", "ln -s java-8-openjdk-${TARGETARCH} /usr/lib/jvm/java-8-openjdk"]

RUN ["chmod", "u+s", "/usr/sbin/sshd"]
RUN ["mkdir", "/run/sshd"]
COPY --chown=root:root ssh /etc/ssh

RUN ["useradd", "-m", "hadoop"]
RUN ["chsh", "-s", "/bin/bash", "hadoop"]
USER hadoop
WORKDIR /home/hadoop

COPY --chown=hadoop:hadoop package       package
COPY --chown=hadoop:hadoop .ssh          .ssh
COPY --chown=hadoop:hadoop entrypoint.sh entrypoint.sh

RUN ["chmod", "go-rwx", ".ssh/id_rsa"]

RUN ["sh", "-c", "cat package/hadoop-2.9.2.tar.gz.[12345] | tar xzf -"]
RUN ["sh", "-c", "cat package/apache-hive-2.3.7-bin.tar.gz.[123] | tar xzf -"]
RUN ["mv", "hadoop-2.9.2", "hadoop"]
RUN ["mv", "apache-hive-2.3.7-bin", "hive"]
RUN ["cp", "package/postgresql-42.5.0.jar", "hive/lib"]

ENV JAVA_HOME       /usr/lib/jvm/java-8-openjdk-${TARGETARCH}
ENV POSTGRESQL_HOME /usr/lib/postgresql/14
ENV PGDATA          /home/hadoop/pgdata
ENV PGHOST          localhost
ENV PGPORT          5432
ENV PGDATABASE      hive
ENV HADOOP_HOME     /home/hadoop/hadoop
ENV HIVE_HOME       /home/hadoop/hive

ENV PATH ${HIVE_HOME}/bin:${HADOOP_HOME}/bin:${HADOOP_HOME}/sbin:${POSTGRESQL_HOME}/bin:${JAVA_HOME}/bin:${PATH}

ENTRYPOINT ["/home/hadoop/entrypoint.sh"]

EXPOSE 8020
EXPOSE 10000
EXPOSE 50010
