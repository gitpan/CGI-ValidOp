use constant TESTS => 107;
#===============================================================================
#
#         FILE:  05-object.t
#
#  DESCRIPTION:  Object-style parameters: tests.
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Erik Hollensbe (), <erikh@opensourcery.com>
#      COMPANY:  OpenSourcery, LLC 
#      VERSION:  1.0
#      CREATED:  01/13/2008 03:45:27 PST
#     REVISION:  $id$
#===============================================================================

use strict;
use warnings;

use Test::More tests => TESTS; # see line 1
use Test::Exception;
use Data::Dumper;

our $CLASS = "CGI::ValidOp::Object";
our ($one, $two); # $one is the same object throughout this suite
use_ok($CLASS);

# constructor tests
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 

throws_ok { $one = $CLASS->new } qr/^No name/i; 
throws_ok { $one = $CLASS->new('foo') } qr/^No arguments/;
throws_ok { $one = $CLASS->new('foo', 1) } qr/^args must be a hash/i;

ok ($one = $CLASS->new('foo', { address1 => [ 'Address Line 1', 'required' ] }) );
is_deeply($one, 
    {
        min_objects => 0,
        max_objects => 0,
        fields_required => [],
        construct_object => undef,
        name => 'foo',
        _param_template => {
            'address1' => bless(
                {
                    'checks'           => [ 'required' ],
                    'name'             => 'address1',
                    'tainted'          => undef,
                    'required'         => 1,
                    'label'            => 'Address Line 1',
                    'error_decoration' => [ undef, undef ],
                    'on_error_return'  => 'undef'
                },
                'CGI::ValidOp::Param'
            )
         },
        _objects => [],
        _validated => 0,
        _errors => [],
    }
);

# set_var
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 
throws_ok { $one->set_var } qr/^args must be hash/i;
throws_ok { $one->set_var({}) } qr/^missing parameters/i;
throws_ok { $one->set_var( { name => "one" } ) } qr/^missing parameters/i;
throws_ok { $one->set_var( { value => "one" } ) } qr/^missing parameters/i;
throws_ok { $one->set_var( { name => "one", value => "two" } )         } qr/^Invalid parameter/i;
throws_ok { $one->set_var( { name => "one[", value => "two" } )        } qr/^Invalid parameter/i;
throws_ok { $one->set_var( { name => "one[]", value => "two" } )       } qr/^Invalid parameter/i;
throws_ok { $one->set_var( { name => "one[foo]", value => "two" } )    } qr/^Invalid parameter/i;
throws_ok { $one->set_var( { name => "one[0]", value => "two" } )      } qr/^Invalid parameter/i;
throws_ok { $one->set_var( { name => "one[0][]", value => "two" } )    } qr/^Invalid parameter/i;
throws_ok { $one->set_var( { name => "one[][]", value => "two" } )     } qr/^Invalid parameter/i;
throws_ok { $one->set_var( { name => "one[[0]][]]", value => "two" } ) } qr/^Invalid parameter/i;

throws_ok { $one->set_var( { name => "bar[0][address1]", value => "bar" }) } qr/^Name does not match/i;
#throws_ok { $one->set_var( { name => "foo[0][bar]", value => "foo" }) } qr/^Parameter \(bar\) for object \(foo\) does not match/i;

ok ( $one->set_var( { name => "foo[0][address1]", value => "bar" } ));

is_deeply($one,
    {
        _errors => [],
        name => 'foo',
        min_objects => 0,
        max_objects => 0,
        fields_required => [],
        construct_object => undef,
        _param_template => {
            'address1' => bless(
                {
                    'checks'           => [ 'required' ],
                    'name'             => 'address1',
                    'tainted'          => undef,
                    'required'         => 1,
                    'label'            => 'Address Line 1',
                    'error_decoration' => [ undef, undef ],
                    'on_error_return'  => 'undef'
                },
                'CGI::ValidOp::Param'
            )
         },
        _objects => [
            {
                'address1' => {
                    'checks'           => ['required'],
                    'name'             => 'foo[0][address1]',
                    'tainted'          => 'bar',
                    'required'         => 1,
                    'label'            => 'Address Line 1',
                    'error_decoration' => [ undef, undef ],
                    'on_error_return'  => 'undef',
                  },
            }
        ],
        _validated => 0,
    }
);

# set_vars
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 
throws_ok { $one->set_vars } qr/args must be hash/i;

ok ($one = $CLASS->new(
        'foo',
        {
            address1 => [ 'Address Line 1', 'required' ],
            address2 => [ 'Address Line 2' ],
            key      => [ 'Key' ],
        }
    )
);

