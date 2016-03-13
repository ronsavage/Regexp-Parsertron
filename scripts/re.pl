#!/usr/bin/env perl

use strict;
use warnings;

# ---------------------

my($s)	= 'z';
my($re)	= qr/(?s-i:)/;

if ($s =~ $re) {print ''}else{print ''};

print "$re\n";

$re = qr/A|B/x;

if ($s =~ $re) {print ''}else{print ''};

print "$re\n";

$re = qr/(?s-i:more.*than).*million/;

if ($s =~ $re) {print ''}else{print ''};

print "$re\n";

$re = qr/my.STRING/is;

if ($s =~ $re) {print ''}else{print ''};

print "$re\n";

