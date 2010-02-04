
=head1 NAME

dump_sgn_loci.pl

=head1 DESCRIPTION

Usage: perl dump_sgn_loci.pl -H dbhost -D dbname -o outfile [-n common_name] [-v]

parameters

=over 5

=item -H

hostname for database [required]

=item -D

database name [required]

=item -v

verbose output

=item -n

optional- common_name. Limit results to one organism (e.g. tomato)

=item -o 

output file 


=back


The script dumps sgn loci into a tab delimited file
common_name  locus_id   locus-name   locus_symbol  list of genbank sequence annotations | list of SGN-unigene ids (genbank|SGN-U) 


=head1 AUTHOR

Naama Menda <nm249@cornell.edu>

=head1 VERSION AND DATE

Version 0.1, March 2009.

=cut


#! /usr/bin/perl
use strict;

use Getopt::Std;

use CXGN::Phenome::Locus;
use CXGN::Chado::Organism;

use CXGN::DB::InsertDBH;
use CXGN::Chado::Dbxref;

#use CXGN::Chado::Cvterm;
#use CXGN::Chado::Ontology;
#use CXGN::Chado::Relationship;

our ($opt_H, $opt_D, $opt_v, $opt_o, $opt_n);

getopts('D:H:n:o:f');
my $dbhost = $opt_H;
my $dbname = $opt_D;

if (!$dbhost && !$dbname) { die "Need -D dbname and -H hostname arguments.\n"; }

my $error = 0; # keep track of input errors (in command line switches).
if (!$opt_D) { 
    print STDERR "Option -D required. Must be a valid database name.\n";
    $error=1;
}

print STDERR "$opt_D, $opt_H, $opt_n, $opt_o\n";
my $file = $opt_o;

if (!$file) { 
    print STDERR "A file is required as a command line argument.\n";
    $error=1;
}

die "Some required command lines parameters not set. Aborting.\n" if $error;

open (OUT, ">$opt_o") ||die "can't open error file $file for writting.\n" ;


my $dbh = CXGN::DB::InsertDBH->new( { dbhost=>$dbhost,
				     dbname=>$dbname,  
				   } );


print STDERR "Connected to database $dbname on host $dbhost.\n";
my $query = "SELECT locus_id FROM phenome.locus";
$query .= " WHERE common_name_id = (SELECT common_name_id FROM sgn.common_name where common_name ilike ?) " if $opt_n;
$query .= " ORDER BY locus_id";
my $common_name = $opt_n || undef;
my $count=0;
my $sth=$dbh->prepare($query);
$sth->execute($common_name);
print OUT "common_name\tlocus_id\tlocus_name\tlocus_symbol\tSGN-unigenes\tGenBank accessions\n";
while (my ($locus_id) = $sth->fetchrow_array()) {
    my $count++;
    my $locus=CXGN::Phenome::Locus->new($dbh, $locus_id) ;
    my $symbol=$locus->get_locus_symbol();
    my $name= $locus->get_locus_name();
    my $common_name = $locus->get_common_name();
    my @u_objects= $locus->get_unigenes(); #unigene ids 
    my @unigenes = map {'SGN-U' . $_->get_unigene_id()  } @u_objects;
    my $unigene_string= join '|', @unigenes;
    my @dbxrefs= $locus->get_dbxrefs_by_type('genbank'); #dbxref objects
    
    my @gb_accs= map {$_->get_feature()->get_uniquename()  }  @dbxrefs;
    my $gb_string = join '|', @gb_accs; 
    print OUT "$common_name \t $locus_id \t $name \t $symbol \t $unigene_string \t $gb_string \n";
    print STDERR "$common_name \t $locus_id \t $name \t $symbol \t $unigene_string \t $gb_string \n";

}


close OUT;

print STDERR "Found $count loci.\n printed into out file $file... Done.\n";



