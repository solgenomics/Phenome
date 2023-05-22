#!/usr/bin/perl

=head1

update_locus_annotations.pl

=head1 SYNOPSIS

    update_locus_annotationss.pl -H [dbhost] -D [dbname] -i [infile]

=head1 COMMAND-LINE OPTIONS
  ARGUMENTS
 -H host name (required) e.g. "localhost"
 -D database name (required) e.g. "sandbox"
 -i path to infile (required)

=head1 DESCRIPTION

This script updates locus annotations associated with obsolete cvterms to the current ones.
The infile provided has two columns, in the first column is the cvterm accession as it is in the database (e.g. GO:0075177),
and in the second column is the new cvterm accession ( e.g. GO:0075178) .
There is no header on the infile and the infile is .xls or .xlsx.


=head1 AUTHOR

 Naama Menda (nm249@cornell.edu)

=cut

use strict;

use Getopt::Std;
use Data::Dumper;
use Carp qw /croak/ ;
use Pod::Usage;
use Spreadsheet::ParseExcel;
use Spreadsheet::ParseXLSX;
use Bio::Chado::Schema;
use CXGN::Phenome::Schema;
use CXGN::Phenome::LocusDbxref;
use CXGN::DB::InsertDBH;
use Try::Tiny;

our ($opt_H, $opt_D, $opt_i, $opt_t);

getopts('H:D:ti:');

if (!$opt_H || !$opt_D || !$opt_i ) {
    pod2usage(-verbose => 2, -message => "Must provide options -H (hostname), -D (database name), -i (input file) \n");
}

my $dbhost = $opt_H;
my $dbname = $opt_D;

# Match a dot, extension .xls / .xlsx
my ($extension) = $opt_i =~ /(\.[^.]+)$/;
my $parser;

if ($extension eq '.xlsx') {
	$parser = Spreadsheet::ParseXLSX->new();
}
else {
	$parser = Spreadsheet::ParseExcel->new();
}

my $excel_obj = $parser->parse($opt_i);

my $dbh = CXGN::DB::InsertDBH->new({
	dbhost=>$dbhost,
	dbname=>$dbname,
	dbargs => {AutoCommit => 0, RaiseError => 1}
});

my $schema= Bio::Chado::Schema->connect(  sub { $dbh->get_actual_dbh() } );

my $phenome_schema= CXGN::Phenome::Schema->connect( sub { $dbh->get_actual_dbh } , { on_connect_do => ['set search_path to public,phenome;'] }  );

my $worksheet = ( $excel_obj->worksheets() )[0]; #support only one worksheet
my ( $row_min, $row_max ) = $worksheet->row_range();
my ( $col_min, $col_max ) = $worksheet->col_range();

my $coderef = sub {
  for my $row ( 0 .. $row_max ) {

    	my $db_cvterm = $worksheet->get_cell($row,0)->value();
    	my $file_cvterm = $worksheet->get_cell($row,1)->value();

	    my ($old_db_name, $old_accession ) = split ":", $db_cvterm ;
    	my ($new_db_name, $new_accession ) = split ":" , $file_cvterm;


	    my $old_dbxref = $schema->resultset('General::Dbxref')->find(
	    {
		      'db.name'          => $old_db_name,
		      'accession' => $old_accession,
	    },
	    { join =>  'db'  }
      ) ;
	if ( !defined $old_dbxref ) {
	    print STDERR "Cannot find cvterm $db_cvterm in the database! skipping\n";
	    next();
	}
  my $new_dbxref;
  if ($new_db_name ne 'DELETE' ) {
      $new_dbxref = $schema->resultset('General::Dbxref')->find(
	    {
		      'db.name'          => $new_db_name,
          'accession' => $new_accession,
          'cvterm.cvterm_id' => \("IS NOT NULL"),
	    },
	    { join => ['db', 'cvterm'] }
	    );
      if ( !defined $new_dbxref ) {
    	    print STDERR "Cannot find cvterm $file_cvterm in the database! skipping\n";
    	    next();
      }
  }
  my $locus_dbxref = $phenome_schema->resultset('LocusDbxref')->search(
	    {
		      dbxref_id  => $old_dbxref->dbxref_id,
          obsolete   => "0",
	    } ) ;
  my $count = $locus_dbxref->count();
  print STDERR "Found $count locus annotations with obsolete cvterm $db_cvterm\n";

  for my $ld ($locus_dbxref->all) {
        my $ld_id = $ld->get_column('locus_dbxref_id');
        my $locus_dbxref_obj = CXGN::Phenome::LocusDbxref->new($dbh, $ld_id);
        print STDRRR "locus_dbxref_id = $ld_id\n\n";
        if ($new_dbxref && $count>0) {
          #if a locus_dbxref already exists for the new dbxref - the old annotation will be obsolete
          $locus_dbxref_obj->update_annotation($new_dbxref->dbxref_id);
          print STDERR "Updating old ID $db_cvterm with new ID $file_cvterm\n";
        } elsif (!$new_dbxref && $count>0) {
          print STDERR "Obsoleting cvterm $db_cvterm from locus_dbxref\n";
          $locus_dbxref_obj->obsolete();
        }
    }
  }
};

my $transaction_error;
try {
    $schema->txn_do($coderef);
} catch {
    $transaction_error =  $_;
};

if ($transaction_error || $opt_t) {
    $dbh->rollback;
      if ($transaction_error) {
        print STDERR "Transaction error storing terms: $transaction_error\n";
      }
      if ($opt_t ) {
        print STDERR "Test mode: rolling back\n";
      }
} else {
    print STDERR "Committing updates.\n";
    $dbh->commit;
}
