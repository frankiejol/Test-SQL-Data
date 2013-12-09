package Test::SQL::Data;
#ABSTRACT: helps test modules that have SQL statements

use strict;
use warnings;

use version;
our $VERSION='0.0.5';

=head1 NAME

Test::SQL::Data - Helps running SQL tests: database preparing and result matching

=cut

use Carp qw(confess croak);
use Test::More;
use YAML qw(LoadFile);

our ($DIR_DB) = $0;
$DIR_DB =~ s{(.*)/.*}{$1/db};

_requires();

=pod

=head1 SYNOPSYS

  use Test::More;
  use Test::SQL::Data;

  my $test = Test::SQL::Data->new() or exit;

  use_ok('My::Module');
  my $n_matches = 1;

  $My::Module->run_something( dbh => $test->dbh );

  $n_matches = $test->match_table('tablename','expected_tablename.sql');

  done_testing($n_matches);


=head1 DESCRIPTION

The purpose of Test::SQL::Data is to give your module a clean database to work with. When the module loads it prepares the database. You can have it empty or pre-load some SQL code before running your tests. Then you can use the module again to check if your expected results match the contents of the tables of the database.


=head2 Clean Database for each test

This module gives a clean database connection for each test. It can be completely empty or you can make it load some tables and rows to run your code against.

You don't need to have a SQL server in the computer you run the tests. It is backed on SQLite so you only need to install the module DBD::SQLite to use it. It is the only driver supported by now.

The database contents are not removed after the test, so you can inspect the results. It will only be erased the next time you run the test.


=head2 Database test connection

After the creation of the database at the construction of the test, you are given a connection to the test database. Both DBI and DBIx::Connector object are available and you have to use one of them to call to the module you want to test.

=head2 Table matching

If you want to match the results, you can either issue SQL select statements or use the Test::SQL::Data API to match large amounts of information. To do so, you have to provide expected SQL dumps of tables. Each field of every row of the tables will be matched and raise an I<ok> or I<not_ok>. The number of tests run will be returned.

At the end of the test you must call I<done_testing> from Test::More with the number of tests run.

=head2 REQUIREMENTS

=over

=item *

DBD::SQLite

=item *

DBIx::Connector

=item *

Test::More

=back

=cut

=head1 CONSTRUCTOR

=head2 new

Creates a new database file with SQLite and returns a new test object.
If some required module is missing it raises a skip.

  my $test_sql = Test::SQL::Data->new();

  my $test_sql = Test::SQL::Data->new( config => "t/etc/test_config.cfg");

  my $test_sql = Test::SQL::Data->new( require => 'Some::Package');
  my $test_sql = Test::SQL::Data->new( require => ['Some::Package' 
                                            ,'Another::Package']);

See Test Configuration bellow to learn how to easily pre-load SQL data in the empty database it creates.

=cut

sub new {
    my $class =shift;
    my %args = @_;
    _requires($args{require}) or return;
    my $self = {};
    bless $self,$class;
    $self->{file_db} = _init_file_db();
    $self->{connection} = $self->connect();
    $self->_auto_load_sql();

    my ($config_file) = ($args{config} or _default_config_file());
    $self->_load_config($config_file);

    delete @args{qw(require config)};
    croak "Unknown argument :",join(",",sort keys %args) if scalar keys %args;
    return $self;
}

