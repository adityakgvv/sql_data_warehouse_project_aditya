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



SELECT pn.prd_id
      ,pn.cat_id
      ,pn.prd_key
      ,pn.prd_nm
      ,pn.prd_cost
      ,pn.prd_line
      ,pn.prd_start_dt
      ,pn.prd_end_dt
      ,pn.dwh_create_date
      ,pc.cat
      ,pc.subcat
      ,pc.maintenance
  FROM silver.crm_prd_info pn
  LEFT JOIN silver.erp_px_cat_g1v2 pc
  ON pn.cat_id = pc.id
  WHERE prd_end_dt IS NULL;----FIlter out all historical data


SELECT prd_key,COUNT(*) FROM (
SELECT pn.prd_id
      ,pn.cat_id
      ,pn.prd_key
      ,pn.prd_nm
      ,pn.prd_cost
      ,pn.prd_line
      ,pn.prd_start_dt
      ,pn.prd_end_dt
      ,pn.dwh_create_date
      ,pc.cat
      ,pc.subcat
      ,pc.maintenance
  FROM silver.crm_prd_info pn
  LEFT JOIN silver.erp_px_cat_g1v2 pc
  ON pn.cat_id = pc.id
  WHERE prd_end_dt IS NULL----FIlter out all historical data
  )t GROUP BY  prd_key
  HAVING  count(*) >1;



SELECT pn.prd_id as product_id
      ,pn.prd_key as product_number
      ,pn.prd_nm as product_name
      ,pn.cat_id as category_id
      ,pc.cat as category
      ,pc.subcat as subcategory
        ,pc.maintenance
      ,pn.prd_cost as cost
      ,pn.prd_line  as product_line
      ,pn.prd_start_dt as start_date
  FROM silver.crm_prd_info pn
  LEFT JOIN silver.erp_px_cat_g1v2 pc
  ON pn.cat_id = pc.id
  WHERE prd_end_dt IS NULL----FIlter out all historical data
  ;


CREATE VIEW gold.dim_products as 
SELECT 
        ROW_NUMBER() OVER(ORDER BY  pn.prd_start_dt,pn.prd_key) as product_key
        ,pn.prd_id as product_id
      ,pn.prd_key as product_number
      ,pn.prd_nm as product_name
      ,pn.cat_id as category_id
      ,pc.cat as category
      ,pc.subcat as subcategory
        ,pc.maintenance
      ,pn.prd_cost as cost
      ,pn.prd_line  as product_line
      ,pn.prd_start_dt as start_date
  FROM silver.crm_prd_info pn
  LEFT JOIN silver.erp_px_cat_g1v2 pc
  ON pn.cat_id = pc.id
  WHERE prd_end_dt IS NULL----FIlter out all historical data
  ;


CREATE VIEW gold.fact_sales as
SELECT sd.sls_ord_num as order_number
      ,pr.product_key
      ,cu.customer_key
      ,sd.sls_order_dt as order_date
      ,sd.sls_ship_dt as ship_date
      ,sd.sls_due_dt as due_date
      ,sd.sls_sales  as sales_amount
      ,sd.sls_quantity as quantity
      ,sd.sls_price as price
  FROM silver.crm_sales_details sd
  LEFT JOIN gold.dim_products pr
  on sd.sls_prd_key = pr.product_number
  LEFT JOIN gold.dim_customers cu
  on sd.sls_cust_id =cu.customer_id;


--1:03:27


--Foreign Key integrity(Dimension)
SELECT *
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
ON c.customer_key = f.customer_key
LEFT JOIN gold.dim_products p
ON p.product_key = f.product_key
WHERE p.product_key IS NULL;
