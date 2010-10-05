#!/usr/bin/env perl


=head1 NAME

 GrantStockPermissions.pm

=head1 SYNOPSIS

mx-run ThisPackageName [options] -H hostname -D dbname -u username [-F]
    
this is a subclass of L<CXGN::Metadata::Dbpatch>
see the perldoc of parent class for more details.
    
=head1 DESCRIPTION

Take care of web_usr permissions for the Chado Stock module
This subclass uses L<Moose>. The parent class uses L<MooseX::Runnable>
    
=head1 AUTHOR

 Naama Menda<nm249@cornell.edu>

=head1 COPYRIGHT & LICENSE

Copyright 2010 Boyce Thompson Institute for Plant Research

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


package GrantStockPermissions;

use Moose;
extends 'CXGN::Metadata::Dbpatch';


sub init_patch {
    my $self=shift;
    my $name = __PACKAGE__;
    print "dbpatch name is :'" .  $name . "'\n\n";
    my $description = 'Granting permissions to web_usr on the chado stock module';
    my @previous_requested_patches = ('LoadChadoStock'); #ADD HERE 
    
    $self->name($name);
    $self->description($description);
    $self->prereq(\@previous_requested_patches);
    print STDOUT "\nChecking if this db_patch was executed before or if previous db_patches have been executed.\n";
}

sub patch {
    my $self=shift;
    
    
    print STDOUT "Executing the patch:\n " .   $self->name . ".\n\nDescription:\n  ".  $self->description . ".\n\nExecuted by:\n " .  $self->username . " .";
    
    print STDOUT "\nExecuting the SQL commands.\n";
    
    my @tables = ( 
	qw /
stock
stock_pub stockprop 
stockprop_pub
stock_relationship
stock_relationship_pub
stock_dbxref
stock_cvterm
stock_genotype
stockcollection
stockcollectionprop
stockcollection_stock
/ );
 
    foreach my $t (@tables) {
	my $seq = $t . "_" . $t . "_id_seq";
	print "Granting permissions to web_user on table $t and sequence $seq\n";
	
	$self->dbh->do( 'SET SEARCH_PATH TO public' );
	$self->dbh->do( "GRANT SELECT, UPDATE, INSERT ON $t TO web_usr" );
	$self->dbh->do( "GRANT USAGE ON $seq TO web_usr" );
    }
    print "You're done!\n";
}


####
1; #
####
