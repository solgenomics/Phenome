use strict;

####################

package CXGN::Phenome;
use base qw/CXGN::Search::DBI::Simple CXGN::Search::WWWSearch/;

__PACKAGE__->creates_result('CXGN::Phenome::Result');
__PACKAGE__->uses_query('CXGN::Phenome::Query');

#####################

package CXGN::Phenome::Result;
use base qw/CXGN::Search::BasicResult/;

#####################

package CXGN::Phenome::Query;
use CXGN::Page::FormattingHelpers
  qw(
     simple_selectbox_html
     info_table_html
     hierarchical_selectboxes_html
     conditional_like_input_html
     html_optional_show
    );

use CXGN::Tools::Organism;
use CXGN::Phenome::Locus::LinkageGroup;
use base qw/CXGN::Search::DBI::Simple::WWWQuery/;
our %pname;

sub _cached_dbh() { our $_cached_dbc ||= CXGN::DB::Connection->new('phenome') }
my $phenome    = 'phenome';
my $sgn        = 'sgn';
my $sgn_people = 'sgn_people';
my $public     = 'public';

__PACKAGE__->selects_data("$phenome.locus.locus_id","$phenome.locus.locus_name","$phenome.locus.locus_symbol",  "$phenome.allele.allele_name", "$phenome.allele.allele_symbol", "$phenome.allele.allele_synonym", "$phenome.allele.allele_phenotype", "$phenome.locus.obsolete", "$phenome.allele.obsolete", "$phenome.locus.sp_person_id", "$phenome.locus.description", "$phenome.locus.linkage_group", "$phenome.locus.lg_arm", "$sgn.common_name.common_name_id", "$sgn.common_name.common_name");



__PACKAGE__->join_root("$phenome.locus");

#join locus with allele table. Filter out obsolete alleles and the empty "default" alleles
#(each locus should have one row in the allele table as a default space holder. This is important for making locus-individual associations, because these 2 are linked via the individual_allele table, so that if we want to link an individual with a locus name, without associating with a specific allele, the link will be made to the default allele_id)
__PACKAGE__->uses_joinpath('allelepath', 
			   [ "$phenome.allele", "$phenome.allele.locus_id=$phenome.locus.locus_id AND $phenome.allele.obsolete=false AND $phenome.allele.is_default=false" ],
			   );

__PACKAGE__->uses_joinpath('locusaliaspath', [ "$phenome.locus_alias", "$phenome.locus_alias.locus_id=$phenome.locus.locus_id"]);


__PACKAGE__->uses_joinpath('locusmarkerpath', [ "$phenome.locus_marker", "$phenome.locus_marker.locus_id=$phenome.locus.locus_id"]);
__PACKAGE__->uses_joinpath('locusunigenepath', [ "$phenome.locus_unigene", "$phenome.locus_unigene.locus_id=$phenome.locus.locus_id"]);
__PACKAGE__->uses_joinpath('person_path', 
			   ["$phenome.locus_owner", "$phenome.locus_owner.locus_id=$phenome.locus.locus_id"],
			   ["$sgn_people.sp_person", "$sgn_people.sp_person.sp_person_id=$phenome.locus_owner.sp_person_id"],
			   );
__PACKAGE__->uses_joinpath('organism_path', [ "$sgn.common_name", "$sgn.common_name.common_name_id=$phenome.locus.common_name_id"]);

__PACKAGE__->uses_joinpath('individual_path',
			   [ "$phenome.individual_locus", "$phenome.individual_locus.locus_id=$phenome.locus.locus_id"],
			   [ "$phenome.individual", "$phenome.individual.individual_id=$phenome.individual_locus.individual_id"],
			   );

__PACKAGE__->uses_joinpath('locusdbxrefpath',
			   [ "$phenome.locus_dbxref", "$phenome.locus_dbxref.locus_id=$phenome.locus.locus_id"],
			   [ "$public.dbxref", "$public.dbxref.dbxref_id=$phenome.locus_dbxref.dbxref_id"],
			   [ "$public.cvterm", "$public.dbxref.dbxref_id=$public.cvterm.dbxref_id"],
			   [ "$public.feature", "$public.dbxref.dbxref_id=$public.feature.dbxref_id"],
			   [ "public.cvtermsynonym", "$public.cvterm.cvterm_id=$public.cvtermsynonym.cvterm_id"],
			   [ "$public.db", "$public.dbxref.db_id=$public.db.db_id"],
			   );


