package LoadTairLoci;

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
    my $schema= Bio::Chado::Schema->connect(  sub { $dbh } ,  { on_connect_do => ['SET search_path TO  public;'] }
        );
    my %common_names = CXGN::Tools::Organism::get_all_organisms($dbh, 1);
    my $cname_id = $common_names{Arabidopsis};

    my $file = $self->infile;
    my @lines = read_file( $file ) ;
    shift(@lines);

    my $db = $schema->resultset("General::Db")->find_or_create( {
        name => 'TAIR locus',
        urlprefix => 'http://',
        url => 'arabidopsis.org/servlets/TairObject?type=locus&name=',                                                                });
    foreach my $line (@lines) {
        chomp $line;
        my ($gene_model, $type, $short_desc, $curator_desc, $comp_desc) = split (/\t/ , $line ) ;
        ##AT1G01010.1
        my $annotation;
        $annotation  .= "Type: $type\n" if $type;
        $annotation .= "Curator description: $curator_desc\n" if $curator_desc;
        $annotation .= "Computational description: $comp_desc\n" if $comp_desc;
        my ( $chromosome ) = $gene_model =~ /^AT(\d)G.+/ or next ; #die "**cannot parse AT gene name '$gene_model'\n";
        my ( $locus_symbol ) = $gene_model =~ /(AT\dG\d+)\.\d/ or die "!!cannot parse AT gene name '$gene_model'\n";
        my $locus = CXGN::Phenome::Locus->new_with_symbol_and_species($dbh, $locus_symbol, 'Arabidopsis');
        my $locus_id = $locus->get_locus_id;
        if ($locus->get_locus_id) {
            next if $locus->get_obsolete eq 't';
            print "locus_id = " . $locus->get_locus_id . "name = " . $locus->get_locus_name . "\n";
            my $locus_chr = $locus->get_linkage_group;
            if ($locus_chr && $locus_chr != $chromosome) {
                warn("ERROR: AT chromosome is $chromosome, but the matching locus (id=" . $locus->get_locus_id . ") is on chromosome $locus_chr. Please fix the locus chromosome in the database, or change the AT match\n");
            }elsif (!$locus_chr) {
                print "Updating chromosome = $chromosome for locus_id " . $locus->get_locus_id . "\n";
                $locus->set_linkage_group($chromosome);
                $locus->store;
            }
        } else {
            $locus->set_locus_name($locus_symbol);
            $locus->set_locus_symbol($locus_symbol);
            $locus->set_description($annotation);
            $locus->set_common_name_id($cname_id);
            $locus->set_linkage_group( $chromosome ) if $chromosome;
            $locus->set_sp_person_id('329');
            $locus->store();
            print "STORED new locus $locus_symbol (id = " . $locus->get_locus_id . ")\n";
        }
        $locus_id = $locus->get_locus_id;
        my $at_synonym = CXGN::Phenome::LocusSynonym->new($dbh);
        $at_synonym->set_locus_id($locus_id);
        $at_synonym->set_locus_alias($gene_model);
        $at_synonym->set_preferred('f');
        $at_synonym->store();
        my $alias_id = $locus->add_locus_alias($at_synonym);
        print "Added synonym $gene_model (id = $alias_id) to locus " . $locus->get_locus_symbol . " (id = $locus_id)\n";
        #add the link to TAIR via dbxref
        my $dbxref = $db->find_or_create_related('dbxrefs' , {
            accession => $locus_symbol,
                                                 });
        my $dbxref_object = CXGN::Chado::Dbxref->new($dbh, $dbxref->dbxref_id);
        $locus->add_locus_dbxref($dbxref_object,
                                 undef,
                                 $locus->get_sp_person_id);
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
