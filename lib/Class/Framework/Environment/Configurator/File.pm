package Class::Framework::Environment::Configurator::File;

# $Id: File.pm 13653 2007-10-22 09:11:20Z gr $

use warnings;
use strict;
use File::Basename;


our $VERSION = '0.01';


use base 'Class::Framework::Environment::Configurator::Base';


__PACKAGE__
    ->mk_hash_accessors(qw(opt))
    ->mk_scalar_accessors(qw(filename));


sub init {
    my $self = shift;
    $self->SUPER::init(@_);

    if (my $conf_file = $self->filename) {
        # replace dollar-variables with their environment equivalent; also
        # some special definitions

        open my $fh, '<', $conf_file or die "can't open $conf_file: $!\n";
        my $yaml = do { local $/; <$fh> };
        close $fh or die "can't close $conf_file: $!\n";

        $ENV{SELF} = dirname($self->filename);
        $yaml =~ s/\$(\w+)/$ENV{$1} || "\$$1"/ge;

        require YAML;
        $self->opt(YAML::Load($yaml));
    }
}


# assume conf values are just top-level keys in the options hash
sub AUTOLOAD {
    my $self = shift;
    (my $method = our $AUTOLOAD) =~ s/.*://;
    $self->opt->{$method}
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

