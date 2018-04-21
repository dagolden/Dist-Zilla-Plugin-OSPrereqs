use 5.008001;
use strict;
use warnings;
use utf8;

package Dist::Zilla::Plugin::OSPrereqs;
# ABSTRACT: List prereqs conditional on operating system

our $VERSION = '0.009';

use Moose;
use List::Util 1.33 'first';
use namespace::autoclean;

with 'Dist::Zilla::Role::FileMunger', 'Dist::Zilla::Role::MetaProvider';

has prereq_os => (
    is       => 'ro',
    isa      => 'Str',
    lazy     => 1,
    init_arg => 'phase',
    default  => sub {
        my ($self) = @_;
        return $self->plugin_name;
    },
);

around dump_config => sub {
    my ( $orig, $self ) = @_;
    my $config = $self->$orig;

    my $this_config = { os => $self->prereq_os, };

    $config->{ '' . __PACKAGE__ } = $this_config;

    return $config;
};

has _prereq => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { {} },
);

has _prereq_str => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub {
        {
            makemaker   => "\t\$WriteMakefileArgs{PREREQ_PM}",
            modulebuild => "\t\$module_build_args{requires}",
        };
    },
);

has _builder_regex => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub {
        {
            makemaker   => 'WriteMakefile\s*\(',
            modulebuild => 'my \$build',
        };
    },
);

sub BUILDARGS {
    my ( $class, @arg ) = @_;
    my %copy = ref $arg[0] ? %{ $arg[0] } : @arg;

    my $zilla = delete $copy{zilla};
    my $name  = delete $copy{plugin_name};

    my @dashed = grep { /^-/ } keys %copy;

    my %other;
    for my $dkey (@dashed) {
        ( my $key = $dkey ) =~ s/^-//;

        $other{$key} = delete $copy{$dkey};
    }

    confess "don't try to pass -_prereq as a build arg!" if $other{_prereq};

    return {
        zilla       => $zilla,
        plugin_name => $name,
        _prereq     => \%copy,
        %other,
    };
}

sub munge_files {
    my ($self) = @_;

    return unless my $os = $self->prereq_os;

    my @build_scripts = grep { $_->name eq 'Makefile.PL' or $_->name eq 'Build.PL' }
      @{ $self->zilla->files };
    $self->log_fatal(
        'No Makefile.PL or Build.PL found! Is [MakeMaker] and [ModuleBuild] at least version 5.022?'
    ) if not @build_scripts;

    foreach my $build_script (@build_scripts) {
        my $builder = $build_script->name eq 'Makefile.PL' ? 'makemaker' : 'modulebuild';
        my $content = $build_script->content;

        my $prereq_str;
        if ( $os =~ /^!~(.+)/ ) {
            $prereq_str = "if ( \$^O !~ /$1/i ) {\n";
        }
        elsif ( $os =~ /^!(.+)/ ) {
            $prereq_str = "if ( \$^O ne '$1' ) {\n";
        }
        elsif ( $os =~ /^~(.+)/ ) {
            $prereq_str = "if ( \$^O =~ /$1/i ) {\n";
        }
        else {
            $prereq_str = "if ( \$^O eq '$os' ) {\n";
        }
        my $prereq_hash = $self->_prereq;
        for my $k ( sort keys %$prereq_hash ) {
            my $v        = $prereq_hash->{$k};
            my $preamble = $self->_prereq_str->{$builder} . "{'$k'}";
            $preamble .= " = \$FallbackPrereqs{'$k'}"
              if $builder eq 'makemaker';
            $prereq_str .= "$preamble = '$v';\n";
        }
        $prereq_str .= "}\n\n";

        my $reg = $self->_builder_regex->{$builder};
        $content =~ s/(?=$reg)/$prereq_str/
          or $self->log_fatal("Failed to insert conditional prereq for $os");

        return $build_script->content($content);
    }

    return 1;
}

sub metadata {
    return { dynamic_config => 1 };
}

no Moose;
__PACKAGE__->meta->make_immutable( inline_constructor => 1 );
1;

__END__

=for Pod::Coverage munge_files metadata

=head1 SYNOPSIS

In your dist.ini:

  [OSPrereqs / MSWin32]
  Win32API::File = 0.11

Some prefixes are recognized, i.e. C<!> (not), C<~> (regex match), C<!~> (regex
non-match). Regex matches are done case-insensitively for convenience:

  ; require on non-Win32 system
  [OSPrereqs / !MSWin32]
  Proc::ProcessTable = 0.50

  ; require on BSD
  [OSPrereqs / ~bsd]
  BSD::Resource=0

  ; require on non-Windows system
  [OSPrereqs / !win]
  Proc::ProcessTable = 0.50

=head1 DESCRIPTION

This L<Dist::Zilla> plugin allows you to specify OS-specific prerequisites.  You
must give the plugin a name corresponding to an operating system that would
appear in C<$^O>.  Any prerequisites listed will be conditionally added to
C<PREREQ_PM> in the Makefile.PL

=head1 WARNING

This plugin works for Makefile.PL generated by the L<Dist::Zilla::Plugin::MakeMaker>
plugin or the Build.PL generated by the L<Dist::Zilla::Plugin::ModuleBuild> plugin,
and must appear in your dist.ini after whichever you use.

This plugin is a fairly gross hack, based on the technique used for
L<Dist::Zilla::Plugin::DualLife> and might break if/when Dist::Zilla
changes how it generates install scripts.

=head1 SEE ALSO

=over 4

=item * L<Dist::Zilla::Plugin::DynamicPrereqs>

=back

=cut

