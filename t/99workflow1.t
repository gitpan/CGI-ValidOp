#!/usr/bin/perl -T
use strict;
use warnings;

use lib qw/ t lib /;

use CGI::ValidOp::Test;
use Test::More tests => 69;
use vars qw/ $one /;
use Data::Dumper;

BEGIN { use_ok( 'CGI::ValidOp' )}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# workflow 1, no params defined
        $one = init_obj;
    is( $one->cgi_object->param('item'), 'Cat food' );
    is( $one->op, 'default' );
    is( $one->param( 'item' ), 'Cat food' );
    is( $one->param( 'price' ), '10.99' );
    is( $one->param( 'shipping' ), 'FedEx' );
    is( $one->param( 'unexpect' ), 'I am the slime' );
    is( $one->param( 'comment' ), "Now is the time for\nall good men\nto come to the aid" );
    is( $one->param( 'checkme' ), 'ON' );
    is( $one->param( 'donotcheckme' ), undef );
    is( $one->param( 'client_email' ), 'whitemice@hyperintelligent_pandimensional_beings.com' );
    is( $one->param( 'no_client' ), 1 );
    is( $one->param( 'client' ), 'disappear' ); #no alternative check specified
    is( $one->param( 'client', [ 'alternative(no_client)' ]), undef );

    is_deeply( $one->param( 'multi' ), [ qw/ banana orange plum /]);
    is( $one->param( 'crackme' ), undef );
    is_deeply({ $one->Vars }, {
        name        => 'Mouse-a-meal',
        checkme     => 'ON',
        comment     => "Now is the time for\nall good men\nto come to the aid",
        crackme     => undef,
        date        => '2004-09-29',
        donotcheckme => undef,
        item        => 'Cat food',
        multi       => [ qw/ banana orange plum /],
        notdefined  => undef,
        price       => '10.99',
        shipping    => 'FedEx',
        unexpect    => 'I am the slime',
        xssme       => undef,
        no_client   => 1,
        client_email => 'whitemice@hyperintelligent_pandimensional_beings.com',
        client      => undef,
    });

    is( @{ $one->errors }, 2 );
    like( @{ $one->errors }[ 0 ], qr/Only letters, numbers, and/ );
    like( @{ $one->errors }[ 1 ], qr/Only letters, numbers, and/ );

        $one->allow_unexpected( 0 );
    is( $one->op, 'default' );
    is( $one->param( 'crackme' ), undef );
    is( $one->param( 'item' ), undef );
    is( $one->param( 'price' ), undef );
    is( $one->param( 'shipping' ), undef );
    is( $one->param( 'unexpect' ), undef );
    is( $one->Vars, undef );
    is( $one->errors, undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# allow unexpected
        $one->allow_unexpected( 1 );
    is( $one->param( 'comment' ), "Now is the time for\nall good men\nto come to the aid" );
    is( $one->param( 'crackme' ), undef );
    is( $one->param( 'item' ), 'Cat food' );
    is( $one->param( 'price' ), '10.99' );
    is( $one->param( 'shipping' ), 'FedEx' );
    is( $one->param( 'unexpect' ), 'I am the slime' );
    is( $one->param( 'client_email' ), 'whitemice@hyperintelligent_pandimensional_beings.com' );
    is( $one->param( 'no_client' ), 1 );
    is( $one->param( 'client' ), 'disappear' ); #no alternative check specified
    is( $one->param( 'client', [ 'alternative(no_client)' ]), undef );
    is_deeply( $one->param( 'multi' ), [ qw/ banana orange plum /]);
    is_deeply( { $one->Vars }, {
        name        => 'Mouse-a-meal',
        checkme     => 'ON',
        comment     => "Now is the time for\nall good men\nto come to the aid",
        crackme     => undef,
        date        => '2004-09-29',
        donotcheckme => undef,
        item        => 'Cat food',
        multi       => [ qw/ banana orange plum /],
        notdefined  => undef,
        price       => '10.99',
        shipping    => 'FedEx',
        unexpect    => 'I am the slime',
        xssme       => undef,
        no_client   => 1,
        client_email => 'whitemice@hyperintelligent_pandimensional_beings.com',
        client      => undef,
    });
    is( @{ $one->errors }, 2 );
    like( @{ $one->errors }[ 0 ], qr/Only letters, numbers, and/ );
    like( @{ $one->errors }[ 1 ], qr/Only letters, numbers, and/ );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# do not allow unexpected
        $one->allow_unexpected( 0 );
    is( $one->param( 'crackme' ), undef );
    is( $one->param( 'item' ), undef );
    is( $one->param( 'price' ), undef );
    is( $one->param( 'shipping' ), undef );
    is( $one->param( 'unexpect' ), undef );
    is( $one->Vars, undef );
    is( $one->errors, undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# on error return encoded
        $one = init_obj({ -on_error_return_encoded => 1 });
        $one->allow_unexpected( 1 );
    is( $one->on_error_return_encoded, 1 );
    is( $one->param( 'comment' ), "Now is the time for\nall good men\nto come to the aid" );
    is( $one->param( 'crackme' ), '$ENV{ meat_of_evil }' );
    is( $one->param( 'item' ), 'Cat food' );
    is( $one->param( 'price' ), '10.99' );
    is( $one->param( 'shipping' ), 'FedEx' );
    is( $one->param( 'unexpect' ), 'I am the slime' );
    is( $one->param( 'xssme' ), '&lt;script&gt;alert(&quot;haxored&quot;)&lt;/script&gt;' );
    is( $one->param( 'client_email' ), 'whitemice@hyperintelligent_pandimensional_beings.com' );
    is( $one->param( 'no_client' ), 1 );
    is( $one->param( 'client' ), 'disappear' ); #No alternative check specified
    is( $one->param( 'client', [ 'alternative(no_client)' ]), undef );
    is_deeply( $one->param( 'multi' ), [ qw/ banana orange plum /]);
    is_deeply( { $one->Vars }, {
        name        => 'Mouse-a-meal',
        checkme     => 'ON',
        comment     => "Now is the time for\nall good men\nto come to the aid",
        crackme     => '$ENV{ meat_of_evil }',
        date        => '2004-09-29',
        donotcheckme => undef,
        item        => 'Cat food',
        multi       => [ qw/ banana orange plum /],
        notdefined  => undef,
        price       => '10.99',
        shipping    => 'FedEx',
        unexpect    => 'I am the slime',
        xssme       => '&lt;script&gt;alert(&quot;haxored&quot;)&lt;/script&gt;',
        no_client   => 1,
        client_email => 'whitemice@hyperintelligent_pandimensional_beings.com',
        client      => undef,
    });
    is( @{ $one->errors }, 2 );
    like( @{ $one->errors }[ 0 ], qr/Only letters, numbers, and/ );
    like( @{ $one->errors }[ 1 ], qr/Only letters, numbers, and/ );


# vim:ft=perl
