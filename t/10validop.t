#!/usr/bin/perl
use warnings;
use strict;

use lib qw/ t lib /;

use CGI::ValidOp::Test;
use Test::More tests => 238;
use vars qw/ $one $vars $ops $op $param @params %vars /;
use Data::Dumper;

BEGIN { use_ok( 'CGI::ValidOp' )}

# setup {{{ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    $vars = {
        item        => 'Cat food',
        price       => '10.99',
        shipping    => 'FedEx',
    };

    $ops = {
        add => {
            item => [ 'item name', 'required' ],
            number => [ 'item number', 'required' ],
            shipping => [ 'shipping method', 'required' ],
        },
        remove => {
            number => [ 'item number', 'required' ],
            item => [ 'item name', 'required' ],
        }
    };
# }}}
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# blank constructor
    $one = CGI::ValidOp->new;
    ok( defined( $one ));
    ok( $one->isa( 'CGI::ValidOp' ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# defaults
    is( $one->allow_unexpected, 1 );
    is( $one->default_op, 'default' );
    is( $one->runmode_name, 'op' );
    is( $one->print_warnings, 1 );
    is( $one->disable_uploads, 1 );
    is( $one->post_max, 25_000 );
    is( $one->error_decoration, undef );
    is( $one->on_error_return_undef, 1 );
    is( $one->on_error_return_encoded, 0 );
    is( $one->on_error_return_tainted, 0 );
    is( $one->return_only_received, 0 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# setting options
    $one = CGI::ValidOp->new({
        -allow_unexpected    => 0,
        -default_op          => 'home',
        -runmode_name        => 'action',
        -print_warnings      => 0,
        -disable_uploads     => 0,
        -post_max            => 2_500_000,
        -error_decoration    => [ '<em>', '</em>' ],
        foo => 'bar',
    });

    is( ref($one->cgi_object), 'CGI' );
    is( $one->allow_unexpected, 0 );
    is( $one->default_op, 'home' );
    is( $one->runmode_name, 'action' );
    is( $one->print_warnings, 0 );
    is( $one->disable_uploads, 0 );
    is( $one->post_max, 2_500_000 );
    is_deeply( { $one->ops }, { foo => 'bar' });
    is_deeply([ $one->error_decoration ], [ '<em>', '</em>' ]);
    is_deeply([ $one->error_decoration( 'foo', 'bar' )], [ 'foo', 'bar' ]);
    is( $one->on_error_return_undef, 1 );
    is( $one->on_error_return_encoded, 0 );
    is( $one->on_error_return_tainted, 0 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# setting options, checking precedence of on_error properties
        $one = CGI::ValidOp->new;
    is( $one->on_error_return_undef, 1 );
    is( $one->on_error_return_encoded, 0 );
    is( $one->on_error_return_tainted, 0 );

        $one = CGI::ValidOp->new({
            -on_error_return_undef      => 1,
            -on_error_return_encoded    => 1,
            -on_error_return_tainted    => 1,
        });
    is( $one->on_error_return_undef, 1 );
    is( $one->on_error_return_encoded, 0 );
    is( $one->on_error_return_tainted, 0 );

        $one = CGI::ValidOp->new({
            -on_error_return_undef      => 0,
            -on_error_return_encoded    => 1,
            -on_error_return_tainted    => 1,
        });
    is( $one->on_error_return_undef, 0 );
    is( $one->on_error_return_encoded, 1 );
    is( $one->on_error_return_tainted, 0 );

        $one = CGI::ValidOp->new({
            -on_error_return_undef      => 0,
            -on_error_return_encoded    => 0,
            -on_error_return_tainted    => 1,
        });
    is( $one->on_error_return_undef, 0 );
    is( $one->on_error_return_encoded, 0 );
    is( $one->on_error_return_tainted, 1 );

    # setting one only
        $one = CGI::ValidOp->new({
            -on_error_return_undef      => 1,
        });
    is( $one->on_error_return_undef, 1 );
    is( $one->on_error_return_encoded, 0 );
    is( $one->on_error_return_tainted, 0 );

        $one = CGI::ValidOp->new({
            -on_error_return_encoded    => 1,
        });
    is( $one->on_error_return_undef, 0 );
    is( $one->on_error_return_encoded, 1 );
    is( $one->on_error_return_tainted, 0 );

        $one = CGI::ValidOp->new({
            -on_error_return_tainted    => 1,
        });
    is( $one->on_error_return_undef, 0 );
    is( $one->on_error_return_encoded, 0 );
    is( $one->on_error_return_tainted, 1 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# setting options on the fly
        $one = CGI::ValidOp->new;
    is( $one->on_error_return_undef, 1 );
    is( $one->on_error_return_encoded, 0 );
    is( $one->on_error_return_tainted, 0 );

    # setting active option as 1 has no effect
        $one->on_error_return_undef( 1 );
    is( $one->on_error_return_undef, 1 );
    is( $one->on_error_return_encoded, 0 );
    is( $one->on_error_return_tainted, 0 );

    # setting undef option as 0
        $one->on_error_return_undef( 0 );
    is( $one->on_error_return_undef, 0 );
    is( $one->on_error_return_encoded, 0 );
    is( $one->on_error_return_tainted, 0 );

    # setting encoded option as 1 unsets undef
        $one->on_error_return_encoded( 1 );
    is( $one->on_error_return_undef, 0 );
    is( $one->on_error_return_encoded, 1 );
    is( $one->on_error_return_tainted, 0 );

    # setting encoded option as 0 works
        $one->on_error_return_encoded( 0 );
    is( $one->on_error_return_undef, 0 );
    is( $one->on_error_return_encoded, 0 );
    is( $one->on_error_return_tainted, 0 );

    # setting tainted as 1 unsets undef
        $one->on_error_return_tainted( 1 );
    is( $one->on_error_return_undef, 0 );
    is( $one->on_error_return_encoded, 0 );
    is( $one->on_error_return_tainted, 1 );

    # setting tainted as 0 works
        $one->on_error_return_tainted( 0 );
    is( $one->on_error_return_undef, 0 );
    is( $one->on_error_return_encoded, 0 );
    is( $one->on_error_return_tainted, 0 );

    # setting encoded as 1 unsets tainted
        $one->on_error_return_tainted( 1 );
        $one->on_error_return_encoded( 1 );
    is( $one->on_error_return_undef, 0 );
    is( $one->on_error_return_encoded, 1 );
    is( $one->on_error_return_tainted, 0 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# set_vars should accept any input
# an empty hashref should set the 'vars' property to undef
# a hashref should set 'vars' to that hashref
# anything else should have no effect
        delete $one->{ _vars };
    is( $one->{ _vars }, undef );
    is( $one->set_vars, undef );

    is( $one->set_vars( $vars ), undef );
    is_deeply( $one->{ _vars }, $vars );

    is( $one->set_vars( undef ), undef );
    is_deeply( $one->{ _vars }, $vars );

    is( $one->set_vars( 0 ), undef );
    is_deeply( $one->{ _vars }, $vars );

    is( $one->set_vars( 'foo' ), undef );
    is_deeply( $one->{ _vars }, $vars );

    is( $one->set_vars( [ 'foo' ] ), undef );
    is_deeply( $one->{ _vars }, $vars );

    is( $one->set_vars( {} ), undef );
    is( $one->{ _vars }, undef );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# setup for op_alias, get_op_name
        $one = CGI::ValidOp->new({
            one => {},
            two => {
                -alias => 'Second Op',
            },
            three => {
                -alias => [ 'Op The Third', 'third' ],
            },
        });

    is( $one->op_alias, undef );
    is( $one->op_alias( 'Second op' ), undef );
    is( $one->op_alias( 'Second Op' ), 'two' );
    is( $one->op_alias( 'Op The Third' ), 'three' );
    is( $one->op_alias( 'third' ), 'three' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get_op_name
    is( $one->get_op_name, 'default' );

    is( $one->set_vars({ op => 'foo' }), undef );
    is( $one->get_op_name, 'default' );

    is( $one->set_vars({ op => 'default' }), undef );
    is( $one->get_op_name, 'default' );

    is( $one->set_vars({ op => 'Default' }), undef );
    is( $one->get_op_name, 'default' );

    is( $one->set_vars({ op => 'One' }), undef );
    is( $one->get_op_name, 'one' );

    is( $one->set_vars({ op => 'THREE' }), undef );
    is( $one->get_op_name, 'three' );

    is( $one->set_vars({ op => 'Op The Third' }), undef );
    is( $one->get_op_name, 'three' );

    is( $one->set_vars({ op => "one\0One\0three" }), undef );
    is( $one->get_op_name, 'one' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# make_op
        $one = CGI::ValidOp->new;
    is( $one->param, undef );
    $one->ops({
        default => {
            item => [ 'item name', 'required' ],
        },
    });
    $one->make_op;
    is( $one->op, 'default' );
    is( $one->Op->name, 'default' );
    is( @{ $one->Op->Param }, 1 );
    is( $one->Op->Param( 'item' )->name, 'item' );
    is( $one->Op->Param( 'item' )->label, 'item name' );
    is_deeply( [ $one->Op->Param( 'item' )->checks ], [ 'required' ]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# setup
    ok( $one = CGI::ValidOp->new );
    $vars = {
        item        => 'Cat food',
        price       => '10.99',
        shipping    => 'FedEx',
    };
    is( $one->set_vars( $vars ), undef );
    is_deeply( $one->{ _vars }, $vars );
    is( $one->op, 'default' );
    ok( $one->Op->isa( 'CGI::ValidOp::Op' ));
    is( $one->Op->name, 'default' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# on_error_return
        $one = CGI::ValidOp->new;
    is( $one->Op->on_error_return, 'undef' );

        $one = CGI::ValidOp->new({
            -on_error_return_undef   => 1,
        });
    is( $one->Op->on_error_return, 'undef' );

        $one = CGI::ValidOp->new({
            -on_error_return_encoded   => 1,
        });
    is( $one->Op->on_error_return, 'encoded' );

        $one = CGI::ValidOp->new({
            -on_error_return_tainted   => 1,
        });
    is( $one->Op->on_error_return, 'tainted' );

        $one = CGI::ValidOp->new({
            -on_error_return_undef      => 1,
            -on_error_return_encoded    => 1,
            -on_error_return_tainted    => 1,
        });
    is( $one->Op->on_error_return, 'undef' );

        $one = CGI::ValidOp->new({
            -on_error_return_undef      => 0,
            -on_error_return_encoded    => 1,
            -on_error_return_tainted    => 1,
        });
    is( $one->Op->on_error_return, 'encoded' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# op
    is( $one->op, 'default' );
    is( $one->op( 'foo' ), 'foo' );
    is( $one->op, 'foo' );

        eval{ $one->op( 'echo rm / -rf' )};
    like( $@, qr/Invalid op name/ );

        eval{ $one->op( "trojan\nhorse" )};
    like( $@, qr/Invalid op name/ );

        eval{ $one->op( "trojanhorse" )};
    like( $@, qr/Invalid op name/ );

    is( $one->op( 'i_am_an_op' ), 'i_am_an_op' );
    is( $one->op, 'i_am_an_op' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# setup
    $vars = {
        item        => 'Cat food',
        price       => '10.99',
        shipping    => 'FedEx',
        op          => 'add',
    };
    is( $one->set_vars( $vars ), undef );
    is_deeply( $one->{ _vars }, $vars );
    is( $one->op, 'default' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Op object
    ok( $one->Op->isa( 'CGI::ValidOp::Op' ));
    is( $one->Op->name, 'default' );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# add_param
        eval{ $one->add_param( 'baz', \'baz' )};
    like( $@, qr/Incorrect param definition/ );

    ok( $param = $one->add_param( 'baz' ));
        ok( $param->isa( 'CGI::ValidOp::Param' ));
        is( $param->name, 'baz' );
        is( $param->label, undef );
        is_deeply( [ $param->checks ], [ qw/ text /]);
        ok( $param = $one->{ Op }{ _params }{ 'baz' });
        is( $param->name, 'baz' );
        ok( $param = $one->add_param(
                    foo => [ 'I Am Foo', 'required', 'text' ]
                ));
        ok( $param->isa( 'CGI::ValidOp::Param' ));
        is( $param->name, 'foo' );
        is( $param->label, 'I Am Foo' );
        is_deeply( [ $param->checks ], [ qw/ required text /]);
        ok( $param = $one->{ Op }{ _params }{ 'foo' });
        is( $param->name, 'foo' );

    ok( $param = $one->add_param( 'foo', [ 'I Am Foo', 'required', 'text' ]));
        ok( $param->isa( 'CGI::ValidOp::Param' ));
        is( $param->name, 'foo' );
        is( $param->label, 'I Am Foo' );
        is_deeply( [ $param->checks ], [ qw/ required text /]);
        ok( $param = $one->{ Op }{ _params }{ 'foo' });
        is( $param->name, 'foo' );

    ok( $param = $one->add_param( 'bar', [ 'We Are Bar', 'required', 'checkbox' ]));
        ok( $param->isa( 'CGI::ValidOp::Param' ));
        is( $param->name, 'bar' );
        is( $param->label, 'We Are Bar' );
        is_deeply( [ $param->checks ], [ qw/ required checkbox /]);
        ok( $param = $one->{ Op }{ _params }{ 'bar' });
        is( $param->name, 'bar' );

    ok( $param = $one->add_param( 'bar', [ 'We Are Bar' ]));
        ok( $param->isa( 'CGI::ValidOp::Param' ));
        is( $param->name, 'bar' );
        is( $param->label, 'We Are Bar' );
        is_deeply( [ $param->checks ], []);
        ok( $param = $one->{ Op }{ _params }{ 'bar' });
        is( $param->name, 'bar' );

    ok( $param = $one->add_param( 'object[property]', [ 'We Are Bar' ]));
        ok( $param->isa( 'CGI::ValidOp::Param' ));
        is( $param->name, 'object[property]' );
        is( $param->label, 'We Are Bar' );
        is_deeply( [ $param->checks ], []);
        ok( $param = $one->{ Op }{ _params }{ 'object[property]' });
        is( $param->name, 'object[property]' );

    ok ($param = $one->add_param( 'object', 
            { 
                address1 => ['Address Line 1', 'required'],
                address2 => ['Address Line 2'],
                key      => ['Key', 'required', 'text' ],
            }
        )
    );
    isa_ok($param, 'CGI::ValidOp::Object');
    is_deeply(
        $param,
        bless(
            {
                _validated => 0,
                '_param_template' => {
                    'address1' => bless(
                        {
                            'checks'           => ['required'],
                            'name'             => 'address1',
                            'tainted'          => undef,
                            'required'         => 1,
                            'label'            => 'Address Line 1',
                            'error_decoration' => [ undef, undef ],
                            'on_error_return'  => 'undef'
                        },
                        'CGI::ValidOp::Param'
                    ),
                    'address2' => bless(
                        {
                            'checks'           => [],
                            'name'             => 'address2',
                            'tainted'          => undef,
                            'required'         => 0,
                            'label'            => 'Address Line 2',
                            'error_decoration' => [ undef, undef ],
                            'on_error_return'  => 'undef'
                        },
                        'CGI::ValidOp::Param'
                    ),
                    'key' => bless(
                        {
                            'checks'           => [ 'required', 'text' ],
                            'name'             => 'key',
                            'tainted'          => undef,
                            'required'         => 1,
                            'label'            => 'Key',
                            'error_decoration' => [ undef,      undef ],
                            'on_error_return'  => 'undef'
                        },
                        'CGI::ValidOp::Param'
                    )
                },
                'name'             => 'object',
                'construct_object' => undef,
                '_objects'         => [],
                'min_objects'      => 0,
                'fields_required'  => [],
                'max_objects'      => 0,
                _errors => [],
            },
            'CGI::ValidOp::Object'
        )
    );


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# param
    ok( @params = $one->param );
    is_deeply([ sort @params ], [ qw/ bar baz foo item object[property] price shipping / ]);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# pass params into constructor
    $one = CGI::ValidOp->new({
        add => {
            -alias => [ 'Add Item', 'Add an item' ],
            item => [ 'item name', 'required' ],
            number => [ 'item number', 'required' ],
            shipping => [ 'shipping method', 'required' ],
        },
        remove => {
            -alias => 'Remove Item',
            number => [ 'item number', 'required' ],
            item => [ 'item name', 'required' ],
        },
        edit => {},
        view => {},
    });

    $vars = {
        item        => 'Cat food',
        price       => '10.99',
        shipping    => 'FedEx',
        op          => 'Add an item',
    };

    ok( defined( $one ));
    ok( $one->isa( 'CGI::ValidOp' ));
    is( $one->set_vars( $vars ), undef );
    is_deeply( $one->{ _vars }, $vars );

    is( $one->op, 'add' );
    ok( $one->Op->isa( 'CGI::ValidOp::Op' ));

    is( $one->Op->Param( 'item' )->label, 'item name' );
    is_deeply( [ $one->Op->Param( 'item' )->checks ], [ 'required' ]);
    is( $one->Op->Param( 'item' )->value, 'Cat food' );
    is( $one->param( 'item' ), 'Cat food' );

    is( $one->param( 'number' ), undef );
    is( $one->param( 'shipping' ), 'FedEx' );
    is( $one->param( 'price' ), 10.99 );

        $one->allow_unexpected( 0 );
    is( $one->op, 'add' );
    is( $one->param( 'item' ), 'Cat food' );
    is( $one->param( 'number' ), undef );
    is( $one->param( 'shipping' ), 'FedEx' );
    is( $one->param( 'price' ), undef );

    is_deeply( { $one->Vars }, {
        item        => 'Cat food',
        number      => undef,
        shipping    => 'FedEx',
    });
        %vars = $one->Vars;
    is_deeply( \%vars, {
        item        => 'Cat food',
        number      => undef,
        shipping    => 'FedEx',
    });
        $vars = $one->Vars;
    is_deeply( $vars, {
        item        => 'Cat food',
        number      => undef,
        shipping    => 'FedEx',
    });
    $one->allow_unexpected( 1 );
    is_deeply( { $one->Vars }, {
        item        => 'Cat food',
        number      => undef,
        shipping    => 'FedEx',
        price       => 10.99,
    });

    $one->return_only_received( 1 );
    is_deeply( { $one->Vars }, {
        item        => 'Cat food',
        shipping    => 'FedEx',
        price       => 10.99,
    });
    $one->return_only_received( 0 );
    is_deeply( { $one->Vars }, {
        item        => 'Cat food',
        number      => undef,
        shipping    => 'FedEx',
        price       => 10.99,
    });

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# pass params into constructor, shorthand notation
    $vars = {
        item        => 'Cat food',
        price       => '10.99',
        shipping    => 'FedEx',
        op          => 'add',
    };

    $one = undef;
    $one = CGI::ValidOp->new({
        -allow_unexpected => 0,
        add => {
            item => [ 'item name', 'required' ],
        },
    });

    ok( defined( $one ));
    ok( $one->isa( 'CGI::ValidOp' ));
    is( $one->set_vars( $vars ), undef );
    is_deeply( $one->{ _vars }, $vars );
    is( $one->op, 'add' );
    is( $one->param( 'item' ), 'Cat food' );
    is( $one->param( 'number' ), undef );
    is( $one->param( 'shipping' ), undef );
    is( $one->param( 'price' ), undef );

    is_deeply( { $one->Vars }, {
        item        => 'Cat food',
    });
    $one->allow_unexpected( 0 );
    is_deeply( { $one->Vars }, {
        item        => 'Cat food',
    });

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# undefined ops will not be set
    $vars = {
        item        => 'Cat food',
        price       => '10.99',
        shipping    => 'FedEx',
    };

    $one = undef;
    $one = CGI::ValidOp->new;
    is( $one->set_vars({ op => 'foo' }), undef );
    is( $one->op, 'default' );

SKIP: {
    skip "no Loompa", 15 unless eval { require Loompa; 1 };
    package Foo;
    our @ISA = qw(Loompa);

    sub methods { [qw(one two three)] }
    sub required_methods { [qw(one two)] }

    package main;

    $one = CGI::ValidOp->new(
        {
            step2_save => {
                -on_error => 'step2',
                foo => {
                    -construct_object => 'Foo',
                    one => [ 'One', 'required' ],
                    two => [ 'Two', 'required' ],
                    three => [ 'Three', 'required' ],
                }
            }
        }
    );

    isa_ok($one, 'CGI::ValidOp');

    $one->set_vars(
        {
            op => 'step2_save',
            'foo[0][one]'  => '1',
            'foo[0][two]'  => '2',
            'foo[0][three]' => '3',
        }
    );

    ok (my $objects = $one->objects('foo'));

    isa_ok($objects->[0], 'Foo');

    can_ok($objects->[0], 'one');
    can_ok($objects->[0], 'two');
    can_ok($objects->[0], 'three');

    is ($objects->[0]->one, 1);
    is ($objects->[0]->two, 2);
    is ($objects->[0]->three, 3);

    is_deeply($one->objects,
        {
            'foo' => [
                bless(
                    {
                        'one'   => 1,
                        'two'   => 2,
                        'three' => 3,
                    },
                    'Foo'
                )
            ]
        }
    );

    $one = CGI::ValidOp->new(
        {
            step2_save => {
                -on_error => 'step2',
                # addresses
                client_address => {
                    -min_objects   => 1,
                    -max_objects   => 3,
                    address1       => [ 'Address 0 Line 1',    'required' ],
                    city           => [ 'Address 0 City',      'required' ],
                    state          => [ 'Address 0 State',     'required' ],
                    postcode       => [ 'Address 0 Post Code', 'required' ],
                    not_required   => [ 'Address 0 Not Required' ],
                }
            }
        }
    );

    ok ($one->isa('CGI::ValidOp'));

    $one->set_vars(
        {
            op                            => 'step2_save',
            'client_address[0][address1]' => 'foo1',
            'client_address[0][city]'     => 'bar1',
            'client_address[0][state]'    => 'baz1',
            'client_address[0][postcode]' => 'quux1',
            'client_address[0][not_required]' => 'not_required!!!',
            'client_address[1][address1]' => 'foo2',
            'client_address[1][city]'     => 'bar2',
            'client_address[1][state]'    => 'baz2',
            'client_address[1][postcode]' => 'quux2',
            'client_address[2][address1]' => 'foo3',
            'client_address[2][city]'     => 'bar3',
            'client_address[2][state]'    => 'baz3',
            'client_address[2][postcode]' => 'quux3',
        }
    );

    is_deeply(
        $one->objects('client_address'),
        [
            {
                address1 => 'foo1',
                city     => 'bar1',
                state    => 'baz1',
                postcode => 'quux1',
                not_required => 'not_required!!!',
            },
            {
                address1 => 'foo2',
                city     => 'bar2',
                state    => 'baz2',
                postcode => 'quux2',
                not_required => undef,
            },
            {
                address1 => 'foo3',
                city     => 'bar3',
                state    => 'baz3',
                postcode => 'quux3',
                not_required => undef,
            }
        ]
    );

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# object_errors

    $one = CGI::ValidOp->new(
        {
            step2_save => {
                -on_error => 'step2',
                # addresses
                client_address => {
                    -min_objects   => 1,
                    -max_objects   => 3,
                    address1       => [ 'Address 0 Line 1',    'required' ],
                    city           => [ 'Address 0 City',      'required' ],
                    state          => [ 'Address 0 State',     'required' ],
                    postcode       => [ 'Address 0 Post Code', 'required' ],
                    not_required   => [ 'Address 0 Not Required' ],
                }
            }
        }
    );

    ok ($one->isa('CGI::ValidOp'));

    $one->set_vars(
        {
            op                            => 'step2_save',
        }
    );

    is_deeply($one->object_errors,
        {
            client_address => {
                global_errors => [ 'object violation: min_objects (1) has been violated' ],
                object_errors => [ ],
            }
        }
    );

    is_deeply($one->object_errors('client_address'),
        {
            global_errors => [ 'object violation: min_objects (1) has been violated' ],
            object_errors => [ ],
        }
    );
}
