package updatePotatoGenomeLocus;

use Modern::Perl;
use CXGN::DB::InsertDBH;
use File::Slurp;
use CXGN::Phenome::Locus;
use CXGN::Phenome::LocusSynonym;
use CXGN::Tools::Organism;
use CXGN::Phenome::Schema;

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
	    dbuser=>"postgres",
	    dbtype => "Pg"
	}
	)->get_actual_dbh();

    $self->dbh($dbh);
    my $schema= Bio::Chado::Schema->connect(  sub { $dbh } ,  { on_connect_do => ['SET search_path TO  public;'] } );
    $self->schema($schema);
    my $phenome_schema = CXGN::Phenome::Schema->connect( sub {$dbh } , { on_connect_do => ['SET search_path TO phenome;'] } ) ;
   
    my ($organism) = $schema->resultset("Organism::Organism")->search(
	{ species => 'Solanum tuberosum' } );
    my $potato_id = $organism->organism_id;
    
    my $potato_rs = $phenome_schema->resultset("Locus")->search(
	{ organism_id => $potato_id,
	  locus_name => { 'ILIKE' => 'PGSC0003DMG%' },
	  locus => { 'IS' => undef}  } );
    
    while (my $potato_locus = $potato_rs->next) {
	my $locus_name = $potato_locus->locus_name;
	print STDERR "Updating locus $locus_name \n";
        $potato_locus->locus($locus_name);
	$potato_locus->update;
    }
    if ( $self->trial) {
        print "Trial mode! Not updating genome locus  \n";
        $dbh->rollback;
    } else {
        print "COMMITING\n";
        $dbh->commit;
    }
    return 0;
}

return 1;
