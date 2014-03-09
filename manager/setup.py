#from distutils.core import setup
from setuptools import setup
setup(
    name='dst',
    version='0.0.1',
    author='Jeroen Janssens',
    author_email='jeroen@jeroenjanssens.com',
    packages=['dst'],
    url='http://pypi.python.org/pypi/dst/',
    license='BSD',
    description='Start doing data science in minutes.',
    long_description=open('README.md').read(),
    install_requires=[
        "ansible >= 1.5",
    ],
    entry_points={
        'console_scripts': ['dst = dst.dst:main']
    },
)
