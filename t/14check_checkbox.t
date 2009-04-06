#!/usr/bin/perl -T
use warnings;
use strict;

use lib qw/ t lib /;

use CGI::ValidOp::Test;

use Test::More tests => 70;
use vars qw/ $one $errmsg /;
use Data::Dumper;
use Test::Taint;

BEGIN { use_ok( 'CGI::ValidOp::Param' )}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# checkbox
        $errmsg = qr/Checkbox William Blake must be checked./;
    check_check( 'checkbox', undef, undef );
    check_check( 'checkbox', 0, undef, undef, $errmsg );
    check_check( 'checkbox', 'one', undef, undef, $errmsg );
    check_check( 'checkbox', 'on', 'on', 0 );
    check_check( 'checkbox', 'ON', 'ON', 0 );
    check_check( 'checkbox', 'On', 'On', 0 );
    check_check( 'checkbox', 'oN', 'oN', 0 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# checkbox::boolean : returns 1 or 0
        $errmsg = qr/Only a checkbox is allowed for parameter William Blake./;
    check_check( 'checkbox::boolean', undef, 0 );
    check_check( 'checkbox::boolean', 0, undef, undef, $errmsg );
    check_check( 'checkbox::boolean', 'one', undef, undef, $errmsg );
    check_check( 'checkbox::boolean', 'on', 1 );
    check_check( 'checkbox::boolean', 'ON', 1 );
    check_check( 'checkbox::boolean', 'On', 1 );
    check_check( 'checkbox::boolean', 'oN', 1 );

# vim:ft=perl
