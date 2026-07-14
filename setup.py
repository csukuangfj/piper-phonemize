#!/usr/bin/env python3
#
# Copyright (c)  2026  Xiaomi Corporation

import os
import platform
import re
import sys
from pathlib import Path

import setuptools
from setuptools.command.build_ext import build_ext


def is_macos():
    return platform.system() == "Darwin"


def is_windows():
    return platform.system() == "Windows"


try:
    from wheel.bdist_wheel import bdist_wheel as _bdist_wheel

    class bdist_wheel(_bdist_wheel):
        def finalize_options(self):
            _bdist_wheel.finalize_options(self)
            self.root_is_pure = False

except ImportError:
    bdist_wheel = None


def cmake_extension(name, *args, **kwargs):
    kwargs["language"] = "c++"
    sources = []
    return setuptools.Extension(name, sources, *args, **kwargs)


class BuildExtension(build_ext):
    def build_extension(self, ext):
        os.makedirs(self.build_temp, exist_ok=True)
        os.makedirs(self.build_lib, exist_ok=True)

        install_dir = Path(self.build_lib).resolve() / "piper_phonemize"
        project_dir = Path(__file__).parent.resolve()

        cmake_args = os.environ.get("PIPER_PHONEMIZE_CMAKE_ARGS", "")
        make_args = os.environ.get("PIPER_PHONEMIZE_MAKE_ARGS", "")

        if cmake_args == "":
            cmake_args = "-DCMAKE_BUILD_TYPE=Release"

        extra_cmake_args = f" -DCMAKE_INSTALL_PREFIX={install_dir} "
        extra_cmake_args += " -DBUILD_PIPER_PHONEMIZE_CORE_TESTS=OFF "
        extra_cmake_args += " -DBUILD_SHARED_LIBS=ON "

        cmake_args += extra_cmake_args

        if is_windows():
            ret = os.system(
                f"cmake {cmake_args} -B {self.build_temp} -S {project_dir}"
            )
            if ret != 0:
                raise Exception("Failed to configure piper-phonemize")

            ret = os.system(
                f"cmake --build {self.build_temp} --target install --config Release -- -m"
            )
            if ret != 0:
                raise Exception("Failed to install piper-phonemize")
        else:
            build_cmd = f"""
                cd {self.build_temp}
                cmake {cmake_args} {project_dir}
                make {make_args} install
            """

            ret = os.system(build_cmd)
            if ret != 0:
                raise Exception(
                    "\nBuild piper-phonemize failed. Please check the error message.\n"
                )


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
    packages=["piper_phonemize"],
    ext_modules=[cmake_extension("_piper_phonemize")],
    cmdclass={"build_ext": BuildExtension, "bdist_wheel": bdist_wheel},
    zip_safe=False,
    python_requires=">=3.8.0",
    license="MIT",
)
