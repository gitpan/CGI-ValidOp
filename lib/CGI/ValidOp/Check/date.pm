package CGI::ValidOp::Check::date;
use strict;
use warnings;

use base qw/ CGI::ValidOp::Check /;

my %TIMES = (
    past => 1,
    present => 1,
    future => 1,
);

sub iso {
    my $self = shift;
    sub {
        my $value = shift;
        my $times = [ grep { $TIMES{ $_ } if defined $_ } @_ ];

        return $self->pass unless defined $value;

        my $errmsg = '$label must include year, month, and date as YYYY-MM-DD';

        my ($y, $m, $d) = check_iso_format($value)
            or return $self->fail( $errmsg );
        
        if ( $times and $times->[0] ) {
            my ( $valid, $time ) = valid_date( $y, $m, $d, $times );
            return $self->fail( '$label cannot be in the ' . $time )
                unless ( $valid );
        }

        if ( check_year($y) &&
             check_month($m) &&
             check_day($d, $m, $y) ) {

            return $self->pass( sprintf( "%02d-%02d-%02d", $y, $m, $d ));
       }

       return $self->fail( $errmsg );
    }
}

sub american {
    my $self = shift;
    sub {
        my $value = shift;
        return $self->pass unless defined $value;

        my $errmsg = '$label must be a valid date in a standard American format: mm/dd/yyyy or mm-dd-yyyy. (Leading zeros are not required)';

        my( $y, $m, $d ) = check_american_format($value)
            or return $self->fail( $errmsg );

        if ( check_year($y) &&
             check_month($m) &&
             check_day($d, $m, $y) ) {

            return $self->pass( sprintf( '%d-%02d-%02d', $y, $m, $d ));
        }

        return $self->fail( $errmsg );
    }
}

sub general {
    my $self = shift;
    sub {
        my $value = shift;
        return $self->pass unless defined $value;

        my $errmsg = '$label must be a valid date in one of the following formats: mm/dd/yyyy, mm-dd-yyyy, yyyy-mm-dd. (Leading zeros are not required)';

        my( $y, $m, $d ) =
            check_american_format($value);
        unless (defined $y) {
            ($y, $m, $d) = check_iso_format($value);
        }

        if ( check_year($y) &&
             check_month($m) &&
             check_day($d, $m, $y) ) {

            return $self->pass( sprintf( '%d-%02d-%02d', $y, $m, $d ));
        }

        return $self->fail( $errmsg );
    }

}

sub valid_date {
    my ( $y, $m, $d, $times ) = @_;
    my @today = today();
    my @value = ( $y, $m, $d );

    my $time = 'present';
    for ( my $i = 0; $i < 3; $i++ ) {
        if ( $today[$i] > $value[$i] ) {
            $time = 'past';
            last;
        }
        if ( $today[$i] < $value[$i] ) {
            $time = 'future';
            last;
        }
    }
    return (grep { m/$time/ } @$times) ? 1 : 0, $time;
}

sub today {
    my ($sec,$min,$hour,$mday,$mon,$year) = localtime time;
    return ( $year + 1900, $mon + 1, $mday);
}

# Checks that given date is in iso format and returns array
# of year, month, day strings if so, else undef.
sub check_iso_format {
    my $date = shift;
    return unless defined $date;

    my( $y, $m, $d ) = 
        $date =~ qr#^(\d{1,4})-(\d{1,2})-(\d{1,2})$#
        or return undef;

    return ($y, $m, $d);
}

# Checks that given date is in american format and returns 
# array of year, month, day strings if so, else undef.
sub check_american_format {
    my $date = shift;
    return unless defined $date;

    my( $m, $d, $y ) = 
        $date =~ qr#^(\d{1,2})(?:-|/)(\d{1,2})(?:-|/)(\d{4})$#
        or return undef;

    return ($y, $m, $d);
}

# Returns 1 if year is a 4 digit number.
sub check_year {
    my $y = shift;
    return unless defined $y;
    return 1 if $y =~ qr/^\d{4}$/;
    return 0;
}

# Returns 1 if month is between 1 and 12.  Accepts 01, 02...
sub check_month {
    my $m = shift;
    return unless defined $m;
    return 1 if $m =~ qr/^\d{1,2}$/ and $m > 0 and $m < 13;
    return 0;
}

# Requires day and month; requires year if month is February.
# Returns 1 if day is valid for month/year.  0 if not.
# Returns undefined if insufficient parameters given.
sub check_day {
    my( $d, $m, $y ) = @_;
    return unless defined $d and defined $m;
    # checking February's day requires the year for leap years
    return unless $m != 2 or defined $y;

    return 0 if $d !~ qr/^\d{1,2}$/ or $d < 1 or $d >31;

    # 30 days hath september, april, june and november
    if ($m == 4 || $m == 6 || $m == 9 || $m == 11 ) {
        return 1 if $d <= 30;
    }
    # all the rest have 31
    elsif ($m != 2) {
        return 1;
    }
    # except February, which has 28
    elsif ( not leap_year($y)) {
        return 1 if $d <= 28;
    }
    # or on a leap year, 29
    else {
        return 1 if $d <= 29;
    }
    return 0;
}

sub leap_year {
    my $y = shift;
    return 0 if $y % 4; # not multiple of 4
    return 1 unless $y % 400; # is multiple of 400
    return 0 unless $y % 100; # is multiple of 100
    return 1; # everything else
}
1;

__END__

=head1 NAME 

CGI::ValidOp::Check::date - CGI::ValidOp::Check module to check if input looks like a date.

=head1 DESCRIPTION

=over 4

=item iso

Checks for ISO 8601 compliance:  YYYY-MM-DD.  Returns date in compliant format, zero-padded if necessary.

=item american

Checks that the date is a standard American mm/dd/yyyy or mm-dd-yyyy date.  Insists on 4 digit years.  Leading zeros for month and day are optional.

Returns date in ISO format with leading zeros.

This allows the application to handle dates in a single, consistent format.  The presentation layer can then concern itself with what format dates need to be displayed in.

=item general

Checks that the date is either iso or american format.  Returns iso format.

=back

=head1 AUTHOR

Randall Hansen <legless@cpan.org>
Joshua Partlow <jpartlow@opensourcery.com>

=head1 COPYRIGHT

Copyright (c) 2003-2006 Randall Hansen. All rights reserved.

This program is free software; you may redistribute it and/or modify it under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
