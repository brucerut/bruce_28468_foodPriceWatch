-- =============================================================================
-- Name       : Bruce RUTAGENGWA
-- Student ID : 28468
-- Group      : C
-- Project    : Rwanda Food Price Watch
-- Script     : 04_archive_log.sql  (Phase III - Task 4)
-- Purpose    : Show the archive log mode; on the LOCAL install only, switch
--              the CDB to ARCHIVELOG mode.
-- Run as     : SYSDBA in CDB$ROOT, from the repository root:
--                sqlplus /nolog @database/setup/04_archive_log.sql
-- =============================================================================
-- WHY ARCHIVE LOGGING CANNOT BE ENABLED FOR A SINGLE PDB
--   All PDBs in a CDB share one set of online redo logs and one control file,
--   which belong to the CDB, not to any PDB. ARCHIVELOG mode decides whether
--   those shared redo logs are copied before reuse, so it is set once for the
--   whole CDB (ALTER DATABASE ARCHIVELOG in CDB$ROOT, while the CDB is MOUNTED).
--   That needs SYSDBA and a restart of the CDB, which closes every PDB in it.
-- =============================================================================
-- PART B CHANGES THE WHOLE DATABASE. RUN IT ONLY ON YOUR OWN LOCAL INSTALL.
-- NEVER RUN PART B ON THE SHARED LAB SERVER (run only Part A there).
-- =============================================================================

CONNECT / AS SYSDBA
SET ECHO ON
SET LINESIZE 200 PAGESIZE 100
SPOOL screenshots/04_archive_log_output.txt

-- ---------------------------------------------------------------------------
-- Part A - check and show the current archive log mode
-- ---------------------------------------------------------------------------
SELECT TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS') AS checked_at,
       name AS cdb_name, log_mode
FROM   v$database;

ARCHIVE LOG LIST

-- ---------------------------------------------------------------------------
-- Part B - LOCAL INSTALL ONLY: enable ARCHIVELOG mode
-- ---------------------------------------------------------------------------
-- 1. Folder for the archived redo logs (no fast recovery area is configured).
HOST if not exist "C:\app\Envy\product\21c\oradata\XE\ARCHIVELOG" mkdir "C:\app\Envy\product\21c\oradata\XE\ARCHIVELOG"
ALTER SYSTEM SET log_archive_dest_1 = 'LOCATION=C:\app\Envy\product\21c\oradata\XE\ARCHIVELOG' SCOPE = SPFILE;

-- 2. Restart the CDB in MOUNT state (this closes every PDB).
SHUTDOWN IMMEDIATE
STARTUP MOUNT

-- 3. Switch the whole CDB to ARCHIVELOG mode and open it again.
ALTER DATABASE ARCHIVELOG;
ALTER DATABASE OPEN;

-- 4. Open the PDBs (saved states also do this automatically).
ALTER PLUGGABLE DATABASE ALL OPEN;

-- 5. Prove it works: show the new mode and force one archived log.
SELECT TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS') AS checked_at,
       name AS cdb_name, log_mode
FROM   v$database;

ARCHIVE LOG LIST

ALTER SYSTEM ARCHIVE LOG CURRENT;

COLUMN name FORMAT A80
SELECT sequence#, name, TO_CHAR(completion_time, 'YYYY-MM-DD HH24:MI:SS') AS archived_at
FROM   v$archived_log
WHERE  name IS NOT NULL
ORDER  BY sequence# DESC
FETCH FIRST 3 ROWS ONLY;

COLUMN pdb_name FORMAT A30
SELECT name AS pdb_name, open_mode FROM v$pdbs ORDER BY con_id;

-- To go back to NOARCHIVELOG later (local only): SHUTDOWN IMMEDIATE,
-- STARTUP MOUNT, ALTER DATABASE NOARCHIVELOG, ALTER DATABASE OPEN.

SPOOL OFF
EXIT
