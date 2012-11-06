package LoadSolycUnigenes;

use Modern::Perl;
use CXGN::DB::InsertDBH;
use File::Slurp;
use CXGN::Phenome::Locus;
use CXGN::Phenome::Locus::LocusUnigene;
use Try::Tiny;

use Moose;
with 'MooseX::Runnable';
with 'MooseX::Getopt';

has "dbh" => (
    is       => 'rw',
    isa      => 'Ref',
    traits   => ['NoGetopt'],
    required => 0,
);

has "dbhost" => (
    is            => 'rw',
    isa           => 'Str',
    required      => 1,
    traits        => ['Getopt'],
    cmd_aliases   => 'H',
    documentation => 'required, database host',
);

has "dbname" => (
    is            => 'rw',
    isa           => 'Str',
    required      => 1,
    traits        => ['Getopt'],
    documentation => 'required, database name',
    cmd_aliases   => 'D',
);

has "infile" => (
    is            => 'rw',
    isa           => 'Str',
    required      => 1,
    traits        => ['Getopt'],
    documentation => 'required, input file',
    cmd_aliases   => 'i',
);

has 'trial' => (
    is          => 'rw',
    isa         => 'Bool',
    required    => 0,
    default     => 0,
    traits      => ['Getopt'],
    cmd_aliases => 't',
    documentation =>
      'Test run. Rollback the transaction.',
);

sub run {
    my ($self,$name) = @_;

    my $dbh =  CXGN::DB::InsertDBH->new(
	{
	    dbname =>$self->dbname,
	    dbhost => $self->dbhost,
	}
	)->get_actual_dbh();

    $self->dbh($dbh);

    my $file = $self->infile;
    my @lines = read_file( $file ) ;
    foreach my $line (@lines) {
        chomp $line;
        my ($unigene_id, $itag, $description, @annotation) = split (/\t/ , $line ) ;
        $itag =~ /^Solyc0?(\d+)g/ or die "cannot parse itag gene name '$itag'\n";
        $unigene_id =~ s/SGN-U(\d+)/$1/ ;
	my ($solyc_id, $version) = split (/\./ , $itag);
	my $locus = CXGN::Phenome::Locus->new_with_locusname($dbh, $solyc_id);
        if ($locus->get_locus_id) {
	    if ($locus->get_obsolete eq 't') {
		print "**LOCUS $solyc_id is obsolete. Skipping. \n ";
		next;
	    }
        } else {
	    print "NO LOCUS EXISTS for solyc_id $solyc_id adding new locus ($description)!!\n";
	    my $chr = $solyc_id;
	    $chr =~ s/Solyc0?(\d+)g\d+/$1/ ;
	    $locus->set_genome_locus($solyc_id);
	    $locus->set_locus_symbol($solyc_id);
	    $locus->set_locus_name($solyc_id);
	    $locus->set_description($description);
	    $locus->set_linkage_group($chr);
	    $locus->set_common_name_id(1);
	    $locus->set_sp_person_id(329);
	    try { $locus->store ; } catch { warn "cannot store locus $solyc_id\n $_" };
        }
	$locus->add_unigene($unigene_id, "329");
	print "Added unigene $unigene_id to locus " . $locus->get_genome_locus . " (id = " . $locus->get_locus_id . ")\n";
    }
    if ( $self->trial) {
        print "Trial mode! No new unigenes added to the database \n";
        $dbh->rollback;
    } else {
        print "COMMITING\n";
        $dbh->commit;
    }

    return 0;
}


return 1;
