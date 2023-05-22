

=head1 NAME

CXGN::Phenome::LocusDbxref
display dbxrefs associated with a locus

=head1 SYNOPSIS

=head1 AUTHOR

Naama Menda (nm249@cornell.edu)

=cut
use CXGN::DB::Connection;
use CXGN::Phenome::Locus;
use CXGN::Phenome::Locus::LocusDbxrefEvidence;
use CXGN::Chado::Dbxref::DbxrefI;

package CXGN::Phenome::LocusDbxref;

#use base qw / CXGN::Phenome::Main CXGN::Phenome::Locus CXGN::DB::ModifiableI CXGN::Chado::Dbxref::DbxrefI /;
use base qw /  CXGN::Chado::Dbxref::DbxrefI  /;


=head2 new

 Usage: my $locus_dbxref = CXGN::Phenome::LocusDbxref->new($dbh, $locus_dbxref_id);
 Desc:
 Ret:
 Args: $dbh, $locus_dbxref_id
 Side Effects:
 Example:

=cut

sub new {
    my $class = shift;
    my $dbh= shift;
    my $id= shift; # the locus_dbxref_id of the LocusDbxref object

    my $args = {};

    my $self=$class->SUPER::new($dbh);

    $self->set_object_dbxref_id($id);

    if ($id) {
	$self->fetch($id);
    }

    return $self;
}




sub fetch {
    my $self=shift;

    my $locus_dbxref_query = $self->get_dbh()->prepare("SELECT  locus_id, dbxref_id, sp_person_id, create_date, modified_date, obsolete FROM phenome.locus_dbxref WHERE locus_dbxref_id=?");

    my $locus_dbxref_id=$self->get_object_dbxref_id();

    $locus_dbxref_query->execute($locus_dbxref_id);

    my ($locus_id, $dbxref_id, $sp_person_id, $create_date, $modified_date, $obsolete)=$locus_dbxref_query->fetchrow_array();
    $self->set_locus_id($locus_id);
    $self->set_dbxref_id($dbxref_id);
    $self->set_sp_person_id($sp_person_id);
    $self->set_create_date($create_date);
    $self->set_modification_date($modified_date);
    $self->set_obsolete($obsolete);
}


=head2 store

 Usage:  $self->store()
 Desc:   store a new dbxref for your locus.
         Update obsolete = 'f' if  locus_dbxref is obsolete.
         Do nothing if locus_dbxref exists and obsolete= 'f'
 Ret:   database id
 Args:  none
 Side Effects: check if locus_dbxref exists in database and if obsolete
 Example:

=cut


sub store {
    my $self= shift;
    my $obsolete= $self->get_obsolete();
    my $locus_dbxref_id=$self->get_object_dbxref_id() || locus_dbxref_exists($self->get_dbh(), $self->get_locus_id(), $self->get_dbxref_id() );
    if (!$locus_dbxref_id) {
	$self->d("Inserting new locus_dbxref");
	my $query = "INSERT INTO phenome.locus_dbxref (locus_id, dbxref_id, sp_person_id) VALUES(?,?,?) RETURNING locus_dbxref_id";
	my $sth= $self->get_dbh()->prepare($query);
	$sth->execute($self->get_locus_id, $self->get_dbxref_id, $self->get_sp_person_id);
	($locus_dbxref_id) = $sth->fetchrow_array();

	$self->set_object_dbxref_id($locus_dbxref_id);

    }elsif ($obsolete eq 't' ) {
	$self->d("Updating a locus_dbxref $locus_dbxref_id. Setting obsolete='f'");
	my $query = "UPDATE phenome.locus_dbxref SET obsolete='f', sp_person_id=? , modified_date=now()
            WHERE locus_dbxref_id=?";
	my $sth= $self->get_dbh()->prepare($query);
	$sth->execute($self->get_sp_person_id, $locus_dbxref_id);
    }else { $self->d("locus_dbxref already stored!! (id=$locus_dbxref_id)");  }
    return $locus_dbxref_id;
}


=head2 obsolete

 Usage: $self->obsolete()
 Desc:  sets to obsolete a locus_dbxref
 Ret: nothing
 Args: none
 Side Effects: obsoletes the evidence codes
               and stores the locus_dbxref_evidence entry in its history table.
               See LocusDbxrefEvidence->store_history()
 Example:

=cut

