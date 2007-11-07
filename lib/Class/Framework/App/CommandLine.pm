package Class::Framework::App::CommandLine;

use strict;
use warnings;
use Class::Framework::Environment;
use Class::Framework::Environment::Configurator;

use Getopt::Long;
Getopt::Long::Configure('no_ignore_case');


our $VERSION = '0.01';


use base 'Class::Framework::App';


__PACKAGE__->mk_hash_accessors(qw(opt));


use constant CONTEXT => 'generic/shell';

# alias logfile to log so that when can use '--log', but it gets stored in
# '{logfile}', which is what Class::Framework::App expects

use constant GETOPT => (qw/
    help man logfile|log=s verbose|v+ dryrun conf=s version|V environment
/);


sub usage {
    my $self = shift;
    require Pod::Usage;
    Pod::Usage::pod2usage(@_);
}


sub app_init {
    my $self = shift;
    my %opt;

    GetOptions(\%opt, $self->every_list('GETOPT')) or usage(2);

    usage(1) if $opt{help};
    usage(-exitstatus => 0, -verbose => 2) if $opt{man};

    # Add the getopt configurator before the superclass has a chance to add
    # the file configurator; this way, getopt definitions take precedence over
    # what's in the conf file.

    Class::Framework::Environment::Configurator->instance->
        add_configurator(getopt => \%opt);
    $self->opt(%opt);

    $self->SUPER::app_init(@_);
}


sub app_finish {
    my $self = shift;
    $self->delegate->disconnect;
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

