

=head1 NAME

CXGN::Phenome::Individual - a class that deals with individuals in populations

=head1 DESCRIPTION

This class inherits from CXGN::Page::Form::UserModifiable and can therefore be used to implement user-modifiable pages easily. It also inherits from CXGN::Phenome::Main, which deals with the database connection.

=head1 AUTHOR(S)

Naama Menda (nm249@cornell.edu)

=head1 FUNCTIONS

This class implements the following functions:

=cut

package CXGN::Phenome::Individual;

use strict;
use CXGN::DB::Connection;
use CXGN::People::Person;
use CXGN::Image;
use CXGN::Phenome::Allele;
use CXGN::Phenome::IndividualHistory;
use CXGN::Phenome::Population;
use CXGN::Phenome::Individual::IndividualDbxref;
use CXGN::Chado::Phenotype;
use CXGN::DB::Object;

use base qw / CXGN::DB::ModifiableI  /;

=head2 function new

  Synopsis:	my $p = CXGN::Phenome::Individual->new($dbh, $individual_id)
  Arguments:	a database handle and a individual id
  Returns:	an CXGN::Phenome::Individual object
  Side effects:	if $individual_id is omitted, an empty project is created. 
                if an illegal $individual_id is supplied, undef is returned.
  Description:	

=cut

sub new {
    my $class = shift;
    my $dbh = shift;
    my $individual_id = shift;
    
    if (!$dbh->isa("CXGN::DB::Connection")) { 
	die "First argument to CXGN::Phenome::Individual constructor needs to be a database handle.";
    }
    my $self = $class->SUPER::new($dbh);

    $self->set_individual_id($individual_id);
    
    if ($individual_id) { 
	$self->fetch();
    }
    return $self;
}

=head2 new_with_name

 Usage:        my @individuals = CXGN::Phenome::Individual->new_with_name($dbh, "LA716", $population_id)
 Desc:         An alternate constructor that takes an individual
               name as a parameter and returns a list of objects
               that match that name.
 Ret:          a list of CXGN::Phenome::Individual objects
 Args:         a database handle, an individual name, population_id (optional!)
 Side Effects: accesses the database.
 Example:

=cut

sub new_with_name {
    my $class = shift;
    my $dbh = shift;
    my $name = shift;
    my $population_id= shift;
    my $query = "SELECT individual_id FROM phenome.individual WHERE name ilike ?";
    $query .= " AND population_id = $population_id " if $population_id;
    my $sth = $dbh->prepare($query);
    $sth->execute($name);
    my @individuals = ();
    while (my ($id) = $sth->fetchrow_array()) { 
	push @individuals, CXGN::Phenome::Individual->new($dbh, $id);
    }
    return @individuals;
}



sub fetch { 
    my $self= shift;
    my $individual_id = $self->get_individual_id();
    my $query = "SELECT individual.name, individual.description, population.name, individual.sp_person_id, individual.create_date, individual.modified_date, updated_by, population_id, common_name_id, common_name, individual.obsolete FROM phenome.individual 
LEFT JOIN phenome.population using(population_id)  
LEFT JOIN sgn.common_name USING (common_name_id)
WHERE individual_id=? and individual.obsolete='f'";
    
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_individual_id());

    my ($name, $description, $population_name, $sp_person_id, $create_date, $modified_date, $updated_by, $population_id, $common_name_id, $common_name, $obsolete) = $sth->fetchrow_array();

    $self->set_name($name);
    $self->set_description($description);
    $self->set_population_name($population_name);
    $self->set_sp_person_id($sp_person_id);
    $self->set_create_date($create_date);
    $self->set_modification_date($modified_date);
    $self->set_updated_by($updated_by);
    $self->set_population_id($population_id);
    $self->set_common_name_id($common_name_id);
    $self->set_common_name($common_name);
    $self->set_obsolete($obsolete);
    
    return $individual_id;
}

=head2 function store

  Synopsis:	$self->store()
  Arguments:	none
  Returns:	database id 
  Side effects:	store a new individual/ update if individual_id exists
  Description:	

