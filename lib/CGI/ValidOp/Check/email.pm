package CGI::ValidOp::Check::email;
use strict;
use warnings;

use base qw/ CGI::ValidOp::Check /;

sub default {
    my $self = shift;
    sub {
        my ( $tainted ) = @_;
        return $self->pass() unless $tainted; 
        $tainted =~ /^(.*)$/s;
        my $value = $1;

        # For now only very basic validation.
        # Make sure we have data before and after an @ symbol, and make sure the
        # data after the @ symbol contains at least one period.
        # For full validation we may want to use an existing cpan module.
        # Found a perl regex that is 100% compliant e-mail validation,
        # however it made me laugh really hard: 
        #   http://ex-parrot.com/~pdw/Mail-RFC822-Address.html
        return $self->fail( "\$label: '$value' is not a valid email address." ) 
            if $value =~ m/\@.*\@/ig or not $value =~ m/.+\@.+\..+/ig;

        return $self->pass( $value );
    }
}

1;
