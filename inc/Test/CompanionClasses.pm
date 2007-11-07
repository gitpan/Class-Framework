#line 1
package Test::CompanionClasses;

use warnings;
use strict;
use Test::CompanionClasses::Engine;
use Getopt::Long;


use base 'Exporter';


our $VERSION = '0.02';


our @EXPORT = ('run_tests');


sub run_tests {
    my $exact;
    GetOptions(exact => \$exact) or
        die "usage: $0 [ --exact ] filter...\n";

    Test::CompanionClasses::Engine->new->run_tests(
        exact     => $exact,
        filter    => [ @main::ARGV ],
        # inherited => [ $inherited_spec ],
    );
}



__END__

#line 108

