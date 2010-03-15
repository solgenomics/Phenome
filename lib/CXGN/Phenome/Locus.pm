     

=head1 NAME

CXGN::Phenome::Locus 

SGN Locus object


=head1 SYNOPSIS

Access the phenome.locus table, find, add, and delete associated data 
(images, alleles, dbxrefs, owners, cvterms, publications, etc.)

=head1 AUTHOR

Naama Menda <nm249@cornell.edu>

=cut

package CXGN::Phenome::Locus;

use CXGN::DB::Connection;
use CXGN::Phenome::Allele;
use CXGN::Phenome::LocusSynonym;
use CXGN::Phenome::LocusMarker;
use CXGN::Phenome::Locus::LocusHistory;
use CXGN::Phenome::Individual;
use CXGN::Phenome::LocusDbxref;
use CXGN::Phenome::Locus::LocusRanking;
use CXGN::Transcript::Unigene;
use CXGN::Phenome::Schema;
use CXGN::Phenome::LocusGroup;


use CXGN::DB::Object;
use CXGN::Chado::Dbxref;

use base qw /  CXGN::DB::ModifiableI CXGN::Phenome::Locus::LocusRanking /;

=head2 new

 Usage: my $gene = CXGN::Phenome::Locus->new($dbh,$locus_id);
 Desc:
 Ret:    
 Args: $gene_id
 Side Effects:
 Example:

=cut

sub new {
    my $class = shift;
    my $dbh = shift;
    my $id= shift; # the primary key in the databaes of this object
    
    if (!$dbh->isa("CXGN::DB::Connection")) { 
	die "First argument to CXGN::Phenome::Locus constructor needs to be a database handle.";
    }
    my $self=$class->SUPER::new($dbh);   
   
    $self->set_locus_id($id);
    
    if ($id) {
	$self->fetch($id); #get the locus details   
	
	#associated markers
	my $locus_marker_query=$self->get_dbh()->prepare(
            "SELECT distinct locus_marker_id from phenome.locus_marker 
            JOIN sgn.marker_alias USING (marker_id)
            JOIN sgn.marker_experiment USING (marker_id) 
            JOIN sgn.marker_location USING (location_id) 
            JOIN sgn.map_version USING (map_version_id) 
            WHERE current_version = 't' AND locus_id=?");
	my @locus_marker;
	$locus_marker_query->execute($id);
	while (my ($lm) = $locus_marker_query->fetchrow_array() ) {
	    push @locus_marker, $lm;
	}
	foreach $lm_id (@locus_marker) {
	   
	    my $locus_marker_obj = CXGN::Phenome::LocusMarker->new($dbh, $lm_id);
	    $self->add_locus_marker($locus_marker_obj);
	}
	#dbxrefs
	my @dbxrefs= $self->get_dbxrefs();
	foreach my $d(@dbxrefs) { $self->add_dbxref(); } 
    }
    return $self;
}

=head2 new_with_symbol_and_species

 Usage: CXGN::Phenome::Locus->new_with_symbol_and_species($dbh, $symbol,$species)
 Desc:  instanciate a new locus object using a symbol and a common_name
 Ret:  a locus object
 Args: dbh, symbol, and common_name 
 Side Effects: 
 Example:

=cut

sub new_with_symbol_and_species {
    my $class = shift;
    my $dbh = shift;
    my $symbol = shift;
    my $species = shift;
    my $query = "SELECT locus_id FROM phenome.locus JOIN sgn.common_name using(common_name_id) WHERE locus_symbol=? AND common_name ilike ?";
    my $sth = $dbh->prepare($query);
    $sth->execute($symbol, $species);
    my ($id) = $sth->fetchrow_array();
    return $class->new($dbh, $id);
}



=head2 get_locus_ids_by_editor

 Usage:        my @loci = CXGN::Phenome::Locus::get_loci_by_editor($dbh, 239)
 Desc:         returns a list of locus ids that belong to the given
               editor. Class function.
 Args:         a database handle and a sp_person_id of the editor
 Side Effects: accesses the database
 Example:

=cut

sub get_locus_ids_by_editor {
    my $dbh = shift;
    my $sp_person_id = shift;
    my $query = "SELECT locus_id FROM phenome.locus JOIN phenome.locus_owner USING(locus_id)
                  WHERE locus_owner.sp_person_id=? AND locus.obsolete = 'f' ORDER BY locus.modified_date desc, locus.create_date desc";
    my $sth = $dbh->prepare($query);
    $sth->execute($sp_person_id);
    my @loci = ();
    while (my($locus_id) = $sth->fetchrow_array()) { 
	push @loci, $locus_id;
    }
    return @loci;
}


=head2 get_locus_ids_by_annotator

 Usage: my @loci=CXGN::Phenome::Locus::get_loci_by_annotator($dbh, $sp_person_id)
 Desc:         returns a list of locus ids that belong to the given
               contributing annotator. Class function.
 Args:         a database handle and a sp_person_id of the submitter
 Side Effects: accesses the database
 Example:

=cut

sub get_locus_ids_by_annotator {
    my $dbh = shift;
    my $sp_person_id = shift;
    
    my $query= "SELECT  distinct locus.locus_id, locus.modified_date FROM phenome.locus
                           LEFT JOIN phenome.locus_dbxref USING (locus_id)
                           LEFT JOIN phenome.locus_unigene using (locus_id)
                           LEFT JOIN phenome.locus_marker using (locus_id)
                           LEFT JOIN phenome.locus_alias using (locus_id)
                           LEFT JOIN phenome.locus2locus ON (phenome.locus.locus_id = locus2locus.subject_id 
                           OR phenome.locus.locus_id = locus2locus.subject_id )
                            JOIN phenome.allele USING (locus_id)
                            LEFT JOIN phenome.individual_allele USING (allele_id)
                            LEFT JOIN phenome.individual USING (individual_id)
                            LEFT JOIN phenome.individual_image USING (individual_id)
                            LEFT JOIN metadata.md_image USING (image_id)
                           
                            WHERE locus.updated_by=? OR locus_dbxref.sp_person_id=? OR locus_unigene.sp_person_id=?
                            OR locus_marker.sp_person_id=? OR allele.sp_person_id=? OR locus_alias.sp_person_id=?
                            OR individual_allele.sp_person_id=? OR metadata.md_image.sp_person_id=? OR locus2locus.sp_person_id =?
                            ORDER BY locus.modified_date DESC";
    
  
    my $sth = $dbh->prepare($query);
    $sth->execute($sp_person_id, $sp_person_id, $sp_person_id, $sp_person_id, $sp_person_id, $sp_person_id, $sp_person_id, $sp_person_id, $sp_person_id);
    my @loci = ();
    while (my($locus_id, $modified_date) = $sth->fetchrow_array()) { 
	push @loci, $locus_id;
    }
    return @loci;
}



sub fetch {
    my $self=shift;
    my $dbh=$self->get_dbh();
    
    my $locus_query = "SELECT locus_id,locus_name, locus_symbol, original_symbol, gene_activity, description,  locus.sp_person_id, locus.create_date, locus.modified_date, linkage_group, lg_arm, common_name, common_name_id,  updated_by, locus.obsolete 
                    FROM phenome.locus 
                    JOIN sgn.common_name USING(common_name_id)
                    WHERE locus_id=?";
    my $sth=$dbh->prepare($locus_query);
    $sth->execute($self->get_locus_id());

    my ($locus_id,$locus_name,$locus_symbol,$original_symbol, $gene_activity, $description, $sp_person_id, $create_date, $modified_date, $chromosome, $arm, $common_name, $common_name_id, $updated_by, $obsolete)=$sth->fetchrow_array();
    $self->set_locus_id($locus_id);
    $self->set_locus_name($locus_name);
    $self->set_locus_symbol($locus_symbol);
   
    $self->set_original_symbol($original_symbol);
    $self->set_gene_activity($gene_activity);
    $self->set_description($description);

    $self->set_sp_person_id($sp_person_id);
    $self->set_create_date($create_date);
    $self->set_modification_date($modified_date);
    $self->set_linkage_group($chromosome);
    $self->set_lg_arm($arm);
    $self->set_common_name($common_name);
    $self->set_common_name_id($common_name_id);
    $self->set_updated_by($updated_by);
    $self->set_obsolete($obsolete);
}

=head2 exists_in_database

 Usage: my $existing_locus_id = CXGN::Phenome::Locus::exists_in_database();
 Desc:  check if a locus symbol or name for a given organism exists in the database  
 Ret:   an error message for the given symbol, name, and common_name_id
 Args:   
 Side Effects: none
 Example:

=cut


sub exists_in_database {
    my $self = shift;
    my $locus_name=shift;
    my $locus_symbol=shift;
      
    my $locus_id= $self->get_locus_id();
    my $common_name_id= $self->get_common_name_id();
    if (!$locus_name) { $locus_name=$self->get_locus_name(); }
    if (!$locus_symbol) { $locus_symbol=$self->get_locus_symbol(); }
    $self->d("Locus.pm: exists_in _database--**$locus_name, $locus_symbol \n");
    
    
    my $name_query = "SELECT locus_id, obsolete 
                        FROM phenome.locus
                        WHERE locus_name ILIKE ? and common_name_id = ? ";
    my $name_sth = $self->get_dbh()->prepare($name_query);
    $name_sth->execute($locus_name, $common_name_id );
    my ($name_id, $name_obsolete)= $name_sth->fetchrow_array();
    
    my $symbol_query = "SELECT locus_id, obsolete
                         FROM phenome.locus
                         WHERE locus_symbol ILIKE ? and common_name_id = ? ";
    my $symbol_sth = $self->get_dbh()->prepare($symbol_query);
    $symbol_sth->execute($locus_symbol, $common_name_id );
    my ($symbol_id, $symbol_obsolete)  = $symbol_sth->fetchrow_array();
    
    
    #loading new locus- $locus_id is undef
    if (!$locus_id && ($name_id || $symbol_id) ) {
	my $message = 1;
	if($name_id){
	    $message = "Existing name $name_id";
	}
	elsif($symbol_id){
	    $message = "Existing symbol $symbol_id";
	}
	$self->d("***$message\n");
	return ( $message ) ; 
    }
    #trying to update a locus.. if both the name and symbol remain- it's probably an update of 
    #the other fields in the form
    if ($locus_id && $symbol_id) {
	if ( ($name_id==$locus_id) && ($symbol_id==$locus_id) ) {
	    $self->d("--locus.pm exists_in_database returned 0.......\n"); 
	    return 0; 
	    #trying to update the name and/or the symbol
	} elsif ( ($name_id!=$locus_id && $name_id) || ($symbol_id!=$locus_id && $symbol_id)) {
	    my $message = " Can't update an existing locus $locus_id name:$name_id symbol:$symbol_id.";
	    $self->d("++++Locus.pm exists_in_database:  $message\n");
	    return ( $message );
	    # if the new name or symbol we're trying to update/insert do not exist in the locus table.. 
	} else {
	    $self->d("--locus.pm exists_in_database returned 0.......\n");
	    return 0; 
	}
    }
}

sub store { 
    my $self = shift;

    #add another check here with a die/error message for loading scripts
    my $exists=  $self->exists_in_database();
    die "Locus exists in database! Cannot insert or update! \n $exists \n " if $exists;
    
    my $locus_id=$self->get_locus_id();
    
    if ($locus_id) {
	$self->store_history();
	
    	my $query = "UPDATE phenome.locus SET
                       locus_name = ?,
                       locus_symbol = ?,
                       original_symbol = ?,
                       gene_activity = ?,
                       description= ?,
                       linkage_group= ?,
                       lg_arm = ?,
                       updated_by = ?,
                       modified_date = now(),
                       obsolete=?
                       where locus_id= ?";
	
	
	my $sth= $self->get_dbh()->prepare($query);
	$sth->execute($self->get_locus_name, $self->get_locus_symbol,  $self->get_original_symbol, $self->get_gene_activity, $self->get_description, $self->get_linkage_group(), $self->get_lg_arm(), $self->get_updated_by(), $self->get_obsolete(), $locus_id );
	
	foreach my $dbxref ( @{$self->{locus_dbxrefs}} )   {
	    my $locus_dbxref_obj= CXGN::Phenome::LocusDbxref->new($self->get_dbh());
	    #$locus_dbxref_obj->store(); # what do I want to store here?
	}
	$self->d("Locus.pm store: Updated locus $locus_id ......+\n");
	#Update locus_alias 'preferred' field
	$self->update_locus_alias();
    }
    else { 
	
	eval {
	    my $query = "INSERT INTO phenome.locus (locus_name, locus_symbol, original_symbol, gene_activity, description, linkage_group, lg_arm,  common_name_id, create_date) VALUES(?,?,?,?,?,?,?,?, now())";
	    
	    my $sth= $self->get_dbh()->prepare($query);
	    $sth->execute($self->get_locus_name, $self->get_locus_symbol, $self->get_original_symbol, $self->get_gene_activity, $self->get_description, $self->get_linkage_group(), $self->get_lg_arm(), $self->get_common_name_id);
	    
	    $locus_id= $self->get_dbh->last_insert_id("locus", "phenome" );
	    $self->set_locus_id($locus_id);
	    
	    my $locus_owner_query="INSERT INTO phenome.locus_owner (locus_id, sp_person_id) VALUES (?,?)";
	    my $locus_owner_sth=$self->get_dbh()->prepare($locus_owner_query);
	    $locus_owner_sth->execute($locus_id, $self->get_sp_person_id());
	    
	    my $alias_query= "INSERT INTO phenome.locus_alias(locus_id, alias, preferred) VALUES (?, ?,'t')";
	    my $alias_sth= $self->get_dbh()->prepare($alias_query);
	    $alias_sth->execute($self->get_locus_id(), $self->get_locus_symbol());
	    
	    #the following query will insert a 'dummy' default allele. Each locus must have a default allele.
	    # This is important for associating individuals with loci. The locus_display code masks the dummy alleles.
	    my $allele= CXGN::Phenome::Allele->new($self->get_dbh());
	    $allele->set_locus_id($locus_id);
	    $allele->set_allele_symbol( uc($self->get_locus_symbol) );
	    $allele->set_is_default('t');
	    $allele->store();
	    
	    $self->d("***#####Locus.pm store: inserting new locus $locus_id....\n");
	};
    }
    if ($@) { warn "locus.pm store failed! \n $@ \n" }
    return $locus_id;
    
}

=head2 delete 

 Usage: $self->delete()
 Desc:  set the locus to obsolete=t
 Ret:   nothing
 Args:  none
 Side Effects: sets locus name and symbol to 'ob$locus_id-$locus_name'
obsoletes the associated alleles (see Allele.pm: delete() )
 Example:
=cut

sub delete { 
    my $self = shift;
    my ($symbol, $name);
    my $locus_id = $self->get_locus_id();
    $self->set_locus_symbol("ob". $self->get_locus_id() . "-" .$self->get_locus_symbol() );
    $self->set_locus_name("ob" . $self->get_locus_id() . "-" . $self->get_locus_name() );
    my $ob=$self->get_obsolete();
    if ($ob eq 'f' && $locus_id)  {
	$self->d("Locus.pm is obsoleting locus  " . $self->get_locus_id() . "(obsolete=$ob)!!!!\n");
	$self->set_obsolete('t');
	$self->store();
    }else { 
	$self->d("trying to delete a locus that has not yet been stored to db.\n");
    }    
}		     


=head2 remove_allele

 Usage:  $self->remove_allele($allele_id)
 Desc:   set an allele of this locus to obsolete
 Ret:    nothing
 Args: $allele_id
 Side Effects: updates the obsolete field in the allele table to 't'
 Example:
=cut

sub remove_allele { 
    my $self = shift;
    my $allele_id = shift;
    my $query = "UPDATE phenome.allele
                        SET obsolete= 't'
                        WHERE locus_id=? AND allele_id=?";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_locus_id(), $allele_id);
}

=head2 remove_locus_alias

 Usage: $self->remove_locus_alias($locus_alias_id)
 Desc:  delete a locus alias from the locus_alias table
 Ret:   nothing
 Args: $locus_alias_id
 Side Effects: deletes a row from the locus_alias table
 Example:


=cut
sub remove_locus_alias { 
    my $self = shift;
    my $locus_synonym_id = shift;
    my $query = "DELETE FROM phenome.locus_alias WHERE locus_id=? AND locus_alias_id=?";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_locus_id(), $locus_synonym_id);
}

