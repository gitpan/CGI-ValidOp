package CGI::ValidOp::Check::required_if;

use strict;
use warnings;

use base qw/ CGI::ValidOp::Check /;

sub default {
    my $self = shift;
    sub {
        my ( $value, $cond ) = @_;

        # pass if both are set OR if both are unset
        # see caveats in Check::alternative too
        my $cgi = CGI->new;
        return $self->pass unless $cgi->param( $cond );
        return $self->fail( "\$label is required." ) unless $value;
        $value =~ m/^(.*)$/;
        return $self->pass( "$1" );
    };
}

1;
