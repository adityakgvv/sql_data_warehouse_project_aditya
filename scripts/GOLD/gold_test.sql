----GOLD layer

SELECT cst_id,count(*) FROM
(SELECT  ci.cst_id
      ,ci.cst_key
      ,ci.cst_firstname
      ,ci.cst_lastname
      ,ci.cst_marital_status
      ,ci.cst_gndr
      ,ci.cst_create_date
      ,ca.bdate
      ,ca.gen
      ,la.cntry
  FROM [DataWarehouse].[silver].[crm_cust_info] ci
  LEFT JOIN  silver.erp_cust_az12 ca
  ON            ci.cst_key= ca.cid
  LEFT JOIN silver.erp_loc_a101 la
  ON            ci.cst_key = la.cid
  )t GROUP BY cst_id
  HAVING COUNT(*) >1;


SELECT  DISTINCT
      ci.cst_gndr
      ,ca.gen
  FROM [silver].[crm_cust_info] ci
  LEFT JOIN  silver.erp_cust_az12 ca
  ON            ci.cst_key= ca.cid
  LEFT JOIN silver.erp_loc_a101 la
  ON            ci.cst_key = la.cid
;

SELECT  DISTINCT
      ci.cst_gndr
      ,ca.gen
      ,CASE WHEN ci.cst_gndr !='n/a' THEN  ci.cst_gndr ---CRM is the MAster for gender info
            ELSE  COALESCE(ca.gen,'n/a')
        END as  new_gen
  FROM [silver].[crm_cust_info] ci
  LEFT JOIN  silver.erp_cust_az12 ca
  ON            ci.cst_key= ca.cid
  LEFT JOIN silver.erp_loc_a101 la
  ON            ci.cst_key = la.cid
;


CREATE VIEW gold.dim_customers AS
SELECT  
        ROW_NUMBER() OVER(ORDER BY cst_id) as customer_key
        ,ci.cst_id as customer_id
      ,ci.cst_key as customer_number
      ,ci.cst_firstname as first_name
      ,ci.cst_lastname as last_name
      ,la.cntry as country
      ,ci.cst_marital_status as martial_status
      ,CASE WHEN ci.cst_gndr !='n/a' THEN  ci.cst_gndr ---CRM is the MAster for gender info
            ELSE  COALESCE(ca.gen,'n/a')
        END as  gender
        ,ci.cst_create_date as create_date
      ,ca.bdate as birth_date
  FROM [DataWarehouse].[silver].[crm_cust_info] ci
  LEFT JOIN  silver.erp_cust_az12 ca
  ON            ci.cst_key= ca.cid
  LEFT JOIN silver.erp_loc_a101 la
  ON            ci.cst_key = la.cid
;