=cut

sub store {
    my $self = shift;

    if ($self->get_individual_id()) { 
	print STDERR "Individual.pm -> updating....\n\n"; 
	$self->store_history();
	
	my $query = "UPDATE phenome.individual SET
                       name = ?,
                       description = ?,
                       updated_by=?,
                       modified_date = now()
                     WHERE
                       individual_id = ?
                     ";
	my $sth = $self->get_dbh()->prepare($query);
	$sth->execute($self->get_name(), $self->get_description(), $self->get_updated_by(), $self->get_individual_id());
	return $self->get_individual_id();
    }
    else { 
	my $query = "INSERT INTO phenome.individual
                      (name, description, population_id, sp_person_id, create_date, common_name_id)
                     VALUES 
                      (?,?,?,?,now(), ?)";
	
	my $sth = $self->get_dbh()->prepare($query);
	$sth->execute($self->get_name(), $self->get_description(), $self->get_population_id(), $self->get_sp_person_id(), $self->get_common_name_id()  );
	
	my $id = $self->get_dbh()->last_insert_id("individual", "phenome");
	$self->set_individual_id($id);
	print STDERR "getting last_insert_id...$id\n";
	
	return $id;
	
    }
}

=head2 function get_images

  Synopsis:     my @images = $self->get_images()	
  Arguments:    none	
  Returns:      an array of image objects	 
  Side effects:	none
  Description:	a method for fetching all images associated with an individual

=cut

sub get_images {
    my $self = shift;
    my $query = "SELECT image_id FROM phenome.individual_image WHERE individual_id=? AND obsolete = 'f'";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_individual_id());
    my $image;
    my @images =();
    while (my ($image_id) = $sth->fetchrow_array()) { 
	$image = CXGN::Image->new($self->get_dbh(), $image_id);
	push @images, $image;
    }
    return @images;
}


=head2 function get_image_ids

  Synopsis:     my @images = $self->get_image_ids()	
  Arguments:    none	
  Returns:      an array of image ids
  Side effects:	none
  Description:	a method for fetching all images associated with an individual

=cut

sub get_image_ids {
    my $self = shift;
    my $ids = $self->get_dbh->selectcol_arrayref
	( "SELECT image_id FROM phenome.individual_image WHERE individual_id=? AND obsolete = 'f'",
	  undef,
	  $self->get_individual_id
	);
    return @$ids;
}

=head2 function get_germplasms

  Synopsis:	my @germplasms = $self->get_germplasms()
  Arguments:	none
  Returns:	an array of germplasm objects
  Side effects:	none
  Description:	a method for fetching all germplasms associated with an individual

=cut

sub get_germplasms {
    my $self = shift;
    my $query = "SELECT germplasm_id FROM phenome.germplasm WHERE individual_id=? AND obsolete = 'f' ";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_individual_id());
    my $germplasm;
    my @germplasms =();
    while (my ($germplasm_id) = $sth->fetchrow_array()) { 
	$germplasm = CXGN::Phenome::Germplasm->new($self->get_dbh(), $germplasm_id);
	push @germplasms, $germplasm;
    }
    return @germplasms;
}


=head2 function get_alleles

  Synopsis:	my @alleles = $self->get_alleles()
  Arguments:	none
  Returns:	an array of allele objects
  Side effects:	none
  Description:	a method for fetching all alleles associated with an individual

=cut

sub get_alleles {
    my $self = shift;
    my $query = "SELECT allele_id FROM phenome.individual_allele JOIN phenome.allele USING (allele_id) WHERE individual_allele.individual_id=? AND individual_allele.obsolete = 'f' AND allele.is_default = 'f'";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_individual_id());
    my $allele;
    my @alleles =();
    while (my ($allele_id) = $sth->fetchrow_array()) { 
	$allele = CXGN::Phenome::Allele->new($self->get_dbh(), $allele_id);
	push @alleles, $allele;
    }
    return @alleles;
}

=head2 function get_loci

  Synopsis:	my @loci = $self->get_loci()
  Arguments:	none 
  Returns:	an array of locus objects associated with the individual object
  Side effects:	none 
  Description:	a method for fetching all loci associated with an individual 

