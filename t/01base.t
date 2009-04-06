#!/usr/bin/perl -T
use warnings;
use strict;

use lib qw/ t lib /;

package Main;
use Test::More tests => 76;
use Test::Taint;
use Test::Exception;
use vars qw/ $one $two $tmp @tmp %tmp /;
use Data::Dumper;

BEGIN { use_ok( 'CGI::ValidOp::Base' )}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# test package with no PROPERTIES
    package CGI::ValidOp::NoPROPERTIES;
    use base qw/ CGI::ValidOp::Base /;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# object creation
    package Main;

    $one = CGI::ValidOp::NoPROPERTIES->new;
    ok( defined( $one ));
    ok( $one->isa( 'CGI::ValidOp::NoPROPERTIES' ));
    ok( $one->isa( 'CGI::ValidOp::Base' ));

    $two = $one->new;
    ok( defined( $two ));
    ok( $two->isa( 'CGI::ValidOp::NoPROPERTIES' ));
    ok( $two->isa( 'CGI::ValidOp::Base' ));

    $one = new CGI::ValidOp::NoPROPERTIES;
    ok( defined( $one ));
    ok( $one->isa( 'CGI::ValidOp::NoPROPERTIES' ));
    ok( $one->isa( 'CGI::ValidOp::Base' ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# set_name() failures
        $one->{ name } = undef;
    is( $one->{ name }, undef );

    throws_ok{ $one->set_name({})} qr/ERROR:  set_name\(\) API./;
    throws_ok{ $one->set_name([ 'foo' ])} qr/ERROR:  set_name\(\) API./;
    throws_ok{ $one->set_name({ foo => 'foo' })} qr/ERROR:  set_name\(\) API./;
    throws_ok{ $one->set_name( \'foo' )} qr/ERROR:  set_name\(\) API./;
    throws_ok{ $one->set_name({ bar => 'name' })} qr/ERROR:  set_name\(\) API./;

    throws_ok{ $one->set_name } qr/Parameter names are required for all values./;
    throws_ok{ $one->set_name({ name => undef })} qr/Parameter names are required for all values./;

    throws_ok{ $one->set_name( 'rank and serial number' )} qr/Parameter names must contain only letters, numbers, underscores, and square brackets./;
    throws_ok{ $one->set_name({ name => 'foo bar' })} qr/Parameter names must contain only letters, numbers, underscores, and square brackets./;

    is( $one->{ name }, undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# set_name() successes
    is( $one->set_name({ name => 'bar' }), 'bar' );
    is( $one->{ name }, 'bar' );

        delete $one->{ name };
    is( $one->set_name( 'foo' ), 'foo' );
    is( $one->{ name }, 'foo' );

    is( $one->set_name( 'baz' ), 'baz' );
    is( $one->{ name }, 'baz' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# set_name() successes, with brackets in name
# ... although technically any characters are valid markup
    is( $one->set_name({ name => 'foo[bar]' }), 'foo[bar]' );
    is( $one->{ name }, 'foo[bar]' );

        delete $one->{ name };
    is( $one->set_name( '[]' ), '[]' );
    is( $one->{ name }, '[]' );

    is( $one->set_name( '[baz' ), '[baz' );
    is( $one->{ name }, '[baz' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# taint checking
        $tmp = 'foo';
        taint( $tmp );
    tainted_ok( $tmp );
    ok( $one->is_tainted( $tmp ));
        $tmp =~ /^(foo)$/;
    untainted_ok( $1 );
    ok( ! $one->is_tainted( $1 ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# error_decoration
    is( $one->error_decoration, undef );
    is( $one->error_decoration( undef ), undef );
    is( $one->error_decoration( $one->error_decoration ), undef );

    is_deeply([ $one->error_decoration( undef, 'END' )], [ undef, 'END' ]);
    is_deeply([ $one->error_decoration ], [ undef, 'END' ]);

    is_deeply([ $one->error_decoration( 'BEGIN', undef )], [ 'BEGIN', undef ]);
    is_deeply([ $one->error_decoration ], [ 'BEGIN', undef ]);

    is_deeply([ $one->error_decoration( '[', ']' )], [ '[', ']' ]);
    is_deeply([ $one->error_decoration ], [ '[', ']' ]);

    is_deeply([ $one->error_decoration( '"' )], [ '"', '"' ]);
    is_deeply([ $one->error_decoration ], [ '"', '"' ]);

    is_deeply([ $one->error_decoration([ '[', ']' ])], [ '[', ']' ]);
    is_deeply([ $one->error_decoration ], [ '[', ']' ]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# test package with PROPERTIES
    package CGI::ValidOp::HasProperties;
    use base qw/ CGI::ValidOp::Base /;

    sub PROPERTIES {
        {
            boy         => 'calvin',
            not_defined => undef,
            zero        => 0,
            arrayref    => [ 17, 19, 23 ],
            hashref     => { foo => 'bar', bar => 'foo' },
            array       => ( 'one', 'two', 'three' ),
        }
    }

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    package Main;
    $one = CGI::ValidOp::HasProperties->new;
    ok( defined( $one ));
    ok( $one->isa( 'CGI::ValidOp::HasProperties' ));
    ok( $one->isa( 'CGI::ValidOp::Base' ));

    is( $one->boy, 'calvin' );
    is( $one->not_defined, undef);
    is( $one->zero, 0);

        @tmp = $one->arrayref;
    is( @tmp, 3 );
    is_deeply( \@tmp, [ 17, 19, 23 ]);

        %tmp = $one->hashref;
    is( keys %tmp, 2 );
    is_deeply( { $one->hashref }, { foo => 'bar', bar => 'foo' });

    is( $one->array, 'one' ); # arrays are bad, m'kay?
    is( $one->two, 'three' ); # arrays are bad, m'kay?

    is( $one->boy( 1 ), 1 );
    is( $one->boy, 1 );

    is( $one->boy( 0 ), 0 );
    is( $one->boy, 0 );

    is( $one->boy( undef ), undef );
    is( $one->boy, undef );

    is( $one->boy( '' ), undef );
    is( $one->boy, undef );

    is( $one->boy( 3, 7, 11 ), 3 );
    is( $one->boy, 3 );

    is_deeply( [ $one->boy([ 3, 7, 11 ]) ], [ 3, 7, 11 ]);
    is_deeply( [ $one->boy ], [ 3, 7, 11 ]);

    is_deeply( { $one->boy({ a => 2, b => 4 }) }, { a => 2, b => 4 });
    is_deeply( { $one->boy }, { a => 2, b => 4 });

# vim:ft=perl
