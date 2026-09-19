CREATE OR REPLACE TABLE dim_payment_type (
  payment_type_key INT,
  payment_type_desc STRING
);
INSERT INTO dim_payment_type VALUES
  (1, 'Credit card'), (2, 'Cash'), (3, 'No charge'),
  (4, 'Dispute'), (5, 'Unknown'), (6, 'Voided trip');

CREATE OR REPLACE TABLE dim_vendor (
  vendor_key INT,
  vendor_desc STRING
);
INSERT INTO dim_vendor VALUES
  (1, 'Creative Mobile Technologies'),
  (2, 'VeriFone Inc');