sub _requires {
    my $require = shift;
    SKIP: {
        eval {
            # TODO: DBIx::Connector should be optional
            require DBIx::Connector;
            require DBD::SQLite;
            if ($require) {
                if (ref($require)) {
                    for my $package (@{$require}) {
                        require $package;
                    }
                } else {
                    require $require;
                }
            }
        };
        if ($@) {
            $@ =~ s/(Can't locate .*) in .*/$1/;
            plan skip_all => $@;
            return ;
        }
    }
    return 1;
}

sub _auto_load_sql {
    my $self = shift;

    my $file_sql = $0;
    $file_sql =~ s{(.*)/(.*)\.\w+$}{$1/etc/$2\.sql};
    warn "Looking for '$file_sql'\n" if $ENV{DEBUG};
    return if ! -e $file_sql;
    
    return $self->load_sql_file($file_sql);
}

sub _default_config_file {
    my ($file_config1, $file_config2) = ($0,$0);
    $file_config1 =~ s{(.*)/(.*)\.\w+$}{$1/etc/$2\.cfg};
    $file_config2 =~ s{(.*)/(.*)\.\w+$}{$1/etc/$2\.conf};
    warn "Looking for '$file_config1' or '$file_config2'\n" if $ENV{DEBUG};
    croak "Only one config file allowed for test $0, there are $file_config1 and $file_config2"
        if -e $file_config1 && -e $file_config2;

    return $file_config1 if -e $file_config1;
    return $file_config2 if -e $file_config2;

    warn "No config file '$file_config1', nor '$file_config2' found"
        if $ENV{DEBUG};
    return;
}

sub _load_config {
    my $self = shift;
    
    my $file_config = shift or return;

    die "Missing config file $file_config" if ! -e $file_config;
    $self->{_config} = LoadFile($file_config);

    $self->_load_config_sql;
}

sub _load_config_sql {
    my $self = shift;
    my $sql = $self->{_config}->{sql};
    
    my $autocommit = $self->{connection}->dbh->{AutoCommit};
    $self->{connection}->dbh->{AutoCommit} = 0  if !$ENV{TEST_SQL_NOCOMMIT};

    for my $file ( @$sql ) {
        $self->load_sql_file("t/etc/$file");
    }

    $self->{connection}->dbh->commit;
    $self->{connection}->dbh->{AutoCommit} = $autocommit;

    return scalar(@$sql);
}

sub _init_file_db {
    my $file_db = shift;
    if (! $file_db ) {
        $file_db = $0;
        $file_db =~ s{.*/(.*)\.\w+$}{$DIR_DB/$1\.db};
        mkdir $DIR_DB or die "$! '$DIR_DB'" if ! -d $DIR_DB;
    }
    if ( -e $file_db ) {
        unlink $file_db or BAIL_OUT("$! $file_db");
    }
    return $file_db;
}

=head1 METHODS

=head2 connect

Connects to database. It is not necessary to do this. It is executed at new().

    my $connection = connect();

    my $connection = connect('t/file.db');


=cut

sub connect {
    my $self = shift;
    my $dir_db = $DIR_DB;
    if (! -e $dir_db ) {
            warn "mkdir $dir_db";
            mkdir $dir_db,0700 or die "$! $dir_db";
    }
    my $connection = DBIx::Connector->new("DBI:SQLite:".$self->file_db
                ,undef,undef
                ,{sqlite_allow_multiple_statements=> 1 
                        , AutoCommit => 1
                        , RaiseError => 1
                        , PrintError => 0
                });
    return $connection;
}

=head2 sql

Runs SQL in the internal test database.

    $test_sql->sql('CREATE TABLE a (field_one int, ... )');

=cut

sub sql {
    my $self = shift;
    

    for my $sql (@_) {
        eval { $self->{connection}->dbh->do($sql) };
        warn $sql   if $@;
        confess "FAILED SQL:\n$@" if $@;
    }
}

=head2 load_sql_file

Loads SQL statements into the temporary database from file.

=head3 parameters

=over

=item *

SQL file

=back

=cut

sub load_sql_file {
    my $self = shift;
    my $file_sql = shift;

    open my $h_sql,'<',$file_sql or die "$! $file_sql";
    my $sql = '';
    while (my $line = <$h_sql>) {
        $sql .= $line;
        if ($line =~ m{;$}) {
            warn "_load_sql_file: $sql" if $ENV{DEBUG};
            $self->sql($sql);
            $sql = '';
        }
    }
    close $h_sql;

}


=head2 file_db

Returns the current database file we are using to store data. So far it is
a SQLite database.

=cut

sub file_db {
    my $self = shift;
    return $self->{file_db};
}


=head2 dbh

Returns the current database handler DBI

=cut

sub dbh {
    my $self = shift;
    return $self->{connection}->dbh();
}


=head2 connector

Returns the current DBIx::Connector

=cut

sub connector {
    my $self = shift;
    return $self->{connection};
}

=head2 match_table

Matches all the fields and rows of a table with an expected SQL data. The SQL file must have the tablename with the prefix expected, and insert statements as rows to match against:

=head3 parameters

=over

=item *

table

=item  *

expected_sql_file

=back

=head3 returns

number of ok matches

=cut

=head3 expected_sql_file example

    /* etc/expected_something.sql; */
    CREATE TABLE(expected_something) ( id integer, name char(10) );
    INSERT INTO expected_something VALUES( 3,'foo' );

This will try to match the same rows in the table something and it will return a 2 if succeded. That comes from number_of_rows*number_of_fields.
One way to generate those files is using the .dump command in sqlite and then edit the output:

    sqlite t/db/something.db .dump > t/etc/expected_something.sql

=cut

sub _check_count {
    my $self = shift;
    my $table = shift;

    my $sth = $self->dbh->prepare("SELECT count(*) FROM $table");
    $sth->execute;
    my ($n_count) = $sth->fetchrow;

    $sth = $self->dbh->prepare("SELECT count(*) FROM expected_$table");
    $sth->execute;
    my ($n_count_expected) = $sth->fetchrow;

    my $msg_error = "Counted $n_count in $table, expecting $n_count_expected";

    die $msg_error if $n_count != $n_count_expected && $self->{_DIE_IF_ERROR};

    ok($n_count == $n_count_expected,$msg_error)
        or return 0;
    return 1;
}

sub _load_table {
    my ($self,$table)= @_;
    my @rows;

    my $sth = $self->dbh->prepare("SELECT * FROM $table");
    $sth->execute;
    while (my $row = $sth->fetchrow_hashref) {
            push @rows,($row);
    }
    $sth->finish;
    return \@rows;
}

sub match_table {
    my $self = shift;
    my ($table,$expected_sql) = @_;

    $self->load_sql_file("t/etc/$expected_sql");

    $self->_check_count($table) or return 0;
    my $n_ok = 1;
    
    my $rows_db = $self->_load_table($table);
    my $rows_exp= $self->_load_table("expected_$table");

    for my $n (0 .. scalar @$rows_exp) {

        my $row_exp = $rows_exp->[$n];
        my  $row_db = $rows_db->[$n];

        for my $field ( keys %{$row_exp} ) {
            my $msg = "Table $table, Row $n.$field "
                        ."found= '".($row_db->{$field} or '<undef>')."'"
                        .", expected= '".($row_exp->{$field} or '<undef>')."'";

            if ( !defined $row_exp->{$field} && !defined $row_db->{$field}
                ||  defined $row_exp->{$field} && defined $row_db->{$field}
                    && ($row_exp->{$field} eq $row_db->{$field})) {

                $n_ok++;
                ok(1,$msg);
            } else {
                die $msg if $self->{_DIE_IF_ERROR};
                ok(0,$msg);
            }
        }
    }
    return $n_ok;
}

1;

__END__
=pod

=head1 TESTS CONFIGURATION

=head2 One SQL file per test

On starting, it loads into the just created database the sql file related to the test.
It searches for a file in the t/etc directory called like the test but ended with
the extension sql. 

ie: t/35_foo.t -> t/etc/35_foo.sql

Multiple SQL statements can be declared in the sql file. So you can put a CREATE
TABLE, then do some inserts or whatever.

=head2 Multiple SQL files

Instead of a single sql file, sometimes you want to execute other sql files from
other tests. You can create a file in t/etc/name_of_the_test.cfg. Add there a
list of SQL files to run:

t/etc/40_bar.cfg

sql:
  - 35_foo.sql
  - 55_whoosa.sql

At the creation of the object it will search for a file called t/etc/name_of_the_test.cfg and it will be used as a config. You can also pass it to the constructor:

  my $test_sql = Test::SQL::Data->new( config => "t/etc/another_config_file.cfg");

=head1 Dumping data from other DataBases

=head2 MySQL

Contents of MySQL tables can be dumped and used for the tests. After the dump, you may have to manually edit the contents of the SQL file to be loaded in the SQLite backend.

  $ mysqldump --compatible=ansi --skip-extended-insert --compact database table

=head3 Manual Changes

=over

=item *

Auto Increment field: id_foo integer primary key autoincrement

=item *

There is no unsigned int, use integer

=item *

There is no enum, use varchar

=item *

Timestamps:  "date_updated" datetime default current_timestamp

=item *

Escape ' with '' instead \'

=back


=head1 Debugging

You can inspect the execution doing:

  DEBUG=1 make test

The result SQLite database for each test is in t/db_name_of_test.db

=head1 SEE ALSO

=over 4

=item *

L<Test::More>

=back

=head1 AUTHOR

Francesc Guasch <frankie@etsetb.upc.edu>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Francesc Guasch.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

