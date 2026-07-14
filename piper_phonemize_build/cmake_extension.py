# Copyright (c)  2026  Xiaomi Corporation

import os
import platform
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


def cmake_extension(name, *args, **kwargs) -> setuptools.Extension:
    kwargs["language"] = "c++"
    sources = []
    return setuptools.Extension(name, sources, *args, **kwargs)


class BuildExtension(build_ext):
    def build_extension(self, ext: setuptools.extension.Extension):
        os.makedirs(self.build_temp, exist_ok=True)
        os.makedirs(self.build_lib, exist_ok=True)

        install_dir = Path(self.build_lib).resolve() / "piper_phonemize"

        piper_phonemize_dir = Path(__file__).parent.parent.resolve()

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
                f"cmake {cmake_args} -B {self.build_temp} -S {piper_phonemize_dir}"
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
                cmake {cmake_args} {piper_phonemize_dir}
                make {make_args} install
            """

            ret = os.system(build_cmd)
            if ret != 0:
                raise Exception(
                    "\nBuild piper-phonemize failed. Please check the error message.\n"
                )
