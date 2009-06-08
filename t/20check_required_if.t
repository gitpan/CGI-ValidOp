#!/usr/bin/perl -T
use warnings;
use strict;

use lib qw/ t lib /;

use CGI::ValidOp::Test;
use CGI::ValidOp;

use Test::More tests => 19;
use vars qw/ $one $errmsg /;
use Data::Dumper;
use Test::Taint;

BEGIN { use_ok( 'CGI::ValidOp::Param' )}

$ENV{REQUEST_METHOD} = 'GET';
$ENV{QUERY_STRING}   = 'fake_param=1';

# both unset
check_check( 'required_if(no_param)', undef, undef, 0, undef );

# dependant set, predicate unset
check_check( 'required_if(no_param)', 'hello', undef, 0, undef );

# predicate set, dependant unset
check_check( 'required_if(fake_param)', undef, undef, 0,
    'William Blake is required.' );

# both set
check_check( 'required_if(fake_param)', 'hello', 'hello', 0, undef );