=cut

sub get_loci {
    my $self = shift;
    my $query = "SELECT locus_id FROM phenome.individual_allele JOIN phenome.allele using (allele_id) WHERE individual_id=? AND individual_allele.obsolete = 'f'";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_individual_id());
    my $locus;
    my @loci =();
    while (my ($locus_id) = $sth->fetchrow_array()) { 
	$locus = CXGN::Phenome::Locus->new($self->get_dbh(), $locus_id);
	push @loci, $locus;
    }
    return @loci;
}


=head2 associate_locus

 This function is deprecated. Please use associate_allele.
 Usage:        $individual->associate_locus($locus_id, $sp_person_id)
 Desc:         associate a CXGN::Phenome::Locus with this individual
 Ret:
 Args:
 Side Effects: associates the locus and individual in the database 
               right away. This function can\'t be called if the 
               individual has not yet been store\'d. 
 Example:

=cut

sub associate_locus {
    my $self = shift;
    my $locus_id = shift;
    my $sp_person_id= shift;
    my $individual_id=$self->store();
    my $query = "INSERT INTO phenome.individual_locus
                   (locus_id, individual_id, sp_person_id) VALUES (?, ?, ?)";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($locus_id, $individual_id, $sp_person_id);
    return $self->get_dbh()->last_insert_id("individual_locus", "phenome");
   
}


=head2 associate_allele

 Usage:        $individual->associate_allele($allele_id, $sp_person_id)
 Desc:         associate a CXGN::Phenome::Allele with this individual
 Ret:         database id
 Args:        allele_id, sp_person_id
 Side Effects:  accesses the database
 Example:

=cut

sub associate_allele {
    my $self = shift;
    my $allele_id = shift;
    my $sp_person_id=shift;
    my $individual_id = $self->get_individual_id();
    
    my  $obsolete_query = "SELECT obsolete, individual_allele_id 
                           from phenome.individual_allele WHERE individual_id=? AND allele_id=?";
    my $obsolete_sth= $self->get_dbh()->prepare($obsolete_query);
    $obsolete_sth->execute($individual_id, $allele_id);
    my ($obsolete, $individual_allele_id)= $obsolete_sth->fetchrow_array();
    $self->d( "*****Individual.pm -> associating allele....\n\nallele_id=$allele_id, individual_id=$individual_id, sp_person_id= $sp_person_id, obsolete=$obsolete, individual_allele_id= $individual_allele_id\n\n");
    if (!$obsolete && !$individual_allele_id) {
	#check if another allele of this locus is already associated with the individual
	my $cq= "SELECT individual_allele_id  FROM phenome.individual_allele 
                 JOIN phenome.allele USING (allele_id) 
                 WHERE allele.locus_id = (SELECT locus_id FROM phenome.allele WHERE allele.allele_id =?)
                 AND individual_id = ?";
	my $csth=$self->get_dbh()->prepare($cq);
	$csth->execute($allele_id, $individual_id) ;
	my ($existing_id) = $csth->fetchrow_array();
	if ($existing_id) {
	    $self->d("Individual.pm: updating allele_id of an existing individual_allele !!");
	    my $query= "UPDATE phenome.individual_allele SET allele_id=?, sp_person_id=?, modified_date=now()
                        WHERE individual_allele_id = ?";
	    my $sth=$self->get_dbh()->prepare($query);
	    $sth->execute($allele_id, $sp_person_id,$existing_id );
	    $individual_allele_id = $existing_id;
	}else { 
	    $self->d("Individual.pm: inserting a new individual_allele.");
	    my $query = "INSERT INTO phenome.individual_allele
                   (allele_id, individual_id, sp_person_id) VALUES (?, ?, ?)";
	    my $sth = $self->get_dbh()->prepare($query);
	    $sth->execute($allele_id, $individual_id, $sp_person_id);
	    
	    $individual_allele_id= $self->get_dbh()->last_insert_id("individual_allele", "phenome");
	}
	
    }elsif ($obsolete || $individual_allele_id) {
	$self->d("Individual.pm: updating individual_allele to obsolete = 'f'.");
	my $query = "UPDATE phenome.individual_allele SET obsolete = 'f', sp_person_id=?, modified_date = now()
                     WHERE individual_allele_id=?";
	my $sth=$self->get_dbh()->prepare($query);
	$sth->execute($sp_person_id, $individual_allele_id);
    }
    return $individual_allele_id;
    
}

