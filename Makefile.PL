
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "helps test modules that have SQL statements",
  "AUTHOR" => "Francesc Guasch <frankie\@etsetb.upc.edu>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Test-SQL-Data",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Test::SQL::Data",
  "PREREQ_PM" => {
    "DBD::SQLite" => "1.20",
    "DBIx::Connector" => "0.4.5",
    "File::Path" => 0
  },
  "TEST_REQUIRES" => {},
  "VERSION" => "0.0.5",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "DBD::SQLite" => "1.20",
  "DBIx::Connector" => "0.4.5"
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



