package AlleleCascades;
use Moose;
extends 'CXGN::Metadata::Dbpatch';

sub patch {

    shift->dbh->do(<<EOSQL);

SET search_path=phenome,public;

ALTER TABLE stock_allele
  DROP CONSTRAINT stock_allele_allele_id_fkey,
  DROP CONSTRAINT stock_allele_stock_id_fkey;

ALTER TABLE stock_allele
  ADD CONSTRAINT stock_allele_allele_id_fkey
                 FOREIGN KEY (allele_id)
                 REFERENCES phenome.allele(allele_id)
                 ON DELETE CASCADE,
  ADD CONSTRAINT stock_allele_stock_id_fkey
                 FOREIGN KEY (stock_id)
                 REFERENCES stock(stock_id)
                 ON DELETE CASCADE;

ALTER TABLE allele
   DROP CONSTRAINT allele_locus_id_fkey;

ALTER TABLE allele
   ADD CONSTRAINT allele_locus_id_fkey
                  FOREIGN KEY (locus_id)
                  REFERENCES locus(locus_id)
                  ON DELETE CASCADE;

EOSQL

    print "Done.";
    return 1;
}

1;
