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
# Bad addresses
    check_check( 'email', undef, undef ); #Empty address is ok.
    check_check( 'email', 'bob', undef, 0, "William Blake: 'bob' is not a valid email address." );
    check_check( 'email', 'bob.com', undef, 0, "William Blake: 'bob.com' is not a valid email address." );
    check_check( 'email', 'bob@bob', undef, 0, "William Blake: 'bob\@bob' is not a valid email address." );
    check_check( 'email', 'bob@bob@bob.com', undef, 0, "William Blake: 'bob\@bob\@bob.com' is not a valid email address." );

# Good Addresses
    check_check( 'email', 'bob@bob.com', 'bob@bob.com' );
    check_check( 'email', 'bob.bob@bob.com', 'bob.bob@bob.com' );
    check_check( 'email', 'bob-bob@bob.com', 'bob-bob@bob.com' );
    check_check( 'email', 'bob_bob@bob.com', 'bob_bob@bob.com' );
    check_check( 'email', 'bob@bob.bob.com', 'bob@bob.bob.com' );
    check_check( 'email', 'bob@bob-bob.com', 'bob@bob-bob.com' );
    check_check( 'email', 'bob@bob_bob.com', 'bob@bob_bob.com' );
    check_check( 'email', 'bob@bob+bob.com', 'bob@bob+bob.com' );
    check_check( 'email', 'bob+bob@bob.com', 'bob+bob@bob.com' );
