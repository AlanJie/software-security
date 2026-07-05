FROM docker.io/klee/klee:2.3

ARG DEBIAN_FRONTEND=noninteractive
ARG INSTALL_GEF=1
ARG RADAMSA_URL=https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/ouspg/radamsa-0.3.tar.gz
ARG RADAMSA_SHA256=17131a19fb28e5c97c28bf0b407a82744c251aa8aedfa507967a92438cd803be
ARG GEF_URL=https://raw.githubusercontent.com/hugsy/gef/2022.01/gef.py
ARG GEF_SHA256=a6b9698cdb06eefeb0a2b6ce9d31e706e75e151b4006be8d90cdcaf7f9afa1f1

USER root

RUN sed -i '/apt\.kitware\.com/d' /etc/apt/sources.list \
  && rm -f /etc/apt/sources.list.d/*kitware* \
  && apt-get update \
  && apt-get install -y --no-install-recommends \
    binutils \
    ca-certificates \
    curl \
    file \
    gcc \
    gcc-multilib \
    gdb \
    less \
    make \
    python3 \
    python3-pygments \
    vim-tiny \
  && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL "$RADAMSA_URL" -o /tmp/radamsa-0.3.tar.gz \
  && printf '%s  %s\n' "$RADAMSA_SHA256" /tmp/radamsa-0.3.tar.gz | sha256sum -c - \
  && tar -C /tmp -xzf /tmp/radamsa-0.3.tar.gz \
  && make -C /tmp/radamsa-0.3 CC='gcc -std=gnu89' \
  && install -m 0755 /tmp/radamsa-0.3/bin/radamsa /usr/local/bin/radamsa \
  && rm -rf /tmp/radamsa-0.3 /tmp/radamsa-0.3.tar.gz

RUN if [ "$INSTALL_GEF" = "1" ]; then \
      curl -fsSL "$GEF_URL" -o /opt/gef.py; \
      printf '%s  %s\n' "$GEF_SHA256" /opt/gef.py | sha256sum -c -; \
      printf 'source /opt/gef.py\n' > /home/klee/.gdbinit; \
      chown klee:klee /home/klee/.gdbinit; \
    else \
      rm -f /opt/gef.py /home/klee/.gdbinit; \
    fi

COPY assets/projects /work/projects
COPY tools/fuzz3.py /usr/local/bin/fuzz3.py
COPY tools/build-labs /usr/local/bin/build-labs
COPY tools/run-klee-wisdom /usr/local/bin/run-klee-wisdom
COPY tools/run-klee-maze /usr/local/bin/run-klee-maze
COPY docker-entrypoint.sh /usr/local/bin/p1p3-entrypoint

RUN printf 'char *gets(char *);\n' > /usr/local/include/legacy-gets.h \
  && chmod +x \
    /usr/local/bin/fuzz3.py \
    /usr/local/bin/build-labs \
    /usr/local/bin/run-klee-wisdom \
    /usr/local/bin/run-klee-maze \
    /usr/local/bin/p1p3-entrypoint \
  && printf '#!/usr/bin/env bash\nexec klee "$@"\n' > /usr/local/bin/klee.cde \
  && printf '#!/usr/bin/env bash\nexec ktest-tool "$@"\n' > /usr/local/bin/ktest-tool.cde \
  && chmod +x /usr/local/bin/klee.cde /usr/local/bin/ktest-tool.cde \
  && chown -R klee:klee /work

ENV KLEE_INCLUDE=/home/klee/klee_src/include
ENV LAB_CFLAGS="-m32 -O0 -no-pie -fno-stack-protector -include /usr/local/include/legacy-gets.h"

USER klee
WORKDIR /work/projects
ENTRYPOINT ["p1p3-entrypoint"]
CMD ["/bin/bash"]