ok ($one->set_vars(
        {
            "foo[0][address1]" => "123 Anywhere",
            "foo[0][address2]" => "234 Anywhere",
            "foo[0][key]"      => "value1",
            "foo[1][address1]" => "456 Anywhere",
            "foo[1][address2]" => "678 Anywhere",
            "foo[1][key]"      => "value2",
        }
    )
);

is_deeply(
    $one->{_objects},
    [
          {
            'address1' => bless( {
                                   'checks' => [
                                                 'required'
                                               ],
                                   'name' => 'foo[0][address1]',
                                   'tainted' => '123 Anywhere',
                                   'required' => 1,
                                   'label' => 'Address Line 1',
                                   'error_decoration' => [
                                                           undef,
                                                           undef
                                                         ],
                                   'on_error_return' => 'undef'
                                 }, 'CGI::ValidOp::Param' ),
            'key' => bless( {
                              'checks' => [],
                              'name' => 'foo[0][key]',
                              'tainted' => 'value1',
                              'required' => 0,
                              'label' => 'Key',
                              'error_decoration' => [
                                                      undef,
                                                      undef
                                                    ],
                              'on_error_return' => 'undef'
                            }, 'CGI::ValidOp::Param' ),
            'address2' => bless( {
                                   'checks' => [],
                                   'name' => 'foo[0][address2]',
                                   'tainted' => '234 Anywhere',
                                   'required' => 0,
                                   'label' => 'Address Line 2',
                                   'error_decoration' => [
                                                           undef,
                                                           undef
                                                         ],
                                   'on_error_return' => 'undef'
                                 }, 'CGI::ValidOp::Param' )
          },
          {
            'address1' => bless( {
                                   'checks' => [
                                                 'required'
                                               ],
                                   'name' => 'foo[1][address1]',
                                   'tainted' => '456 Anywhere',
                                   'required' => 1,
                                   'label' => 'Address Line 1',
                                   'error_decoration' => [
                                                           undef,
                                                           undef
                                                         ],
                                   'on_error_return' => 'undef'
                                 }, 'CGI::ValidOp::Param' ),
            'address2' => bless( {
                                   'checks' => [],
                                   'name' => 'foo[1][address2]',
                                   'tainted' => '678 Anywhere',
                                   'required' => 0,
                                   'label' => 'Address Line 2',
                                   'error_decoration' => [
                                                           undef,
                                                           undef
                                                         ],
                                   'on_error_return' => 'undef'
                                 }, 'CGI::ValidOp::Param' ),
            'key' => bless( {
                              'checks' => [],
                              'name' => 'foo[1][key]',
                              'tainted' => 'value2',
                              'required' => 0,
                              'label' => 'Key',
                              'error_decoration' => [
                                                      undef,
                                                      undef
                                                    ],
                              'on_error_return' => 'undef'
                            }, 'CGI::ValidOp::Param' )
          }
    ]
);

# (min|max)_objects
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 

is ($one->PROPERTIES->{-max_objects}, 0);
is ($one->PROPERTIES->{-min_objects}, 0);

ok ($one->can('max_objects'));
ok ($one->can('min_objects'));

ok (!$one->max_objects);
ok (!$one->min_objects);

ok ($one->max_objects(2));
ok ($one->min_objects(1));

is ($one->max_objects, 2);
is ($one->min_objects, 1);

# HACK so tests do what we expect without setting up a new object
$one->{_validated} = 0;

lives_ok { $one->validate };
ok ($one->max_objects(1));

# HACK so tests do what we expect without setting up a new object
$one->{_validated} = 0;

lives_ok { $one->validate };

is_deeply($one->global_errors,
    ['object violation: max_objects (1) has been violated' ]
);

# HACK so tests do what we expect without setting up a new object
$one->{_validated} = 0;
ok ($one->max_objects(2));
ok ($one->min_objects(3));
$one->{_errors} = [];
throws_ok { $one->validate } qr/min_objects is greater than max_objects/;

# HACK so tests do what we expect without setting up a new object
$one->{_validated} = 0;
ok ($one->min_objects(1));
# it's ok if max_objects is set to 0 and min is set to something else.
ok (!$one->max_objects(0));
lives_ok { $one->validate };

# HACK so tests do what we expect without setting up a new object
$one->{_validated} = 0;
$one->{_errors} = [];
ok ($one->min_objects(4));
lives_ok { $one->validate };

is_deeply($one->global_errors,
    [ 
        'object violation: min_objects (4) has been violated',
    ]
);

$one->{_errors} = [];

# normalize_objects 
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 

