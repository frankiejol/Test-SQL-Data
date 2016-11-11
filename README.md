# NAME

Test::SQL::Data - Helps running SQL tests: database preparing and result matching

# SYNOPSYS

    use Test::More;
    use Test::SQL::Data;

    my $test = Test::SQL::Data->new() or exit;

    use_ok('My::Module');
    my $n_matches = 1;

    $My::Module->run_something( dbh => $test->dbh );

    $n_matches += $test->match_table('tablename','expected_tablename.sql');

    done_testing($n_matches);



# DESCRIPTION

The purpose of Test::SQL::Data is to give your module a clean database to work with. When the module loads it prepares the database. You can have it empty or pre-load some SQL code before running your tests. Then you can use the module again to check if your expected results match the contents of the tables of the database.



## Clean Database for each test

This module gives a clean database connection for each test. It can be completely empty or you can make it load some tables and rows to run your code against.

You don't need to have a SQL server in the computer you run the tests. It is backed on SQLite so you only need to install the module DBD::SQLite to use it. It is the only driver supported by now.

The database contents are not removed after the test, so you can inspect the results. It will only be erased the next time you run the test.



## Database test connection

After the creation of the database at the construction of the test, you are given a connection to the test database. Both DBI and DBIx::Connector object are available and you have to use one of them to call to the module you want to test.

## Table matching

If you want to match the results, you can either issue SQL select statements or use the Test::SQL::Data API to match large amounts of information. To do so, you have to provide expected SQL dumps of tables. Each field of every row of the tables will be matched and raise an _ok_ or _not\_ok_. The number of tests run will be returned.

At the end of the test you must call _done\_testing_ from Test::More with the number of tests run.

## REQUIREMENTS

- DBD::SQLite
- DBIx::Connector
- Test::More

# CONSTRUCTOR

## new

Creates a new database file with SQLite and returns a new test object.
If some required module is missing it raises a skip.

    my $test_sql = Test::SQL::Data->new();

    my $test_sql = Test::SQL::Data->new( config => "t/etc/test_config.cfg");

    my $test_sql = Test::SQL::Data->new( require => 'Some::Package');
    my $test_sql = Test::SQL::Data->new( require => ['Some::Package' 
                                              ,'Another::Package']);

See Test Configuration bellow to learn how to easily pre-load SQL data in the empty database it creates.

# METHODS

## connect

Connects to database. It is not necessary to do this. It is executed at new().

    my $connection = connect();

    my $connection = connect('t/file.db');

## sql

Runs SQL in the internal test database.

    $test_sql->sql('CREATE TABLE a (field_one int, ... )');

## load\_sql\_file

Loads SQL statements into the temporary database from file.

### parameters

- SQL file

## file\_db

Returns the current database file we are using to store data. So far it is
a SQLite database.

## dbh

Returns the current database handler DBI

## connector

Returns the current DBIx::Connector

## match\_table

Matches all the fields and rows of a table with an expected SQL data. The SQL file must have the tablename with the prefix expected, and insert statements as rows to match against:

### parameters

- table
- expected\_sql\_file

### returns

number of ok matches

### expected\_sql\_file example

    /* etc/expected_something.sql; */
    CREATE TABLE(expected_something) ( id integer, name char(10) );
    INSERT INTO expected_something VALUES( 3,'foo' );

This will try to match the same rows in the table something and it will return a 2 if succeded. That comes from number\_of\_rows\*number\_of\_fields.
One way to generate those files is using the .dump command in sqlite and then edit the output:

    sqlite t/db/something.db .dump > t/etc/expected_something.sql

# TESTS CONFIGURATION

## One SQL file per test

On starting, it loads into the just created database the sql file related to the test.
It searches for a file in the t/etc directory called like the test but ended with
the extension sql. 

ie: t/35\_foo.t -> t/etc/35\_foo.sql

Multiple SQL statements can be declared in the sql file. So you can put a CREATE
TABLE, then do some inserts or whatever.

## Multiple SQL files

Instead of a single sql file, sometimes you want to execute other sql files from
other tests. You can create a file in t/etc/name\_of\_the\_test.cfg. Add there a
list of SQL files to run:

t/etc/40\_bar.cfg

sql:
  - 35\_foo.sql
  - 55\_whoosa.sql

At the creation of the object it will search for a file called t/etc/name\_of\_the\_test.cfg and it will be used as a config. You can also pass it to the constructor:

    my $test_sql = Test::SQL::Data->new( config => "t/etc/another_config_file.cfg");

# Dumping data from other DataBases

## MySQL

Contents of MySQL tables can be dumped and used for the tests. After the dump, you may have to manually edit the contents of the SQL file to be loaded in the SQLite backend.

    $ mysqldump --compatible=ansi --skip-extended-insert --compact database table

There are tools to convert from MySQL to SQLite, like https://github.com/dumblob/mysql2sqlite.
This is how to convert in 2 steps:

    $ mysqldump --compatible=ansi --skip-extended-insert --compact database table >table.my.sql
    $ mysql2sqlite table.mysql.sql | egrep -v "(^PRAGMA|TRANSACTION)" > table.lite.sql

    

### Manual Changes

- Auto Increment field: id\_foo integer primary key autoincrement
- There is no unsigned int, use integer
- There is no enum, use varchar
- Timestamps:  "date\_updated" datetime default current\_timestamp
- Escape ' with '' instead \\'



# Debugging

You can inspect the execution doing:

    DEBUG=1 make test

The result SQLite database for each test is in t/db\_name\_of\_test.db

# SEE ALSO

- [Test::More](https://metacpan.org/pod/Test::More)

# AUTHOR

Francesc Guasch <frankie@etsetb.upc.edu>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Francesc Guasch.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
