package CGI::ValidOp;
use strict;
use warnings;

our $VERSION = '0.52';

use base qw/ CGI::ValidOp::Base /;
use CGI::ValidOp::Op;
use CGI::ValidOp::Param;
use CGI::ValidOp::Object;
use CGI;
use Carp qw/ croak confess /;
use Data::Dumper;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub PROPERTIES {
    {
        ops                 => undef,
        print_warnings      => 1,
        default_op          => 'default',
        runmode_name        => 'op',
        disable_uploads     => 1,
        post_max            => 25_000,
        -cgi_object         => new CGI,
        -error_decoration   => undef,
        -allow_unexpected   => 1,
        -on_error_return_undef   => 0,
        -on_error_return_encoded => 0,
        -on_error_return_tainted => 0,
        -return_only_received    => 0,
    }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# the argument parsing means:
# 1) if an argument is prefixed with a '-', take it as a config option
# 2) else take it as an op
sub init {
    my $self = shift;
    my( $args ) = @_;

    my( %ops, %config );
    if( ref $args eq 'HASH' ) {
        for( keys %$args ) {
            $_ =~ /^-(.*)$/
                ? $config{ $1 } = $args->{ $_ }
                : $ops{ $_ } = $args->{ $_ };
        }
        $config{ ops } = \%ops if keys %ops;
        $self->SUPER::init( \%config );
    }
    else {
        $self->SUPER::init;
    }

    # order of precedence for on_error arguments -- only one of the three
    # shold be active at once
    $self->on_error_return_undef( 1 )
        unless $self->on_error_return_encoded
        or $self->on_error_return_tainted;
    $self->on_error_return_tainted( 0 )
        if $self->on_error_return_undef
        or $self->on_error_return_encoded;
    $self->on_error_return_encoded( 0 )
        if $self->on_error_return_undef;

    $self->get_cgi_vars;
    $self;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub cgi_object {
    my $self = shift;
    my( $value ) = @_;

    return $self->{ cgi_object }
        unless defined $value;

    $self->{cgi_object} = $value;
}


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub reset_on_error {
    my $self = shift;

    # we want object construction not to account for precedence
    return if $self->{ in_init };
    $self->{ $_ } = 0 for qw/
        on_error_return_undef
        on_error_return_encoded
        on_error_return_tainted
    /;
    return;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub on_error_return_undef {
    my $self = shift;
    my( $value ) = @_;

    return $self->{ on_error_return_undef }
        unless defined $value;
    $self->reset_on_error if $value;
    $self->{ on_error_return_undef } = $value ? 1 : 0;
    return $self->{ on_error_return_undef };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub on_error_return_encoded {
    my $self = shift;
    my( $value ) = @_;

    return $self->{ on_error_return_encoded }
        unless defined $value;
    $self->reset_on_error if $value;
    $self->{ on_error_return_encoded } = $value ? 1 : 0;
    return $self->{ on_error_return_encoded };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub on_error_return_tainted {
    my $self = shift;
    my( $value ) = @_;

    return $self->{ on_error_return_tainted }
        unless defined $value;
    $self->reset_on_error if $value;
    $self->{ on_error_return_tainted } = $value ? 1 : 0;
    return $self->{ on_error_return_tainted };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# FIXME if you add a param and then change allow_unexpected, that param will go away
sub allow_unexpected {
    my $self = shift;

    return $self->{ allow_unexpected } unless @_;
    $self->{ allow_unexpected } = shift;
    $self->set_vars; # FIXME this is a hack; related to the above FIXME
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub return_only_received {
    my $self = shift;

    return $self->{ return_only_received } unless @_;
    $self->{ return_only_received } = shift;
    $self->{ return_only_received };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_cgi_vars {
    my $self = shift;

    $CGI::POST_MAX = $self->post_max;
    $CGI::DISABLE_UPLOADS = $self->disable_uploads;
    $self->set_vars({ $self->cgi_object->Vars });
# next two lines may be necessary for file uploads, but break existing
# multi-value param functionality
#     my $cgi = CGI->new;
#     $self->set_vars({ map { $_ => $cgi->param( $_ )} $cgi->param });
    return; # so we can't get untainted user input
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# an empty hashref {} resets vars
# TODO should accept arrayrefs as values
sub set_vars {
    my $self = shift;
    my( $vars ) = @_;

    return if $self->{ in_init }; # if we're still being initialized
    if( ref $vars eq 'HASH' ) {
        if( keys %$vars == 0 ) {
            delete $self->{ _vars };
        }
        else {
            $self->{ _vars } = $vars;
        }
    }
    $self->make_op;
    $self->make_params;
    return; # so we can't get untainted user input
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# make the current Op object and add the defined params
sub make_op {
    my $self = shift;

    delete $self->{ Op };
    my $options = $self->ops;
    return unless my $params = $options->{ $self->op };
    for( keys %$params ) {
        next if /^-.*/;
        $self->add_param( $_, $params->{ $_ });
    }
    return;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# makes parameters using incoming vars
sub make_params {
    my $self = shift;

    my $vars = $self->{ _vars };
    # create params if we need to and are allowed
    if( $self->allow_unexpected ) {
        for( keys %$vars ) {
            next if $_ eq $self->runmode_name; # don't make one for runmode
            if (/\[/) {
                $self->append_to_object($_);
            } else {
                $self->add_param( $_ ) unless $self->Op->Param( $_ );
            }
        }
    }
    # set all tainted values
    $_->tainted( $vars->{ $_->name }) for $self->Op->Param;
    return;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# appends a parameter to an object - takes a parameter name as an argument.
sub append_to_object {
    my $self = shift;
    my ($param_name) = @_;

    $self->{_objects} ||= { };

    my ($name) = $param_name =~ /^([^\[]+)/;

    return unless ($self->{_objects}{$name});

    $self->{_objects}{$name}->set_var({ name => $param_name, value => $self->{_vars}{$param_name} });
    return $name;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# accepts:
# ( $name )
# ( \%options )
# ( $name, \%options )
# ( $name, [ $label, @checks ])
sub add_param {
    my $self = shift;

    my $param;
    if( @_ == 1 ) { # either a hashref or a single name
        $param = $self->Op->add_param( @_ );
    }
    else { # either a name and hashref or a name and arrayref
        my( $name, $vars ) = @_;
        my( $label, $checks );
        if ( ref $vars eq 'ARRAY' ) {
            $label = $vars->[0];
            # slice and take a reference to that, copying 1..-1
            $checks = [@{$vars}[1..$#$vars]];

            $param = $self->Op->add_param({
                    name    => $name,
                    label   => $label,
                    checks  => $checks,
            });
        }
        elsif( ref $vars eq 'HASH' ) {
            $self->{_objects} ||= { };
            $param = $self->{_objects}{$name} = CGI::ValidOp::Object->new($name, $vars);
        }
        else {
            croak qr/Incorrect param definition./;
        }
    }

    if ($param->isa('CGI::ValidOp::Param')) {
        $param->tainted( $self->{ _vars }{ $param->name })
            if defined $self->{ _vars };
    }

    $param;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# capitalized for CGI compatibility
sub Vars {
    my $self = shift;
    my %params;
    my @vars = keys %{ $self->{ _vars }}
        if $self->{ _vars };
    for( $self->Op->Param ) {
        my $name = $_->name;
        next
            if $self->return_only_received and not grep /^$name$/ => @vars;
        $params{ $name } = $_->value;
    }
    return unless keys %params;
    wantarray
        ? %params
        : \%params;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# fetches an object collection
sub objects {
    my $self = shift;
    my ($object_name) = @_;

    $self->{_objects} ||= { };

    if (defined($object_name)) {
        return $self->{_objects}{$object_name} ? $self->{_objects}{$object_name}->objects : []; 
    }

    my $hash = { };
    foreach my $key (keys %{$self->{_objects}}) {
        $hash->{$key} = $self->{_objects}{$key}->objects || [];
    }

    return $hash;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# fetches all the errors for object collections
sub object_errors {
    my $self = shift;
    my ($object_name) = @_;

    if (defined($object_name)) {
        # return the errors just for the requested object
        return $self->{_objects}{$object_name} ? $self->{_objects}{$object_name}->object_errors : {};
    }

    my $hash = { };
    # return all the object errors in a hash keyed by the object name
    foreach my $key (keys %{$self->{_objects}}) {
        $hash->{$key} = $self->{_objects}{$key}->object_errors;
    }

    return $hash;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub op {
    my $self = shift;
    $self->Op( @_ )->name;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# given a scalar, returns the op for which that scalar is an alias
# accounts both for alias being a string and an arrayref
# alias is case-sensitive
sub op_alias {
    my $self = shift;
    my( $alias ) = @_;

    return unless $alias and $self->ops;
    for( keys %{ $self->ops }) {
        next unless $self->ops->{ $_ }{ -alias };
        return $_ if $self->ops->{ $_ }{ -alias } eq $alias;
        return $_ if ref $self->ops->{ $_ }{ -alias } eq 'ARRAY'
            and grep /^$alias$/, @{ $self->ops->{ $_ }{ -alias }};
    }
    return;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_op_name {
    my $self = shift;

    my $op_name;
    if( $self->{ _vars } and $self->{ _vars }{ $self->runmode_name }) {
        $op_name = $self->{ _vars }{ $self->runmode_name };
        ( $op_name ) = split /\0/, $op_name;  # if we get more than one, use the first
        $op_name = $self->op_alias( $op_name )
            if $self->op_alias( $op_name );
        $op_name = $self->default_op
            unless $self->ops
            and grep /^$op_name$/i => keys %{ $self->ops };
    }
    else {
        $op_name = $self->default_op;
    }
    lc $op_name;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# FIXME if you add a param and then change op, that param will go away
sub Op {
    my $self = shift;
    my( $op_name ) = @_;

    croak 'Invalid op name; only a word is allowed.'
        if $op_name and $op_name !~ /^\w+$/;
    unless( $op_name ) {
        return $self->{ Op } if $self->{ Op };
        $op_name = $self->get_op_name;
    }

#     print STDERR Dumper[
#         $self->{ on_error_return_undef },
#         $self->{ on_error_return_encoded },
#         $self->{ on_error_return_tainted },
#         ];

    my $on_error_return = $self->on_error_return_encoded    ? 'encoded'
        : $self->on_error_return_tainted                    ? 'tainted'
        :                                                     'undef';
    $self->{ Op } = CGI::ValidOp::Op->new({
        name => $op_name,
        error_decoration    => [ $self->error_decoration ],
        on_error_return => $on_error_return,
    });
    $self->{ Op };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub param {
    my $self = shift;
    my( $param_name, $checks ) = @_;

    # return all param names if we're not asked for one
    unless( $param_name ) {
        my @params = map $_->name, $self->Op->Param;
        return @params if @params;
        return;
    }
    my $param = $self->Op->Param( $param_name, $checks );
    if( !$param and $checks ) { # if we have checks create the param
        $param = $self->add_param($param_name, [ $param_name, @$checks ]);
    }
    return $param->value if $param;
    return;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub errors {
    my $self = shift;

    return unless $self->Op->Param;
    my @errors;
    for( $self->Op->Param ) {
        $_->validate; # slightly nasty to have to do this
        next unless my $errors = $_->errors;
        push @errors => @$errors;
    }
    @errors = sort @errors;
    return \@errors if @errors;
    return;
}

1;

__END__

=head1 NAME 

CGI::ValidOp - Simple validation of CGI parameters and runmodes.

=head1 SYNOPSIS

    # given the following CGI parameters:
    # op=add_item; name=William Blake; ssn=345-21-6789; crackme=$ENV{EVIL_MEAT};

    use CGI::ValidOp;

    my $cgi = CGI::ValidOp->new({
        add_item => {   # using full syntax
            name => {
                label => 'Name',
                checks => [ 'required', 'text::words' ],
            },
            ssn => {
                label => 'Social Security number',
                checks => [ 'demographics::us_ssn' ],
            },
        },
        remove_item => {   # using shortcut syntax
            ssn => [ 'Social Security number', 'required', 'demographics::us_ssn' ],
            confirm => [ 'Confirmation checkbox', 'required', 'checkbox::boolean' ],
        },
        cgi_object => new CGI($fh),
    });

    my $name    = $cgi->param( 'name' );    # eq "William Blake"
    my $ssn     = $cgi->param( 'ssn' );     # eq "345-21-6789"
    my $crackme = $cgi->param( 'crackme' ); # is undef; it was removed by the check
    my $confirm = $cgi->param( 'confirm' ); # is undef; it doesn't exist

    my $op      = $cgi->op;                 # eq "add_item"
    my @errors  = $cgi->errors;             # eq ( 'Parameter "crackme" contained invalid data.' )
    my %vars    = $cgi->Vars;               # eq (
                                            #   name    => "William Blake",
                                            #   ssn     => "345-21-6789",
                                            #   crackme => undef,
                                            # )

=head1 DESCRIPTION

CGI::ValidOp is a CGI parameter validator that also helps you manage runmodes.
Its aims are similar to Perl's: make the easy jobs easy and the complex jobs
possible.  CGI parameter validation is boring, and precisely for that reason
it's easy to get wrong or ignore.  CGI::ValidOp takes as much of the repetition
as possible out of this job, replacing it with a simple interface.

=head2 Unique features

There are many CGI parameter validation modules on CPAN; why on earth would I
write another one, and why should you use it?  Before writing ValidOp I made a
list of requirements and checked all available modules against it, hoping that
even if nothing matched there'd be a project which I could subclass or
contribute to.  I didn't find anything.  Here's what I think ValidOp does
right:

=over 4

=item Simple API.

=item Minimal usage is useful.

=item Easy to add new checks.

=item Relation of parameters to run-modes/operations.

In addition to validating parameters, CGI::ValidOp has a number of methods for
dealing with runmodes (henceforth referred to as 'ops').  In fact, the 'op'
concept is key to ValidOp's advanced usage:  parameters are defined as children
of ops.  A "display_item" op may need only a numeric id, while an "add_item" op
will take several parameters.  All these can be defined once in a single
location.

=item Validation defaults settable on many levels to minimize repetition.

You can change the validation defaults for the entire app, all parameters for
one runmode, or per-parameter.

=item CGI integration and compatibility.

Parameters can be accessed just like with CGI.pm: L<param> for individual
parameters and L<Vars> for all of them.

=item Per-parameter error messages.

While error message must be available globally, having per-parameter error
messages is an important usability improvement.  When returning a long form
page to a user, it's good to show them error messages where they're most
useful.

=item OO and test-driven

ValidOp is test-driven, object-oriented Perl.

=item Extensive and public test suite.

If you're going to trust someone else's code for security purposes it's nice to
have proof that it works.  CGI::ValidOp has an extensive test suite that checks
every part of its operation, particularly the validation routines.  I keep the
current version running at L<http://sonofhans.net> validop with a full test
page.  If you can produce unexpected output, file a bug report.

=back

=head1 METHODS

=head2 new( \%options )

Creates and returns a new CGI::ValidOp object.  The initializing hashref is
optional.  If supplied, it may contain two types of values:  configuration
options and runmode definitions.  Configuration options must be prepended with
a dash (C<->); runmodes must not be.

Setting 'cgi_object' will allow you to override the CGI object that would be
provided by default, if say, you needed to use this module under mod_perl.

    my $cgi = CGI::ValidOp->new({
        -allow_unexpected => 0,     # configuration option
        add => {},                  # op, or runmode definition
    );

See L<Configuration> and L<Runmode Management> for more details.

=head2 param( $name, \@checks )

C<param> behaves similarly to the CGI.pm method of the same name, returning the value for the named parameter.  The differences from CGI.pm's C<param> are:

=over 4

=item * The return value will be validated against all defined checks.

=item * The return value will be untainted if the checks require it.
    
=item * Any necessary error messages will be created.

=back

The C<\@checks> arrayref is optional.  If supplied, it replaces all previously defined checks for the parameter and overrides all defaults.  An empty arrayref (C<[]>) will give you the parameter as input by the user, unchecked; it will still be tainted.

=head2 Vars

C<Vars> behaves similarly to the CGI.pm method of the same name, returning the entire parameter list.  In scalar context it returns a hash reference; in list context it returns a hash.  The differences from CGI.pm's C<Vars> method are:

=over 4

=item * Multivalue parameters are returned as an arrayref, rather than a null-byte packed string.

=item * The L<runmnode_name> parameter ("op" by default) is not returned; see L<op> for more details.

=item * Unexpected parameters are not returned (see L<allow_unexpected>).

=item * Parameters that failed one or more checks are returned as C<undef>.

=item * In scalar context the hashref is not tied, and changes to it do not affect the parameter list.

=back

=head2 op

Returns the current runmode name.  In the normal case, this is the CGI parameter given for "op" (but see L<runmode_name>).  Several factors affect the return value:

=over 4

=item * If a runmode parameter is given but it doesn't match the name of any defined runmode, L<runmode aliases> are searched.

=item * If no L<runmode alias> matches, the value of L<default_op> is returned.

=back

Note that while ValidOp doesn't require you to use its runmode management features, it still uses them internally.  Even in the of no defined parameters or runmodes, ValidOp uses "default" as its runmode and all parameters are subsidiary to it.  This is invisible to the user.

=head2 errors

Returns an arrayref of all error messages for the current parameter list and parameter definitions.  Returns C<undef> if there are no errors.

=head2 Op( $op_name )

Returns the CGI::ValidOp::Op object for the current runmode, or the runmode given.  See L<Op Objects> for more details, or the documentation for L<CGI::ValidOp::Op> for all the details.

=head2 set_vars( \%params )

Resets the parameter list to the given hash reference.

=head1 CONFIGURATION

ValidOp has a number of configurable options which alter its behavior.  These options can be given in the constructor, via accessor methods, or both:

    my $cgi = CGI::ValidOp->new({
        -allow_unexpected   => 0,
        -default_op         => 'home',
    });
    
    $cgi->default_op( 'view' );  # overrides 'home' above

=head2 allow_unexpected

Default: B<1>.  Accepts: B<1 or 0>.  Controls whether ValidOp accepts incoming CGI parameters which you have not defined.  If true, all incoming parameters are accepted and validated.  If false, parameters you have not defined are ignored.

=head2 return_only_received

Default: B<0>.  Accepts: B<1 or 0>.  If true, will not return any data for a parameter not received in the query string.  ValidOp's default behavior is to return an C<undef> value in this situation.

=head2 default_op

Default: B<'default'>.  Accepts: B<word>.  The default runmode name.  If no runmode parameter is given, or if the runmode given does not exist, the runmode specified here will be used.  See L<Runmode Management>.

=head2 disable_uploads

Default: B<1>.  Accepts: B<positive integer>.  Passed through to CGI.pm when getting parameters.  See L<CGI.pm>.

=head2 error_decoration

Default: B<undef>.  Accepts: B<array>.  Text with which to surround parameter labels in error messages.  If given a single scalar, it is inserted both before and after the label.  If given an arrayref, the first value is inserted before and the second is inserted after.

Given an error message of C<$label is required.> and a label of "Confirmation checkbox," ValidOp would normally output C<Confirmation checkbox is required.>.  Here's how various values affect the error message:

    $cgi->error_decoration( '"' );
    # "Confirmation checkbox" is required.

    $cgi->error_decoration( '* ', undef );
    # * Confirmation checkbox is required.

    $cgi->error_decoration( undef, ':' );
    # Confirmation checkbox: is required.

    $cgi->error_decoration( '<strong>', '</strong>' );
    # <strong>Confirmation checkbox</strong> is required.

=head2 post_max

Default: B<25,000>.  Accepts: B<positive integer>.  Passed through to CGI.pm when getting parameters.  See L<CGI.pm>.

=head2 runmode_name

Default: B<'op'>.  Accepts: B<word>.  The name of the runmode.  ValidOp treates the runmode parameter differently from other parameters; see L<Runmode Management> for more details.

=head2 on_error_return...

These routines control what values are returned by C<Vars()> and C<param()>.  They are mutually exclusive, and have the following order of precedence:

=over 4

=item * on_error_return_undef

=item * on_error_return_encoded

=item * on_error_return_tainted

=back

In other words, if both C<on_error_return_undef> and C<on_error_return_tainted> are given as true, C<on_error_return_undef> will apply.

=head3 on_error_return_undef

The default behavior.  Values which fail validation are ignored, and returned as C<undef>.

=head3 on_error_return_encoded

Values which fail validation are returned as input, but first encoded with L<HTML::Entities>'s C<encode()> method.

=head3 on_error_return_tainted

Values which fail validation are returned unchanged.  Don't do this.

=head1 Defining Checks

=over 4

=item ValidOp checks

When constructing a CGI::ValidOp object, you may pass a C<-checks> option.  The default checks are: C<['text']>.

=item Op checks

When defining an op within the CGI::ValidOp constructor, you may pass a C<-checks> option.

=item Parameter checks

When defining a param within the op definition, you may pass a C<-checks> option.

=item On-the-fly checks

When calling the C<param> method, you may pass an array reference as the second parameter.  This arrayref is passed straight through to the parameter's C<checks> accessor.

=back


=head1 COPYRIGHT

Copyright (c) 2003-2005 Randall Hansen. All rights reserved.

This program is free software; you may redistribute it and/or modify it under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=head1 AUTHOR

Randall Hansen <legless@cpan.org>

=cut

# $Id: ValidOp.pm 387 2005-04-21 23:45:27Z soh $
