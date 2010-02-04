
=head1 NAME

update_sgn_loci.pl

=head1 DESCRIPTION

Usage: perl update_sgn_loci.pl -H [dbhost] -D [dbname] -o [organism] -u [sp_person] [-vtc] -i file


parameters

=over 10

=item -H

hostname for database [required]

=item -D

database name [required]

=item -i 

input file [required]

=item -v

verbose output

=item -u 

sp_person user name 

=item -p

sp_person_id - your database id (sgn_people.sp_person)
Each locus has an owner.

=item -o 

organism name

=item -c 

check mode. Check infile for duplicate locus names and synonyms. Do not insert anything

=item -y

update all loci in the database. Names, symbols, and activity fields in the file will replace those in the database.
It is highly recommneded to run with this option only after running check mode (-c) and looking at the error file.
 
=item -t

trial mode. Don't perform any store operations at all.

 
=back

The script parses a custom locus data file (see internal site: LocusFileHelp)
inserts new loci and  updates existing ones. Synonyms, GenBank accessions, and PubMed Ids are linked with each locus 
whenever available.   

This script works with SGN's phenome schema and accesse the following tables:

=over 6

=item locus 

=item locus_owner

=item locus_alias

=item locus_marker

=item locus_dbxref

=item dbxref


=back

The following data are associated with each locus insert/update:

=over 8

=item locus name

=item locus symbol

=item gene activity

=item Synonyms

=item linkage_group

=item common_name_id

=item locus_alias.alias

=item locus_dxref

=back 


=head1 AUTHOR

Naama Menda <nm249@cornell.edu>


=head1 VERSION AND DATE

Version 1.0, March 2008.

=cut

#! /usr/bin/perl
use strict;

use CXGN::DB::InsertDBH;

use CXGN::Phenome::Locus;
use CXGN::Phenome::LocusSynonym;

use CXGN::Chado::Feature;
use CXGN::Chado::Dbxref;
use CXGN::Chado::Publication;
use CXGN::Chado::Organism;

use CXGN::Tools::FeatureFetch;
use CXGN::Tools::FeatureTree;

use CXGN::Tools::Pubmed;
use CXGN::People::Person;

use Getopt::Std;

########################################
#Add : chromosome check
#publication check!
#Check if update handles chromosome number, activity, etc...
#
#########################################


our ($opt_H, $opt_D, $opt_v, $opt_u, $opt_o, $opt_t, $opt_x, $opt_i, $opt_c, $opt_y, $opt_p);

getopts('H:D:i:p:txu:ycvo:');

my $dbhost = $opt_H;
my $dbname = $opt_D;
my $organism=$opt_o;
my $infile = $opt_i;
my $sp_person=$opt_u;
my $sp_person_id = $opt_p || "329";

my $help;


if (!$organism || !$infile) {
    $help= 1;
    print STDERR "\n You must provide an organism name and and infile!\n";
}

if (!$dbhost && !$dbname) { 
    $help=1;
    print  STDERR "Need -D dbname and -H hostname arguments.\n"; 
}

if($help){

print STDERR <<EOT;
    Script for updating existing sgn loci and insertning new ones based on the output of 
    sgn-tools/util/update_parce_acefile.pl 
    
  Usage: update_sgn_loci.pl  -o [organism name] -i [infile] -u [sgn user name] -D [dbname] -H [dbhost] [-txvc]
  
 Options:

-o   set SGN organism name
-i   infile
-u   set SGN user name

-D  set database name (cxgn or sandbox)
-H  set dbhost name

EOT
exit;

}
if ($opt_t) { 
    print STDERR "Trial mode - rolling back all changes at the end.\n";
}

if ($opt_y) {  message ("Update mode - existing locus information will be updated from file '$infile'.\n", 1);}
else { message ("'-y' option not specified. Existing locus information will not be updated.\n",1) ;}

