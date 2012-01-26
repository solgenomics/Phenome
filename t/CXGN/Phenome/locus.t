#!/usr/bin/perl

=head1 NAME

  locus.t
  A test for  CXGN::Phenome::Locus class

=cut

=head1 SYNOPSIS

 perl locus.t



=head1 DESCRIPTION

Testing the locus object. Storing a new locus, updating, obsoleting, adding associated features, including
synonyms, alleles, dbxrefs, and unigenes, merging loci, and other accessors and class functions



=head2 Author

Naama Menda <n249@cornell.edu>

    
=cut

use strict;
use warnings;
use autodie;

use Test::More  tests => 35;

use lib '../sgn/t/lib';
use SGN::Test::WWW::Mechanize;
use CXGN::Phenome::Locus;
use CXGN::Phenome::Schema;

BEGIN {
    use_ok('CXGN::Phenome::Schema');
    use_ok('CXGN::Phenome::Locus');
}

#if we cannot load the CXGN::Phenome::Schema module, no point in continuing
CXGN::Phenome::Schema->can('connect')
    or BAIL_OUT('could not load the CXGN::Phenome::Schema  module');

my $m = SGN::Test::WWW::Mechanize->new();
my $dbh = $m->context->dbc->dbh;

#my $schema=  CXGN::Phenome::Schema->connect(  sub { $dbh->get_actua
my $schema = $m->context->dbic_schema('CXGN::Phenome::Schema');

my $last_locus_id= $schema->resultset('Locus')->get_column('locus_id')->max; 
my $last_allele_id = $schema->resultset('Allele')->get_column('allele_id')->max;

# make a new locus and store it, all in a transaction. 
# then rollback to leave db content intact.

#1. Store a new locus
diag("Store new locus test \n");
my $locus = CXGN::Phenome::Locus->new($dbh);

my $locus_name= 'test locus name';
my $symbol= 'testsymbol';
my $common_name = 'Tomato';
my $q= "SELECT common_name_id FROM sgn.common_name where common_name = ?";
my $sth=$dbh->prepare($q);
$sth->execute($common_name);
my ($common_name_id) = $sth->fetchrow_array();

my $gene_activity  = 'test activity';
#my $locus_notes     = 'test notes';
my $description  = 'test description' ;
my $linkage_group ='1';
my $lg_arm    ='short';
my $sp_person_id= 329;

$locus->set_locus_name($locus_name);
$locus->set_locus_symbol($symbol);
$locus->set_common_name_id($common_name_id);
$locus->set_gene_activity($gene_activity);
#$locus->set_locus_notes($locus_notes);
$locus->set_description($description);
$locus->set_linkage_group($linkage_group);
$locus->set_lg_arm($lg_arm);
$locus->set_sp_person_id($sp_person_id);

my $locus_id = $locus->store();

is($locus_name, $locus->get_locus_name, "Locus name test");
is($symbol, $locus->get_locus_symbol(), "Locus symbol test");
is($common_name_id, $locus->get_common_name_id, "Locus common_name_id test");

is($gene_activity, $locus->get_gene_activity, "Gene activity test");
#is($locus_notes, $locus->get_locus_notes, "Locus notes test");
is($description, $locus->get_description, "Locus description test");
is($linkage_group, $locus->get_linkage_group, "Locus linkage group test");
is($lg_arm, $locus->get_lg_arm, "Locus lg arm test");
is($sp_person_id, $locus->get_sp_person_id , "Locus sp_person_id test");
is($sp_person_id, ($locus->get_owners)[0] , "Locus owner test");

##########
#re-read the locus from the database
diag("\nRe-read locus test\n");
my $re_locus= CXGN::Phenome::Locus->new($dbh, $locus->get_locus_id());
is($locus_name, $re_locus->get_locus_name, "Locus name test");
is($symbol, $re_locus->get_locus_symbol(), "Locus symbol test");
is($common_name, $re_locus->get_common_name, "Locus common_name test");

is($gene_activity, $re_locus->get_gene_activity, "Gene activity test");
is($description, $re_locus->get_description, "Locus description test");
is($linkage_group, $re_locus->get_linkage_group, "Locus linkage group test");
is($lg_arm, $re_locus->get_lg_arm, "Locus lg arm test");
is($sp_person_id, ($re_locus->get_owners)[0] , "Locus owner test");
is('f', $re_locus->get_obsolete(), "Locus obsolete test");
is(undef, $re_locus->get_modification_date(), "Locus modification date test");
ok( $re_locus->get_create_date(), "Locus create_date test");
    
#3. Now try to store the same thing
diag("\nTry to store existing locus test\n");
$locus= CXGN::Phenome::Locus->new($dbh);
$locus->set_locus_name($locus_name);
$locus->set_locus_symbol($symbol);
$locus->set_common_name_id($common_name_id);
my $message=$locus->exists_in_database() ;
diag("locus->exists_in_database returned $message !\n ");
ok($message, "Store existing locus test");