=head2 add_allele

  Usage: $self->add_allele($allele)
 Desc:  an accessor for building an allele list for the individual 
 Ret:   nothing
 Args:  allele object
 Side Effects:
 Example:

=cut

sub add_allele {
    my $self=shift;
    my $allele=shift; #allele
    push @{ $self->{alleles} }, $allele;
}


=head2 allele_exists

 Usage: my $exising_allele= $self->allele_exists($allele_id);
 Desc: check if allele is already associated with teh individual
 Ret:  allele_id or undef
 Args:  allele_id
 Side Effects: none
 Example:

=cut

sub allele_exists {
    my $self=shift;
    my $allele_id=shift;
    my @alleles= $self->get_alleles();
    foreach (@alleles) {
	my $e_id= $_->get_allele_id();
	if ($e_id == $allele_id) { return $e_id }
    }
    return undef;
}

=head2 get_dbxrefs

 Usage: my @dbxrefs = $self-> get_dbxrefs()
 Desc:  method for getting an array of dbxref objects associated with a single individual
 Ret:   an array of dbxref objects
 Args:  none
 Side Effects:
 Example:

=cut

sub get_dbxrefs {
    my $self= shift;
    
    my $dbxref_query = $self-> get_dbh()->prepare("SELECT dbxref_id from phenome.individual_dbxref WHERE individual_id= ? ");
    $dbxref_query->execute($self->get_individual_id());
    my @dbxrefs; #array for storing all dbxref objects associated with individual_id
    my $dbxref;
    while (my ($id) = $dbxref_query->fetchrow_array() ) {
	$dbxref = CXGN::Chado::Dbxref->new($self->get_dbh(), $id);
	push @dbxrefs, $dbxref;
    }
    return @dbxrefs;
}

=head2 function associate_dbxref

  Synopsis:  $individual->associate_dbxref($dbxref_id)
  Arguments: $dbxref_id an id of an entry from public.dbxref table	
  Returns:   last_insert_id 
  Side effects:	
  Description:	inserts a new entry into phenome.individual_dbxref

=cut

sub associate_dbxref {
    my $self = shift;
    my $dbxref_id = shift;
    my $query = "INSERT INTO phenome.individual_dbxref
                   (dbxref_id, individual_id) VALUES (?, ?)";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($dbxref_id, $self->get_individual_id());
    return $self->get_dbh()->last_insert_id("individual_dbxref", "phenome");
}

=head2 function get_individual_id

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub get_individual_id { 
    my $self=shift;
    return $self->{individual_id};
}

=head2 function set_individual_id

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub set_individual_id { 
    my $self=shift;
    $self->{individual_id}=shift;
}

=head2 function get_name

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub get_name { 
    my $self=shift;
    return $self->{name};
}

=head2 function set_name

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub set_name { 
    my $self=shift;
    $self->{name}=shift;
}

=head2 function get_description

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub get_description { 
    my $self=shift;
    return $self->{description};
}

=head2 function set_description

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub set_description { 
    my $self=shift;
    $self->{description}=shift;
}


=head2 get_population_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_population_id {
  my $self=shift;
  return $self->{population_id};

}

=head2 set_population_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_population_id {
  my $self=shift;
  $self->{population_id}=shift;
}

=head2 get_population_name

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_population_name {
  my $self=shift;
  return $self->{population_name};

}

=head2 set_population_name

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_population_name {
  my $self=shift;
  $self->{population_name}=shift;
}

=head2 get_individual_locus_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_individual_locus_id {
  my $self=shift;
  return $self->{individual_locus_id};

}

