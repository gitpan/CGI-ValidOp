#!/usr/bin/perl -T
use warnings;
use strict;

use lib qw/ t lib /;

use CGI::ValidOp::Test;

use Test::More tests => 248;
use vars qw/ $one $errmsg /;
use Data::Dumper;
use Test::Taint;

BEGIN { use_ok( 'CGI::ValidOp::Param' )}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# number
        $errmsg = qr/William Blake must be a number./;
    check_check( 'number', 0, 0 );
    check_check( 'number', 0, 0 );
    check_check( 'number', -0, -0 );
    check_check( 'number', 123, 123 );
    check_check( 'number', -123, -123 );
    check_check( 'number', +123, +123 );
    check_check( 'number', 123.45, 123.45 );
    check_check( 'number', '8.7E3', '8.7E3' );
    check_check( 'number', '-8.7e3', '-8.7e3' );
    check_check( 'number', '123.4.5', undef, 0, $errmsg );
    check_check( 'number', 'foo', undef, 0, $errmsg );
    check_check( 'number', '123-456', undef, 0, $errmsg );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# number::integer
        $errmsg = qr/William Blake must be an integer./;
    check_check( 'number::integer', 0, 0 );
    check_check( 'number::integer', 0, 0 );
    check_check( 'number::integer', -0, -0 );
    check_check( 'number::integer', 123, 123 );
    check_check( 'number::integer', -123, -123 );
    check_check( 'number::integer', +123, +123 );
    check_check( 'number::integer', 123.45, undef, 0, $errmsg );
    check_check( 'number::integer', '8.7E3', undef, 0, $errmsg );
    check_check( 'number::integer', '-8.7e3', undef, 0, $errmsg );
    check_check( 'number::integer', '123.4.5', undef, 0, $errmsg );
    check_check( 'number::integer', 'foo', undef, 0, $errmsg );
    check_check( 'number::integer', '123-456', undef, 0, $errmsg );
    check_check( 'number::integer', '.5', undef, 0, $errmsg );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# number::decimal
        $errmsg = qr/William Blake must be a decimal number./;
    check_check( 'number::decimal', 0, 0 );
    check_check( 'number::decimal', 0, 0 );
    check_check( 'number::decimal', -0, -0 );
    check_check( 'number::decimal', 123, 123 );
    check_check( 'number::decimal', -123, -123 );
    check_check( 'number::decimal', +123, +123 );
    check_check( 'number::decimal', 123.45, 123.45 );
    check_check( 'number::decimal', '8.7E3', undef, 0, $errmsg );
    check_check( 'number::decimal', '-8.7e3', undef, 0, $errmsg );
    check_check( 'number::decimal', '123.4.5', undef, 0, $errmsg );
    check_check( 'number::decimal', 'foo', undef, 0, $errmsg );
    check_check( 'number::decimal', '123-456', undef, 0, $errmsg );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# number::decimal

    sub errormsg {
        my @values = @_;
        my $out =  'William Blake: "' . join( ', ', @values );
        $out .=(@values > 1) ? '" are not positive integers.'
                             : '" is not a positive integer.';
        return $out;
    }

    is( errormsg( -5, -10, 'uhg' ), 'William Blake: "-5, -10, uhg" are not positive integers.' );
    is( errormsg( -5 ), 'William Blake: "-5" is not a positive integer.' );

    check_check( 'number::positive_list', 0, 0 );
    check_check( 'number::positive_list', '1,-1,5', undef, 0, errormsg( '-1' ));
    check_check( 'number::positive_list', '1,-0,5', undef, 0, errormsg( '-0' ));
    check_check( 'number::positive_list', '5,10,100', '5, 10, 100' );
    check_check( 'number::positive_list', '1,-5,-10,-100,5', undef, 0, errormsg( -5, -10, -100 ));
    check_check( 'number::positive_list', '-5', undef, 0, errormsg( -5 ));
    check_check( 'number::positive_list', '5, 10, 100', '5, 10, 100' );
    check_check( 'number::positive_list', '1, -5, -10, -100, 5', undef, 0, errormsg( -5, -10, -100 ));
    check_check( 'number::positive_list', '5 , 10 , 100', '5, 10, 100' );
    check_check( 'number::positive_list', '1 , -5 , -10 , -100 , 5', undef, 0, errormsg( -5, -10, -100 ));
    check_check( 'number::positive_list', 'bob', undef, 0, errormsg( 'bob' ));
    check_check( 'number::positive_list', 'bob, fred', undef, 0, errormsg( 'bob', 'fred' ));

# vim:ft=perl