=head2 update_locus_alias

 Usage: $self->update_locus_alias()
 Desc:  after updating the locus synonym field, we need to make that synonym the 
        'preferred' alias, and set the currently preferred one to 'f' 
 Ret:   nothing
 Args:  none
 Side Effects: updating rows in the locus_alias table
 Example:

=cut

sub update_locus_alias {
    my $self=shift;
    my $symbol= $self->get_locus_symbol();
    my @aliases= $self->get_locus_aliases();
       
    foreach my $a ( @aliases) {
	my $alias=$a->get_locus_alias();
	if ($alias eq $symbol) {  
	    $self->d("alias = $alias , symbol =$symbol, preferred=" . $a->get_preferred() . " Setting prefrred = 't'\n");
	    $a->set_preferred('t');
	    $a->store();
	}
	elsif ($a->get_preferred() ==1) {
	    $self->d( "alias = $alias , symbol =$symbol, preferred=" . $a->get_preferred() . " Setting prefrred = 'f'\n");
	    $a->set_preferred('f'); 
	    $a->store();
	}
    }
}



=head2 get_unigenes

 Usage: $self->get_unigenes(1)
 Desc:  find unigenes associated with the locus
 Ret:   list of (lite) unigene objects (without the sequences- much faster) 
 Args:  optional boolean - get a list of full unigene objects 
        (much slower, but important if you want to access the sequences of the unigens) 
 Side Effects: none
 Example:

=cut

sub get_unigenes {
    my $self=shift;
    my $full = shift;
    my $query = "SELECT unigene_id FROM phenome.locus_unigene WHERE locus_id=? AND obsolete = 'f'";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_locus_id());
    my $unigene;
    my @unigenes=();
    while (my ($unigene_id) = $sth->fetchrow_array()) {
	if ($full)  { $unigene = CXGN::Transcript::Unigene->new($self->get_dbh(), $unigene_id); }
	else { $unigene = CXGN::Transcript::Unigene->new_lite_unigene($self->get_dbh(), $unigene_id); }
	push @unigenes, $unigene;
    }
    return @unigenes;
}

=head2 get_locus_unigene_id

 Usage: my $locus_unigene_id= $locus->get_locus_unigene_id($unigene_id)
 Desc:  find the locus_unigene database id for a given unigene id
        useful for manipulating locus_unigene table (like obsoleting a locus-unigene association)
        since we do not have a LocusUnigene object (not sure an object is necessary if all is done from the Locus object)
        
 Ret: a database id from the table phenome.locus_unigene
 Args: $unigene_id
 Side Effects:
 Example:

