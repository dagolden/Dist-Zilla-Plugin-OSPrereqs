use 5.008001;
use strict;
use warnings;
use utf8;

package Dist::Zilla::Plugin::OSPrereqs;
# ABSTRACT: List prereqs conditional on operating system

use Moose;
use List::AllUtils 'first';
use namespace::autoclean;

with 'Dist::Zilla::Role::InstallTool';

has prereq_os => (
  is   => 'ro',
  isa  => 'Str',
  lazy => 1,
  init_arg => 'phase',
  default  => sub {
    my ($self) = @_;
    return $self->plugin_name;
  },
);

around dump_config => sub {
  my ($orig, $self) = @_;
  my $config = $self->$orig;

  my $this_config = {
    os => $self->prereq_os,
  };

  $config->{'' . __PACKAGE__} = $this_config;

  return $config;
};

has _prereq => (
  is   => 'ro',
  isa  => 'HashRef',
  default => sub { {} },
);

sub BUILDARGS {
  my ($class, @arg) = @_;
  my %copy = ref $arg[0] ? %{$arg[0]} : @arg;

  my $zilla = delete $copy{zilla};
  my $name  = delete $copy{plugin_name};

  my @dashed = grep { /^-/ } keys %copy;

  my %other;
  for my $dkey (@dashed) {
    (my $key = $dkey) =~ s/^-//;

    $other{ $key } = delete $copy{ $dkey };
  }

  confess "don't try to pass -_prereq as a build arg!" if $other{_prereq};

  return {
    zilla => $zilla,
    plugin_name => $name,
    _prereq     => \%copy,
    %other,
  }
}


sub setup_installer {
  my ($self) = @_;
  return unless my $os = $self->prereq_os;

  my $makefile = first { $_->name eq 'Makefile.PL' } @{ $self->zilla->files };
  $self->log_fatal('No Makefile.PL. It needs to be provided by another plugin')
    unless $makefile;

  my $content = $makefile->content;

  my $prereq_str = "if ( \$^O eq '$os' ) {\n";
  my $prereq_hash = $self->_prereq;
  for my $k ( sort keys %$prereq_hash ) {
    my $v = $prereq_hash->{$k};
    $prereq_str .= "  \$WriteMakefileArgs{PREREQ_PM}{'$k'} = '$v';\n";
  }
  $prereq_str .= "}\n";

  $content =~ s/(?=WriteMakefile\s*\()/$prereq_str/
    or $self->log_fatal("Failed to insert conditional prereq for $os");

  $makefile->content($content);
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
1;

__END__

__END__

=for Pod::Coverage method_names_here

=begin wikidoc

= SYNOPSIS

  use Dist::Zilla::Plugin::OSPrereqs;

= DESCRIPTION

This module might be cool, but you'd never know it from the lack
of documentation.

= USAGE

Good luck!

= SEE ALSO

Maybe other modules do related things.

=end wikidoc

=cut

