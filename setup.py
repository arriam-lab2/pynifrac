from distutils.core import setup
import platform
import os

from Cython.Build import cythonize
import numpy as np

DARWIN = platform.system() == "Darwin"
os.environ['CFLAGS'] = ('-O3 -Wall -std=c++11' if not DARWIN else
                        '-O3 -Wall -std=c++11 -stdlib=libc++')


ext_modules = cythonize("unifrac/*.pyx",
                        include_path=["unifrac/"],
                        language="c++")
for module in ext_modules:
    module.include_dirs += [np.get_include()]

setup(
    name="pyunifrac",
    ext_modules=ext_modules,
    packages=["unifrac"],
    install_requires=["cython>=0.27"]
)
