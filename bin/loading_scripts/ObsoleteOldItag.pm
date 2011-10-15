package ObsoleteOldItag;

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
    my $species ='Tomato';
    my %common_names = CXGN::Tools::Organism::get_existing_organisms($dbh, 1);
    my $tomato_cname_id = $common_names{$species};

    my $file = $self->infile;
    my @lines = read_file( $file ) ;
    ITAG: foreach my $line (@lines) {
        chomp $line;
        my ($itag, $annotation) = split (/\t/ , $line ) ;
        my ( $chromosome ) = $itag =~ /^Solyc0?(\d+)g/ or die "cannot parse itag gene name '$itag'\n";
        my $locus =  CXGN::Phenome::Locus->new_with_symbol_and_species($dbh, $itag,$species);
        my $locus_id = $locus->get_locus_id;
        if ( !$locus_id)  {
            #no locus_id
            #check if the locus_symbol was linked to an existing locus , and is now a synonym
            my $q = "Select locus_id from phenome.locus_alias where alias ilike ? and preferred = false";
            my $sth = $dbh->prepare($q);
            $sth->execute($itag);
            ($locus_id) = $sth->fetchrow_array; # should be one match
            if ($locus_id) { $locus = CXGN::Phenome::Locus->new($dbh, $locus_id) ; }
            else { warn "NO LOCUS FOUND FOR IDENTIFIER $itag!!\n\n"; next ITAG ; }
        }
        next if $locus->get_obsolete eq 't'; #locus is already obsolete
        #now we should have locus_id from symbol or synonym
        if ($locus_id) {
            print "locus_id = " . $locus->get_locus_id . "name = " . $locus->get_locus_name . "\n";
            $locus->set_obsolete('t');
            $locus->set_updated_by('329');
            $locus->store();
            print "Obsoleted locus $itag (id = " . $locus->get_locus_id . ")\n";
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
