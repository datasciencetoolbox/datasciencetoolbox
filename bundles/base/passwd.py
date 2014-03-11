#!/usr/bin/env python
import sys
from IPython.lib import passwd

# Create hash of password
passwd_hash = passwd(sys.argv[1])
c = open("passwd_hash.yml", "w")
c.write("---\nipython_password_sha1: '%s'\n" % passwd_hash)
c.close()
