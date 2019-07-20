#!perl

use Test::More;

use_ok('Data::Pageset::Extended');

ok my $pager = Data::Pageset::Extended->new(), 'constructor';

is $pager->total_entries, 0, 'total_entries';

is $pager->total_entries(100), 100, 'set total_entries';

is $pager->entries_per_page, 10, 'entries_per_page (default)';

is $pager->current_page, 1, 'current_page';

is $pager->current_page(2), 2, 'set current_page';
is $pager->current_page, 2, 'current_page';

is $pager->first, 11, 'first';

is $pager->entries_per_page(5), 5, 'set entries_per_page';

is $pager->current_page, 3, 'current_page';

is $pager->first, 11, 'first';


is $pager->total_entries(1200), 1200, 'set total_entries';
is $pager->last_page, 240, 'last_page';
is $pager->current_page(1), 1, 'set current_page';

is_deeply $pager->series, [
    -4999,  -3999, -2999, -1999, -999,    #
      -499, -399,  -299,  -199,  -99,     #
      -49,  -39,   -29,   -19,   -9,      #
      -4 .. 4,                            #
      9,   19,   29,   39,   49,          #
      99,  199,  299,  399,  499,         #
      999, 1999, 2999, 3999, 4999,        #
      ],
  'series';

is $pager->max_pages_per_set => 39, 'pages_per_set';

is_deeply $pager->pages_in_set, [
    1 .. 5,    #
    10, 20, 30, 40, 50,    #
    100, 200               #
  ],
  'pages_in_set';

is $pager->current_page(50), 50, 'set current_page';

is_deeply $pager->pages_in_set, [
    1, 11, 21, 31, 41, #
    46.. 54, #
    59, 69, 79, 89, 99, #
    149, #
  ],
  'pages_in_set';


done_testing;
