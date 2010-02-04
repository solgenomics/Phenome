#!/usr/bin/env perl
use strict;
use warnings;
use English;
use Carp;
use FindBin;
use Getopt::Std;

use Data::Dumper;

use Bio::FeatureIO;

use CXGN::ITAG::Release;

sub usage {
  my $message = shift || '';
  $message = "Error: $message\n" if $message;
  die <<EOU;
$message
Usage:
  $FindBin::Script

  Script to get some stuff or something. (Naama should rewrite this)

  Options:

    none yet

EOU
}
sub HELP_MESSAGE {usage()}

our %opt;
getopts('',\%opt) or usage();

my ($curr_pipeline) = CXGN::ITAG::Release->find();
$curr_pipeline or die 'no current ITAG pipeline found in base dir '.CXGN::ITAG::Release->releases_root_dir;

my $annotation_file = $curr_pipeline->get_file_info('combi_genomic_gff3')->{file};

open my $loci_matches, "grep ITAG_sgn_loci $annotation_file |"
  or die "$! running grep on $annotation_file";

while (my $line = <$loci_matches> ) {
  chomp $line;
  my ($seq,$source,$type,$start,$end,$score,$dir,$phase,$attrs) = split /\s+/,$line,9;
  next unless $source eq 'ITAG_sgn_loci';
  my %attrs = map split(/(?<=[^\\])=/,$_), split(/(?<=[^\\]);/,$attrs);
  print "got match for $attrs{Name} on $seq from $start to $end\n";
}

