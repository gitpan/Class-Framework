package Class::Framework::Log;

# $Id: Log.pm 13653 2007-10-22 09:11:20Z gr $

use warnings;
use strict;
use Carp;
use IO::File;
use Time::HiRes 'gettimeofday';



our $VERSION = '0.01';


use base 'Class::Framework::Base';


__PACKAGE__
    ->mk_singleton(qw(instance))
    ->mk_scalar_accessors(qw(filename max_level))
    ->mk_boolean_accessors(qw(pid timestamp))
    ->mk_concat_accessors(qw(output));


use constant DEFAULTS => (
    max_level => 1,
);


sub init {
    my $self = shift;
    $self->SUPER::init(@_);
    $self->clear_pid;
    $self->set_timestamp;
}


sub precdate {
    my @hires = gettimeofday;
    return sub {
      sprintf "%04d%02d%02d.%02d%02d%02d",
          $_[5]+1900,$_[4]+1,@_[3,2,1,0]
    }->(localtime($hires[0]))
     . (@_ ? sprintf(".%06d",$hires[1]) : "");
}


sub logdate { substr(precdate(1), 0, 18) }


# like get_set_std, but also generate handle from filename unless defined
sub handle {
    my $self = shift;
    $self = Class::Framework::Log->instance unless ref $self;

    # in test mode, ignore what we're given - always log to STDOUT.

    if ($self->delegate->test_mode) {
        return $self->{handle} ||= IO::File->new(">&STDOUT") or
            die "can't open STDOUT: $!\n";
    }

    if (@_) {
        $self->{handle} = shift;
    } else {
        if ($self->filename) {
            $self->{handle} ||=
                IO::File->new(sprintf(">>%s", $self->filename)) or
                die sprintf("can't append to %s: %s\n", $self->filename, $!);
        } else {
            $self->{handle} ||= IO::File->new(">&STDERR") or
                die "can't open STDERR: $!\n";
        }
        $self->{handle}->autoflush(1);
        return $self->{handle};
    }
}


# called like printf
sub __log {
    my ($self, $level, $format, @args) = @_;
    $format = "$format";

    # in case someone passes us an object that needs to be stringified so we
    # can compare it with 'ne' further down (e.g., an exception object).

    $self = Class::Framework::Log->instance unless ref $self;
    return unless defined $format and $format ne '';
    return if $level > $self->max_level;

    # make sure there's exactly one newline at the end
    1 while chomp $format;
    $format .= "\n";

    $format = sprintf "(%08d) %s", $$, $format if $self->pid;
    $format = sprintf "%s %s", $self->logdate, $format if $self->timestamp;
    my $msg = sprintf $format => @args;

    # Open and close the file for each line that is logged. That doesn't cost
    # much and makes it possible to move the file away for backup, rotation
    # or whatver.

    my $fh;
    if ($self->delegate->test_mode) {
        print $msg;
    } elsif (defined($self->filename) && length ($self->filename)) {

        open $fh, '>>', $self->filename or
            die sprintf "can't open %s for appending: %s", $self->filename, $!;
        print $fh $msg or
            die sprintf "can't print to %s: %s", $self->filename, $!;
        close $fh or
            die sprintf "can't close %s: %s", $self->filename, $!;

    } else {
        warn $msg;
    }

    $self->output($msg);
}


sub info {
    my $self = shift;
    $self->__log(1, @_);
}


sub debug {
    my $self = shift;
    $self->__log(2, @_);
}


sub deep_debug {
    my $self = shift;
    $self->__log(3, @_);
}


# log a final message, close the log and croak.
sub fatal {
    my ($self, $format, @args) = @_;
    my $message = sprintf($format, @args);
    $self->info($message);
    croak($message);
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

