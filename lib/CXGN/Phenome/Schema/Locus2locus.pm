package CXGN::Phenome::Schema::Locus2locus;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("locus2locus");
__PACKAGE__->add_columns(
  "locus2locus_id",
  {
    data_type => "integer",
    default_value => "nextval('locus2locus_locus2locus_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "subject_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "object_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "relationship_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "evidence_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "reference_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "sp_person_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "obsolete",
  {
    data_type => "boolean",
    default_value => "false",
    is_nullable => 1,
    size => 1,
  },
  "modified_date",
  {
    data_type => "timestamp with time zone",
    default_value => undef,
    is_nullable => 1,
    size => 8,
  },
  "create_date",
  {
    data_type => "timestamp with time zone",
    default_value => "now()",
    is_nullable => 1,
    size => 8,
  },
);
__PACKAGE__->set_primary_key("locus2locus_id");
__PACKAGE__->add_unique_constraint("locus2locus_pkey", ["locus2locus_id"]);
__PACKAGE__->belongs_to(
  "subject_id",
  "CXGN::Phenome::Schema::Locus",
  { locus_id => "subject_id" },
);
__PACKAGE__->belongs_to(
  "object_id",
  "CXGN::Phenome::Schema::Locus",
  { locus_id => "object_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-04 22:42:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:M49D5HaOKu4VmZvrqFbTgQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