=cut

sub get_locus_unigene_id {
    my $self=shift;
    my $unigene_id=shift;
    my $query= "SELECT locus_unigene_id FROM phenome.locus_unigene 
                WHERE locus_id=? AND unigene_id=?";
    my $sth=$self->get_dbh()->prepare($query);
    $sth->execute($self->get_locus_id(), $unigene_id);
    my ($locus_unigene_id) = $sth->fetchrow_array();
    return $locus_unigene_id;
}

=head2 add_unigene

 Usage: $self->add_unigene($unigene_id, $sp_person_id)
 Desc:  store a unigene-locus association in the database. If the link exists the function will set obsolete=f
 Ret:   database id
 Args:  unigene_id, sp_person_id
 Side Effects: access the database. Adds a locus_dbxref for SolCyc reactions which are linked to $unigene_id 
               (see table unigene_dbxref)
 Example:

=cut

sub add_unigene {
    my $self=shift;
    my $unigene_id=shift;
    my $sp_person_id=shift;
    my $existing_id= $self->get_locus_unigene_id($unigene_id);
    
    if ($existing_id) {
	$self->d("Locus::add_unigene is updating locus_unigene_id $existing_id!!!!!!");
	my $u_query="UPDATE phenome.locus_unigene SET obsolete='f' WHERE locus_unigene_id=?";
	my $u_sth=$self->get_dbh()->prepare($u_query);
	$u_sth->execute($existing_id);
	return $existing_id;
    }else {
	$self->d( "Locus:add_unigene is inserting a new unigene $unigene_id for locus " . $self->get_locus_id() . " (by person $sp_person_id) !!!"); 
	my $query="Insert INTO phenome.locus_unigene (locus_id, unigene_id,sp_person_id) VALUES (?,?,?)";
	my $sth=$self->get_dbh->prepare($query);
	$sth->execute($self->get_locus_id(), $unigene_id, $sp_person_id);
	my $id= $self->get_currval("phenome.locus_unigene_locus_unigene_id_seq");
	return $id;
    }
    #se if the unigene has solcyc links
    my $unigene= CXGN::Transcript::Unigene->new($dbh, $unigene_id);
    my @u_dbxrefs= $unigene->get_dbxrefs();
    foreach my $d(@u_dbxrefs) {
	$self->add_locus_dbxref($d, undef, $sp_person_id) if $d->get_db_name() eq 'solcyc_images';
    }
}

=head2 obsolete_unigene

 Usage: $self->obsolete_unigene
 Desc:  set locus_unigene to obsolete
 Ret:   nothing 
 Args:  locus_unigene_id
 Side Effects: none
 Example:

=cut

sub obsolete_unigene {
    my $self=shift;
    my $lu_id= shift;
    my $u_query="UPDATE phenome.locus_unigene SET obsolete='t' WHERE locus_unigene_id=?";
    my $u_sth=$self->get_dbh()->prepare($u_query);
    $u_sth->execute($lu_id);
}


=head2 get_associated_loci  DEPRECATED. SEE get_locusgroups


 Usage:        my @locus_ids = $locus->get_associated_loci()
 Desc:         return the loci that are associated to this 
               locus from the locus2locus table
 Ret:          a list of locus ids
 Args:        none
 Side Effects: none
 Example:

=cut


sub get_associated_loci {
    warn("DEPRECATED. SEE get_locusgroups() !!!!!!!\n");

    my $self = shift;
    my $query = "SELECT object_id FROM phenome.locus2locus WHERE obsolete = 'f' AND subject_id=?";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_locus_id());
    my @associated_loci;
    while (my ($associated_locus) = $sth->fetchrow_array()) {
	push @associated_loci, $associated_locus;
    }
    return @associated_loci;
    
}


=head2 get_reciprocal_loci DEPRECATED - SEE get_locusgroups() 
 Usage:         my $locus_ids = $locus->get_reciprocal_loci()
 Desc:          returns the loci that this locus is associated to
                in the locus2locus table
 Ret:
 Args:
 Side Effects:
 Example:

=cut


sub get_reciprocal_loci {
    warn("DEPRECATED. SEE get_locusgroups() !!!!!!!\n");
    my $self = shift;
    my $query = "SELECT DISTINCT subject_id FROM phenome.locus2locus WHERE obsolete = 'f' AND object_id=?";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_locus_id());
    my @reciprocal_loci;
    while (my ($reciprocal_locus) = $sth->fetchrow_array()) {
	push @reciprocal_loci, $reciprocal_locus;
    }
    return @reciprocal_loci;


}

=head2 get_subject_locus2locus_objects   DEPRECATED. SEE get_locusgroups() 


 Usage:        @l2l = $locus->get_subject_locus2locus_objects()
 Desc:         returns all associated locus2locus objects, including
               object and subject id based ones.
 Ret:          a list of CXGN::Phenome::Locus2Locus objects
 Args:
 Side Effects:
 Example:

=cut

sub get_subject_locus2locus_objects {
    warn("DEPRECATED. SEE get_locusgroups() !!!!!!!\n");

    my $self = shift;
    my @l2l = ();
    my $q = "SELECT DISTINCT locus2locus_id FROM phenome.locus2locus WHERE (subject_id=?) and obsolete='f'";
    my $sth = $self->get_dbh()->prepare($q);
    $sth->execute($self->get_locus_id());

    while( my ($l2l) =  $sth->fetchrow_array()) {
	push @l2l, CXGN::Phenome::Locus2Locus->new($self->get_dbh(), $l2l);
    }
    return @l2l;
    
}


=head2 get_object_locus2locus_objects     DEPRECATED. SEE get_locusgroups()


 Usage:        @l2l = $locus->get_object_locus2locus_objects()
 Desc:         returns all associated locus2locus objects, including
               based ones.
 Ret:          a list of CXGN::Phenome::Locus2Locus objects
 Args:
 Side Effects:
 Example:

=cut

sub get_object_locus2locus_objects {
    warn("DEPRECATED. SEE get_locusgroups() !!!!!!!\n");

    my $self = shift;
    my @l2l = ();
    my $q = "SELECT DISTINCT locus2locus_id FROM phenome.locus2locus WHERE object_id=? and obsolete='f'";
    my $sth = $self->get_dbh()->prepare($q);
    $sth->execute($self->get_locus_id());

    while( my ($l2l) =  $sth->fetchrow_array()) {
	push @l2l, CXGN::Phenome::Locus2Locus->new($self->get_dbh(), $l2l);
    }
    return @l2l;
    
}

=head2 add_related_locus

 Usage: $self->add_related_locus($locus_id)
 Desc:  an accessor for building an associated locus list for the locus 
 Ret:   nothing
 Args:  locus symbol
 Side Effects:
 Example:

=cut

sub add_related_locus {
    my $self=shift;
    my $locus=shift; 
    push @{ $self->{related_loci} }, $locus;
}


=head2 accessors available (get/set)
 
    locus_id
    locus_name
    locus_symbol
    original_symbol
    gene_activity
    description
    linkage_group
    lg_arm
    common_name
    common_name_id
=cut

sub get_locus_id {
  my $self=shift;
  return $self->{locus_id};

}

sub set_locus_id {
  my $self=shift;
  $self->{locus_id}=shift;

}

sub get_locus_name {
  my $self=shift;
  return $self->{locus_name};

}

sub set_locus_name {
  my $self=shift;
  $self->{locus_name}=shift;
}

sub get_locus_symbol {
  my $self=shift;
  return $self->{locus_symbol};

}

sub set_locus_symbol {
  my $self=shift;
  $self->{locus_symbol}=shift;
}


sub get_original_symbol {
  my $self=shift;
  return $self->{original_symbol};

}

sub set_original_symbol {
  my $self=shift;
  $self->{original_symbol}=shift;
}

sub get_gene_activity {
  my $self=shift;
  return $self->{gene_activity};

}

sub set_gene_activity {
  my $self=shift;
  $self->{gene_activity}=shift;
}


sub get_description {
  my $self=shift;
  return $self->{description};

}

sub set_description {
  my $self=shift;
  $self->{description}=shift;
}


sub get_linkage_group {
  my $self=shift;
  return $self->{linkage_group};

}

sub set_linkage_group {
  my $self=shift;
  $self->{linkage_group}=shift;
}

=head2 accessors get_lg_arm, set_lg_arm

 Usage:
 Desc:
 Property:     the position of the locus on the linkage group
               in terms of linkage group arms ["long", "short", undef] 
 Side Effects:
 Example:

=cut

sub get_lg_arm {
  my $self=shift;
  return $self->{lg_arm};

}

sub set_lg_arm {
  my $self=shift;
  $self->{lg_arm}=shift;
}

=head2 accessors get_common_name, set_common_name

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_common_name {
  my $self=shift;
  return $self->{common_name};

}

sub set_common_name {
  my $self=shift;
  $self->{common_name}=shift;
}


sub get_common_name_id {
  my $self=shift;
  return $self->{common_name_id};

}

sub set_common_name_id {
  my $self=shift;
  $self->{common_name_id}=shift;
}


=head2 add_locus_alias

 Usage: $self->add_locus_alias($locus_synonym_object)
 Desc:  add an alias to the locus
 Ret:   a locus_alias id
 Args:  LocusSynonym object
 Side Effects: accesses the database
 Example:

=cut

