# syntax=docker/dockerfile:1
#
# Data Science Toolbox: the Docker image for Data Science at the Command Line.
#
# Build:  docker build -t datasciencetoolbox/dsatcl2e .
# Run:    docker run --rm -it -v "$(pwd)":/data datasciencetoolbox/dsatcl2e
#
# Builder stages compile the tools that aren't packaged for Ubuntu, so no
# compilers end up in the final image. Every version is pinned below.

ARG UBUNTU=ubuntu:26.04

# Snapshot date for CRAN (Posit Package Manager) and PyPI (uv --exclude-newer)
ARG SNAPSHOT=2026-11-01

ARG VW_VERSION=9.11.9
ARG TAPKEE_VERSION=v1.4.0
ARG XSV_VERSION=0.13.0
ARG JSON2CSV_VERSION=v1.2.1
# fx 40.0.1 (its tags lack the v prefix that Go needs, so pin the commit)
ARG FX_COMMIT=5d57637b00f4
ARG PUP_COMMIT=5a57cf1
ARG CSVQUOTE_COMMIT=3e26cee6ec9d05bec3e70506154fa01721888d06
ARG XML2JSON_VERSION=0.0.3
ARG DSUTILS_COMMIT=94e795fc503e4dcdf623f2979f5ba988295792e5
# rush 0.2.1
ARG RUSH_COMMIT=c91f8b4274b1a4ef3c2f98a36e08193aac037dd8
ARG DEVOUT_COMMIT=fae1037ac2acbc6f134e200d19d5246f31048a1f
ARG MINIANSI_COMMIT=38351133b5d588c4c06e34a44c6d06508089e223
ARG DEVOUTANSI_COMMIT=f9c78b2e186808b3564b9853336495944b611354
ARG PYTHON_VERSION=3.13
ARG SKLL_VERSION=5.1.0
ARG CSVKIT_VERSION=1.1.0
ARG SAMPLE_VERSION=0.2.5
ARG UV_VERSION=0.13.7
ARG IR_VERSION=0.4.1
ARG IR_SHA256_AMD64=6fd9281e538c7b0d6bb6ec39172f6e54a50c4d0c25180269285638e5ecbd2ba2
ARG IR_SHA256_ARM64=92649e568cb8437fa6a007fd5a27c7a8b600ee529ce47e295064bbac163ab0e8
ARG JUPYTER_CONSOLE_VERSION=6.6.3


# ---------------------------------------------------------------------------
# C++ tools: vw, tapkee, csvquote
# ---------------------------------------------------------------------------
FROM ${UBUNTU} AS cxx
ARG VW_VERSION TAPKEE_VERSION CSVQUOTE_COMMIT
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential cmake git ca-certificates \
      libeigen3-dev libfmt-dev libcxxopts-dev libarpack2-dev \
      libboost-math-dev zlib1g-dev
WORKDIR /src

RUN git clone --depth 1 --branch ${TAPKEE_VERSION} https://github.com/lisitsyn/tapkee.git && \
    cmake -S tapkee -B tapkee/build -DCMAKE_BUILD_TYPE=Release -DBUILD_CLI=ON && \
    cmake --build tapkee/build -j"$(nproc)" && \
    install -s tapkee/bin/tapkee /usr/local/bin/tapkee

# Only the CLI is built; the Python wheel on PyPI can't read from stdin
RUN git clone --depth 1 --branch ${VW_VERSION} --recursive https://github.com/VowpalWabbit/vowpal_wabbit.git && \
    cmake -S vowpal_wabbit -B vowpal_wabbit/build -DCMAKE_BUILD_TYPE=Release \
      -DBUILD_TESTING=OFF -DVW_BUILD_VW_C_WRAPPER=OFF -DBUILD_JAVA=OFF -DBUILD_PYTHON=OFF \
      -DVW_INSTALL=OFF -DRAPIDJSON_SYS_DEP=OFF -DFMT_SYS_DEP=OFF -DSPDLOG_SYS_DEP=OFF \
      -DVW_ZLIB_SYS_DEP=ON -DVW_BOOST_MATH_SYS_DEP=ON && \
    cmake --build vowpal_wabbit/build --target vw_cli_bin -j"$(nproc)" && \
    install -s vowpal_wabbit/build/vowpalwabbit/cli/vw /usr/local/bin/vw

