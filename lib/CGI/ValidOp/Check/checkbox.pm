package CGI::ValidOp::Check::checkbox;
use strict;
use warnings;

use base qw/ CGI::ValidOp::Check /;

sub default {
    (
        qr/^on$/i,
        q#Checkbox $label must be checked.#,
    )
}

sub boolean {
    my $self = shift;
    sub {
        my $value = shift;
        return $self->pass( 0 ) unless defined $value;
        return $self->pass( 1 ) if $value =~ /^on$/i;
        $self->fail( q/Only a checkbox is allowed for parameter $label./ );
    }
}

1;

__END__

=head1 NAME 

CGI::ValidOp::Check::checkbox - CGI::ValidOp::Check module to validate a checkbox control.

=head1 DESCRIPTION

=over 4

=item default

Fails unless value equals "on" (or "on," since it's case-insensitive).  Using this check requires the checkbox to be checked; if the checkbox is unchecked an error will be created.

=item boolean

Returns 1 if the checkbox was checked (i.e. is "on"); 0 if it was not; an error if it reeives any other data.

=back

=head1 AUTHOR

Randall Hansen <legless@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2003-2005 Randall Hansen. All rights reserved.

This program is free software; you may redistribute it and/or modify it under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut

# $Id: checkbox.pm 75 2005-01-14 05:49:20Z soh $
