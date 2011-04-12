#!/usr/bin/env perl


=head1 NAME

 PhenomeAnnotationsToStock.pm

=head1 SYNOPSIS

mx-run ThisPackageName [options] -H hostname -D dbname -u username [-F]

this is a subclass of L<CXGN::Metadata::Dbpatch>
see the perldoc of parent class for more details.

=head1 DESCRIPTION

This is a patch for loading cvterm annotation data in phenome.individual_dbxref in the stock module (stock_cvterm) and the evidence codes into stock_cvtermprop. Previous annotations loaded into stock_dbxref and stock_dbxrefprop will be deleted.

This subclass uses L<Moose>. The parent class uses L<MooseX::Runnable>

=head1 AUTHOR

 Naama Menda<nm249@cornell.edu>

=head1 COPYRIGHT & LICENSE

Copyright 2011 Boyce Thompson Institute for Plant Research

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


package PhenomeAnnotationsToStock;

use Try::Tiny;
use Moose;
extends 'CXGN::Metadata::Dbpatch';

use Bio::Chado::Schema;

use CXGN::Phenome::Population;
use CXGN::Phenome::Individual;
use CXGN::Chado::Dbxref;

use CXGN::People::Person;


sub init_patch {
    my $self=shift;
    my $name = __PACKAGE__;
    print "dbpatch name is : '" .  $name . "'\n\n";
    my $description = 'Loading the phenome individual annotations into stock_cvterm ';
    my @previous_requested_patches = ('LoadPhenomeInStock', 'AddStockCvtermProp','PopulateStockPub'); #ADD HERE

    $self->name($name);
    $self->description($description);
    $self->prereq(\@previous_requested_patches);

}

sub patch {
    my $self=shift;

    print STDOUT "Executing the patch:\n " .   $self->name . ".\n\nDescription:\n  ".  $self->description . ".\n\nExecuted by:\n " .  $self->username . " .";

    print STDOUT "\nChecking if this db_patch was executed before or if previous db_patches have been executed.\n";

    my $schema = Bio::Chado::Schema->connect( sub { $self->dbh->clone } ,  { on_connect_do => ['SET search_path TO public;'], autocommit => 1 });

###################################################################
    my $pub_curator = $schema->resultset('Pub::Pub')->find( { title => 'curator' });
    
##################
    my $result = $schema->txn_do( sub {
        print "loading ...\n";
# do this for GO, PO, SP - copy from stock_dbxref to stock cvterm, and the evidence codes copied to stock_cvtermprop.
        my $stockdbxrefs = $schema->resultset("General::Db")->search( {
            -or => [
                 name => 'GO',
                 name => 'PO',
                 name => 'SP',
                ], } )
            ->search_related('dbxrefs')->search_related('stock_dbxrefs');
        while ( my $sd = $stockdbxrefs->next )  {
            # for each stock_dbxref create a stock_cvterm
            my $stock_cvterm = $sd->stock->find_or_create_related('stock_cvterms' , {
                cvterm_id => $sd->dbxref->search_related('cvterm')->first->cvterm_id ,
                pub_id => $pub_curator->pub_id  } );
            #print "Added cvterm for stock " . $sd->stock->name . "\n";
            
            # get all the properties of the stock_dbxref , and load them into stock_cvtermprop
            my $dprops = $sd->search_related('stock_dbxrefprops') ;
          PROP: while ( my $dprop = $dprops->next )  {
              my $cv_name = $dprop->type->cv->name;
              my $type_name = $dprop->type->name;
              my $db_name = $dprop->type->dbxref->db->name;
              my $value = $dprop->value
                  or die "Invalid stock_dbxrefprop: ".Data::Dumper::Dumper({ $dprop->get_columns });
              my $rank = $dprop->rank;
              if ($cv_name eq 'local' ) {
                  # load the reference into stock_cvterm.pub_id
                  if ($type_name eq 'reference' ) {
                      my @pubs = $schema->resultset("General::Dbxref")
                                        ->find({ dbxref_id => $value })
                                        ->pubs_mm;
                      if( @pubs > 1 ) {
                          die "multiple pubs for stock_dbxrefprop ID ".$dprop->stock_dbxrefprop_id;
                      }
                      $stock_cvterm->update( { pub_id => $_->pub_id } ) for @pubs;
                      next PROP;
                  }
                  $stock_cvterm->create_stock_cvtermprops(
                      {  $type_name => $value  } , { cv_name =>'local' , autocreate=>1} ) if ( $value && $rank == 0) ;
                  #print "Added prop to stock_cvterm. type= $type_name , value =  $value \n";
              }
              if ($cv_name eq 'relationship' || $cv_name eq 'evidence_code' ) {
                  $stock_cvterm->create_stock_cvtermprops(
                      {  $cv_name => $dprop->type_id  } , { cv_name =>$cv_name , db_name => $db_name} ) if $value && $rank == 0 ;
                  #print "Added prop to stock_cvterm. type= $cv_name , value =  $type_name \n";
              }
              #delete the stock_dbxrefprop
              $dprop->delete
          }
            # delete the stock_dbxref
            $sd->delete;
        }
        if ( $self->trial ) {
            print "Trial mode! Rolling back transaction.\n\n";
            $schema->txn_rollback;
            return 0;
        } else {
            print "Committing.\n";
            return 1;
        }
    });

    print $result ? "Patch applied successfully.\n" : "Patch not applied.\n";
}

return 1;
