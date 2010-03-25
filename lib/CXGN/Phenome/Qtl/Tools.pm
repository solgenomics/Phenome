#!/usr/bin/perl

=head1 NAME

CXGN::Phenome::Qtl::Tools

=head1 DESCRIPTION

Non-object-oriented functions for doing things with qtl data uploading, processing etc...

=head1 AUTHOR

Isaak Y Tecle (iyt2@cornell.edu)

=head1 FUNCTIONS

=cut

package CXGN::Phenome::Qtl::Tools;

use CXGN::Phenome::Qtl;
use CXGN::Phenome::Population;
use List::MoreUtils qw /uniq/;
use CXGN::DB::Connection;

use base qw /CXGN::DB::Object/ ;

sub new { 
    my $class = shift;   
    my $self = bless {}, $class;
    
    my $dbh = CXGN::DB::Connection->new();
    $self->set_dbh($dbh);
   
    return $self; 
}





=head2 cross_types

 Usage:  my @type = $->cross_types();
 Desc:  returns a list of cross types in the database.
 Ret: an array of cross types
 Args: none
 Side Effects:
 Example:

=cut

sub cross_types {
    my $self = shift;
    my $dbh = $self->get_dbh();

  
    my $sth = $dbh->prepare("SELECT cross_type_id, cross_type FROM phenome.cross_type");
    $sth->execute();
    
    my %cross_types;
    while (my ($cross_type_id, $cross_type) = $sth->fetchrow_array()) {
	 
	$cross_types{$cross_type_id}=$cross_type;
    }
    
    return %cross_types;


}

=head2 check_pop_fields

 Usage: my @missing = $qtl_tools->check_pop_fields(\%fields);
 Desc: checks if required population details form fields are filled or not. 
 Ret: an array of field names missing values
 Args: a hash_ref of the form arguments
 Side Effects:
 Example:

=cut

sub check_pop_fields {
    my $self=shift;
    my $args_ref = shift;
    my %args = %{$args_ref};

    my @messages=();
  
    my %error_messages = ( 
	           pop_name    => 'Population name',
	           pop_desc    => 'Population description',
	           pop_type    => 'Cross type',
	           pop_male_parent => 'Male parent',
                   pop_female_parent => 'Female parent',
                   pop_common_name_id => 'Organism common name'
	        );
                  # pop_donor_parent  => 'Donor parent',
                  # pop_recurrent_parent => 'Recurrent parent'
   	          # organism    => 'Organism', 
                   #traits_file       => 'Traits file',
                   #pheno_file        => 'Phenotype data file',
                   #geno_file         => 'Genotype data file',

    foreach my $k (keys (%args)) {
	my $v = $args{$k};
	unless ($v) {
	    my $error_message = $error_messages{$k};
	    if ($error_message) {
		push @messages, $error_message;
	    }
	}
    }
    
    	
return @messages;			   

}

=head2 check_stat_fields

 Usage: my @missing = $qtl_tools->check_stat_fields(\%fields);
 Desc: checks if required stat form fields are filled or not. 
 Ret: an array of field names missing values
 Args: a hash_ref of the form arguments
 Side Effects:
 Example:

=cut

