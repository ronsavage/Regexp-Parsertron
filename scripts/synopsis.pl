#!/usr/bin/env perl

use strict;
use warnings;

use File::Slurper 'read_lines';

use Regexp::Parsertron;

# ---------------------

my($input_file_name)	= 'perl-5.21.11/re_tests';
my(@lines)				= grep{! /#/ && ! /^\s*$/ && ! /^__END__/} read_lines($input_file_name);
my(%expected_failure)	=
(
	 14 => 1,
	 15 => 1,
	 16 => 1,
	 34 => 1,
	 35 => 1,
	 36 => 1,
	 38 => 1,
	 39 => 1,
	 40 => 1,
	 42 => 1,
	 43 => 1,
	 50 => 1,
	 51 => 1,
	 52 => 1,
	 53 => 1,
	 54 => 1,
	 55 => 1,
	 56 => 1,
	 57 => 1,
	 58 => 1,
	 59 => 1,
	 62 => 1,
	 74 => 1,
	 75 => 1,
	 76 => 1,
	 81 => 1,
	 82 => 1,
	 85 => 1,
	 86 => 1,
	 87 => 1,
	 88 => 1,
	 95 => 1,
	100 => 1,
	113 => 1,
	114 => 1,
	115 => 1,
	116 => 1,
	117 => 1,
	128 => 1,
	129 => 1,
	139 => 1,
	140 => 1,
	141 => 1,
	142 => 1,
	143 => 1,
	144 => 1,
	195 => 1,
	196 => 1,
	197 => 1,
	247 => 1,
	248 => 1,
	249 => 1,
	250 => 1,
	251 => 1,
	252 => 1,
	253 => 1,
	254 => 1,
	255 => 1,
	256 => 1,
	257 => 1,
	258 => 1,
	259 => 1,
	260 => 1,
	261 => 1,
	262 => 1,
	263 => 1,
	264 => 1,
	265 => 1,
	266 => 1,
	267 => 1,
	268 => 1,
	269 => 1,
	270 => 1,
	276 => 1,
	278 => 1,
	279 => 1,
	280 => 1,
	281 => 1,
	282 => 1,
	283 => 1,
	284 => 1,
	285 => 1,
	286 => 1,
	287 => 1,
	290 => 1,
	292 => 1,
	295 => 1,
	296 => 1,
	297 => 1,
	298 => 1,
	299 => 1,
	300 => 1,
	301 => 1,
	302 => 1,
	303 => 1,
	304 => 1,
	305 => 1,
	306 => 1,
	307 => 1,
	308 => 1,
	309 => 1,
	310 => 1,
	311 => 1,
	312 => 1,
	313 => 1,
	314 => 1,
	315 => 1,
	316 => 1,
	317 => 1,
	318 => 1,
	319 => 1,
	320 => 1,
	321 => 1,
	368 => 1,
	369 => 1,
	370 => 1,
	371 => 1,
	372 => 1,
	373 => 1,
);

my(@fields);
my(@re);
my(%seen);

for my $line (@lines)
{
	@fields		= split(/\t/, $line);
	$fields[0]	=~ s/^\s+//;

	next if ($fields[2] =~ /y/);
	next if ($seen{$fields[0]});

	$seen{$fields[0]} = 1;

	push @re, $fields[0];
}

my($count)	= 0;
my($number)	= shift(@ARGV) || 0;
my($parser)	= Regexp::Parsertron -> new(verbose => 1);

my($error);
my($result);

for my $re (@re)
{
	$count++;

	# Use this trick to run the tests one-at-a-time. See scripts/test.sh.

	next if ( ($number > 0) && ($count != $number) );

	if ($expected_failure{$count})
	{
		print "\tExpected error: ";
	}

	$result = $parser -> parse(re => $re);

	# Reset tree for next test.

	$parser -> tree('');
}

print 'Perl error count:  ', $parser -> perl_error_count, "\n";
print 'Marpa error count: ', $parser -> marpa_error_count, "\n";
