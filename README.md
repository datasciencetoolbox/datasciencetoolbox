# Data Science Toolbox <img src="https://github.com/datasciencetoolbox/www/raw/master/src/dst-logo.png" align="right" width="100px" />

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](https://opensource.org/licenses/MIT)

The Data Science Toolbox is the Docker image that accompanies [Data Science at the Command Line](https://jeroenjanssens.com/dsatcl/).
It contains every command-line tool discussed in the book, so you can follow along without installing anything except Docker.
The image runs on Linux, macOS, and Windows, on both Intel/AMD (amd64) and ARM (arm64, e.g., Apple Silicon) machines.


## Usage

```console
$ docker pull datasciencetoolbox/dsatcl2e
$ docker run --rm -it -v "$(pwd)":/data datasciencetoolbox/dsatcl2e
```

The directory from which you run `docker run` is available as */data* inside the container.
See [Chapter 2](https://jeroenjanssens.com/dsatcl/chapter-2-getting-started) for more details, including the commands for Windows.


## Tools

<!-- tools:start -->
These are the tools in the latest image.
The book's [list of command-line tools](https://jeroenjanssens.com/dsatcl/list-of-command-line-tools) explains what each one does.

### Python

| Tool | Version | |
|---|---|---|
| Python | 3.13.18 | `python` |
| uv | 0.13.7 | `pip` runs `uv pip` |
| Jupyter Console | 6.6.3 | with IPython kernel 7.4.0 |

### R

| Tool | Version | |
|---|---|---|
| R | 4.5.2 | |
| tidyverse | 2.0.0 | includes ggplot2 4.0.3 |
| rush | 0.2.1 | R one-liners from the shell |
| ir | 0.4.1 | runs R scripts that declare their packages |
| janitor, docopt | 2.2.1, 0.7.2 | |

### Shells

| Tool | Version | |
|---|---|---|
| Z shell | 5.9 | default shell, with syntax highlighting |
| Bash | 5.3.9 | |

### Core command-line tools

| Tool | Version | |
|---|---|---|
| coreutils | uutils 0.10.0 | `cat`, `cut`, `head`, `sort`, `wc`, and the rest; `cp`, `mv`, and `rm` are GNU coreutils 9.7 |
| grep | 3.12 | |
| sed | 4.9 | |
| awk | mawk 1.3.4 | |
| findutils | 4.10.0 | `find` |
| util-linux | 2.41.3 | `column`, `rev` |
| moreutils | 0.69 | `sponge`, `ts` |
| tar, gzip | 1.35, 1.14 | `zcat` |
| bc | 1.07.1 | |
| less, man-db | 668, 2.13.1 | |

### CSV

| Tool | Version | |
|---|---|---|
| csvkit | 1.1.0 | `csvcut`, `csvgrep`, `csvjoin`, `csvlook`, `csvsort`, `csvsql`, `csvstack`, `csvstat`, `in2csv`, `sql2csv` |
| xsv | 0.13.0 | |
| csvquote | git 3e26cee | |

### JSON, XML, and HTML

| Tool | Version | |
|---|---|---|
| jq | 1.8.1 | |
| fx | 40.0.1 | |
| gron | 0.7.1 | |
| json2csv | 1.2.1 | |
| xml2json | 0.0.3 | |
| XMLStarlet | 1.6.1 | `xmlstarlet` |
| pup | 0.4.0 | git 5a57cf1 |

### Obtaining data

| Tool | Version | |
|---|---|---|
| curl | 8.18.0 | |
| AWS CLI | 2.31.35 | `aws` |
| OpenSSH | 10.2p1 | `ssh`, `scp` |
| telnet | 0.17 | |
| unzip, 7-Zip, unrar-free | 6.00, 26.00, 0.3.3 | `unzip`, `7z`, `unrar` |

### Modeling

| Tool | Version | |
|---|---|---|
| Vowpal Wabbit | 9.11.9 | `vw` |
| SKLL | 5.1.0 | `run_experiment`, also available as `skll` |
| Tapkee | 1.4.0 | `tapkee` |

### Parallel pipelines

| Tool | Version | |
|---|---|---|
| GNU parallel | 20240222 | |
| sample | 0.2.5 | |

### Data Science Toolbox utilities

| Tool | Version | |
|---|---|---|
| [dsutils](https://github.com/jeroenjanssens/dsutils) | git 94e795f | `body`, `cols`, `csv2vw`, `dseq`, `header`, `pbc`, `scrape`, `servewd`, `trim`, `unpack`, and more |

### Other tools

| Tool | Version | |
|---|---|---|
| bat | 0.25.0 | |
| tldr | tealdeer 1.8.1 | pages included, so it works offline |
| nano | 8.7.1 | |
| make | 4.4.1 | |
| git | 2.53.0 | |
| tree | 2.3.1 | |
| htop | 3.4.1 | |
| cowsay | 3.03 | |
| sudo | 1.9.17p2 | user `dst` has passwordless sudo |
<!-- tools:end -->


## Versions

Every build is pushed as `:latest` and as a date tag, e.g., `:20261104`.
All previous images remain available.
The image that was used for the second edition of the book (2021, amd64 only) is:

```console
$ docker pull datasciencetoolbox/dsatcl2e:20210628
```

The current image is based on Ubuntu 26.04 LTS and contains up-to-date versions of the same tools.
Where a newer version would break a command from the book, the tool is pinned to an older version.
See the comments in the [Dockerfile](Dockerfile) for which tools are pinned and why.

The tools that are no longer packaged or maintained are compiled from source: Vowpal Wabbit, Tapkee, xsv, pup, fx, json2csv, and csvquote.
Python and the Python tools (csvkit, SKLL, and sample) are managed by [uv](https://docs.astral.sh/uv/); `pip install` runs `uv pip install` in the default virtual environment.


## Building

```console
$ make build   # build for the architecture of this machine
$ make test    # run the smoke tests in tests/smoke.sh
$ make run     # start a shell in the image
$ make readme  # update the Tools section of this README with the versions in the image
```

GitHub Actions builds the image natively for amd64 and arm64, runs the smoke tests on both, and pushes a multi-platform image to Docker Hub for every commit on `main`.
The Docker Hub page shows this README.


## License

The Data Science Toolbox is licensed under the MIT License.
