package Regexp::Parsertron;

use strict;
use warnings;
use warnings qw(FATAL utf8); # Fatalize encoding glitches.

use Data::Section::Simple 'get_data_section';

use Marpa::R2;

use Moo;

use Scalar::Does '-constants';

use Tree;

use Try::Tiny;

use Types::Standard qw/Any Bool Int Object Str/;

has bnf =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Any,
	required => 0,
);

has count =>
(
	default  => sub{return 0},
	is       => 'rw',
	isa      => Int,
	required => 0,
);

has grammar =>
(
	default  => sub {return ''},
	is       => 'rw',
	isa      => Any,
	required => 0,
);

has match_count =>
(
	default  => sub{return 0},
	is       => 'rw',
	isa      => Int,
	required => 0,
);

has miss_count =>
(
	default  => sub{return 0},
	is       => 'rw',
	isa      => Int,
	required => 0,
);

has re =>
(
	default  => sub {return ''},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has recce =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Any,
	required => 0,
);

has target =>
(
	default  => sub {return ''},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has tree =>
(
	default  => sub{return Tree -> new('root')},
	is       => 'rw',
	isa      => Object,
	required => 0,
);

has verbose =>
(
	default  => sub {return 1},
	is       => 'rw',
	isa      => Bool,
	required => 0,
);

our $VERSION = '0.01';

# ------------------------------------------------

sub BUILD
{
	my($self)	= @_;
	my($bnf)	= get_data_section('V 5.20');

	$self -> bnf($bnf);
	$self -> grammar
	(
		Marpa::R2::Scanless::G -> new
		({
			source => \$self -> bnf
		})
	);

} # End of BUILD.

# ------------------------------------------------

sub as_string
{
	my($self, $candidate) = @_;

	return does($candidate, 'Regexp') ? $candidate : qr/$candidate/;

} # End of as_string.

# ------------------------------------------------

sub next_few_chars
{
	my($self, $stringref, $offset) = @_;
	my($s) = substr($$stringref, $offset, 20);
	$s     =~ tr/\n/ /;
	$s     =~ s/^\s+//;
	$s     =~ s/\s+$//;

	return $s;

} # End of next_few_chars.

# ------------------------------------------------

sub parse
{
	my($self, %opts) = @_;

	$self -> recce
	(
		Marpa::R2::Scanless::R -> new
		({
			exhaustion     => 'event',
			grammar        => $self -> grammar,
			ranking_method => 'high_rule_only',
		})
	);

	# Emulate parts of new(), which makes things a bit earier for the caller.

	$self -> count($opts{count})	if (defined $opts{count});
	$self -> re($opts{re})			if (defined $opts{re});
	$self -> target($opts{target})	if (defined $opts{target});

	# Return 0 for success and 1 for failure.

	my($result) = 0;

	my($message);

	try
	{
		if (defined (my $value = $self -> _process) )
		{
		}
		else
		{
			$result = 1;

			print "Error: Parse failed\n" if ($self -> verbose);
		}
	}
	catch
	{
		$result = 1;

		print "Error: Parse failed. ${_}" if ($self -> verbose);
	};

	# Return 0 for success and 1 for failure.

	return 0;

} # End of parse.

# ------------------------------------------------

sub _process
{
	my($self)		= @_;
	my($raw_re)		= $self -> re;
	my($string_re)	= $self -> as_string($raw_re);
	$string_re		= $1 if ($string_re =~ /^\((.+)\)$/);
	my($ref_re)		= \"$string_re"; # Use " in comment for UltraEdit.
	my($length)		= length($string_re);
	my($re_count)	= $self -> count;
	my($target)		= $self -> target;

	print "$re_count: Parsing $raw_re => $string_re. Target: '$target'. ";

	if ($target =~ qr/$raw_re/)
	{
		$self -> match_count($self -> match_count + 1);

		print "Target matches. \n";
	}
	else
	{
		$self -> miss_count($self -> miss_count + 1);

		print "Target does not match. \n";
	}

	my($child) = Tree -> new();

	$child -> meta
	({
		name	=> 'open_parenthesis',
		text	=> '(',
	});

	$self -> tree -> add_child($child);

	my($event_name);
	my($lexeme);
	my($message);
	my($original_lexeme);
	my($pos);
	my($span, $start);

	# We use read()/lexeme_read()/resume() because we pause at each lexeme.

	for
	(
		$pos = $self -> recce -> read($ref_re);
		($pos < $length);
		$pos = $self -> recce -> resume($pos)
	)
	{
		($start, $span)            = $self -> recce -> pause_span;
		($event_name, $span, $pos) = $self -> _validate_event($ref_re, $start, $span, $pos,);

		# If the input is exhausted, we exit immediately so we don't try to use
		# the values of $start, $span or $pos. They are ignored upon exit.

		last if ($event_name eq "'exhausted"); # Yes, it has a leading quote.

		$lexeme          = $self -> recce -> literal($start, $span);
		$original_lexeme = $lexeme;
		$pos             = $self -> recce -> lexeme_read($event_name);

		die "lexeme_read($event_name) rejected lexeme |$lexeme|\n" if (! defined $pos);

		$child = Tree -> new();

		$child -> meta
		({
			name	=> $event_name,
			text	=> $lexeme,
		});
 		$self -> tree -> add_child($child);
   }

	if ($self -> recce -> exhausted)
	{
		$message = 'Parse exhausted';

		print "Warning: $message\n" if ($self -> verbose);
	}
	elsif (my $status = $self -> recce -> ambiguous)
	{
		my($terminals) = $self -> recce -> terminals_expected;
		$terminals     = ['(None)'] if ($#$terminals < 0);
		$message       = "Ambiguous parse. Status: $status. Terminals expected: " . join(', ', @$terminals);

		print "Warning: $message\n";
	}

	$child = Tree -> new();

	$child -> meta
	({
		name	=> 'close_parenthesis',
		text	=> ')',
	});

	$self -> tree -> add_child($child);

	# Return a defined value for success and undef for failure.

	return $self -> recce -> value;

} # End of _process.

# ------------------------------------------------

sub report
{
	my($self)	= @_;
	my($format)	= "%-20s  %s\n";

	print sprintf($format, 'Name', 'Text');
	print sprintf($format, '----', '----');

	my($meta);

	for my $node ($self -> tree -> traverse)
	{
		next if ($node -> is_root);

		$meta = $node -> meta;

		print sprintf($format, $$meta{name}, $$meta{text});
	}

	print 'Match count: ', $self -> match_count, '. Miss count: ', $self -> miss_count, ". \n";
	print "\n";

} # End of report.

# ------------------------------------------------

sub _validate_event
{
	my($self, $stringref, $start, $span, $pos) = @_;
	my(@event)       = @{$self -> recce -> events};
	my($event_count) = scalar @event;
	my(@event_name)  = sort map{$$_[0]} @event;
	my($event_name)  = $event_name[0]; # Default.

	# If the input is exhausted, we return immediately so we don't try to use
	# the values of $start, $span or $pos. They are ignored upon return.

	if ($event_name eq "'exhausted") # Yes, it has a leading quote.
	{
		return ($event_name, $span, $pos);
	}

	my($lexeme)        = substr($$stringref, $start, $span);
	my($line, $column) = $self -> recce -> line_column($start);
	my($literal)       = $self -> next_few_chars($stringref, $start + $span);
	my($message)       = "Location: ($line, $column). Lexeme: |$lexeme|. Next few chars: |$literal|";
	$message           = "$message. Events: $event_count. Names: ";

	print $message, join(', ', @event_name), "\n" if ($self -> verbose);

	return ($event_name, $span, $pos);

} # End of _validate_event.

# ------------------------------------------------

1;

=pod

=head1 NAME

C<Regexp::Parsertron> - Parse a Perl regexp into a Tree

=head1 Synopsis


=head1 Description


=head1 Distributions

This module is available as a Unix-style distro (*.tgz).

See L<http://savage.net.au/Perl-modules/html/installing-a-module.html>
for help on unpacking and installing distros.

=head1 Installation

Install L<Regexp::Parsertron> as you would any C<Perl> module:

Run:

	cpanm Regexp::Parsertron

or run:

	sudo cpan Regexp::Parsertron

or unpack the distro, and then either:

	perl Build.PL
	./Build
	./Build test
	sudo ./Build install

or:

	perl Makefile.PL
	make (or dmake or nmake)
	make test
	make install

=head1 Constructor and Initialization

C<new()> is called as C<< my($parser) = Regexp::Parsertron -> new(k1 => v1, k2 => v2, ...) >>.

It returns a new object of type C<Regexp::Parsertron>.

Key-value pairs accepted in the parameter list (see corresponding methods for details
[e.g. L</text([$stringref])>]):

=over 4

=item o close => $arrayref

=back

=head1 Methods

=head2 new()

See L</Constructor and Initialization> for details on the parameters accepted by L</new()>.


=head1 FAQ

=head2 What is the purpose of this module?

=over 4

=item o To provide a stand-alone parser for regexps

=item o To help me learn more about regexps

=item o To, I hope, form the basis of a replacement for the horrendously complex L<Regexp::Assemble>

=back

=head2 Does this module interpret regexps in any way?

No. You have to run your own Perl code to do that. This module just parses them into a data
structure.

And that really means this module does not match the regexp against anything. If I appear to do that
while testing new code, you can't rely on that appearing in production versions of the module.

=head2 Does this module re-write regexps?

Not yet, but that's the plan. So, ultimately, this module might be able to replace some of
L<Regexp::Assemble>'s functionality.

This includes support for assembling complex regexps out of repeated calls to methods within this
module.

=head2 Does this module handle both Perl5 and Perl6?

Initially, it will only handle Perl5 syntax.

=head2 Does this module handle various versions of regexps (i.e., of Perl5)?

Yes, version-dependent regexp syntax will be supported for recent versions of Perl. This is done by
having tokens within the BNF which are replaced at start-up time with version-dependent details.

=head1 References

L<http://perldoc.perl.org/perlre.html>. This is the definitive document.

L<http://perldoc.perl.org/perlretut.html>. Samples with commentary.

L<http://perldoc.perl.org/perlop.html#Regexp-Quote-Like-Operators>

L<http://perldoc.perl.org/perlrequick.html>

L<http://perldoc.perl.org/perlrebackslash.html>

L<http://www.nntp.perl.org/group/perl.perl5.porters/2016/02/msg234642.html>

=head1 See Also

L<Graph::Regexp>

L<Regexp::Assemble>

L<Regexp::ERE>

L<Regexp::Keywords>

L<Regexp::Lexer>

L<Regexp::List>

L<Regexp::Optimizer>

L<Regexp::Parser>

L<Regexp::SAR>. This is vaguely a version of L<Set::FA::Element>.

L<Regexp::Stringify>

L<Regexp::Trie>

And many others...

=head1 Machine-Readable Change Log

The file Changes was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Repository

L<https://github.com/ronsavage/Regexp-Parsertron>

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Regexp::Parsertron>.

=head1 Author

L<Regexp::Parsertron> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2016.

Marpa's homepage: L<http://savage.net.au/Marpa.html>.

My homepage: L<http://savage.net.au/>.

=head1 Copyright

Australian copyright (c) 2016, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License 2.0, a copy of which is available at:
	http://opensource.org/licenses/alphabetical.

=cut

# Policy: Event names are always the same as the name of the corresponding lexeme.
#
# Note:   Tokens of the form '_xxx_' are replaced with version-dependent values.

__DATA__
@@ V 5.20
:default				::= action => [values]

lexeme default			= latm => 1

:start					::= regexp

# G1 stuff.

regexp					::= pattern_set+

pattern_set				::= extended_modifiers

# Note: The outer '(' ... ')' will be stripped off before Marpa sees the regexp.

extended_modifiers		::= question_mark comment
extended_modifiers		::= question_mark colon pattern
extended_modifiers		::= question_mark extended_set
extended_modifiers		::= question_mark extended_set colon pattern

comment					::= hash pattern

extended_set			::= caret_token positive_letters negative_letter_set

caret_token				::=
caret_token				::= caret

positive_letters		::=
positive_letters		::= a2z

negative_letter_set		::=
negative_letter_set		::= minus_negative_letters

minus_negative_letters	::= minus negative_letters

negative_letters		::= a2z

pattern					::= text*

# L0 stuff, in alphabetical order.

:lexeme					~ a2z					pause => before		event => a2z
a2z						~ [a-z]

:lexeme					~ caret					pause => before		event => caret
caret					~ '^'

#:lexeme					~ close_parenthesis		pause => before		event => close_parenthesis
#close_parenthesis		~ ')'

:lexeme					~ colon					pause => before		event => colon
colon					~ ':'

:lexeme					~ hash					pause => before		event => hash
hash					~ ':'

:lexeme					~ minus					pause => before		event => minus
minus					~ '-'

#:lexeme					~ open_parenthesis		pause => before		event => open_parenthesis
#open_parenthesis		~ '('

:lexeme					~ question_mark			pause => before		event => question_mark
question_mark			~ '?'

:lexeme					~ text					pause => before		event => text
text					~ [[:print:]]+
