FROM debian:trixie-slim
RUN apt-get update && apt-get install -y --no-install-recommends openssh-server \
    && rm -rf /var/lib/apt/lists/* && mkdir -p /run/sshd /respaldos \
    && useradd -m -s /bin/bash revisor
COPY revisor.pub /home/revisor/.ssh/authorized_keys
RUN chown -R revisor /home/revisor/.ssh && chmod 600 /home/revisor/.ssh/authorized_keys
CMD ["/usr/sbin/sshd", "-D", "-e"]
