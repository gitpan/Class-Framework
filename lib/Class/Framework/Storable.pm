package Class::Framework::Storable;

# $Id: Storable.pm 13653 2007-10-22 09:11:20Z gr $

# base class for all framework classes that support a storage.

use strict;
use warnings;


our $VERSION = '0.01';


use base 'Class::Framework::Base';


__PACKAGE__
    ->mk_scalar_accessors(qw(storage_type))
    ->mk_hash_accessors(qw(storage_info));


# Don't store the storage object itself, store the method we need to call on
# the delegate to get the storage object. This is just a little overhead, but
# saves us from a lot of headache when serializing and deserializing objects
# with Storable's freeze() and thaw(), because storage objects can't be
# deserialized properly.
#
# Impose a certain order on how the constructor args are processed. We want
# the storage to be set first, because other properties could be defined using
# mk_framework_object_accessors(). Now if the args were set in an arbitrary
# order, the framework_object-properties could be processed before the storage
# is set, which would cause an error, because the storage wouldn't be set yet,
# so it can't be asked to make an object.
#
# We can't have storage_type as a key within the storage_info hash, because we
# want to be able to set it directly if passed as an argument to the
# constructor; we also need to be able to prefer it in
# Class::Framework::Storable::FIRST_CONSTRUCTOR_ARGS().
#
# We use the storage's signature as the id key, i.e. to find the id of the
# object within the storage. It would not be sufficient to use the storage's
# package name as the hash key because we can think of a multiplex storage
# that multiplexes onto two file system paths. In that case each of the
# multiplexed storages would have the same package name. And we can't use the
# storage's memory address (0x012345678) because different stages can be run
# within different processes and on different machines.
#
# For example, the attributes of an object of this class might look like:

# storage_type: core_storage
# storage_info:
#   id:
#     'Registry::NICAT::Storage::DBI::Oracle::NICAT,dbname=db.test,dbuser=nic': id12345
#     'Some::File::Storage,fspath=/path/to/storage/root': id45678

# This example assumes that the core storage is multiplexing on a DBI storage
# and a file system storage.


use constant FIRST_CONSTRUCTOR_ARGS => ('storage_type');

use constant SKIP_COMPARABLE_KEYS => (qw/storage_type storage_info/);

use constant HYGIENIC => ( qw/storage storage_type/ );


sub MUNGE_CONSTRUCTOR_ARGS {
    my ($self, @args) = @_;
    @args = $self->SUPER::MUNGE_CONSTRUCTOR_ARGS(@args);

    my $object_type = $self->get_my_factory_type;
    if (defined $object_type) {
        my $storage_type = $self->delegate->get_storage_type_for($object_type);

        $self->delegate->$storage_type->lazy_connect;
        # storage will be disconnected in Class::Framework::App->app_finish

        push @args => (storage_type => $storage_type);
    }
    @args;
}


sub storage {
    my $self = shift;
    my $method = $self->storage_type;
    if ($method) {
        $self->delegate->$method;
    } else {
        local $Error::Depth = $Error::Depth + 1;
        throw Error::Hierarchy::Internal::CustomMessage(
            custom_message =>
                "can't find method to get storage object from delegate"
        );
    }
};


sub id {
    my $self    = shift;
    my $storage = shift;
    if (@_) {
        my $id = shift;
        $self->storage_info->{id}{ $storage->signature } = $id;
    } else {
        $self->storage_info->{id}{ $storage->signature };
    }
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

