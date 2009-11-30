#===============================================================================
#
#         FILE:  CGI/ValidOp/Object.pm
#
#  DESCRIPTION:  Object-level parameters for CGI::ValidOp 
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Erik Hollensbe (), <erikh@opensourcery.com>
#      COMPANY:  OpenSourcery, LLC 
#      VERSION:  1.0
#      CREATED:  01/13/2008 03:48:07 PST
#     REVISION:  $Id$
#===============================================================================

package CGI::ValidOp::Object;

use strict;
use warnings;

use Carp qw(croak confess);
use base qw(CGI::ValidOp::Base); 
use CGI::ValidOp::Param;
use Data::Dumper;

sub PROPERTIES {
    {
        name              => undef,
        -min_objects      => 0,
        -max_objects      => 0,
        -fields_required  => [],
        -construct_object => undef,
    }
}

# constructor. requires a name (text) and an args definition (hash of array) 
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 
sub init {
    my $self = shift;
    my ($name, $args) = (@_);

    croak ("No name") unless defined $name;
    croak ("No arguments") unless $args;
    croak ("Args must be a hash") unless ref $args eq 'HASH';

    $self->SUPER::init($args);
    $self->set_name( { name => $name } );

    $self->{_param_template} = { };

    foreach my $arg (keys %$args) {
        if ($arg =~ /^-/) {
            $arg =~ s/^-//;
            $self->$arg($args->{"-$arg"});
        } else {
            my ($label, @checks) = @{$args->{$arg}};
            $self->{_param_template}{$arg} = CGI::ValidOp::Param->new(
                {
                    name   => $arg,
                    label  => $label,
                    checks => \@checks,
                }
            );
        }
    }

    $self->{_validated} = 0;
    $self->{_errors}    = [];
    $self->{_objects}   = [];

    return $self;
}

# sets a var on an object. requires a hash with a name and value which would
# supposedly come from the CGI object.
#
# A lot of validation happens here. It probably shouldn't, but it's much
# cleaner this way.
#
# Builds C::V::Param objects out from this data and fills an array of hash with
# it in _objects.
#
# While this could be used to set one thing at a time, set_vars() is probably
# better for that, and conforms to the rest of the external API.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 
sub set_var {
    my $self = shift;
    my ($args) = @_;

    croak ("args must be hash") 
        unless (defined $args and ref $args eq 'HASH');
    croak ("missing parameters in args hash")
        unless (defined $args->{name} and exists $args->{value});

    # XXX: this regex parses foo[0][key] into "foo", 0, "key". Don't touch it.
    $args->{name} =~ /^([^\[]+?)\[(\d+?)\]\[([^\]]+?)\]$/
        || $args->{name} =~ /^object--(\w+)--(\d+)--(\w+)/;
    my ($param_name, $index, $key) = ($1, $2, $3);

    unless (defined($param_name) && defined($index) && defined($key)) {
        ($param_name, $index, $key) = map { defined($_) ? $_ : "Unknown" } ($param_name, $index, $key);
        croak ("Invalid parameter ($args->{name}, $param_name, $index, $key) in ".__PACKAGE__."::set_var(): not enough data")
    }
    croak ("Name does not match this object")
        unless ($param_name eq $self->name);

    unless (defined($self->{_param_template}{$key})) {
        $self->{_param_template}{$key} = new CGI::ValidOp::Param(
            {
                name => $key,
                label => $key,
                checks => []
            }
        );
    }

#    croak ("Parameter ($key) for object (".$self->name.") does not match object template")
#        unless (defined($self->{_param_template}{$key}));

    $self->{_objects}[$index] ||= { };

    my $param = $self->{_param_template}{$key};

    $param = $param->clone;

    $param->name($args->{name});
    $param->tainted($args->{value});

    $self->{_objects}[$index]{$key} = $param;

    return $param;
}

# sets multiple vars on an object. key => value association. See set_var() for
# more information.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 
sub set_vars {
    my $self = shift;
    my ($args) = @_;

    croak ("args must be hash") 
        unless (defined $args and ref $args eq 'HASH');

    while (my ($name, $value) = each %$args) {
        $self->set_var({ name => $name, value => $value });
    }

    return 1;
}

