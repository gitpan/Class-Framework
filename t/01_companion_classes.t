#!/usr/local/perl/bin/perl -w

use strict;
use warnings;

use base 'Class::Framework::App::Test::Classes';

$ENV{CF_CONF} = 'local' unless defined $ENV{CF_CONF};

main->new->run_app;
