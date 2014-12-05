#!/usr/bin/perl

use LWP::Simple;
use GD;
use CGI;

use strict;
use warnings;

my $q = CGI->new;

print $q->header('text/plain');

my $user = $q->param('user');

do { print "No user."; exit } unless $user;

$user =~ s/[^a-zA-Z0-9]//;

do { print "No user."; exit } unless $user;

my $url = 'http://www.gokgs.com/servlet/graph/'.$user.'-en_US.png';

my $content = get($url);

do { print "No graph."; exit } unless $content;

my $image = GD::Image->newFromPngData($content);

my $last = 0;
my $ltot = 0;
my $s = 21;
my @lines = (0);
my $green;
my $gpos;
my $glast = 0;
my $gtot = 0;
my $isgreen;
my $isgrey;
foreach my $y ( ($s+1) .. 441 ) {
	my ($r, $g, $b) = $image->rgb($image->getPixel(638,$y));
	my $ints = $r - 4; #(($r - 4) ** 2 + ($g - 2) ** 2 + ($b - 4) ** 2) ** 0.5;
	($r, $g, $b) = (0, $g - ($r - 2), $b - $r);
	if ($ints > 0) {
		$last += ($y - $s) * $ints;
		$ltot += $ints;
		$isgrey = 1;
	} elsif ($isgrey) {
		#print "Grey: $y $last $ltot\n";
		$last = $last / $ltot;
		push @lines, $last;
		$last = 0;
		$ltot = 0;
		undef $isgrey;
	}
	if ($g > 10) {
		$glast += ($y - $s) * $g;
		$gtot += $g;
		$isgreen = 1;
	} elsif ($isgreen) {
		if ($gtot > 100) {
			$glast = $glast / $gtot;
			#print "Green: $y $glast $gtot\n";
			do { print "Two greens."; exit } if ($green);
			$green = $glast;
			$gpos = $#lines;
		}
		$glast = 0;
		$gtot = 0;
		undef $isgreen;
	}
}
push @lines, 442 - $s;
#foreach(1..$#lines) {
#	print "Diff $_: ".($lines[$_] - $lines[$_-1])."\n";
#}
#print "Main diff: ".(421 / $#lines)."\n";
my $diff = 421 / $#lines;

do { print "No green."; exit } unless defined $green;

my $gstart = $diff * $gpos;
my $gfrac = ($green - $gstart) / $diff;

#print "Green is $green ($gpos + $gfrac from $gstart / $lines[$gpos]).\n";

$url = 'http://www.gokgs.com/gameArchives.jsp?user='.$user;

$content = get($url);

do { print "No archive."; exit } unless $content;

do { print "No rank on archives"; exit } unless $content =~ /$user \[(\d+)(k|d)\??\]/;
my $rank = $2 eq 'd' ? $1 : 1 - $1;
$rank -= $gfrac;
if ($rank > -0.5) {
	print sprintf("%0.2fd", $rank + 1)."\n";
} else {
	print sprintf("%0.2fk", -$rank)."\n";
}