# Normalizes objects so that they have all parameters and constraints.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 
sub normalize_objects {
    my $self = shift;

    @{$self->{_objects}} = grep defined($_), @{$self->{_objects}};

    foreach my $object (@{$self->{_objects}}) {
        foreach my $template_name (keys %{$self->{_param_template}}) {
            if (!exists($object->{$template_name})) {
                $object->{$template_name} = $self->{_param_template}{$template_name}->clone;
            }
        }

        foreach my $param_name (keys %$object) {
            # XXX: this is a bit dirty, but I didn't want to modify Param's API.
            #      yet another reason not to call validate() twice.
            if (
                scalar grep $param_name, @{$self->fields_required} and
                !scalar grep 'required', @{$object->{$param_name}{checks}}
            ) 
            {
                $object->{$param_name}->required(1);
                push @{$object->{$param_name}{checks}}, 'required';
            }
        }
    }
    
    return 1;
}

# Validates all the params on the object.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 
sub validate {
    my $self = shift;

    return if $self->{_validated};

    # this should croak because someone flubbed an ops definition.
    croak ("min_objects is greater than max_objects")
        if ($self->min_objects gt $self->max_objects and $self->max_objects gt 0);


    $self->normalize_objects;

    foreach my $object (@{$self->{_objects}}) {
        foreach my $param_name (keys %$object) {
            # XXX: this is a bit of a hack. Since we want encoded entities and
            # this is tightly coupled in Param, we override param's {value}
            # value with the value returned. I'm not sure if this is such a hot
            # idea, but ATM can't think of a better one.
            #
            # e.g., this could lead to double-encoding if validate is called
            # twice.
            $object->{$param_name}{value} = $object->{$param_name}->value;
        }
    }

    $self->global_errors("object violation: min_objects (".$self->min_objects.") has been violated")
        if ($self->min_objects and $self->min_objects gt @{$self->{_objects}});

    $self->global_errors("object violation: max_objects (".$self->max_objects.") has been violated")
        if ($self->max_objects and $self->max_objects lt @{$self->{_objects}});

    $self->{_validated} = 1;

    return;
}

#
# global_errors is a private interface that is an acccessor (with append only)
# to set errors that are global to this class of objects.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 
sub global_errors {
    my $self = shift;

    push @{$self->{_errors}}, $_ for (@_);

    return $self->{_errors};
}

# object_errors is another external interface. it provides the errors for our
# parameters.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 
sub object_errors {
    my $self = shift;

    $self->validate;

    my $objects = [ ];

    foreach my $object (@{$self->{_objects}}) {
        push @$objects, { map { $_ => ($object->{$_}->errors || [ ]) } keys %$object };
    }

    return { global_errors => $self->global_errors, object_errors => $objects };
}

# objects is the external interface to the end-user. it's passed through validop
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 
sub objects {
    my $self = shift;

    $self->validate; 
    
    my $objects = [ ];

    foreach my $object (@{$self->{_objects}}) {
        if ($self->construct_object) {
            my $new_obj = $self->construct_object->new(
                {
                    map {
                        (
                            $_ => (
                                defined( $object->{$_}->value )
                                ? $object->{$_}->value
                                : undef
                            )
                          )
                      } keys %$object
                }
            );

            push @$objects, $new_obj;
        } else {
            push @$objects, {
                map {
                    $_ => (
                        defined( $object->{$_}->value )
                        ? $object->{$_}->value
                        : undef )
                  } keys %$object
            };
        }
    }

    return $objects;
}

#
# Accessors
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 
sub max_objects {
    my $self = shift;

    $self->{max_objects} = shift 
        if (defined $_[0]);

    return $self->{max_objects};
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 
sub min_objects {
    my $self = shift;
    $self->{min_objects} = shift
        if (defined $_[0]);
    return $self->{min_objects};
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 
sub fields_required {
    my $self = shift;
    $self->{fields_required} = shift
        if (defined $_[0]);
    return $self->{fields_required};
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 
sub construct_object {
    my $self = shift;
    $self->{construct_object} = shift if (@_);
    return $self->{construct_object};
}

'validop';

__END__

=head1 NAME 

CGI::ValidOp::Object - CGI<->object bridge for CGI::ValidOp

=head1 DESCRIPTION

Implements a CGI<->object bridge.  Used internally by CGI::ValidOp; please see the L<CGI::ValidOp> documentation.

=head1 AUTHORS

Erik Hollensbe <erik@hollensbe.org>

Chad Granum <exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (c) 2003-2006 Randall Hansen. All rights reserved.

This program is free software; you may redistribute it and/or modify it under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut

