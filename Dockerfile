FROM python:3.12-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends gettext wget && \
    wget -qO /usr/local/bin/yq \
      https://github.com/mikefarah/yq/releases/download/v4.44.1/yq_linux_amd64 && \
    chmod +x /usr/local/bin/yq && \
    rm -rf /var/lib/apt/lists/*

RUN pip install rendercv[full]

WORKDIR /cv
