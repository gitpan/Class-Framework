package Class::Framework::Environment::Configurator;

# $Id: Configurator.pm 13653 2007-10-22 09:11:20Z gr $
#
# Base class for environment configurators

use warnings;
use strict;
use Error::Hierarchy::Util qw/assert_defined load_class/;
use Class::Framework::Environment::Configurator::Local;

# Don't rely on UNIVERSAL::throw if we defined an AUTOLOAD...
use Error::Hierarchy::Internal::CustomMessage;


our $VERSION = '0.01';


use base 'Class::Framework::Accessor';


__PACKAGE__
    ->mk_singleton_constructor(qw(new instance))
    ->mk_array_accessors(qw(configurators))
    ->mk_scalar_accessors(qw(local_configurator));


sub init {
    my $self = shift;
    $self->local_configurator(
        Class::Framework::Environment::Configurator::Local->new,
    );
}


sub add_configurator {
    my $self = shift;
    my $type = shift;

    assert_defined $type, 'missing configuration type';

    if ($type eq 'file') {
        my $spec = shift;
        assert_defined $spec, 'missing file configuration spec';

        my ($class, $conf_filename);
        if (index($spec, ';') != -1) {
            ($class, $conf_filename) = split /;/ => $spec;

            assert_defined $_, sprintf(
                "can't determine file configuration class from spec [%s]", $spec)
                for $class, $conf_filename;
        } else {

            # assume a default class, and the spec _is_ the conf file name
            $class = 'Class::Framework::Environment::Configurator::File';
            $conf_filename = $spec;
        }

        load_class $class, 0;
        $self->configurators_push($class->new(filename => $conf_filename));

    } elsif ($type eq 'getopt') {
        my $options = shift;
        assert_defined $options, 'missing getopt configuration spec';

        require Class::Framework::Environment::Configurator::Getopt;
        $self->configurators_push(
            Class::Framework::Environment::Configurator::Getopt->
                new(opt => $options)
        );

    } else {
        throw Error::Hierarchy::Internal::CustomMessage(custom_message =>
            sprintf 'unknown configuration type [%s]', $type);
    }
}


# Define functions and class methods lest they be handled by AUTOLOAD.

sub DEFAULTS { () }
sub FIRST_CONSTRUCTOR_ARGS { () }
sub DESTROY {}


# Ask every configurator in turn; return the first defined answer we're given.

sub AUTOLOAD {
    my $self = shift;
    (my $method = our $AUTOLOAD) =~ s/.*://;

    if (@_) {
        throw Error::Hierarchy::Internal::CustomMessage(custom_message =>
            sprintf 'configuration key [%s] is read-only', $method);
    }

    # The local configurator is special -- it always comes first, no matter
    # which configurators have been specified.

    for my $configurator ($self->local_configurator, $self->configurators) {
        my $answer = $configurator->$method;
        return $answer if defined $answer;
    }
    undef;
}


1;


__END__

=head1 NAME

Class::Framework - large-scale OOP application support

=head1 SYNOPSIS

None yet (see below).

=head1 DESCRIPTION

None yet. This is an early release; fully functional, but undocumented. The
next release will have more documentation.

=head1 TAGS

If you talk about this module in blogs, on del.icio.us or anywhere else,
please use the C<classframework> tag.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-class-framework@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit <http://www.perl.com/CPAN/> to find a CPAN
site near you. Or see <http://www.perl.com/CPAN/authors/id/M/MA/MARCEL/>.

=head1 AUTHORS

Marcel GrE<uuml>nauer, C<< <marcel@cpan.org> >>

Florian Helmberger C<< <fh@univie.ac.at> >>

Achim Adam C<< <ac@univie.ac.at> >>

Mark Hofstetter C<< <mh@univie.ac.at> >>

Heinz Ekker C<< <ek@univie.ac.at> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 by Marcel GrE<uuml>nauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

