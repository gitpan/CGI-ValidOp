package CGI::ValidOp::Param;
use strict;
use warnings;

use base qw/ CGI::ValidOp::Base /;
use Carp;
use Data::Dumper;
use HTML::Entities;
use Storable qw(dclone);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub PROPERTIES {
    {
        label       => undef,
        checks      => [ qw/ text/ ],
        required    => 0,
        -error_decoration    => undef,
        tainted    => undef,
        on_error_return => 'undef',
    }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub init {
    my $self = shift;
    my( $args ) = @_;

    # XXX set_name should raise the error, maybe
    $self->set_name( $args )
        or croak 'Name required in CGI::ValidOp::Param::init().';
    $self->SUPER::init( $args );
    $self->required( 1 ) # FIXME hack, not a ::Check; can it be?
        if grep /^required$/ => $self->checks;
    $self;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# treats the empty string '' as undef
sub tainted {
    my $self = shift;
    my( $tainted ) = @_;

    return $self->{ tainted } unless @_;
    delete $self->{ value };
    undef $tainted if defined $tainted and $tainted eq '';
    $self->{ tainted } = $tainted;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# returns validated param
# take on_error_return into account
sub value {
    my $self = shift;
    croak 'Cannot directly set parameter value with CGI::ValidOp::Param::value().'
        if @_;
    $self->validate;

    return encode_entities( $self->tainted )
        if $self->errors
        and $self->on_error_return eq 'encoded';

    return $self->tainted
        if $self->errors
        and $self->on_error_return eq 'tainted';

    return if $self->errors; # 'undef' is the default
    return $self->{ value }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# validates $self->{ tainted } against all checks defined for it
sub validate {
    my $self = shift;

    # empty arrayref means "no checks"
    return unless $self->checks and $self->checks > 0;
    $self->check_required; # this is a little magic; read its comments
    for my $check_name( $self->checks ) {
        next if $check_name eq 'required'; #FIXME nasty special case

        delete $self->{ value }; # we'll set the value later if it's ok
        if( $self->tainted and $self->tainted =~ /\0/ ) { # if multi-value
            for( split /\0/, $self->tainted ) {
                my $value = $self->check( $_, $check_name );
                push @{ $self->{ value }} => $value if defined $value;
            }
        }
        else {
            my $value = $self->check( $self->tainted, $check_name );
            $self->{ value } = $value
                if defined $value;
        }
    }
    return;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# checks a single value against one check
# returns a good value, or adds an error and returns undef
sub check {
    my $self = shift;
    my( $tainted, $check_name ) = @_;

    my $check = $self->load_check( $check_name );
    my( $value, $errmsg ) = $check->check( $tainted );
    return $value unless $errmsg;

    $self->add_error( $check_name, $errmsg );
    return;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# check_string can be any of (e.g.):
# foo, foo::bar, foo(2,4), foo::bar(2,4)
sub load_check {
    my $self = shift;
    my( $check_string ) = @_;

    croak "Must pass a scalar check name to CGI::ValidOp::Param::load_check()"
        if !$check_string or ref $check_string;

    # strip out trailing parens and capture anything inside them as a list
    ( my $check_name = $check_string ) =~ s/(.*)\((.*)\)/$1/;
    my @params = $2
        ? split /,/ => $2
        : undef;

    my( $package, $method ) = split /::/, $check_name;
    $package = "CGI::ValidOp::Check::$package";
    eval "require $package";
    $@ and croak "Failed to require $package in CGI::ValidOp::Param::check(): ". $@;

    $package->new( $method, @params );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# FIXME this should go into ::Check
#     | $param-> | defined |      |    RETURNS      |     | add    |
#  if | required | tainted | then | undef | tainted | and | error? |
#     |----------|---------|      |-------|---------|     |--------|
#     |   X      |         |      |   X   |         |     |   X    |
#     |          |         |      |   X   |         |     |        |
#     |   X      |   X     |      |       |   X     |     |        |
#     |          |   X     |      |       |   X     |     |        |
sub check_required {
    my $self = shift;

    if( defined $self->tainted ) {
        $self->{ value } = $self->tainted;
        return $self->{ value };
    }
    $self->add_error( 'required', '$label is required.' )
        if $self->required;
    return;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# returns error if it was added, undef otherwise
sub add_error {
    my $self = shift;
    my( $check_name, $error ) = @_;

    return unless $check_name and $error;
    $check_name =~ s/(.*)\((.*)\)/$1/; # removes trailing parens
    $self->{ errors }{ $check_name } = $error;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# copy constructor.
sub clone {
    return dclone(shift);
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# errors are structured like:
# $param = {
#     ...
#     errors => {
#         $check_name    => $error_message,
#         }
sub errors {
    my $self = shift;

    return unless $self->{ errors };
    my @errors;
    my( $b, $e ) = $self->error_decoration;
    for( sort values %{ $self->{ errors }}) {
        my $label = $self->label || $self->name;
        { # don't care if these exist
            no warnings qw/ uninitialized /;
            $label = $b . $label . $e;
        }
        $_ =~ s/\$label/$label/g;
        push @errors => $_ 
    }
    return \@errors if @errors;
    return;
}

1;

__END__

=head1 NAME 

CGI::ValidOp::Param - Parameter object for CGI::ValidOp

=head1 DESCRIPTION

Implements a CGI parameter object.  Used internally by CGI::ValidOp; please see the L<CGI::ValidOp> documentation.

=head1 AUTHOR

Randall Hansen <legless@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2003-2006 Randall Hansen. All rights reserved.

This program is free software; you may redistribute it and/or modify it under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut

