import platform
from pathlib import Path

# Available at setup time due to pyproject.toml
from pybind11.setup_helpers import Pybind11Extension, build_ext
from setuptools import setup

extra_link_args = []

if platform.system() == 'Darwin':
    extra_link_args.append('-Wl,-rpath,' + 'piper_phonemize')

_DIR = Path(__file__).parent
_ESPEAK_DIR = _DIR / "espeak-ng"
print('_ESPEAK_DIR: ', _ESPEAK_DIR)

import os
os.system("pwd")
os.system("ls -lh")
os.system("ls -lh piper_phonemize; echo '---here---'")

__version__ = "1.3.0"

ext_modules = [
    Pybind11Extension(
        "piper_phonemize_cpp",
        [
            "src/python.cpp",
            "src/phonemize.cpp",
            "src/phoneme_ids.cpp",
        ],
        define_macros=[("VERSION_INFO", __version__)],
        include_dirs=[str(_ESPEAK_DIR / "src/include")],
        library_dirs=[
            str(_ESPEAK_DIR / "my-build/src/libespeak-ng"),
            str(_ESPEAK_DIR / "my-build/src/ucd-tools"),
            str(_ESPEAK_DIR / "my-build/src/libespeak-ng/Release"),
            str(_ESPEAK_DIR / "my-build/src/ucd-tools/Release"),
                      ],
        libraries=["espeak-ng", 'ucd'],
        extra_link_args = extra_link_args,
    ),
]

setup(
    name="piper_phonemize",
    version=__version__,
    author="Michael Hansen",
    author_email="mike@rhasspy.org",
    url="https://github.com/rhasspy/piper-phonemize",
    description="Phonemization library used by Piper text to speech system",
    long_description="",
    packages=["piper_phonemize"],
    package_data={
        "piper_phonemize": [
            str(p) for p in (_DIR / "piper_phonemize" / "espeak-ng-data").rglob("*")
        ]
    },
    include_package_data=True,
    ext_modules=ext_modules,
    cmdclass={"build_ext": build_ext},
    zip_safe=False,
    python_requires=">=3.7",
)
