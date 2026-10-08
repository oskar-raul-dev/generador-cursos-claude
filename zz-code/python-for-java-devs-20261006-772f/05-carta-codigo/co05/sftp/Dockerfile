FROM debian:trixie-slim
RUN apt-get update && apt-get install -y --no-install-recommends openssh-server \
    && rm -rf /var/lib/apt/lists/* && mkdir -p /run/sshd /salida/aurea \
    && useradd -m -s /bin/bash aurea && chown aurea /salida/aurea
COPY aurea_ed25519.pub /home/aurea/.ssh/authorized_keys
RUN chown -R aurea /home/aurea/.ssh && chmod 600 /home/aurea/.ssh/authorized_keys
CMD ["/usr/sbin/sshd", "-D", "-e"]