=head2 set_individual_locus_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_individual_locus_id {
  my $self=shift;
  $self->{individual_locus_id}=shift;
}


=head2 get_common_name

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

=head2 set_common_name

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_common_name {
  my $self=shift;
  $self->{common_name}=shift;
}

=head2 get_common_name_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_common_name_id {
  my $self=shift;
  return $self->{common_name_id};

}

=head2 set_common_name_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_common_name_id {
  my $self=shift;
  $self->{common_name_id}=shift;
}



=head2 delete

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut


sub delete { 
    my $self = shift;
    if ($self->get_individual_id()) { 
	my $query = "UPDATE phenome.individual SET obsolete='t', modified_date=now()
                  WHERE individual_id=?";
	my $sth = $self->get_dbh()->prepare($query);
	$sth->execute($self->get_individual_id());
       
 	my $allele_query = "UPDATE phenome.individual_allele SET obsolete='t', modified_date=now()
                   WHERE individual_id=?";
 	my $allele_sth = $self->get_dbh()->prepare($allele_query);
 	$allele_sth->execute($self->get_individual_id());
	
    }else { 
	print STDERR  "trying to delete an individual that has not yet been stored to db.\n";
    }    
}		     


=head2 exists_in_database

 Usage: my $existing_individual_id = CXGN::Phenome::Individual::exists_in_database();
 Desc:  check if an individual name exists in the database (phenome.individual)  
 Ret:   individual_id for the given individual name
 Args:   
 Side Effects: none
 Example:

=cut


sub exists_in_database { ######check why this doesn't work for updates..
    my $self = shift;
    my $name = shift;
    my $individual_id= $self->get_individual_id();
    my $name_query = "SELECT individual_id, obsolete 
                        FROM phenome.individual
                        WHERE name ILIKE ? ";
    my $name_sth = $self->get_dbh()->prepare($name_query);
    $name_sth->execute($name );
    my ($name_id, $obsolete) = $name_sth->fetchrow_array();
    
    if ( $name_id && ($individual_id!= $name_id)  ) { 
	my $message = "";
	if(!$individual_id){
	    $message = "Insert failed: phenome.individual.individual_id=$name_id already exists in database\n";
	}
	elsif($individual_id!=$name_id){
	    $message = "Update failed: individual_id $name_id fetched from database, should be $individual_id\n";
	}
	return $message;
    }
    else {  return 0; }
}


=head2 store_history

 Usage: $self->store_history()
 Desc:  Inserts the current fields of an individual object into the individual_history table before updating the individual details
 Ret:   
 Args: none
 Side Effects: 
 Example:

=cut

sub store_history {
    my $self=shift;
    my $individual=CXGN::Phenome::Individual->new($self->get_dbh(), $self->get_individual_id() );

    my $history_query = "INSERT INTO phenome.individual_history (individual_id, name, description, population_id, sp_person_id, updated_by, obsolete, create_date) 
                             VALUES(?,?,?,?,?,?,?, now())";
    my $history_sth= $self->get_dbh()->prepare($history_query);
    
    $history_sth->execute($individual->get_individual_id(), $individual->get_name(), $individual->get_description(), $individual->get_population_id(), $individual->get_sp_person_id, $self->get_updated_by(), $individual->get_obsolete() );
    
    
}

=head2 show_history

  Usage: $inividual->show_history();
 Desc:   Selects the data from individual_history table for an individual object 
 Ret:    
 Args:    
 Side Effects:
 Example:

=cut

sub show_history {
    my $self=shift;
    my $individual_id= $self->get_individual_id();
    my $history_query=$self->get_dbh()->prepare("SELECT individual_history_id FROM phenome.individual_history WHERE individual_id=?"); 
    my @history;
    $history_query->execute($individual_id);
    while (my ($history_id) = $history_query->fetchrow_array()) { 
	my $history_obj = CXGN::Phenome::IndividualHistory->new($self->get_dbh(), $history_id);
	push @history, $history_obj;
    }
    return @history;
}



