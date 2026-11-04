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
```

GitHub Actions builds the image natively for amd64 and arm64, runs the smoke tests on both, and pushes a multi-platform image to Docker Hub for every commit on `master`.


## License

The Data Science Toolbox is licensed under the MIT License.
