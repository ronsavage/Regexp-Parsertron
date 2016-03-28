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
		print "Expected failure: ";
	}

	$result = $parser -> parse(re => $re);

	# Reset tree for next test.

	$parser -> tree('');
}
