package Class::Framework::Environment;

# $Id: Environment.pm 13666 2007-11-07 07:53:28Z gr $

use warnings;
use strict;
use Error::Hierarchy::Util 'load_class';
use Class::Framework::Factory::Type;


our $VERSION = '0.01';


use base 'Class::Framework::Base';
Class::Framework::Base->add_autoloaded_package('Class::Framework::');

# ptags: /(\bconst\b[ \t]+(\w+))/


__PACKAGE__
    ->mk_scalar_accessors(qw(test_mode context))
    ->mk_boolean_accessors(qw(rollback_mode))
    ->mk_class_hash_accessors(qw(storage_cache multiplex_transaction_omit))
    ->mk_object_accessors('Class::Framework::Environment::Configurator' => 
        { slot => 'configurator',
          comp_mthds => [
              qw(core_storage_name core_storage_args memory_storage_name)
          ]
        },
    );



use constant DEFAULTS => (
    test_mode => (defined $ENV{TEST_MODE} && $ENV{TEST_MODE} == 1),
);


Class::Framework::Factory::Type->register_factory_type(
    exception_container => 'Class::Framework::Exception::Container',
    result              => 'Data::Storage::DBI::Result',
    storage_statement   => 'Data::Storage::Statement',
);


{ # closure over $env so that it really is private

my $env;

sub getenv { $env }

sub setenv {
    my ($self, $newenv, @args) = @_;
    return $env = $newenv if
        ref $newenv && UNIVERSAL::isa($newenv, 'Class::Framework::Environment');

    unless (ref $newenv) {
        # it's a string containing the class name
        load_class $newenv, 1;
        return $env = $newenv->new(@args);
    }

    throw Error::Hierarchy::Internal::CustomMessage(
        custom_message => "Invalid environment specification [$newenv]",
    );
}

} # end of closure


sub setup {}


# ----------------------------------------------------------------------
# class name-related code


use constant STORAGE_CLASS_NAME_HASH => (
    # storage names
    STG_NULL => 'Data::Storage::Null',
);


sub make_obj {
    my $self = shift;
    Class::Framework::Factory::Type->make_object_for_type(@_);
}


sub get_class_name_for {
    my ($self, $object_type) = @_;
    Class::Framework::Factory::Type->get_factory_class($object_type);
}


sub isa_type {
    my ($self, $object, $object_type) = @_;
    return unless UNIVERSAL::can($object, 'get_my_factory_type');
    $object->get_my_factory_type eq $object_type;
}


sub gen_class_hash_accessor (@) {
    for my $prefix (@_) {
        my $method          = sprintf 'get_%s_class_name_for' => lc $prefix;
        my $every_hash_name = sprintf '%s_CLASS_NAME_HASH', $prefix;
        my $hash;   # will be cached here

        no strict 'refs';
        $::PTAGS && printf "%s\t%s\t%s\n", $method, __FILE__, __LINE__+1;
        *$method = sub {
            local $DB::sub = local *__ANON__ =
                sprintf "%s::%s", __PACKAGE__, $method
                if defined &DB::DB && !$Devel::DProf::VERSION;
            my ($self, $key) = @_;
            $hash ||= $self->every_hash($every_hash_name);
            $hash->{$key} || $hash->{_AUTO};
        };


        # so FOO_CLASS_NAME() will return the whole every_hash

        $method = sprintf '%s_CLASS_NAME' => lc $prefix;
        $::PTAGS && printf "%s\t%s\t%s\n", $method, __FILE__, __LINE__+1;
        *$method = sub {
            local $DB::sub = local *__ANON__ =
                sprintf "%s::%s", __PACKAGE__, $method
                if defined &DB::DB && !$Devel::DProf::VERSION;
            my $self = shift;
            $hash ||= $self->every_hash($every_hash_name);
            wantarray ? %$hash : $hash;
        };

        $method = sprintf 'release_%s_class_name_hash' => lc $prefix;
        $::PTAGS && printf "%s\t%s\t%s\n", $method, __FILE__, __LINE__+1;
        *$method = sub {
            local $DB::sub = local *__ANON__ =
                sprintf "%s::%s", __PACKAGE__, $method
                if defined &DB::DB && !$Devel::DProf::VERSION;
            undef $hash;
        };
    }
}

gen_class_hash_accessor('STORAGE');