__PACKAGE__->has_parameter(name    => 'locus_name',
                           columns => "$phenome.locus.locus_name",
	                   );

__PACKAGE__->has_parameter(name    => 'locus_alias',
 	                   columns => "$phenome.locus_alias.alias",
	                   group   =>1,
	                   );

__PACKAGE__->has_parameter(name    => 'locus_alias_obsolete',
 	                   columns => "$phenome.locus_alias.obsolete",
	                   group   =>1,
			   );

__PACKAGE__->has_parameter(name    => 'locus_id',
 	                   columns => "$phenome.locus.locus_id",
			   );


__PACKAGE__->has_parameter(name    => 'locus_symbol',
 	                   columns => "$phenome.locus.locus_symbol",
			   );

__PACKAGE__->has_parameter(name    => 'allele_id',
 	                   columns => "$phenome.allele.allele_id",
			   );
__PACKAGE__->has_parameter(name    => 'allele_name',
 	                   columns => "$phenome.allele.allele_name",
			   );
__PACKAGE__->has_parameter(name    => 'allele_symbol',
 	                   columns => "$phenome.allele.allele_symbol",
			   );

__PACKAGE__->has_parameter(name    => 'allele_synonym',
 	                   columns => "$phenome.allele.allele_synonym",
	                   sqlexpr => "array_to_string($phenome.allele.allele_synonym, ',')",
			   );

__PACKAGE__->has_parameter(name    => 'phenotype',
	                   columns => "$phenome.allele.allele_phenotype",
			   );


__PACKAGE__->has_parameter(name   =>'locus_obsolete',
 	                   columns=>"$phenome.locus.obsolete",
			   );
__PACKAGE__->has_parameter(name   =>'allele_obsolete',
 	                   columns=>"$phenome.allele.obsolete",
			   );


__PACKAGE__->has_parameter(name   =>'locus_description',
 	                   columns=>"$phenome.locus.description",
			   );
__PACKAGE__->has_parameter(name   =>'locus_linkage_group',
 	                   columns=>"$phenome.locus.linkage_group",
			   );
__PACKAGE__->has_parameter(name   =>'locus_lg_arm',
	                   columns=>"$phenome.locus.lg_arm",
			   );
__PACKAGE__->has_parameter(name   =>'common_name',
 	                   columns=>"$sgn.common_name.common_name",
			   );
__PACKAGE__->has_parameter(name   =>'common_name_id',
 	                   columns=>"$sgn.common_name.common_name_id",
			   );
__PACKAGE__->has_parameter(name   =>'editor',
 	                   columns=>["$sgn_people.sp_person.first_name",
 	                             "$sgn_people.sp_person.last_name",
				     "$sgn_people.sp_person.sp_person_id"],
 	                   sqlexpr=>"$sgn_people.sp_person.last_name || $sgn_people.sp_person.first_name 
                                      || $sgn_people.sp_person.sp_person_id",
			   );

__PACKAGE__->has_parameter(name   =>'editor_id',
 	                   columns=>"$phenome.locus_owner.sp_person_id",
			   );

__PACKAGE__->has_parameter(name   =>'has_sequence',
	                   columns=>["$phenome.locus_dbxref.locus_id"],
	                   sqlexpr=>"count(distinct $phenome.locus_dbxref.locus_id)",
 	                   group  =>1,
 	                   aggregate=>1,
			   );


__PACKAGE__->has_parameter(name   =>'has_marker',
	                   columns=>["$phenome.locus_marker.locus_id"],
	                   sqlexpr=>"count(distinct $phenome.locus_marker.locus_id)",
	                   group  =>1,
	                   aggregate=>1,
			   );

