=head1 NAME
CXGN::Phenome::Qtl 

=head1 DESCRIPTION
processes user submitted QTL data: phenotype and genotype data uploading 
and statistical parameters setting. Creates user subdirectories where raw 
data files are stored before loading the data to the database. 
Validation functions in development...

=head1 AUTHOR

Isaak Y Tecle (iyt2@cornell.edu)

=cut

use strict;


package CXGN::Phenome::Qtl;

use File::stat;
#use CXGN::Tools::Text qw | sanitize_string |;
use CXGN::People::Person;
use CXGN::Phenome::Population;
use File::Spec;
use SGN::Context;




sub new {
    my $class = shift; 
    my $sp_person_id = shift;
    my $params_ref = shift;
    my $self = bless {}, $class; 
    # put the right control conditions for a hash ref $params_ref
    if ($params_ref) {
	$self->set_all_parameters($params_ref);
    }
    #$self->set_user_stat_parameters($self->user_stat_parameters);
 
    $self->set_sp_person_id($sp_person_id);
    return $self;
}



=head2 apache_upload_file

 Usage:        my $temp_file_name = $image->apache_upload_file($apache_upload_object, $c);
 Desc:
 Ret:          the name of the intermediate tempfile that can be 
               used to access down the road.
 Args:         an apache upload object
 Side Effects: generates an intermediate temp file from an apache request
               that can be handled more easily. 
 
 Example:

=cut



sub apache_upload_file { 
    my $self = shift;
    my $upload = shift;
    my $c = shift;
    
    # Adjust File name if using Windows IE - it sends whole path; drive letter, path, and filename
    my ($upload_filename, $dir);
    if  ( $ENV{HTTP_USER_AGENT} =~ /msie/i ) {	
	($dir, $upload_filename) =   $upload->filename =~ m/(.*\\)(.*)$/;	
    
    }
    else {
	$upload_filename = $upload->filename;
     }
    
    
    my ($temp_qtl, $temp_user) = $self->create_user_qtl_dir($c);
    
    my $temp_file = $temp_user . "/".$upload_filename;      
    my $upload_fh = $upload->fh;

   
    if (-e $temp_file) { 
	 # #die "The file $temp_file already exists. You cannot upload a file more than once\n";
	unlink $temp_file;  
 }

    print STDERR "Uploading file to location: $temp_file\n";
    
    open UPLOADFILE, ">$temp_file" or die "Could not write to $temp_file: $!\n";
    
    #warn "could open filename $temp_filename...\n";
    binmode UPLOADFILE;
    while (<$upload_fh>) {
	#warn "Read another chunk...\n";
	print UPLOADFILE;
    }
    close UPLOADFILE;
    warn "Done uploading.\n";


    return $temp_file;

}


sub set_all_parameters {
    my $self = shift;
    $self->{all_parameters}=shift;
}

sub get_all_parameters {
    my $self = shift;
    return $self->{all_parameters};
}


sub set_sp_person_id {
    my $self = shift;
    $self->{sp_person_id} = shift;
}

sub get_sp_person_id {
    my $self = shift;
    return $self->{sp_person_id};
}


=head2 accessors get_population_id, set_population_id

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut


sub get_population_id {
  my $self = shift;
  return $self->{population_id}; 
}

sub set_population_id {
  my $self = shift;
  $self->{population_id} = shift;
}

=head2 user_pop_details

 Usage: my $pop_details = $qtl->user_pop_details()
 Desc: filters out the population related parameters and values from 
       the web form and creates a hash holder
 Ret: a hash ref (with data types (as the keys) and their values)  or undef
 Args: None
 Side Effects:
 Example:

=cut



sub user_pop_details {
    my $self = shift;
    my $args_ref = $self->get_all_parameters();
    
    if ($args_ref) {
	my %args = %$args_ref;

	my %pop_args;
    
	foreach my $k (keys %args) {
	    my $v = $args{$k};	

	    if ($k =~/^pop/) {
		$pop_args{$k}=$v;
	    }
    
	}     

	return \%pop_args;	    
    }
    else { 
	return undef;
    }
}

=head2 user_stat_parameters

 Usage: my $pop_details = $qtl->user_stat_parameters()
 Desc: filters out the statistics related parameters and values from 
       the web form and creates a hash holder
 Ret: a hash ref (with statistical parameter types 
      (as the keys) and their values)  or undef
 Args: None
 Side Effects:
 Example:

=cut

sub user_stat_parameters {
    my $self = shift;
    my $args_ref = $self->get_all_parameters();
   
    if ($args_ref) {
	my %args = %$args_ref;
	my %stat_args;
    
	foreach my $k (keys %args) {
	    my $v = $args{$k};	
	
	    if ($k =~/^stat_/) {
		$stat_args{$k}=$v;
	    }
	}    
    
	return \%stat_args;	
    } else {   

	return undef;
    }
}

