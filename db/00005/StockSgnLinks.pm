#!/usr/bin/env perl


=head1 NAME

 StockSgnLinks.pm

=head1 SYNOPSIS

mx-run ThisPackageName [options] -H hostname -D dbname -u username [-F]

this is a subclass of L<CXGN::Metadata::Dbpatch>
see the perldoc of parent class for more details.

=head1 DESCRIPTION

This patch creates and populates linking tables between Chado stock and sgn alleles, images, and owners. These are currently stored in stockprop, but it does not work very well wit hdb queries, and also we cannot maintain database integrity with FKs

This subclass uses L<Moose>. The parent class uses L<MooseX::Runnable>

=head1 AUTHOR

 Naama Menda<nm249@cornell.edu>

=head1 COPYRIGHT & LICENSE

Copyright 2011 Boyce Thompson Institute for Plant Research

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


package StockSgnLinks;

use Try::Tiny;
use Moose;
extends 'CXGN::Metadata::Dbpatch';

use CXGN::Metadata::Metadbdata;
use CXGN::People::Person;

sub init_patch {
    my $self=shift;
    my $name = __PACKAGE__;
    print "dbpatch name is : '" .  $name . "'\n\n";
    my $description = 'Loading stock alleles, images, and owners in the perspective linking tables';
    my @previous_requested_patches = ('AddAllStockAlleles'); #ADD HERE

    $self->name($name);
    $self->description($description);
    $self->prereq(\@previous_requested_patches);

}

