from setuptools import find_packages, setup

with open("requirements.txt") as f:
    requirements = [
        line.strip() for line in f.readlines() if not line.strip().startswith("-")
    ]

with open("README.md") as f:
    long_description = f.read()


setup(
    name="photonmover",
    url="https://github.com/mdecea/photonmover",
    version="0.0.2",
    author="Marc de Cea, Gavin West, Jaehwan Kim",
    description="Control scientific instruments commonly found in optics," \
        " photonics and electronics labs.",
    long_description=long_description,
    long_description_content_type="text/markdown",
    packages=find_packages(),
    include_package_data=True,
    install_requires=requirements,
    python_requires=">=3.7",
    license="MIT",
    entry_points="""
        [console_scripts]
        photonmover=photonmover.launch_photonmover:main
    """,
    classifiers=[
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
        "Topic :: Scientific/Engineering",
    ],
    package_data={'': ['*.yaml', '*.jpg', '*.txt', '*.pickle']},
)