ok ($two = $CLASS->new('foo', { foo => [ 'foo', 'required' ], address1 => [ 'Address Line 1', 'required' ] }));
ok ($two->set_vars({ "foo[0][foo]" => 'bar' }));
ok ($two->normalize_objects);

is_deeply(
    $two->{_objects},
    [
        {
            'address1' => bless(
                {
                    'checks'           => [ 'required' ],
                    'required'         => '1',
                    'name'             => 'address1',
                    'label'            => 'Address Line 1',
                    'tainted'          => undef,
                    'on_error_return'  => 'undef',
                    'error_decoration' => [ undef, undef ]
                },
                'CGI::ValidOp::Param'
            ),
            'foo' => bless(
                {
                    'checks'           => [ 'required' ],
                    'required'         => '1',
                    'name'             => 'foo[0][foo]',
                    'label'            => 'foo',
                    'tainted'          => 'bar',
                    'on_error_return'  => 'undef',
                    'error_decoration' => [ undef, undef ]
                },
                'CGI::ValidOp::Param'
            )
        }
    ]
);

# validate 
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 

ok ($one->max_objects(2));
ok ($one->min_objects(1));

lives_ok { $one->validate };

is_deeply(
    $one->{_objects},
    [
          {
            'address1' => bless( {
                                   'checks' => [
                                                 'required'
                                               ],
                                   'name' => 'foo[0][address1]',
                                   'value' => '123 Anywhere',
                                   'tainted' => '123 Anywhere',
                                   'required' => 1,
                                   'label' => 'Address Line 1',
                                   'error_decoration' => [
                                                           undef,
                                                           undef
                                                         ],
                                   'on_error_return' => 'undef'
                                 }, 'CGI::ValidOp::Param' ),
            'key' => bless( {
                              'checks' => [],
                              'name' => 'foo[0][key]',
                              'value' => 'value1',
                              'tainted' => 'value1',
                              'required' => 0,
                              'label' => 'Key',
                              'error_decoration' => [
                                                      undef,
                                                      undef
                                                    ],
                              'on_error_return' => 'undef'
                            }, 'CGI::ValidOp::Param' ),
            'address2' => bless( {
                                   'checks' => [],
                                   'name' => 'foo[0][address2]',
                                   'value' => '234 Anywhere',
                                   'tainted' => '234 Anywhere',
                                   'required' => 0,
                                   'label' => 'Address Line 2',
                                   'error_decoration' => [
                                                           undef,
                                                           undef
                                                         ],
                                   'on_error_return' => 'undef'
                                 }, 'CGI::ValidOp::Param' )
          },
          {
            'address1' => bless( {
                                   'checks' => [
                                                 'required'
                                               ],
                                   'name' => 'foo[1][address1]',
                                   'value' => '456 Anywhere',
                                   'tainted' => '456 Anywhere',
                                   'required' => 1,
                                   'label' => 'Address Line 1',
                                   'error_decoration' => [
                                                           undef,
                                                           undef
                                                         ],
                                   'on_error_return' => 'undef'
                                 }, 'CGI::ValidOp::Param' ),
            'address2' => bless( {
                                   'checks' => [],
                                   'name' => 'foo[1][address2]',
                                   'value' => '678 Anywhere',
                                   'tainted' => '678 Anywhere',
                                   'required' => 0,
                                   'label' => 'Address Line 2',
                                   'error_decoration' => [
                                                           undef,
                                                           undef
                                                         ],
                                   'on_error_return' => 'undef'
                                 }, 'CGI::ValidOp::Param' ),
            'key' => bless( {
                              'checks' => [],
                              'name' => 'foo[1][key]',
                              'value' => 'value2',
                              'tainted' => 'value2',
                              'required' => 0,
                              'label' => 'Key',
                              'error_decoration' => [
                                                      undef,
                                                      undef
                                                    ],
                              'on_error_return' => 'undef'
                            }, 'CGI::ValidOp::Param' )
          }
    ]
);

# test that required fields get errors properly

ok ( 
    $two = $CLASS->new('foo', 
        { 
            foo      => [ "Foo" ],
            address1 => [ "Address Line 1", 'required' ],
        }
    )
);

