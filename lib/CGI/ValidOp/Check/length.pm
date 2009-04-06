package CGI::ValidOp::Check::length;
use strict;
use warnings;

use base qw/ CGI::ValidOp::Check /;
use Carp;

sub default {
    my $self = shift;
    sub {
        # this code is brutally verbose, but all the tests pass
        my( $value, $min, $max ) = @_;
        
        $self->allow_tainted( 1 );
        return $self->pass unless defined $value;

        # length
        # length(0)
        # length(0,0)
        return $self->pass( $value ) unless $min or $max;

        # length(3)
        # length(3,3)
        if(( $min and ! defined $max ) or $min and $min == $max ) {
            return $self->pass( $value ) if $value =~ /^.{$min}$/;
            return $self->fail( "\$label length must be exactly $min characters long." );
        }
        # length(3,0)
        elsif( $min and defined $max and $max == 0 ) {
            return $self->pass( $value ) if $value =~ /^.{$min,}$/;
            return $self->fail( "\$label length must be at least $min characters long." );
        }
        # length(6,3)
        elsif( $min and defined $max and $min > $max ) {
            croak "Length 'min' must be less than 'max.'"
        }
        # length(0,3)
        elsif( $min == 0 and $max ) {
            return $self->pass( $value ) if $value =~ /^.{$min,$max}$/;
            return $self->fail( "\$label length must be at most $max characters long." );
        }
        # length(3,6)
        elsif( $min and $max ) {
            return $self->pass( $value ) if $value =~ /^.{$min,$max}$/;
            return $self->fail( "\$label length must be between $min and $max characters long." );
        }
        croak 'Something has gone horribly wrong with length check.';
    }
}

1;


__END__

=head1 NAME 

CGI::ValidOp::Check::length - CGI::ValidOp::Check module to check length of value

=head1 DESCRIPTION

Fails if length of value in characters is not within specified parameters.  Usage:

=over 4

=item length

=item length(0)

=item length(0,0)

Any value will pass.

=item length(3)

=item length(3,3)

Length must exactly equal 3.

=item length(3,0)

Length must be at least 3.

=item length(0,3)

Length must be at most 3.

=item length(3,6)

Length must be between 3 and 6.

=item length(6,3)

Error; death.

=back

=head1 AUTHOR

Randall Hansen <legless@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2003-2005 Randall Hansen. All rights reserved.

This program is free software; you may redistribute it and/or modify it under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut

# $Id: length.pm 75 2005-01-14 05:49:20Z soh $

