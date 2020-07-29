# Data Science Toolbox <img src="https://github.com/datasciencetoolbox/www/raw/master/src/dst-logo.png" align="right" width="100px" />

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](https://opensource.org/licenses/MIT)

If you're a data scientist, installing all the software you need can be quite involved. The goal of the Data Science Toolbox is to provide a virtual environment that will enable you to start doing data science in a matter of minutes. 

The Data Science Toolbox is currently being revived for the upcoming second edition of [Data Science at the Command Line](https://www.datascienceatthecommandline.com). 
At the moment there's only a basic Docker image ([datasciencetoolbox/dsatcl2e](https://hub.docker.com/repository/docker/datasciencetoolbox/dsatcl2e)), which is based on Ubuntu 20.04 and includes tools such as:

* jq
* xmlstarlet
* GNU parallel
* xsv
* pup
* vowpal wabbit

Under the hood, this project employs Packer, Ansible, and Docker. We'll soon add support for other platforms such as Vagrant, VirtualBox, VMware, and AWS. Expect many breaking changes in the coming months as we're learning this on-the-fly. Stay tuned.


## License

The Data Science Toolbox is licensed under the MIT License.
