#!/usr/bin/env perl

use v5.10;
use strict;
use warnings;

use File::Slurper 'read_lines';

use Regexp::Parsertron;

# ---------------------

my($prefix)				= 'perl-5.21.11';
my($input_file_name)	= "$prefix/re_tests";
my(@lines)				= grep{! /#/ && ! /^\s*$/ && ! /^__END__/} read_lines($input_file_name);
my(%perl_failure) =
(	# For V 5.20.2.
	  41 => 1,
	  42 => 1,
	  43 => 1,
	  71 => 1,
	  72 => 1,
	  73 => 1,
	  75 => 1,
	  79 => 1,
	  80 => 1,
	  85 => 1,
	  93 => 1,
	 133 => 1,
	 134 => 1,
	 135 => 1,
	 136 => 1,
	 137 => 1,
	 138 => 1,
	 139 => 1,
	 140 => 1,
	 141 => 1,
	 142 => 1,
	 145 => 1,
	 182 => 1,
	 183 => 1,
	 184 => 1,
	 193 => 1,
	 194 => 1,
	 200 => 1,
	 201 => 1,
	 206 => 1,
	 216 => 1,
	 270 => 1,
	 289 => 1,
	 315 => 1,
	 316 => 1,
	 317 => 1,
	 318 => 1,
	 319 => 1,
	 320 => 1,
	 321 => 1,
	 322 => 1,
	 323 => 1,
	 352 => 1,
	 353 => 1,
	 354 => 1,
	 355 => 1,
	 356 => 1,
	 357 => 1,
	 373 => 1,
	 374 => 1,
	 375 => 1,
	 381 => 1,
	 382 => 1,
	 384 => 1,
	 410 => 1,
	 411 => 1,
	 416 => 1,
	 450 => 1,
	 558 => 1,
	 582 => 1,
	 583 => 1,
	 612 => 1,
	 613 => 1,
	 614 => 1,
	 615 => 1,
	 616 => 1,
	 617 => 1,
	 618 => 1,
	 619 => 1,
	 620 => 1,
	 621 => 1,
	 622 => 1,
	 623 => 1,
	 631 => 1,
	 635 => 1,
	 636 => 1,
	 637 => 1,
	 638 => 1,
	 642 => 1,
	 786 => 1,
	 787 => 1,
	 788 => 1,
	 789 => 1,
	 790 => 1,
	 791 => 1,
	 792 => 1,
	 793 => 1,
	 794 => 1,
	 795 => 1,
	 796 => 1,
	 797 => 1,
	 798 => 1,
	 799 => 1,
	 800 => 1,
	 801 => 1,
	 802 => 1,
	 803 => 1,
	 804 => 1,
	 805 => 1,
	 806 => 1,
	 807 => 1,
	 808 => 1,
	 809 => 1,
	 839 => 1,
	 876 => 1,
	 878 => 1,
	 880 => 1,
	 881 => 1,
	 882 => 1,
	 883 => 1,
	 884 => 1,
	 885 => 1,
	 886 => 1,
	 887 => 1,
	 888 => 1,
	 889 => 1,
	 892 => 1,
	 894 => 1,
	 926 => 1,
	 927 => 1,
	 928 => 1,
	 929 => 1,
	 930 => 1,
	 931 => 1,
	 932 => 1,
	 933 => 1,
	 934 => 1,
	 935 => 1,
	 936 => 1,
	 937 => 1,
	 938 => 1,
	 939 => 1,
	 940 => 1,
	 941 => 1,
	 942 => 1,
	 943 => 1,
	 944 => 1,
	 945 => 1,
	 946 => 1,
	 947 => 1,
	 948 => 1,
	 949 => 1,
	 950 => 1,
	 951 => 1,
	 952 => 1,
	 976 => 1,
	 997 => 1,
	 998 => 1,
	 999 => 1,
	1001 => 1,
	1003 => 1,
	1040 => 1,
	1041 => 1,
	1042 => 1,
	1043 => 1,
	1044 => 1,
	1045 => 1,
	1046 => 1,
	1047 => 1,
	1048 => 1,
	1049 => 1,
	1050 => 1,
	1051 => 1,
	1052 => 1,
	1053 => 1,
	1054 => 1,
	1055 => 1,
	1056 => 1,
	1084 => 1,
	1099 => 1,
	1100 => 1,
	1101 => 1,
	1102 => 1,
	1121 => 1,
	1122 => 1,
	1123 => 1,
	1124 => 1,
	1125 => 1,
	1126 => 1,
);

my(%marpa_failure) =
(	# For V 5.20.2.
	 645 => 1,
	 646 => 1,
	 647 => 1,
	 648 => 1,
	 655 => 1,
	 656 => 1,
	 657 => 1,
	 658 => 1,
	 659 => 1,
	 660 => 1,
	 661 => 1,
	 662 => 1,
	 663 => 1,
	 664 => 1,
	 665 => 1,
	 815 => 1,
	 816 => 1,
	 870 => 1,
	 871 => 1,
	1085 => 1,
	1086 => 1,
	1087 => 1,
	1088 => 1,
	1114 => 1,
	1115 => 1,
	1116 => 1,
	1119 => 1,
	1120 => 1,
);

my(@fields);
my(@re);
my(%seen);

for my $line (@lines)
{
	@fields		= split(/\t/, $line);
	$fields[0]	=~ s/^\s+//;

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

	if ($perl_failure{$count})
	{
		print 'Perl error: ';
	}
	elsif ($marpa_failure{$count})
	{
		print 'Marpa error: ';
	}

	$result = $parser -> parse(re => $re);

	# Reset for next test.

	$parser -> reset;
}

say 'Perl error count:  ', $parser -> perl_error_count;
say 'Marpa error count: ', $parser -> marpa_error_count;

open(my $fh, '>', "xt/author/$prefix.tests");
say $fh map{$_} sort keys %seen;
close $fh;
