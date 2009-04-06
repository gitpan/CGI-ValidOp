#!/usr/bin/perl -T
use warnings;
use strict;

use lib qw/ t lib /;

use CGI::ValidOp::Test;

use Test::More tests => 690;
use vars qw/ $one $errmsg /;
use Data::Dumper;
use Test::Taint;

BEGIN { use_ok( 'CGI::ValidOp::Param' )}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# default
    check_check( 'demographics', undef, 'DIE' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# us_state2
        $errmsg = qr/William Blake must be the 2-letter abbreviation for a US state name./;
    check_check( 'demographics::us_state2', undef, undef );
    check_check( 'demographics::us_state2', $_, undef, undef, $errmsg )
        for qw/ohio oregon us sa za rc/;

    check_check( 'demographics::us_state2', $_, $_ )
        for qw/AL AK AS AZ AR CA CO CT DE DC FM FL GA GU HI ID IL IN IA KS KY LA ME MH MD MA MI MN MS MO MT NE NV NH NJ NM NY NC ND MP OH OK OR PW PA PR RI SC SD TN TX UT VT VI VA WA WV WI WY
               al ak as az ar ca co ct de dc fm fl ga gu hi id il in ia ks ky la me mh md ma mi mn ms mo mt ne nv nh nj nm ny nc nd mp oh ok or pw pa pr ri sc sd tn tx ut vt vi va wa wv wi wy/;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ssn
        $errmsg = qr/William Blake must be a number like "123-45-6789"./;
    check_check( 'demographics::us_ssn', 12345678, undef, undef, $errmsg );
    check_check( 'demographics::us_ssn', 1234567890, undef, undef, $errmsg );
    check_check( 'demographics::us_ssn', '123456789',   '123456789' );
    check_check( 'demographics::us_ssn', '123-45-6789', '123-45-6789' );
    check_check( 'demographics::us_ssn', '123-456789',  '123-456789' );
    check_check( 'demographics::us_ssn', '12345-6789',  '12345-6789' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ssn integer
        $errmsg = qr/William Blake must be a number like "123-45-6789"./;
    check_check( 'demographics::us_ssn(integer)', 12345678, undef, undef, $errmsg );
    check_check( 'demographics::us_ssn(integer)', 1234567890, undef, undef, $errmsg );
    check_check( 'demographics::us_ssn(integer)', '123456789',   '123456789' );
    check_check( 'demographics::us_ssn(integer)', '123-45-6789', '123456789' );
    check_check( 'demographics::us_ssn(integer)', '123-456789',  '123456789' );
    check_check( 'demographics::us_ssn(integer)', '12345-6789',  '123456789' );

# vim:ft=perl
