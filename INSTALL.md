Test-SQL-Data
=============

This perl module helps running SQL tests: database preparing and result matching



Installation
------------

The easier way to install is using Makefile.PL:

    $ perl Makefile.PL
    # make install

Installation with Dist::Zilla
--------------------------------

Installation from this source requires Dist::Zilla and some plugins. You dont''t
need to do this if you followed the Makefile.PL instructions before.

- Dist::Zilla::Plugin::Prereqs
- Dist::Zilla::Plugin::ReadmeAnyFromPod
- Dist::Zilla::Plugin::VersionFromModule

Installation procedure:

    $ dzil test
    # dzil install

Documentation
-------------

The documentation is in the module file. Once you install
the file, you can read it with perldoc.

    $ perldoc Test::SQL::Data

This module is also in GitHub:

    git@github.com:frankiejol/Test-SQL-Data.git
