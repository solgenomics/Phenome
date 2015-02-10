package CXGN::Phenome::Qtl;

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
use warnings;

use File::stat;
use CXGN::People::Person;
use CXGN::Phenome::Population;
use File::Spec;

use File::Path qw/ mkpath /;
use File::Slurp qw / read_file /;

sub new {
    my ($class, $sp_person_id, $params_ref) = @_;
    my $self         = bless {}, $class;

    # put the right control conditions for a hash ref $params_ref
    if ($params_ref) {
        $self->set_all_parameters($params_ref);
    }

    #$self->set_user_stat_parameters($self->user_stat_parameters);

    $self->set_sp_person_id($sp_person_id);
    return $self;
}

=head2 apache_upload_file

 Usage:        my $data_file_name = $qtl->apache_upload_file($upload_object, $c);
 Desc:         writes uploaded data to a file in  user specific dir
 Ret:          the name of the data file that can be 
               used to access down the road.
 Args:         an upload object
 Side Effects: generates an data file from a request
               that can be handled more easily. 
 
 Example:

=cut

sub apache_upload_file {
    my $self   = shift;
    my $upload = shift;
    my $c      = shift;

# Adjust File name if using Windows IE - it sends whole path; drive letter, path, and filename
    my ( $data_filename, $dir );
    
    if ( $ENV{HTTP_USER_AGENT} =~ /msie/i ) 
    {
        ( $dir, $data_filename ) = $upload->filename =~ m/(.*\\)(.*)$/;
    }
    else {
        $data_filename = $upload->filename;
    }
    print STDERR "data_filename: $data_filename\n\n";
    my ( $temp_qtl, $temp_user ) = $self->create_user_qtl_dir($c);

    my $data_file = $temp_user . "/" . $data_filename;
    my $data_fh = $upload->fh;
    my $temp_file = $upload->tempname();
    
    if ( -e $data_file ) {
        unlink $data_file;
    }
 
    if (-e $temp_file ) 
    {
	open my $temp_fh, "<", $temp_file 
	    or die "Could not read to $temp_file: $!\n";
	open my $data_fh, ">", $data_file 
	    or die "Could not write to $data_file: $!\n";
	while (<$temp_fh>) 
	{
	    $data_fh->print($_);	   
	}
    }

    return $data_file;

}

sub set_all_parameters {
    my $self = shift;
    $self->{all_parameters} = shift;
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
    my $self     = shift;
    my $args_ref = $self->get_all_parameters();

    if ($args_ref) 
    {
        my %args = %$args_ref;
        my %pop_args;

        foreach my $k ( keys %args ) 
        {
            my $v = $args{$k};
            if ( $k =~ /^pop/ ) 
            {
                $pop_args{$k} = $v;
            }
        }
        return \%pop_args;
    }
    else 
    {
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
    my $self     = shift;
    my $args_ref = $self->get_all_parameters();

    if ($args_ref) {
        my %args = %$args_ref;
        my %stat_args;

        foreach my $k ( keys %args ) {
            my $v = $args{$k};

            if ( $k =~ /^stat_/ ) {
                $stat_args{$k} = $v;
            }
        }

        if (   $stat_args{stat_qtl_method} eq 'Marker Regression'
            || $stat_args{stat_step_size} eq 'zero' )
        {
            $stat_args{stat_prob_method} = "";
        }
        return \%stat_args;
    }
    else {

        return undef;
    }
}

=head2 user_stat_file

 Usage: my $stat_file = $qtl->user_stat_file($c, $pop_id)
 Desc: converts user submitted statistical parameters from a hash
       to a tab delimited file and saves it in the users qtl directory.
 Ret: an abosolute path the user submitted statistics file or undef
 Args: SGN::Context object and population id
 Side Effects:
 Example:

=cut

sub user_stat_file {
    my ($self, $c, $pop_id) = @_;
   
    my ( $temp_qtl, $temp_user ) = $self->get_user_qtl_dir($c);
    my $stat_file = "$temp_user/user_stat_pop_$pop_id.txt";

    my $stat_ref = $self->user_stat_parameters();
    if ($stat_ref) 
    {
        my $stat_table = $self->make_table($stat_ref);
        open my $f, '>', $stat_file or die "Can't create file: $! \n";
        $f->print($stat_table);
    }       
    else 
    { 
        $stat_file = undef;
    }

    return $stat_file;
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
    my $self         = shift;
    my $c            = shift;
    my %default_stat = (
        stat_qtl_method  => 'Maximum Likelihood',
        stat_qtl_model   => 'Single-QTL Scan',
        stat_prob_method => 'Calculate',
        stat_prob_level  => '0.05',
        stat_permu_test  => '1000',
        stat_permu_level => '0.05',
        stat_step_size   => '10',
    );

    my $stat_table = $self->make_table( \%default_stat );
    my ( $temp_qtl, $temp_user ) = $self->create_user_qtl_dir($c);

    my $stat_file = "$temp_user/default_stat.txt";
    open my $t, '>', $stat_file or die "$! writing $stat_file\n";
    $t->print($stat_table);

    return $stat_file;
}

=head2 default_stat_file

 Usage: my $stat_file = $qtl->get_stat_file($c, $pop_id)
 Desc: Checks if a qtl population has a submitter defined statistical
       parameters or not. If yes, it returns the submitter defined statistical
       parameter file. Otherwise, it return the default statistical file.
 Ret: an abosolute path to either statistics file
 Args: SGN::Context object and population id
 Side Effects:
 Example:

=cut

sub get_stat_file {
    my ($self, $c, $pop_id)  = @_;
    
    my ($temp_qtl, $temp_user) = $self->get_user_qtl_dir($c);
    my $user_stat_file         = "$temp_user/user_stat_pop_$pop_id.txt";
    my $stat_options           = "$temp_user/stat_options_pop_$pop_id.txt";
    
    if (-e $stat_options &&  grep(/No/, read_file($stat_options))) 
    {            
        if (-e $user_stat_file) 
        { 
            return $user_stat_file; 
        } 
        else 
        { 
            return $self->default_stat_file($c);
        }
    }
    else 
    {
        return $self->default_stat_file($c);
    }
}

=head2 make_table

 Usage: my $make_table = $qtl->make_table($param_ref)
 Desc: makes a tab delimited file out of a hash ref file.
 Ret: tab delimited file or undef
 Args: hash ref of parameters
 Side Effects:
 Example:

=cut

sub make_table {
    my $self      = shift;
    my $param_ref = shift;

    if ($param_ref) {
        my $table;
        foreach my $k ( keys %{$param_ref} ) {
            my $v = $param_ref->{$k};
            $table .= $k . "\t" . $v . "\n";
        }
        return $table;
    }
    else {
        return undef;
    }

}

sub get_user_qtl_dir {
    my ($self, $c)   = @_;        
    my $sp_person_id = $self->get_sp_person_id();

 
    my $bdir     = $c->path_to($c->config->{basepath});
    my $tdir     = $c->path_to($c->config->{tempfiles_subdir});
    my $temp_qtl = File::Spec->catfile( $bdir, $tdir, "page_uploads", "qtl" );
    my $dbh      = CXGN::DB::Connection->new();
    my $person   = CXGN::People::Person->new( $dbh, $sp_person_id );
    
    if ($person)
    {
        my $last_name  = $person->get_last_name() || '';
        my $first_name = $person->get_first_name() || '';
        $last_name     =~ s/\s//g;
        $first_name    =~ s/\s//g;
        my $temp_user  = "$temp_qtl/user_" . $first_name . $last_name;

        return $temp_qtl, $temp_user;
    } 
    else
    {
    return;
    }

}

sub create_user_qtl_dir {
    my $self         = shift;
    my $c            = shift;
    my $sp_person_id = $self->get_sp_person_id();

    if ($sp_person_id) 
    {
        my ( $temp_qtl, $temp_user ) = $self->get_user_qtl_dir($c);
        mkpath ( [ $temp_qtl, $temp_user ], 0, 0755 );
        
        return $temp_qtl, $temp_user;
    }
    else 
    {
        die "Can't create qtl dir for a user not logged in";
    }
}

1;
