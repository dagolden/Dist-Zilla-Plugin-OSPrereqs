use 5.008001;
use strict;
use warnings;
use utf8;

package Dist::Zilla::Plugin::OSPrereqs;
# ABSTRACT: List prereqs conditional on operating system

use Moose;
use List::AllUtils 'first';
use namespace::autoclean;

with 'Dist::Zilla::Role::InstallTool', 'Dist::Zilla::Role::MetaProvider';

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
  $prereq_str .= "}\n\n";

  $content =~ s/(?=WriteMakefile\s*\()/$prereq_str/
    or $self->log_fatal("Failed to insert conditional prereq for $os");

  $makefile->content($content);
}

sub metadata {
  return { dynamic_config => 1 };
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 1);
1;

__END__

__END__

=for Pod::Coverage setup_installer metadata

=begin wikidoc

= SYNOPSIS

In your dist.ini:

  [OSPrereqs / MSWin32]
  Win32API::File = 0.11

= DESCRIPTION

This [Dist::Zilla] plugin allows you to specify OS-specific prerequisites.  You
must give the plugin a name corresponding to an operating system that would
appear in {$^O}.  Any prerequisites listed will be conditionally added to
{PREREQ_PM} in the Makefile.PL

= WARNING

This plugin only works for Makefile.PL geneated by the
[Dist::Zilla::Plugin::MakeMaker] plugin and must appear in your dist.ini after
that plugin.

This plugin is a fairly gross hack, based on the technique used for
[Dist::Zilla::Plugin::DualLife] and might break if/when Dist::Zilla
changes how it generates a Makefile.PL.

=end wikidoc

=cut

