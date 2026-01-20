FROM python:3.12-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends gettext && \
    rm -rf /var/lib/apt/lists/*

RUN pip install rendercv[full]

WORKDIR /cv
