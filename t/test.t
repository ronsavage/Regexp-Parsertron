#!/usr/bin/env perl

use strict;
use warnings;

use Regexp::Parsertron;

# Warning: Can't use Test2 or Test::Stream because of the '#' in the regexps.

use Test::More;

# ------------------------------------------------

my(@test)	=
(
{
	count		=> 1,
	expected	=> '(?^:(?#Comment))',
	re			=> qr/(?#Comment)/,
},
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
	expected	=> '(?^i:Perl|JavaScript|C++)',
	re			=> qr/Perl|JavaScript/i,
},
{
	count		=> 10,
	expected	=> '(?^i:Perl|JavaScript|C++)',
	re			=> qr/Perl|JavaScript|C++/i,
},
{
	count		=> 11,
	expected	=> '(?^:/ab+bc/)',
	re			=> '/ab+bc/',
},
{
	count		=> 12,
	expected	=> '(?^:^)',
	re			=> qr/^/,
},
);

my($parser)	= Regexp::Parsertron -> new;

my($count);
my($expected);
my($got);
my($message);
my($result);

for my $test (@test)
{
	$count	= $$test{count}; # Used after the loop.
	$result = $parser -> parse(re => $$test{re});

	if ($count == 9)
	{
		$parser -> append(text => '|C++', uid => 5);
	}

	if ($result == 0) # 0 is success.
	{
		$got		= $parser -> as_string;
		$expected	= $$test{expected};
		$message	= "$$test{count}: re: $$test{re}. got: $got";
		$message	.= ' (After calling append(...) )' if ($$test{count} == 12);

		is_deeply("$got", $expected, $message);
	}
	else
	{
		BAIL_OUT("Test $$test{count} failed to return 0 (== success) from parse()");
	}

	# Reset for next test.

	$parser -> reset;
}

print "# Internal test count: $count\n";

done_testing;
