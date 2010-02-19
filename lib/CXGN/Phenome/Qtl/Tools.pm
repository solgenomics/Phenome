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
use CXGN::DB::Connection;

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
                   pop_female_parent => 'Female parent'
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


########
return 1;
#######
