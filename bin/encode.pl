#!/usr/bin/perl
use strict;
use warnings;

use HTML::Entities;

print encode_entities( $_ ), "\n"
    for @ARGV;
