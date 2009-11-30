package CGI::ValidOp::Base;
use strict;
use warnings;

use Data::Dumper;
use Carp qw/ croak confess /;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;
    my $self = bless {}, $class;
    $self->init( @_ );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# if the calling object has a PROPERTIES method, this
# 1) creates accessor methods for each key returned,
# 2) and calls the method with the value
# if the key is prefixed with a '-', only (2) is performed
sub init {
    my $self = shift;
    my( $args ) = @_;

    return $self unless $self->can( 'PROPERTIES' );
    $self->{ in_init } = 1; # tells other methods that we're not baked yet
    my $config = $self->PROPERTIES;
    for( keys %$config ) {
        $self->method( $_ )
            unless $_ =~ /^-/;
        ( my $prop = $_ ) =~ s/^-//;
        $self->$prop( $config->{ $_ }); # set default
        $self->$prop( $args->{ $prop })    # set incoming
            if ref $args eq 'HASH' and defined $args->{ $prop };
    }
    delete $self->{ in_init };
    $self;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# creates a method to store the property
sub method {
    my $self = shift;
    my( $property ) = @_;

    my $pkg = caller;
    return if $pkg->can( $property );

    no strict 'refs';
    *{ "${ pkg }::$property" } =
        sub {
            my $self = shift;
            my( $value ) = @_;

            if( @_ ) {
                undef $value if defined $value and $value eq '';
                $self->{ $property } = $value;
            }
            return unless defined wantarray;
            return @{ $self->{ $property }}
                if wantarray and ref $self->{ $property } eq 'ARRAY';
            return %{ $self->{ $property }}
                if wantarray and ref $self->{ $property } eq 'HASH';
            $self->{ $property };
        };
    return;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# accessor for object name; will accept a scalar word
# or a hashref containing a 'name' key
sub set_name {
    my $self = shift;
    my( $args ) = @_;

    my %e = (
        api     => q/ERROR:  set_name() API./,
        preq    => q/Parameter names are required for all values./,
        regex   => q/Parameter names must contain only letters, numbers, underscores, and square brackets./,
    );

    my $name;
    if( ref $args ) {
        croak $e{ api } unless ref $args eq 'HASH' and keys %$args;
        croak $e{ api } unless grep /^name$/ => keys %$args;
        croak $e{ preq } unless $args->{ name };
        $name = $args->{ name };
    }
    $name ||= $args;

    croak $e{ preq }
        unless $name;
    croak $e{ regex }
        unless $name =~ /^[\w\[\]-]+$/;

    $self->{ name } = $name;
    $self->{ name };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# adapted from 'CGI Programming with Perl'
sub is_tainted {
    my $self = shift;
    my( $value ) = @_;

    return unless defined $value;
    my $blank = substr( $value, 0, 0 );
    return not eval { eval "1 || $blank" || 1 };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub error_decoration {
    my $self = shift;
    my( $begin, $end ) = @_;

    # must accept arrayref
    ( $begin, $end ) = @$begin
        if ref $begin eq 'ARRAY';

    # we have to be able to pass undef as the second param
    $end = $begin if ! defined $end and @_ == 1;
    if( @_ ) {
        $self->{ error_decoration } = [ $begin, $end ];
        return( $begin, $end );
    }

    ( $begin, $end ) = @{ $self->{ error_decoration }}
        if $self->{ error_decoration };
    return @{ $self->{ error_decoration }}
        if defined $begin or defined $end;
    return;
};

1;

__END__

=head1 NAME 

CGI::ValidOp::Base - base class for CGI::ValidOp and its associates.

=head1 DESCRIPTION

Provides object and method construction, and other common methods, for other CGI::ValidOp classes.  Should not be used directly; see L<CGI::ValidOp>.

=head1 AUTHOR

Randall Hansen <legless@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2003-2005 Randall Hansen. All rights reserved.

This program is free software; you may redistribute it and/or modify it under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut

# $Id: Base.pm 387 2005-04-21 23:45:27Z soh $
