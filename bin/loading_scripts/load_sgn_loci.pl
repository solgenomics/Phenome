#!/usr/bin/perl
use strict;
use CXGN::DB::Connection;
use CXGN::Phenome::Locus;
use CXGN::Phenome::LocusSynonym;

use CXGN::Chado::Feature;
use CXGN::Chado::Dbxref;
use CXGN::Chado::Publication;
use CXGN::Tools::FeatureFetch;
use CXGN::Tools::Pubmed;

use Getopt::Long;

CXGN::DB::Connection->verbose(0);

# replaced by update_sgn_loci.pl!!

unless ( $ARGV[0] eq 'scopolamine' or $ARGV[0] eq 'hyoscine' ) {
    die "First argument must be valid database host";
}
unless ( $ARGV[1] eq 'sandbox'
    or $ARGV[1] eq 'cxgn_tmp'
    or $ARGV[1] eq 'schematest' )
{
    die "Second argument must be valid database name";
}
unless ( $ARGV[2] eq 'COMMIT' or $ARGV[2] eq 'ROLLBACK' ) {
    die 'Third argument must be either COMMIT or ROLLBACK';
}

my ( $organism, $infile, $sp_person, $help, $dbname, $dbhost );
GetOptions(
    'o=s'      => \$organism,
    'i=s'      => \$infile,
    'h'        => \$help,
    'u=s'      => \$sp_person,
    'dbname=s' => \$dbname,
    'dbhost=s' => \$dbhost,
);
if ( !$organism || !$infile ) {
    $help = 1;
    print "\n You must provide an organism name and and infile!\n";
}

if ($help) {

    print <<EOT;

Options:

-o   set SGN organism name
-i   infile
-u   set SGN user name
-h   output this help message


--dbname  set database name (cxgn or sandbox)
--dbhost  set dbhost (scopolamine or hyoscine)

EOT
    exit;

}

print "enter your password\n";

my $pass = <STDIN>;
chomp $pass;

my $dbh = CXGN::DB::Connection->new(
    {
        dbname   => $ARGV[1],
        dbschema => "phenome",
        dbhost   => $ARGV[0],
        dbuser   => "postgres",
        dbpass   => $pass,
        dbargs   => { AutoCommit => 0 }
    }
);

$dbh->add_search_path(qw/public utils tsearch2 /);

if ( !$sp_person ) { $sp_person = 'nm249'; }
my $sp_person_sth = $dbh->prepare(
    "SELECT sp_person_id FROM sgn_people.sp_person WHERE username ilike ?");
$sp_person_sth->execute($sp_person);
my ($sp_person_id) = $sp_person_sth->fetchrow_array();

if ( !$sp_person_id ) {

    print "ERROR: Invalid SGN username \"$sp_person\"!! \n";
    exit;
}

my $organism_sth = $dbh->prepare(
    "SELECT common_name_id FROM sgn_bt.common_name WHERE common_name ilike ?");
$organism_sth->execute($organism);
my ($organism_id) = $organism_sth->fetchrow_array();

if ( !$organism_id ) {

    print "ERROR: Invalid SGN organism common name \"$organism\"!! \n";
    exit;
}

my %name2id     = ();    #hash for retrieving existing locus ids and names
my %dbxref_hash = ()
  ; #retrieve dbxref_id - accession connections for solanaceae phenotype ontology

my $loci_query =
"SELECT locus_id, locus_name, locus_symbol FROM phenome.locus where common_name_id=?";
my $sth = $dbh->prepare($loci_query);
$sth->execute($organism_id);
while ( my ( $id, $locus_name, $locus_symbol ) = $sth->fetchrow_array() ) {
    $name2id{ ($locus_name) } = $id;
}

#####################
my $locus_dbxref =
"SELECT locus_id, dbxref_id FROM phenome.locus_dbxref WHERE  locus_id =? AND dbxref_id=(SELECT dbxref_id FROM public.dbxref JOIN public.db USING (db_id) WHERE accession = ? AND db.name= ?)";
my $check_dbxref_sth = $dbh->prepare($locus_dbxref);

#$dbxref_sth->execute();
#while (my ($accession, $id) = $dbxref_sth->fetchrow_array() ) { $dbxref_hash{$accession} = $id; }

#query for storing a new locus
my $locus_sth = $dbh->prepare(
"INSERT INTO phenome.locus (locus_name, locus_symbol, gene_activity, locus_notes, sp_person_id, description, linkage_group,  common_name_id) VALUES (?,?,?,?,?,?,?, ?)"
);

#storing the locus synonyms. The locus symbol is entered as the 'prefered' synonym
my $alias_sth = $dbh->prepare(
"INSERT INTO phenome.locus_alias (alias, locus_id, preferred, sp_person_id) VALUES (?,?,?,329)"
);