__PACKAGE__->has_parameter(name   =>'has_db_name',
	                   columns=>"$public.db.name",
			   );

__PACKAGE__->has_parameter(name   =>'has_annotation',
	                   columns=>["$phenome.locus_dbxref.dbxref_id"],
 	                   sqlexpr=>"count (distinct $phenome.locus_dbxref.locus_id)",
 	                   group  =>1,
	                   aggregate=>1,
			   );

__PACKAGE__->has_parameter(name   =>'has_reference',
	                   columns=>["$phenome.locus_dbxref.locus_id"],
	                   sqlexpr=>"count (distinct $phenome.locus_dbxref.locus_id)",
                           group  =>1,
 	                   aggregate=>1,
			   );

__PACKAGE__->has_parameter(name   =>'cvterm_synonym',
	                   columns=>"$public.cvtermsynonym.synonym",
			   );

__PACKAGE__->has_parameter(name   =>'ontology_term',
 	                   columns=>["$public.dbxref.accession",
 	                             "$public.cvterm.name"],
 	                   sqlexpr=>"$public.cvterm.name ||  $public.dbxref.accession",
	                   group  => 1,
			   );

__PACKAGE__->has_parameter(name   =>'genbank_accession',
	                   columns=>["$public.feature.name",
 	                             "$public.dbxref.accession"],
                           sqlexpr=>"$public.feature.name || $public.dbxref.accession",
	                   group  => 1,
			   );

__PACKAGE__->has_parameter(name   =>'ind_phenotype',
                           columns=>"$phenome.individual.description",
 	                   group  =>1,
			   );
__PACKAGE__->has_parameter(name   =>'default_allele',
                           columns=>"$phenome.allele.is_default",
 	                   group  =>1,
			   );

__PACKAGE__->has_complex_parameter( name => 'any_name',
				    uses => [qw/locus_name locus_symbol locus_alias locus_description allele_symbol allele_name allele_synonym/],
				    setter => sub {
				      my ($self, @args) = @_;
				      $self->locus_name(@args);
				      $self->locus_symbol(@args);
				      $self->locus_alias(@args);
				      $self->locus_description(@args);
				      $self->allele_symbol(@args);
				      $self->allele_name(@args);
				      $self->allele_synonym(@args);

				      $self->compound('&t OR &t OR &t OR &t OR &t OR &t OR &t' ,'locus_name', 'locus_symbol', 'locus_alias', 'locus_description', 'allele_symbol','allele_name', 'allele_synonym');
				    }
				  );

###### NOW WWW STUFF ###

