use warnings;
use strict;

use Test::More;

use_ok('Test::SQL::Data');

my $test_sql = Test::SQL::Data->new();

$test_sql->load_sql_file('t/etc/international.sql');

my $sth;
my $ca;

eval { 
    $sth = $test_sql->dbh->prepare("SELECT * FROM foo where cod_asig='9003'");
    $sth->execute;
    ( $ca) = $sth->fetchrow;
    $sth->finish;
};
ok(defined $ca && $ca eq '9003');

ok( -e $test_sql->file_db);

done_testing(3);