sub patch {
    my $self=shift;

    print STDOUT "Executing the patch:\n " .   $self->name . ".\n\nDescription:\n  ".  $self->description . ".\n\nExecuted by:\n " .  $self->username . " .";

    print STDOUT "\nChecking if this db_patch was executed before or if previous db_patches have been executed.\n";

    my $metadata_schema = $self->md_schema;
    my $coderef = sub {
        my ($allele_count, $image_count, $owner_count) = 0;
       #set the searchpath
        $self->dbh->do('set search_path to phenome, public');
	#create the linking tables
        $self->dbh->do("
CREATE TABLE phenome.stock_allele (
stock_allele_id serial not null primary key,
stock_id integer not null REFERENCES public.stock(stock_id),
allele_id integer not null REFERENCES phenome.allele(allele_id),
metadata_id integer REFERENCES metadata.md_metadata(metadata_id))" );

        $self->dbh->do("
CREATE TABLE phenome.stock_image (
stock_image_id serial not null primary key,
stock_id integer not null REFERENCES public.stock(stock_id),
image_id integer not null REFERENCES metadata.md_image(image_id),
metadata_id integer REFERENCES metadata.md_metadata(metadata_id))" );

        $self->dbh->do("
CREATE TABLE phenome.stock_owner (
stock_owner_id serial not null primary key,
stock_id integer not null REFERENCES public.stock(stock_id),
sp_person_id integer not null REFERENCES sgn_people.sp_person(sp_person_id),
metadata_id integer REFERENCES metadata.md_metadata(metadata_id))" );

        #
        $self->dbh->do("GRANT UPDATE, INSERT, SELECT ON phenome.stock_allele TO web_usr");
        $self->dbh->do("GRANT USAGE ON phenome.stock_allele_stock_allele_id_seq TO web_usr");
        $self->dbh->do("GRANT UPDATE, INSERT, SELECT ON phenome.stock_image TO web_usr");
        $self->dbh->do("GRANT USAGE ON phenome.stock_image_stock_image_id_seq TO web_usr");
        $self->dbh->do("GRANT UPDATE, INSERT, SELECT ON phenome.stock_owner TO web_usr");
        $self->dbh->do("GRANT USAGE ON phenome.stock_owner_stock_owner_id_seq TO web_usr");
        $self->dbh->do("GRANT UPDATE, INSERT, SELECT ON metadata.md_metadata TO web_usr");
        $self->dbh->do("GRANT USAGE ON metadata.md_metadata_metadata_id_seq TO web_usr");

        #select all stock-allele links
        my $q = "SELECT individual_allele.*, stock_id FROM phenome.individual_allele JOIN phenome.individual USING (individual_id)";
        my $sth = $self->dbh->prepare($q);
        $sth->execute();
        print "Loading stock alleles .... \n";
        while ( my $hashref = $sth->fetchrow_hashref() ) {
            my $stock_id      = $hashref->{stock_id};
            my $allele_id     = $hashref->{allele_id};
            my $sp_person_id  = $hashref->{sp_person_id};
            my $create_date   = $hashref->{create_date};
            my $modified_date = $hashref->{modified_date};
            my $obsolete      = $hashref->{obsolete};
            my $username = CXGN::People::Person->new($self->dbh, $sp_person_id)->get_username;
            #stock metadata object
            my $metadata = CXGN::Metadata::Metadbdata->new($metadata_schema, $username);
            $metadata->set_create_date($create_date) if $create_date;
            $metadata->set_modified_date($modified_date) if $modified_date;
            $metadata->set_obsolete($obsolete) if $obsolete;
            $metadata->set_create_person_id($sp_person_id) if $sp_person_id;
            my $metadata_id = $metadata->store->get_metadata_id; # we need a new metadata row for each object for future edit tracking
            #now store the stock_allele link
            if ($stock_id && $allele_id && $metadata_id) {
                $self->dbh->do("INSERT INTO phenome.stock_allele (stock_id, allele_id, metadata_id) VALUES ($stock_id , $allele_id, $metadata_id)");
                $allele_count++;
            } else { warn "NULL VALUE FOUND! stock_id = $stock_id, allele_id = $allele_id , metadata_id = $metadata_id\n" ; }
        }
        print "Loaded $allele_count alleles \n";

        $q = "SELECT stockprop.* FROM public.stockprop JOIN public.cvterm on cvterm_id = type_id where cvterm.name = 'sgn image_id'";
        $sth = $self->dbh->prepare($q);
        $sth->execute();
        print "Loading stock images .... \n";
        while (my $hashref = $sth->fetchrow_hashref() ) {
            my $stock_id      = $hashref->{stock_id};
            my $image_id     = $hashref->{value};
            #my $sp_person_id  = $hashref->{sp_person_id};
            #my $create_date   = $hashref->{create_date};
            #my $modified_date = $hashref->{modified_date};
            #my $obsolete      = $hashref->{obsolete};
            #my $username = CXGN::People::Person->new($self->dbh, $sp_person_id)->get_username;
            #stock metadata objext
            #my $metadata = CXGN::Metadata::Metadbdata->new($metadata_schema, $username);
            #now store the stock_image link
            if ($stock_id && $image_id) {
                $self->dbh->do("INSERT INTO phenome.stock_image (stock_id, image_id) VALUES ($stock_id , $image_id)");
                $image_count++;
            } else { warn "NULL VALUE FOUND! stock_id = $stock_id, image_id = $image_id \n" ; }
        }
        print "Loaded $image_count image-stock links! \n";
        ######
        $q = "SELECT stockprop.* FROM public.stockprop JOIN public.cvterm on cvterm_id = type_id where cvterm.name = 'sp_person_id'";

        $sth = $self->dbh->prepare($q);
        $sth->execute();
        print "Loading stock owners .... \n";
        while (my $hashref = $sth->fetchrow_hashref() ) {
            my $stock_id      = $hashref->{stock_id};
            my $sp_person_id  = $hashref->{value};
            #now store the stock_image link
            if ($sp_person_id && $stock_id ) {
                $self->dbh->do("INSERT INTO phenome.stock_owner (stock_id, sp_person_id) VALUES ($stock_id , $sp_person_id)");
                $owner_count++;
            } else { warn "NULL VALUE FOUND! stock_id = $stock_id, person_id = $sp_person_id\n" ; }
        }
        print "Loaded $owner_count owner-stock links! \n";

	if ($self->trial) {
	    print "Trail mode! Rolling back transaction\n\n";
	    $metadata_schema->txn_rollback;
        }
	return 1;
    };

    try {
	$metadata_schema->txn_do($coderef);
	print "Data committed! \n";
    } catch {
	die "Load failed! " . $_ . "\n" ;
    };


}


return 1;
