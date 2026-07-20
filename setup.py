#!/usr/bin/env python3

import os
import re
import sys
from pathlib import Path

# Ensure the project directory is on sys.path so piper_phonemize_build is
# importable even when pip runs setup.py inside an isolated build environment.
# Note: __file__ may not be set when setuptools.build_meta exec's setup.py,
# so we use os.getcwd() which is always the project root.
sys.path.insert(0, os.getcwd())

import setuptools

from piper_phonemize_build.cmake_extension import (
    BuildExtension,
    bdist_wheel,
    cmake_extension,
    is_windows,
    set_version,
)


def read_long_description():
    with open("README.md", encoding="utf8") as f:
        readme = f.read()
    return readme


def get_package_version():
    with open("CMakeLists.txt") as f:
        content = f.read()

    match = re.search(r"set\(PIPER_PHONEMIZE_VERSION (.*)\)", content)
    latest_version = match.group(1).strip('"')

    return latest_version


set_version(get_package_version())

package_name = "piper_phonemize"

with open("piper_phonemize/__init__.py", "a") as f:
    f.write(f"__version__ = '{get_package_version()}'\n")


setuptools.setup(
    name=package_name,
    python_requires=">=3.7",
    version=get_package_version(),
    author="Michael Hansen",
    author_email="mike@rhasspy.org",
    url="https://github.com/rhasspy/piper-phonemize",
    packages=["piper_phonemize"],
    package_data={"piper_phonemize": ["espeak-ng-data/**", "./LICENSE.md"]},
    long_description=read_long_description(),
    long_description_content_type="text/markdown",
    ext_modules=[cmake_extension("piper_phonemize_cpp")],
    cmdclass={"build_ext": BuildExtension, "bdist_wheel": bdist_wheel},
    zip_safe=False,
    classifiers=[
        "Programming Language :: C++",
        "Programming Language :: Python",
        "Topic :: Scientific/Engineering :: Artificial Intelligence",
    ],
)

with open("piper_phonemize/__init__.py", "r") as f:
    lines = f.readlines()

with open("piper_phonemize/__init__.py", "w") as f:
    for line in lines:
        if "__version__" in line:
            # skip __version__ = "x.x.x"
            continue
        f.write(line)
