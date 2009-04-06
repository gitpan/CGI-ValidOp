#!/usr/bin/perl -T
use warnings;
use strict;

use lib qw/ t lib /;

use CGI::ValidOp::Test;

use Test::More tests => 112;
use vars qw/ $errmsg /;
use Data::Dumper;
use Test::Taint;

BEGIN { use_ok( 'CGI::ValidOp::Param' )}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# length
    check_check( 'length',      123, 123, 'taint' );
    check_check( 'length(0)',   123, 123, 'taint' );
    check_check( 'length(0,0)', 123, 123, 'taint' );

    check_check( 'length(3)',   12, undef, 0, 'length must be exactly 3' );
    check_check( 'length(3)',   123, 123, 'taint' );
    check_check( 'length(3)',   1234, undef, 0, 'length must be exactly 3' );

    check_check( 'length(3,3)', 12, undef, 0, 'length must be exactly 3' );
    check_check( 'length(3,3)', 123, 123, 'taint' );
    check_check( 'length(3,3)', 1234, undef, 0, 'length must be exactly 3' );

    check_check( 'length(0,3)', 12, 12, 'taint' );
    check_check( 'length(0,3)', 123, 123, 'taint' );
    check_check( 'length(0,3)', 1234, undef, 0, 'length must be at most 3' );

    check_check( 'length(3,0)', 12, undef, 0, 'length must be at least 3' );
    check_check( 'length(3,0)', 123, 123, 'taint' );
    check_check( 'length(3,0)', 1234, 1234, 'taint' );

    check_check( 'length(3,6)', 12, undef, 0, 'length must be between 3 and 6' );
    check_check( 'length(3,6)', 123, 123, 'taint' );
    check_check( 'length(3,6)', 1234, 1234, 'taint' );
    check_check( 'length(3,6)', 12345, 12345, 'taint' );
    check_check( 'length(3,6)', 123456, 123456, 'taint' );
    check_check( 'length(3,6)', 1234567, undef, 0, 'length must be between 3 and 6' );

    check_check( 'length(6,3)', 123, 'DIE', 0, "Length 'min' must be less than 'max.'" );

# vim:ft=perl
