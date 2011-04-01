#!/usr/bin/env perl


=head1 NAME

 AddAllStockAlleles.pm

=head1 SYNOPSIS

mx-run ThisPackageName [options] -H hostname -D dbname -u username [-F]

this is a subclass of L<CXGN::Metadata::Dbpatch>
see the perldoc of parent class for more details.

=head1 DESCRIPTION

This is a patch for loading all the alleles linked with an individual into the stockprop table

This subclass uses L<Moose>. The parent class uses L<MooseX::Runnable>

=head1 AUTHOR

 Naama Menda<nm249@cornell.edu>

=head1 COPYRIGHT & LICENSE

Copyright 2011 Boyce Thompson Institute for Plant Research

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


package AddAllStockAlleles;

use Try::Tiny;
use Moose;
extends 'CXGN::Metadata::Dbpatch';

use Bio::Chado::Schema;

use CXGN::Phenome::Individual;

sub init_patch {
    my $self=shift;
    my $name = __PACKAGE__;
    print "dbpatch name is : '" .  $name . "'\n\n";
    my $description = 'Loading the  individual data into the stock module';
    my @previous_requested_patches = ('CopyAccessionToStock', 'AddStockLinks'); #ADD HERE

    $self->name($name);
    $self->description($description);
    $self->prereq(\@previous_requested_patches);

}

sub patch {
    my $self=shift;

    print STDOUT "Executing the patch:\n " .   $self->name . ".\n\nDescription:\n  ".  $self->description . ".\n\nExecuted by:\n " .  $self->username . " .";

    print STDOUT "\nChecking if this db_patch was executed before or if previous db_patches have been executed.\n";

    my $schema = Bio::Chado::Schema->connect( sub { $self->dbh->clone } ,  { on_connect_do => ['SET search_path TO public;'], autocommit => 1 });

    my $coderef = sub {
        my $count = 0;
       #set the searchpath
        $self->dbh->do('set search_path to phenome, public');
	# delete existing alleles , to prevent duplications
        $self->do("delete from stockprop where type_id = (select cvterm_id from cvterm where name = 'sgn allele_id' " ) ;
        print "Loading individual alleles .... \n";
        my $q = "SELECT individual_id FROM phenome.individual";
        my $sth = $self->dbh->prepare($q);
        $sth->execute();
        my @individuals;
        while (my ($individual_id) = $sth->fetchrow_array ) {
            my $individual = CXGN::Phenome::Individual->new($self->dbh , $individual_id);
            push @individuals, $individual;
        }
        foreach my $ind (@individuals) {
            #########find linked alleles
            my $stock_id = $ind->get_stock_id;
            my $stock_individual = $schema->resultset("Stock::Stock")->find( { stock_id => $stock_id } );
            if (!$stock_id) { print 'No stock is found for ' . $ind->get_individual_id . "\n" ; next; }
            my @alleles = $ind->get_alleles;
            foreach my $a (@alleles) {
                $count++;
                my $a_id = $a->get_allele_id;
                $stock_individual->create_stockprops({ 'sgn allele_id' => $a_id},
                                                     {autocreate => 1,
                                                      cv_name => 'local',
                                                      allow_duplicate_values => 1,
                                                     });
            }
        }
        print "You're done! loaded $count alleles \n";
	if ($self->trial) {
	    print "Trail mode! Rolling back transaction\n\n";
	    $schema->txn_rollback;
        }
	return 1;
    };

    try {
	$schema->txn_do($coderef);
	print "Data committed! \n";
    } catch {
	die "Load failed! " . $_ . "\n" ;
    };
}

return 1;