=head2 get_population

  Usage: $inividual->get_population();
 Desc:    
 Ret:    a population object 
 Args:   none
 Side Effects:
 Example:

=cut

sub get_population {
    my $self=shift;
    my $population_id= $self->get_population_id();
    my $population = CXGN::Phenome::Population->new($self->get_dbh(), $population_id);
    
    return $population;
}

=head2 add_individual_dbxref

 Usage: $self->add_individual_dbxref($dbxref, $individual_dbxref_id, $sp_person_id)
 Desc:  store/update individual_dbxref 
 Ret:   database id
 Args:  dbxref object , individual_dbxref_id(optional), sp_person_id
 Side Effects: accesses the database
 Example:

=cut

sub add_individual_dbxref {
    my $self=shift;
    my $dbxref=shift; #dbxref object
    my $ind_dbxref_id=shift;
    my $sp_person_id=shift;
    
    my $ind_dbxref=CXGN::Phenome::Individual::IndividualDbxref->new($self->get_dbh(), $ind_dbxref_id );
    $ind_dbxref->set_individual_id($self->get_individual_id() );
    $ind_dbxref->set_dbxref_id($dbxref->get_dbxref_id() );
    $ind_dbxref->set_sp_person_id($sp_person_id);
    $ind_dbxref_id = $ind_dbxref->store();
    
    #return $self->{ind_dbxref};
    return $ind_dbxref_id;
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


=head2 get_individual_dbxref

 Usage: $individual->get_individual_dbxref($dbxref)
 Desc:  access individual_dbxref object for a given individual and its dbxref object
 Ret:    an IndividualDbxref object
 Args:   dbxref object
 Side Effects:
 Example:

=cut

sub get_individual_dbxref {
    my $self=shift;
    my $dbxref=shift; # my dbxref object..
    my $query="SELECT individual_dbxref_id from phenome.individual_dbxref
                                        WHERE individual_id=? AND dbxref_id=? ";
   
    my $sth=$self->get_dbh()->prepare($query);
    $sth->execute($self->get_individual_id(), $dbxref->get_dbxref_id() );
    my ($individual_dbxref_id) = $sth->fetchrow_array();
    my $individual_dbxref= CXGN::Phenome::Individual::IndividualDbxref->new($self->get_dbh(), $individual_dbxref_id);
   
    return $individual_dbxref;
}

=head2 get_dbxref_lists

 Usage:        $self->get_dbxref_lists();
 Desc:         get all the dbxrefs terms associated with the individual
 Ret:          hash of 2D arrays . Keys are the db names values are  [dbxref object, individual_dbxref.obsolete]
 Args:         none
 Side Effects: none
 Example:

=cut

sub get_dbxref_lists {
    my $self=shift;
    my %dbxrefs;
    my $query= "SELECT db.name, dbxref.dbxref_id, individual_dbxref.obsolete FROM individual_dbxref
               JOIN public.dbxref USING (dbxref_id) JOIN public.db USING (db_id) 
               WHERE individual_id= ? ORDER BY db.name, dbxref.accession";
    my $sth=$self->get_dbh()->prepare($query);
    $sth->execute($self->get_individual_id());
    while (my ($db_name, $dbxref_id, $obsolete) = $sth->fetchrow_array()) {
	push @ {$dbxrefs{$db_name} }, [CXGN::Chado::Dbxref->new($self->get_dbh(), $dbxref_id), $obsolete] ;
    }
    return %dbxrefs;
}

=head2 get_individual_annotations

 Usage: $self->get_individual_annotations($dbh, $cv_name)
 Desc:  retrieve all cvterm annotations from the individual database
 Ret:  @annotations  
 Args: $dbh, controlled vocabulary name, as appears in cv table (e.g. plant_structure)
 Side Effects:
 Example:

=cut

sub get_individual_annotations {
    my $self=shift;
    my $dbh=shift;
    my $cv_name=shift;
    my @annotations;
    my $query = "SELECT individual_dbxref_id FROM phenome.individual_dbxref
                 JOIN public.dbxref USING (dbxref_id) 
                 JOIN public.cvterm USING (dbxref_id) 
                 JOIN public.cv USING (cv_id)
                 WHERE cv.name = ? AND individual_dbxref.obsolete= 'f' ORDER BY individual_id";
    my $sth=$dbh->prepare($query);
    $sth->execute($cv_name);
    while (my ($individual_dbxref_id) = $sth->fetchrow_array()) {
	my $individual_dbxref= CXGN::Phenome::Individual::IndividualDbxref->new($dbh, $individual_dbxref_id);
	push @annotations , $individual_dbxref;
    }
    return @annotations;
}


=head2 get_annotations_by_db

 Usage: $self->get_annotations_by_db('PO')
 Desc:  find all individual cvterm annotations for a given db
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
    my $query = "SELECT individual_dbxref_id FROM phenome.individual_dbxref
                 JOIN public.dbxref USING (dbxref_id) 
                 JOIN public.db USING (db_id)
                 JOIN public.cvterm USING (dbxref_id) 
                 WHERE db.name = ? AND individual_dbxref.obsolete= 'f'";
    my $sth=$dbh->prepare($query);
    $sth->execute($db_name);
    while (my ($individual_dbxref_id) = $sth->fetchrow_array()) {
	my $individual_dbxref= CXGN::Phenome::Individual::IndividualDbxref->new($dbh, $individual_dbxref_id);
	push @annotations , $individual_dbxref;
    }
    return @annotations;
}

