package CGI::ValidOp::Test;
use strict;
use warnings;

require Exporter;
use vars qw/
    @ISA @EXPORT
    $one $tmp @tmp %tmp
    $vars1 $ops1 $ops2 $ops3
/;

@ISA = qw/ Exporter /;
@EXPORT = qw/
    $vars1 $ops1 $ops2 $ops3
    &check_taint &check_check
    &init_param
    &init_obj
    init_obj_via_cgi_pm
    /;

use Carp;
use Data::Dumper;
use Test::More;
use Test::Taint;

# {{{ data 1  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    $vars1 = {
        name         => 'Mouse-a-meal',
        item         => 'Cat food',
        price        => '10.99',
        shipping     => 'FedEx',
        client_email => 'whitemice@hyperintelligent_pandimensional_beings.com',
        no_client    => 1,
        client       => undef,
    };

    $ops1 = {
        add => {
            name         => [ 'item brand name', 'required' ],
            item         => [ 'item name', 'required' ],
            number       => [ 'item number', 'required' ],
            shipping     => [ 'shipping method', 'required' ],
            client       => [ 'client name', 'alternative(no_client)' ],
            no_client    => [ 'no client option' ],
            client_email => [ 'client email address', 'email' ],

        },
        remove => {
            number => [ 'item number', 'required' ],
            item   => [ 'item name', 'required' ],
        },
    };

    $ops2 = {
        add => {
            stuff => {
                name         => [ 'item brand name', 'required' ],
                item         => [ 'item name', 'required' ],
                number       => [ 'item number', 'required' ],
                shipping     => [ 'shipping method', 'required' ],
                client       => [ 'client name', 'alternative(no_client)' ],
                no_client    => [ 'no client option' ],
                client_email => [ 'client email address', 'email' ],
            }
        }
    };
    
    $ops3 = {
        add => {
            stuff => {
                -construct_object => 'Stuff',
                name         => [ 'item brand name', 'required' ],
                item         => [ 'item name', 'required' ],
                number       => [ 'item number', 'required' ],
                shipping     => [ 'shipping method', 'required' ],
                client       => [ 'client name', 'alternative(no_client)' ],
                no_client    => [ 'no client option' ],
                client_email => [ 'client email address', 'email' ],
            }
        }
    };
# }}}
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub check_check {
    my( $check_name, $value, $expect_value, $expect_tainted, $errmsg ) = @_;

    no warnings qw/ uninitialized /; # many of these values are optional

    taint_checking_ok( undef );
    taint( $value );
    tainted_ok( $value );

    my $test_id = $errmsg
        ? "testing: $value fails with $check_name"
        : "testing: $value = $expect_value with $check_name";

    my $caller = join ' : ' => ( caller() )[ 1, 2 ];
    my $param = CGI::ValidOp::Param->new({ name => 'tester', label => 'William Blake' });
    ok( $param->isa( 'CGI::ValidOp::Param' ), $test_id );

    my $new_value;
    eval{ $new_value = $param->check( $value, $check_name )};
    croak "Unexpected check failure: $@"
        if $@ and $expect_value ne 'DIE';

    # if we tell it to expect 'DIE', then it should die and we match
    # $@ against the expected error message
    defined $expect_value and $expect_value eq 'DIE'
        ? like( $@, qr/$errmsg/, $caller )
        : is( $new_value, $expect_value, $caller );
    $expect_tainted
        ? tainted_ok( $new_value, $caller )
        : untainted_ok( $new_value, $caller );
    $errmsg and !( $expect_value and $expect_value eq 'DIE' )
        ? like( @{ $param->errors }[0], qr/$errmsg/, $caller )
        : is( $param->errors, undef, $caller );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub init_param {
    my $spec = shift;
    ok( my $param = CGI::ValidOp::Param->new( $spec ));
    $param;
}
 
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub init_obj {
    $ENV{ REQUEST_METHOD } = 'GET';
    $ENV{ QUERY_STRING } = join '&',
        "comment=Now is the time for\nall good men\nto come to the aid",
        'crackme=$ENV{ meat_of_evil }',
        'date=2004-09-29',
        'name=Mouse-a-meal',
        'item=Cat food',
        'multi=banana',
        'multi=orange',
        'multi=plum',
        'notdefined=',
        'op=add',
        'price=10.99',
        'shipping=FedEx',
        'unexpect=I am the slime',
        'checkme=ON',
        'donotcheckme=',
        'xssme=<script>alert("haxored")</script>',
        'client_email=whitemice@hyperintelligent_pandimensional_beings.com',
        'no_client=1',
        'client=disappear',
    ;
    my $obj = CGI::ValidOp->new ( @_ );
    ok( $obj->isa( 'CGI::ValidOp' ));
    return $obj;
}

sub init_obj_via_cgi_pm {
    my ($params, $ops) = @_;

    my $q = new CGI;
    $q->param( -name => $_, -value => $params->{$_} ) foreach (keys %$params);
    return CGI::ValidOp->new({ -cgi_object => $q, %$ops});
}


1;

__END__

=head1 NAME 

CGI::ValidOp::Test - test class for CGI::ValidOp and its associates.

=head1 DESCRIPTION

none yet

=head1 AUTHOR

Randall Hansen <legless@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2003-2005 Randall Hansen. All rights reserved.

This program is free software; you may redistribute it and/or modify it under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut

# $Id: Base.pm 40 2004-10-03 06:26:24Z soh $
