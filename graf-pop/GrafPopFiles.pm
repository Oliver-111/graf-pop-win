#    ====================================================================================
#                               PUBLIC DOMAIN NOTICE
#                National Center for Biotechnology Information
#
#        This software/database is a "United States Government Work" under the
#        terms of the United States Copyright Act.  It was written as part of
#        the author's official duties as a United States Government employee and
#        thus cannot be copyrighted.  This software/database is freely available
#        to the public for use. The National Library of Medicine and the U.S.
#        Government have not placed any restriction on its use or reproduction.
#        Although all reasonable efforts have been taken to ensure the accuracy
#        and reliability of the software and data, the NLM and the U.S.
#        Government do not and cannot warrant the performance or results that
#        may be obtained by using this software or data. The NLM and the U.S.
#        Government disclaim all warranties, express or implied, including
#        warranties of performance, merchantability or fitness for any particular
#        purpose.
#
#        Please cite the author in any work or product based on this material.
#    ====================================================================================

package GrafPopFiles;

use strict;
use Carp;

#
# Read scores of subjects from result file generated by the C++ program
#
sub ReadGrafPopResults
{
    my ($inFile, $minSnps, $maxSnps) = @_;

    my $sbjNo = 0;
    my $totSbjs = 0;
    my @sbjPopScores = ();
    my %allPopSbjs = ();
    my ($minAncSnps, $maxAncSnps, $totAncSnps, $meanAncSnps) = (100000, 0, 0, 0);
    my $error = "";

    open FILE, $inFile or die "ERROR: Couldn't open file $inFile!\n\n";
    my $header = <FILE>;
    while ($header =~ /^\#/) {
	    $header = <FILE>;
    }
    if ($header !~ /^Sample\t\#SNPs\tGD1.*\tGD2.*\tGD3.*\tGD4.*/) {
	    $error = "Invalid input file.  Expected following columns:\n" .
	            "\tSample\n\t#SNPs\n\tGD1 (x)\n\tGD2 (y)\n\tGD3 (z)\n\tGD4\n\tE(%)\n\tF(%)\n\tA(%)\n\n";
    }
    else {
	    while(<FILE>) {
	        chomp;
	        my @vals = split /\t/, $_;
            if (@vals >= 9) {
                my ($sbj, $numSnps, $xVal, $yVal, $zVal, $gd4, $ePct, $fPct, $aPct) = @vals;
                my %info = (subject => $sbj, race => "", raceNo => 0, color => "", snps => $numSnps,
                        x => $xVal, y => $yVal, z => $zVal, gd4 => $gd4, fPct => $fPct, ePct => $ePct, aPct => $aPct);
                if ($numSnps >= $minSnps && $numSnps <= $maxSnps && !$allPopSbjs{$sbj}) {
                    push @sbjPopScores, \%info;

                    $minAncSnps = $numSnps if ($numSnps < $minAncSnps);
                    $maxAncSnps = $numSnps if ($numSnps > $maxAncSnps);
                    $totAncSnps += $numSnps;
                    $allPopSbjs{$sbj} = 1;
                    $sbjNo++;
                }

                $totSbjs++;
            }
	    }
        close FILE;

        my $numSbjs = @sbjPopScores;
        $meanAncSnps = $numSbjs > 0 ? $totAncSnps * 1.0 / $numSbjs : 0;

        if ($sbjNo < 1) {
            $error = "No sample found in $inFile";
        }

        print "Found $numSbjs samples with population scores in file $inFile. Total $totSbjs samples.\n";
        if ($minSnps > 0 || $maxSnps < 100438) {
            if ($numSbjs > 0) {
                print "\t$numSbjs samples have $minSnps to $maxSnps genotyped Ancestry SNPs.\n";
            }
            else {
                $error = "No samples with genotype ancestry SNPs between $minSnps and $maxSnps found in the input file.\n";
            }
        }
    }

    return (\@sbjPopScores, \%allPopSbjs, $minAncSnps, $maxAncSnps, $meanAncSnps, $error);
}

#
# Read races from a two-column file without header line for all subjects in a set
#
sub ReadSubjectRaces
{
    my ($file, $allSbjs) = @_;

    my $err = "";
    my $hasRace = 0;
    my %sbjRaces = ();
    my %allRaces = ();
    my $totSbjs = 0;

    unless (-e $file) {
        $err = "didn't find subject race file $file!\n";
        return (\%sbjRaces, \%allRaces, $hasRace, $err);
    }

    my $unkRace = "NOT REPORTED";
    open FILE, $file or die "\nERROR: Couldn't open $file!\n\n";
    while (<FILE>) {
        chomp;
        next if ($_ !~ /\S/);

        my ($sbj, $race) = split /\t/, $_;
        $race =~ s/\s*$//;
        $race = $1 if ($race =~ /^\s*\"(.+)\"\s*$/);

        if ($sbj && $race) {
            $totSbjs++;

            if ($allSbjs->{$sbj}) {
                $hasRace = 1 if ($race && $race !~ /^unknown$/i);
                $race = $unkRace if (!$race || $race !~ /\S/);
                $sbjRaces{$sbj} = $race;
                $allRaces{$race} = 1;
            }
        }
    }
    close FILE;

    my $numSbjs = keys %sbjRaces;
    my $numRaces = keys %allRaces;
    if ($totSbjs == 0) {
	    print "\nWARNING: No subject races found in $file.\n";
    }
    elsif ($numRaces > 0) {
	    print "\nRead $numRaces populations from $numSbjs subjects in $file\n";
    }
    else {
	    print "\nWARNING: No race values found in $file for subjects included in input GrafPop result file.\n\n";
    }

    return (\%sbjRaces, \%allRaces, $hasRace, $err);
}

1;