###
#4. Update an existing locus
diag("\nTry to update an existing locus test\n");

$locus=CXGN::Phenome::Locus->new($dbh, $locus_id);
$symbol = "update" . $symbol;
$locus->set_locus_symbol( $symbol);
my $u_locus_id= $locus->store();
is($u_locus_id, $locus_id, "Update existing locus test");

#5 new_with_symbol_and_species 
diag('Test new_with_symbol_and_species');
$locus=CXGN::Phenome::Locus->new_with_symbol_and_species($dbh, $symbol, $common_name);
is($locus->get_locus_id() , $locus_id, "new_with_symbol_and_species test");

#6. Test obsoleting a locus. The delete function also alters the locus name and symbol 
#to prevent uniqueness issues.
diag("\nTest obsoleting and un-obsoleting\n");
$locus->delete();
is($locus->get_obsolete(), 't', "Obsolete status test");
is($locus->get_locus_symbol(), "ob". $locus_id . "-" .$symbol, "Obsolete symbol test");
is($locus->get_locus_name(),  "ob" . $locus_id . "-" . $locus_name, "Obsolete name test");

#revert obsoleting
$locus->set_obsolete('f');
$locus->set_locus_name($locus_name);
$locus->set_locus_symbol($symbol);
$locus->store();
is($locus->get_obsolete(), 'f', "Un-obsoleting test");
is($locus->get_locus_symbol(), $symbol, "Un-obsolete symbol test");
is($locus->get_locus_name(),  $locus_name, "Un-obsolete name tets");

#add some data to the locus

#unigene
my $unigene_id = '222222';
$locus->add_unigene($unigene_id, ($locus->get_owners() )[0]);
my @u = $locus->get_unigenes();
is($u[0]->get_unigene_id(), $unigene_id, "Stored unigene test");

#locus alias
my $new_alias= CXGN::Phenome::LocusSynonym->new($dbh);
my $alias = 'new_alias';
$new_alias->set_locus_alias($alias);
$new_alias->set_sp_person_id($sp_person_id);
$locus->add_locus_alias($new_alias);

my @aliases= $locus->get_locus_aliases();
my $found_alias=0;
foreach (@aliases) {
    my $a= $_->get_locus_alias();
    $found_alias = 1 if ($a eq $alias);
}
ok($found_alias, "Locus alias stored test");
my ($a_id, $a_obsolete) = CXGN::Phenome::LocusSynonym::exists_locus_synonym_named($dbh, $alias, $locus_id);
is($a_id, $new_alias->get_locus_alias_id(), "Stored locus alias id test");

#allele
my $allele= CXGN::Phenome::Allele->new($dbh);
my $allele_symbol='new_allele';
my $allele_name = "New allele 1";
$allele->set_locus_id($locus_id);
$allele->set_allele_symbol($allele_symbol);
$allele->set_allele_name($allele_name);
$allele->set_sp_person_id($sp_person_id);
$allele->set_is_default('f');
my $allele_id= $allele->store();

my @alleles= $locus->get_alleles();
my $new_allele_id;
foreach my $al (@alleles) {
if ($al->get_is_default() eq 'f') { $new_allele_id = $al->get_allele_id() ; }
}
is($new_allele_id , $allele_id, "Add new allele test");

#dbxrefs
#$locus->add_locus_dbxref
#1. genbank sequence

#2. pubmed id

#3. GO term


#Individual

#
#####################################
##############
#test these too:
# $self->add_figure($image_id, $sp_person_id)
#$self->add_owner($owner_id,$sp_person_id)
# $self->owner_exists($sp_person_id)
# get_locus_ids_by_annotator 
# get_locus_ids_by_annotator
#$locus->get_dbxrefs_by_type("ontology");
# $locus->get_dbxref_lists();
#$self->get_locus_dbxrefs()
#my $associated= $locus->associated_publication($accession)
#my %edits= CXGN::Phenome::Locus::get_recent_annotated_loci($dbh, $date)
#my %edits= CXGN::Phenome::Locus::get_edits($locus)
# $self->get_locus_annotations($dbh, $cv_name)
#  $self->get_annotations_by_db('GO')
#$self->get_locusgroups()
# $self->count_associated_loci()
#$self->count_ontology_annotations()
#
#$self->merge_locus($merged_locus_id, $sp_person_id)


# rollback in any case
$dbh->rollback();

#reset locusgroup table sequence
if ($last_locus_id) {
    $dbh->do("SELECT setval ('phenome.locus_locus_id_seq', $last_locus_id, true)");
}else {
    $dbh->do("SELECT setval ('phenome.locus_locus_id_seq', 1, false)");
}

if ($last_allele_id) {
    $dbh->do("SELECT setval ('phenome.allele_allele_id_seq', $last_allele_id, true)");
}else {
    $dbh->do("SELECT setval ('phenome.allele_allele_id_seq', 1, false)");
}

