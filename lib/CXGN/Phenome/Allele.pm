

=head1 NAME

CXGN::Phenome::Allele 
display alleles of a locus 

=head1 SYNOPSIS

=head1 AUTHOR

Naama

=cut
package CXGN::Phenome::Allele;

use CXGN::DB::Connection;
use CXGN::Phenome::Locus; 
use CXGN::Phenome::AlleleSynonym;
use CXGN::Phenome::Individual;
use CXGN::Phenome::AlleleDbxref;
use CXGN::Phenome::Allele::AlleleHistory;

use base qw / CXGN::DB::ModifiableI  /;

=head2 new

 Usage: my $gene = CXGN::Phenome::Allele->new($dbh, $allele_id);
 Desc:
 Ret:    
 Args: $dbh, $allele_id
 Side Effects:
 Example:

=cut

sub new {
    my $class = shift;
    my $dbh= shift;
    my $id= shift; # the allele_id of the allele object 
    
    my $args = {};  

    my $self=$class->SUPER::new($dbh);   
    $self->set_allele_id($id);
      
    if ($id) {
	$self->fetch($id);
	
        #get an array of allele synonym IDs
	my $allele_alias_query=$self->get_dbh()->prepare("SELECT allele_alias_id from phenome.allele_alias WHERE allele_id=? and obsolete ='f'");
	my @allele_synonyms;
	$allele_alias_query->execute($id);
	while (my ($as) = $allele_alias_query->fetchrow_array()) {
	    push @allele_synonyms, $as;
	}
	#get an array of allele synonym objects
	foreach $as_id (@allele_synonyms) {
	    my $allele_synonym_obj=CXGN::Phenome::AlleleSynonym->new($dbh, $as_id);
	    $self->add_allele_aliases($allele_synonym_obj);
	}
    }    
    return $self;
}



sub fetch {
    my $self=shift;
    
    my $allele_query = "SELECT  locus_id, allele_symbol, allele_name, mode_of_inheritance, allele_synonym, allele_phenotype, allele.sp_person_id, allele.updated_by, allele.obsolete, allele.create_date, locus_name, is_default, sequence FROM phenome.allele join phenome.locus using (locus_id) WHERE allele_id=? ";
    my $sth=$self->get_dbh()->prepare($allele_query);
         	   
    $sth->execute( $self->get_allele_id() );

    my ($locus_id, $allele_symbol, $allele_name, $mode_of_inheritance, $allele_synonym, $allele_phenotype, $sp_person_id, $updated_by, $obsolete, $create_date, $locus_name, $is_default, $sequence)=$sth->fetchrow_array();

    $self->set_locus_id($locus_id);
    $self->set_allele_symbol($allele_symbol);
    $self->set_allele_name($allele_name);
    $self->set_mode_of_inheritance($mode_of_inheritance);
    $self->set_allele_synonym($allele_synonym);
    $self->set_allele_phenotype($allele_phenotype);
    $self->set_sp_person_id($sp_person_id);
    $self->set_updated_by($updated_by);
    $self->set_obsolete($obsolete);
    $self->set_create_date($create_date),
    $self->set_locus_name($locus_name);
    $self->set_is_default($is_default);
    $self->set_sequence($sequence);
}

=head2 delete

 Usage: $self->delete()
 Desc:   obsolete the allele
 Ret: nothing 
 Args: nothing 
 Side Effects:
 Example:

=cut


sub delete { 
    my $self = shift;
    if ($self->get_allele_id()) { 

	my $query = "UPDATE phenome.allele SET obsolete='t'
                  WHERE allele_id=?";
	my $sth = $self->get_dbh()->prepare($query);
	$sth->execute($self->get_allele_id());
	#$self->store_history();
    }else { 
	print STDERR  "trying to delete an allele that has not yet been stored to db.\n";
    }   
    return $self->get_allele_id();
}		 

     

