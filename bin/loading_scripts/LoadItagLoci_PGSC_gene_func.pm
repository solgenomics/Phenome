package LoadItagLoci_PGSC_gene_func;

=head1 NAME

  LoadItagLoci - reads potato loci data from GFF and loads (or updates) them into the database

=head1 SYNOPSIS

Invoke this module directly with mx-run (MooseX::Runnable):

  mx-run LoadItagLoci_PGSC_gene [options] <file>


Note, you may need to include the following two libraries:
    -I$HOME/cxgn/Phenome/lib
    -I$HOME/cxgn/sgn/lib

=head1 DESCRIPTION

The script(?) uses CXGN::DB::InsertDBH to connect to the database, so
it will prompt for a username and password when run.

I'm guessing the appropriate tables have to already exist in the given
database?

=head2 OPTIONS

=over 12

=item --dbhost, -H

The host you want to connect to.

=item --dbname, -D

The database that you want to load into.

=back

=head1 AUTHOR

Naama and Dan

=head1 SEE ALSO

CXGN::DB::InsertDBH
CXGN::DB::Connection

=cut

use Modern::Perl;
use CXGN::DB::InsertDBH;
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
      'optional, test run. Rollback the transaction.',
);

sub run {
    my ($self,$name) = @_;

    my $dbh = CXGN::DB::InsertDBH->
      new({ dbname =>$self->dbname,
            dbhost => $self->dbhost,
          })->get_actual_dbh();

    $self->dbh($dbh);

    ## This 'just works'
    my %common_names = CXGN::Tools::Organism::get_existing_organisms($dbh, 1);
    my $potato_cname_id = $common_names{Potato};

    my $file = $self->infile;
    open INFILE, '<', $file
      or die "cant open file '$file' for reading : $!\n";

    while (<INFILE>) {
        chomp;
        my ($seq_id, $source, $type, $start, $end,
            $score, $strand, $phase, $attrs
           ) = split/\t/;

        next unless $type eq 'gene';

        ## Gene ID
        $attrs =~ /(?:;|\t)ID=(PGSC0003DMG4\d{8})(?:;|$)/
          or die "cant recognize gene id in '$attrs'\n";
        my $gene_id = $1;

        # For now...
        my $itag = $gene_id;

        ## Chromosome
        $seq_id =~ /^ST3-2.1.9ch(\d\d)$/
          or die "cant recognize chromosome in '$seq_id'\n";
        my $chromosome = $1;

         my $locus = CXGN::Phenome::Locus->
          new_with_symbol_and_species($dbh, $itag, 'Potato');



        ## Update
        if (my $locus_id = $locus->get_locus_id){
            ## Dont bother to update obsolete loci (I guess)
            next if $locus->get_obsolete eq 't';

            print
              "Updating locus_id $locus_id, name = ". $locus->get_locus_name. "\n";

            my $locus_chr = $locus->get_linkage_group;
            if (defined( $locus_chr ) && $locus_chr != $chromosome){
                warn
                  "ERROR: $locus_id is on ITAG Chr. $locus_chr, but the ".
                    "locus is on chromosome $chromosome.\n";
            }
            elsif (!defined( $locus_chr )){
                print
                  "Updating chromosome = $chromosome for locus_id $locus_id\n";
                $locus->set_linkage_group($chromosome);
                $locus->store;
            }
        }

        ## Create
        else {
            ## Debugging
            die "how did we get here?\n";

            $locus->set_locus_name($itag);
            $locus->set_locus_symbol($itag);
            # TODO: get this from the 'Note' attribute
            #$locus->set_description($annotation);
            $locus->set_common_name_id($potato_cname_id);
            $locus->set_linkage_group( $chromosome ) if defined( $chromosome );
            $locus->set_sp_person_id('1203');

            $locus->store();

            my $locus_id = $locus->get_locus_id;
            print "STORED new locus $itag (id = $locus_id)\n";

            # Add a synonym
            my $itag_synonym = CXGN::Phenome::LocusSynonym->new($dbh);
            $itag_synonym->set_locus_id($locus_id);
            $itag_synonym->set_locus_alias($itag);
            $itag_synonym->set_preferred('f');
            $itag_synonym->store();

            my $alias_id = $locus->add_locus_alias($itag_synonym);
            print
              "Added synonym $itag (id = $alias_id) to locus ".
              $locus->get_locus_symbol. " (id = $locus_id)\n";

        }

        # Debugging
        last;
    }

    if ( $self->trial) {
        print
          "Trial mode! Not storing in the database \n";
        $dbh->rollback;
    }
    else {
        print "COMMITING\n";
        $dbh->commit;
    }

    return 0;
}

return 1;