RUN git clone https://github.com/dbro/csvquote.git && \
    git -C csvquote checkout ${CSVQUOTE_COMMIT} && \
    make -C csvquote && \
    install -s csvquote/csvquote /usr/local/bin/csvquote


# ---------------------------------------------------------------------------
# Rust tools: xsv (archived upstream, but still builds and works)
# ---------------------------------------------------------------------------
FROM rust:1-slim-trixie AS rust
ARG XSV_VERSION
RUN cargo install --locked --root /out xsv --version ${XSV_VERSION} && strip /out/bin/xsv


# ---------------------------------------------------------------------------
# Go tools: pup, fx, json2csv (static binaries)
# ---------------------------------------------------------------------------
FROM golang:1-trixie AS go
ARG PUP_COMMIT FX_COMMIT JSON2CSV_VERSION
ENV CGO_ENABLED=0 GOBIN=/out GOFLAGS=-trimpath
RUN go install -ldflags="-s -w" github.com/ericchiang/pup@${PUP_COMMIT} && \
    go install -ldflags="-s -w" github.com/antonmedv/fx@${FX_COMMIT} && \
    go install -ldflags="-s -w" github.com/jehiah/json2csv@${JSON2CSV_VERSION}


# ---------------------------------------------------------------------------
# Node tools: xml2json (only npm is needed at build time, not at run time)
# ---------------------------------------------------------------------------
FROM ${UBUNTU} AS node
ARG XML2JSON_VERSION
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends npm ca-certificates && \
    npm install -g --prefix /opt/node xml2json-command@${XML2JSON_VERSION}


# ---------------------------------------------------------------------------
# ir (runs R scripts that declare their own packages; used by rush)
# ---------------------------------------------------------------------------
FROM ${UBUNTU} AS ir
ARG IR_VERSION IR_SHA256_AMD64 IR_SHA256_ARM64 TARGETARCH
RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates && \
    case "${TARGETARCH}" in \
      amd64) arch=x86_64; sha256=${IR_SHA256_AMD64} ;; \
      arm64) arch=aarch64; sha256=${IR_SHA256_ARM64} ;; \
      *) echo "Unsupported architecture: ${TARGETARCH}" >&2; exit 1 ;; \
    esac && \
    curl -fsSL -o ir.tar.gz \
      "https://github.com/r-lib/ir/releases/download/v${IR_VERSION}/ir-${arch}-unknown-linux-gnu.tar.gz" && \
    echo "${sha256}  ir.tar.gz" | sha256sum -c - && \
    mkdir /out && tar -xzf ir.tar.gz -C /out --strip-components 1 && \
    /out/ir --version


# ---------------------------------------------------------------------------
# uv (Python and package manager)
# ---------------------------------------------------------------------------
FROM ghcr.io/astral-sh/uv:${UV_VERSION} AS uv


# ---------------------------------------------------------------------------
# Final image
# ---------------------------------------------------------------------------
FROM ${UBUNTU}
ARG SNAPSHOT DSUTILS_COMMIT RUSH_COMMIT DEVOUT_COMMIT MINIANSI_COMMIT DEVOUTANSI_COMMIT \
    PYTHON_VERSION SKLL_VERSION CSVKIT_VERSION SAMPLE_VERSION JUPYTER_CONSOLE_VERSION \
    TAPKEE_VERSION CSVQUOTE_COMMIT PUP_COMMIT
ARG TARGETARCH
ENV DEBIAN_FRONTEND=noninteractive

