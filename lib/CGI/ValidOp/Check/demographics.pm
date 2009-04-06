package CGI::ValidOp::Check::demographics;
use strict;
use warnings;

use base qw/ CGI::ValidOp::Check /;

# sub default {
#     (
#         qr/^on$/i,
#         q#Parameter $label must be a US state name.#,
#     )
# }

sub us_state2 {
    my $self = shift;
    sub {
        my $value = shift;
        return $self->pass unless defined $value;
        my $errmsg = q/$label must be the 2-letter abbreviation for a US state name./;
        return $self->fail( $errmsg ) unless $value =~ /^\w{2}$/;
        return $self->pass( $1 ) if $value =~
            qr/^(al|ak|as|az|ar|ca|co|ct|de|dc|fm|fl|ga|gu|hi|id|il|in|ia|ks|ky|la|me|mh|md|ma|mi|mn|ms|mo|mt|ne|nv|nh|nj|nm|ny|nc|nd|mp|oh|ok|or|pw|pa|pr|ri|sc|sd|tn|tx|ut|vt|vi|va|wa|wv|wi|wy)$/i;
        $self->fail( $errmsg );
    }
}

sub us_ssn {
    my $self = shift;
    sub {
        my( $value, $constraint ) = @_;
        return $self->pass unless defined $value;
        if( $value =~ /(^\d{3}-?\d{2}-?\d{4}$)/ ) {
            my $ssn = $1;
            $ssn =~ s/-//g if $constraint and $constraint eq 'integer';
            return $self->pass( $ssn );
        }
        return $self->fail( q/$label must be a number like "123-45-6789"./);
    }
}

1;

__END__

=head1 NAME 

CGI::ValidOp::Check::demographics - CGI::ValidOp::Check module to validate various demographics.

=head1 DESCRIPTION

=over 4

=item default

Should die.

=item us_state2

Passes if value is a valid United States 2-letter abbreviation, as determined by the USPS: http://www.usps.com/ncsc/lookups/usps_abbreviations.html.

=item us_ssn($constraint)

Passes if value is a 9-digit integer with optional dashes (e.g. 123-45-6789).  If C<$constraint> is C<integer> the dashes are stripped:

    # given CGI variable 'ssn' equal to '123-45-6789'
    $ssn = $cgi->param( 'ssn', [ 'demographics::ssn' ]);            # eq '123-45-6789'
    $ssn = $cgi->param( 'ssn', [ 'demographics::ssn(integer)' ]);   # eq '123456789'

=back

=head1 AUTHOR

Randall Hansen <legless@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2003-2005 Randall Hansen. All rights reserved.

This program is free software; you may redistribute it and/or modify it under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut

# $Id: demographics.pm 75 2005-01-14 05:49:20Z soh $

__DATA__

AL AK AS AZ AR CA CO CT DE DC FM FL GA GU HI ID IL IN IA KS KY LA ME MH MD MA MI MN MS MO MT NE NV NH NJ NM NY NC ND MP OH OK OR PW PA PR RI SC SD TN TX UT VT VI VA WA WV WI WY

ALABAMA
ALASKA
AMERICAN SAMOA
ARIZONA
ARKANSAS
CALIFORNIA
COLORADO
CONNECTICUT
DELAWARE
DISTRICT OF COLUMBIA
FEDERATED STATES OF MICRONESIA
FLORIDA
GEORGIA
GUAM
HAWAII
IDAHO
ILLINOIS
INDIANA
IOWA
KANSAS
KENTUCKY
LOUISIANA
MAINE
MARSHALL ISLANDS
MARYLAND
MASSACHUSETTS
MICHIGAN
MINNESOTA
MISSISSIPPI
MISSOURI
MONTANA
NEBRASKA
NEVADA
NEW HAMPSHIRE
NEW JERSEY
NEW MEXICO
NEW YORK
NORTH CAROLINA
NORTH DAKOTA
NORTHERN MARIANA ISLANDS
OHIO
OKLAHOMA
OREGON
PALAU
PENNSYLVANIA
PUERTO RICO
RHODE ISLAND
SOUTH CAROLINA
SOUTH DAKOTA
TENNESSEE
TEXAS
UTAH
VERMONT
VIRGIN ISLANDS
VIRGINIA
WASHINGTON
WEST VIRGINIA
WISCONSIN
WYOMING

