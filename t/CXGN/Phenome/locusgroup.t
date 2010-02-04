#!/usr/bin/perl

=head1 NAME

  locusgroup.t
  A test for  CXGN::Phenome::Locusgroup class

=cut

=head1 SYNOPSIS

 perl locusgroup.t



=head1 DESCRIPTION



=head2 Author

Naama Menda <n249@cornell.edu>

    
=cut

use strict;

use Test::More qw / no_plan / ; # tests=>6; 
use CXGN::DB::Connection;
use CXGN::Phenome::LocusGroup;

use Data::Dumper;

BEGIN {
    use_ok('CXGN::Phenome::Schema');
    use_ok('CXGN::Phenome::LocusGroup');
}

#if we cannot load the CXGN::Phenome::Schema module, no point in continuing
CXGN::Phenome::Schema->can('connect')
    or BAIL_OUT('could not load the CXGN::Phenome::Schema  module');


my $schema=  CXGN::Phenome::Schema->connect(  sub { CXGN::DB::Connection->new( {} )->get_actual_dbh() },
					      { on_connect_do => ['SET search_path TO phenome;'],
					      },
    );

my $dbh= $schema->storage()->dbh();

my $last_locusgroup_id= $schema->resultset('Locusgroup')->get_column('locusgroup_id')->max; 


# make a new locusgroup and store it, all in a transaction. 
# then rollback to leave db content intact.

eval {
    #my $row=$schema->resultset('Organism::Organism')->create();

    my $lg = CXGN::Phenome::LocusGroup->new($schema);
    
    my $name= "Test group";
    my $relationship= "Homolog";
    
    #my $dbix_o=$o->get_schema()->resultset('Organism::Organism')->new({species=>$species, genus=>$genus});
    #$o->get_schema()->resultset('Organism::Organism')species($species);
    $lg->set_locusgroup_name($name);
    
    my $lg_id= $lg->store();
    

    my $re_lg= CXGN::Phenome::LocusGroup->new($schema, $lg_id);
    is($re_lg->get_locusgroup_name(), $name, "Locusgroup name test");
  
};

######ok (@term_list == 2, "get_parents");

if ($@) { 
    print STDERR "An error occurred: $@\n";
}

# rollback in any case
$dbh->rollback();

#reset table sequence
if ($last_locusgroup_id) {
    $dbh->do("SELECT setval ('phenome.locusgroup_locusgroup_id_seq', $last_locusgroup_id, true)");
}else {
    $dbh->do("SELECT setval ('phenome.locusgroup_locusgroup_id_seq', 1, false)");
}

