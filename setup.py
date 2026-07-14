#!/usr/bin/env python3
#
# Copyright (c)  2026  Xiaomi Corporation

import re

import setuptools

from piper_phonemize_build.cmake_extension import BuildExtension, bdist_wheel, cmake_extension


def get_package_version():
    with open("CMakeLists.txt") as f:
        content = f.read()

    match = re.search(r"VERSION\s+(\S+)", content)
    return match.group(1)


package_name = "piper_phonemize"
__version__ = get_package_version()

setuptools.setup(
    name=package_name,
    version=__version__,
    author="Michael Hansen",
    author_email="mike@rhasspy.org",
    url="https://github.com/rhasspy/piper-phonemize",
    description="Phonemization library used by Piper text to speech system",
    packages=["piper_phonemize", "piper_phonemize_build"],
    ext_modules=[cmake_extension("_piper_phonemize")],
    cmdclass={"build_ext": BuildExtension, "bdist_wheel": bdist_wheel},
    zip_safe=False,
    python_requires=">=3.8.0",
    license="MIT",
)
