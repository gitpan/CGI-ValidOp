#!/usr/bin/perl -T
use strict;
use warnings;

use lib qw/ t lib /;

use CGI::ValidOp::Test;
use Test::More tests => 23;
use vars qw/ $one /;
use Data::Dumper;

BEGIN { use_ok( 'CGI::ValidOp' )}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# workflow 3, params added individually
        $one = init_obj;
        $one->allow_unexpected( 0 );
    ok( $one->add_param( 'name' ));
    ok( $one->add_param( 'item' ));
    ok( $one->add_param( 'multi' ));
    ok( $one->add_param( 'price' ));
    ok( $one->add_param( 'shipping' ));
    ok( $one->add_param( 'client_email' ));
    ok( $one->add_param( 'no_client' ));
    ok( $one->add_param( 'client' ));

    is( $one->param( 'name' ), 'Mouse-a-meal' );
    is( $one->param( 'crackme' ), undef );
    is( $one->param( 'item' ), 'Cat food' );
    is( $one->param( 'price' ), '10.99' );
    is( $one->param( 'shipping' ), 'FedEx' );
    is( $one->param( 'unexpect' ), undef );
    is( $one->param( 'client' ), 'disappear' ); #no check
    is( $one->param( 'client', [ 'alternative(no_client)' ] ), undef );
    is( $one->param( 'no_client' ), 1 );
    is( $one->param( 'client_email' ), 'whitemice@hyperintelligent_pandimensional_beings.com' );
    is_deeply( $one->param( 'multi', [ 'text' ] ), [ qw/ banana orange plum /]);
    is_deeply( { $one->Vars }, {
        name        => 'Mouse-a-meal',
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
