use warnings;
use strict;

use Test::More tests => 18;

use_ok('Test::SQL::Data');

my $test_sql = Test::SQL::Data->new();

###########################################################################
#
# check missing table
#
eval {
    $test_sql->match_table('missing','expected_something.sql');
};
ok($@ && $@ =~ /No such table: missing at/i, $@);

eval {$test_sql->dbh->do("DROP TABLE expected_something")};

###########################################################################
#
# check missing SQL file
#
eval {
    $test_sql->match_table('something','expected_something_missing.sql');
};
ok($@ && $@ =~ m{ t/etc/expected_something_missing.sql}i, $@);

eval {$test_sql->dbh->do("DROP TABLE expected_something")};

###########################################################################
#
# check count 
#
eval {
    $test_sql->{_DIE_IF_ERROR} = 1;
    my $n_matches = $test_sql->match_table('something','expected_something.sql');
};
ok( $@ && $@ =~ /Counted 1 in something, expected=2/, $@ or 'Missing ERROR');
$test_sql->{_DIE_IF_ERROR} = 0;

###########################################################################
#
# check table and expected_table
#
eval {$test_sql->dbh->do("DROP TABLE expected_something;")};
$test_sql->sql("INSERT INTO something VALUES( 44,'bar');");
my $n_matches = $test_sql->match_table('something','expected_something.sql');

ok(defined $n_matches && $n_matches ==  5
        ,"Found ".($n_matches or '<undef>')." matches, expected = 5");

###########################################################################
#
# Check different row
#
$test_sql->{_DIE_IF_ERROR} = 1;
$test_sql->sql("UPDATE something SET name='foo' where id=44");

eval {$test_sql->dbh->do("DROP TABLE expected_something;")};
eval { $test_sql->match_table('something','expected_something.sql') };
ok($@ && $@ =~ /Table something, Row 1.name found= 'foo', expected= 'bar'/, $@);

###########################################################################
#
# Check null field
#
$test_sql->{_DIE_IF_ERROR} = 1;
$test_sql->sql("UPDATE something SET name=null where id=44");

eval {$test_sql->dbh->do("DROP TABLE expected_something;")};
eval { $test_sql->match_table('something','expected_something.sql') };
ok($@ && $@ =~ /Table something, Row 1.name found= '<undef>', expected= 'bar'/, $@);

