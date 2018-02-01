#!/usr/bin/env perl

use v5.10;
use strict;
use warnings;

use Regexp::Parsertron;

# ------------------------------------------------

my(@test)	=
(
{
	count		=> 1,
	expected	=> '(?^:(?#Comment))',
	re			=> qr/(?#Comment)/,
},
# This is commented out because the BNF now defines
# pattern_sequence				::= pattern_set+
# Instead of
# pattern_sequence				::= pattern_set*
#
#{
#	count		=> 90,
#	expected	=> '(?^:(?))',
#	re			=> qr/(?)/,
#},
{
	count		=> 2,
	expected	=> '(?^:(?a))',
	re			=> qr/(?a)/,
},
{
	count		=> 3,
	expected	=> '(?^:(?a-i))',
	re			=> qr/(?a-i)/,
},
{
	count		=> 4,
	expected	=> '(?^:(?^a))',
	re			=> qr/(?^a)/,
},
{
	count		=> 5,
	expected	=> '(?^:(?a:))',
	re			=> qr/(?a:)/,
},
{
	count		=> 6,
	expected	=> '(?^:(?a:b))',
	re			=> qr/(?a:b)/,
},
# This is commented out because the BNF now defines
# pattern_sequence				::= pattern_set+
# Instead of
# pattern_sequence				::= pattern_set*
#
#{
#	count		=> 91,
#	expected	=> '(?^:(?:))',
#	re			=> qr/(?:)/,
#},
{
	count		=> 7,
	expected	=> '(?^:[yY][eE][sS])',
	re			=> qr/[yY][eE][sS]/,
},
{
	count		=> 8,
	expected	=> '(?^:(A|B))',
	re			=> qr/(A|B)/,
},
{
	count		=> 9,
	expected	=> '(?^i:Perl|JavaScript)',
	re			=> qr/Perl|JavaScript/i,
},
{
	count		=> 10,
	expected	=> '(?^i:Perl|JavaScript|C++)',
	re			=> qr/Perl|JavaScript/i,
},
{
	count		=> 11,
	expected	=> '(?^:/ab+bc/)',
	re			=> '/ab+bc/',
},
{
	count		=> 12,
	expected	=> '(?^:a)',
	re			=> qr/a/,
},
{
	count		=> 13,
	expected	=> '(?^i:Perl|JavaScript|(?:Flub|BCPL))',
	re			=> qr/Perl|JavaScript|(?:Flub|BCPL)/i,
},
{
	count		=> 14,
	expected	=> "(?^:(?:(?<n>foo)|(?'n'bar)))",
	re			=> qr/(?:(?<n>foo)|(?'n'bar))/,
},
{
	count		=> 15,
	expected	=> "(?^:(?:(?'n2'foo)|(?<n2>bar)))",
	re			=> qr/(?:(?'n2'foo)|(?<n2>bar))/,
},
{
	count		=> 16,
	expected	=> "(?^:(?:(?'n'foo)|(?'n'bar)))",
	re			=> qr/(?:(?'n'foo)|(?'n'bar))/,
},
{
	count		=> 17,
	expected	=> "(?^:(?:(?'n2'foo)|(?'n2'bar)))",
	re			=> qr/(?:(?'n2'foo)|(?'n2'bar))/,
},
{
	count		=> 18,
	expected	=> '(?^:(?:(?<n2>foo)|(?<n2>bar))\k<n2>)',
	re			=> qr/(?:(?<n2>foo)|(?<n2>bar))\k<n2>/,
},
);

my($limit)	= shift || 0;
my($parser)	= Regexp::Parsertron -> new(verbose => 2);
my(%stats)	= (success => 0, total => 0);

my($expected);
my($got);
my($result);
my($success);

for my $test (@test)
{
	# Use this trick to run the tests one-at-a-time. See scripts/test.sh.

	next if ( ($limit > 0) && ($$test{count} != $limit) );

	$stats{total}++;

	$result		= $parser -> parse(re => $$test{re});
	$success	= 1;

	if ($$test{count} == 10)
	{
		$parser -> append(text => '|C++', uid => 5);
	}

	if ($result == 0)
	{
		$got		= $parser -> as_string;
		$expected	= $$test{expected};
		$success	= 0 if ($got eq $expected);

		$stats{success}++ if ($success == 0);

		say "Case: $$test{count}. got: $got. expected: $expected. result: $success (0 is success). ";
	}
	else
	{
		say "Test $$test{count} failed to return 0 from parse(). ";
	}

	say '-' x 100;

	# Reset for next test.

	$parser -> reset;
}

print "Statistics: ";
print "$_: $stats{$_}. " for (sort keys %stats);
say '';
