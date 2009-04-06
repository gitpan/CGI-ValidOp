package CGI::ValidOp::Op;
use strict;
use warnings;

use base qw/ CGI::ValidOp::Base /;
use CGI::ValidOp::Param;
use Data::Dumper;
use Carp;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub PROPERTIES {
    {
        name        => undef,
        alias       => undef,
        error_op    => undef,
        -error_decoration    => undef,
        on_error_return => 'undef',
    }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# the argument parsing means:
# 1) if an argument is an existing method, take it as a config option
# 2) else take it as a param
# FIXME should have a params key instead; this is too magical
sub init {
    my $self = shift;
    my( $args ) = @_;

    $self->SUPER::init; # FIXME nasty hack to get around methods not being
                        # defined 'cause we return if no input
    $self->set_name( $args )
        or croak 'Name required in CGI::ValidOp::Op::init.';

    return $self unless ref $args eq 'HASH';
    my( %config, %params );
    for( keys %$args ) {
        $self->can( $_ )
            ? $config{ $_ } = $args->{ $_ }
            : $params{ $_ } = $args->{ $_ };
    }
    $self->SUPER::init( \%config );
    for( keys %params ) {
        $params{ $_ }->{ name } = $_;
        $self->add_param( $params{ $_ });
    }
    $self;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# takes a hashref specifying a parameter
sub add_param {
    my $self = shift;
    my( $vars ) = @_;

    if( defined $vars and ref $vars eq '' ) {
        $vars = { name => $vars };
    }

    $vars->{ on_error_return } = $self->on_error_return;
    croak 'no param created'
        unless my $param = CGI::ValidOp::Param->new( $vars );
    $param->error_decoration( $self->error_decoration );
    $self->{ _params }{ $param->name } = $param;
    $param;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# returns all Param objects unless asked for one
# also sets new checks for a param if they're given
sub Param {
    my $self = shift;
    my( $param_name, $checks ) = @_;

    if( $param_name ) {
        my $param = $self->{ _params }{ $param_name };
        $param->checks( $checks ) if $param and $checks;
        return $param;
    }

    my @params;
    push @params => $self->{ _params }{ $_ }
        for sort keys %{ $self->{ _params }};
    return unless @params;
    wantarray ? @params : \@params;
}

1;

__END__

=head1 NAME 

CGI::ValidOp::Op - Op object for CGI::ValidOp

=head1 DESCRIPTION

Implements an Op object, which contains parameters.  Used internally by CGI::ValidOp; please see the L<CGI::ValidOp> documentation.

=head1 AUTHOR

Randall Hansen <legless@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2003-2005 Randall Hansen. All rights reserved.

This program is free software; you may redistribute it and/or modify it under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut

# $Id: Op.pm 388 2005-04-22 16:11:04Z soh $
