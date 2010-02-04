package CXGN::Phenome::Schema::PhenotypeTerm;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("phenotype_term");
__PACKAGE__->add_columns(
  "phenotype_term_id",
  {
    data_type => "integer",
    default_value => "nextval('phenotype_term_phenotype_term_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "term_ref",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 10,
  },
  "term_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 10,
  },
  "phenotype_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
);
__PACKAGE__->set_primary_key("phenotype_term_id");
__PACKAGE__->add_unique_constraint("term_id_key", ["term_id", "phenotype_id"]);
__PACKAGE__->add_unique_constraint("phenotype_term_pkey", ["phenotype_term_id"]);
__PACKAGE__->belongs_to(
  "phenotype_id",
  "CXGN::Phenome::Schema::Phenotype",
  { phenotype_id => "phenotype_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-04 22:42:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:QA4jRZhgAx9pR/UhAEU6FQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
