-- =============================================================================
-- Name       : Bruce RUTAGENGWA
-- Student ID : 28468
-- Group      : C
-- Project    : Rwanda Food Price Watch
-- Script     : 03_tablespaces.sql  (Phase III - Task 3)
-- Purpose    : Create the data, index and temporary tablespaces inside the PDB
--              and make them the admin user's defaults, with unlimited quota.
-- Run as     : bruce_admin (DBA) in the PDB, from the repository root:
--                sqlplus /nolog @database/setup/03_tablespaces.sql
-- =============================================================================
-- <project> = pricewatch
--   pricewatch_data : 100M, AUTOEXTEND ON NEXT 10M MAXSIZE 1G
--   pricewatch_idx  :  50M, AUTOEXTEND ON NEXT 10M MAXSIZE 500M
--   pricewatch_temp :  50M, AUTOEXTEND ON NEXT 10M MAXSIZE 500M (temporary)
-- =============================================================================

CONNECT bruce_admin/bruce@//localhost:1521/c_28468_bruce_pricewatch_db
SET ECHO ON
SET LINESIZE 200 PAGESIZE 100
SPOOL screenshots/03_tablespaces_output.txt

COLUMN container FORMAT A30
COLUMN username FORMAT A15
SELECT SYS_CONTEXT('USERENV', 'CON_NAME')        AS container,
       USER                                      AS username,
       TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS') AS run_at
FROM   dual;

WHENEVER SQLERROR EXIT FAILURE

CREATE TABLESPACE pricewatch_data
  DATAFILE 'C:\APP\ENVY\PRODUCT\21C\ORADATA\XE\C_28468_BRUCE_PRICEWATCH_DB\PRICEWATCH_DATA01.DBF'
  SIZE 100M AUTOEXTEND ON NEXT 10M MAXSIZE 1G;

CREATE TABLESPACE pricewatch_idx
  DATAFILE 'C:\APP\ENVY\PRODUCT\21C\ORADATA\XE\C_28468_BRUCE_PRICEWATCH_DB\PRICEWATCH_IDX01.DBF'
  SIZE 50M AUTOEXTEND ON NEXT 10M MAXSIZE 500M;

CREATE TEMPORARY TABLESPACE pricewatch_temp
  TEMPFILE 'C:\APP\ENVY\PRODUCT\21C\ORADATA\XE\C_28468_BRUCE_PRICEWATCH_DB\PRICEWATCH_TEMP01.DBF'
  SIZE 50M AUTOEXTEND ON NEXT 10M MAXSIZE 500M;

ALTER USER bruce_admin
  DEFAULT TABLESPACE   pricewatch_data
  TEMPORARY TABLESPACE pricewatch_temp
  QUOTA UNLIMITED ON pricewatch_data
  QUOTA UNLIMITED ON pricewatch_idx;

WHENEVER SQLERROR CONTINUE

COLUMN default_tablespace   FORMAT A20
COLUMN temporary_tablespace FORMAT A20
SELECT default_tablespace, temporary_tablespace
FROM   user_users;

COLUMN tablespace_name FORMAT A20
COLUMN quota           FORMAT A10
SELECT tablespace_name,
       CASE max_bytes WHEN -1 THEN 'UNLIMITED' ELSE TO_CHAR(max_bytes) END AS quota
FROM   user_ts_quotas
ORDER  BY tablespace_name;

SPOOL OFF
EXIT