=head2 get_owners

 Usage: my @owners=$i->get_owners()
 Desc:  get all the owners of the current individual object 
 Ret:   an array of SGN person ids (it is just one for now..)
 Args:  none 
 Side Effects:
 Example:

=cut

sub get_owners {
    my $self=shift;
    my $query = "SELECT sp_person_id FROM phenome.individual
                 WHERE individual_id = ? AND obsolete = 'f'";
    my $sth=$self->get_dbh()->prepare($query);
    $sth->execute($self->get_individual_id());
    my $person;
    my @owners = ();
    while (my ($sp_person_id) = $sth->fetchrow_array()) { 
        $person = CXGN::People::Person->new($self->get_dbh(), $sp_person_id);
	push @owners, $sp_person_id;
    }
    return @owners;
}

=head2 get_existing_organisms
 
 Usage:        my ($names_ref, $ids_ref) = CXGN::Phenome::INdividual::get_existing_organisms($dbh);
 Desc:         This is a static function. Selects the distinct organism names and their IDs from phenome.individual.
               Useful for populating a unique drop-down menu with only the organism names that exist in the table.
 Ret:          Returns two arrayrefs. One array contains all the
               organism names, and the other all the organism ids
               with corresponding array indices.
 Args:         a database handle
 Side Effects:
 Example:
 

=cut

sub get_existing_organisms {
    my $dbh= shift;
    my $query = "SELECT distinct(common_name), common_name_id FROM phenome.individual 
                 JOIN sgn.common_name using(common_name_id) 
                 WHERE obsolete = 'f'";
    my $sth = $dbh->prepare($query);
    $sth->execute();
    my @names = ();
    my @ids = ();
    while (my($common_name, $common_name_id) = $sth->fetchrow_array()) { 
	push @names, $common_name;
	push @ids, $common_name_id;
    }
    return (\@names, \@ids);
}


=head2 get_phenotypes

 Usage: $self->get_phenotypes()
 Desc:  find associated phenotypes
 Ret:   an array of  phenotype objects
 Args:  none
 Side Effects: none
 Example:

=cut

sub get_phenotypes {
    my $self=shift;
    my $query = "SELECT phenotype_id
                        FROM  public.phenotype 
                        LEFT JOIN phenome.individual using (individual_id) 
                        LEFT JOIN  public.cvterm ON (observable_id = cvterm_id) 
                        WHERE individual_id =? 
                        ORDER BY cvterm.name";

    my $sth = $self->get_dbh()->prepare($query);
    
    $sth->execute($self->get_individual_id());
    my @phenotypes;
    
    while (my ($id) = $sth->fetchrow_array()) {
	my $pheno=CXGN::Chado::Phenotype->new($self->get_dbh(), $id);
	push @phenotypes, $pheno;
	
    }
    return @phenotypes;
}


