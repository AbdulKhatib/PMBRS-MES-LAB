-- Run this connected as SYS AS SYSDBA
ALTER SESSION SET "_ORACLE_SCRIPT"=true;  -- allows creating a user without CDB naming rules, needed on XE's default PDB setup

--User and pass

CREATE USER pmbrs_app IDENTIFIED BY PmbrsApp2026
  DEFAULT TABLESPACE users
  TEMPORARY TABLESPACE temp
  QUOTA UNLIMITED ON users;

GRANT CONNECT, RESOURCE TO pmbrs_app;
GRANT CREATE SESSION, CREATE TABLE, CREATE SEQUENCE, CREATE VIEW TO pmbrs_app;