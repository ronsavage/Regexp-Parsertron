#!/usr/bin/env perl

use v5.10;
use strict;
use warnings;

use Regexp::Parsertron;

# ---------------------

my($re)		= qr/Perl|JavaScript/i;
my($parser)	= Regexp::Parsertron -> new(verbose => 1);

# Return 0 for success and 1 for failure.

my($result) = $parser -> parse(re => $re);

say "Calling add(text => '|C++', uid => 6)";

$parser -> add(text => '|C++', uid => 6);
$parser -> print_raw_tree;
$parser -> print_cooked_tree;

my($as_string) = $parser -> as_string;

say "Original:  $re. Result: $result. (0 is success)";
say "as_string: $as_string";
say 'Perl error count:  ', $parser -> perl_error_count;
say 'Marpa error count: ', $parser -> marpa_error_count;