sub add_locus_alias {
    my $self=shift;
    my $locus_alias = shift; #LocusSynonym object!!
    $locus_alias->set_locus_alias_id(); #set the id to undef in case of the function was called from the merge_locus function
    $locus_alias->set_locus_id($self->get_locus_id());
    my $symbol = $self->get_locus_symbol();
    #if the locus symbol and the alias are the same, then set the new alias to preferred = 't'
    if ($symbol eq $locus_alias->get_locus_alias()) {
	$locus_alias->set_preferred('t');
    }
    my $id=$locus_alias->store();
    return $id;
}


=head2 get_locus_aliases

 Usage: $self->get_locus_aliases()
 Desc:  find the aliases of a locus
 Ret:    list of LocusSynonym objects
 Args:   optional : preffered and obsolete booleans
 Side Effects: none
 Example:

=cut

sub get_locus_aliases {
    my $self=shift;
    my ($preferred, $obsolete) = @_;
    my $query="SELECT locus_alias_id from phenome.locus_alias WHERE locus_id=? ";
    $query .= " AND preferred = '$preferred' " if $preferred;
    $query .= " AND obsolete =  '$obsolete' " if $obsolete;
    my $sth=$self->get_dbh()->prepare($query);
    my @locus_synonyms;
    $sth->execute($self->get_locus_id());
    while (my ($ls_id) = $sth->fetchrow_array()) {
	my $lso=CXGN::Phenome::LocusSynonym->new($self->get_dbh(), $ls_id);
	push @locus_synonyms, $lso;
    }
    return @locus_synonyms;
}

=head2 add_allele

 Usage: $self->add_allele($allele)
 Desc:  add an allele to the locus
 Ret:   the new allele_id
 Args:  allele object
 Side Effects: accessed the database, Calls Allele->store().
 Example:

=cut

sub add_allele {
    my $self=shift;
    my $allele=shift; #allele object
       
    $allele->set_locus_id($self->get_locus_id() );
    my $id = $allele->store();
    return $id;
}

=head2 add_allele_symbol

  Usage: $self->add_allele_symbol($allele_symbol)
 Desc:  an accessor for building an allele list for the locus 
 Ret:   nothing
 Args:  allele symbol
 Side Effects:
 Example:

=cut

sub add_allele_symbol {
    my $self=shift;
    my $allele=shift; #allele symbol
    push @{ $self->{allele_symbols} }, $allele;
}

=head2 get_alleles

 Usage: my @alleles=$self->get_alleles()
 Desc:   find the alleles associated with the locus
 Ret:    a list of allele objects 
 Args:   none 
 Side Effects: none 
 Example:

=cut

sub get_alleles {
    my $self=shift;
    $self->d("Getting alleles....   \n\n");
    my $allele_query=("SELECT allele_id FROM phenome.allele WHERE locus_id=? AND obsolete='f' AND is_default='f'"); 
    my $sth=$self->get_dbh()->prepare($allele_query);
    my @alleles=();
    $sth->execute($self->get_locus_id());
    while (my ($a_id) = $sth->fetchrow_array()) {
	my $allele= CXGN::Phenome::Allele->new($self->get_dbh(), $a_id);
	push  @alleles, $allele;
    } 
    return @alleles;
}
=head2 get_default_allele

 Usage: $self->get_default_allele()
 Desc:  find the database id from the default allele
 Ret:   database id 
 Args:  none
 Side Effects: none
 Example:

=cut

sub get_default_allele {
    my $self=shift;
    my $query = "SELECT allele_id from phenome.allele 
                WHERE locus_id = ? AND is_default = 't'";
    my $sth=$self->get_dbh()->prepare($query);
    $sth->execute($self->get_locus_id());
    my ($allele_id) = $sth->fetchrow_array();
    return $allele_id;
}

=head2 add_synonym

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub add_synonym {
    my $self=shift;
    my $synonym=shift; #synonym
    push @{ $self->{synonyms} }, $synonym;
}


=head2 add_dbxref

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut


sub add_dbxref {
    my $self=shift;
    my $dbxref=shift; #dbxref object
    push @{ $self->{dbxrefs} }, $dbxref;
}

=head2 get_dbxrefs

 Usage:        $locus->get_dbxrefs();
 Desc:         get all the dbxrefs associated with a locus
 Ret:          array of dbxref objects
 Args:         none
 Side Effects: accesses the database
 Example:

=cut

sub get_dbxrefs {
    my $self=shift;
    my $locus_id=$self->get_locus_id();
    
    my $dbxref_query="SELECT locus_dbxref.dbxref_id from phenome.locus_dbxref JOIN public.dbxref USING(dbxref_id) WHERE locus_id=? ORDER BY public.dbxref.accession";
    my $sth=$self->get_dbh()->prepare($dbxref_query);
    my $dbxref;
    my @dbxrefs=(); #an array for storing dbxref objects
    $sth->execute($locus_id);
    while (my ($d) = $sth->fetchrow_array() ) {
	$dbxref= CXGN::Chado::Dbxref->new($self->get_dbh(), $d);
	push @dbxrefs, $dbxref;
    }
    
    return @dbxrefs;
}
=head2 get_dbxrefs_by_type

 Usage:        $locus->get_dbxrefs_by_type("ontology");
 Desc:         get all the dbxrefs terms associated with a locus
 Ret:          array of dbxref objects
 Args:         type (ontology, literature, genbank)
 Side Effects: accesses the database
 Example:

=cut

sub get_dbxrefs_by_type {
    my $self=shift;
    my $type = shift;
    my $locus_id=$self->get_locus_id();
    my $query;
    my $dbh = $self->get_dbh();
   
    if ($type eq 'ontology') {
	$query="SELECT locus_dbxref.dbxref_id from phenome.locus_dbxref 
               JOIN public.dbxref USING(dbxref_id) 
               JOIN public.cvterm USING (dbxref_id) 
               WHERE locus_id=? ORDER BY public.dbxref.accession";
    }elsif ($type eq 'literature') {
	$query="SELECT locus_dbxref.dbxref_id from phenome.locus_dbxref 
	        JOIN public.dbxref USING(dbxref_id) 
                JOIN public.db USING (db_id) 
                WHERE locus_id=? AND db.name IN ('PMID','SGN_ref') ORDER BY public.dbxref.accession";
    }elsif ($type eq 'genbank') {
	$query="SELECT locus_dbxref.dbxref_id from phenome.locus_dbxref 
	        JOIN public.dbxref USING(dbxref_id) 
                JOIN public.db USING (db_id) 
                WHERE locus_id=? AND db.name IN ('DB:GenBank_GI') 
                AND locus_dbxref.obsolete= 'f' ORDER BY public.dbxref.accession";
    }else { warn "dbxref type '$type' not recognized! \n" ; return undef; }
    my $sth=$self->get_dbh()->prepare($query);
    my $dbxref;
    my @dbxrefs=(); #an array for storing dbxref objects
    $sth->execute($locus_id);
    while (my ($d) = $sth->fetchrow_array() ) {
	$dbxref= CXGN::Chado::Dbxref->new($self->get_dbh(), $d);
	push @dbxrefs, $dbxref;
    }
    return @dbxrefs;
}

=head2 get_dbxref_lists

 Usage:        $locus->get_dbxref_lists();
 Desc:         get all the dbxrefs terms associated with a locus
 Ret:          hash of 2D arrays . Keys are the db names values are  [dbxref object, locus_dbxref.obsolete]
 Args:         none
 Side Effects: none
 Example:

=cut

sub get_dbxref_lists {
    my $self=shift;
    my %dbxrefs;
    my $query= "SELECT db.name, dbxref.dbxref_id, locus_dbxref.obsolete FROM locus_dbxref
               JOIN public.dbxref USING (dbxref_id) JOIN public.db USING (db_id) 
               WHERE locus_id= ? ORDER BY db.name, dbxref.accession";
    my $sth=$self->get_dbh()->prepare($query);
    $sth->execute($self->get_locus_id());
    while (my ($db_name, $dbxref_id, $obsolete) = $sth->fetchrow_array()) {
	push @ {$dbxrefs{$db_name} }, [CXGN::Chado::Dbxref->new($self->get_dbh(), $dbxref_id), $obsolete] ;
    }
    return %dbxrefs;
}


=head2 get_locus_dbxrefs

 Usage: $self->get_locus_dbxrefs()
 Desc:  get the LocusDbxref objects associated with this locus
 Ret:   a hash of arrays. Keys=db_name, values = lists of LocusDbxref objects
 Args:  none
 Side Effects: none
 Example:

=cut

sub get_locus_dbxrefs {
    my $self=shift;
     my %lds;
    my $query= "SELECT db.name, locus_dbxref.locus_dbxref_id FROM locus_dbxref
               JOIN public.dbxref USING (dbxref_id) JOIN public.db USING (db_id) 
               WHERE locus_id= ? ORDER BY db.name, dbxref.accession";
    my $sth=$self->get_dbh()->prepare($query);
    $sth->execute($self->get_locus_id());
    while (my ($db_name, $ld_id) = $sth->fetchrow_array()) {
	push @ {$lds{$db_name} }, CXGN::Phenome::LocusDbxref->new($self->get_dbh(), $ld_id) ;
    }
    return %lds;
}


=head2 add_locus_marker

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub add_locus_marker {
    my $self=shift;
    push @{ $self->{locus_markers} }, shift;
}

=head2 get_locus_markers

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_locus_markers {
  my $self=shift;
  return @{$self->{locus_markers}};
}


=head2 get_locus_dbxref

 Usage:        $locus->get_locus_dbxref($dbxref)
 Desc:         access locus_dbxref object for a given locus and 
               its dbxref object
 Ret:          a LocusDbxref object
 Args:         dbxref object
 Side Effects: accesses the database
 Example:

=cut