sub obsolete {

    my $self = shift;
    if ($self->get_object_dbxref_id()) {
	my $query = "UPDATE phenome.locus_dbxref SET obsolete='t', modified_date=now()
                  WHERE locus_dbxref_id=?";
	my $sth = $self->get_dbh()->prepare($query);
	$sth->execute($self->get_object_dbxref_id());
	#this stores the locus_dbxref_evidence entry in its history table, if the same term was ever unobsolete
	#the history helps keep track of the previous evidence codes that now have been updated.
	# obsolete all derived evidence codes and store_history();
	foreach ($self->get_locus_dbxref_evidence()) { $_-> obsolete(); }
	print STDERR "obsoleting locus_dbxref_id: ". $self->get_object_dbxref_id() . "!\n\n";
    }else { 
	print STDERR  "trying to obsolete a locus_dbxref that has not yet been stored to db.\n";
    }
}


=head2 unobsolete

 Usage: $self->unobsolete()
 Desc:  unobsolete a locus_dbxref
 Ret: nothing
 Args: none
 Side Effects:
 Example:

=cut

sub unobsolete {
    my $self = shift;
    if ($self->get_object_dbxref_id()) {
	my $query = "UPDATE phenome.locus_dbxref SET obsolete='f', modified_date=now()
                  WHERE locus_dbxref_id=?";
	my $sth = $self->get_dbh()->prepare($query);
	$sth->execute($self->get_object_dbxref_id());

    }else {
	#print STDERR  "trying to unobsolete a locus_dbxref that has not yet been stored to db.\n";
    }
}


=head2 accessors in this class

    locus_dbxref_id (DEPRECATED use  object_dbxref_id)
    locus_id
    dbxref_id

The following accessors are available from Phenome::Main
    sp_person_id
    obsolete
    create_date
    modification_date

=cut

sub get_locus_dbxref_id {
  my $self=shift;
  #return $self->{locus_dbxref_id};
  warn "DEPRECATED. get_locus_dbxref_id has been replaced by get_object_dbxref_id";
  return $self->get_object_dbxref_id();
}

sub set_locus_dbxref_id {
  my $self=shift;
  #$self->{locus_dbxref_id}=shift;
  warn "DEPRECATED. set_locus_dbxref_id has been replaced by set_object_dbxref_id";
  $self->{object_dbxref_id}=shift;
}


sub get_locus_id {
  my $self=shift;
  return $self->{locus_id};

}

sub set_locus_id {
  my $self=shift;
  $self->{locus_id}=shift;
}


sub get_dbxref_id {
  my $self=shift;
  return $self->{dbxref_id};

}

sub set_dbxref_id {
  my $self=shift;
  $self->{dbxref_id}=shift;
}


=head2 get_locus_publications

 Usage: my $locus->get_locus_publications()
 Desc:  get all the publications associated with a locus
 Ret:   an array of publication objects
 Args:  none
 Side Effects:
 Example:

=cut