sub check_stat_fields {
    my $self=shift;
    my $args_ref = shift;
    my %args = %{$args_ref};

    my @messages=();
  
    my %error_messages = ( 
                   stat_qtl_model    => 'QTL model parameter',
                   stat_qtl_method   => 'QTL mapping method parameter',
                   stat_prob_method  => 'QTL genotype probability method parameter',
                   stat_prob_level   => 'QTL genotype significance level parameter',
                   stat_step_size    => 'QTL genome scan size parameter',
                   stat_permu_test   => 'No. permutations parameter',
                   stat_permu_level  => 'Significance of permutation test parameter',
                   stat_no_draws     => 'No. of draws parameter',

	        );

    foreach my $k (keys (%args)) {
	my $v = $args{$k};
	unless ($v) {
	    unless (($k eq 'stat_no_draws' && $args{'stat_qtl_method'} eq 'Maximum Likelihood') || 
                    ($k eq 'stat_no_draws' && $args{'stat_qtl_method'} eq 'Haley-Knott Regression')
                   ) 
	    {
		my $error_message = $error_messages{$k};
		if ($error_message) {
		    push @messages, $error_message;
		}
	    }
	}
    }
	if ($args{'stat_qtl_method'} eq 'Multiple Imputation') {
	    if ($args{'stat_prob_method'} ne 'Simulate') {
		push @messages, "Since you selected <i><b>Multiple Imputation</i></b> as 
                                 the QTL mapping method, you need to select the 
                                 QTL genotype probablity method <i><b>Simulate</i></b> and 
                                 also set the <i><b>No. of draws (imputations)</b></i>, 
                                 if you have not"; 
	}

    }

    if (($args{'stat_qtl_method'} eq 'Maximum Likelihood' && $args{'stat_prob_method'} eq 'Simulate') ||
        ($args{'stat_qtl_method'} eq 'Haley-Knott Regression' && $args{'stat_prob_method'} eq 'Simulate')
       ) 
    {
	   
	push @messages, "Since you selected <i><b>$args{stat_qtl_method}</i></b> as 
                         the QTL mapping method, you need to select the QTL genotype 
                        probablity method <i><b>Calculate</i></b> instead of <i><b>Simulate</i></b>";
                         
	

    }

    	
return @messages;			   

}
=head2 accessors get_dbh, set_dbh

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_dbh {
  my $self = shift;
  return $self->{dbh}; 
}

sub set_dbh {
  my $self = shift;
  $self->{dbh} = shift;
}


=head2 has_qtl_data

 Usage: my @pop_objs = $qtl_tools->has_qtl_data();
 Desc: returns a list of populations (objects)  with genetic and phenotypic data (qtl data). 
       The assumption is if a trait has genetic and phenotype data, it is from a qtl study.
 Ret: an array of population objects
 Args: none
 Side Effects: accesses the database
 Example:

=cut

sub has_qtl_data {
    my $self = shift;    
    my $dbh = $self->get_dbh();
    my $query = "SELECT DISTINCT (population_id) 
                        FROM public.phenotype 
                        LEFT JOIN phenome.individual USING (individual_id)";

    my $sth = $dbh->prepare($query);
    $sth->execute();
    
    my (@pop_objs, @pop_ids)=();
    
    while (my ($pop_id) = $sth->fetchrow_array()) {
	push @pop_ids, $pop_id;
    }

    foreach my $pop_id2 (@pop_ids) {
	$self->d("phenotype population id: $pop_id2\n");

	my $query2 = "SELECT DISTINCT (population_id) 
                             FROM phenome.genotype 
                             LEFT JOIN phenome.individual USING (individual_id) 
                             WHERE individual.population_id = ?";

	my $sth2 = $dbh->prepare($query2);
	$sth2->execute($pop_id2);
	
	my ($qtl_pop_id) = $sth2->fetchrow_array();
	
	if ($qtl_pop_id) {
	$self->d("qtl population id: $qtl_pop_id\n");
	    my $pop_obj = CXGN::Phenome::Population->new($dbh, $qtl_pop_id);
	

	    push @pop_objs, $pop_obj;
	}
    }

        return  @pop_objs; 
 
    

}




=head2 all_traits_with_qtl_data

 Usage: my ($traits, trait_ids) = $qtl_tools->all_traits_with_qtl_data();
 Desc: returns a list of all traits and their ids from all qtl populations
 Ret: array refs for trait names and their ids
 Args: none
 Side Effects:
 Example:

=cut