sub get_locus_dbxref {
    my $self=shift;
    my $dbxref=shift; # my dbxref object..
    my $query="SELECT locus_dbxref_id from phenome.locus_dbxref
                                        WHERE locus_id=? AND dbxref_id=? ";
    my $sth=$self->get_dbh()->prepare($query);
    $sth->execute($self->get_locus_id(), $dbxref->get_dbxref_id() );
    my ($locus_dbxref_id) = $sth->fetchrow_array();
    my $locus_dbxref= CXGN::Phenome::LocusDbxref->new($self->get_dbh(), $locus_dbxref_id);
    return $locus_dbxref;
}

=head2 add_locus_dbxref

 Usage:        $locus->add_locus_dbxref($dbxref_object, 
					$locus_dbxref_id, 
					$sp_person_id);
 Desc:         adds a locus_dbxref relationship
 Ret:   database id 
 Args:
 Side Effects: calls store function in LocusDbxref
 Example:

=cut

sub add_locus_dbxref {
    my $self=shift;
    my $dbxref=shift; #dbxref object
    my $locus_dbxref_id=shift;
    my $sp_person_id=shift;
    
    my $locus_dbxref=CXGN::Phenome::LocusDbxref->new($self->get_dbh(), $locus_dbxref_id );
    $locus_dbxref->set_locus_id($self->get_locus_id() );
    $locus_dbxref->set_dbxref_id($dbxref->get_dbxref_id() );
    $locus_dbxref->set_sp_person_id($sp_person_id);
    if (!$dbxref->get_dbxref_id()) {return undef };
    
    my $id = $locus_dbxref->store();
    return $id;
}

=head2 function get_individuals

  Synopsis:	my @individuals=$locus->get_individuals();
  Arguments:	none
  Returns:	array of individual objects
  Side effects:	
  Description:	selects the ids of all individuals associated with the locus from
                phenome.individual_locus linking table and and array of these individual objects.

=cut

sub get_individuals {
    my $self = shift;
    my $query = "SELECT individual_id FROM phenome.individual_allele 
                 JOIN phenome.allele USING (allele_id)
                 JOIN phenome.individual USING (individual_id)
                 WHERE locus_id=? AND allele.obsolete = 'f' AND individual_allele.obsolete = 'f'
                ";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_locus_id());
    my $individual;
    my @individuals= ();
    while (my ($individual_id) = $sth->fetchrow_array()) { 
	$individual = CXGN::Phenome::Individual->new($self->get_dbh(), $individual_id);
	push @individuals, $individual;
    }
    return @individuals;
}


=head2 get_locus_registry_symbol

 Usage: $locus->get_locus_registry_symbol()
 Desc:  get the registered symbol of a locus
 Ret:   a  registry object?
 Args:   none
 Side Effects:
 Example:

=cut

