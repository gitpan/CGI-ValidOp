package CGI::ValidOp::Check::alternative;
use strict;
use warnings;

use base qw/ CGI::ValidOp::Check /;
use CGI;

sub default {
    my $self = shift;
    sub {
        my ( $value, $cond ) = @_;


        # Pass if there is a value, and the conditional is empty
        # Pass if the value is empty but the conditional is not
        # Pass if both are set
        # FIXME: Only need to check if the parameter is true or false
        # this means this is safe in that we won;t be bringing in anything
        # bad, however since this is being queried from CGI instead of validop
        # it will return true even if '$cond' is not validated. This is not
        # critical, but should be resolved.
        my $CGI = CGI->new; #Randall, please don't kill me.
        return $self->pass if $CGI->param( $cond );

        if ( $value ) {
            $value =~ m/^(.*)$/;
            return $self->pass( $1 );
        }

        #Fail saying the label is required because the condition has not been met.
        return $self->fail( "\$label is required." ); 
    }
}

1;