ok ($two->set_vars( { "foo[0][foo]" => 'bar' } ));
lives_ok { $two->validate };
is_deeply( 
    $two->{_objects},
    [
        {
            'address1' => bless(
                {
                    'checks' => [ 'required' ],
                    'errors' => { 'required' => 'Address Line 1 is required.' },
                    'value'  => undef,
                    'name'   => 'address1',
                    'tainted'          => undef,
                    'required'         => '1',
                    'label'            => 'Address Line 1',
                    'error_decoration' => [ undef, undef ],
                    'on_error_return'  => 'undef'
                },
                'CGI::ValidOp::Param'
            ),
            'foo' => bless(
                {
                    'checks'           => [],
                    'required'         => '0',
                    'value'            => 'bar',
                    'name'             => 'foo[0][foo]',
                    'label'            => 'Foo',
                    'tainted'          => 'bar',
                    'on_error_return'  => 'undef',
                    'error_decoration' => [ undef, undef ]
                },
                'CGI::ValidOp::Param'
            )
        }
    ]
);


# test that validate does not run twice.
$two->{_validated} = 0;
lives_ok { $two->validate };
ok($two->{_validated});
my $tmp = $two->{_objects};

# this should NOT change after validation
ok ($two->set_vars( { "foo[0][foo]" => 'quux' } ));
is_deeply($tmp, $two->{_objects});


# objects() (part one, hashes)
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 
is_deeply(
    $one->objects,
    [
        {
            'address1' => '123 Anywhere',
            'address2' => '234 Anywhere',
            'key'      => 'value1'
        },
        {
            'address1' => '456 Anywhere',
            'key'      => 'value2',
            'address2' => '678 Anywhere'
        }
    ]
);

# fields_required() 
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 

ok ($one->can('fields_required'));
ok ($one->fields_required);
is_deeply ($one->fields_required, []);

ok ($one->fields_required([qw(key)]));
ok ($one->set_vars( { "foo[0][key]" => undef } ));

# HACK so tests do what we expect without setting up a new object
$one->{_validated} = 0;

# undef here is ok. what won't be ok is in the errors hash.
is_deeply(
    $one->objects,
    [
        {
            'address1' => '123 Anywhere',
            'address2' => '234 Anywhere',
            'key'      => undef,
        },
        {
            'address1' => '456 Anywhere',
            'key'      => 'value2',
            'address2' => '678 Anywhere'
        }
    ]
);

# notice [0][foo]'s error message existing. good!
is_deeply(
    $one->{_objects},
    [
        {
            'address1' => bless(
                {
                    'checks'           => [ 'required' ],
                    'required'         => '1',
                    'value'            => '123 Anywhere',
                    'name'             => 'foo[0][address1]',
                    'label'            => 'Address Line 1',
                    'tainted'          => '123 Anywhere',
                    'on_error_return'  => 'undef',
                    'error_decoration' => [ undef, undef ]
                },
                'CGI::ValidOp::Param'
            ),
            'key' => bless(
                {
                    'checks'           => [ 'required' ],
                    'errors'           => { 'required' => 'Key is required.' },
                    'value'            => undef,
                    'name'             => 'foo[0][key]',
                    'tainted'          => undef,
                    'required'         => 1,
                    'label'            => 'Key',
                    'error_decoration' => [ undef, undef ],
                    'on_error_return'  => 'undef'
                },
                'CGI::ValidOp::Param'
            ),
            'address2' => bless(
                {
                    'checks'           => [ 'required' ],
                    'required'         => 1,
                    'value'            => '234 Anywhere',
                    'name'             => 'foo[0][address2]',
                    'label'            => 'Address Line 2',
                    'tainted'          => '234 Anywhere',
                    'on_error_return'  => 'undef',
                    'error_decoration' => [ undef, undef ]
                },
                'CGI::ValidOp::Param'
            )
        },
        {
            'address1' => bless(
                {
                    'checks'           => [ 'required' ],
                    'required'         => '1',
                    'value'            => '456 Anywhere',
                    'name'             => 'foo[1][address1]',
                    'label'            => 'Address Line 1',
                    'tainted'          => '456 Anywhere',
                    'on_error_return'  => 'undef',
                    'error_decoration' => [ undef, undef ]
                },
                'CGI::ValidOp::Param'
            ),
            'address2' => bless(
                {
                    'checks'           => [ 'required' ],
                    'required'         => 1,
                    'value'            => '678 Anywhere',
                    'name'             => 'foo[1][address2]',
                    'label'            => 'Address Line 2',
                    'tainted'          => '678 Anywhere',
                    'on_error_return'  => 'undef',
                    'error_decoration' => [ undef, undef ]
                },
                'CGI::ValidOp::Param'
            ),
            'key' => bless(
                {
                    'checks'           => [ 'required' ],
                    'required'         => 1,
                    'value'            => 'value2',
                    'name'             => 'foo[1][key]',
                    'label'            => 'Key',
                    'tainted'          => 'value2',
                    'on_error_return'  => 'undef',
                    'error_decoration' => [ undef, undef ]
                },
                'CGI::ValidOp::Param'
            )
        }
    ]
);

