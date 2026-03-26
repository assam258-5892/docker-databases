-- Oracle: FREE database (system/manager)
-- docker compose exec -T oracle-service sqlplus system/manager@FREE @/sql/oracle.sql

BEGIN EXECUTE IMMEDIATE 'DROP TABLE departments CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE employees CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE departments_seq'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

CREATE SEQUENCE departments_seq START WITH 1 INCREMENT BY 1;

CREATE TABLE departments (
    id            NUMBER DEFAULT departments_seq.NEXTVAL PRIMARY KEY,
    dept_name     VARCHAR2(50) NOT NULL,
    manager_name  VARCHAR2(100),
    location      VARCHAR2(100),
    budget        NUMBER(12,2),
    created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO departments (dept_name, manager_name, location, budget) VALUES ('Engineering 1', 'Kim Minsu',     'Seoul Gangnam',   500000000);
INSERT INTO departments (dept_name, manager_name, location, budget) VALUES ('Engineering 2', 'Lee Jiyoung',   'Seoul Pangyo',    450000000);
INSERT INTO departments (dept_name, manager_name, location, budget) VALUES ('Planning',      'Park Junho',    'Seoul Gangnam',   300000000);
INSERT INTO departments (dept_name, manager_name, location, budget) VALUES ('HR',            'Jung Sujin',    'Seoul Jongno',    200000000);
INSERT INTO departments (dept_name, manager_name, location, budget) VALUES ('Design',        'Choi Younghun', 'Seoul Gangnam',   250000000);
INSERT INTO departments (dept_name, manager_name, location, budget) VALUES ('Marketing',     'Han Mirae',     'Seoul Mapo',      350000000);
INSERT INTO departments (dept_name, manager_name, location, budget) VALUES ('Sales',         'Oh Sejin',      'Busan Haeundae',  280000000);
INSERT INTO departments (dept_name, manager_name, location, budget) VALUES ('Finance',       'Yoon Hana',     'Seoul Jongno',    180000000);
INSERT INTO departments (dept_name, manager_name, location, budget) VALUES ('QA',            'Seo Donghyun',  'Gyeonggi Suwon',  220000000);
INSERT INTO departments (dept_name, manager_name, location, budget) VALUES ('Data',          'Lim Chaewon',   'Seoul Pangyo',    400000000);

COMMIT;
EXIT;