=head2 exists_in_database

 Usage: $self->exists_in_database($allele_symbol, $locus_id) 
 Desc:  check if the allele symbol exists for a locus
 Ret:   a message string or undef
 Args:   allele_symbol, locus_id (both optional, if the allele does not have one set) 
 Side Effects: none
 Example:

=cut


sub exists_in_database {
    my $self=shift;
    my $allele_symbol = shift || $self->get_allele_symbol() ;
    my $locus_id= shift || $self->get_locus_id();
    my $allele_id= $self->get_allele_id();
    
    if (!$locus_id || !$allele_symbol) { die "Cannot check if allele exists in database without a locus id and an allele symbol! \n" ; }
    my $query = "SELECT allele_id 
                 FROM phenome.allele
                 WHERE allele_symbol ILIKE ? and locus_id = ? and obsolete = ? and is_default =?";
    my $sth = $self->get_dbh->prepare($query);
    $sth->execute($allele_symbol, $locus_id, 'f', 'f');
    my ($id)=$sth->fetchrow_array();
    
    if ( ($id && ($allele_id!= $id) )   ) { 
	my $message = "";
	if($id){
	    $message = "Insert failed: phenome.allele.allele_id=$id ($allele_symbol) already exists in database\n";
	}
	elsif($allele_id!=$id){
	    $message = "Update failed: allele_id $id ($allele_symbol) fetched from database, should be $allele_id\n";
	}
	return $message;
    }
    else {  return 0; }
}


=head2 store
    
 Usage: $self->store()
 Desc:  store a new allele/ update an existing one
 Ret:   database id 
 Args:  none
 Side Effects: inserts/updates a database row
 Example:

=cut

sub store {
    my $self= shift;
    my $allele_id= $self->get_allele_id();
    my $exists=$self->exists_in_database();
    
    if ($allele_id) {
	$self->store_history();
	my $query = "UPDATE phenome.allele SET
                         obsolete= 'f',
                         allele_symbol=?,
                         allele_name=?,
                         mode_of_inheritance=?,
                         allele_phenotype=?, 
                         updated_by=?,
                         modified_date = now(),
                         sequence= ?
                         where allele_id=?";
	my $sth = $self->get_dbh()->prepare($query);
	$sth->execute($self->get_allele_symbol(), $self->get_allele_name, $self->get_mode_of_inheritance, $self->get_allele_phenotype, $self->get_updated_by, $self->get_sequence(), $allele_id);

    }elsif (!$exists) {
	my $query = "INSERT INTO phenome.allele (locus_id, allele_symbol, allele_name, mode_of_inheritance, allele_phenotype, sp_person_id, is_default, sequence) VALUES(?,?,?,?,?,?,?,?) RETURNING allele_id";
	my $sth= $self->get_dbh()->prepare($query);
	my $is_default = $self->get_is_default();

       	$sth->execute($self->get_locus_id, $self->get_allele_symbol, $self->get_allele_name, $self->get_mode_of_inheritance, $self->get_allele_phenotype, $self->get_sp_person_id, $is_default, $self->get_sequence());
    	($allele_id) = $sth->fetchrow_array;
	$self->set_allele_id($allele_id);

    }elsif ($exists) {
	$allele_id=$exists ;
	print STDERR "Allele.pm cannot store existing allele. id = $allele_id, locus_id =" .  $self->get_locus_id() . ", symbol= ". $self->get_allele_symbol() ."\n";
    }
    return $allele_id;
}


=head2 accessors are available for the following: 
 allele_id
 allele_symbol
 allele_name
 allele_synonym
 mode_of_inheritance
 allele_phenotype
 sequence

=cut


sub get_allele_id {
  my $self=shift;
  return $self->{allele_id};
}

sub set_allele_id {
  my $self=shift;
  $self->{allele_id}=shift;
}

sub get_allele_symbol {
  my $self=shift;
  return $self->{allele_symbol};
}

sub set_allele_symbol {
  my $self=shift;
  $self->{allele_symbol}=shift;
}

