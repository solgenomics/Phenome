
=head1 NAME

update_locus_unigenes.pl

=head1 Synopsis

When a new unigene build is released the associated loci must be updated to the current unigenes.
The page locus_display shows only associated unigenes from the locus_unigene table that are from a current build.


=head2 Usage

perl update_loci_unigenes.pl -D dbname -H dbhost   -t [test mode] [-v]

=over 4

=item -D 
db name

=item -H 
host name

=item -v
verbose output

=item -t 
trail mode. Rolling back transaction at end of script

=back 


=cut



#!/usr/bin/perl
use strict;

use CXGN::Phenome::Locus;
use CXGN::Phenome::Locus::LocusUnigene;
use CXGN::DB::InsertDBH;
use CXGN::Transcript::Unigene;

use Getopt::Std;


our ($opt_H, $opt_D, $opt_v,$opt_t);

getopts('vtH:D:');

my $dbhost = $opt_H;
my $dbname = $opt_D;
my $help;

if (!$dbhost && !$dbname) { 
    print  STDERR "Need -D dbname and -H hostname arguments.\n"; 
    exit();
}
if ($opt_t) { 
    print STDERR "Trial mode - rolling back all changes at the end.\n";
}

my $dbh = CXGN::DB::InsertDBH->new( { dbhost=>$dbhost,
				      dbname=>$dbname,
                                      dbschema => 'phenome', 
				      dbargs => {AutoCommit => 0,
						 RaiseError => 1}
				  }
				    );

$dbh->add_search_path(qw/public phenome sgn/);

print STDERR "Connected to database $dbname on host $dbhost.\n";


#########################################################################
#select all the locus-unigene entries that need to be updated
my $query= "SELECT locus_unigene_id FROM phenome.locus_unigene 
            JOIN sgn.unigene USING (unigene_id) 
            JOIN sgn.unigene_build USING (unigene_build_id) 
            WHERE status != 'C'
            AND obsolete ='f'";
my $sth=$dbh->prepare($query);

$sth->execute();
my $unigene_count=0;
my $old_count=0;

eval {
    while (my ($lu_id)= $sth->fetchrow_array()  ) {
	$old_count++;
	my $old_lu=CXGN::Phenome::Locus::LocusUnigene->new($dbh, $lu_id);
	my $unigene= CXGN::Transcript::Unigene->new($dbh, $old_lu->get_unigene_id());
	foreach my $cu_id ($unigene->get_current_unigene_ids() ) {
	    my $new_lu=CXGN::Phenome::Locus::LocusUnigene->new($dbh);
	    $new_lu->set_locus_id($old_lu->get_locus_id());
	    $new_lu->set_sp_person_id($old_lu->get_sp_person_id());
	    $new_lu->set_unigene_id($cu_id);
	    $new_lu->store();
	    $unigene_count++;
	    print STDERR "Storing new unigene_id $cu_id for locus ". $old_lu->get_locus_id() . " (replacing old unigene_id " . $old_lu->get_unigene_id . "). \n";
	}
    }
};

if($@) {
    print $@;
    print"Failed; rolling back.\n";
    $dbh->rollback();
}else{ 
    print"Succeeded.\n";
    print "inserted $unigene_count locus-unigene associations (updating $old_count unigenes)\n";
    if(!$opt_t) {
        print "committing .\n";
	$dbh->commit();
    }else{
	print "Running trial mode- Rolling back!\n ";
        $dbh->rollback();
    }
}

sub message {
    my $message=shift;
    print ERR $message;
    if ($opt_v) { print STDERR $message  ; }
}