sub load_cached_class_for_type {
    my ($self, $object_type_const) = @_;

    # Cache for efficiency reasons; the environment is the core of the whole
    # framework.

    our %cache;
    my $class = $self->get_class_name_for($object_type_const);

    unless (defined($class) && length($class)) {
        throw Error::Hierarchy::Internal::CustomMessage(custom_message =>
            "Can't find class for object type [$object_type_const]",
        );
    }

    load_class $class, $self->test_mode;
    $class;
}


sub storage_for_type {
    my ($self, $object_type) = @_;
    my $storage_type = $self->get_storage_type_for($object_type);
    $self->$storage_type;
}


# When running class tests in non-final distributions, which storage should we
# use? Ideally, every distribution (but especially the non-final ones like
# Registry-Core and Registry-Enum) should have a mock storage against which to
# test. Until then, the following mechanism can be used:
#
# Every storage notes whether it is abstract or an implementation. Class tests
# that need a storage will skip() the tests if the storage is abstract.
# Problem: we need to ask all the object types' storages used in a test code
# block, as different objects types could use different storages. For example:

#    skip(...) unless
#        $self->delegate->all_storages_are_implemented(qw/person command .../);

sub all_storages_are_implemented {
    my ($self, @object_types) = @_;
    for my $object_type (@object_types) {
        return 0 if $self->storage_for_type($object_type)->is_abstract;
    }
    1;
}


# Have a special method for making delegate objects, because delegates will be
# cached (i.e., pseudo-singletons) and don't need storages and extra args and
# such.

sub make_delegate {
    my ($self, $object_type_const, @args) = @_;
    our %cache;
    $cache{delegate}{$object_type_const} ||=
        $self->make_obj($object_type_const, @args);
}


# ----------------------------------------------------------------------
# storage-related code

use constant STORAGE_TYPE_HASH => (
    _AUTO => 'core_storage',
);


sub get_storage_type_for {
    my ($self, $key) = @_;

    our %cache;
    return $cache{get_storage_type_for}{$key}
        if exists $cache{get_storage_type_for}{$key};

    my $storage_type_for = $self->every_hash('STORAGE_TYPE_HASH');
    $cache{get_storage_type_for}{$key} =
        $storage_type_for->{$key} || $storage_type_for->{_AUTO};
}


sub make_storage_object {
    my $self         = shift;
    my $storage_name = shift;
    my %args =
        @_ == 1
            ? defined $_[0]
                ? ref $_[0] eq 'HASH'
                    ? %{$_[0]}
                    : @_
                : ()
            : @_;
    if (my $class = $self->get_storage_class_name_for($storage_name)) {
        load_class $class, $self->test_mode;
        return $class->new(%args);
    }

    throw Error::Hierarchy::Internal::CustomMessage(
        custom_message => "Invalid storage name [$storage_name]",
    );
}


sub core_storage {
    my $self = shift;
    $self->storage_cache->{core_storage} ||= $self->make_storage_object(
        $self->core_storage_name, $self->core_storage_args);
}


sub memory_storage {
    my $self = shift;
    $self->storage_cache->{memory_storage} ||= $self->make_storage_object(
        $self->memory_storage_name);
}



# Forward some special methods onto all cached storages. Some storages could
# be a bit special - we don't want to rollback or disconnect from them when
# calling the multiplexing rollback() and disconnect() methods below, so we
# ignore them when multiplexing. For example, mutex storages (see
# Data-Conveyor for the concept).


sub rollback {
    my $self = shift;
    while (my ($storage_type, $storage) = each %{ $self->storage_cache }) {
        next if $self->multiplex_transaction_omit($storage_type);
        $storage->rollback;
    }
}


sub commit {
    my $self = shift;
    while (my ($storage_type, $storage) = each %{ $self->storage_cache }) {
        next if $self->multiplex_transaction_omit($storage_type);
        $storage->commit;
    }
}


sub disconnect {
    my $self = shift;
    while (my ($storage_type, $storage) = each %{ $self->storage_cache }) {
        next if $self->multiplex_transaction_omit($storage_type);
        $storage->disconnect;

        # remove it from the cache so we'll reconnect next time
        $self->storage_cache_delete($storage_type);
    }

    our %cache;
    $cache{get_storage_type_for} = {};
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