if ($opt_c) {  print STDERR "Running  check mode - checking locus names and symbols in file...\n";}
else { 
    print STDERR "*Did you run check mode (-c) first? ...['n' to exit, any other key to continue]*  " ;
    use Term::ReadKey;
    my $r = ReadLine(0);
    chomp $r;
    print STDERR "\n"; 
    exit() if ($r eq 'n');
} 


my $dbh = CXGN::DB::InsertDBH->new( { dbhost=>$dbhost,
				      dbname=>$dbname,
                                      dbschema => 'phenome', 
                                   } );

$dbh->add_search_path(qw/public utils tsearch2 phenome /);

print STDERR "Connected to database $dbname on host $dbhost.\n";

if ($opt_u) {  $sp_person_id= CXGN::People::Person->get_person_by_username($dbh, $sp_person) };

if (!$sp_person_id) {
    print STDERR "ERROR: Invalid SGN username in option -u : \"$sp_person\"!! \n";
    exit;
}


my $organism_sth=$dbh->prepare("SELECT common_name_id FROM sgn.common_name WHERE common_name ilike ?");
$organism_sth->execute($organism);
my ($organism_id)= $organism_sth->fetchrow_array();

if (!$organism_id) {
    
    print STDERR "ERROR: Invalid SGN organism common name \"$organism\"!! \n";
    exit;
} else { print STDERR "$organism=$organism_id\n"; }


my %db_names = (); #hash for retrieving existing locus ids and names 
my %db_symbols=();
my %db_loci;
my $loci_query = "SELECT locus_id, locus_name, locus_symbol, gene_activity FROM phenome.locus where common_name_id=? AND obsolete = 'f'";
my $sth = $dbh->prepare($loci_query);
$sth->execute($organism_id);
while (my ($id, $locus_name, $locus_symbol, $activity) = $sth->fetchrow_array()){ 
    $db_names{lc($locus_name)} = $id; 
    $db_symbols{lc($locus_symbol)} =$id;
    $db_loci{$id} = [$locus_name, $locus_symbol, $activity]; 
}

############################
#query for finding the marker ID according to marker name
my $marker_query= $dbh->prepare ("SELECT marker_id from sgn.marker_alias where alias ilike ?");
###

open (INFILE, "<$infile") || die "can't open file";   #parse_potato_genes.txt
open (ERR, ">$infile.err") || die "Can't open the error ($infile.err) file for writing.\n";

my %file_names=();
my %file_symbols=();
my %file_accessions=();
my @file_loci;
my ($locus_count,$alias_count, $allele_count, $marker_count, $locus_dbxref_count, $dbxref_count)= (0,0,0,0,0,0);

