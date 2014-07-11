#!/usr/bin/perl

use strict;

die "usage: exprcount.pl <ensemble#>\n" unless @ARGV == 1;

my $ENSEMBLE_TO_UNIGENE_FILE = "mart_export.txt";
my $UNIGEN_PROFILES_FILE = "Hs.profiles";
#my $UNIGEN_PROFILES_FILE = "Hs.temp";

my $ENSEMBLE_NUMBER = $ARGV[0];

#
# Find all corresponding unigene numbers
#
my @UNIGENE_NUMBERS = ();

open(my $fh, '<', $ENSEMBLE_TO_UNIGENE_FILE) or die "$!\n";

for (<$fh>) {
    chomp;
    my @vals = split(/\s+/, $_);
    if ($ENSEMBLE_NUMBER eq $vals[0] && @vals > 1) {
        if ($vals[1] =~ /.*\.(\d+)/) {
            my $unigene_num = $1;
            push @UNIGENE_NUMBERS, $unigene_num;
        }
    }
}

close($fh);


#
# Exit with error code 1 if no unigene numbers found
#
exit 1 unless @UNIGENE_NUMBERS > 0;

print "unigene numbers:\n";
foreach (@UNIGENE_NUMBERS) {
   print $_, "\n";
}

my %TISSUES_FOUND = ();
my %DEV_STAGES_FOUND = ();

open(my $gh, '<', $UNIGEN_PROFILES_FILE) or die "$!\n";

#
# Scan profiles file one line at a time.
# We are in 1 of 3 possible modes:
#   0 : searching for matching unigen number
#   1 : searching for tissue (body sites)
#   2 : searching for developement stage
#
my $mode = 0;

foreach (<$gh>) {
    chomp;

    if ($mode != 0 && /^>/) {
        $mode = 0;
    }

    if ($mode == 0 && /^>\s+(\d+)\|(.*)$/) {
        my $unigene_num = $1;
        my $description = $2;
        next unless 
            $description eq "Body Sites" ||
            $description eq "Developmental Stage";
        my $found = 0;
        for (my $i = 0; $i < @UNIGENE_NUMBERS; $i++) {
            $found = $unigene_num == $UNIGENE_NUMBERS[$i];
            last if $found;
        }
        next unless $found;

        if ($description eq "Body Sites") {
            $mode = 1;
        } else {
            $mode = 2;
        }
    }

    if ($mode != 0 && /^(.*)\t(\d+).*\/.*(\d+)/) {
        my $name = $1;
        my $count = $2;
        my $foo = $3;
        if ($mode == 1) {
            $TISSUES_FOUND{$name} = 1 if $count > 0;
        } else {
            $DEV_STAGES_FOUND{$name} = 1 if $count > 0;
        }
    }
}

close($gh);

print "tissues found:\n";
print join("\n", keys %TISSUES_FOUND), "\n";
print "\n";

print "development stages found:\n";
print join("\n", keys %DEV_STAGES_FOUND), "\n";

exit 0;

