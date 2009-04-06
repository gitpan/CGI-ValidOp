package CGI::ValidOp::Check::text;
use strict;
use warnings;

use base qw/ CGI::ValidOp::Check /;

sub default {
    (
        qr#^[\w\s\(\*\.\\\?,!"'/:;@&%)-]+$#,
        q#Only letters, numbers, and the following punctuation are allowed for $label: ! " ' ( ) * , - .  / : ; ? \ @ & %#,
    )
}

sub word {
    (
        qr/^\w+$/,
        q#Only one word is allowed for $label#,
    )
}

sub words {
    (
        qr/^[\w -]+$/,
        q#Only words are allowed for $label#,
    )
}

sub liberal {
    (
        qr#^[\w\s\(\*\.\\\?,!"'/:;&=%~\+\@\$)\#-]+$#,
        q|Only letters, numbers, and the following punctuation are allowed for $label: ! " ' ( ) * , - . / : ; & = % ~ + ? \ @ $ #|,
    )
}

sub hippie {
    (
        qr{^[\w\s\(\*\.\\\?#,{}^_[\]!"'/:;&=%~\+\@\$)-]+$},
        q{Only letters, numbers, and the following punctuation are allowed for $label: ! " ' ( ) * , - . / : ; & = % ~ + ?  \ @ # { } [ ] ^ _ $},
    )
}

1;

__END__

=head1 NAME 

CGI::ValidOp::Check::text - CGI::ValidOp::Check module to validate text

=head1 DESCRIPTION

=over 4

=item default

Fails if incoming value contains characters other than Perl's character classes \w, \s, and: ! " ' ( ) * , - .  / : ; ? @ \

=item word

Fails if value contains anything other an Perl's "word" character class ([a-zA-Z0-9_]).

=item words

Like B<word> above, but can contain spaces as well.

=item liberal

Expands on default allowing $ = ~ +

=item hippie

Even more permissive than liberal, including # { } [ ] ^ _ $

Still does not allow <tags> to be embedded though...

=back

=head1 AUTHOR

Randall Hansen <legless@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2003-2005 Randall Hansen. All rights reserved.

This program is free software; you may redistribute it and/or modify it under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut

# $Id: text.pm 75 2005-01-14 05:49:20Z soh $
