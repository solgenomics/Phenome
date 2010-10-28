use strict;
use Module::Build;

my $build = Module::Build->new(
    dist_name          => 'Phenome',
    dist_author        => 'Sol Genomics Network',
    dist_abstract      => 'scripts and libraries for managing the SGN Phenome database',
    license            => 'perl',
    create_makefile_pl => 'passthrough',

    # current version of our core libraries distribution
    dist_version => '0.1',

    recursive_test_files => 1,

    # and now the list of perl module dependencies
    requires => {
        perl => '5.10.0',

	'Bio::Chado::Schema'         => '0.04000',
	'Bio::GMOD::GenericGenePage' => '0.12',

# 	'CXGN::Chado::Cvterm' => 0,
# 	'CXGN::Chado::Dbxref' => 0,
# 	'CXGN::Chado::Dbxref::DbxrefI' => 0,
# 	'CXGN::Chado::Dbxref::EvidenceI' => 0,
# 	'CXGN::Chado::Organism' => 0,
# 	'CXGN::Chado::Phenotype' => 0,
# 	'CXGN::Chado::Publication' => 0,
# 	'CXGN::Contact' => 0,
# 	'CXGN::Cview::MapFactory' => 0,
# 	'CXGN::DB::Connection' => 0,
# 	'CXGN::DB::ModifiableI' => 0,
# 	'CXGN::DB::Object' => 0,
# 	'CXGN::Image' => 0,
# 	'CXGN::Marker' => 0,
# 	'CXGN::People::Person' => 0,
# 	'CXGN::Search::BasicResult' => 0,
# 	'CXGN::Search::DBI::Simple' => 0,
# 	'CXGN::Search::DBI::Simple::WWWQuery' => 0,
# 	'CXGN::Search::WWWSearch' => 0,
# 	'CXGN::Tools::Class' => 0,
# 	'CXGN::Tools::Organism' => 0,
# 	'CXGN::Tools::Tsearch' => 0,
# 	'CXGN::Transcript::Unigene' => 0,

	'Cache::File' => 0,
	'DBIx::Class' => 0,
	'DBIx::Class::Schema' => 0,
	'JSON' => 0,
	'List::Compare' => 0,
    },

    build_requires => {
	'Test::More' => 0,
	'Test::Exception' => 0,
    },
);
$build->create_build_script;

## print the db_patches that this module needs to run to work

my $db_patches = {
    '1. mx-run AddStockLinks -H [host] -D [dbname] -u [sgn username]'  => 1,
    '2. LoadChadoContact' => 1,
    '3. LoadChadoProject' =>1,
    '4. LoadChadoGenotype' =>1 ,
    '5. LoadChadoStock' => 1,
    '6. LoadChadoND' => 1,
    '7. GrantStockPermissions' => 1,
    '8. CopyAccessionToStock' => 1,
    '9. LoadPhenomeInStock' => 1,
};

## For now it will print the dbpatches that this Build.PL requires

if (%{$db_patches}) {
    print "\nDB: db_patches required:\n";
    for my $dbpatch (sort  keys %{$db_patches}) {
        print "\t+ $dbpatch\n";
    }
}
