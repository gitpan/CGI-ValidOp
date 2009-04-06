#!/usr/bin/perl -T
use strict;
use warnings;

use lib qw/ t lib /;

use CGI::ValidOp::Test;
use Test::More tests => 33;
use vars qw/ $one /;
use Data::Dumper;

BEGIN { use_ok( 'CGI::ValidOp' )}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# workflow 2, params called with checks 'on-the-fly'
        $one = init_obj({
            -error_decoration => '"',
        });
    is( $one->param( 'comment' ), "Now is the time for\nall good men\nto come to the aid" );
    is( $one->param( 'crackme', [ 'required', 'text' ]), undef );
    is( $one->param( 'foobar', [ 'required' ]), undef );
    is( $one->param( 'item', [ 'required', 'text' ]), 'Cat food' );
    is( $one->param( 'price', [ 'required' ]), '10.99' );
    is( $one->param( 'shipping', [ 'required' ]), 'FedEx' );
    is( $one->param( 'notdefined', [ 'required' ]), undef );
    is( $one->param( 'unexpect' ), 'I am the slime' );
    is( $one->param( 'client_email' ), 'whitemice@hyperintelligent_pandimensional_beings.com' );
    is( $one->param( 'no_client' ), 1 );
    is( $one->param( 'client' ), 'disappear' ); #No check
    is( $one->param( 'client', [ 'alternative(no_client)' ] ), undef );

    is( $one->param( 'donotcheckme', [ 'checkbox::boolean' ]), 0 );

    is_deeply( $one->param( 'multi' ), [ qw/ banana orange plum /]);
    is_deeply( { $one->Vars }, {
        name        => 'Mouse-a-meal',
        checkme     => 'ON',
        comment     => "Now is the time for\nall good men\nto come to the aid",
        crackme     => undef,
        date        => '2004-09-29',
        donotcheckme => 0,
        foobar      => undef,
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
    is( @{ $one->errors }, 3 );
    like( @{ $one->errors }[ 0 ], qr/"foobar" is required/ );
    like( @{ $one->errors }[ 1 ], qr/Only letters, numbers, and/ );
    like( @{ $one->errors }[ 2 ], qr/Only letters, numbers, and/ );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# do not allow unexpected
        $one->allow_unexpected( 0 );
    is( $one->param( 'comment', [ 'text' ] ), "Now is the time for\nall good men\nto come to the aid" );
    is( $one->param( 'crackme', [ 'required', 'text' ]), undef );
    is( $one->param( 'foobar', [ 'required' ]), undef );
    is( $one->param( 'item', [ 'required', 'text' ]), 'Cat food' );
    is( $one->param( 'price', [ 'required' ]), '10.99' );
    is( $one->param( 'shipping', [ 'required' ]), 'FedEx' );
    is( $one->param( 'unexpect' ), undef );
    is_deeply( $one->param( 'multi', [ 'text' ] ), [ qw/ banana orange plum /]);
    is_deeply( { $one->Vars }, {
        comment     => "Now is the time for\nall good men\nto come to the aid",
        crackme     => undef,
        foobar      => undef,
        item        => 'Cat food',
        multi       => [ qw/ banana orange plum /],
        price       => '10.99',
        shipping    => 'FedEx',
    });
    is( @{ $one->errors }, 2 );
    like( @{ $one->errors }[ 0 ], qr/"foobar" is required/ );
    like( @{ $one->errors }[ 1 ], qr/Only letters, numbers, and/ );


# vim:ft=perl
