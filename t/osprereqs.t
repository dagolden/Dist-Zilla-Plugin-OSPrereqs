use strict;
use warnings;

use lib 't/lib';

use Test::More 0.88;
use Path::Class;

use Dist::Zilla::App::Tester;
use Test::DZil;

## SIMPLE TEST WITH DZIL::APP TESTER

my $result = test_dzil('corpus/DZ1', [ qw(build) ]);

is($result->exit_code, 0, "dzil build would have exited 0")
  or diag join("\n",@{$result->log_messages});

my $makefilepl = file($result->build_dir, 'Makefile.PL')->slurp;
like($makefilepl, qr/MSWin32/, "saw MSWin32");

done_testing;

