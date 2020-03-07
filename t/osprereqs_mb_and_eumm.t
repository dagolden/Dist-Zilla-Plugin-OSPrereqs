use strict;
use warnings;

use lib 't/lib';

use Test::More 0.88;

use Test::DZil;

my $tzil = Builder->from_config( { dist_root => 'corpus/DZ6' }, );

$tzil->build;

my $contents = $tzil->slurp_file('build/Build.PL');

my $conditional = q|if ( $^O eq 'MSWin32' ) {|;
my $prereq      = q|$module_build_args{requires}{'Win32API::File'} = '0.11'|;

like(
    $contents,
    qr/\Q$conditional\E.*?\Q$prereq\E.*?^\}/ms,
    "saw MSWin32 conditional in Build.PL"
);

my $meta = $tzil->slurp_file('build/META.yml');
like( $meta, qr/dynamic_config: +1/, "dynamic_config is true in META.yml" );

$contents = $tzil->slurp_file('build/Makefile.PL');
like(
    $contents,
    qr/\Q$conditional\E/ms,
    "saw MSWin32 conditional in Makefile.PL too"
);

done_testing;

