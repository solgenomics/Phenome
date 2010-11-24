package LoadItagLoci;

use Modern::Perl;
use CXGN::DB::InsertDBH;
use File::Slurp;
use CXGN::Phenome::Locus;
use CXGN::Phenome::LocusSynonym;
use CXGN::Tools::Organism;

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

    my %common_names = CXGN::Tools::Organism::get_existing_organisms($dbh, 1);
    my $tomato_cname_id = $common_names{Tomato};

    my $file = $self->infile;
    my @lines = read_file( $file ) ;
    foreach my $line (@lines) {
        my ($locus_id, $itag, $annotation) = split (/\t/ , $line ) ;
        my $locus = CXGN::Phenome::Locus->new($dbh, $locus_id);
        if ($locus->get_locus_id) {
            my $itag_synonym = CXGN::Phenome::LocusSynonym->new($dbh);
            $itag_synonym->set_locus_id($locus_id);
            $itag_synonym->set_locus_alias($itag);
            $itag_synonym->store();
            my $alias_id = $locus->add_locus_alias($itag_synonym);
            print "Added synonym $itag (id = $alias_id) to locus " . $locus->get_locus_symbol . " (id = $locus_id)\n";
        } else {
            $locus->set_locus_name($itag);
            $locus->set_locus_symbol($itag);
            $locus->set_description($annotation);
            $locus->set_common_name_id($tomato_cname_id);
            $locus->set_sp_person_id('329');
            $locus->store();
            print "STORED new locus $itag (id = " . $locus->get_locus_id . ")\n";
        }
    }
    if ( $self->trial) {
        print "Trial mode! Not locus synonyms and new loci in the database \n";
        $dbh->rollback;
    } else {
        $dbh->commit;
    }

    return 0;
}


return 1;
