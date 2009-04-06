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

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    # Set the no_param parameter so that CGI can pick it up.
    $ENV{ REQUEST_METHOD } = 'GET';
    $ENV{ QUERY_STRING } = "no_param=1";

# No effect, the one we want is set, the alternative is not.
check_check( 'alternative(fake_param)', 'hello', 'hello' );

#Error, nothing was set, and the alternative was not either.
check_check( 'alternative(fake_param)', undef, undef, 0, 'William Blake is required.' ); 

#No error, the alternative was set
check_check( 'alternative(no_param)', undef, undef ); 

#No value, the alternative was set
check_check( 'alternative(no_param)', '"should go away"', undef ); 
