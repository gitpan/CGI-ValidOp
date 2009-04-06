package CGI::ValidOp::Check::number;
use strict;
use warnings;

use base qw/ CGI::ValidOp::Check /;

sub default {
    (
        qr/^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/,
        '$label must be a number.',
    )
}

sub integer {
    (
        qr/^[+-]?\d+$/,
        '$label must be an integer.',
    )
}

sub decimal {
    (
        qr/^-?(?:\d+(?:\.\d*)?|\.\d+)$/,
        '$label must be a decimal number.',
    )
}

sub positive_int {
    (
        qr/^[+]?\d+$/,
        '$label must be a positive integer.',
    )
}

sub positive_list {
    my $self = shift;
    sub {
        my ( $input ) = @_;
        return $self->pass() unless defined $input;

        $input =~ m/(.*)/g;
        $input = $1;

        my @values = split(/\s*,\s*/, $input );
        my @bad;
        for my $value ( @values ) {
            next if $value =~ m/^[+]?\d+$/;
            push( @bad, $value );
        }
        if ( @bad ) {
            my $error = '$label: "' . join( ', ', @bad );
            $error .= (@bad > 1) ? '" are not positive integers.'
                                 : '" is not a positive integer.';
            return $self->fail( $error );
        }
        return $self->pass( join(', ', @values ));
    }
}

1;

__END__

=head1 NAME 

CGI::ValidOp::Check::number - CGI::ValidOp::Check module to check for numericity.

=head1 DESCRIPTION

=over 4

=item default

Checks for something that looks like a number.

=item integer

Checks for an integer, positive or negative; includes 0.

=item decimal

Checks for a decimal, positive or negative; includes 0.

=back

=head1 AUTHOR

Randall Hansen <legless@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2003-2005 Randall Hansen. All rights reserved.

This program is free software; you may redistribute it and/or modify it under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut

# $Id: number.pm 75 2005-01-14 05:49:20Z soh $