sub get_locus_publications {
    my $self=shift;
    my $query = $self->get_dbh()->prepare("SELECT pub_id FROM pub_dbxref
                                           JOIN dbxref USING (dbxref_id)
                                           JOIN phenome.locus_dbxref USING (dbxref_id)
                                           WHERE locus_id = ?");
    $query->execute($self->get_locus_id());
    my $publication;
    my @publications;
    while (my ($pub_id) = $sth->fetchrow_array()) {
	$publication = CXGN::Chado::Publication->new($self->get_dbh(), $pub_id);
	push @publications, $publication;
    }
    return @publications;
}

=head2 get_locus_dbxref_evidence

 Usage: my $locus_dbxref->get_locus_dbxref_evidence($obsolete)
 Desc:  get all the evidence data associated with a locus dbxref (ontology term)
 Ret:   a list of locus_dbxref_evidence objects
 Args:  optional - boolean for filtering obsolete evidence codes
 Side Effects:
 Example:

=cut

sub get_locus_dbxref_evidence {
    my $self=shift;
    my $obsolete = shift;
    my $query = "SELECT locus_dbxref_evidence_id FROM phenome.locus_dbxref_evidence
                                           WHERE locus_dbxref_id = ?";
    $query .= " AND locus_dbxref_evidence.obsolete = 'f' " if $obsolete;
    my $sth=$self->get_dbh()->prepare($query);
    my $locus_dbxref_id= $self->get_object_dbxref_id();

    $sth->execute($self->get_object_dbxref_id());
    my @evidences;

    while (my ($evidence_id) = $sth->fetchrow_array()) {
	my $evidence = CXGN::Phenome::Locus::LocusDbxrefEvidence->new($self->get_dbh(), $evidence_id);
	push @evidences, $evidence;
    }
    return @evidences;
}

=head2 get_object_dbxref_evidence

 Usage:
 Desc: a synonym for get_locus_dbxref_evidence. Need to have this alias for working with DbxrefI
 Ret:
 Args:
 Side Effects:
 Example:

=cut


sub get_object_dbxref_evidence {
    my $self=shift;
    return $self->get_locus_dbxref_evidence();

}

=head2 add_locus_dbxref_evidence

 Usage:       DEPRECATED
 Desc:         replaced by add_object_dbxref_evidence
 Ret:          nothing
 Args:
 Side Effects:
 Example:

=cut

sub add_locus_dbxref_evidence {
    my $self=shift;
    my $evidence=shift;
    warn "DEPRECATED. Replaced by add_object_dbxref_evidence() ! ";
    $self->add_locus_dbxref_evidence($evidence);
}



=head2 locus_dbxref_exists

 Usage: my $locus_dbxref_id= CXGN::Phenome::LocusDbxref::locus_dbxref_exists($dbh, $locus_id, $dbxref_id)
 Desc:  check if locus_id is associated with $dbxref_id
  Ret: $locus_dbxref_id
 Args:  $dbh, $locus_id, $dbxref_id
 Side Effects:
 Example:

=cut

sub locus_dbxref_exists {
    my ($dbh, $locus_id, $dbxref_id)=@_;
    my $query = "SELECT locus_dbxref_id from phenome.locus_dbxref
                 WHERE locus_id= ? and dbxref_id = ? ";
    my $sth=$dbh->prepare($query);
    $sth->execute($locus_id, $dbxref_id);
    my ($locus_dbxref_id) = $sth->fetchrow_array();
    return $locus_dbxref_id;
}


=head2 object_dbxref_exists

 Usage:
 Desc: A synonym for locus_dbxref_exists. Need this for overriding a function in DbxrefI
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub object_dbxref_exists {
    return locus_dbxref_exists(@_);
}


=head2 update_annotation

 Usage: $self->update_annotation($dbxref_id)
 Desc:  update the dbxref_id of an annotation
        To be used for updating an annotation to an obsolete term
 Ret:   nothing
 Args:  dbxref_id (replacing the obsolete cvterm
 Side Effects:  if a locus_dbxref already exists for the new dbxref - the old annotation
		   will be obsolete.
 Example:

=cut

sub update_annotation {
    my $self=shift;
    my $dbxref_id= shift;
    my $query = "UPDATE phenome.locus_dbxref SET dbxref_id=?
                       WHERE locus_dbxref_id=? ";

    my $existing_id=CXGN::Phenome::LocusDbxref::locus_dbxref_exists($self->get_dbh(), $self->get_locus_id(), $dbxref_id);
    if ($existing_id) {
	$self->obsolete();

    } else {
	my $sth=$self->get_dbh()->prepare($query);
	$sth->execute($dbxref_id, $self->get_object_dbxref_id());
    }
}
=head2 get_locus_by_dbxref

 Usage: CXGN::Phenome::LocusDbxref->get_locus_by_dbxref($dbh, $dbxref)
 Desc:  find the locus associated with a dbxref. Intended to use with load_match_unigenes.pl which finds a single locus associated with a genbank record.
 Ret:   locus object
 Args: dbh, dbxref object
 Side Effects: prints warning if more than one locus is found
 Example:

=cut

sub get_locus_by_dbxref {
    my $self=shift;
    my $dbh=shift;
    my $dbxref=shift;
    my $dbxref_id=$dbxref->get_dbxref_id();
    my $query ="SELECT locus_id FROM locus_dbxref JOIN locus using (locus_id)
                               WHERE dbxref_id=? AND locus.obsolete ='f' AND locus_dbxref.obsolete='f'";
    my $sth=$dbh->prepare($query);
    $sth->execute($dbxref_id);
    my @ids;
    while (my ($id) = $sth->fetchrow_array()) {
	push @ids, $id;
    }
    if (scalar(@ids) > 1 ) { warn "LocusDbxref.pm: get_locus_by_dbxref found more than one locus with dbxref $dbxref_id! Please check your databse."; }
    my $locus_id= $ids[0] || undef; #return only the 1st id
    my $locus = CXGN::Phenome::Locus->new($dbh, $locus_id);
    return $locus;
}



###
1;#do not remove
###
