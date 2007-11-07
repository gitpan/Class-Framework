package Class::Framework::Test;

# $Id: Test.pm 13666 2007-11-07 07:53:28Z gr $

use strict;
use warnings;
use Test::More;
use Class::Value;  # see run() below


our $VERSION = '0.01';


# Also inherit from Class::Framework::Base so we get a delegate; put it first
# so its new() is found, not the very basic new() from Project::Build::Test

use base qw(
    Class::Framework::Base
    Test::CompanionClasses::Base
);


use constant PLAN => 1;


sub obj_ok {
    my ($self, $object, $object_type_const) = @_;
    isa_ok($object, $self->delegate->
        get_class_name_for($object_type_const)
    );
}


# Override planned_test_count() with a version that uses every_list().
# Project::Build::Test->planned_test_count() couldn't use that because
# every_list() is implemented in Data::Inherited, which in turn uses
# Project::Build.

sub planned_test_count {
    my $self = shift;
    my $plan;

    # so that PLANs can use the delegate:
    $::delegate = $self->delegate;

    $plan += $_ for $self->every_list('PLAN');
    $plan;
}


sub run {
    my $self = shift;
    $self->SUPER::run(@_);

    # check that test prerequisites are ok

    is($Class::Value::SkipChecks, 0, '$Class::Value::SkipChecks is off');
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

