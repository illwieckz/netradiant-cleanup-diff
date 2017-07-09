NetRadiant clean-up diff
========================

What's this?
------------

This is a tool to be sure Melanosuchus's clean-up branch lost nothing useful.

It's cloning the netradiant repository before and after clean-up,
then adds an option to CMakeLists to keep preprocessed files,
then compile the repository before and after clean-up, this way
you can compare processed files for differences.

Type `./do -h` to get some help on how to use it.

Warning
-------

No warranty is given, use this at your own risk.

Author
------

Thomas Debesse <dev@illwieckz.net>

Copyright
---------

This script is distributed under the highly permissive and laconic [ISC License](COPYING.md).