=head2 get_phenotype_data

 Usage:
 Desc:  deprecated? use get_phenotypes instead
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_phenotype_data {
    my $self=shift;
    my $individual_id=$self->get_individual_id();
   
    my $query = "SELECT observable_id, cvterm.name, cvterm.definition, value
                        FROM  public.phenotype 
                        LEFT JOIN phenome.individual using (individual_id) 
                        LEFT JOIN  public.cvterm ON (observable_id = cvterm_id) 
                        WHERE individual_id =? 
                        ORDER BY cvterm.name";

    my $sth = $self->get_dbh()->prepare($query);
    
    $sth->execute($individual_id);
    my (@obs_id, @cvterm, @definition, @value);

    while (my ($obs_id, $cvterm, $definition, $value) =$sth->fetchrow_array()) {

	if (!defined($value)) {$value= 'N/A';}
	elsif ($value == 0) {$value = '0.0';}
	
	push @obs_id, $obs_id;

	push @cvterm, $cvterm;
        push @definition, $definition;
	
	push @value, $value;

    }
    return  \@obs_id, \@cvterm, \@definition, \@value;
}
=head2 get_unique_cvterms

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_unique_cvterms {
    my $self=shift;
    my $individual_id=shift;
   
    my $query = "SELECT DISTINCT cvterm.name, observable_id
                        FROM  public.phenotype
                        LEFT JOIN  public.cvterm ON (observable_id = cvterm_id) 
                        WHERE individual_id =?
			ORDER BY cvterm.name"; 
                        
    my $sth = $self->get_dbh()->prepare($query);
    
    $sth->execute($individual_id);
    my @name;
    my @obs_id;

    while (my ($name, $obs_id) =$sth->fetchrow_array()) {

	push @name, $name;
        push @obs_id, $obs_id;
    }
    return @name;
}

=head2 add_synonym

 Usage: $self->add_synonym('synonym1')
 Desc:  a list constructor for individual_synonyms 
 Ret:   nothing
 Args:  a synonym
 Side Effects:  none
 Example:

=cut


sub add_synonym {
    my $self=shift;
    my $synonym=shift; #
    push @{ $self->{synonyms} }, $synonym;
}

=head2 add_individual_alias

 Usage: $self->add_individual_alias($synonym, $sp_person_id)
 Desc:  add an alias to the individual
 Ret:   an individual_alias id
 Args:  a synonym and sp_person_id
 Side Effects: stores the alias in the database
 Example:

=cut

sub add_individual_alias {
    my $self=shift;
    my $alias = shift; #individual alias
    my $sp_person_id=shift;
    #my $locus_alias=CXGN::Phenome::LocusSynonym->new($self->get_dbh());
    my $query= "INSERT INTO phenome.individual_alias (individual_id, alias, sp_person_id)
                 VALUES (?,?,?)";
    my $sth=$self->get_dbh()->prepare($query);
    $sth->execute($self->get_individual_id(), $alias, $sp_person_id);
    my $id= $self->get_currval("phenome.individual_alias_individual_alias_id_seq");
    return $id;
}


=head2 get_aliases

 Usage: $self->get_aliases()
 Desc:  find the aliases of the individual
 Ret:    list of individual_aliases
 Args:   none
 Side Effects: none
 Example:

=cut

sub get_aliases {
    my $self=shift;
    my $query="SELECT alias from phenome.individual_alias WHERE individual_id=? and obsolete ='f' AND preferred ='f'";
    my $sth=$self->get_dbh()->prepare($query);
    my @synonyms;
    $sth->execute($self->get_individual_id());
    while (my ($alias) = $sth->fetchrow_array() ) {
	#my $lso=CXGN::Phenome::LocusSynonym->new($self->get_dbh(), $ls_id);
	push @synonyms, $alias;
    }
    return @synonyms;
}
#######do not remove#    
return 1; ###########
####################