sub get_allele_name {
  my $self=shift;
  return $self->{allele_name};

}

sub set_allele_name {
  my $self=shift;
  $self->{allele_name}=shift;
}

sub get_allele_synonym {
  my $self=shift;
  return $self->{allele_synonym};

}

sub set_allele_synonym {
  my $self=shift;
  $self->{allele_synonym}=shift;
}


sub get_mode_of_inheritance {
  my $self=shift;
  return $self->{mode_of_inheritance};

}

sub set_mode_of_inheritance {
  my $self=shift;
  $self->{mode_of_inheritance}=shift;
}

sub get_allele_phenotype {
  my $self=shift;
  return $self->{allele_phenotype};

}


sub set_allele_phenotype {
  my $self=shift;
  $self->{allele_phenotype}=shift;
}

sub get_sequence {
  my $self = shift;
  return $self->{sequence}; 
}

sub set_sequence {
  my $self = shift;
  $self->{sequence} = shift;
}



=head2 add_allele_aliases

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut


sub add_allele_aliases {
    my $self=shift;
    my $alias = shift; #allele alias object
    push @{ $self->{allele_aliases} }, $alias;
}

=head2 get_allele_aliases

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_allele_aliases {
  my $self=shift;
  return @{$self->{allele_aliases}};

}

=head2 remove_allele_alias

 Usage:
 Desc:
 Ret:
 Args: $allele_alias_id
 Side Effects:
 Example:


=cut

=head2 get_locus_name

  Usage: my $locus_name= $allele->get_locus_name();
 Desc: gets the name of the locus this allele is associated with from phenome.locus table  
 Ret:  the name of the locus this allele is associated with
 Args: 
 Side Effects:
 Example:

=cut

sub get_locus_name {
  my $self=shift;
  return $self->{locus_name};

}

=head2 set_locus_name

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_locus_name {
  my $self=shift;
  $self->{locus_name}=shift;
}


=head2 get_locus_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_locus_id {
  my $self=shift;
  return $self->{locus_id};

}

=head2 set_locus_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_locus_id {
  my $self=shift;
  $self->{locus_id}=shift;
}


=head2 get_is_default

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_is_default {
    my $self=shift;
    if (!exists($self->{is_default}) || !defined($self->{is_default})) { $self->{is_default}='f'; }
    return $self->{is_default};
}

=head2 set_is_default

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_is_default {
  my $self=shift;
  my $default=shift;
  if ($default eq "1") { $default = "t"; }
  if ($default eq "0") { $default = "f"; }
  if ($default ne "t" && $default ne "f") { 
      print STDERR "Allele.pm: set_is_default parameters can either be t or f.\n";
  }
  $self->{is_default}=$default;
}

sub remove_allele_alias { 
    my $self = shift;
    my $allele_synonym_id = shift;
    my $query = "UPDATE phenome.allele_alias
                        SET obsolete= 't'
                        WHERE allele_id=? AND allele_alias_id=?";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_allele_id(), $allele_synonym_id);
}


=head2 function get_individuals

  Synopsis:	$allele->get_individuals()
  Arguments:	none
  Returns:	An arrayref of individual objects
  Side effects:	
  Description:	Gets all individuals associated with this allele
                from the linking table phenome.individual_allele

=cut

sub get_individuals {
    my $self = shift;
    my $query = "SELECT individual_id FROM phenome.individual_allele WHERE allele_id=? AND obsolete= 'f'";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_allele_id());
    my $individual;
    my @individuals =();
    while (my ($individual_id) = $sth->fetchrow_array()) { 
	$individual = CXGN::Phenome::Individual->new($self->get_dbh(), $individual_id);
	push @individuals, $individual;
    }
    return @individuals;
}

