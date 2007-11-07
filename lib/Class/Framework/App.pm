package Class::Framework::App;

use strict;
use warnings;
use Class::Framework::Environment;
use Class::Framework::Environment::Configurator;
use Error ':try';


our $VERSION = '0.01';


use base 'Class::Framework::Storable';


__PACKAGE__->mk_boolean_accessors(qw(initialized));


use IO::Handle;
STDOUT->autoflush;
STDERR->autoflush;

use constant CONTEXT => 'generic/generic';

sub app_init {
    my $self = shift;

    # Normally, app_init() is called only once (namely, when the program
    # subclasses this class and does 'main->new->run_app'). However, if used
    # from within mod_perl (for example), the app is a cached object and
    # run_app() is called repeatedly from the outside. In this case,
    # app_init() should be called only once. We do this with initialized().

    return if $self->initialized;
    $self->initialized(1);

    my $configurator = Class::Framework::Environment::Configurator->instance;

    # If a subclass added a getopt configurator, we can ask it for the
    # location of the conf file, in case the user specified '--conf' on the
    # command line. If a filename is given, we'll use that conf file. If the
    # special string "local" is given, we try to find the conf file.
    # Otherwise use the one given in an environment variable.

    my $conf_file = $configurator->conf;
    $conf_file = '' unless defined $conf_file;
    if ($conf_file eq 'local' ||
        ($conf_file eq '' && $ENV{CF_CONF} eq 'local')) {

        # only load if needed
        require Class::Framework::Introspect;
        $conf_file = Class::Framework::Introspect::find_conf_file();
    }

    $conf_file ||= $ENV{CF_CONF};

    $configurator->add_configurator(file => $conf_file);

    $self->log->max_level(1 + ($configurator->verbose || 0));

    # Now that we have both a getopt and a file configurator, the log file
    # name can come from either the command line (preferred) or the conf file.

    $self->log->filename($configurator->logfile) if
        defined $configurator->logfile;

    # This class subclasses Class::Framework::Base, which returns
    # Class::Framework::Environment->getenv as the default delegate. So set the
    # proper environment here and then pass the newly formed delegate the
    # configurator. The environment will make use of it in its methods.

    Class::Framework::Environment->setenv($configurator->environment);
    $self->delegate->setup;
    $self->delegate->configurator($configurator);

    $self->delegate->context(
        Class::Framework::Context->new->parse_context($self->CONTEXT)
    );

    if ($configurator->dryrun) {
        $self->log->clear_timestamp;
        $self->delegate->set_rollback_mode;
    }
}


sub app_finish { 1 }
sub app_code   {}


sub run_app {
    my $self = shift;
    $self->app_init;

    $Error::Debug++;   # to get a stacktrace
    try {
        $self->app_code;
    } catch Error with {
        my $E = shift;
        $self->log->info($E->{statement}) if
            ref $E eq 'Error::Hierarchy::Internal::DBI::DBH';
        $self->log->info('Application exception: %s', $E);
        $self->log->info('%s', $E->stacktrace);
        # $self->delegate->set_rollback_mode;
    };

    $self->app_finish;
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

