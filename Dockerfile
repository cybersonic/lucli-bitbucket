FROM markdrew/lucli:snapshot AS base

WORKDIR /workspace

RUN mkdir -p /home/lucee/.lucli/modules/bitbucket
COPY --chown=lucee:lucee . /home/lucee/.lucli/modules/bitbucket/

FROM base AS lucli

ENTRYPOINT ["lucli", "bitbucket"]

FROM base AS mcp

ENTRYPOINT ["lucli", "mcp", "bitbucket"]