sub request_to_params {
    my($self, %params) = @_;
    
    #sanitize all the parameters
    foreach my $key (keys %params) {
	if( $params{$key} ) {
	    $params{$key} =~ s/[;\'\",]//g;
	}
    }

    $self->locus_obsolete("='f'");

    if($params{any_name}) {
	$self->conditional_like_from_scalars('any_name',
					     @params{qw/any_name_matchtype any_name/}
					     );
    }

    if($params{phenotype}) {
	$self->phenotype('ILIKE ?',"%$params{phenotype}%");
	$self->ind_phenotype('ILIKE ?',"%$params{phenotype}%");
	$self->compound('&t OR &t', 'phenotype','ind_phenotype');
    }

    if($params{common_name}) {
	$self->common_name('= ?', "$params{common_name}");
    }

    #if ($params{editor} =~ m/^\d/) {
#	$self->editor('= ?', "$params{editor}");
    if ($params{editor}) {
	$self->editor('ILIKE ?', "%$params{editor}%");
    }
    
    if ($params{has_sequence}) {
	$self->has_sequence('>0');
	$self->has_db_name("= 'DB:GenBank_GI'");
	$self->terms_combine_op('AND');
    }
    if ($params{has_marker}) {
	$self->has_marker('!=0');
    }
    if ($params{has_annotation} && !$params{has_reference}) {
	$self->has_annotation('=1');
	$self->has_db_name("IN ('GO', 'PO', 'SP')");
	$self->terms_combine_op('AND');
    }
    if ($params{has_reference} && !$params{has_annotation}) {
	$self->has_reference('=1');
	$self->has_db_name("= 'PMID'");
	$self->terms_combine_op('AND');
    }
    if ($params{locus_linkage_group}) {
	$self->locus_linkage_group('= ?', "$params{locus_linkage_group}");
    }

    if ($params{ontology_term}) {
	if ($params{ontology_term} =~m /(..)(:)(\d+)/i) {  #PO: | GO: | SP:
	    $self->has_db_name('ILIKE ?', "$1");
	    $self->ontology_term('ILIKE ?', "%$3%");
	    $self->terms_combine_op('AND');
	    
	}else {
	    $self->has_db_name("IN ('GO', 'PO', 'SP')");
	    $self->cvterm_synonym('ILIKE ?', "%$params{ontology_term}%");
	    $self->ontology_term('ILIKE ?', "%$params{ontology_term}%");
	    $self->compound('&t AND (&t OR &t)','has_db_name','ontology_term', 'cvterm_synonym');
	}
    }
    
    if ($params{genbank_accession}) {
	$self->genbank_accession('ILIKE ?', "%$params{genbank_accession}%");
    }

    #page number
    if( defined($params{page}) ) {
	$self->page($params{page});
    }
}

sub _to_scalars {   
    my $self= shift;
    my $search= shift;
    my %params;

    no warnings 'uninitialized';

    #this part defines the mapping from get/post data to search params
    @params{qw/any_name_matchtype any_name/} = $self->conditional_like_to_scalars('any_name');
    
    
    ($params{phenotype}) = $self->param_bindvalues('phenotype');
    $params{phenotype} =~ s/%//g;
    
    ($params{allele_obsolete}) = $self->param_bindvalues('allele_obsolete');
    $params{allele_obsolete} =~ s/%//g;
    
    ($params{common_name}) = $self->param_bindvalues('common_name');
    ($params{common_name_id}) = $self->param_bindvalues('common_name_id');
    
    ($params{editor}) = $self->param_bindvalues('editor');
    $params{editor} =~ s/%//g;
    
    
    $params{has_sequence} = $self->pattern_match_parameter('has_sequence', qr/>\s*0/);
    $params{has_marker} = $self->pattern_match_parameter('has_marker', qr/!=\s*0/);
    
    $params{has_annotation} = $self->pattern_match_parameter('has_annotation', qr/!=\=1/);
    $params{has_annotation} = $self->pattern_match_parameter('has_db_name', qr/PO|GO|SP/);
    
    $params{has_reference} = $self->pattern_match_parameter('has_reference', qr/=1/);
    $params{has_reference} = $self->pattern_match_parameter('has_db_name', qr/PMID/);
    
    ($params{locus_linkage_group}) = $self->param_bindvalues('locus_linkage_group');
    
    ($params{ontology_term}) = $self->param_bindvalues('ontology_term');
    $params{ontology_term} =~ s/%//g;
    ($params{has_db_name}) = $self->param_bindvalues('has_db_name');
    
    if ( $params{has_db_name} ) {
	$params{ontology_term} = $params{has_db_name} . ":" . $params{ontology_term};
    }

    ($params{genbank_accession}) = $self->param_bindvalues('genbank_accession');
    $params{genbank_accession} =~ s/%//g;
    
    
    return %params;
}

sub to_html {
    my $self = shift;
    my $search = 'advanced';
    my %scalars = $self->_to_scalars($search);

    #make %pname, a tied hash that uniqifies names the make_pname
    # function is in CXGN::Page::WebForm, which is a parent of
    # CXGN::Search::DBI::Simple::WWWQuery
    $self->make_pname;
    our %pname;
    
    my $any_name_select = conditional_like_input_html($pname{any_name}, $scalars{any_name_matchtype}, $scalars{any_name}, '30');
    
    my $dbh=_cached_dbh();
    my ($organism_names_ref, $organism_ids_ref) = CXGN::Tools::Organism::get_existing_organisms($dbh);
    #add an empty entry to the front of the list
    unshift @$organism_names_ref, '';
    
    my $organism = simple_selectbox_html( choices  => $organism_names_ref,
					  name     => $pname{common_name},
					  selected => $scalars{common_name},
					  );
    
    my ($lg_names_ref) = CXGN::Phenome::Locus::LinkageGroup::get_all_lgs($dbh);
    my @lg_options = ();

    for(my $i = 0; $i < scalar(@$lg_names_ref); $i++) {
	push @lg_options, [$lg_names_ref->[$i], $lg_names_ref->[$i]];
    }
   
    my $linkage_group_select = simple_selectbox_html( choices  => \@lg_options,
						      name     => $pname{locus_linkage_group},
						      selected => $scalars{locus_linkage_group},
						      );
    
    my $has_sequence= $self->uniqify_name('has_sequence');
    my $has_marker = $self->uniqify_name('has_marker');
    my $has_annotation= $self->uniqify_name('has_annotation');
    my $has_reference= $self->uniqify_name('has_reference');
    my $ontology_term = $self->uniqify_name('ontology_term');
    my $genbank_accession = $self->uniqify_name('genbank_accession');
    
    #check boxes
    @scalars{qw/has_sequence has_marker has_annotation has_reference/} =
	map {$_ ? 'checked="checked" ' : undef} @scalars{qw/has_sequence has_marker has_annotation has_reference/};
    
    my $show_advanced_search =
	grep {defined($_)} @scalars{qw/ common_name phenotype editor has_sequence
					locus_linkage_group has_marker
					has_annotation has_reference
					ontology_term genbank_accession
					/};
    my $advanced_search=
	html_optional_show('advanced_search',
			   'Advanced search options',
			   qq|<div class="minorbox">\n|
			   .info_table_html(
					    'Organism'   => $organism,
					    'Chromosome / Linkage&nbsp;Group' => $linkage_group_select,
					    'Locus editor' =>qq|<input name="$pname{editor}" value="$scalars{editor}" size="20"/>|,
					    'Show only genes with' => <<EOH,
					    <input type="checkbox" name="$has_sequence" $scalars{has_sequence} />sequence <br />
					    <input type="checkbox" name="$has_marker" $scalars{has_marker} />markers<br />
					    <input type="checkbox" name="$has_annotation" $scalars{has_annotation} />GO/PO annotation<br />
EOH
					    'Phenotype'  => qq|<input name="$pname{phenotype}" value="$scalars{phenotype}" size="30" /><a href="direct_search.pl?search=phenotypes"> [Advanced SGN phenotype search]</a>|,
					    'Ontology term' => qq|<input name="$ontology_term" value = "$scalars{ontology_term}" />
					    <br /><span class="ghosted">(Term name or ID: e.g. 'carotenoid' or 'PO:0007010')</span>|,
					    'Genbank ID' =>qq|<input name="$genbank_accession" value="$scalars{genbank_accession}"
					    <br /><span class="ghosted">(Accession or GI: e.g. 'EF091820' or '118185006')</span>|,   
					    #'Associated publication' => "pubmedID insert text area/check box",
					    __border   =>0,
					    __multicol =>2,
					    __tableattrs => 'width="100%"',
					    ) .qq|</div>|,
			   $show_advanced_search);
    $scalars{has_sequence}   ||= '';
    $scalars{has_marker}     ||= '';
    $scalars{has_annotation} ||= '';
    $scalars{has_reference}  ||= '';
    
    my $html_ret = <<EOHTML;
    
    <table><tr>
	<td colspan="2"><b>Search for any locus or allele</b>  (<a href="../help/gene_search_help.pl" />gene search help page<a />)</td></tr>
	<tr><td>$any_name_select</td>
	<td><a href="../phenome/locus_display.pl?action=new">[Submit new locus]</a></td>
	</tr></table>
	<br />
	$advanced_search
	<div align="center"><input type="submit" value="Search"/></div>
EOHTML
}

sub quick_search {
    my ($self,$term) = @_;
    $self->any_name('ILIKE ?', "%$term%");
    $self->locus_obsolete('=?', "f");
    #$self->allele_obsolete('=?', "f");
    return $self;		  
}

###
1;#do not remove
###
