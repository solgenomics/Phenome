#!/usr/bin/env perl


=head1 NAME

 LoadChadoProject.pm

=head1 SYNOPSIS

mx-run ThisPackageName [options] -H hostname -D dbname -u username [-F]
    
this is a subclass of L<CXGN::Metadata::Dbpatch>
see the perldoc of parent class for more details.
    
=head1 DESCRIPTION

This is a ptch for loadin chado's contact module, which is required by the stock module.
This subclass uses L<Moose>. The parent class uses L<MooseX::Runnable>
    
=head1 AUTHOR

 Naama Menda<nm249@cornell.edu>

=head1 COPYRIGHT & LICENSE

Copyright 2010 Boyce Thompson Institute for Plant Research

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


package LoadChadoProject;

use Try::Tiny;
use Moose;
extends 'CXGN::Metadata::Dbpatch';


sub init_patch {
    my $self=shift;
    my $name = __PACKAGE__;
    print "dbpatch name is : '" .  $name . "'\n\n";
    my $description = 'Loading the chado project linking tables';
    my @previous_requested_patches = (); #ADD HERE 
    
    $self->name($name);
    $self->description($description);
    $self->prereq(\@previous_requested_patches);
    
}

sub patch {
    my $self=shift;
    
   
    print STDOUT "Executing the patch:\n " .   $self->name . ".\n\nDescription:\n  ".  $self->description . ".\n\nExecuted by:\n " .  $self->username . " .";
    
    print STDOUT "\nChecking if this db_patch was executed before or if previous db_patches have been executed.\n";

    

    print STDOUT "\nExecuting the SQL commands.\n";
    
    my @tables = ( 
	qw /
projectprop
project_relationship
project_contact
project_pub
/ );
  
	$self->dbh->do(<<EOSQL); 
	
SET SEARCH_PATH  TO public;	
--do your SQL here


-- ================================================
-- TABLE: projectprop
-- ================================================

CREATE TABLE projectprop (
	projectprop_id serial NOT NULL,
	PRIMARY KEY (projectprop_id),
	project_id integer NOT NULL,
	FOREIGN KEY (project_id) REFERENCES project (project_id) ON DELETE CASCADE,
	type_id integer NOT NULL,
	FOREIGN KEY (type_id) REFERENCES cvterm (cvterm_id) ON DELETE CASCADE,
	value text,
	rank integer not null default 0,
	CONSTRAINT projectprop_c1 UNIQUE (project_id, type_id, rank)
);

-- ================================================
-- TABLE: project_relationship
-- ================================================

CREATE TABLE project_relationship (
	project_relationship_id serial NOT NULL,
	PRIMARY KEY (project_relationship_id),
	subject_project_id integer NOT NULL,
	FOREIGN KEY (subject_project_id) REFERENCES project (project_id) ON DELETE CASCADE,
	object_project_id integer NOT NULL,
	FOREIGN KEY (object_project_id) REFERENCES project (project_id) ON DELETE CASCADE,
	type_id integer NOT NULL,
	FOREIGN KEY (type_id) REFERENCES cvterm (cvterm_id) ON DELETE RESTRICT,
	CONSTRAINT project_relationship_c1 UNIQUE (subject_project_id, object_project_id, type_id)
);
COMMENT ON TABLE project_relationship IS 'A project can be composed of several smaller scale projects';
COMMENT ON COLUMN project_relationship.type_id IS 'The type of relationship being stated, such as "is part of".';


create table project_pub (
       project_pub_id serial not null,
       primary key (project_pub_id),
       project_id int not null,
       foreign key (project_id) references project (project_id) on delete cascade INITIALLY DEFERRED,
       pub_id int not null,
       foreign key (pub_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,
       constraint project_pub_c1 unique (project_id,pub_id)
);
create index project_pub_idx1 on project_pub (project_id);
create index project_pub_idx2 on project_pub (pub_id);

COMMENT ON TABLE project_pub IS 'Linking project(s) to publication(s)';


create table project_contact (
       project_contact_id serial not null,
       primary key (project_contact_id),
       project_id int not null,
       foreign key (project_id) references project (project_id) on delete cascade INITIALLY DEFERRED,
       contact_id int not null,
       foreign key (contact_id) references contact (contact_id) on delete cascade INITIALLY DEFERRED,
       constraint project_contact_c1 unique (project_id,contact_id)
);
create index project_contact_idx1 on project_contact (project_id);
create index project_contact_idx2 on project_contact (contact_id);

COMMENT ON TABLE project_contact IS 'Linking project(s) to contact(s)';


EOSQL
   
    
    print "Granting permissions to web_user...\n";
    foreach my $table (@tables) {
	my $seq = $table . "_" . $table . "_id_seq";
	
	$self->dbh->do("GRANT SELECT, INSERT, UPDATE ON $table to web_usr;"); 
	$self->dbh->do("GRANT SELECT, USAGE ON $seq to web_usr;");
	
    }
    print "You're done!\n";
    
}


return 1;
