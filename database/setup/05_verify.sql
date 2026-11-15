-- =============================================================================
-- Name       : Bruce RUTAGENGWA
-- Student ID : 28468
-- Group      : C
-- Project    : Rwanda Food Price Watch
-- Script     : 05_verify.sql  (Phase III - Task 6)
-- Purpose    : Confirm every Phase III item with queries and spool the output.
-- Run as     : bruce_admin in the PDB, from the repository root:
--                sqlplus /nolog @database/setup/05_verify.sql
-- Output     : screenshots/05_verify_output.txt
-- =============================================================================

CONNECT bruce_admin/bruce@//localhost:1521/c_28468_bruce_pricewatch_db
SET ECHO ON
SET LINESIZE 230 PAGESIZE 100 FEEDBACK ON
SPOOL screenshots/05_verify_output.txt

-- 0. Who, where and when
COLUMN username  FORMAT A15
COLUMN container FORMAT A30
SELECT USER                                      AS username,
       SYS_CONTEXT('USERENV', 'CON_NAME')        AS container,
       TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS') AS verified_at
FROM   dual;

-- 1. The PDB exists and is open (and its state is saved for restarts)
COLUMN pdb_name    FORMAT A30
COLUMN open_mode   FORMAT A12
COLUMN restricted  FORMAT A10
SELECT con_id, name AS pdb_name, open_mode, restricted,
       TO_CHAR(open_time, 'YYYY-MM-DD HH24:MI:SS') AS opened_at
FROM   v$pdbs;

-- 2. The admin user's default and temporary tablespaces
COLUMN default_tablespace   FORMAT A20
COLUMN temporary_tablespace FORMAT A20
COLUMN account_status       FORMAT A15
SELECT username, default_tablespace, temporary_tablespace, account_status
FROM   dba_users
WHERE  username = 'BRUCE_ADMIN';

COLUMN grantee FORMAT A15
COLUMN granted_role FORMAT A12
SELECT grantee, granted_role
FROM   dba_role_privs
WHERE  grantee = 'BRUCE_ADMIN' AND granted_role = 'DBA';

COLUMN quota FORMAT A10
SELECT username, tablespace_name,
       CASE max_bytes WHEN -1 THEN 'UNLIMITED' ELSE TO_CHAR(max_bytes) END AS quota
FROM   dba_ts_quotas
WHERE  username = 'BRUCE_ADMIN'
ORDER  BY tablespace_name;

-- 3. Each project tablespace with its size, autoextend and maximum size
COLUMN tablespace_name FORMAT A16
COLUMN contents        FORMAT A10
COLUMN file_name       FORMAT A90
SELECT t.tablespace_name, t.contents,
       f.bytes / 1024 / 1024                         AS size_mb,
       f.autoextensible,
       f.increment_by * t.block_size / 1024 / 1024   AS next_mb,
       f.maxbytes / 1024 / 1024                      AS max_mb,
       f.file_name
FROM   dba_tablespaces t
JOIN  (SELECT tablespace_name, file_name, bytes, autoextensible, increment_by, maxbytes FROM dba_data_files
       UNION ALL
       SELECT tablespace_name, file_name, bytes, autoextensible, increment_by, maxbytes FROM dba_temp_files) f
       ON f.tablespace_name = t.tablespace_name
WHERE  t.tablespace_name LIKE 'PRICEWATCH%'
ORDER  BY t.tablespace_name;

-- 4. The archive log mode of the database (a CDB-wide setting)
COLUMN cdb_name FORMAT A10
SELECT name AS cdb_name, log_mode FROM v$database;

-- 5. EM Express HTTPS port for this PDB (Task 5)
SELECT DBMS_XDB_CONFIG.GETHTTPSPORT() AS em_express_https_port FROM dual;

SPOOL OFF
EXIT
