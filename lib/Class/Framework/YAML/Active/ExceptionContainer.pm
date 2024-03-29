package Class::Framework::YAML::Active::ExceptionContainer;

# $Id: ExceptionContainer.pm 13653 2007-10-22 09:11:20Z gr $

use warnings;
use strict;
use YAML::Active qw/assert_arrayref array_activate/;


our $VERSION = '0.01';


use base 'Class::Framework::YAML::Active';


sub yaml_activate {
    my ($self, $phase) = @_;
    assert_arrayref($self);
    my $exceptions = array_activate($self, $phase);

    # Expect a list of hashrefs; each hash element is an exception with a
    # 'ref' key giving the exception class, and the rest being treated as args
    # to give to the exception when it is being recorded. Example:
    #
    #  exception_container: !perl/Class::Framework::YAML::Active::ExceptionContainer
    #    - ref: Class::Framework::Exception::Policy::Blah
    #      property1: value1
    #      property2: value2

    my $container = $self->delegate->make_obj('exception_container');
    for my $exception (@$exceptions) {
        my $class = $exception->{ref};
        delete $exception->{ref};
        $container->record($class, %$exception);
    }
    $container;
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