=head2 add_allele_dbxref

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub add_allele_dbxref {
    my $self=shift;
    my $dbxref=shift; #dbxref object
    my $allele_dbxref_id=shift;
    my $sp_person_id=shift;
    
    my $allele_dbxref=CXGN::Phenome::AlleleDbxref->new($self->get_dbh(), $allele_dbxref_id );
    $allele_dbxref->set_allele_id($self->get_allele_id() );
    $allele_dbxref->set_dbxref_id($dbxref->get_dbxref_id() );
    $allele_dbxref->set_sp_person_id($sp_person_id);
    $allele_dbxref->store();
    
    return $self->{allele_dbxref} ;
}

=head2 get_allele_dbxref

 Usage: $allele->get_allele_dbxref($dbxref)
 Desc:  access allele_dbxref object for a given allele and its dbxref object
 Ret:    an AlleleDbxref object
 Args:   dbxref object
 Side Effects:
 Example:

=cut

sub get_allele_dbxref {
    my $self=shift;
    my $dbxref=shift; # my dbxref object..
    my $query=$self->get_dbh()->prepare("SELECT allele_dbxref_id from phenome.allele_dbxref
                                        WHERE allele_id=? AND dbxref_id=? ");
    $query->execute($self->get_allele_id(), $dbxref->get_dbxref_id() );
    my ($allele_dbxref_id) = $query->fetchrow_array();
    my $allele_dbxref= CXGN::Phenome::AlleleDbxref->new($self->get_dbh(), $allele_dbxref_id);
    return $allele_dbxref;
}


=head2 get_all_allele_dbxrefs

 Usage: $allele->get_all_allele_dbxrefs
 Desc:  fetch all dbxrefs associated with an allele
 Ret: an array of dbxref objects
 Args: none
 Side Effects:
 Example:

=cut

sub get_all_allele_dbxrefs {   #get an array of dbxref objects (from public dbxref):
    my $self=shift;
    my @allele_dbxrefs;
    my $dbxref_query=$self->get_dbh()->prepare("SELECT dbxref_id from phenome.allele_dbxref JOIN public.dbxref USING (dbxref_id) WHERE allele_id=? ORDER BY public.dbxref.accession"); 
    my @dbxref_id;
    $dbxref_query->execute($self->get_allele_id() );
    while (my ($d) = $dbxref_query->fetchrow_array() ) {
	push @dbxref_id, $d;
    }
    #an array of dbxref objects
    foreach $id (@dbxref_id) {
	my $dbxref_obj= CXGN::Chado::Dbxref->new($self->get_dbh(), $id);
	#$self->add_dbxref($dbxref_obj);
	push @allele_dbxrefs, $dbxref_obj;
    }
    return @allele_dbxrefs;
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


=head2 store_history

 Usage: $self->store_history()
 Desc:  Inserts the current fields of an allele object into the allele_history table before updating the allele details
 Ret:   
 Args: none
 Side Effects: 
 Example:

=cut

sub store_history {
    my $self=shift;
    my $allele=CXGN::Phenome::Allele->new($self->get_dbh(), $self->get_allele_id() );

    my $history_query = "INSERT INTO phenome.allele_history (allele_id, locus_id, allele_symbol, allele_name, mode_of_inheritance,allele_phenotype, sp_person_id, updated_by, obsolete, create_date, sequence) 
                             VALUES(?,?,?,?,?,?,?,?,?,now(), ?)";
    my $history_sth= $self->get_dbh()->prepare($history_query);
    
    $history_sth->execute($allele->get_allele_id(), $allele->get_locus_id(), $allele->get_allele_symbol(),  $allele->get_allele_name(), $allele->get_mode_of_inheritance(), $allele->get_allele_phenotype(), $allele->get_sp_person_id, $self->get_updated_by(), $allele->get_obsolete(), $allele->get_sequence() );
    
    
}

=head2 show_history

  Usage: $allele->show_history();
 Desc:   Selects the data from allele_history table for an allele object 
 Ret:    
 Args:    
 Side Effects:
 Example:

=cut

sub show_history {
    my $self=shift;
    my $allele_id= $self->get_allele_id();
    my $history_query=$self->get_dbh()->prepare("SELECT allele_history_id FROM phenome.allele_history WHERE allele_id=?"); 
    my @history;
    $history_query->execute($allele_id);
    while (my ($history_id) = $history_query->fetchrow_array()) { 
	my $history_obj = CXGN::Phenome::Allele::AlleleHistory->new($self->get_dbh(), $history_id);
	push @history, $history_obj;
    }
    return @history;
}


=head2 get_owners

 Usage: my @owners=$allele->get_owners()
 Desc:  get all the owners of the current allele object 
 Ret:   an array of SGN person ids (it is just one for now..)
 Args:  none 
 Side Effects:
 Example:

=cut

sub get_owners {
    my $self=shift;
    my $query = "SELECT sp_person_id FROM phenome.allele
                 WHERE allele_id = ? AND obsolete = 'f'";
    my $sth=$self->get_dbh()->prepare($query);
    $sth->execute($self->get_allele_id());
    my $person;
    my @owners = ();
    while (my ($sp_person_id) = $sth->fetchrow_array()) { 
        $person = CXGN::People::Person->new($self->get_dbh(),$sp_person_id);
	push @owners, $sp_person_id;
    }
    return @owners;
}

=head2 new_with_symbol

 Usage: CXGN::Phenome::Allele->new_with_symbol($dbh, $symbol,$species)
 Desc:  instanciate a new allele object using a symbol and a common_name
 Ret:  an allele object (or undef if allele_symbol is not unique! ) 
 Args: dbh, symbol, and common_name 
 Side Effects: 
 Example:

=cut

sub new_with_symbol {
    my $class = shift;
    my $dbh = shift;
    my $symbol = shift;
    my $species = shift;
    my $query = "SELECT allele_id FROM phenome.allele 
                 JOIN phenome.locus USING (locus_id)  
                 JOIN sgn.common_name using(common_name_id) 
                 WHERE allele_symbol=? AND common_name ilike ?";
    my $sth = $dbh->prepare($query);
    $sth->execute($symbol, $species);
    my @ids;
     while (my ($id) = $sth->fetchrow_array()) {
	push @ids, $id;	
    }
    if (scalar(@ids) > 1 ) {
	warn "Allele.pm: new_with_symbol found more than one allele with iname $symbol! Cannot instanciate new allele object. Returning 'undef'."; 
	return undef;
    }
    my $id= $ids[0] ;
    my $self = $class->new($dbh, $id);
    return $self;
}

=head2 get_dbxref_lists

 Usage:        $allele->get_dbxref_lists();
 Desc:         get all the dbxrefs terms associated with an allele
 Ret:          hash of 2D arrays . Keys are the db names values are  [dbxref object, allele_dbxref.obsolete]
 Args:         none
 Side Effects: none
 Example:

=cut

sub get_dbxref_lists {
    my $self=shift;
    my %dbxrefs;
    my $query= "SELECT db.name, dbxref.dbxref_id, allele_dbxref.obsolete FROM allele_dbxref
               JOIN public.dbxref USING (dbxref_id) JOIN public.db USING (db_id) 
               WHERE allele_id= ? ORDER BY db.name, dbxref.accession";
    my $sth=$self->get_dbh()->prepare($query);
    $sth->execute($self->get_allele_id());
    while (my ($db_name, $dbxref_id, $obsolete) = $sth->fetchrow_array()) {
	push @ {$dbxrefs{$db_name} }, [CXGN::Chado::Dbxref->new($self->get_dbh(), $dbxref_id), $obsolete] ;
    }
    return %dbxrefs;
}

=head2 get_locus

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_locus {
    my $self=shift;
    my $locus_id= $self->get_locus_id();
    my $locus= CXGN::Phenome::Locus->new($self->get_dbh(), $locus_id);
    return $locus;
}


###
1;#do not remove
###



