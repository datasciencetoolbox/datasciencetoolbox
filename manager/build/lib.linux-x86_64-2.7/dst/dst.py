#!/usr/bin/env python

"""usage: dst [--version] [--help]
       <command> [<args>...]

options:
   -v, --version   Print the version and exit
   -h, --help      Print this help

Available commands:
   add             Add a bundle
   info            Print bundle information
   list            List all available bundles
   setup           Set up a bundle

For help on any individual command run `dst COMMAND -h`
"""

import yaml
import inspect
import logging
import os
import sys

from os import listdir
from os.path import join, isdir, realpath, dirname

from docopt import docopt
from schema import Schema


def run_ansible_playbook(filename):
    command = ["/usr/local/bin/ansible-playbook", filename, "-c",
        "local", "-i", "'127.0.0.1,'", "-vvv"]
    os.system(' '.join(command))


class DataScienceToolbox(object):

    log_format = '%(asctime)-15s  [%(levelname)s] - %(name)s: %(message)s'
    logging.basicConfig(format=log_format, level=logging.DEBUG)
    log = logging.getLogger('data-science-toolbox')

    def __init__(self):
        pass


    def add(self, bundle_id):
        """usage: dst add [options] <name>

options:
   -h, --help
   -v, --verbose    be verbose

        """
        run_ansible_playbook('../bundles/%s/install.yml' % bundle_id)


    def list(self):
        """usage: dst list [options]

options:
   -h, --help
   -v, --verbose    be verbose

        """
        #bundle_dir = join(dirname(realpath(__file__)), '..', 'bundles')
        bundle_dir = '/repos/data-science-toolbox/bundles'
        bundles = [f for f in listdir(bundle_dir) if isdir(join(bundle_dir,f))]
        print "The following Data Science Toolbox bundles are available:"
        print
        for bundle in sorted(bundles):
            try:
                with open(join(bundle_dir, bundle, 'info.yml')) as f:
                    info = yaml.load(f.read())
            except:
                continue
            print "%-10s - %s" % (bundle, info['title'])
        print
        print "For more information about a bundle, run `dst info BUNDLE`"


    def update(self):
        """usage: dst update [options]

options:
   -h, --help
   -v, --verbose    be verbose

        """
        os.system('cd /repos/data-science-toolbox && sudo git pull')


    def info(self, bundle_id):
        """usage: dst info [options] <name>

options:
   -h, --help
   -v, --verbose    be verbose

        """

        bundle_dir = join(dirname(realpath(__file__)), '..', 'bundles')
        try:
            with open(join(bundle_dir, bundle_id, 'info.yml')) as f:
                info = yaml.load(f.read())
        except:
            print "Cannot get information of bundle %s" % bundle_id

        for k, v in sorted(info.iteritems()):
            print "%-10s: %s" % (k.capitalize(), v)
        print


    def setup(self, bundle_id):
        """usage: dst setup [options] <name>

options:
   -h, --help
   -v, --verbose    be verbose

        """
        run_ansible_playbook('../bundles/%s/setup.yml' % bundle_id)


def main():
    args = docopt(__doc__, version='Data Science Toolbox version 0.1', options_first=True)
    help = {m[0]: inspect.getdoc(m[1]) for m in \
        inspect.getmembers(DataScienceToolbox, predicate=inspect.ismethod) \
        if not m[0].startswith('_')}

    argv = [args['<command>']] + args['<args>']
    if args['<command>'] not in help:
        exit("%r is not a dst command. See 'dst --help'." % args['<command>'])
    else:
        args = docopt(help[args['<command>']], argv=argv)
        dst = DataScienceToolbox()
        if 'add' in args:
            dst.add(args['<name>'])
        if 'setup' in args:
            dst.setup(args['<name>'])
        if 'info' in args:
            dst.info(args['<name>'])
        if 'list' in args:
            dst.list()
        if 'update' in args:
            dst.update()
    return 0


if __name__ == "__main__":
    exit(main())
