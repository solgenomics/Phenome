package LoadPhylogenesSGN;

use Modern::Perl;
use CXGN::DB::InsertDBH;
use File::Slurp;
use CXGN::Phenome::Locus;
use Bio::Chado::Schema;

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

    #$dbh->{AutoCommit} = 1;
    $self->dbh($dbh);
    my $schema= Bio::Chado::Schema->connect(  sub { $dbh } ,  { on_connect_do => ['SET search_path TO  public;'] }
        );
    
    my $file = $self->infile;
    my @lines = read_file( $file ) ;
   
    my $db = $schema->resultset("General::Db")->find_or_create( {
        name => 'PhyloGenes',
        urlprefix => 'http://',
        url => 'www.phylogenes.org/gene-id/',
								});
    foreach my $line (@lines) {
        chomp $line;
        my ($gene_model, @everything_else ) = split (/\t/ , $line ) ;
	#Solyc04g082310.3 PGSC0003DMG402001235
	my $sgn_locusname = $gene_model;
	if ($gene_model =~ m/Solyc.*/) { 
	    my ($tomato_locus_name, $version)  = split (/\./ , $gene_model ) ;
	    $sgn_locusname = $tomato_locus_name;
	    print STDERR "Found tomato locus $sgn_locusname\n";
	}
        my $locus = CXGN::Phenome::Locus->new_with_locusname($dbh, $sgn_locusname);
        my $locus_id = $locus->get_locus_id;
        if ($locus_id) {
            if ($locus->get_obsolete eq 't') {
		print STDERR "Locus $gene_model is obsolete. Skipping. \n";
		next();
	    }
	} else {
	    print STDERR "No locus exists for ID $gene_model.\n";
	    next();
	}
        #add the link to PhyloGenes via dbxref
	print STDERR "ADDING dbxref \n";
	my $dbxref = $db->find_or_create_related('dbxrefs' , {
            accession => $gene_model,
                                                 });
	my $dbxref_id = $dbxref->dbxref_id();
	my $dbxref_object = CXGN::Chado::Dbxref->new($dbh, $dbxref_id);
	$locus->add_locus_dbxref($dbxref_object,
                                 undef,
                                 $locus->get_sp_person_id);
	print STDERR "Added PhyloGene link dbxref_id=$dbxref_id , locus_id = $locus_id\n ";
    }
    if ( $self->trial) {
        print "Trial mode! rolling back \n";
        $dbh->rollback;
    } else {
        print "COMMITING\n";
        $dbh->commit;
    }
    return 0;
}

return 1;
