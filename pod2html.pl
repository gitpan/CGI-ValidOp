#!/usr/bin/perl
use strict;
use warnings;

use Pod::Simple::HTMLBatch;

my $pod = Pod::Simple::HTMLBatch->new;
$pod->css_flurry( 0 );
$pod->javascript_flurry( 0 );

$pod->add_css( '/res/css/cpan.css' );
$pod->batch_convert( [ 'lib/CGI', 'lib/CGI/ValidOp' ], '/Users/soh/public_html/dev/validop/pod' );
# $pod->batch_convert( [ '/System/Library/Perl/5.8.1/CGI.pm' ], '/Users/soh/public_html/doc/cgi' );
