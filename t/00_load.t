use warnings;
use strict;

use Test::More;

use_ok('Test::SQL::Data');

if ( -e $Test::SQL::Data::DIR_DB ) {
    opendir my $dir_db , $Test::SQL::Data::DIR_DB or die "$! $Test::SQL::Data::DIR_DB";
    while ( my $filename = readdir $dir_db ) {
        my $file = "$Test::SQL::Data::DIR_DB/$filename";
        if ( $file =~ /\.db$/
            && -f $file ) {
                unlink $file or die "$! $file";
           }
        close $dir_db;
    }
    rmdir $Test::SQL::Data::DIR_DB or die "$! $Test::SQL::Data::DIR_DB";
}
ok !( -e $Test::SQL::Data::DIR_DB );

my $test_sql = Test::SQL::Data->new();

ok($test_sql->connect());
ok(!-e $test_sql->file_db());

ok($test_sql->dbh);
ok($test_sql->connector);

ok($test_sql->connector->dbh eq $test_sql->dbh);

$test_sql->sql('CREATE TABLE a ( ca int );');

ok(-e $test_sql->file_db());

# let's insert a value
$test_sql->sql("INSERT INTO a(ca) VALUES(35)");
my $sth = $test_sql->dbh->prepare("SELECT ca FROM a");
$sth->execute;
my ( $ca) = $sth->fetchrow;
$sth->finish;
ok($ca == 35);


my $test2;
eval { $test2 = Test::SQL::Data->new( bogus => 'argument' ) };
ok(! defined $test2, "test with bogus argument shouldn't be created" );
ok($@ =~ /unknown argument .*bogus/i,"Expecting exception about unknown argument, got "
            ."'".($@ or '')."'");

done_testing(11);
