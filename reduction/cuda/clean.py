#!/usr/bin/python3

import subprocess

remove_list = [
        "bin",
        "results",
        "plot/*.png",
        ]

for elem in remove_list:
    subprocess.run(f"rm -r {elem}".split())
