#!/usr/local/bin/perl

my $disclaim = << "EOF";
    ====================================================================================
                               PUBLIC DOMAIN NOTICE
                National Center for Biotechnology Information

        This software/database is a "United States Government Work" under the
        terms of the United States Copyright Act.  It was written as part of
        the author's official duties as a United States Government employee and
        thus cannot be copyrighted.  This software/database is freely available
        to the public for use. The National Library of Medicine and the U.S.
        Government have not placed any restriction on its use or reproduction.
        Although all reasonable efforts have been taken to ensure the accuracy
        and reliability of the software and data, the NLM and the U.S.
        Government do not and cannot warrant the performance or results that
        may be obtained by using this software or data. The NLM and the U.S.
        Government disclaim all warranties, express or implied, including
        warranties of performance, merchantability or fitness for any particular
        purpose.

        Please cite the author in any work or product based on this material.

        Author: Yumi (Jimmy) Jin (jinyu\@ncbi.nlm.nih.gov)
        File Description: script to save samples and ancestry scores into a file.
        Date: 07/07/2021
    ====================================================================================
EOF

BEGIN {
    use Cwd 'abs_path';
    my ($scriptName, $scriptDir) = ("", "");
    my $scriptFullname = abs_path($0);
    ($scriptDir, $scriptName) = ($1, $2) if ($scriptFullname =~ /(\S+)\/(\S+)/);
    push ( @INC, $scriptDir);
}

use strict;
use GrafPopFiles;
use GraphParameters;
use PopulationCutoffs;
use GraphTransformation;
use SubjectAncestry;

if (@ARGV < 2) {
    my $usage = GetScriptUsage();
    print "$disclaim\n$usage\n\n";
    exit;
}

my $inFile = $ARGV[0];
my $outFile = $ARGV[1];

my $param = new GraphParameters();
exit unless ($param);

#--------------------------- Read subject GrafPop scores  ---------------------------#
my ($sbjPopScores, $allPopSbjs, $minSbjSnps, $maxSbjSnps, $meanSbjSnps, $error)
    = GrafPopFiles::ReadGrafPopResults($inFile, $param->{minSnps}, $param->{maxSnps});
if ($error) {
    print "\nERROR: $error\n\n";
    exit;
}

#--------------------------- Read subject races from file ---------------------------#
my %sbjRaces = ();
my %allRaces = ();
my $hasRaceInfo = 0;
my $numRaces = 0;
if ($param->{raceFile}) {
    my ($sbjRaceRef, $allRaceRef, $hasRace, $err) = GrafPopFiles::ReadSubjectRaces($param->{raceFile}, $allPopSbjs);
    %sbjRaces = %$sbjRaceRef;
    %allRaces = %$allRaceRef;
    $hasRaceInfo = $hasRace;
    if ($err) {
        print "\nERROR: $err\n";
        exit;
    }
}

my $ancSbjs = new SubjectAncestry($param, $sbjPopScores, \%sbjRaces);
$ancSbjs->SetSubjectGenoPopulations();
$ancSbjs->SaveResults($outFile);
$ancSbjs->ShowPopulationComparison() if ($param->{raceFile});

sub GetScriptUsage
{
    my $usage = "Usage: SaveSamples.pl <input file> <output file> [Options]

    Note:
          Input file is the file generated by the C++ grafpop program that includes subject ancestry scores.
          Samples and ancestry scores will be saved to the output file as plain texts.

    Options:
        Set a rectangle area to retrieve subjects from graph of GD2 (y) vs. GD1 (x)
            -xcmin   min x value
            -xcmax   max x value
            -ycmin   min y value
            -ycmax   max y value
            -isByd:  retrieve subjects whose values are beyond the above rectangle

        Set minimum and maximum numbers of genotyped fingerprint SNPs for samples to be processed
            -minsnp  minimum number of SNPs with genotypes
            -maxsnp  maximum number of SNPs with genotypes

        Set population cutoff lines
            -ecut    proportion: cutoff European proportion dividing Europeans from other populations. Default 90%.
            -fcut    proportion: cutoff African proportion dividing Africans from other populations. Default 95%.
                                 Set it to -1 to combine African and African American populations
            -acut    proportion: cutoff East Asian proportion dividing East Asians from other populations. Default 95%.
                                 Set it to -1 to combine East Asian and Other Asian populations
            -ohcut   proportion: cutoff African proportion dividing Latin Americans from Other population. Default 13%.
            -fhcut   proportion: cutoff African proportion dividing Latin Americans from African Americans. Default 40%.

        The input file with self-reported subject race information
            -spf     a file with two columns: subject and self-reported population";

    return $usage;
}