#!/usr/bin/perl -w
use strict;
use Getopt::Long;
use CXGN::Phenome::Locus;
use CXGN::Transcript::Unigene;
use Bio::Chado::Schema;
use SGN::View::Feature;
use File::Slurp ;

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

my $schema= Bio::Chado::Schema->connect(  sub { $dbh->get_actual_dbh } ,  { on_connect_do => ['SET search_path TO  public, phenome;'] } );

my $filename =  "/data/prod/ftpsite/loci/loci_sequences.fasta";
#
write_file( $filename, '');
#  or die "Can't open output file  ($!)";
my @lines ;

my $loci_query = "SELECT locus_id FROM phenome.locus WHERE obsolete = 'f' ";
my $sth        = $dbh->prepare($loci_query);
$sth->execute();
while ( my ($locus_id) = $sth->fetchrow_array() ) {
    my $locus       = CXGN::Phenome::Locus->new( $dbh, $locus_id );
    my $common_name = $locus->get_common_name();
    my @unigenes    = $locus->get_unigenes( { full=>1, current=>1} );
    #get the sequences of the unigenes
    foreach my $unigene_obj (@unigenes) {
        my $sgn_id      = $unigene_obj->get_sgn_id();
        my $unigene_seq = $unigene_obj->get_sequence();
        my $header = $common_name . "_SGNlocusID_" . $locus_id . "_" . $sgn_id;
        if ( $unigene_seq && length($unigene_seq) < 20000 ) {
	    write_file( $filename, {append => 1 }, ">$header\n$unigene_seq\n" );
	    $| = 1;
#push @lines ,  ">$header\n$unigene_seq\n";
        }
    }
    #get the sequences of the linked genbank accessions
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
		write_file( $filename, {append => 1 }, ">$header\n$seq\n" );
		#push @lines , ">$header\n$seq\n";
            }
        };
        if ($@) { print $@; }

    }
    #get the ITAG gene model sequences
    my $genome_locus = $locus->get_genome_locus;
    if ($genome_locus) {
	my ($feature) = $schema->resultset("Sequence::Feature")->search(
            {
                'me.name'  => { 'like' => $genome_locus . '%' },
                'type.name'=> 'mRNA',
            } ,
            { prefetch => 'type'   },
            );
        if ($feature) {
	    my $header = $common_name . "_SGNlocusID_" . $locus_id . "_" . $genome_locus;
            #for my $seq_ref ( SGN::View::Feature::mrna_cds_protein_sequence($feature) ) {  
	    #my $mrna_seq = $seq_ref->[0];
	    my $mrna_seq = $feature->residues;
	    write_file( $filename, {append => 1 }, ">$header\n$mrna_seq\n" );
	  #  push @lines ,  ">$header\n$mrna_seq\n";
	}
    }
}

#close OF;

#system("formatdb -p F -i ${output_fname}.seq -n $output_fname -t \"$title\"");
