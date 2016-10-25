use warnings;
use strict;

use Test::More;

use_ok('Test::SQL::Data');

my $test_sql = Test::SQL::Data->new(config => 't/etc/20_config.cfg') or exit;

my $exp_dir = "t/.db/dir";

my $file = "${exp_dir}/dir.db";
ok( -e $file,"Expecting db file in '$file'") or exit;
my $dir = $test_sql->dir_db();
ok(defined $dir && $dir eq $exp_dir, "Expecting $exp_dir , got ".($dir or '<UNDEF>'));

done_testing(3);
