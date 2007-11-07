package Class::Framework::Base_TEST;

# $Id: Base_TEST.pm 11275 2006-04-26 10:53:05Z gr $

use strict;
use warnings;
use Error::Hierarchy::Test 'throws2_ok';
use Test::More;


our $VERSION = '0.01';


use base 'Class::Framework::Test';


use constant PLAN => 5;


sub run {
    my $self = shift;
    $self->SUPER::run(@_);

    my $obj = $self->make_real_object;
    isa_ok($obj->delegate , 'Class::Framework::Environment');
    isa_ok($obj->log      , 'Class::Framework::Log');

    throws2_ok { $obj->delegate(1) }
        'Error::Hierarchy::Internal::CustomMessage',
        qr/delegate\(\) is read-only/,
        'exception when trying to set a delegate';

    throws2_ok { $obj->foo }
        'Error::Simple',
        qr/^Undefined subroutine &Class::Framework::Base::foo called at/,
        'call to undefined subroutine caught by UNIVERSAL::AUTOLOAD';

    # Undef the existing error. Strangely necessary, otherwise the next
    # ->make_real_object dies with the error message still in $@, although the
    # require() in ->make_real_object should have cleared it on success...

    undef $@;

    throws2_ok { Class::Framework::Does::Not::Exist->new }
        'Error::Hierarchy::Internal::CustomMessage',
        qr/Couldn't load package \[Class::Framework::Does::Not::Exist\]:/,
        'call to undefined package caught by UNIVERSAL::AUTOLOAD';
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

