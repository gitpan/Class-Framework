package Class::Framework::App::Test::YAMLDriven;

use strict;
use warnings;
use File::Find;
use Class::Framework::App;
use Error::Hierarchy::Util 'assert_defined';
use String::FlexMatch;           # in case some tests need it
use Test::More;
use YAML::Active qw/Load Load_inactive/;
use Test::Builder;


our $VERSION = '0.01';


use base 'Class::Framework::App::Test';


use Error;
$Error::Debug = 1;   # to trigger a stacktrace on an exception


__PACKAGE__
    ->mk_abstract_accessors(qw(run_test plan_test))
    ->mk_hash_accessors(qw(test_def))
    ->mk_scalar_accessors(qw(
        testdir testname expect run_num runs current_test_def
    ));


use constant SHARED => '00shared.yaml';


# 'runs' is the number of stage runs per test file ensure idempotency

use constant DEFAULTS => (
    runs    => 1,
    testdir => '.',
);


sub app_code {
    my $self = shift;
    $self->SUPER::app_code(@_);

    $self->read_test_defs;
    $self->make_plan;

    for my $testname (sort $self->test_def_keys) {
        next if $testname eq SHARED;
        $self->execute_test_def($testname);
    }
}


sub read_test_defs {
    my $self = shift;

    # It's possible to pass args to the test program. If there are any
    # such args, then in order for a test file to be used its name has to
    # contain one of the args as a substring. For example, to only run
    # the policy tests whose name contains 'unnamed' or '99', you'd use:
    #
    #   perl t/10Policy.t unnamed 99

    my $name_filter = join '|' => map { "\Q$_\E" } @ARGV;
    my $testdir = $self->testdir;

    # First collect the files to process into a hash, then process that
    # hash sorted by name. This separation is necessary because some test
    # files depend on others, but find() doesn't ensure that the files are
    # returned in sorted order.

    my %file;
    find(sub {
        return unless -f && /\.yaml$/;

        (my $name = $File::Find::name) =~ s!^$testdir/!!;
        return if $name ne SHARED && $name_filter && $name !~ /$name_filter/o;
        $file{$name} = $File::Find::name;
    }, $testdir);

    for my $name (sort keys %file) {
        print "# Loading test file $name\n";

        (my $tests_yaml = do { local (@ARGV, $/) = $file{$name}; <> })
            =~ s/%%PID%%/sprintf("%06d", $$)/ge;
        $tests_yaml =~ s/%%CNT%%/sprintf("%03d", ++(our $cnt))/ge;

        # First, load without activation. This is to give the test def a
        # chance to say that it wants to be skipped. If we used YAML::Active's
        # Load() directly, it would activate the yaml file, which might be
        # potentially invalid if it is a work in progress.
        #
        # Then we load again using YAML::Active only if the test doesn't want
        # to be skipped.

        my $inactive_yaml = Load_inactive($tests_yaml);
        if ($self->should_skip($inactive_yaml)) {
            print "#    Test wants to be skipped, no activation\n";
            $self->test_def($name => $inactive_yaml);
        } else {
            # support for value classes
            local $Class::Value::SkipChecks = 1;
            $self->test_def($name => Load($tests_yaml));
        }
    }
}


sub should_skip {
    my ($self, $test_def) = @_;
    $test_def->{skip};
}


sub should_skip_testname {
    my ($self, $testname) = @_;
    $self->should_skip($self->test_def($testname));
}


sub make_plan {
    my $self = shift;
    my $plan = 0;

    # Each YAML file produces a number of tests, except for the shared
    # file, which is expected to only contain YAML::Active objects for
    # setup.

    for my $name (sort $self->test_def_keys) {
        next if $name eq SHARED;
        for my $run (1..$self->runs) {

            # If a test def specifies that it wants to be skipped, just plan
            # one test - a pass.

            if ($self->should_skip($self->test_def($name))) {
                $plan++;
            } else {
                $plan += $self->plan_test($self->test_def($name), $run);
            }
        }
    }

    plan tests => $plan;
}


sub execute_test_def {
    my ($self, $testname) = @_;

    assert_defined $testname, 'called without testname';

    # In case subclasses need to do special things, like multiple tickets in a
    # test definition:

    $self->current_test_def($self->test_def($testname));

    $self->expect($self->current_test_def->{expect} || {});

    for my $run (1..$self->runs) {
        $self->run_num($run);
        $self->testname(
            sprintf('%s run %d of %d', $testname, $run, $self->runs));

        # If the current test def specifies that it wants to be skipped, just
        # pass.

        if ($self->should_skip_testname($testname)) {
            $self->todo_skip_test;
        } else {
            $self->run_test;
        }
    }
}


sub named_test {
    my ($self, $suffix) = @_;
    sprintf '%s: %s', $self->testname, $suffix;
}


sub todo_skip_test {
    my $self = shift;
    Test::Builder->new->todo_skip($self->named_test('wants to be skipped'), 1);
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

