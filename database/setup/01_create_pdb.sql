-- =============================================================================
-- Name       : Bruce RUTAGENGWA
-- Student ID : 28468
-- Group      : C
-- Project    : Rwanda Food Price Watch
-- Script     : 01_create_pdb.sql  (Phase III - Task 1)
-- Purpose    : Create the pluggable database, open it and save its state.
-- Run as     : SYSDBA in CDB$ROOT, from the repository root:
--                sqlplus /nolog @database/setup/01_create_pdb.sql
-- Database   : Oracle Database 21c Express Edition (CDB "XE"), local install
-- =============================================================================
-- PDB name rule: GroupName_StudentID_FirstName_ProjectName_DB, lowercase,
-- starts with a letter, at most 30 characters.
--   c_28468_bruce_foodpricewatch_db = 31 characters (too long)
--   c_28468_bruce_pricewatch_db     = 27 characters (used)
--
-- Oracle requires an ADMIN USER when a PDB is created from the seed. The
-- brief's admin user (bruce_admin) is therefore created here; script 02 grants
-- it the DBA role and confirms the connection.
-- =============================================================================

CONNECT / AS SYSDBA
SET ECHO ON
SET LINESIZE 200 PAGESIZE 100
SPOOL screenshots/01_create_pdb_output.txt

COLUMN container FORMAT A30
COLUMN username FORMAT A15
SELECT TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS') AS run_at,
       SYS_CONTEXT('USERENV', 'CON_NAME')         AS container
FROM   dual;

WHENEVER SQLERROR EXIT FAILURE

-- The new PDB's data files go in their own folder next to the other PDBs.
CREATE PLUGGABLE DATABASE c_28468_bruce_pricewatch_db
  ADMIN USER bruce_admin IDENTIFIED BY bruce   -- lab-only password (brief)
  FILE_NAME_CONVERT = (
    'C:\APP\ENVY\PRODUCT\21C\ORADATA\XE\PDBSEED\',
    'C:\APP\ENVY\PRODUCT\21C\ORADATA\XE\C_28468_BRUCE_PRICEWATCH_DB\'
  );

ALTER PLUGGABLE DATABASE c_28468_bruce_pricewatch_db OPEN;

-- Re-open the PDB automatically after the CDB restarts.
ALTER PLUGGABLE DATABASE c_28468_bruce_pricewatch_db SAVE STATE;

WHENEVER SQLERROR CONTINUE

COLUMN name      FORMAT A30
COLUMN open_mode FORMAT A12
COLUMN state     FORMAT A8
SELECT p.con_id, p.name, p.open_mode, s.state AS saved_state
FROM   v$pdbs p
LEFT   JOIN dba_pdb_saved_states s ON s.con_name = p.name
WHERE  p.name = 'C_28468_BRUCE_PRICEWATCH_DB';

SPOOL OFF
EXIT
