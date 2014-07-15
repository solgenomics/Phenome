package LoadPepperLoci;

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
    my $pepper_cname_id = $common_names{Pepper};

    my $file = $self->infile;
    my @lines = read_file( $file ) ;
    foreach my $line (@lines) {
        chomp $line;
        ## ID=mRNA.CA01g01690;Parent=CA01g01690;Note="Transmembrane protein TPARL%2C putative"
        my ($id, $parent, $annotation) = split (/;/ , $line ) ;
        my ( $chromosome ) = $parent =~ /^Parent=CA0?(\d+)g/ or die "cannot parse pepper gene name '$parent'\n";
        my ( $gene_model ) =  $parent =~ /^Parent=(CA0?\d+g\d+)/ or die "Cannot parse pepper gene model id '$parent'\n";
        my ( $desc ) = $annotation =~ /^Note="(.*)"/ or die "Cannot parse annotation '$annotation'\n";
        my $locus = CXGN::Phenome::Locus->new_locusnmae($dbh, $gene_model);
        if ($locus->get_locus_id) {
            next if $locus->get_obsolete eq 't';
            print "locus_id = " . $locus->get_locus_id . "name = " . $locus->get_locus_name . "\n";
            my $locus_chr = $locus->get_linkage_group;
            if ($locus_chr && $locus_chr != $chromosome) {
                warn("ERROR: Pepper chromosome is $chromosome, but the matching locus (id=" . $locus->get_locus_id . ") is on chromosome $locus_chr. Please fix the locus chromosome in the database, or change the match in your gff3 file\n");
            }elsif (!$locus_chr) {
                print "Updating chromosome = $chromosome for locus_id " . $locus->get_locus_id . "\n";
                $locus->set_linkage_group($chromosome);
                $locus->store;
            }
            my $locus_id = $locus->get_locus_id;
            my $itag_synonym = CXGN::Phenome::LocusSynonym->new($dbh);
            $itag_synonym->set_locus_id($locus_id);
            $itag_synonym->set_locus_alias($gene_model);
            $itag_synonym->set_preferred('f');
            $itag_synonym->store();
            my $alias_id = $locus->add_locus_alias($itag_synonym);
            print "Added synonym $gene_model (id = $alias_id) to locus " . $locus->get_locus_symbol . " (id = $locus_id)\n";
        } else {
            $locus->set_locus_name($gene_model);
            $locus->set_locus_symbol($gene_model);
            $locus->set_description($desc);
            $locus->set_common_name_id($pepper_cname_id);
            $locus->set_linkage_group( $chromosome ) if $chromosome;
            $locus->set_sp_person_id('4944'); # this is Surya's ID. Should be changed to someone from the pepper genome project
            $locus->store();
            print "STORED new locus $gene_model (id = " . $locus->get_locus_id . ")\n";
        }
    }
    if ( $self->trial) {
        print "Trial mode! Not locus synonyms and new loci in the database \n";
        $dbh->rollback;
    } else {
        print "COMMITING\n";
        $dbh->commit;
    }

    return 0;
}


return 1;
