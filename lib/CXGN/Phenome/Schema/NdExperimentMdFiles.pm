use utf8;
package CXGN::Phenome::Schema::NdExperimentMdFiles;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CXGN::Phenome::Schema::NdExperimentMdFiles

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<nd_experiment_md_files>

=cut

__PACKAGE__->table("nd_experiment_md_files");

=head1 ACCESSORS

=head2 nd_experiment_md_files_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'nd_experiment_md_files_nd_experiment_md_files_id_seq'

=head2 nd_experiment_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 file_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "nd_experiment_md_files_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "nd_experiment_md_files_nd_experiment_md_files_id_seq",
  },
  "nd_experiment_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "file_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</nd_experiment_md_files_id>

=back

=cut

__PACKAGE__->set_primary_key("nd_experiment_md_files_id");


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-07-16 23:38:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:P5lf1C7HmcCMvaJ4oBpqqA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