# Undo the minimization of the Ubuntu base image, because the book uses `man`
# a lot: allow man pages again, restore the real `man`, and reinstall the
# packages that came with the base image so that their man pages return too.
RUN rm -f /etc/dpkg/dpkg.cfg.d/excludes && \
    rm -f /usr/bin/man && dpkg-divert --quiet --remove --rename /usr/bin/man && \
    apt-get update && \
    apt-get install -y --no-install-recommends --reinstall \
      $(dpkg-query -W -f='${binary:Package}\n') && \
    apt-get install -y --no-install-recommends \
      7zip awscli bat bc ca-certificates cowsay curl file git gron htop jq less \
      libarpack2t64 libwebpmux3 locales make man-db moreutils nano nodejs openssh-client parallel \
      procps r-base-core sudo telnet tealdeer tree unrar-free unzip xmlstarlet \
      zsh zsh-syntax-highlighting && \
    rm -rf /var/lib/apt/lists/* && \
    sed -i 's/^# *\(en_US.UTF-8\)/\1/' /etc/locale.gen && locale-gen

# Debian/Ubuntu install bat as batcat and cowsay in /usr/games
RUN ln -s /usr/bin/batcat /usr/local/bin/bat && \
    ln -s /usr/games/cowsay /usr/local/bin/cowsay && \
    ln -s /usr/games/cowthink /usr/local/bin/cowthink

# The dst user keeps uid 1000, as in the previous images, so files written to
# a mounted /data directory are owned by the host user on Linux
RUN userdel --remove ubuntu && \
    groupadd wheel && \
    useradd --create-home --uid 1000 --shell /usr/bin/zsh --groups wheel dst && \
    echo 'dst:dst' | chpasswd && \
    echo '%wheel ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/wheel && \
    chmod 0440 /etc/sudoers.d/wheel

# R packages: binaries from Posit Package Manager, pinned to a snapshot date.
# devout, miniansi, and devoutansi (used by `rush plot` for terminal output)
# exist only on GitHub and are compiled, so build tools are installed and
# removed again in the same layer. pak, renv, and secretbase are the resolver
# tooling of ir; installing them here keeps ir from compiling its own copies.
#
# rush runs with RUSH_NO_IR=1 (see below), i.e., against these installed
# packages: that works offline and starts instantly. Through ir, rush would
# download its packages at first use, and `rush plot` would need a compiler for
# devout. Unset RUSH_NO_IR to use ir anyway.
RUN echo "options(repos = c(CRAN = 'https://p3m.dev/cran/__linux__/resolute/${SNAPSHOT}'), \
      HTTPUserAgent = sprintf('R/%s R (%s)', getRversion(), \
      paste(getRversion(), R.version['platform'], R.version['arch'], R.version['os'])))" \
      >> /etc/R/Rprofile.site && \
    apt-get update && apt-get install -y --no-install-recommends build-essential && \
    Rscript -e "install.packages(c('tidyverse', 'docopt', 'janitor', 'fs', 'remotes', \
                                  'pak', 'renv', 'secretbase'), Ncpus = 4)" && \
    Rscript -e "for (r in c('coolbutuseless/devout@${DEVOUT_COMMIT}', \
                             'jeroenjanssens/miniansi@${MINIANSI_COMMIT}', \
                             'coolbutuseless/devoutansi@${DEVOUTANSI_COMMIT}', \
                             'jeroenjanssens/rush@${RUSH_COMMIT}')) \
                  remotes::install_github(r, upgrade = 'never')" && \
    Rscript -e "for (p in c('tidyverse', 'docopt', 'janitor', 'devoutansi', 'rush', 'pak', 'renv')) \
                  stopifnot(requireNamespace(p, quietly = TRUE))" && \
    apt-get purge -y --auto-remove build-essential && \
    rm -rf /var/lib/apt/lists/* /tmp/*

# Python: uv manages Python itself, the command-line tools, and a default
# virtual environment, which also has Jupyter Console (Chapter 10), so that
# `! pip install ...` inside Jupyter installs into the kernel's environment. Each tool gets an isolated environment so that
# installing packages in the default environment can't break them. Everything
# is owned by dst, so `pip install` and `uv tool upgrade` work without sudo.
#
# Pins needed to keep the book's commands working:
# - csvkit 1.1.0: from 1.1.1 on, csvstack can't read process substitution,
#   e.g. `csvstack a.csv <(...)` in chapter 9
# - sqlalchemy<2 and setuptools<81: csvkit 1.1.0 (csvsql) needs them; its
#   "pkg_resources is deprecated" warning is silenced
# - agate, since 1.6.2, warns "Error sniffing CSV dialect" whenever it falls
#   back to the default dialect (e.g. `csvlook wine-scaled.csv` in chapter 9);
#   older agate versions don't run on Python 3.10+, so silence that warning
# - pandas<3: skll 5.1 rejects pandas 3's string arrays as ids
# - Python 3.13: skll needs scikit-learn<1.6, which has no 3.14 wheels
COPY --from=uv /uv /uvx /usr/local/bin/
ENV UV_PYTHON_INSTALL_DIR=/opt/uv/python \
    UV_TOOL_DIR=/opt/uv/tools \
    UV_TOOL_BIN_DIR=/opt/uv/bin \
    UV_PYTHON_PREFERENCE=only-managed \
    UV_COMPILE_BYTECODE=1 \
    UV_NO_CACHE=1
RUN uv python install ${PYTHON_VERSION} && \
    uv tool install --python ${PYTHON_VERSION} --exclude-newer ${SNAPSHOT} \
      skll==${SKLL_VERSION} --with 'pandas<3' && \
    uv tool install --python ${PYTHON_VERSION} --exclude-newer ${SNAPSHOT} \
      csvkit==${CSVKIT_VERSION} --with 'sqlalchemy<2' --with 'setuptools<81' && \
    printf '%s\n' 'import warnings' \
      'warnings.filterwarnings("ignore", message="Error sniffing CSV dialect")' \
      'warnings.filterwarnings("ignore", message="pkg_resources is deprecated")' \
      > /opt/uv/tools/csvkit/lib/python${PYTHON_VERSION}/site-packages/sitecustomize.py && \
    uv tool install --python ${PYTHON_VERSION} --exclude-newer ${SNAPSHOT} sample-stream==${SAMPLE_VERSION} && \
    uv venv --python ${PYTHON_VERSION} /opt/venv && \
    VIRTUAL_ENV=/opt/venv uv pip install --exclude-newer ${SNAPSHOT} \
      cssselect lxml jupyter-console==${JUPYTER_CONSOLE_VERSION} ipykernel && \
    find /opt/uv /opt/venv -depth -type d -name tests -path '*/site-packages/*' -exec rm -rf {} + && \
    chown -R dst:dst /opt/uv /opt/venv

# dsutils (body, cols, csv2vw, dseq, header, pbc, servewd, trim, unpack, ...)
RUN git clone https://github.com/jeroenjanssens/dsutils.git /usr/bin/dsutils && \
    git -C /usr/bin/dsutils checkout ${DSUTILS_COMMIT} && \
    rm -rf /usr/bin/dsutils/.git

COPY --from=cxx /usr/local/bin/ /usr/local/bin/
COPY --from=rust /out/bin/xsv /usr/local/bin/
COPY --from=go /out/ /usr/local/bin/
COPY --from=node /opt/node /opt/node
COPY --from=ir /out/ir /out/rx /usr/local/bin/
COPY files/bin/ /usr/local/bin/

# Versions of the tools that can't report their own, for scripts/readme-tools.zsh
RUN mkdir -p /usr/local/share/datasciencetoolbox && \
    printf '%s\n' "TAPKEE_VERSION=${TAPKEE_VERSION#v}" "CSVQUOTE_COMMIT=${CSVQUOTE_COMMIT}" \
      "PUP_COMMIT=${PUP_COMMIT}" "DSUTILS_COMMIT=${DSUTILS_COMMIT}" \
      > /usr/local/share/datasciencetoolbox/build-info

COPY --chown=dst:dst files/zshrc /home/dst/.zshrc

USER dst
WORKDIR /home/dst
ENV HOSTNAME=datasciencetoolbox \
    SHELL=/usr/bin/zsh \
    VIRTUAL_ENV=/opt/venv \
    PATH=/opt/venv/bin:/opt/uv/bin:/usr/bin/dsutils:/home/dst/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    RUSH_NO_IR=1 \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

# Silence GNU parallel's citation notice and prefetch the tldr pages so
# that `tldr` also works offline
RUN mkdir -p ~/.parallel && touch ~/.parallel/will-cite && \
    tldr --update

ENTRYPOINT ["/usr/bin/zsh"]
