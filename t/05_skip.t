use warnings;
use strict;

use Test::More;

use Test::SQL::Data;

my $test_sql;

eval {
        $test_sql = Test::SQL::Data->new( require => 'Missing::Package');
};
