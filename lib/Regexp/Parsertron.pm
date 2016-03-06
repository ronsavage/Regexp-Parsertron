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

use Types::Standard qw/Any Bool Object RegexpRef Str/;

has bnf =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Any,
	required => 0,
);

has grammar =>
(
	default  => sub {return ''},
	is       => 'rw',
	isa      => Any,
	required => 0,
);

has re =>
(
	default  => sub {return qr//},
	is       => 'rw',
	isa      => RegexpRef,
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
	my($re)			= $self -> re; # $self -> as_string($self -> re);
	my($stringref)	= \"$re"; # Use " in comment for UltraEdit.
	my($first_pos)	= 0;
	$$stringref		= $1 if ($$stringref =~ /^\((.+)\)$/);
	my($length)		= length($$stringref);
	my($child)		= Tree -> new();

	$child -> meta
	({
		name	=> 'open_parenthesis',
		value	=> '(',
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
		$pos = $self -> recce -> read($stringref);
		($pos < $length);
		$pos = $self -> recce -> resume($pos)
	)
	{
		($start, $span)            = $self -> recce -> pause_span;
		($event_name, $span, $pos) = $self -> _validate_event($stringref, $start, $span, $pos,);

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
			value	=> $lexeme,
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
		value	=> ')',
	});

	$self -> tree -> add_child($child);
	$self -> report;

	# Return a defined value for success and undef for failure.

	return $self -> recce -> value;

} # End of _process.

# ------------------------------------------------

sub report
{
	my($self)	= @_;
	my($format)	= "%-20s  %s\n";

	print sprintf($format, 'Name', 'Value');

	my($meta);

	for my $node ($self -> tree -> traverse)
	{
		next if ($node -> is_root);

		$meta = $node -> meta;

		print sprintf($format, $$meta{name}, $$meta{value});
	}

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


__DATA__
@@ V 5.20
:default				::= action => [values]

lexeme default			= latm => 1

:start					::= regexp

# G1 stuff.

regexp					::= pattern_set+

pattern_set				::= extended_modifiers

extended_modifiers		::= question_mark extended_set colon pattern

extended_set			::= caret_token positive_letters negative_letter_set

caret_token				::=
caret_token				::= caret

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

:lexeme					~ minus					pause => before		event => minus
minus					~ '-'

#:lexeme					~ open_parenthesis		pause => before		event => open_parenthesis
#open_parenthesis		~ '('

:lexeme					~ question_mark			pause => before		event => question_mark
question_mark			~ '?'

:lexeme					~ text					pause => before		event => text
text					~ [[:print:]]+