eval {
    #skip the first header line
    <INFILE>;
    my %new_locus=(); #hash of arrays for the locus info
    my $file_count=0;
    my $line_number=1;
    my $prev_line=0;
    my $insert_locus;
    my $prev_entry;
    my $prev_accession;
    
    while (my $line = <INFILE>) {
	$line_number++;
	$prev_line++;
	my $locus_obj=undef;
	chomp $line;
  	my @fields = split "\t", $line;
	
	#the first field indicate if this line is a part of a contig, or a singlet
	my $new_entry = $fields[0];
	
	#do not  need this now...
	my $gi = $fields[1];       #the gis should be in public.dbxref.accession
	
	###the accession should be used for fetching the sequence from ncbi,
	#storing in dbxref, feature, feature_dbxref, and phenome.locus_dbxref
	#the accessions should already be stored in public.feature.name (see sgn-tools/chado/gmod_bulk_load_gb.pl) 
        my $accession = $fields[2]; 
	my $locus_name= sanitize($fields[4]);
	if ($new_entry && ($locus_name =~ m/^x$/i)) { 
            #message("skipping $new_entry ($accession)", 1);  
            next();  #skipping loci marked with 'x' locus name
	}
	my $locus_symbol= sanitize($fields[5]); 
	my $activity= sanitize($fields[6]);

	my $aliases= $fields[7]; #need to split this line by '|' and filter for uniques
	my @alias = split '\|', $aliases;
	
	#pubmeds should be fetched from genbank and stored in 
	#dbxref, pub, pubauthor, pubabstract, pub_dbxref, phenome.locus_dbxref
	my $pubmed = $fields[11]; #split by '|' and filter
	my @pubmed_ids = split '\|', $pubmed;

	my $chromosome = $fields[12];
        my $locus_id= $fields[14];
	my $marker = $fields[15];
	my $allele = $fields[16];
	my $comments= sanitize($fields[17]);
	
        #if ($locus_name || $locus_symbol) {##########################################################
	
        my $exists; 
	
        # check if locus name seen before in the file for another entry:
	
	
       	if ($new_entry) { $file_count++ ; } #print STDERR "$count_lines, $new_entry: $locus_name\n"; }
        if ($new_entry && ($file_count>1) ) { $insert_locus='t' ; } 
        else { $insert_locus=undef ; }  
        
        #check if the accession was seen before in the file for another entry:
        if (exists $file_accessions{$accession} ) {
           if (!grep {/$accession/i } @{ $new_locus{gb_acc} } ) {
               print STDERR "Accession '$accession' (see line $line_number) already exists !  please correct your input file\n";
               print ERR "Accession '$accession' (see line $line_number) already exists !  please correct your input file\n";
           }
       }elsif ($locus_name ne 'x')  { $file_accessions{$accession} = $new_locus{locus_name}[0] };
	
#############	
#####################################################
	if ( $file_count>1 && $insert_locus ) {
	       my $update;
	       if (!$new_locus{locus_name} || !$new_locus{locus_symbol} ) {
                   message( "Must provide a locus name and a locus symbol!! (See line $prev_line $new_entry $prev_accession)\n",1);
	       }else { 
                   push @file_loci, [$locus_name, $locus_symbol];
		   if ($locus_id && ($locus_name ne $db_loci{$locus_id}[0]) ) {
                       message ("*Warning: the name for locus_id $locus_id (" . $db_loci{$locus_id}[0] .") will be updated to $locus_name! \n", 1);
		       $update=1;
                   } 
                   if ($locus_id && ($locus_symbol ne $db_loci{$locus_id}[1]) ) { 
		       message ("*Warning: the symbol for locus_id $locus_id (" . $db_loci{$locus_id}[1] .") will be updated to $locus_symbol! \n", 1);
		       $update=1;
		   } 
		   if ($locus_id && $activity && ($activity ne $db_loci{$locus_id}[2]) ) { 
                      message ("*Warning: the gene activity for locus_id $locus_id (" . $db_loci{$locus_id}[2] .") will be updated to $activity! \n", 1);
		      $update=1;
		  }
               }
	       if (defined ($new_locus{locus_id})) {
		   my %lid_hash = map { $_ => 1 } @{ $new_locus{locus_id} };
		   my @u_locus_ids = sort keys %lid_hash;
		   if ( scalar( @u_locus_ids ) >1) {  print ERR "**Multiple db loci are in one file contig!(see $prev_entry) Please correct your input file\n"  ; }}
	       if (defined($new_locus{locus_symbol} ) ) { if ( scalar( @{ $new_locus{locus_symbol} } ) >1) { 
		   print ERR "**Multiple locus symbols exists for one file contig (see $prev_entry)! Please correct your input file\n";}}
	       if (defined ($new_locus{locus_name})) { if ( scalar( @{ $new_locus{locus_name} } ) >1) { 
		   print ERR "**Multiple locus names exists for one file contig (see $prev_entry)! Please correct your input file\n"; }}
	       
	       ####
	       $prev_entry = $new_entry;
	       $prev_accession = $accession;
	       ####
	       
	       if (!$opt_c) {
		   print STDERR "inserting new locus data from file...(locus name: $new_locus{locus_name}[0]) \n";   
		   message("**inserting new locus data from file...(locus name: $new_locus{locus_name}[0]) \n");   

		   #new locus object..
		   my $locus_id=undef;
		   if (defined($new_locus{locus_id}) ) { 
		       $locus_id = $new_locus{locus_id}[0];  
		       print STDERR "found locus_id $locus_id for symbol ". $new_locus{locus_symbol}[0] . "!!\n";
		   } 
		   ########## this option was used for updating existing loci based on symbol. Not recommended unless 
		   ######### there's a real need (i.e. loci were already inserted into db without related sequences.) 
		   #else {
		   #    my $locus_exists = CXGN::Phenome::Locus->new_with_symbol_and_species($dbh, $new_locus{locus_symbol}[0],$organism);
		   #    $locus_id= $locus_exists->get_locus_id() || undef;
		   #}
		   #########
		   $locus_obj=CXGN::Phenome::Locus->new($dbh, $locus_id);
		   if ( ($opt_y && $update) || (!$locus_id) ) { # Update if the locus exists and -y option or if the file-locus is new 
		       #setting all available values for this locus
		       $locus_obj->set_locus_name($new_locus{locus_name}[0]);
		       $locus_obj->set_locus_symbol($new_locus{locus_symbol}[0]);
		       $locus_obj->set_gene_activity($new_locus{activity}[0]) if $new_locus{activity}[0] ;
 		       $locus_obj->set_linkage_group($new_locus{linkage_group}[0]) if $new_locus{linkage_group}[0];
		       ######
		       message ("the linkage group is " . $new_locus{linkage_group}[0]  . " make sure this does not override database input!! \n");
		       ########
		       $locus_obj->set_common_name_id($organism_id);
		       $locus_obj->set_sp_person_id($sp_person_id);
		       
		       #storing the locus returns the new locus_id
		       #this should also store the 'prefered' locus_alias and a default 'dummy' allele. See Locum.pm..
		       $locus_id= $locus_obj->store();
		       message ("inserting/updating locus $locus_id: $new_locus{locus_name}[0], $new_locus{locus_symbol}[0], $new_locus{activity}[0], $organism_id, $new_locus{linkage_group}[0] \n",1);
		       $locus_count++;
		       #$locus_obj->add_locus_pub_rank();
		   }
		   
		   ##########
		   my %alias_hash = map { $_ => 1 } @{ $new_locus{alias} };
		   my @uniq_alias = sort keys %alias_hash;
		   foreach my $ua(@uniq_alias) {
		       unless ($ua eq  $new_locus{locus_symbol}[0]) {
			   message ("Adding alias for locus '$new_locus{locus_symbol}[0]' (id=$locus_id): $ua\n",1); 
			   #this should insert the new alias into locus_alias..
			   $locus_obj->add_locus_alias($ua, $sp_person_id);
			   $alias_count++;
		       }
		   }
		   
		   if ($new_locus{allele}[0]) {
		       my $allele_obj= CXGN::Phenome::Allele->new($dbh);
		       $allele_obj->set_allele_symbol($new_locus{allele}[0]);
		       $locus_obj->add_allele($allele_obj);
		       $allele_count++;
		       message ("Adding allele '$new_locus{allele}[0]' to locus '$new_locus{locus_symbol}[0]' (id=$locus_id)\n",1); 
		   }
		   for my $i ( 0 .. $#{ $new_locus{marker} } ) {
		       #print "inserting marker $new_locus{locus_symbol}[0]: $new_locus{marker}[$i]\n"; 
		       my $marker_id=$marker_query->execute($new_locus{marker}[$i]);
		       my $locus_marker_obj = CXGN::Phenome::LocusMarker->new($dbh);
		       $locus_marker_obj->set_marker_id($marker_id);
		       $locus_obj->add_locus_marker($locus_marker_obj);
		       $marker_count++;
		       message ("Adding marker '$new_locus{marker}[$i]' to locus '$new_locus{locus_symbol}[0]' (id=$locus_id)\n",1); 
		   }
		   
		   my %gb_hash = map { $_ => 1 } @{ $new_locus{gb_acc} };
		   my @uniq_gb = sort keys %gb_hash;
		   
		 FEATURE: foreach my $ugb(@uniq_gb) {
		       
		       print ERR "inserting GB accession '$new_locus{locus_symbol}[0]' (id= $locus_id): $ugb\n"; 
		       
		       my $feature=CXGN::Chado::Feature->new_with_name($dbh, $ugb);
		       #my $feature_id= $feature_obj->feature_exists();
		       #print STDERR "feature_id= $feature_id\n";
		       my $feature_id= $feature->get_feature_id();
		       if (!$feature_id) { 	#fetch the feature from genbank:
			   print STDERR "No feature_id! storing a new one!!";
			   $feature->set_name($ugb);
			   my $db_name = 'DB:GenBank_GI';
			   $feature->set_db_name($db_name);
			   ##############################################
			   #CXGN::Tools::FeatureFetch->new($feature_obj);
			   #my $name=$feature_obj->get_name();
			   #my $uname= $feature_obj->get_uniquename();
			   #print STDERR "update_sgn_loci: name = $name uname= $uname\n\n";
			   #my $mol_type= $feature_obj->get_molecule_type();
			   #if (!$mol_type) { 
			   #    $feature_obj->set_molecule_type('DNA') ;
			       #this default value has to be resolved in a better way 
			       #need to check XML from NCBI to see when no molecule type is specified
			   #}
			   #this gives the feature a dbxref id, and stores it in feature, and featre_dbxref
			   ###########$feature_obj->store();
			   
			   my $ft= CXGN::Tools::FeatureTree->new($ugb);
			   my @ftree=$ft->get_feature_list();
			   my $j= -1 ;
			   for my $i (0 ..$#{$ftree[2]} ) {
			       $j=$i;
			       message("found in file " . $ftree[2][$i] . " user acc=" . $ugb, 1);
			       last() if ($ftree[2][$i] eq $ugb)  ; 
			   }
			   message("$ugb matches element '# $j in XML tree ($ftree[2][$j], $ftree[3][$j] )", 1);
			   
			   my $org_pos = $j;
			   if ($j>1) {
			       $org_pos=$j/2;
			       message("organism position = $org_pos. int() position = " . int($org_pos) , 1);
			       $org_pos = $j if $org_pos != int ($j/2);
			   }
			   message("##position of accession $ugb is $j. Organism position is $org_pos!",1);
			   my $o_name= $ftree[0][$org_pos] || $ftree[0][0]; # see AF161095 for multiple organisms in 1 XML
			   $feature->set_organism_name($o_name); 
			   my $taxon_id= $ftree[1][$org_pos] || $ftree[1][0];
			   $feature->set_organism_taxon_id($taxon_id); 
			  
			   $feature->set_accession($ftree[3][$j]);
			   $feature->set_uniquename($ugb . "." . $ftree[5][$j] );
			   $feature->set_accession($ftree[3][$j]);
			   $feature->set_version($ftree[5][$j]);
			   my $res= $ftree[6][$j] || $ftree[6][0];
			   $feature->set_residues($res); 
			   $feature->set_seqlen($ftree[7][$j]); 
			   $feature->set_description($ftree[8][$j]);
			   my $mol_type= $ftree[9][$j];
			   if ($mol_type) {
			       $feature->set_molecule_type($mol_type);
			   }else { 
			       $feature->set_molecule_type('DNA'); #default just to keep te program form crashing..
			       message("No molecule type found! check the XML for $ugb " . @{$ftree[9]} , 1);
			   }
			   for my $pubmed_id (0 .. $#{$ftree[4] } ) {
			       $feature->add_pubmed_id($pubmed_id);
			   }
			  
			   for my $i ( 0 .. $#ftree  ) {
			       for my $j (0 .. $#{$ftree[$i]} ) {
				   message("Found from feature tree $i $j: '". $ftree[$i][$j] ."' ", 1) ;
			       }
			   }
			   # This is a bit tricky. The organism names in the XML don't always match the corresponding 
			   # location of the accession (see DQ069270 and DQ069271) 
			   #so it's a good idea to double check here if the
			   #organism from the XML exists in the db. If it does not exist this program will skip the 
			   #accession and generate a warning to add it manually somehow. Not the best solution
			   # but I can't figure out why these XML files are messed up when have multiple organisms.
			   # This is all because GenBank insist on dumping XML with ALL the sequences submitted from
			   # one 'project' , which is defined solely by the submitter. An annoying feature wich makes
			   # parsing correctly 100% of times nearly impossible! Entrez has a 'miniXML' format, containing
			   #only the 1 accession from the user query, but it's not available for Eutils, only in the web 
			   # interface <great!>
			   my $organism= CXGN::Chado::Organism->new_with_taxon_id($dbh, $taxon_id);
			   if  (!$organism->get_organism_id()) {
			       message("*AN ERROR OCCURED. organism $o_name (taxon id = $taxon_id) not found in dh! Skipping to the next feature. Accession $ugb is not stored. Please check your input and add manually if needed\n",1);
			       next FEATURE;
			   }
			   #this gives the feature a dbxref id, and stores it in feature, and featre_dbxref
			   $feature->store();
		       }


		       my $dbxref_id = $feature->get_dbxref_id() || undef ;
		       #make a locus_dbxref connection:
		       my $dbxref_obj=CXGN::Chado::Dbxref->new($dbh, $dbxref_id);
		       $locus_obj->add_locus_dbxref($dbxref_obj,undef, $sp_person_id);
		       
		       if ($dbxref_id) { $locus_dbxref_count++; } 
		       else { 
			   message("Warning: no dbxref found for accession $ugb!! Transaction will be rolled-back", 1);
			   $opt_t=1;
		       }
		   }
		   my %pubmed_hash = map { $_ => 1 } @{ $new_locus{pubmed} };
		   my @uniq_pubmed = sort keys %pubmed_hash;
		   foreach my $pmid(@uniq_pubmed) {
		       print ERR "Adding publication '$pmid' to locus '$new_locus{locus_symbol}[0]' (id = $locus_id\n"; 
		       
		       my $publication = CXGN::Chado::Publication->new($dbh);
		       $publication->set_accession($pmid);
		       $publication->add_dbxref('PMID:$pmid');
		       my $existing_publication = $publication->get_pub_by_accession($dbh, $pmid);
		       if ($pmid) {
			   if(!($existing_publication)) { #publication does not exist in our database
			       my $message= CXGN::Tools::Pubmed->new($publication);
			       if ($message) { message($message,1); }
			       print STDERR "storing publication now. pubmed id = $pmid\n";
			       my $pub_id = $publication->store();
			       $dbxref_count++;
			       my $publication_dbxref_id = $publication->get_dbxref_id_by_db('PMID');
			       my $publication_dbxref= CXGN::Chado::Dbxref->new($dbh, $publication_dbxref_id);
			       $locus_obj->add_locus_dbxref($publication_dbxref, undef, $sp_person_id);	
			       
			   }else { #publication exists but is not associated with the object
			       print STDERR "***the publication $pmid exists but is not associated.\n";
			       $publication=CXGN::Chado::Publication->new($dbh, $existing_publication->get_pub_id());
			       if (!($publication->is_associated_publication($locus_obj, $locus_id))) {
				   my $publication_dbxref_id= $publication->get_dbxref_id_by_db('PMID');
				   my $publication_dbxref= CXGN::Chado::Dbxref->new($dbh, $publication_dbxref_id);
				   
				   my $associated_feature = $locus_obj->get_locus_dbxref($publication_dbxref)->get_locus_dbxref_id();
				   my $obsolete = $locus_obj->get_locus_dbxref($publication_dbxref)->get_obsolete();
				   
				   if ($publication_dbxref_id ) {
				       $locus_obj->add_locus_dbxref($publication_dbxref, $associated_feature, $sp_person_id);
				   }
				   $locus_dbxref_count++;
			       }
			   }
		       }
		   }
	       }
	       %new_locus = (); #reset the file locus HoA  
	   }
######################
	
	# grep { $_ =~ /^foo$/i } @array
####################### 
	if ($opt_c && $insert_locus) { %new_locus = () ; }  
	
	if ($insert_locus && $opt_c) { %new_locus=() } ; #after inserting new locus reset the hash in 'check' mode
        if ($locus_name && ($locus_name ne 'x') ) {
	    if (!grep { $_=~ /^$locus_name$/i } @{ $new_locus{locus_name} } ) {
                push @{ $new_locus{locus_name} }, $locus_name; 
                if (exists $file_names{lc($locus_name)} ) { 
		    message("locus name '$locus_name' (symbol '$locus_symbol') already exists (see line $line_number)! \n", 1);
                } else {  $file_names{(lc($locus_name))} = $locus_id; } 
            #check if locus name seen in db for another locus id:   
                if ($db_names{lc($locus_name)} && $file_names{lc($locus_name)} != $db_names{lc($locus_name)} ) {
		    message("locus name '$locus_name' (symbol $locus_symbol) already exists in database for locus_id $db_names{$locus_name}! (see line $line_number)\n", 1);
		}
            }
	}
        if ($locus_symbol && $locus_name ne 'x') {
            if ((!grep{/$locus_symbol/i } @{ $new_locus{locus_symbol} } ) ) { 
                push @{ $new_locus{locus_symbol} }, $locus_symbol; 
                #check if locus symbol seen before in the file for another entry:
                if (exists $file_symbols{lc($locus_symbol)} ) { 
                    message("locus symbol '$locus_symbol' (see line $line_number: name '$locus_name') already exists !\n", 1);
                }else { $file_symbols{lc(($locus_symbol))} = $locus_id };
                #check if locus symbol seen in db for another locus id:   
                if ($db_symbols{lc($locus_symbol)} && $file_symbols{lc($locus_symbol)} != $db_symbols{lc($locus_symbol)} ) {
                    message ("locus symbol '$locus_symbol' (see line $line_number: name '$locus_name') already exists in database for locus_id $db_symbols{$locus_symbol}! \n", 1);
                }
            }
        }
	
        if ($locus_id) {   push @{ $new_locus{locus_id} }, $locus_id;  }
	
	push @{ $new_locus{gb_acc} }, $accession  if $locus_name ne 'x'; #the constraint allows ignoring unwanted associated sequences. e.g a contig includes genbank record 'clone xyz' 
	
        push @{ $new_locus{gis} }, $gi;
	push @{ $new_locus{activity} }, $activity;
	
	push @{ $new_locus{alias} }, @alias; 
	
	
	foreach my $pid(@pubmed_ids) {
	    if ((!grep{/$pid/ } @{ $new_locus{pubmed} } )) {
		push @{ $new_locus{pubmed} }, $pid; 
	    }
	}
	
	push @{ $new_locus{linkage_group} }, $chromosome; #there should be only one chromosome num per locus
	if ($marker) {push @{ $new_locus{marker} }, $marker; }
	push @{ $new_locus{allele} }, $allele;
	push @{ $new_locus{locus_notes} }, $comments;
    }
};   

if($@) {
    print $@;
    print"Failed; rolling back.\n";
    $dbh->rollback();
}else{ 
    print"Succeeded.\n";
    print "Inserted $locus_count new $organism loci, $alias_count locus aliases\n";
    print "$allele_count alleles, $marker_count markers, $locus_dbxref_count locus-dbxref associations\n";
    print "**$dbxref_count new pubmed IDs where inserted into public.dbxref**\n";
    if($opt_t) {
        print STDERR "Rolling back!\n";
        $dbh->rollback();
    }elsif (!$opt_c) {
        print STDERR "Committing...\n";
        $dbh->commit();
    }
}
if ($opt_c)  { print STDERR "Check mode done. Please check $infile.err file for output\n" } ; 

close ERR;
close INFILE;


sub message {
    my $message=shift;
    my $err=shift;
    if ($opt_v) {
	print STDERR $message. "\n";
    }
    print ERR "$message \n" if $err;
}



sub sanitize {
    my $string = shift;
    $string =~ s/^\s+//; #remove leading spaces
    $string =~ s/\s+$//; #remove trailing spaces
    if ($string =~ m/^x$/i) { $string = 'x' } ;
    return $string;
}