#store an allele
my $allele_sth = $dbh->prepare(
"INSERT INTO phenome.allele (locus_id, allele_symbol, sp_person_id) VALUES (?, ?)"
);

#store a marker
my $marker_sth = $dbh->prepare(
"INSERT INTO phenome.locus_marker (locus_id, marker_id) VALUES (?, (SELECT marker_id from sgn_bt.markers where marker_name= ?))"
);

my $locus_dbxref_sth = $dbh->prepare(
"INSERT into phenome.locus_dbxref (locus_id, dbxref_id) VALUES (?, (SELECT dbxref_id FROM public.dbxref JOIN public.db USING (db_id) WHERE accession = ? AND db.name= ?))"
);

my $check_dbxref = $dbh->prepare(
"SELECT dbxref_id FROM public.dbxref JOIN public.db USING (db_id) WHERE accession= ? AND db.name = ?"
);

#check if this is necessary- dbxrefs of genbank objects should be pre-loaded into dbxref, feature, and feature_dbxref
# I think this is for storing pubmed IDS- should be prestored in pub, pubauthor
my $public_dbxref_sth = $dbh->prepare(
"INSERT INTO public.dbxref (accession, db_id) VALUES (?, (SELECT db_id FROM public.db WHERE db.name = ?))"
);

############################

#query for findiing the marker ID according to marker name
my $marker_query =
  $dbh->prepare("SELECT marker_id from sgn_bt.markers where marker_name= ?");

open( INFILE, "<$infile" ) || die "can't open file";    #parse_potato_genes.txt
open( ERR, ">$infile.err" )
  || die "Can't open the error ($infile.err) file for writing.\n";