# object_errors()
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 
is_deeply(
    $one->object_errors,
    {
        global_errors => [],
        object_errors => [
            {
                'address1' => [],
                'address2' => [],
                'key'      => ['Key is required.']
            },
            {
                'address1' => [],
                'key'      => [],
                'address2' => [],
            }

        ]
    }
);

# objects() (part two, real objects)
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 


SKIP: {
    skip "need Loompa", 34 unless eval { require Loompa; 1 };
    package Foo;
    use strict;
    use warnings;
    our @ISA = 'Loompa';

    sub methods { [qw/address1 address2 key/] }

    package main;

    ok ($one = $CLASS->new(
            'foo',
            {
                -construct_object => 'Foo',
                address1 => [ 'Address Line 1', 'required' ],
                address2 => [ 'Address Line 2' ],
                key      => [ 'Key' ],
            }
        )
    );

    ok ($one->set_vars(
            {
                "foo[0][address1]" => "123 Anywhere",
                "foo[0][address2]" => "234 Anywhere",
                "foo[0][key]"      => "value1",
                "foo[1][address1]" => "456 Anywhere",
                "foo[1][address2]" => "678 Anywhere",
                "foo[1][key]"      => "value2",
            }
        )
    );

    foreach my $object (@{$one->objects}) {
        isa_ok($object, 'Foo');
    }

    is ($one->objects->[0]->key,      'value1');
    is ($one->objects->[0]->address1, '123 Anywhere');
    is ($one->objects->[0]->address2, '234 Anywhere');
    is ($one->objects->[1]->key,      'value2');
    is ($one->objects->[1]->address1, '456 Anywhere');
    is ($one->objects->[1]->address2, '678 Anywhere');


    # objects() (part three, object pruning)
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 
    ok ($one = $CLASS->new(
            'foo',
            {
                -construct_object => 'Foo',
                address1 => [ 'Address Line 1', 'required' ],
                address2 => [ 'Address Line 2' ],
                key      => [ 'Key' ],
            }
        )
    );

    # XXX the big difference here is that we're filling 0 and 2, not 0 and 1.
    ok ($one->set_vars(
            {
                "foo[0][address1]" => "123 Anywhere",
                "foo[0][address2]" => "234 Anywhere",
                "foo[0][key]"      => "value1",
                "foo[2][address1]" => "456 Anywhere",
                "foo[2][address2]" => "678 Anywhere",
                "foo[2][key]"      => "value2",
            }
        )
    );

    foreach my $object (@{$one->objects}) {
        isa_ok($object, 'Foo');
    }

    is ($one->objects->[0]->key,      'value1');
    is ($one->objects->[0]->address1, '123 Anywhere');
    is ($one->objects->[0]->address2, '234 Anywhere');
    is ($one->objects->[1]->key,      'value2');
    is ($one->objects->[1]->address1, '456 Anywhere');
    is ($one->objects->[1]->address2, '678 Anywhere');

    ok ($one = $CLASS->new(
            'foo',
            {
                -construct_object => 'Foo',
                address1 => [ 'Address Line 1', 'required' ],
                address2 => [ 'Address Line 2' ],
                key      => [ 'Key' ],
            }
        )
    );

    # XXX the big difference here is that we're filling 1 and 2, not 0 and 1.
    ok ($one->set_vars(
            {
                "foo[1][address1]" => "123 Anywhere",
                "foo[1][address2]" => "234 Anywhere",
                "foo[1][key]"      => "value1",
                "foo[2][address1]" => "456 Anywhere",
                "foo[2][address2]" => "678 Anywhere",
                "foo[2][key]"      => "value2",
            }
        )
    );

    foreach my $object (@{$one->objects}) {
        isa_ok($object, 'Foo');
    }

    is ($one->objects->[0]->key,      'value1');
    is ($one->objects->[0]->address1, '123 Anywhere');
    is ($one->objects->[0]->address2, '234 Anywhere');
    is ($one->objects->[1]->key,      'value2');
    is ($one->objects->[1]->address1, '456 Anywhere');
    is ($one->objects->[1]->address2, '678 Anywhere');

    ok ($one = $CLASS->new(
            'foo',
            {
                bar => [ 'Checkbox', 'checkbox::boolean' ],
            }
        )
    );

    # XXX the big difference here is that we're filling 1 and 2, not 0 and 1.
    ok ($one->set_vars(
            {
                "foo[0][bar]" => "on",
                "foo[1][bar]" => undef,
            }
        )
    );

    is ($one->objects->[0]->{bar}, 1);
    is ($one->objects->[1]->{bar}, 0);
}
