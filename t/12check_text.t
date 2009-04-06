#!/usr/bin/perl -T
use warnings;
use strict;

use lib qw/ t lib /;

use CGI::ValidOp::Test;

use Test::More tests => 166;
use vars qw/ $errmsg /;
use Data::Dumper;
use Test::Taint;

BEGIN { use_ok( 'CGI::ValidOp::Param' )}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# text
        $errmsg = qr/Only letters, numbers, and the following punctuation are allowed for William Blake/;
    check_check( 'text', 0, 0 );
    check_check( 'text', "\0", undef, 0, $errmsg );
    check_check( 'text', "\n", undef, 0, $errmsg );
    check_check( 'text', ' foo  bar ', 'foo  bar' );
    check_check( 'text', 'foo bar', 'foo bar' );
    check_check( 'text', 'foo', 'foo' );
    check_check( 'text', '%&()', '%&()' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# text::word
        $errmsg = qr/Only one word is allowed for William Blake/;
    check_check( 'text::word', 0, 0 );
    check_check( 'text::word', "\0", undef, 0, $errmsg );
    check_check( 'text::word', "\n", undef, 0, $errmsg );
    check_check( 'text::word', 'foo bar', undef, 0, $errmsg );
    check_check( 'text::word', 'foo', 'foo' );
    check_check( 'text::word', 'foo_bar', 'foo_bar' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# text::words
        $errmsg = qr/Only words are allowed for William Blake/;
    check_check( 'text::words', 0, 0 );
    check_check( 'text::words', "\0", undef, 0, $errmsg );
    check_check( 'text::words', "\n", undef, 0, $errmsg );
    check_check( 'text::words', 'foo', 'foo' );
    check_check( 'text::words', 'foo bar', 'foo bar' );
    check_check( 'text::words', 'foo-bar', 'foo-bar' );
    check_check( 'text::word', 'foo_bar', 'foo_bar' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# text::liberal
        $errmsg = qr/Only letters, numbers, and the following punctuation are allowed for William Blake/;
    check_check( 'text::liberal', 0, 0 );
    check_check( 'text::liberal', "\0", undef, 0, $errmsg );
    check_check( 'text::liberal', "\n", undef, 0, $errmsg );
    check_check( 'text::liberal', 'foo bar', 'foo bar' );
    check_check( 'text::liberal', '$echo', '$echo' );
    check_check( 'text::liberal', '# comment me', '# comment me' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# text::hippie
        $errmsg = qr/Only letters, numbers, and the following punctuation are allowed for William Blake/;
    check_check( 'text::hippie', 0, 0 );
    check_check( 'text::hippie', "\0", undef, 0, $errmsg );
    check_check( 'text::hippie', "\n", undef, 0, $errmsg );
    check_check( 'text::hippie', 'foo bar', 'foo bar' );
    check_check( 'text::hippie', '$echo', '$echo' );
    check_check( 'text::hippie', '#23_^[32]{23}', '#23_^[32]{23}' );
    check_check( 'text::hippie', '<pyscho>', undef, 0, $errmsg ); # hippies aren't psycho

# vim:ft=perl
