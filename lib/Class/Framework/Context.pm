package Class::Framework::Context;

# $Id: Charset.pm 9275 2005-06-21 13:58:39Z gr $

use strict;
use warnings;


our $VERSION = '0.01';


use base 'Class::Framework::Base';


__PACKAGE__->mk_scalar_accessors(qw(execution job));


# types of execution context: cron, apache, shell, soap
# types of job context: mail, sif, epp

# takes something like 'run/epp' and sets execution and job context

sub parse_context {
    my ($self, $spec) = @_;
    if ($spec =~ m!^(\w+)/(\w+)$!) {
        my ($job, $execution) = ($1, $2);
        $self->execution($execution);
        $self->job($job);
    } else {
        throw Error::Hierarchy::Internal::CustomMessage(
            custom_message => "Invalid context specification [$spec]",
        );
    }

    $self;
}


sub as_string {
    my $self = shift;
    sprintf '%s/%s',
        (defined $self->job ? $self->job : 'none'),
        (defined $self->execution ? $self->execution : 'none');
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

