#!/usr/bin/perl -T
use warnings;
use strict;

use lib qw/ t lib /;

use CGI::ValidOp::Test;

use Test::More tests => 96;
use vars qw/ $errmsg /;
use Data::Dumper;
use Test::Taint;

BEGIN { use_ok( 'CGI::ValidOp::Param' )}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# default
        $errmsg = qr/Only letters, numbers, and the following punctuation are allowed for William Blake/;
    check_check( 'sql', 0, 0 );
    check_check( 'sql', "\0", undef, 0, $errmsg );
    check_check( 'sql', "\n", undef, 0, $errmsg );
    check_check( 'sql', ' foo  bar ', 'foo  bar' );
    check_check( 'sql', 'foo bar', 'foo bar' );
    check_check( 'sql', 'foo', 'foo' );
    check_check( 'sql', '%&()', '%&()' );
    check_check( 'sql', 'foo
bar', "foo\nbar" );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# safer
    check_check( 'sql::safer', 0, 0 );
    check_check( 'sql::safer', ';', undef, 0, qr/Semicolons not allowed for William Blake/ );
    check_check( 'sql::safer', '-', undef, 0, qr/Dashes not allowed for William Blake/ );
    check_check( 'sql::safer', 'DROP', undef, 0, qr/DROP statement not allowed for William Blake/ );
    check_check( 'sql::safer', 'DELETE', undef, 0, qr/DELETE statement not allowed for William Blake/ );
    check_check( 'sql::safer', 'UPDATE', undef, 0, qr/UPDATE statement not allowed for William Blake/ );
    check_check( 'sql::safer', 'INTO', undef, 0, qr/INTO statement not allowed for William Blake/ );
    check_check( 'sql::safer', 'SELECT', undef, 0, qr/SELECT statement not allowed for William Blake/ );

    check_check( 'sql::safer', 'SELECT * FROM foo WHERE 1 = 1', undef, 0, qr/SELECT statement not allowed for William Blake/ );
    check_check( 'sql::safer', 'SELECT * FROM foo WHERE 1 = 1', undef, 0, qr/SELECT statement not allowed for William Blake/ );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# safer_select
    check_check( 'sql::safer_select', 'SELECT * FROM foo WHERE 1 = 1', 'SELECT * FROM foo WHERE 1 = 1' );

