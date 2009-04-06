#!/usr/bin/perl
use warnings;
use strict;

use lib qw/ t lib /;

use Test::More tests => 113;
use Test::Exception;
use vars qw/ $one $tmp $required_error $text_error $error $param $check /;
use Data::Dumper;

BEGIN { use_ok( 'CGI::ValidOp::Param' )}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# setup error messages
    $required_error = '$label is required.';
    $text_error = 'Only letters, numbers, and the following punctuation are allowed for $label: ! " \' ( ) * , - .  / : ; ? \ @ & %';

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# constructor
    throws_ok{ $one = CGI::ValidOp::Param->new }
        qr/Parameter names are required for all values/;

    ok( $one = CGI::ValidOp::Param->new( 'foo' ));
    ok( $one->isa( 'CGI::ValidOp::Param' ));
    ok( $one->label( 'I am Foo' ));
    is( $one->required, 0 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# label
    is( $one->label( undef ), undef );
    is( $one->label, undef );
    is( $one->label( 'Bar None' ), 'Bar None' );
    is( $one->label, 'Bar None' );

    ok( $one = CGI::ValidOp::Param->new({
        name    => 'foo',
        label   => 'Foo type',
    }));
    is( $one->label, 'Foo type' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# tainted
    is( $one->tainted( undef ), undef );
    is( $one->tainted, undef );
    is( $one->tainted( '' ), undef );
    is( $one->tainted, undef );
    is( $one->tainted( 'Bar None' ), 'Bar None' );
    is( $one->tainted, 'Bar None' );

    ok( $one = CGI::ValidOp::Param->new({
        name    => 'foo',
        label   => 'Foo type',
        tainted => 'fooby',
    }));
    is( $one->tainted, 'fooby' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# required
    is( $one->required( 0 ), 0 );
    is( $one->required, 0 );
    is( $one->required( 1 ), 1 );
    is( $one->required, 1 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# load check failing
        eval{ $one->load_check };
    like( $@, qr/Must pass a scalar check name to/ );
        eval{ $one->load_check( 'killme' )};
    like( $@, qr/Failed to require CGI::ValidOp::Check::killme/ );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# load check: simple package, default
    ok( $check = $one->load_check( 'text' ));
    ok( $check->isa( 'CGI::ValidOp::Check::text' ));
    is( $check->validator, qr#^[\w\s\(\*\.\\\?,!"'/:;@&%)-]+$# ); #
    is( $check->errmsg, q#Only letters, numbers, and the following punctuation are allowed for $label: ! " ' ( ) * , - .  / : ; ? \ @ & %# );  

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# load check: method in package
    ok( $check = $one->load_check( 'text::word' ));
    ok( $check->isa( 'CGI::ValidOp::Check::text' ));
    is( $check->validator, qr#^\w+$# );
    is( $check->errmsg, q#Only one word is allowed for $label# );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# load check: passing params
    ok( $check = $one->load_check( 'text(6,12)' ));
    is( $check->name, 'default' );
    is_deeply( [ $check->params ], [ 6, 12 ]);

    ok( $check = $one->load_check( 'text::word(6,12)' ));
    is( $check->name, 'word' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# multi check
# must check fail, then pass, to see if we get a value (we shouldn't)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# required failing should stop other tests


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# check_required
# |    RETURNS      | add_  |    | $param-> | defined |
# | undef | tainted | error | if | required | tainted |
# |-------|---------|-------|    |----------|---------|
# |   X   |         |   X   |    |   X      |         |
# |   X   |         |       |    |          |         |
# |       |   X     |       |    |   X      |   X     |
# |       |   X     |       |    |          |   X     |
#         delete $one->{ errors };
#     ok( $one->checks([ 'required' ]));
#     is( $one->tainted( undef ), undef );
#     is( $one->check_required, undef );
#     is( @{ $one->errors }, 1 );
#     is( $one->value, undef );
# 
#         delete $one->{ errors };
#     ok( $one->checks([ 'required' ]));
#     is( $one->tainted( 'bar' ), 'bar' );
#     is( $one->check_required, 'bar' );
#     is( $one->errors, undef );
#     is( $one->value, 'bar' );
# 
#         delete $one->{ errors };
#     is( $one->checks( undef ), undef );
#     is( $one->tainted( 'bar' ), 'bar' );
#     is( $one->check_required, 'bar' );
#     is( $one->errors, undef );
#     is( $one->value, 'bar' );
# 
#         delete $one->{ errors };
#     is( $one->checks( undef ), undef );
#     is( $one->tainted( undef ), undef );
#     is( $one->check_required, undef );
#     is( $one->errors, undef );
#     is( $one->value, undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# checks dying
    eval{ $one->check };
    like( $@, qr/Must pass a scalar check name to CGI::ValidOp::Param::load_check/ );

    eval{ $one->check([ qw/ required /])};
    like( $@, qr/Must pass a scalar check name to CGI::ValidOp::Param::load_check/ );

    eval{ $one->check( 'fooby' )};
    like( $@, qr/Must pass a scalar check name to CGI::ValidOp::Param::load_check/ );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# check
        delete $one->{ errors };
    is( $one->check( 'foo', 'text' ), 'foo' );
    is( $one->errors, undef );

    is( $one->check( 'foo', 'text' ), 'foo' );
    is( $one->errors, undef );

    is( $one->check( "\0", 'text' ), undef );
    is( @{ $one->errors }, 1 );
    like( $one->errors->[ 0 ], qr/Only letters, numbers, and the following punctuation are allowed for Foo type/ );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# multiple values
    ok( $one = CGI::ValidOp::Param->new({
        name    => 'fruits',
        label   => 'Fruits I like',
    }));

        $one->tainted( "orange\0plum\0nectarine" );
    is( $one->validate, undef );
    is( $one->errors, undef );
    is_deeply( $one->value, [ qw/ orange plum nectarine /]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# validate: required fails
    ok( $one = CGI::ValidOp::Param->new({
        name    => 'foo',
        label   => 'Foo type',
        checks  => [ 'required' ],
    }));
    ok( $one->isa( 'CGI::ValidOp::Param' ));
    is( $one->required, 1 );

        ( $error = $required_error ) =~ s/\$label/Foo type/;

        $one->validate;
    is( @{ $one->errors }[ 0 ], $error );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# validate: text fails
    ok( $one = CGI::ValidOp::Param->new({
        name    => 'foo',
        label   => 'Foo type',
        checks  => [ 'required', 'text' ],
    }));

        $one->tainted( '$ENV{crackme}' );
        ( $error = $text_error ) =~ s/\$label/Foo type/;
        $one->validate;
    is( @{ $one->errors }[ 0 ], $error );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# validate: both succeed
    ok( $one = CGI::ValidOp::Param->new({
        name    => 'foo',
        label   => 'Foo type',
        checks  => [ 'required', 'text' ],
    }));

        $one->tainted( 'i am some regular text.  foo!' );

    is( $one->validate, undef );
    is( $one->errors, undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# value
        $one->tainted( undef );
    is( $one->validate, undef );
    is( $one->value, undef );
        eval{ $one->value( 'die' )};
    like( $@, qr/Cannot directly set parameter value/ );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# value, taking into account on_error_return
    can_ok( $one, 'on_error_return' );
    is( $one->on_error_return, 'undef' );

    ok( $one = CGI::ValidOp::Param->new({
        name    => 'foo',
    }));
        $one->tainted( '<script>crackme()</script>' );
    is( $one->value, undef );

    # encoded
    ok( $one = CGI::ValidOp::Param->new({
        name    => 'foo',
    }));
        $one->on_error_return( 'encoded' );
        $one->tainted( '<script>crackme()</script>' );
    is( $one->value, '&lt;script&gt;crackme()&lt;/script&gt;' );

    # tainted
    ok( $one = CGI::ValidOp::Param->new({
        name    => 'foo',
    }));
        $one->on_error_return( 'tainted' );
        $one->tainted( '<script>crackme()</script>' );
    is( $one->value, '<script>crackme()</script>' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# values, make sure on_error_return doesn't affect valid params
    ok( $one = CGI::ValidOp::Param->new({
        name    => 'foo',
        checks  => [ 'required' ],
    }));
    is( $one->value, undef );

    ok( $one = CGI::ValidOp::Param->new({
        name    => 'foo',
        checks  => [ 'text::liberal' ],
    }));
        $one->tainted( 'He said "foo"' );
    is( $one->value, 'He said "foo"' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# errors
    ok( $one = CGI::ValidOp::Param->new({
        name    => 'foo',
        label   => 'Foo type',
    }));
    is( $one->label, 'Foo type' );
    is( $one->errors, undef );

    is( $one->add_error, undef );
    is( $one->add_error( 'foo' ), undef );
    is( $one->errors, undef );

    ok( $one->add_error( 'text', 'jack sprat would eat no fat; $label' ));
    is( @{ $one->errors }, 1 );
    is( $one->{ errors }{ text }, 'jack sprat would eat no fat; Foo type' );
    is( @{ $one->errors }[ 0 ], 'jack sprat would eat no fat; Foo type' );
    
    ok( $one->error_decoration( '"' ));
    ok( $one->add_error( 'wb', 'fiery the angels fell; $label' ));
    is( @{ $one->errors }, 2 );
    is( $one->{ errors }{ wb }, 'fiery the angels fell; "Foo type"' );

    is( @{ $one->errors }[ 0 ], 'fiery the angels fell; "Foo type"' );
    is( @{ $one->errors }[ 1 ], 'jack sprat would eat no fat; Foo type' );
    
    ok( $one->error_decoration( '[', ']' ));
    ok( $one->add_error( 'wb', 'fiery the angels rose; $label' ));
    is( @{ $one->errors }, 2 );
    is( $one->{ errors }{ wb }, 'fiery the angels rose; [Foo type]' );
    is( @{ $one->errors }[ 0 ], 'fiery the angels rose; [Foo type]' );
    
    ok( $one->label( 'plain' ));
    ok( $one->error_decoration( '<<', '>>' ));
    ok( $one->add_error( 'wb', 'The rain in Spain falls mainly in the $label.' ));
    is( @{ $one->errors }, 2 );
    is( $one->{ errors }{ wb }, 'The rain in Spain falls mainly in the <<plain>>.' );
    is( @{ $one->errors }[ 0 ], 'The rain in Spain falls mainly in the <<plain>>.' );
    
    ok( $one->error_decoration( '<em>', '</em>' ));
    ok( $one->add_error( 'wb(3)', 'The rain in Spain falls mainly in the <em>plain</em>.' ));
    is( @{ $one->errors }, 2 );
    is( $one->{ errors }{ wb }, 'The rain in Spain falls mainly in the <em>plain</em>.' );
    is( @{ $one->errors }[ 0 ], 'The rain in Spain falls mainly in the <em>plain</em>.' );

    ok( $one->add_error( 'wb::los', 'Zoa.' ));
    is( @{ $one->errors }, 3 );
    is( $one->{ errors }{ 'wb::los' }, 'Zoa.' );
    is( @{ $one->errors }[ 1 ], 'Zoa.' );
    
    delete $one->{ errors };
__END__
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# dies too gorily for a TODO test ...
    local $TODO = '';
    ok( $one = CGI::ValidOp::Param->new({
        name    => 'foo-bar',
        label   => 'Foo type',
    }));
    is( $one->label, 'Foo type' );


# vim:ft=perl
