=head1 NAME

CXGN::Phenome::Locus::LocusHistory 

A subclass of Phenome::Locus for accessing the history edits of a locus object 

=head1 SYNOPSIS

=head1 AUTHOR

Naama Menda (nm249@cornell.edu)

=cut

use CXGN::DB::Connection;


package CXGN::Phenome::Locus::LocusHistory;

use base qw / CXGN::Phenome::Locus /;

=head2 new

 Usage: my $history = CXGN::Phenome::Locus::LocusHistory->new($dbh,$locus_history_id);
 Desc:
 Ret:    
 Args: $dbh, $locus_history_id
 Side Effects:
 Example:

=cut

sub new {
    my $class = shift;
    my $dbh = shift;
    my $id= shift; # the primary key in the databaes of this object

    my $args = {};  
    
    my $self=$class->SUPER::new($dbh);   
   
    $self->set_locus_history_id($id);  
  
    if ($id) {
	$self->fetch($id); #get the locus_history  details   
    }
    
    return $self;
}


sub fetch {
    my $self=shift;
    
    my $history_query = $self->get_dbh()->prepare("SELECT locus_history_id, locus_id,locus_name, locus_symbol, original_symbol, gene_activity, locus_description, linkage_group, lg_arm, sp_person_id, updated_by, obsolete, create_date FROM phenome.locus_history WHERE locus_history_id=? ");

    $history_query->execute($self->get_locus_history_id());

    my ($locus_history_id, $locus_id,$locus_name,$locus_symbol,$original_symbol, $gene_activity, $description, $linkage_group, $lg_arm, $sp_person_id, $updated_by, $obsolete, $create_date)=$history_query->fetchrow_array();
    
    $self->set_locus_history_id($locus_history_id);
    $self->set_locus_id($locus_id);
    $self->set_locus_name($locus_name);
    $self->set_locus_symbol($locus_symbol);
    $self->set_original_symbol($original_symbol);
    $self->set_gene_activity($gene_activity);
    $self->set_description($description);
    $self->set_linkage_group($linkage_group);
    $self->set_lg_arm($lg_arm);
    $self->set_sp_person_id($sp_person_id);
    $self->set_updated_by($updated_by);
    $self->set_obsolete($obsolete);
    $self->set_create_date($create_date);
}

sub store { 

}


=head2 get_locus_history_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_locus_history_id {
  my $self=shift;
  return $self->{locus_history_id};

}

=head2 set_locus_history_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_locus_history_id {
  my $self=shift;
  $self->{locus_history_id}=shift;
}


sub delete { 
}


### Do not remove
1;#
###
