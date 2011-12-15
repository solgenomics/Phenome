package UpdatePotatoPgLoci;

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

has 'schema' => (
    is       => 'rw',
    isa      => 'DBIx::Class::Schema',
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
    my $schema= Bio::Chado::Schema->connect(  sub { $dbh } ,  { on_connect_do => ['SET search_path TO  public;'] } );
    $self->schema($schema);

    my %common_names = CXGN::Tools::Organism::get_existing_organisms($dbh, 1);
    my $potato_cname_id = $common_names{Potato};
    my ($organism) = $schema->resultset("Organism::Organism")->search(
        { species = 'Solanum tuberosum' } );

    my $file = $self->infile;
    my @lines = read_file( $file ) ;
    foreach my $line (@lines) {
        chomp $line;
        my ($locus_id, $genome_locus, $annotation, $chromosome) = split (/\t/ , $line ) ;
        my $locus = CXGN::Phenome::Locus->new($dbh, $locus_id);
        $locus->set_genome_locus($genome_locus);
        ###### $locus->set_organism_id($organism->organism_id); ## run db patch first!
        if ($locus->get_locus_id) {
            next if $locus->get_obsolete eq 't';
            print "locus_id = " . $locus->get_locus_id . "name = " . $locus->get_locus_name . "\n";
            my $locus_chr = $locus->get_linkage_group;
            if ($locus_chr && $locus_chr != $chromosome) {
                warn("ERROR: genome chromosome is $chromosome, but the matching locus (id=" . $locus->get_locus_id . ") is on chromosome $locus_chr. Please fix the locus chromosome in the database, or change the genome match\n");
            }elsif (!$locus_chr) {
                print "Updating chromosome = $chromosome for locus_id " . $locus->get_locus_id . "\n";
                $locus->set_linkage_group($chromosome);
                $locus->store;
            }
        } else {
            $locus->set_locus_name($genome_locus);
            $locus->set_locus_symbol($genome_locus);
            $locus->set_description($annotation);
            $locus->set_common_name_id($potato_cname_id);
            #$locus->set_organism_id($organism->organism_id); ##run the db patch 
            $locus->set_linkage_group( $chromosome ) if $chromosome;
            $locus->set_sp_person_id('329');
            $locus->store();
            print "STORED new locus $genome_locus (id = " . $locus->get_locus_id . ")\n";
        }
    }
    if ( $self->trial) {
        print "Trial mode! Not loadinglocus synonyms and new loci in the database \n";
        $dbh->rollback;
    } else {
        print "COMMITING\n";
        $dbh->commit;
    }

    return 0;
}


return 1;
