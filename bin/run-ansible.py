#!/usr/bin/env python

import os
import sys
import json
import ConfigParser
import tempfile
import shlex
import time

from distutils.util import strtobool
from subprocess import call, check_output
from optparse import OptionParser

# parse the options
parser = OptionParser()
parser.add_option("-m", "--module", dest="module",
                  help="the module you want to provisioning")
parser.add_option("-i", "--instance", dest="ec2_instance_public_dns",
                  help="the ec2 instance name to provisioning")
parser.add_option("-d", "--data-nfs-endpoint", dest="data_nfs_endpoint",
                  help="dta nfs endpoint")
(options, args) = parser.parse_args()

# reads the provisioning configuration file
config = ConfigParser.ConfigParser()
config.read("config/%s.ini" % options.module )

print options
deploy_vars = {}

# loads the deploy section of the configuration file
for item in config.items("deploy"):
  key, val = item
  if key == "aws_server":
    deploy_vars["aws_server"] = options.ec2_instance_public_dns
  elif key == "config_data_nfs_endpoint":
    deploy_vars["config_data_nfs_endpoint"] = options.data_nfs_endpoint
  else:
    try:
      if key not in deploy_vars:
        deploy_vars[key] = strtobool(val)
    except ValueError:
      deploy_vars[key] = val

# create the temporary file with the vars inside
tmp = tempfile.NamedTemporaryFile(delete=False)
tmp.write(json.dumps(deploy_vars))
tmp.close()

print deploy_vars
# loads the ansible section for the run
cmd = "%s -u %s -i %s %s -e @%s --tags %s" % \
    (config.get('ansible','binary'), config.get('ansible','user'), \
     config.get('ansible','inventory'), config.get('ansible','main_playbook'), \
     tmp.name, config.get('ansible','tags') )

os.chdir(config.get('ansible','playbook_directory'))

# sleeping here as even if ssh is available, the server may not be ready yet.
time.sleep( int(config.get('ansible','wait') ))

# finally, run.
run = call(shlex.split(cmd))
os.unlink(tmp.name)
