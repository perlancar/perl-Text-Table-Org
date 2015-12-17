package Text::Table::Org;

# DATE
# VERSION

#IFUNBUILT
use 5.010001;
use strict;
use warnings;
#END IFUNBUILT

package Text::Table::Tiny;
$Text::Table::Tiny::VERSION = '0.04';
use parent 'Exporter';
use List::Util qw();

our @EXPORT_OK = qw/ generate_table /;

# ABSTRACT: makes simple tables from two-dimensional arrays, with limited templating options


our $COLUMN_SEPARATOR = '|';
our $ROW_SEPARATOR = '-';
our $CORNER_MARKER = '+';
our $HEADER_ROW_SEPARATOR = '=';
our $HEADER_CORNER_MARKER = 'O';

sub generate_table {

    my %params = @_;
    my $rows = $params{rows} or die "Must provide rows!";

    # foreach col, get the biggest width
    my $widths = _maxwidths($rows);
    my $max_index = _max_array_index($rows);

    # use that to get the field format and separators
    my $format = _get_format($widths);
    my $row_sep = _get_row_separator($widths);
    my $head_row_sep = _get_header_row_separator($widths);

    # here we go...
    my @table;
    push @table, $row_sep;

    # if the first row's a header:
    my $data_begins = 0;
    if ( $params{header_row} ) {
        my $header_row = $rows->[0];
        $data_begins++;
        push @table, sprintf(
                         $format,
                         map { defined($header_row->[$_]) ? $header_row->[$_] : '' } (0..$max_index)
                     );
        push @table, $params{separate_rows} ? $head_row_sep : $row_sep;
    }

    # then the data
    foreach my $row ( @{ $rows }[$data_begins..$#$rows] ) {
        push @table, sprintf(
	    $format,
	    map { defined($row->[$_]) ? $row->[$_] : '' } (0..$max_index)
	);
        push @table, $row_sep if $params{separate_rows};
    }

    # this will have already done the bottom if called explicitly
    push @table, $row_sep unless $params{separate_rows};
    return join("\n",grep {$_} @table);
}

sub _get_cols_and_rows ($) {
    my $rows = shift;
    return ( List::Util::max( map { scalar @$_ } @$rows), scalar @$rows);
}

sub _maxwidths {
    my $rows = shift;
    # what's the longest array in this list of arrays?
    my $max_index = _max_array_index($rows);
    my $widths = [];
    for my $i (0..$max_index) {
        # go through the $i-th element of each array, find the longest
        my $max = List::Util::max(map {defined $$_[$i] ? length($$_[$i]) : 0} @$rows);
        push @$widths, $max;
    }
    return $widths;
}

# return highest top-index from all rows in case they're different lengths
sub _max_array_index {
    my $rows = shift;
    return List::Util::max( map { $#$_ } @$rows );
}

sub _get_format {
    my $widths = shift;
    return "$COLUMN_SEPARATOR ".join(" $COLUMN_SEPARATOR ",map { "%-${_}s" } @$widths)." $COLUMN_SEPARATOR";
}

sub _get_row_separator {
    my $widths = shift;
    return "$CORNER_MARKER$ROW_SEPARATOR".join("$ROW_SEPARATOR$CORNER_MARKER$ROW_SEPARATOR",map { $ROW_SEPARATOR x $_ } @$widths)."$ROW_SEPARATOR$CORNER_MARKER";
}

sub _get_header_row_separator {
    my $widths = shift;
    return "$HEADER_CORNER_MARKER$HEADER_ROW_SEPARATOR".join("$HEADER_ROW_SEPARATOR$HEADER_CORNER_MARKER$HEADER_ROW_SEPARATOR",map { $HEADER_ROW_SEPARATOR x $_ } @$widths)."$HEADER_ROW_SEPARATOR$HEADER_CORNER_MARKER";
}

# Back-compat: 'table' is an alias for 'generate_table', but isn't exported
*table = \&generate_table;

1;
#ABSTRACT: Generate Org tables

=head1 SYNOPSIS

 use Text::Table::Org;

 my $rows = [
     # header row
     ['Name', 'Rank', 'Serial'],
     # rows
     ['alice', 'pvt', '123456'],
     ['bob',   'cpl', '98765321'],
     ['carol', 'brig gen', '8745'],
 ];
 print Text::Table::Org::table(rows => $rows, header_row => 1);


=head1 DESCRIPTION

This module provides a single function, C<table>, which formats a
two-dimensional array of data as an Org text table.

The example shown in the SYNOPSIS generates the following table:

    | Name  | Rank     | Serial   |
    |-------+----------+----------|
    | alice | pvt      | 123456   |
    | bob   | cpl      | 98765321 |
    | carol | brig gen | 8745     |


=head2 OPTIONS

The C<table> function understands three arguments, which are passed as a hash.

=over

=item * rows (aoaos)

Takes an array reference which should contain one or more rows of data, where
each row is an array reference.

=item * header_row (bool)

If given a true value, the first row in the data will be interpreted as a header
row, and separated from the rest of the table with a ruled line.

=back


=head1 SEE ALSO

This module is basically L<Text::Table::Tiny> 0.03 modified to output Org tables
instead of its original variant table format.

The output of this module is very similar to that of L<Text::MarkdownTable>. In
fact, Org recognizes its output as a valid Org table (the only difference is
that corner marker is C<|> instead of the Org standard of C<+>).

Some other text table modules: L<Text::ANSITable>, L<Text::ASCIITable>,
L<Text::FormatTable>, L<Text::Table>, L<Text::TabularDisplay>.

See also L<Bencher::Scenario::TextTableModules>.

=cut