my (
    $locus_count,  $alias_count,        $allele_count,
    $marker_count, $locus_dbxref_count, $dbxref_count
) = ( 0, 0, 0, 0, 0, 0 );
eval {

    #skip the first line
    <INFILE>;
    my %new_locus     = ();          #hash of arrays for the locus info
    my $previous_line = 'Contig1';
    my $count_lines   = 0;
    while ( my $line = <INFILE> ) {

        my $locus_obj = undef;
        chomp $line;
        my @fields = split "\t", $line;

      #the first field indicate if this line is a part of a contig, or a singlet
        my $new_entry = $fields[0];

        #don't need this now...
        my $gi = $fields[1];    #the gis should be in public.dbxref.accession

        ###the accession should be used for fetching the sequence from ncbi,
        #storing in dbxref, feature, feature_dbxref, and phenome.locus_dbxref
        my $accession = $fields[2]
          ;    #the accessions should already be stored in public.feature.name
        my $locus_name = $fields[4];
        if ( $locus_name eq 'x' ) { next(); }

        if ( $new_entry && $locus_name ) {
            $count_lines++;
        }
        else { $locus_name = ''; }

        my $locus_symbol = $fields[5];
        my $activity     = $fields[6];

        my $aliases =
          $fields[7];    #need to split this line by '|' and filter for uniques
        my @alias = split '\|', $aliases;

        #pubmeds should be fetched from genbank and stored in
        #dbxref, pub, pubauthor, pubabstract, pub_dbxref, phenome.locus_dbxref
        my $pubmed = $fields[11];               #split by '|' and filter
        my @pubmed_ids = split '\|', $pubmed;

        my $chromosome = $fields[12];
        my $marker     = $fields[14];
        my $allele     = $fields[15];
        my $comments   = $fields[16];

        #if ($new_entry) {print "$count_lines, $new_entry: $locus_name\n"; }
#############

        if ( $count_lines > 1 && $new_entry ) {

            my $locus_id = $name2id{$locus_name};
            if ($locus_id) {
                print ERR "$locus_name exists in database!! skipping...\n";

                #print "ID: $locus_id, locus_name: $locus_name\n";
                %new_locus = ();
                next();
            }

            #new locus object..
            $locus_obj = CXGN::Phenome::Locus->new($dbh);

            #setting all available values for this locus
            $locus_obj->set_locus_name( $new_locus{locus_name}[0] );
            $locus_obj->set_locus_symbol( $new_locus{locus_symbol}[0] );
            $locus_obj->set_gene_activity( $new_locus{activity}[0] );
            $locus_obj->set_linkage_group( $new_locus{linkage_group}[0] );
            $locus_obj->set_common_name_id($organism_id);
            $locus_obj->set_sp_person_id($sp_person_id);

#storing the locus returns the new locus_id
#this should also store the 'prefered' locus_alias and a default 'dummy' allele. See Locum.pm..
            my $locus_id = $locus_obj->store();
            print "inserting locus $new_locus{locus_name}[0]"
              . ", $new_locus{locus_symbol}[0],$new_locus{activity}[0], $organism_id,'', $new_locus{linkage_group}[0] \n";
            $locus_count++;

#$locus_sth->execute($new_locus{locus_name}[0], $new_locus{locus_symbol}[0],$new_locus{activity}[0], $new_locus{locus_notes}[0],$sp_person_id,'', $new_locus{linkage_group}[0], $organism_id);

            #  my $locus_id = $dbh->last_insert_id("locus", "phenome");
            #$alias_sth ->execute($new_locus{locus_symbol}[0],$locus_id, 't');

            my %alias_hash = map { $_ => 1 } @{ $new_locus{alias} };
            my @uniq_alias = sort keys %alias_hash;
            foreach my $ua (@uniq_alias) {
                unless ( $ua eq $new_locus{locus_symbol}[0] ) {
                    print ERR
                      "alias for locus $new_locus{locus_symbol}[0]: $ua\n";

                    #$alias_sth->execute($ua, $locus_id, 'f');
                    my $synonym =
                      CXGN::Phenome::LocusSynonym->new( undef, $dbh );
                    $synonym->set_locus_alias($ua);

                    #this should insert the new alias into locus_alias..
                    $locus_obj->add_locus_aliases($synonym);
                    my $la_obj =
                      CXGN::Phenome::LocusSynonym->new( undef, $dbh );
                    $la_obj->set_locus_id($locus_id);
                    $la_obj->set_locus_alias($ua);
                    $la_obj->set_sp_person_id($sp_person_id);
                    $la_obj->store();
                    $alias_count++;
                }
            }

            if ( $new_locus{allele}[0] ) {

         #$allele_sth->execute($locus_id, $new_locus{allele}[0], $sp_person_id);
                my $allele_obj = CXGN::Phenome::Allele->new($dbh);
                $allele_obj->set_allele_syymbol( $new_locus{allele}[0] );
                $locus_obj->add_allele($allele_obj);
                $allele_count++;
            }
            for my $i ( 0 .. $#{ $new_locus{marker} } ) {

#print "inserting marker $new_locus{locus_symbol}[0]: $new_locus{marker}[$i]\n";
#$marker_sth->execute($locus_id,$new_locus{marker}[0] );
                my $marker_id =
                  $marker_query->execute( $new_locus{marker}[$i] );
                my $locus_marker_obj = CXGN::Phenome::LocusMarker->new($dbh);
                $locus_marker_obj->set_marker_id($marker_id);
                $locus_obj->add_locus_marker($locus_marker_obj);
                $marker_count++;
            }

            my %gb_hash = map { $_ => 1 } @{ $new_locus{gb_acc} };
            my @uniq_gb = sort keys %gb_hash;
            foreach my $ugb (@uniq_gb) {

                #  for my $i ( 0 .. $#{ $new_locus{gb_acc} } ) {
                #	my $db_name = 'DB:GenBank_GI';
                print ERR
                  "inserting GB accession $new_locus{locus_symbol}[0]: $ugb\n";

         #	$locus_dbxref_sth->execute($locus_id, $new_locus{gis}[$i], $db_name);
         #
         #new feature object

                my $feature_obj = CXGN::Chado::Feature->new($dbh);
                $feature_obj->set_name($ugb);
                my $feature_id = $feature_obj->feature_exists();
                print "feature_id= $feature_id\n";

                #$feature_obj->set_feature_id($feature_id);
                if ($feature_id) {
                    $feature_obj =
                      CXGN::Chado::Feature->new( $dbh, $feature_id );
                }

#fix bug in EFetch first! it returns more than the sequence submitted..##fetch the sequence from genbank...
#my $feature_fetch= CXGN::Tools::FeatureFetch->new($feature_obj);
#NO NEED TO STORE BECAUSE ALL SEQUENCES SHOULD BE ALREADY IN THE DATABASEstore the feature
                ##$feature_obj->store();

                #make a locus_dbxref connection:
                my $dbxref_obj =
                  CXGN::Chado::Dbxref->new( $dbh,
                    $feature_obj->get_dbxref_id() );
                $locus_obj->add_locus_dbxref( $dbxref_obj, undef,
                    $sp_person_id );

                $locus_dbxref_count++;

                ## this is not quite working without using FeatureFetch...
                #get the pubmed ids
                #my @pubmed_ids= $feature_obj->get_pubmed_ids();
                #foreach my $pmid(@pubmed_ids) {

                my %pubmed_hash = map { $_ => 1 } @{ $new_locus{pubmed} };
                my @uniq_pubmed = sort keys %pubmed_hash;
                foreach my $pmid (@uniq_pubmed) {
                    print ERR
"inserting publication $new_locus{locus_symbol}[0]: $pmid\n";

                    my $publication = CXGN::Chado::Publication->new($dbh);
                    $publication->set_accession($pmid);
                    CXGN::Tools::Pubmed->new($publication);

                    my $existing_publication =
                      $publication->publication_exists();
                    if ($pmid) {
                        if ( !($existing_publication) )
                        {    #publication does not exist in our database
                            print STDERR
                              "storing publication now. pubmed id = $pmid";
                            my $pub_id = $publication->store();
                            $dbxref_count++;
                            my $publication_dbxref_id =
                              $publication->get_dbxref_id();
                            my $publication_dbxref =
                              CXGN::Chado::Dbxref->new( $dbh,
                                $publication_dbxref_id );
                            $locus_obj->add_locus_dbxref( $publication_dbxref,
                                undef, $sp_person_id );

                        }
                        else
                        { #publication exists but is not associated with the object
                            print STDERR
"***the publication exists but is not associated.";
                            $publication = CXGN::Chado::Publication->new( $dbh,
                                $existing_publication );
                            if (
                                !(
                                    $publication->is_associated_publication(
                                        $locus_obj, $locus_id
                                    )
                                )
                              )
                            {
                                my $publication_dbxref_id =
                                  $publication->get_dbxref_id();
                                my $publication_dbxref =
                                  CXGN::Chado::Dbxref->new( $dbh,
                                    $publication_dbxref_id );

                                my $associated_feature =
                                  $locus_obj->get_locus_dbxref(
                                    $publication_dbxref)->get_locus_dbxref_id();
                                my $obsolete =
                                  $locus_obj->get_locus_dbxref(
                                    $publication_dbxref)->get_obsolete();

                                if ($publication_dbxref_id) {
                                    $locus_obj->add_locus_dbxref(
                                        $publication_dbxref,
                                        $associated_feature,
                                        $sp_person_id
                                    );
                                }

                                print ERR
"publication dbxref is  $publication_dbxref_id\n";
                                $locus_dbxref_count++;
                            }
                        }
                    }
                }
            }
######################

####################
            #my %pubmed_hash = map { $_ => 1 } @{ $new_locus{pubmed} };
            #my @uniq_pubmed = sort keys %pubmed_hash;
            #foreach my $ua(@uniq_pubmed) {
            #	my $db_name = 'PMID';
            #	$check_dbxref->execute($ua, $db_name);
            #	my ($dbxref_id) = $check_dbxref->fetchrow_array();
            #	print "pubmed ID for locus $new_locus{locus_symbol}[0]: $ua\n";
            #	if (!$dbxref_id) {
            #	    $public_dbxref_sth->execute($ua, $db_name);
            #	    $dbxref_count++;
            #	}
            #	$locus_dbxref_sth->execute($locus_id, $ua, $db_name);
            #	$locus_dbxref_count++;
            #    }

            %new_locus = ();

        }
        $previous_line = $new_entry;

        #my $locus_id = $name2id{$locus_name};
        #if ($locus_id) {
        #    print ERR "$locus_name exists in database!! skipping...\n";
        #    next();
        #}else{

        #}

        if ($locus_name) {
            push @{ $new_locus{locus_name} },   $locus_name;
            push @{ $new_locus{locus_symbol} }, $locus_symbol;
        }

        #my $acc_exists= grep(/$accession/,$new_locus{gb_acc} );
        #print "*****$accession: $acc_exists...\n";
        #if (!$acc_exists ) {
        push @{ $new_locus{gb_acc} }, $accession;

        push @{ $new_locus{gis} },      $gi;
        push @{ $new_locus{activity} }, $activity;

        push @{ $new_locus{alias} }, @alias;

        foreach my $pid (@pubmed_ids) {
            my $exists = grep( /$pid/, $new_locus{pubmed} );
            if ( !$exists ) {

                #    print "$pid\n";
                push @{ $new_locus{pubmed} }, $pid;
            }
        }

        push @{ $new_locus{linkage_group} },
          $chromosome;    #there should be only one chromosome num per locus
        if ($marker) { push @{ $new_locus{marker} }, $marker; }
        push @{ $new_locus{allele} },      $allele;
        push @{ $new_locus{locus_notes} }, $comments;
    }

};

if ($@) {
    print $@;
    print "Failed; rolling back.\n";
    $dbh->rollback();
}
else {
    print "Succeeded.\n";
    print
      "Inserted $locus_count new $organism loci, $alias_count locus aliases\n";
    print
"$allele_count alleles, $marker_count markers, $locus_dbxref_count locus-dbxref associations\n";
    print
      "**$dbxref_count new pubmed IDs where inserted into public.dbxref**\n";
    if ( $ARGV[2] eq 'COMMIT' ) {
        $dbh->commit();
    }
    else {
        $dbh->rollback();
    }
}

close ERR;
close INFILE;
