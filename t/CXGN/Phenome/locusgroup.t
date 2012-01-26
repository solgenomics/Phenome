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
use warnings;
use autodie;

use Test::More tests => 2;

use lib '../sgn/t/lib';
use SGN::Test::WWW::Mechanize;
use CXGN::Phenome::LocusGroup;
use CXGN::Phenome::Schema;

my $m = SGN::Test::WWW::Mechanize->new();

BEGIN {
    use_ok('CXGN::Phenome::LocusGroup');
}

my $schema = $m->context->dbic_schema('CXGN::Phenome::Schema', 'sgn_test');

my $last_locusgroup_id= $schema->resultset('Locusgroup')->get_column('locusgroup_id')->max; 

my $lg = CXGN::Phenome::LocusGroup->new($schema);

my $name= "Test group";
my $relationship= "Homolog";

$lg->set_locusgroup_name($name);

my $lg_id= $lg->store();

my $re_lg= CXGN::Phenome::LocusGroup->new($schema, $lg_id);
is($re_lg->get_locusgroup_name(), $name, "Locusgroup name test");

$schema->resultset('Locusgroup')->search('locusgroup_id'=> $lg_id)->first()->delete();  



