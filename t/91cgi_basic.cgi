#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 16;
use vars qw/ $one $error $text_error $required_error /;
use Data::Dumper;

use lib '../lib';

BEGIN { use_ok( 'CGI::ValidOp' )}
BEGIN { use_ok( 'CGI::ValidOp::Check::text' )}

$ENV{REQUEST_METHOD} = 'GET';
$ENV{QUERY_STRING} = 'number=3172&name=Lava lamp&price=27.99&crackme=;rm / -rf'; 

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    ok( $one = CGI::ValidOp->new );
    ok( $one->isa( 'CGI::ValidOp' ));

    is( $one->param( 'number' ), 3172 );
    is( $one->param( 'name' ), 'Lava lamp' );
    is( $one->param( 'price' ), 27.99 );
    is( $one->param( 'crackme' ), undef );

#         ( $error = $text_error ) =~ s/\$label/crackme/;
    ok( $one->errors );
    is( @{ $one->errors }[ 0 ], $error );

    is_deeply( $one->Vars, {
        number  => 3172,
        name    => 'Lava lamp',
        price   => 27.99,
        crackme => undef,
    });

    ok( $one->errors );
    is( @{ $one->errors }[ 0 ], $error );
