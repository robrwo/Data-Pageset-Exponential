# NAME

Data::Pageset::Exponential - Page numbering for very large page numbers

# VERSION

version v0.4.0

# SYNOPSIS

```perl
my $pager = Data::Pageset::Exponential->new(
  total_entries => $total_entries,
  entries_per_page => $per_page,
);

$pager->current_page( 1 );

my $pages = $pager->pages_in_set;

# Returns
# [ 1, 2, 3, 10, 20, 30, 100, 200, 300, 1000, 2000, 3000 ]
```

# DESCRIPTION

This is a pager designed for paging through resultsets that contain
hundreds if not thousands of pages.

The interface is similar to [Data::Pageset](https://metacpan.org/pod/Data%3A%3APageset) with sliding pagesets.

# ATTRIBUTES

## `total_entries`

This is the total number of entries.

It is a read/write attribute.

## `entries_per_page`

This is the total number of entries per page. It defaults to `10`.

It is a read/write attribute.

## `first_page`

This returns the first page. It defaults to `1`.

## `current_page`

This is the current page number. It defaults to the ["first\_page"](#first_page).

It is a read/write attribute.

## `exponent_base`

This is the base exponent for page sets. It defaults to `10`.

## `exponent_max`

This is the maximum exponent for page sets. It defaults to `3`, for
pages in the thousands.

It should not be greater than

```
ceil( log( $total_pages ) / log(10) )
```

however, larger numbers will increase the size of ["pages\_in\_set"](#pages_in_set).

## `pages_per_exponent`

This is the number of pages per exponent. It defaults to `3`.

## `pages_per_set`

This is the maximum number of pages in ["pages\_in\_set"](#pages_in_set). It defaults
to

```
1 + 2 * ( $pages_per_exponent * ( $exponent_max + 1 ) - 1 )
```

which for the default values is 23.

This should be an odd number.

This was renamed from ["max\_pages\_per\_set"](#max_pages_per_set) in v0.3.0.

## `max_pages_per_set`

This is a deprecated alias for ["pages\_per\_set"](#pages_per_set).

# METHODS

## `entries_on_this_page`

Returns the number of entries on the page.

## `last_page`

Returns the number of the last page.

## `first`

Returns the index of the first entry on the ["current\_page"](#current_page).

## `last`

Returns the index of the last entry on the ["current\_page"](#current_page).

## `previous_page`

Returns the number of the previous page.

## `next_page`

Returns the number of the next page.

## `pages_in_set`

Returns an array reference of pages in the page set.

## `previous_set`

This returns the first page number of the previous page set, for the
first exponent.

It is added for compatability with [Data::Pageset](https://metacpan.org/pod/Data%3A%3APageset).

## `next_set`

This returns the first page number of the next page set, for the first
exponent.

It is added for compatability with [Data::Pageset](https://metacpan.org/pod/Data%3A%3APageset).

# KNOWN ISSUES

## Differences with Data::Page

This module is intended as a drop-in replacement for [Data::Page](https://metacpan.org/pod/Data%3A%3APage).
However, it is based on a complete rewrite of [Data::Page](https://metacpan.org/pod/Data%3A%3APage) using
[Moo](https://metacpan.org/pod/Moo), rather than extending it.  Because of that, it needs to fake
`@ISA`.  This may break some applications.

Otherwise, it has the following differences:

- The attributes have type constraints.  Invalid data may throw a fatal
error instead of being ignored.
- Setting the ["current\_page"](#current_page) to a value outside the ["first\_page"](#first_page) or
["last\_page"](#last_page) will return the first or last page, instead of that
value.

## Differences with Data::Pageset

This module can behave like [Data::Pageset](https://metacpan.org/pod/Data%3A%3APageset) in `slide` mode if the
exponent is set to `1`:

```perl
my $pager = Data::Pageset::Exponential->new(
  exponent_max       => 1,
  pages_per_exponent => 10,
  pages_per_set      => 10,
);
```

# SUPPORT FOR OLDER PERL VERSIONS

Since v0.8.0, the this module requires Perl v5.20 or later.

Future releases may only support Perl versions released in the last ten years.

# SEE ALSO

- [Data::Page](https://metacpan.org/pod/Data%3A%3APage)
- [Data::Pageset](https://metacpan.org/pod/Data%3A%3APageset)

# SOURCE

The development version is on github at [https://github.com/robrwo/Data-Pageset-Exponential](https://github.com/robrwo/Data-Pageset-Exponential)
and may be cloned from [git://github.com/robrwo/Data-Pageset-Exponential.git](git://github.com/robrwo/Data-Pageset-Exponential.git)

# BUGS

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/Data-Pageset-Exponential/issues](https://github.com/robrwo/Data-Pageset-Exponential/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

# AUTHOR

Robert Rothenberg <rrwo@cpan.org>

Test code was adapted from [Data::Page](https://metacpan.org/pod/Data%3A%3APage) to ensure compatability.

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2024 by Robert Rothenberg.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```
