#!/usr/bin/perl -w
use strict;
use Getopt::Long;
use CXGN::Phenome::Locus;
use CXGN::Transcript::Unigene;

my ( $help, $dbname, $dbhost, $outfile );

#GetOptions(
#
# 	   'h' => \$help,
# 	   'dbname=s' => \$dbname,
#            'dbhost=s' => \$dbhost,
# 	   'o=s' => \$outfile,
# 	   );

if ($help) {
    print <<EOF;

  Program to create a FASTA file with loci-related sequnces.
  Currently from SGN unigenes and GenBank accessions (stored in public.feature).
  FASTA .seq file should be saved in the ftp site where a nightly cron job runs formatdb 
  on updated files.

  Usage:

   
    -o <output filename>  - output FASTA file.
    -dbhost <server hostname>  - host running the database to be queried
    -dbname - name of the database (sandbox, cxgn...)
   
    -t <title>            - BLAST database title for formatdb
   
EOF
    exit -1;
}

#print "enter your password\n";

#my $pass= <STDIN>;
#chomp $pass;

my $dbh = CXGN::DB::Connection->new();
$dbh->add_search_path(qw/ sgn phenome /);

open OF, ">/data/prod/ftpsite/loci/loci_sequences.fasta"
  or die "Can't open output file  ($!)";

my $loci_query = "SELECT locus_id FROM phenome.locus";
my $sth        = $dbh->prepare($loci_query);
$sth->execute();
while ( my ($locus_id) = $sth->fetchrow_array() ) {
    my $locus       = CXGN::Phenome::Locus->new( $dbh, $locus_id );
    my $common_name = $locus->get_common_name();
    my @unigenes    = $locus->get_unigenes(1);
    foreach my $unigene_obj (@unigenes) {
        my $sgn_id      = $unigene_obj->get_sgn_id();
        my $unigene_seq = $unigene_obj->get_sequence();
        my $header = $common_name . "_SGNlocusID_" . $locus_id . "_" . $sgn_id;
        if ( $unigene_seq && length($unigene_seq) < 20000 ) {
            print OF ">$header\n$unigene_seq\n";
        }
    }
    my @locus_dbxrefs = $locus->get_dbxrefs();
    foreach my $dbxref (@locus_dbxrefs) {

        eval {
            my $feature   = $dbxref->get_feature();
            my $accession = $feature->get_uniquename();
            my $seq       = $feature->get_residues();
            my $length    = $feature->get_seqlen();
            if ( $seq && ( length($seq) < 20000 ) ) {
                my $header =
                  $common_name . "_SGNlocusID_" . $locus_id . "_" . $accession;
                print OF ">$header\n$seq\n";
            }
        };
        if ($@) { print $@; }

    }
}

close OF;

#system("formatdb -p F -i ${output_fname}.seq -n $output_fname -t \"$title\"");
