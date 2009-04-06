package CGI::ValidOp::Check::sql;
use strict;
use warnings;

use base qw/ CGI::ValidOp::Check /;

sub default {
    (
        qr|^[\w\s\.:\[\]_\^\*/%+<>=~!@#&\|`\?\$\(\),;'"-]+$|,
        q{Only letters, numbers, and the following punctuation are allowed for $label: .  : [ ] _ ^ * / % + - <> = ~ !  @ # & | ` ?  $ ( )  , ; ' "},
    )
}

sub safer {
    my $self = shift;
    sub {
        my( $value ) = @_;

        my $error = _safer( $value );
        return $self->fail( $error )
            if $error;

        return $self->fail( "SELECT statement not allowed for \$label" )
            if $value =~ /select/i;
        $value =~ /^(.*)$/s;
        return $self->pass( $1 );
    }
}

sub safer_select {
    my $self = shift;
    sub {
        my( $value ) = @_;

        my $error = _safer( $value );
        return $self->fail( $error )
            if $error;

        $value =~ /^(.*)$/s;
        return $self->pass( $1 );
    }
}

sub _safer {
    my( $value ) = @_;

    return "Semicolons not allowed for \$label"
        if $value =~ /[;]/;
    return "Dashes not allowed for \$label"
        if $value =~ /[-]/;
    return "DELETE statement not allowed for \$label"
        if $value =~ /delete/i;
    return "DROP statement not allowed for \$label"
        if $value =~ /drop/i;
    return "UPDATE statement not allowed for \$label"
        if $value =~ /update/i;
    return "INTO statement not allowed for \$label"
        if $value =~ /into/i;
    return;
}

1;

__END__

=head1 NAME 

CGI::ValidOp::Check::sql - CGI::ValidOp::Check module to validate SQL.

=head1 DESCRIPTION

=over 4

=item default

Fails if incoming value contains characters other than: \w \s .  : [ ] _ ^ * / % + - <> = ~ !  @ # & | ` ?  $ ( )  , ; ' "

=item safer

Named "safer" since allowing users to write SQL can never be truly "safe."  This check attempts to allow only things which will not harm data.  It doesn't prevent a clever query from wreaking other havoc, though, like a DOS.

=item safer_select

Just like "safer" but allows 'SELECT'.

=back

=head1 AUTHOR

Randall Hansen <legless@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2003-2007 Randall Hansen. All rights reserved.

This program is free software; you may redistribute it and/or modify it under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