=head2 user_stat_file

 Usage: my $stat_file = $qtl->user_stat_file($c)
 Desc: converts user submitted statistical parameters from a hash
       to a tab delimited file and saves it in the users qtl directory.
 Ret: an abosolute path the user submitted statistics file or undef
 Args: None
 Side Effects:
 Example:

=cut

sub user_stat_file {
    my $self = shift;
    my $c = shift;
    my $pop_id = $self->get_population_id();
    my $stat_ref = $self->user_stat_parameters();
 
    if ($stat_ref) {
	my ($temp_qtl, $temp_user) = $self->get_user_qtl_dir($c);

	my $stat_file = "$temp_user/user_stat_pop_$pop_id.txt";
	my $stat_table = $self->make_table($stat_ref);
       
   
	open TXTFILE, ">$stat_file" or die "Can't create file: $! \n";
	print TXTFILE $stat_table;
	close TXTFILE;
	print STDERR "created the statistics text file";

	return $stat_file;
    } else { 
	return undef;
    }
}

=head2 default_stat_file

 Usage: my $default_file = $qtl->default_stat_file($c)
 Desc: creates a default statistical parameters for the qtl analysis
       saves it in the users qtl directory. Useful when there is a qtl 
       population in the db to which the submitter has not set statistical
       parameters.
 Ret: an abosolute path the default statistics file
 Args: SGN::Context object
 Side Effects:
 Example:

=cut

sub default_stat_file {
    my $self = shift;
    my $c = shift;
    my %default_stat = ( 
	           stat_qtl_method  => 'Maximum Likelihood',
	           stat_qtl_model   => 'Single-QTL Scan',
	           stat_prob_method => 'Calculate',
	           stat_prob_level  => '0.05',
	           stat_permu_test  => '1000',
	           stat_permu_level => '0.05', 	          
	           stat_step_size   => '10',	          
	        );
 
   
    my $stat_table = $self->make_table(\%default_stat);
    my ($temp_qtl, $temp_user) = $self->create_user_qtl_dir($c);

    
    my $stat_file = "$temp_user/default_stat.txt";
    open TXTFILE, ">$stat_file" or die "Can't create file: $! \n";
    print TXTFILE $stat_table;
    close TXTFILE;
   
   
    return $stat_file;
}

=head2 default_stat_file

 Usage: my $stat_file = $qtl->get_stat_file($c)
 Desc: Checks if a qtl population has a submitter defined statistical
       parameters or not. If yes, it returns the submitter defined statistical
       parameter file. Otherwise, it return the default statistical file.
 Ret: an abosolute path to either statistics file
 Args: SGN::Context object
 Side Effects:
 Example:

=cut

sub get_stat_file {
    my $self = shift;
    my $c = shift;
    my $pop_id = $self->get_population_id();
    my $user_stat = $self->user_stat_file($c);
    
    if (-e $user_stat) {
	return $user_stat;
    }
    else {
	my $default_stat = $self->default_stat_file($c);
	return $default_stat;
    }

}

=head2 make_table

 Usage: my $make_table = $qtl->make_table()
 Desc: makes a tab delimited file out of a hash file.
 Ret: tab delimited file or undef
 Args: None
 Side Effects:
 Example:

=cut

sub make_table {    
    my $self =shift;
    my $param_ref = shift;
    
    if ($param_ref) {
	my %parameters = %$param_ref;
    
	my $table;
	foreach my $k (keys %parameters) {
	    my $v = $parameters{$k};
	    $table .= $k . "\t" . $v ."\n";
	}    
    
	return $table;
    } else {
	return undef; 
    }
        
}




sub get_user_qtl_dir {
    my $self = shift;
    my $vh = shift;
    my $sp_person_id = $self->get_sp_person_id();
    
    #my $vh = SGN::Context->new();
    my $bdir = $vh->get_conf("basepath");
    my $tdir = $vh->get_conf("tempfiles_subdir");    
    my $temp = File::Spec->catfile($bdir, $tdir, "page_uploads");    
    
    my $temp_qtl = "$temp/qtl";
    
    my $dbh = CXGN::DB::Connection->new();
    my $person = CXGN::People::Person->new($dbh, $sp_person_id);
    my $last_name = $person->get_last_name();
    my $first_name = $person->get_first_name();
    $last_name =~ s/\s//g;
    $first_name =~ s/\s//g;
    my $temp_user = "$temp_qtl/user_" . $first_name . $last_name;
    
    return $temp_qtl, $temp_user;
   
    
}


sub create_user_qtl_dir {
    my $self = shift;
    my $c = shift;
    my $sp_person_id = $self->get_sp_person_id();
   
    my ($temp_qtl, $temp_user) = $self->get_user_qtl_dir($c);
   
    if ($sp_person_id) {
	unless (-d $temp_qtl) {    
	    mkdir ($temp_qtl, 0755);
	} 
    
	unless (-d $temp_user) {    
	    mkdir ($temp_user, 0755);	    
	}  
	
	return $temp_qtl, $temp_user;  

    } 
     else { 
	return 0;
     }
       
   
}










#####
return 1;
#####