sub get_locus_registry_symbol {
    my $self=shift;

    my $query=$self->get_dbh()->prepare("SELECT registry_id from phenome.locus_registry
                                        WHERE locus_id=?  ");
    $query->execute($self->get_locus_id() );
    my ($registry_id) = $query->fetchrow_array();
    if ($registry_id) {
	my $registry= CXGN::Phenome::Registry->new($self->get_dbh(), $registry_id);
	return $registry;
    }else { return undef; }
}



=head2 store_history

 Usage:        $self->store_history()
 Desc:         Inserts the current fields of a locus object into 
               the locus_history table before updating the locus details
 Ret:   
 Args: none
 Side Effects: 
 Example:

=cut

sub store_history {

    my $self=shift;
    my $locus=CXGN::Phenome::Locus->new($self->get_dbh(), $self->get_locus_id() );
    $self->d( "Locus.pm:*Storing history for locus " . $self->get_locus_id() . "\n"); 
    my $history_query = "INSERT INTO phenome.locus_history (locus_id, locus_name, locus_symbol, original_symbol,gene_activity,locus_description,linkage_group, lg_arm, sp_person_id, updated_by, obsolete, create_date) 
                             VALUES(?,?,?,?,?,?,?,?,?,?,?, now())";
    my $history_sth= $self->get_dbh()->prepare($history_query);
    
    $history_sth->execute($locus->get_locus_id(), $locus->get_locus_name(), $locus->get_locus_symbol(),  $locus->get_original_symbol(), $locus->get_gene_activity(), $locus->get_description(), $locus->get_linkage_group(), $locus->get_lg_arm(), $locus->get_sp_person_id, $self->get_updated_by(), $locus->get_obsolete() );
    
    
}

=head2 show_history

  Usage: $locus->show_history();
 Desc:   Selects the data from locus_history table for a locus object 
 Ret:    
 Args:    
 Side Effects:
 Example:

=cut

sub show_history {
    my $self=shift;
    my $locus_id= $self->get_locus_id();
    my $history_query=$self->get_dbh()->prepare("SELECT locus_history_id FROM phenome.locus_history WHERE locus_id=?"); 
    my @history;
    $history_query->execute($locus_id);
    while (my ($history_id) = $history_query->fetchrow_array()) { 
	my $history_obj = CXGN::Phenome::Locus::LocusHistory->new($self->get_dbh(), $history_id);
	push @history, $history_obj;
    }
    return @history;
}

=head2 get_associated_registry

 Usage:
 Desc:
 Ret: the Registry symbol
 Args:
 Side Effects:
 Example:

=cut

sub get_associated_registry{
    my $self=shift;
    my $locus_id= $self->get_locus_id();
    my $registry_query=$self->get_dbh()->prepare("SELECT locus_registry.registry_id, registry.name FROM phenome.locus_registry JOIN phenome.registry USING (registry_id) WHERE locus_id=?");
    $registry_query->execute($locus_id);
    my ($registry_id, $name) = $registry_query->fetchrow_array();
    return $name;
}

=head2 associated_publication

 Usage: my $associated= $locus->associated_publication($accession)
 Desc:  checks if a publication is already associated with the locus
 Ret:  a dbxref_id
 Args: publication accession (pubmed ID) 
 Side Effects:
 Example:

=cut

sub associated_publication {

    my $self=shift;
    my $accession=shift;
    my $query = $self->get_dbh()->prepare("SELECT dbxref_id FROM phenome.locus_dbxref JOIN dbxref USING (dbxref_id) WHERE locus_id = ? AND dbxref.accession = ? AND obsolete = 'f'");
    $query->execute($self->get_locus_id(), $accession);
    my ($is_associated) = $query->fetchrow_array();
    return $is_associated;
}

=head2 get_recent_annotated_loci

 Usage: my %edits= CXGN::Phenome::Locus::get_recent_annotated_loci($dbh, $date)
 Desc:  find all the loci annotated after date $date
 Ret:   hash of arrays of locus objects, aliases, alleles, locus_dbxrefs, unigenes, markers,individuals, and images
 Args:  database handle and a date
 Side Effects:
 Example:

=cut

sub get_recent_annotated_loci {

    my $dbh=shift;
    my $date= shift;
    my %edits={};

    ####
    #get all created and modified loci
    ####
    my $locus_query="SELECT locus_id FROM phenome.locus WHERE modified_date>? OR create_date>?
                     ORDER BY modified_date desc";
    my $locus_sth=$dbh->prepare($locus_query);
    $locus_sth->execute($date,$date);
    while (my($locus_id) = $locus_sth->fetchrow_array()) { 
	my $locus= CXGN::Phenome::Locus->new($dbh, $locus_id);
	push @{ $edits{loci} }, $locus;
    }
    
    #get all created and modified aliases
    ####
    my $locus_alias_query="SELECT locus_alias_id FROM phenome.locus_alias 
                          WHERE (modified_date>? OR create_date>?) AND preferred='f'
                          ORDER BY modified_date desc";
    my $locus_alias_sth=$dbh->prepare($locus_alias_query);
    $locus_alias_sth->execute($date,$date);
    while (my($locus_alias_id) = $locus_alias_sth->fetchrow_array()) { 
	my $locus_alias= CXGN::Phenome::LocusSynonym->new($dbh, $locus_alias_id);
	push @{ $edits{aliases} }, $locus_alias;
    }
    #get all created and modified alleles
    ####
    my $allele_query="SELECT allele_id FROM phenome.allele 
                      WHERE (modified_date>? OR create_date>?) and is_default='f'
                      ORDER BY modified_date desc";
    my $allele_sth=$dbh->prepare($allele_query);
    $allele_sth->execute($date,$date);
    while (my($allele_id) = $allele_sth->fetchrow_array()) { 
	my $allele= CXGN::Phenome::Allele->new($dbh, $allele_id);
	push @{ $edits{alleles} }, $allele;
    }
    
    ####
    #get all locus_dbxrefs
    ####
    my $locus_dbxref_query="SELECT locus_dbxref_id FROM phenome.locus_dbxref 
                            WHERE (modified_date>? OR create_date>?) 
			    ORDER BY modified_date desc, create_date desc";
    my $locus_dbxref_sth=$dbh->prepare($locus_dbxref_query);
    $locus_dbxref_sth->execute($date,$date);
    
    while (my($locus_dbxref_id) = $locus_dbxref_sth->fetchrow_array()) { 
	my $locus_dbxref= CXGN::Phenome::LocusDbxref->new($dbh, $locus_dbxref_id);
	push @{ $edits{locus_dbxrefs} }, $locus_dbxref;
    }

    ###
    #get associated images
    ####
    my $image_query="SELECT locus_id, image_id , sp_person_id, create_date, modified_date, obsolete
                     FROM phenome.locus_image 
                     WHERE (modified_date>? OR create_date>?) 
                     ORDER BY modified_date desc, create_date desc";
    my $image_sth=$dbh->prepare($image_query);
    $image_sth->execute($date,$date);
    
    while (my($locus_id, $image_id, $person_id, $cdate, $mdate, $obsolete) = $image_sth->fetchrow_array()) { 
	my $image= CXGN::Image->new($dbh, $image_id);
	my $locus=CXGN::Phenome::Locus->new($dbh, $locus_id);
	push @{ $edits{locus_images} }, [$locus, $image, $person_id, $cdate, $mdate, $obsolete];
    }
    
    ###
    #get associated individuals
    ####
    my $individual_query="SELECT individual_id, allele_id, sp_person_id, create_date, modified_date, obsolete
                          FROM phenome.individual_allele 
                          WHERE (individual_allele.modified_date>? OR individual_allele.create_date>?) 
                          ORDER BY individual_allele.modified_date DESC, individual_allele.create_date DESC";
    my $individual_sth=$dbh->prepare($individual_query);
    $individual_sth->execute($date,$date);
    
    while (my($individual_id, $allele_id, $person_id, $cdate, $mdate, $obsolete) = $individual_sth->fetchrow_array()) { 
	my $individual= CXGN::Phenome::Individual->new($dbh, $individual_id);
	my $allele= CXGN::Phenome::Allele->new($dbh, $allele_id);
	
	push @{ $edits{individuals} }, [$individual, $allele, $person_id, $cdate, $mdate, $obsolete];
    }
    
    ###
    #get associated unigenes
    ####
    my $locus_unigene_query="SELECT locus_id, unigene_id, sp_person_id, create_date, modified_date, obsolete
                            FROM phenome.locus_unigene 
                            WHERE (modified_date>? OR create_date>?)
                            ORDER BY modified_date DESC, create_date DESC";
    
    my $locus_unigene_sth=$dbh->prepare($locus_unigene_query);
    $locus_unigene_sth->execute($date,$date);
    
    while (my($locus_id, $unigene_id, $person_id, $cdate,$mdate, $obsolete) = $locus_unigene_sth->fetchrow_array()) { 
	my $unigene= CXGN::Transcript::Unigene->new_lite_unigene($dbh, $unigene_id);
	my $locus=CXGN::Phenome::Locus->new($dbh, $locus_id);
	push @{ $edits{locus_unigenes} }, [$unigene,$locus, $person_id, $cdate, $mdate, $obsolete];
    }
    
    #get associated markers
    my $locus_marker_query="SELECT locus_marker_id
                            FROM phenome.locus_marker 
                            WHERE (modified_date>? OR create_date>?) 
                            ORDER BY modified_date DESC, create_date DESC";
    my $locus_marker_sth=$dbh->prepare($locus_marker_query);
    $locus_marker_sth->execute($date,$date);
    
    while (my ($locus_marker_id) = $locus_marker_sth->fetchrow_array()) { 
	my $locus_marker= CXGN::Phenome::LocusMaker->new($dbh, $locus_marker_id);
	push @{ $edits{locus_markers} }, $locus_marker;
    }
    
    return %edits;
}


=head2 get_edit

 Usage: my %edits= CXGN::Phenome::Locus::get_edits($locus)
 Desc:  find all annotations by date for this locus
 Ret:   hash of arrays of  aliases, alleles, locus_dbxrefs, unigenes, markers,individuals, and images
 Args:  locus object
 Side Effects:
 Example:

=cut

sub get_edits {
    my $self= shift;
    my %edits={};
    my $dbh=$self->get_dbh();
    ####
    #get all locus edits (LocusHistory objects
    ####
    
    push @{ $edits{loci} }, $self->show_history();
    
    
    #get all created and modified aliases
    ####
    my $locus_alias_query="SELECT locus_alias_id FROM phenome.locus_alias 
                           WHERE locus_id= ?
                          ORDER BY modified_date desc, create_date desc";
    my $locus_alias_sth=$dbh->prepare($locus_alias_query);
    $locus_alias_sth->execute($self->get_locus_id());
    while (my($locus_alias_id) = $locus_alias_sth->fetchrow_array()) { 
	my $locus_alias= CXGN::Phenome::LocusSynonym->new($dbh, $locus_alias_id);
	push @{ $edits{aliases} }, $locus_alias;
    }
    #get all created and modified alleles
    ####
    my $allele_query="SELECT allele_id FROM phenome.allele 
                      WHERE  is_default='f' AND locus_id =?
                      ORDER BY modified_date DESC,  create_date DESC";
    my $allele_sth=$dbh->prepare($allele_query);
    $allele_sth->execute($self->get_locus_id());
    while (my($allele_id) = $allele_sth->fetchrow_array()) { 
	my $allele= CXGN::Phenome::Allele->new($dbh, $allele_id);
	push @{ $edits{alleles} }, $allele;
    }
    
    ####
    #get all locus_dbxrefs
    ####
    my $locus_dbxref_query="SELECT locus_dbxref_id FROM phenome.locus_dbxref 
                            WHERE locus_id = ? 
			    ORDER BY modified_date desc, create_date desc";
    my $locus_dbxref_sth=$dbh->prepare($locus_dbxref_query);
    $locus_dbxref_sth->execute($self->get_locus_id());
    
    while (my($locus_dbxref_id) = $locus_dbxref_sth->fetchrow_array()) { 
	my $locus_dbxref= CXGN::Phenome::LocusDbxref->new($dbh, $locus_dbxref_id);
	push @{ $edits{locus_dbxrefs} }, $locus_dbxref;
    }

    ###
    #get associated images
    ####
    my $image_query="SELECT image_id , sp_person_id, create_date, modified_date, obsolete
                     FROM phenome.locus_image 
                     WHERE locus_id=?
                     ORDER BY modified_date desc, create_date desc";
    my $image_sth=$dbh->prepare($image_query);
    $image_sth->execute($self->get_locus_id);
    
    while (my($image_id, $person_id, $cdate, $mdate, $obsolete) = $image_sth->fetchrow_array()) { 
	my $image= CXGN::Image->new($dbh, $image_id);
	push @{ $edits{images} }, [$image, $person_id, $cdate, $mdate, $obsolete];
    }
    
    ###
    #get associated individuals
    ####
    my $individual_query="SELECT individual_id FROM phenome.individual 
                          JOIN phenome.individual_allele USING (individual_id)
                          JOIN phenome.allele USING (allele_id) 
                          WHERE locus_id = ?
                          ORDER BY individual_allele.modified_date DESC, individual_allele.create_date DESC";
    my $individual_sth=$dbh->prepare($individual_query);
    $individual_sth->execute($self->get_locus_id());
    
    while (my($individual_id) = $individual_sth->fetchrow_array()) { 
	my $individual= CXGN::Phenome::Individual->new($dbh, $individual_id);
	push @{ $edits{individuals} }, $individual;
    }
    
    ###
    #get associated unigenes
    ####
    my $locus_unigene_query="SELECT unigene_id, sp_person_id, create_date, modified_date, obsolete
                            FROM phenome.locus_unigene 
                            WHERE locus_id = ?
                            ORDER BY modified_date DESC, create_date DESC";
    
    my $locus_unigene_sth=$dbh->prepare($locus_unigene_query);
    $locus_unigene_sth->execute($self->get_locus_id());
    
    while (my($unigene_id, $person_id, $cdate,$mdate, $obsolete) = $locus_unigene_sth->fetchrow_array()) { 
	my $unigene= CXGN::Transcript::Unigene->new($dbh, $unigene_id);
	push @{ $edits{unigenes} }, [$unigene, $person_id, $cdate, $mdate, $obsolete];
    }
    
    #get associated markers
    my $locus_marker_query="SELECT marker_id FROM phenome.locus_marker 
                            WHERE locus_id  = ?
                            ORDER BY modified_date DESC, create_date DESC";
    my $locus_marker_sth=$dbh->prepare($locus_marker_query);
    $locus_marker_sth->execute($self-get_locus_id());
    
    while (my($locus_marker_id) = $locus_marker_sth->fetchrow_array()) { 
	my $locus_marker= CXGN::Phenome::LocusMaker->new($dbh, $locus_marker_id);
	push @{ $edits{markers} }, $locus_marker;
    }
    
    return %edits;
}


=head2 function get_figures

  Synopsis:	my @figures=$locus->get_figures();
  Arguments:	none
  Returns:	array of figure and image objects
  Side effects:	
  Description:	selects the ids of all figures associated with the locus from
                locus_image linking table and and array of these individual objects.

=cut

sub get_figures {
    my $self = shift;
    my $query = "SELECT image_id FROM phenome.locus_image 
                 WHERE  obsolete = 'f' and locus_id=?";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_locus_id());
    my $image;
    my @images = ();
    while (my ($image_id) = $sth->fetchrow_array()) { 
        $image = CXGN::Image->new($self->get_dbh(), $image_id);
	push @images, $image;
    }
    return @images;
}

=head2 get_figure_ids

 Usage: $self->get_figure_ids
 Desc:  get a list of image_ids for figures associated with the locus
 Ret:   a list of image ids
 Args:  none
 Side Effects:
 Example:

=cut

sub get_figure_ids {
    my $self = shift;
    my $query = "SELECT image_id FROM phenome.locus_image 
                 WHERE  obsolete = 'f' and locus_id=?";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_locus_id());
    my @image_ids = ();
    while (my ($image_id) = $sth->fetchrow_array()) { 
 	push @image_ids, $image_id;
    }
    return @image_ids;
}



=head2 add_figure

 Usage: $self->add_figure($image_id, $sp_person_id)
 Desc: associate an existing image/figure with the locus 
 Ret:  database id (locus_image_id)
 Args: image_id, sp_person_id
 Side Effects: accesses the database
 Example:

=cut

sub add_figure {
    my $self=shift;
    my $image_id=shift;
    my $sp_person_id=shift;
    my $query="Insert INTO phenome.locus_image (locus_id, image_id,sp_person_id) VALUES (?,?,?)";
    my $sth=$self->get_dbh->prepare($query);
    $sth->execute($self->get_locus_id(), $image_id, $sp_person_id);
    my $id= $self->get_currval("phenome.locus_image_locus_image_id_seq");
    return $id;
}


=head2 get_owners

 Usage: my @owners=$locus->get_owners()
 Desc:  get all the owners of the current locus object 
 Ret:   an array of SGN person ids
 Args:  none 
 Side Effects:
 Example:

=cut

sub get_owners {
    my $self=shift;
    my $query = "SELECT sp_person_id FROM phenome.locus_owner 
                 WHERE locus_id = ? AND obsolete = 'f' ORDER BY create_date";
    my $sth=$self->get_dbh()->prepare($query);
    $sth->execute($self->get_locus_id());
    my $person;
    my @owners = ();
    while (my ($sp_person_id) = $sth->fetchrow_array()) { 
        $person = CXGN::People::Person->new($self->get_dbh(), $sp_person_id);
	push @owners, $sp_person_id;
    }
    return @owners;
}

=head2 add_owner

 Usage: $self->add_owner($owner_id,$sp_person_id)
 Desc:  assign a locus owner
 Ret:    database id 
 Args:   owner_id, user_id
 Side Effects: insert a new locus_owner
 Example:

=cut

sub add_owner {
    my $self=shift;
    my $owner_id=shift;
    my $sp_person_id=shift;
   
    if (!$self->owner_exists($owner_id)) {
	
	my $query = "INSERT INTO phenome.locus_owner (sp_person_id, locus_id, granted_by)
                      VALUES (?,?,?)";
	my $sth=$self->get_dbh()->prepare($query);
	$sth->execute($owner_id, $self->get_locus_id(), $sp_person_id);
        my $id= $self->get_currval("phenome.locus_owner_locus_owner_id_seq");
	$self->d( "Locus.pm:add_owner: added owner id: $owner_id, granted by: $sp_person_id\n");
	return $id;
    }else { return undef; }
}


=head2 owner_exists

 Usage: $self->owner_exists($sp_person_id)
 Desc:  check if the locus already has owner $sp_person_id
 Ret:   database id (locus_owner_id) or undef
 Args:  $sp_person_id
 Side Effects: none
 Example:

=cut

sub owner_exists {
    my $self=shift;
    my $sp_person_id=shift;
    my $q= "SELECT locus_owner_id, obsolete FROM phenome.locus_owner WHERE locus_id=? AND sp_person_id=? ";
    my $sth=$self->get_dbh()->prepare($q);
    $sth->execute($self->get_locus_id(), $sp_person_id);
    my ($id, $ob)= $sth->fetchrow_array();
    return $id || undef;
}



=head2 get_individual_allele_id

 Usage: my $individual_allele_id= $locus->get_individual_allele_id($individual_id)
 Desc:  find the individual_allele database id for a given individual id
        useful for manipulating individual_allele table (like obsoleting an individual-allele  association)
               
 Ret: a database id from the table phenome.individual_allele
 Args: $individual_id
 Side Effects:
 Example:

=cut

sub get_individual_allele_id {
    my $self=shift;
    my $individual_id=shift;
    my $query= "SELECT individual_allele_id FROM phenome.individual_allele 
                JOIN phenome.allele USING (allele_id) 
                WHERE locus_id=? AND individual_id=?";
    my $sth=$self->get_dbh()->prepare($query);
    $sth->execute($self->get_locus_id(), $individual_id);
    my ($individual_allele_id) = $sth->fetchrow_array();
    return $individual_allele_id;
}

=head2 get_associated_locus    DEPRECATED. SEE get_locusgroups() 

 Usage: $locus->get_associated_locus($associated_locus_id)
 Desc:  get a locus2locus object of the locus (object) associated to the current locus (subject)
 Ret:    a Locus2Locus object or undef
 Args:  $associated_locus_id
 Side Effects: none
 Example:

=cut

sub get_associated_locus {
    warn("DEPRECATED. SEE get_locusgroups() !!!!!!!\n");
    
    my $self=shift;
    my $associated_locus_id=shift;
    my $query = "SELECT locus2locus_id FROM phenome.locus2locus WHERE object_id=? AND subject_id = ? AND obsolete= 'f'";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($associated_locus_id, $self->get_locus_id());
    my ($l2l_id) = $sth->fetchrow_array();
  
    if ($l2l_id) {
	my $l2l=CXGN::Phenome::Locus2Locus->new($self->get_dbh(), $l2l_id);
	return $l2l;
    } else { return undef };
}

=head2 get_reciprocal_locus  DEPRECATED. SEE get_locusgroups() 


 Usage:  $locus->get_reciprocal_locus($reciprocal_locus_id)
 Desc:   get a locus2locus object of the reciprocal_locus (subject) associated to the current locus (object).
         This is used for printing the reciprocal loci associated with a specific locus.
 Ret:    Locus2Locus object or undef
 Args:   $reciprocal_locus_id
 Side Effects: none
 Example:

=cut

sub get_reciprocal_locus {
    warn("DEPRECATED. SEE get_locusgroups() !!!!!!!\n");

    my $self=shift;
    my $reciprocal_locus_id=shift;
    my $query = "SELECT locus2locus_id FROM phenome.locus2locus WHERE object_id=? AND subject_id = ? AND obsolete='f'";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute( $self->get_locus_id(), $reciprocal_locus_id);
    my ($l2l_id) = $sth->fetchrow_array();
    if ($l2l_id) {
	my $l2l=CXGN::Phenome::Locus2Locus->new($self->get_dbh(), $l2l_id);
	return $l2l;
    }else {return undef ; }
}


=head2 get_locus_annotations

 Usage: $self->get_locus_annotations($dbh, $cv_name)
 Desc:  find all cv_name annotations for loci
 Ret:   list of LocusDbxref objects
 Args:  database handle and a cv name
 Side Effects: none
 Example:

=cut

sub get_locus_annotations {
    my $self=shift;
    my $dbh=shift;
    my $cv_name=shift;
    my @annotations;
    my $query = "SELECT locus_dbxref_id FROM phenome.locus_dbxref
                 JOIN public.dbxref USING (dbxref_id) 
                 JOIN public.cvterm USING (dbxref_id) 
                 JOIN public.cv USING (cv_id)
                 WHERE cv.name = ? AND locus_dbxref.obsolete= 'f' ORDER BY locus_id";
    my $sth=$dbh->prepare($query);
    $sth->execute($cv_name);
    while (my ($locus_dbxref_id) = $sth->fetchrow_array()) {
	my $locus_dbxref= CXGN::Phenome::LocusDbxref->new($dbh, $locus_dbxref_id);
	push @annotations , $locus_dbxref;
    }
    return @annotations;
}

=head2 get_curated_annotations

 Usage: $self->get_curated_annotations($dbh, $cv_name)
 Desc:  find all cv_name non-electronic annotations for loci
 Ret:   list of LocusDbxref objects
 Args:  database handle and a cv name
 Side Effects: none
 Example:

=cut

sub get_curated_annotations {
    my $self=shift;
    my $dbh=shift;
    my $cv_name=shift;
    my @annotations;
    my $query = "SELECT locus_dbxref_id , locus_dbxref_evidence.evidence_code_id FROM phenome.locus_dbxref
                 JOIN public.dbxref USING (dbxref_id) 
                 JOIN public.cvterm USING (dbxref_id) 
                 JOIN public.cv USING (cv_id)
                 JOIN locus_dbxref_evidence USING (locus_dbxref_id)
                 WHERE cv.name = ? AND locus_dbxref.obsolete= 'f' 
                 AND locus_dbxref_evidence.evidence_code_id !=(SELECT dbxref_id FROM public.cvterm WHERE name = 'inferred from electronic annotation') ORDER BY locus_id";
    my $sth=$dbh->prepare($query);
    $sth->execute($cv_name);
    while (my ($locus_dbxref_id) = $sth->fetchrow_array()) {
	my $locus_dbxref= CXGN::Phenome::LocusDbxref->new($dbh, $locus_dbxref_id);
	push @annotations , $locus_dbxref;
    }
    return @annotations;
}

=head2 get_annotations_by_db

 Usage: $self->get_annotations_by_db('GO')
 Desc:  find all locus cvterm annotations for a given db
 Ret:   an array of locus_dbxref objects
 Args:  $db_name
 Side Effects: none
 Example:

=cut

sub get_annotations_by_db {
    my $self=shift;
    my $dbh=shift;
    my $db_name=shift;
    my @annotations;
    my $query = "SELECT locus_dbxref_id FROM phenome.locus_dbxref
                 JOIN public.dbxref USING (dbxref_id) 
                 JOIN public.db USING (db_id)
                 JOIN public.cvterm USING (dbxref_id) 
                 WHERE db.name = ? AND locus_dbxref.obsolete= 'f'";
    my $sth=$dbh->prepare($query);
    $sth->execute($db_name);
    while (my ($locus_dbxref_id) = $sth->fetchrow_array()) {
	my $locus_dbxref= CXGN::Phenome::LocusDbxref->new($dbh, $locus_dbxref_id);
	push @annotations , $locus_dbxref;
    }
    return @annotations;
}



=head2 merge_locus

 Usage: $self->merge_locus($merged_locus_id, $sp_person_id)
 Desc:  merge locus X with this locus. The merged locus will be set to obsolete.
 Ret:   nothing
 Args:  the id of the locus to be merged 
 Side Effects: all data associated with the merged locus will now be associated with the current locus. 
 Example:

=cut

sub merge_locus {
    my $self=shift;
    my $merged_locus_id=shift;
    my $sp_person_id=shift;
    my $m_locus=CXGN::Phenome::Locus->new($self->get_dbh(), $merged_locus_id);
    $self->( "*****locus.pm: calling merge_locus...merging locus " . $m_locus->get_locus_id() . " with locus ". $self->get_locus_id() . " \n");
    eval {
	my @m_owners=$m_locus->get_owners();
	foreach my $o (@m_owners) { 
	    my $o_id= $self->add_owner($o, $sp_person_id);  
	    $self->d( "merge_locus is adding owner $o to locus " . $self->get_locus_id() . "\n**") if $o_id;
	}
        $self->d( "merge_locus checking for aliases ....\n");
	my @m_aliases=$m_locus->get_locus_aliases();
	foreach my $alias(@m_aliases) {
	    $self->add_locus_alias($alias);
	    $self->( "merge_locus is adding alias " . $alias->get_locus_alias() . " to locus " . $self->get_locus_id() . "\n**");
	}
	my @unigenes=$m_locus->get_unigenes();
	foreach my $u(@unigenes) { 
	    my $u_id= $u->get_unigene_id();
	    $self->add_unigene($u_id, $sp_person_id); 
	    $self->d( "merge_locus is adding unigene $u to locus" . $self->get_locus_id() . "\n**");
	}
	
	my @alleles=$m_locus->get_alleles();
	foreach my $allele(@alleles) { 
	    $self->d( "adding allele ........\n");
	    #reset allele id for storing a new one for the current locus
	    $allele->set_allele_id(undef);
	    my $allele_id=$self->add_allele($allele);
	    $self->d( "merge_locus is adding allele $allele_id " . $allele->get_allele_symbol() . "to locus" . $self->get_locus_id() . "\n**");
	   
	    #find the individuals of the current allele
	    my @individuals=$allele->get_individuals();
	    #associated individuals with the newly inserted allele
	    foreach my $i(@individuals) {
		$i->associate_allele($allele_id, $sp_person_id); 
		$self->d( "merge_locus is adding allele $allele_id to *individual* " . $i->get_individual_id() . "\n**");
	    }
	}
	
	my @figures=$m_locus->get_figures();
	foreach my $image(@figures) { 
	    $self->add_figure($image->get_image_id(), $sp_person_id);
	    $self->d( "merge_locus is adding figure" . $image->get_image_id() . " to locus " . $self->get_locus_id() . "\n**");
	}
	
	my @dbxrefs=$m_locus->get_dbxrefs();
	foreach my $dbxref(@dbxrefs) {
	    my $ldbxref=$m_locus->get_locus_dbxref($dbxref); #the old locusDbxref object
	    my @ld_evs=$ldbxref->get_locus_dbxref_evidence(); #some have evidence codes
	    my $ldbxref_id=$self->add_locus_dbxref($dbxref, undef, $ldbxref->get_sp_person_id()); #store the new locus_dbxref..
	    $self->d( "merge_locus is adding dbxref " . $dbxref->get_dbxref_id() . "to locus " . $self->get_locus_id() . "\n");
	    foreach my $ld_ev ( @ld_evs) {
		if ($ld_ev->get_object_dbxref_evidence_id() ) {
		    $ld_ev->set_object_dbxref_evidence_id(undef);
		    $ld_ev->set_object_dbxref_id($ldbxref_id);
		    $ld_ev->store(); #store the new locus_dbxref_evidence 
		}
	    }
	}
	#Add this locus to all the groups of the merged locus
	my @groups=$m_locus->get_locusgroups();
	
	my $schema;
	
	if ($groups[0]) { $schema = $groups[0]->get_schema(); }
	foreach my $group (@groups) {
	    my $m_lgm=$group->get_object_row()->
		find_related('locusgroup_members', { locus_id => $m_locus->get_locus_id() } ); 
	    #see if the locus is already a member of the group
	    my $existing_member= $group->get_object_row()->
		find_related('locusgroup_members', { locus_id => $self->get_locus_id() } );
	    if (!$existing_member) {
		my $lgm=CXGN::Phenome::LocusgroupMember->new($schema);
		
		$lgm->set_locusgroup_id($m_lgm->locusgroup_id() );
		$lgm->set_locus_id($self->get_locus_id() );
		$lgm->set_evidence_id($m_lgm->evidence_id());
		$lgm->set_reference_id($m_lgm->reference_id());
		$lgm->set_sp_person_id($m_gm->sp_person_id());
		$lgm->set_direction($m_lgm->direction());
		$lgm->set_obsolete($m_lgm->obsolete());
		$lgm->set_create_date($m_lgm->create_date());
		$lgm->set_modified_date($m_lgm->modified_date());
		
		my $lgm_id= $lgm->store();
	    }
	    $self->d( "obsoleting group member... \n");
	    $m_lgm->set_column(obsolete => 't');
	    $m_lgm->update();
	}
	$self->d( "Obsoleting merged locus... \n");
	#last step is to obsolete the old locus. All associated objects (images, alleles, individuals..) should not display obsolete objects on the relevant pages! 
	$m_locus->delete();
    };
    if ($@) { 
	my $error = "Merge locus failed! \n $@\n\nCould not merge locus $merged_locus_id with locus " . $self->get_locus_id() . "\n";
	return $error;
    } else {
	$self->d( "merging locus succeded ! \n"); 
	return undef;
    } 
}

=head2 get_locus_stats

 Usage: CXGN::Phenome::Locus->get_locus_stats($dbh)
 Desc:  class function. Find the status of the locus database by month.
 Ret:   List of lists [locus_count], [month/year]]
 Args:  dbh 
 Side Effects: none
 Example:

