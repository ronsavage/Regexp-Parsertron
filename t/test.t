use strict;
use warnings;

use Regexp::Parsertron;

# Warning: Can't use Test::Stream because of the '#' in the regexps.

use Test::More;

# ------------------------------------------------

my(@test) =
(
{
	count	=> 1,
	regexp	=> qr//i,
	string	=> '(?^i:)',
	target	=> '',
},
{
	count	=> 2,
	regexp	=> qr/A|B/i,
	string	=> '(?^i:A|B)',
	target	=> 'A',
},
);
my($limit)	= shift || 0;
my($parser)	= Regexp::Parsertron -> new;

my($expected);
my($got);
my($result);

for my $test (@test)
{
	# Use this trick to run the tests one-at-a-time. See scripts/test.sh.

	next if ( ($limit > 0) && ($$test{count} != $limit) );

	$result = $parser -> parse($$test{target}, $$test{regexp}, $$test{string});

	if ($result == 0)
	{
		$got		= $parser -> as_string;
		$expected	= $$test{string};

		is_deeply($got, $expected, "$$test{count}: $$test{regexp}");
	}
	else
	{
		die "Test $$test{count} failed to return 0 from run()\n";
	}
}

done_testing;
