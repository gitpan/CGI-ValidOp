package CGI::ValidOp::Check;
use strict;
use warnings;

use base qw/ CGI::ValidOp::Base /;
use Carp;

my @ALLOWED_TYPES = ( qw/ regexp code /); # types of reference we allow for checks

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub PROPERTIES {
    {
        validator   => undef,
        errmsg      => undef,
        name        => undef,
        params      => undef,
        allow_tainted => 0,
    }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# params are optional parameters passed in, e.g. "check_name(3,4)"
sub init {
    my $self = shift;
    my( $check_name, @params ) = @_;

    $check_name ||= 'default';
    my $pkg = ref $self;
    croak qq/No such check ("$check_name") in package "$pkg"./
        unless $self->can( $check_name );
    my( $validator, $errmsg ) = $self->$check_name;
    my $validator_type = ref $validator;
    croak join ' ', "Disallowed reference type for validator. You used $validator_type; valid types are:", @ALLOWED_TYPES
        unless $validator_type and grep /^$validator_type$/i, @ALLOWED_TYPES;

    $self->SUPER::init({
        validator   => $validator,
        errmsg      => $errmsg,
        name        => $check_name,
        params      => \@params,
    });
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# called by a check to indicate success: "pass( $value )"
sub pass {
    my $self = shift;
    my( $value ) = @_;
    ( $value, undef );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# called by a check to indicate failure "fail( $errmsg )"
sub fail {
    my $self = shift;
    my( $errmsg ) = @_;
    ( undef, $errmsg );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# check to see what type of validator we have and call the appropriate sub
sub check {
    my $self = shift;
    my( $tainted ) = @_;

    # trim whitespace
    if (defined $tainted) {
        $tainted =~ s/^\s+//;
        $tainted =~ s/\s+$//;
    }

    my $check_sub = 'check_'. lc ref $self->validator;
    $self->$check_sub( $tainted, $self->validator );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# this method makes the decision about whether the test passed or failed
# if it gets undef it returns it with no error message
# if the regex then returns undef it returns an error
sub check_regexp {
    my $self = shift;
    my( $tainted, $validator ) = @_;
    return( undef, undef ) unless defined $tainted;
    $tainted =~ /($validator)/;
    return $1 unless wantarray;
    defined $1
        ? ( $1, undef )
        : ( undef, $self->errmsg );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# this method expects the coderef to call either pass or fail
sub check_code {
    my $self = shift;
    my( $tainted, $validator ) = @_;
    my( $value, $errmsg ) = &$validator( $tainted, $self->params );
    croak 'Validator returned a tainted value'
        if $self->is_tainted( $value )
        and ! $self->allow_tainted;
    wantarray
        ? ( $value, $errmsg )
        : $value;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub default {
    (
        sub {
            croak 'You must override CGI::ValidOp::Check::check() with your own code.';
        },
        'Parameter $label contained invalid data.',
    )
}

1;

__END__

=head1 NAME 

CGI::ValidOp::Check - base class for CGI::ValidOp checks

=head1 SYNOPSIS

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
                $self->pass( $1 ) if $value =~ /^($color)$/i;
                $self->fail( "\$label must be the color: $color." );
            },
        )
    }

=head1 DESCRIPTION

CGI::ValidOp::Check contains all the code to validate data from CGI::ValidOp::Param objects, and enables simple creation your own checks.  Unless you're creating or testing your own checks, you should use and read the documentation for L<CGI::ValidOp> instead.

=head2 How checks are used

Each check module must contain at least one check, and can contain as many as you care to create.  This document walks through the creation of one module containing mutliple checks.  Some of ValidOp's default checks are organized by types of data (e.g. 'text', 'number'), but there's nothing to say you must also do this.  You may find it convenient to package all the checks for one project in a single module.

Your check can be used in three ways.  The first is with a simple scalar corresponding to the module name:

    $validop->param( 'price', [ 'mychecks' ]);

The second is by calling a particular check within the package:

    $validop->param( 'price', [ 'mychecks::robot' ]);

The third is by passing parameters to either the module or a check:

    $validop->param( 'price', [ 'mychecks(3,6)' ]);
    $validop->param( 'price', [ 'mychecks::robot("Robbie")' ]);

=head1 METHODS

Unless you're creating or testing your own checks, this reference is not likely to help you.  You can use ValidOp's public API without knowing a thing about ValidOp::Check's internals.

=head2 params()

The 'params' method returns a list passed to the check by the user:

    $validop->param( 'price', [ 'mychecks(3,6)' ]);

These parameters are captured by splitting the contents of the parenthesis on commas.  The resulting list is made available with the 'params' method.

=head2 validator( $regexp_or_coderef )

Sets or returns the validator.

=head2 errmsg( $error_message )

Sets or returns the error message.  When CGI::ValidOp::Param parses these error messages, it replaces every isntance of C<$label> with the parameter's 'label' property or, if that does not exist, with the parameter's 'name'.

=head2 check( $tainted_value )

check() runs its calling object's validator against the incoming tainted value.  It returns the resulting value on success, or C<undef> on failure.  check() itself does very little work; it finds what type of validator it has (regex and coderef are the only types currently allowed) and farms out the work to the appropriate method.

=head2 check_regexp( $tainted, $validator )

check_regexp() captures the result of matching $tainted against $validator, using code similar to this:

    $tainted =~ /($validator)/;
    return $1;

Note that the return value is untainted.  Also note that the code does B<not> anchor the regular expression with ^ (at the beginning) or $ (at the end).  In other words, if you used this quoted regex as a check:

    qr/demo/

any string containing "demo" (e.g. "demographics," "modemophobia") would pass.  This may or may not be what you intend.

=head2 check_code( $tainted, $validator )

check_code() passes $tainted to the anonymous subroutine referenced by $validator and returns the result.  The two most notable differences from regex checks are that the value of L<params()|"params()"> is passed into the validator subroutine and that the entire thing croaks if the return value is tainted.

ValidOp's default behavior is to die like a dog if your coderef returns a tainted value.  This safe default can be changed by returning a third list item from your check subroutine, a hashref of additional properties:

    sub should_allow_tainted {(
        sub { $_[ 0 ] },
        'This should be an error message',
        { allow_tainted => 1, }
    )}

=head2 is_tainted

=head1 CREATING A CHECK MODULE

=head2 Starting a check module

For the moment, your check module must be in the CGI::ValidOp::Check namespace; future versions will allow more flexibility.  The module must be in Perl's search path.

    package CGI::ValidOp::Check::demo;

You must subclass CGI::ValidOp::Check for your module.  It contains methods that the rest of the code uses to perform the validation.

    use base qw/ CGI::ValidOp::Check /;

=head2 Creating checks

Each check is completely defined by a single subroutine.  If you define only one check in your module, it should be called 'default'.  Using only the module name as a check, the 'default' subroutine is called.  There's nothing to stop you calling your single check something else, but it does mean less intuitive use.

Checks return one to three scalar values.  The first value is the check itself, and is required.  The second value is an optional error message.  The third is an optional list of additional properties, defined for the check and made available as methods.

    sub check_name {
        ( $check, $errmsg, \%options )
    }


=head2 Types of checks

=head3 Quoted regular expression

The simplest checks are quoted regular expressions.  These are perfect for relatively static data.  This one checks that the incoming value is "demo" and sets a custom error message.  Any instance of '$label' in an error message is substituted with the parameter's 'label' property, if you define one, or the parameter's 'name' property (which is required and thus guaranteed to exist).

    sub default {
        (
            qr/^demo$/,                  # validator
            '$label must equal "demo."', # error message
        )
    }

Parameters are validated against Regex checks with the L<check_regexp> method.

You cannot pass parameters to a regex check (more to the point you can, but they'll be ignored).

=head3 Subroutine reference

These checks can be much more powerful and flexible, but require a little extra work.

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

You'll note that the check only returns one item, an anonymous subroutine.  This coderef sets the check's error message with the 'errmsg' method, allowing it to pass incoming parameters into the error message.  (You could supply an error message here as the second array element, but it would be overridden.)

Parameters are validated against coderef checks with the L<check_code> method:

Right now the only additional property available ValidOp checks is 'allow_tainted.'  ValidOp's stock 'length' check uses this, reasoning that just knowing the length of an incoming value isn't reason enough to trust it.

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

=head1 AUTHOR

Randall Hansen <legless@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2003-2005 Randall Hansen. All rights reserved.

This program is free software; you may redistribute it and/or modify it under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut

# $Id: Check.pm 388 2005-04-22 16:11:04Z soh $

    /^checkbox$/ and return qr/^on$/i;
    /^email$/    and return qr/[\w\.@]+/;
    /^encode_html$/     and return sub {
        require HTML::Entities;
        my( $value ) = @_;
        return( HTML::Entities::encode( $value ), 1 );
    };
    /^checkbox_10$/ and return sub {
        $_ = shift;
        /^on$/i and return 1;
        return 0;
    };
#     file name, from http://www.perlmonks.org/index.pl?node_id=36309
#     /^(
#         (?:\w+\/)*      # Directory components?
#         \w+             # Start of filename
#         (?:\.\w+)?      # Extension?
#     )$/x
