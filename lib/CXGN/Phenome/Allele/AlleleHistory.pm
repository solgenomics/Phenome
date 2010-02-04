=head1 NAME

CXGN::Phenome::Allele::AlleleHistory 

A subclass of Phenome::Allele for accessing the history edits of an allele object 

=head1 SYNOPSIS

=head1 AUTHOR

Naama Menda (nm249@cornell.edu)

=cut

use CXGN::DB::Connection;


package CXGN::Phenome::Allele::AlleleHistory;

use base qw / CXGN::Phenome::Allele /;

=head2 new

 Usage: my $history = CXGN::Phenome::Allele::AlleleHistory->new($dbh,$locus_history_id);
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
   
    $self->set_allele_history_id($id);  
  
    if ($id) {
	$self->fetch($id); #get the locus_history  details   
    }
    
    return $self;
}


sub fetch {
    my $self=shift;
    
    my $history_query = $self->get_dbh()->prepare("SELECT locus_id, allele_id,allele_symbol, allele_name, mode_of_inheritance, allele_phenotype, sequence, sp_person_id, updated_by, obsolete, create_date FROM phenome.allele_history WHERE allele_history_id=? ");

    $history_query->execute($self->get_allele_history_id());

    my ($locus_id, $allele_id,$allele_symbol,$allele_name,$mode_of_inheriance, $allele_phenotype, $sequence, $sp_person_id, $updated_by, $obsolete, $create_date)=$history_query->fetchrow_array();
    
    $self->set_locus_id($locus_id);
    $self->set_allele_id($allele_id);
    $self->set_allele_symbol($allele_symbol);
    $self->set_allele_name($allele_name);
    $self->set_mode_of_inheritance($mode_of_inheritance);
    $self->set_allele_phenotype($allele_phenotype);
    $self->set_sequence($sequence);
    $self->set_sp_person_id($sp_person_id);
    $self->set_updated_by($updated_by);
    $self->set_obsolete($obsolete);
    $self->set_create_date($create_date);
}

sub store { 

}


=head2 get_allele_history_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_allele_history_id {
  my $self=shift;
  return $self->{allele_history_id};

}

=head2 set_allele_history_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_allele_history_id {
  my $self=shift;
  $self->{allele_history_id}=shift;
}


sub delete { 
}


### Do not remove
1;#
###