=cut


sub get_locus_stats {
    my $self=shift;
    my $dbh=shift;
    my $query = "select count (locus_id), date_part('month', create_date) as month , date_part('year', create_date) as year from phenome.locus group by month, year order by year, month asc";
    my $sth=$dbh->prepare($query);
    $sth->execute();
    my @stats;
    my $count;
    while (($loci, $month, $year) = $sth->fetchrow_array()) {
	$year= substr($year, -2);
	$count +=$loci;
	push @{ $stats[0] }, "$month/$year";
	push @{ $stats[1] }, $count;
	
    }
    return @stats;
}

=head2 get_locusgroups

 Usage: $self->get_locusgroups()
 Desc:  Find all the locus groups this locus is a member of
 Ret:   a list of CXGN::Phenome::LocusGroup objects (DBIx::Class ojects! )
 Args:  none
 Side Effects: connects to CXGN::Phenome::Schema
 Example:

=cut

sub get_locusgroups {
    my $self=shift;
    my $locus_id = $self->get_locus_id();
    my $schema= CXGN::Phenome::Schema->connect( sub{ $self->get_dbh()->get_actual_dbh()} ,
						{ on_connect_do => ['SET search_path TO phenome, public;'],
						},);
    
    my @members= $schema->resultset('LocusgroupMember')->search( 
	{
	    locus_id => $locus_id ,
	    obsolete => 'f',
	});
    my @lgs;
    foreach my $member (@members) {
	my $group_id = $member->get_column('locusgroup_id');
	my $lg= CXGN::Phenome::LocusGroup->new($schema, $group_id);
	push @lgs, $lg;
    }
    return @lgs;
}