sub all_traits_with_qtl_data {
    my $self = shift;
    my @pops = $self->has_qtl_data();
    my $dbh = $self->get_dbh();
    my (@all_traits, @all_trait_ids);
   
    
    foreach my $pop (@pops) {
	my ($table, $table_id, $name);
	my $pop_id = $pop->get_population_id();
	$self->d( "population_id: $pop_id \n");
	if ($pop->get_web_uploaded()) {
	    $table = 'phenome.user_trait';
	    $table_id  = 'user_trait_id';
	    $name = 'user_trait.name';
	} else {
	    $table = 'public.cvterm';
	    $table_id  = 'cvterm_id';
	    $name = 'cvterm.name';
	}
	if ($pop_id) {
	my $sth = $dbh->prepare("SELECT DISTINCT($name), $table_id 
                                        FROM $table
                                        LEFT JOIN public.phenotype ON ($table_id = phenotype.observable_id) 
                                        LEFT JOIN phenome.individual USING (individual_id) 
                                        WHERE population_id = ?"
                                         );

	$sth->execute($pop_id);
	while (my ($trait, $trait_id) = $sth->fetchrow_array()) {
	    $self->d( "pop id: $pop_id trait: $trait\n");
	    push @all_traits, $trait;
	    push @all_trait_ids, $trait_id;
	}
	}
    }
    return \@all_traits, \@all_trait_ids;	

}

=head2 browse_traits

 Usage: $links = $qtl_tools->browse_traits();
 Desc: returns hyperlinked alphabetical index of 
       traits with genotype and phenotype data
 Ret: 
 Args: none
 Side Effects:
 Example:

=cut

sub browse_traits {
    my $self = shift;
    my ($all_traits, $all_trait_d) = $self->all_traits_with_qtl_data();
    my @all_traits = @{$all_traits}; 
    $all_traits = uniq(@all_traits);
    @all_traits = sort{$a<=>$b} @all_traits;

    my @indices = ('A'..'Z');
    my %traits_hash = ();
	my @valid_indices=();
	foreach my $index (@indices) {
	    my @index_traits;
	    foreach my $trait (@all_traits) {
		if ($trait =~ /^$index/i) {
		   push @index_traits, $trait; 
		   
		}
		
	    }
	    if (@index_traits) {
	    $traits_hash{$index}=[ @index_traits ];
	    }
	}
           
    foreach my $k ( keys(%traits_hash)) {
	push @valid_indices, $k;
    }
    @valid_indices = sort( @valid_indices );
    
    my $links;
    foreach my $v_i (@valid_indices) {
	$links .= qq | <a href=/chado/trait_list.pl?index=$v_i>$v_i</a> |;
	unless ($v_i eq $valid_indices[-1]) {
	    $links .= " | ";
	}
	 
    }

    return $links;
}


=head2 is_from_qtl

 Usage: my $has_qtl = $qtl_tools->is_from_qtl($id);
 Desc: returns 0 or 1 depending on whether a trait has been assayed in a 
       population for genetic and phenotypic data (qtl data). 
       The assumption is if a trait has a genetic and phenotype data, 
       it is from qtl study.
 Ret: true or false
 Args: none
 Side Effects: accesses the database
 Example:

=cut

sub is_from_qtl {
    my $self = shift;
    my $id = shift;
    my $query = "SELECT DISTINCT (population_id) FROM phenome.genotype
                        LEFT JOIN phenome.individual USING (individual_id)
                        LEFT JOIN public.phenotype USING (individual_id) 
                        WHERE observable_id =?" ;
    
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($id);
    
    my @pop_ids;
    while (my ($pop_id) = $sth->fetchrow_array()) {

	push @pop_ids, $pop_id;

    }
    
    if (@pop_ids) { 
	return 1; 
    } else { return 0;
	 }
    

}

# =head2 all_pops_trait_cv

#  Usage:
#  Desc:
#  Ret:
#  Args:
#  Side Effects:
#  Example:

# =cut

# sub all_pops_trait_cv {
#     my $self = shift;
    

# }



########
return 1;
#######
