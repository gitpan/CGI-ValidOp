#!/usr/bin/perl
use warnings;
use strict;

use lib qw/ t lib /;

use Test::More tests => 84;
use Test::Exception;
use vars qw/ $one $param @params /;
use Data::Dumper;

BEGIN { use_ok( 'CGI::ValidOp::Op' )}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# constructor errors
    throws_ok{ $one = CGI::ValidOp::Op->new }
        qr/Parameter names are required for all values/;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# valid constructor
    ok( $one = CGI::ValidOp::Op->new( 'home' ));
    ok( $one->isa( 'CGI::ValidOp::Op' ));
    is( $one->name, 'home' );
    is( $one->{ name }, 'home' );
    is( $one->error_decoration, undef );
    is( $one->on_error_return, 'undef' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# name, alias
    ok( $one = CGI::ValidOp::Op->new({
        name    => 'home',
        alias   => [ 'Mad William', 'Mr Blake' ],
    }));
    is( $one->name, 'home' );
    is_deeply( [ $one->alias ], [ 'Mad William', 'Mr Blake' ]);

    ok( $one = CGI::ValidOp::Op->new({
        name    => 'home',
        alias   => 'poet',
    }));
    is( $one->name, 'home' );
    is_deeply( $one->alias, 'poet');

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# add_param failures
    is( $one->{ _params }, undef );

    throws_ok{ $one->add_param } qr/set_name\(\) API/;
    throws_ok{ $one->add_param( {} ) } qr/set_name\(\) API/;
    throws_ok{ $one->add_param({ foo => 'bar' }) } qr/set_name\(\) API/;
    throws_ok{ $one->add_param({ name => undef }) } qr/Parameter names are required for all values./;
    throws_ok{ $one->add_param({ name => 'foo bar' }) }
        qr/Parameter names must contain only letters, numbers, underscores, and square brackets./;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# add_param successes
    ok( $param = $one->add_param({ name => 'foo' }));
    ok( $param->isa( 'CGI::ValidOp::Param' ));
    is( $param->name, 'foo' );
    is( $param->on_error_return, 'undef' );

    ok( $param = $one->add_param({ name => 'foo[bar]' }));
    ok( $param->isa( 'CGI::ValidOp::Param' ));
    is( $param->name, 'foo[bar]' );
    is( $param->on_error_return, 'undef' );

    ok( $param = $one->{ _params }{ 'foo' });
    ok( $param->isa( 'CGI::ValidOp::Param' ));
    is( $param->name, 'foo' );
    is_deeply( [ $param->checks ], [ qw/ text /]);
    is( $param->tainted, undef );
    is( $param->value, undef );

        $one->on_error_return( 'encoded' );
    ok( $param = $one->add_param( 'bar' ));
    ok( $param->isa( 'CGI::ValidOp::Param' ));
    is( $param->name, 'bar' );
    is( $param->on_error_return, 'encoded' );

    ok( $param = $one->{ _params }{ 'bar' });
    ok( $param->isa( 'CGI::ValidOp::Param' ));
    is( $param->name, 'bar' );
    is_deeply( [ $param->checks ], [ qw/ text /]);
    is( $param->tainted, undef );
    is( $param->value, undef );

        $one->on_error_return( 'tainted' );
    ok( $param = $one->add_param({
        name    => 'wb',
        label   => 'William Blake',
        tainted => 'fiery the angels cracked my box',
        checks  => [ 'required', 'text' ],
    }));
    ok( $param->isa( 'CGI::ValidOp::Param' ));
    is( $param->name, 'wb' );
    is( $param->label, 'William Blake' );
    is( $param->tainted, 'fiery the angels cracked my box' );
    is_deeply( [ $param->checks ], [ qw/ required text /]);
    is( $param->value, 'fiery the angels cracked my box' );
    is( $param->on_error_return, 'tainted' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# add_param duplicates
    is( $param->label( 'I am Bar' ), 'I am Bar' );
        $one->add_param( 'bar' );
    ok( $param = $one->{ _params }{ 'bar' });
    is( $param->label, undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Param
    is( $one->Param( 'bang' ), undef );
    ok( $param = $one->Param( 'foo' ));
    ok( $param->isa( 'CGI::ValidOp::Param' ));
    is( $param->name, 'foo' );

    is( @{ $one->Param }, 4 );
    ok( @params = $one->Param );
    ok( $params[ $_ ]->isa( 'CGI::ValidOp::Param' ))
        for 0..2;

        delete $one->{ _params };
    is( $one->Param, undef );
    is( $one->Param( 'foo' ), undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# add_param called on incoming arguments with no dash
    ok( $one = CGI::ValidOp::Op->new({
        name    => 'home',
        error_decoration => [ '<em>', '</em>' ],
        comment => {
            label   => 'Comment text',
            checks  => [ 'required', 'text' ],
        },
        item => {
            label   => 'item name',
            checks  => [ 'required', 'text' ],
        },
        multi => {
            label   => 'Multiple parameters',
            checks  => [ 'required', 'text' ],
        },
        price => {
            label   => 'item number',
            checks  => [ 'required', 'text' ],
        },
        shipping => {
            label   => 'shipping method',
            checks  => [ 'required', 'text' ],
        },
    }));
    is_deeply([ $one->error_decoration ], [ '<em>', '</em>' ]);

    is( @{ $one->Param }, 5 );
    ok( @params = $one->Param );

    for( 0..4 ) {
        ok( $params[ $_ ]->isa( 'CGI::ValidOp::Param' ));
        is_deeply([ $params[ $_ ]->error_decoration ], [ '<em>', '</em>' ]);
    }

    is( $one->Param( 'item' )->name, 'item' );
    is( $one->Param( 'item' )->label, 'item name' );
    is_deeply( [ $one->Param( 'item' )->checks ], [ 'required', 'text' ]);
    ok( $one->Param( 'item' )->required );


