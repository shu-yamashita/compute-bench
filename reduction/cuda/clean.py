#!/usr/bin/python3

import subprocess

subprocess.run("rm -r bin", shell=True)
subprocess.run("rm -r results", shell=True)
subprocess.run("rm -r plot/*.png", shell=True)
