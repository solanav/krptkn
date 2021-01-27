import setuptools

with open("README.md", "r", encoding="utf-8") as fh:
    long_description = fh.read()

setuptools.setup(
    name="libgnis",
    version="0.0.2",
    author="Solanav",
    author_email="solanav@qq.com",
    description="Library of utilities for Ignis Energy",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/solanav/libgnis",
    packages=setuptools.find_packages(),
    classifiers=[
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: GNU Affero General Public License v3 or later (AGPLv3+)",
        "Operating System :: OS Independent",
    ],
    python_requires='>=3.6',
    project_urls={
        'Source': 'https://github.com/solanav/libgnis',
    },
)