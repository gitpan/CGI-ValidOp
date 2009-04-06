use constant TESTS => 22;
#===============================================================================
#
#         FILE:  99workflow5.t
#
#  DESCRIPTION:  Tests the objects functionality in a workflow-style fashion.
#                Greatly mimics elements from eMC.
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Erik Hollensbe (), <erik@hollensbe.org>
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  01/15/2008 06:17:20 AM PST
#     REVISION:  $Id$
#===============================================================================

use strict;
use warnings;

use Test::More tests => TESTS; # see line 1
use CGI::ValidOp::Test;

use_ok('CGI::ValidOp');

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    my $obj = init_obj_via_cgi_pm(
        {
            op => 'add',
            'stuff[0][name]' => '123 Foobar',
            'stuff[0][item]' => '8675309',
            'stuff[0][number]'     => 'Funkytown',
            'stuff[0][shipping]'    => 'PA',
            'stuff[0][client_email]' => 'shorts@shorts.com',
            'stuff[0][client]'       => 'bob',
            'stuff[0][no_client]'    => 0,
        },
        $ops2
    );

    isa_ok($obj, 'CGI::ValidOp');
    ok ($obj->objects('stuff'));
    isa_ok($obj->objects('stuff')->[0], 'HASH');
    is_deeply($obj->objects('stuff')->[0],
        {
            name => '123 Foobar',
            item => '8675309',
            number => 'Funkytown',
            shipping => 'PA',
            client      => 'bob', 
            no_client   => 0,
            client_email => 'shorts@shorts.com',
        }
    );

SKIP: {
    skip "no Loompa", 17 unless eval { require Loompa; 1 };
    package Stuff;
    our @ISA = qw(Loompa);

    sub methods { [qw(name item number shipping client client_email no_client)] }

    package main;

    # test constructing an object
    $obj = init_obj_via_cgi_pm(
        {
            op => 'add',
            'stuff[0][name]' => '123 Foobar',
            'stuff[0][item]' => '8675309',
            'stuff[0][number]'     => 'Funkytown',
            'stuff[0][shipping]'    => 'PA',
            'stuff[0][client_email]' => 'shorts@shorts.com',
            'stuff[0][client]'       => 'bob',
            'stuff[0][no_client]'    => 0,
        },
        $ops3
    );

    isa_ok($obj, 'CGI::ValidOp');
    ok($obj->objects('stuff'));
    isa_ok($obj->objects('stuff')->[0], 'Stuff');
    my $stuff = $obj->objects('stuff')->[0];

    can_ok($stuff, 'name');
    can_ok($stuff, 'number');
    can_ok($stuff, 'item');
    can_ok($stuff, 'shipping');
    can_ok($stuff, 'client');
    can_ok($stuff, 'client_email');
    can_ok($stuff, 'no_client');

    is($stuff->name, '123 Foobar');
    is($stuff->item, '8675309');
    is($stuff->number, 'Funkytown');
    is($stuff->shipping, 'PA');
    is($stuff->client, 'bob');
    is($stuff->no_client, 0);
    is($stuff->client_email, 'shorts@shorts.com');
}