=head2 count_associated_loci

 Usage: $self->count_associated_loci()
 Desc:  count the number of loci associated with this locus
 Ret: an integer
 Args: none 
 Side Effects: 
 Example:

=cut

sub count_associated_loci {
    my $self=shift;
    my $locus_id=$self->get_locus_id();
    my $count=0;
    my @locus_groups= $self->get_locusgroups();
    foreach my $group(@locus_groups) {
	my @members= $group->get_locusgroup_members(); 
	foreach my $member(@members) { 
	    my $member_locus_id= $member->get_column('locus_id');
	    if (( $member->obsolete() == 0 ) &&  ($member_locus_id != $locus_id) ) {
		$count++; 
	    }
	}
    }
    return $count;
}

=head2 count_ontology_annotations

 Usage: $self->count_ontology_annotations()
 Desc:  count the number of non-obsolete ontology terms  with this locus directly or indirectly via alleles
 Ret: an integer
 Args: none 
 Side Effects: 
 Example:

=cut

sub count_ontology_annotations {
    my $self=shift;
    my $locus_id=$self->get_locus_id();
        
    my $query = "SELECT count(distinct(cvterm_id)) FROM public.cvterm 
                JOIN phenome.locus_dbxref USING (dbxref_id) JOIN phenome.locus_dbxref_evidence USING (locus_dbxref_id) 
                LEFT JOIN phenome.allele_dbxref USING  (dbxref_id)
                LEFT JOIN phenome.allele USING (allele_id)
                WHERE locus_dbxref.locus_id=? AND locus_dbxref.obsolete='f' AND locus_dbxref_evidence.obsolete='f'
                OR allele_dbxref.obsolete = 'f'";
    my $sth=$self->get_dbh()->prepare($query);
    $sth->execute($locus_id);
    my ($count)= $sth->fetchrow_array();
    
    return $count;
}


###
1;#do not remove
###



