use Test::More qw(no_plan);
use strict;
use warnings;
use lib 't/';
BEGIN { use_ok('Simple') };

# construct a small tree
my $root = Simple->new_root(name => 'root');
isa_ok($root, 'Simple');
can_ok($root, 'match', 'xpath');
$root->add_kid(name => 'page', foo => 10, bar => 'bif');
$root->add_kid(name => 'page', foo => 20, bar => 'bof');
$root->add_kid(name => 'page', foo => 30, bar => 'bongo');
my @pages = $root->kids;
for my $page (@pages) {
    isa_ok($page, 'Simple');
    can_ok($page, 'match', 'xpath');
    for (0 .. 9) {
        $page->add_kid(name => 'paragraph');
        $page->add_kid(name => 'image') if $_ % 2;
    }
}

# root's xpath should be /
is($root->xpath(), '/');

# page xpath tests
is($pages[0]->xpath, '/page[0]');
is($pages[1]->xpath, '/page[1]');
is($pages[2]->xpath, '/page[2]');

# paragraph xpath tests
foreach my $page (@pages) {
    my @para = grep { $_->name eq 'paragraph' } $page->kids;
    for (my $x = 0; $x < $#para; $x++) {
        is($para[$x]->xpath, $page->xpath . "/paragraph[$x]");
    }
    my @images = grep { $_->name eq 'image' } $page->kids;
    for (my $x = 0; $x < $#images; $x++) {
        is($images[$x]->xpath, $page->xpath . "/image[$x]");
    }
}

# test match against returned xpaths
is($root->match($pages[0]->xpath), 1);
is(($root->match($pages[0]->xpath))[0], $pages[0]);
is($root->match($pages[1]->xpath), 1);
is(($root->match($pages[1]->xpath))[0], $pages[1]);
is($root->match($pages[2]->xpath), 1);
is(($root->match($pages[2]->xpath))[0], $pages[2]);

# test paragraph xpath matching, both from the page and the root
foreach my $page (@pages) {
    my @para = grep { $_->name eq 'paragraph' } $page->kids;
    for (my $x = 0; $x < $#para; $x++) {
        is($para[$x]->match($page->xpath), 1);
        is(($para[$x]->match($page->xpath))[0], $page);
        is(($root->match($page->xpath))[0], $page);
    }
}

# test local name query
is($root->match('page'), 3);
is(($root->match('page'))[0]->match('paragraph'), 10);

# test global  name query
is($root->match('//paragraph'), 30);

# test parent context
foreach my $page (@pages) {
    my @para = grep { $_->name eq 'paragraph' } $page->kids;
    for (my $x = 0; $x < $#para; $x++) {
        is(($para[$x]->match("../paragraph[$x]"))[0], $para[$x]);
    }
}

# test string attribute matching
is($root->match('page[@bar="bif"]'), 1);
is(($root->match('page[@bar="bif"]'))[0], $pages[0]);
is($root->match('page[@bar="bof"]'), 1);
is(($root->match('page[@bar="bof"]'))[0], $pages[1]);
is($root->match("page[\@bar='bongo']"), 1);
is(($root->match("page[\@bar='bongo']"))[0], $pages[2]);

# test numeric attribute matching
is($root->match('page[@foo=10]'), 1);
is(($root->match('page[@foo=10]'))[0], $pages[0]);
is($root->match('page[@foo=20]'), 1);
is(($root->match('page[@foo=20]'))[0], $pages[1]);
is($root->match('page[@foo=30]'), 1);
is(($root->match('page[@foo=30]'))[0], $pages[2]);

is($root->match('page[@foo>10]'), 2);
is(($root->match('page[@foo>10]'))[0], $pages[1]);
is(($root->match('page[@foo>10]'))[1], $pages[2]);

is($root->match('page[@foo<10]'), 0);

is($root->match('page[@foo!=10]'), 2);

is($root->match('page[@foo<=10]'), 1);

is($root->match('page[@foo>=10]'), 3);
