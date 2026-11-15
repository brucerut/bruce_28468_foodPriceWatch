-- =============================================================================
-- Name       : Bruce RUTAGENGWA
-- Student ID : 28468
-- Group      : C
-- Project    : Rwanda Food Price Watch
-- Script     : 02_create_user.sql  (Phase III - Task 2, and the Task 5 port)
-- Purpose    : Give the PDB admin user bruce_admin the DBA role, set the
--              EM Express HTTPS port for the PDB, and confirm that
--              bruce_admin can connect to the PDB.
-- Run as     : SYSDBA, from the repository root:
--                sqlplus /nolog @database/setup/02_create_user.sql
-- =============================================================================
-- bruce_admin was created by the ADMIN USER clause in 01_create_pdb.sql.
-- Password = first name: a lab-only convention required by the brief;
-- never use a weak password on a real system.
-- =============================================================================

CONNECT / AS SYSDBA
SET ECHO ON
SET LINESIZE 200 PAGESIZE 100
SET SERVEROUTPUT ON
SPOOL screenshots/02_create_user_output.txt

WHENEVER SQLERROR EXIT FAILURE
ALTER SESSION SET CONTAINER = c_28468_bruce_pricewatch_db;

ALTER USER bruce_admin IDENTIFIED BY bruce ACCOUNT UNLOCK;
GRANT DBA TO bruce_admin;

-- Task 5: EM Express HTTPS port 55xx, xx = last two digits of 28468 -> 5568
EXEC DBMS_XDB_CONFIG.SETHTTPSPORT(5568);
WHENEVER SQLERROR CONTINUE

SELECT DBMS_XDB_CONFIG.GETHTTPSPORT() AS em_express_https_port FROM dual;

-- Confirm the connection as the admin user, straight to the PDB service.
CONNECT bruce_admin/bruce@//localhost:1521/c_28468_bruce_pricewatch_db

SHOW USER
SHOW CON_NAME

COLUMN username  FORMAT A15
COLUMN container FORMAT A30
COLUMN role      FORMAT A10
SELECT USER                                        AS username,
       SYS_CONTEXT('USERENV', 'CON_NAME')          AS container,
       TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS')   AS connected_at
FROM   dual;

SELECT granted_role AS role, admin_option, default_role
FROM   user_role_privs
WHERE  granted_role = 'DBA';

SPOOL OFF
EXIT
