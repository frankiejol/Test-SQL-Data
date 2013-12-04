use warnings;
use strict;

use Test::More tests => 4;

use_ok('Test::SQL::Data');

my $test_sql = Test::SQL::Data->new();

ok($test_sql->{_config},"Config wasn't loaded") or exit;

my $sth;
my $ca;

eval { 
    $sth = $test_sql->dbh->prepare("SELECT ca FROM a");
    $sth->execute;
    ( $ca) = $sth->fetchrow;
    $sth->finish;
};
ok(defined $ca && $ca == 35);

ok( -e $test_sql->file_db);

