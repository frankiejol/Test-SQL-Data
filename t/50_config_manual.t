use warnings;
use strict;

use Test::More;

use_ok('Test::SQL::Data');

my $test_sql;

eval { $test_sql = Test::SQL::Data->new( config => "t/etc/missing_config.cfg") };
ok(!$test_sql);
ok($@ =~ /missing config file/i,"Expecting missing config file, got: '".($@ or '')."'");

eval { $test_sql = Test::SQL::Data->new( config => "t/etc/20_config.cfg") };
ok($test_sql && $test_sql->{_config},"Expecting _config entry, not found") or exit;

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

done_testing(6);
