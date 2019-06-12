use utf8;
package CXGN::Phenome::Schema::NdExperimentMdJson;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CXGN::Phenome::Schema::NdExperimentMdJson

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<nd_experiment_md_json>

=cut

__PACKAGE__->table("nd_experiment_md_json");

=head1 ACCESSORS

=head2 nd_experiment_md_json_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'phenome.nd_experiment_md_json_nd_experiment_md_json_id_seq'

=head2 nd_experiment_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 json_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "nd_experiment_md_json_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "phenome.nd_experiment_md_json_nd_experiment_md_json_id_seq",
  },
  "nd_experiment_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "json_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</nd_experiment_md_json_id>

=back

=cut

__PACKAGE__->set_primary_key("nd_experiment_md_json_id");


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2019-06-12 07:31:51
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:D23xGnHhyKxYKqYWXkxEUQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
