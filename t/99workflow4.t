#!/usr/bin/perl -T
use strict;
use warnings;

use lib qw/ t lib /;

use CGI::ValidOp::Test;
use Test::More tests => 30;
use vars qw/ $one /;
use Data::Dumper;

BEGIN { use_ok( 'CGI::ValidOp' )}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# workflow 4, params created at start
        $one = init_obj({
            add => {
                comment => [ 'Comment text', 'required', 'text'],
                item => [ 'item name', 'required', 'text' ],
                multi => [ 'Multiple parameters', 'required', 'text' ],
                price => [ 'item number', 'required', 'text' ],
                shipping => [ 'shipping method', 'required', 'text'],
                donotcheckme => [ 'Do not check me', 'checkbox::boolean' ],
                client => [ 'client name', 'alternative(no_client)' ],
                client_email => [ 'client_email', 'email' ],
                no_client => [ 'no client' ],
            },
        });

    is( $one->param( 'comment', [ 'text' ] ), "Now is the time for\nall good men\nto come to the aid" );
    is( $one->param( 'crackme' ), undef );
    is( $one->param( 'item' ), 'Cat food' );
    is( $one->param( 'price' ), '10.99' );
    is( $one->param( 'shipping' ), 'FedEx' );
    is( $one->param( 'unexpect' ), 'I am the slime' );
    is( $one->param( 'checkme' ), 'ON' );
    is( $one->param( 'client' ), undef );
    is( $one->param( 'client_email' ), 'whitemice@hyperintelligent_pandimensional_beings.com' );
    is_deeply( $one->param( 'multi', [ 'text' ] ), [ qw/ banana orange plum /]);
    is_deeply( { $one->Vars }, {
        name        => 'Mouse-a-meal',
        checkme     => 'ON',
        comment     => "Now is the time for\nall good men\nto come to the aid",
        crackme     => undef,
        date        => '2004-09-29',
        donotcheckme => 0,
        item        => 'Cat food',
        multi       => [ qw/ banana orange plum /],
        notdefined  => undef,
        price       => '10.99',
        shipping    => 'FedEx',
        unexpect    => 'I am the slime',
        xssme       => undef,
        client      => undef, 
        no_client   => 1,
        client_email => 'whitemice@hyperintelligent_pandimensional_beings.com',
    });
    is( @{ $one->errors }, 2 );
    like( @{ $one->errors }[ 0 ], qr/Only letters, numbers, and/ );
    like( @{ $one->errors }[ 1 ], qr/Only letters, numbers, and/ );

    # add arbitrary errors
    $one->Op->Param( 'crackme' )->add_error( 'fooby', '$label must be fooby!' );
    is( @{ $one->errors }, 3 );
    like( @{ $one->errors }[ 0 ], qr/Only letters, numbers, and/ );
    like( @{ $one->errors }[ 1 ], qr/Only letters, numbers, and/ );
    like( @{ $one->errors }[ 2 ], qr/must be fooby/ );

        $one->allow_unexpected( 0 );
    is( $one->param( 'comment', [ 'text' ] ), "Now is the time for\nall good men\nto come to the aid" );
    is( $one->param( 'crackme' ), undef );
    is( $one->param( 'item' ), 'Cat food' );
    is( $one->param( 'price' ), '10.99' );
    is( $one->param( 'shipping' ), 'FedEx' );
    is( $one->param( 'unexpect' ), undef );
    ok( ! $one->param( 'checkme' ));
    is_deeply( $one->param( 'multi', [ 'text' ] ), [ qw/ banana orange plum /]);
    is_deeply( { $one->Vars }, {
        comment     => "Now is the time for\nall good men\nto come to the aid",
        donotcheckme => 0,
        item        => 'Cat food',
        multi       => [ qw/ banana orange plum /],
        price       => '10.99',
        shipping    => 'FedEx',
        client      => undef, 
        no_client   => 1,
        client_email => 'whitemice@hyperintelligent_pandimensional_beings.com',
    });
    is( $one->errors, undef );


# vim:ft=perl
