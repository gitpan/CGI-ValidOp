#!/usr/bin/perl -T
use warnings;
use strict;

use lib qw/ t lib /;

package Main;

use Test::More tests => 95;
use Test::Taint;
use vars qw/ $one $validator $errmsg $tmp $sub @params /;
use Data::Dumper;
use Carp;

BEGIN { use_ok( 'CGI::ValidOp::Check' )}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# setup
    sub taintme {
        my $value = shift;
        taint( $value );
        tainted_ok( $value );
        $value;
    }

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# defaults
    eval{ CGI::ValidOp::Check->new( 'zippy' )};
    like( $@, qr/No such check \("zippy"\) in package "CGI::ValidOp::Check"/ );

    $one = CGI::ValidOp::Check->new;

    ok( defined( $one ));
    ok( $one->isa( 'CGI::ValidOp::Check' ));

    ok(( $validator, $errmsg ) = $one->default );
    is( ref $validator, 'CODE' );
    is( $errmsg, 'Parameter $label contained invalid data.' );

    is( $one->name, 'default' );
    is( ref $one->validator, 'CODE' );
    is( $one->errmsg, 'Parameter $label contained invalid data.' );

    eval{ $one->check };
    like( $@, qr/You must override CGI::ValidOp::Check::check/ );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# pass/fail
    is_deeply([ $one->pass ], [ undef, undef ]);
    is_deeply([ $one->pass( 'foo' ) ], [ 'foo', undef ]);

    is_deeply([ $one->fail ], [ undef, undef ]);
    is_deeply([ $one->fail( 'foo' )], [ undef, 'foo' ]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# regex checks
    taint_checking_ok();

        $tmp = taintme( 'a' );
    is_deeply([ $one->check_regexp( $tmp, qr/^\w$/ )], [ 'a', undef ]);
    untainted_ok( $one->check_regexp( $tmp, qr/\w/ ));

        $tmp = taintme( 1 );
    is_deeply([ $one->check_regexp( $tmp, qr/^\w$/ )], [ 1, undef ]);
    untainted_ok( $one->check_regexp( $tmp, qr/\w/ ));

        $tmp = taintme( '_' );
    is_deeply([ $one->check_regexp( $tmp, qr/^\w$/ )], [ '_', undef ]);
    untainted_ok( $one->check_regexp( $tmp, qr/\w/ ));

    is_deeply([ $one->check_regexp( 'fo', qr/^\w$/ )], [ undef, 'Parameter $label contained invalid data.' ]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# coderef checks
        $sub = sub{ return unless my $v = shift; $v =~ /^(foo)$/; return $1; };
    is( $one->check_code( undef,     $sub ), undef );
    is( $one->check_code( 0,         $sub ), undef );
    is( $one->check_code( 'foo bar', $sub ), undef );

        $tmp = taintme( 'foo' );
    is( $one->check_code( $tmp, $sub ), 'foo' );
    untainted_ok( $one->check_code( $tmp, $sub ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# test package
package CGI::ValidOp::Check::Test;
    use strict;
    use warnings;
    use base qw/ CGI::ValidOp::Check /;

    sub default {(
        qr/\w/,
        'Must be one character',
    )}

    sub coderef {
        my $self = shift;
        sub {
            my $value = shift;
            $value =~ /^(foo)$/;
            return $self->pass( $1 ) if $1;
            $self->fail( 'Must be foo' );
        }
    }

    sub coderef_tainted {
        my $self = shift;
        sub {
            return $self->fail( 'this should go down in flames' )
                unless $_[ 0 ] eq 'foo';
            $self->pass( $_[ 0 ] );
        }
    }

    sub echo_incoming {
        my $self = shift;
        sub {
            $self->pass( join '-', @_ );
        }
    }

    sub arrayref { [ qw/ one two three /] }

    sub notaref { 'foo' }

    sub should_pass {
        my $self = shift;
        sub {
            $self->pass( 1 );
        }
    }

    sub should_fail {
        my $self = shift;
        sub {
            $self->fail( 'this should fail' );
        }
    }

    sub should_allow_tainted {
        my $self = shift;
        sub {
            $self->allow_tainted( 1 );
            $self->pass( $_[ 0 ]);
        };
    }

    sub should_check_undef {
        my $self = shift;
        sub {
            my $value = shift;
            return $self->pass( 'undefined' ) unless defined $value;
            $self->pass( 'defined' );
        }
    }

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
package Main;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# disallowed types
    eval{ $one = CGI::ValidOp::Check::Test->new( 'arrayref' )};
    like( $@, qr/Disallowed reference type for validator. You used ARRAY; valid types are: regexp code/ );

    eval{ $one = CGI::ValidOp::Check::Test->new( 'notaref' )};
    like( $@, qr/Disallowed reference type for validator. You used ; valid types are: regexp code/ );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# default
        $one = CGI::ValidOp::Check::Test->new;
    ok( defined( $one ));
    ok( $one->isa( 'CGI::ValidOp::Check::Test' ));
    is( $one->name, 'default' );
    is( $one->errmsg, 'Must be one character' );
    is( $one->validator, qr/\w/ );
    ok( ! $one->allow_tainted );

        $tmp = taintme( 'a' );
    is( $one->check( $tmp ), 'a' );
    untainted_ok( $one->check( $tmp ));
        $tmp = taintme( 1 );
    is( $one->check( $tmp ), 1 );
    untainted_ok( $one->check( $tmp ));

        $tmp = taintme( '/' );
    is( $one->check( $tmp ), undef );
    untainted_ok( $one->check( $tmp ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# pass/fail
        $one = CGI::ValidOp::Check::Test->new( 'should_pass' );
        $tmp = taintme( 'i will pass' );
    is( $one->check( $tmp ), 1 );
    untainted_ok( $one->check( $tmp ));

        $one = CGI::ValidOp::Check::Test->new( 'should_fail' );
        $tmp = taintme( 'i will fail' );
    is_deeply([ $one->check( $tmp )], [ undef, 'this should fail' ]);
    untainted_ok( $one->check( $tmp ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# coderef
        $one = CGI::ValidOp::Check::Test->new( 'coderef' );
    ok( defined( $one ));
    ok( $one->isa( 'CGI::ValidOp::Check::Test' ));
    is( $one->name, 'coderef' );
    is( $one->errmsg, undef );
    is( ref $one->validator, 'CODE' );

        $tmp = taintme( 'a' );
    is( $one->check( $tmp ), undef );
    untainted_ok( $one->check( $tmp ));

        $tmp = taintme( 1 );
    is( $one->check( $tmp ), undef );
    untainted_ok( $one->check( $tmp ));

        $tmp = taintme( 0 );
    is( $one->check( $tmp ), undef );
    untainted_ok( $one->check( $tmp ));

        $tmp = taintme( 'foo' );
    is( $one->check( $tmp ), 'foo' );
    untainted_ok( $one->check( $tmp ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# tainted coderef
        $one = CGI::ValidOp::Check::Test->new( 'coderef_tainted' );
    ok( defined( $one ));
    ok( $one->isa( 'CGI::ValidOp::Check::Test' ));
    is( $one->name, 'coderef_tainted' );
    is( $one->errmsg, undef );
    is( ref $one->validator, 'CODE' );

        $tmp = taintme( 'foo' );
    eval{ $one->check( $tmp )};
    like( $@, qr/Validator returned a tainted value/ );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# allow tainted
        $one = CGI::ValidOp::Check::Test->new( 'should_allow_tainted' );
    ok( ! $one->allow_tainted );

        $tmp = taintme( 'foo' );
    is( $one->check( $tmp ), 'foo' );
    ok( $one->allow_tainted );
    tainted_ok( $one->check( $tmp ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# echo incoming parameters
        @params = qw/ fee fi foe /;
        $one = CGI::ValidOp::Check::Test->new( 'echo_incoming', @params );
    is_deeply([ $one->params ], \@params );
    is_deeply([ $one->check( 'foo' )], [ 'foo-fee-fi-foe', undef ]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# check undef
        $one = CGI::ValidOp::Check::Test->new( 'should_check_undef' );
    ok( $one->should_check_undef );

    is( $one->check( 'foo' ), 'defined' );
    is( $one->check( undef ), 'undefined' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# for documentation
# these tests are redundant, but i want to make sure what i'm
# putting in the docs is correct
    package CGI::ValidOp::Check::demo;
    use base qw/ CGI::ValidOp::Check /;

    sub default {
        (
            qr/^demo$/,                  # validator
            '$label must equal "demo."', # error message
        )
    }

    sub color {
        my $self = shift;
        (
            sub {
                my( $value, $color ) = @_;
                return $1 if $value =~ /^($color)$/i;
                $self->errmsg( "\$label must be the color: $color." );
                return;
            },
        )
    }

    package Main;

    my $demo = CGI::ValidOp::Check::demo->new;
    is( $demo->check( 'failure' ), undef );
    is( $demo->check( 'demo' ), 'demo' );
        my $value = $demo->check( 'demo' );
    ok( ! $demo->is_tainted( $value ));

    my $demo_color = CGI::ValidOp::Check::demo->new( 'color', 'red' );
    is( $demo_color->check( 'green' ), undef );
    is( $demo_color->errmsg, '$label must be the color: red.' );
    is( $demo_color->check( 'red' ), 'red' );

# vim:ft=perl
