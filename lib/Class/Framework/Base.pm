package Class::Framework::Base;

# $Id: Base.pm 13653 2007-10-22 09:11:20Z gr $

# base class for all classes of the class framework.
# Everything should subclass this.

use strict;
use warnings;
use Data::Miscellany 'set_push';
use Error::Hierarchy::Util 'load_class';


our $VERSION = '0.01';


use base qw/
    Data::Inherited
    Data::Comparable
    Error::Hierarchy::Mixin
    Class::Framework::Delegate::Mixin
    Class::Framework::Accessor
    Class::Framework::Factory::Type
/;

# We subclass Class::Framework::Factory::Type so objects can introspect to see
# which object type they are.


__PACKAGE__->mk_constructor;


# so every_hash has something to fall back to:

sub FIRST_CONSTRUCTOR_ARGS { () }


# so everyone can call SUPER:: without worries, just pass through the args:

sub MUNGE_CONSTRUCTOR_ARGS {
    my $self = shift;
    @_
}


sub init { 1 }


# Convenience method so subclasses don't need to say
#
#   use Class::Framework::Log;
#   my $log = Class::Framework::Log;
#   $log->info(...);
#
# or
#
#   Class::Framework::Log->debug(...);
#
# but can say
#
#   $self->log->info(...);
#
# Eliminating fixed package names is also a way of decoupling; later on we
# might choose to get the log from the delegate or anywhere else, in which
# case we can make the change in one location - here.
#
# Class::Framework::Log inherits from this class, so we don't use() it but
# require() it, to avoid 'redefined' warnings.

sub log {
    my $self = shift;
    require Class::Framework::Log;
    Class::Framework::Log->instance;
}


# Try to load currently not loaded packages of the Class-Framework and other
# registered distributions and call the wanted method.
#
# Throw an exception if the package in which we have to look for the wanted
# method is already loaded (= the method doesn't exist).

sub UNIVERSAL::DESTROY {}

sub UNIVERSAL::AUTOLOAD {
    my ($pkg, $method) = ($UNIVERSAL::AUTOLOAD =~ /(.*)::(.*)/);

    local $" = '|';
    our @autoload_packages;
    unless ($pkg =~ /^(@autoload_packages)/) {
        # we don't deal with crappy external libs and
        # their problems. get lost with your symbol.
        require Carp;
        local $Carp::CarpLevel = 1;
        Carp::confess sprintf
            "Undefined subroutine &%s called", $UNIVERSAL::AUTOLOAD;
    }
    (my $key = "$pkg.pm") =~ s!::!/!g;
    local $Error::Depth = $Error::Depth + 1;
    if (exists $INC{$key}) {
        # package has been loaded already, so the method wanted
        # doesn't seem to exist.
        require Carp;
        local $Carp::CarpLevel = 1;
        Carp::confess sprintf
            "Undefined subroutine &%s called", $UNIVERSAL::AUTOLOAD;
    } else {
        load_class $pkg, 1;
        no warnings;
        if (my $coderef = UNIVERSAL::can($pkg, $method)) {
            goto &$coderef;
        } else {
            require Carp;
            local $Carp::CarpLevel = 1;
            Carp::confess sprintf
                "Undefined subroutine &%s called", $UNIVERSAL::AUTOLOAD;
        }
    }
}



sub add_autoloaded_package {
    shift if $_[0] eq __PACKAGE__;
    my $prefix = shift;
    our @autoload_packages;
    set_push @autoload_packages, $prefix;
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

