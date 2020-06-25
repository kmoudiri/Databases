/* 1.1 */
-- eisagwgh proswpikwn dedomenwn

create or replace function insert_data(n integer, entry_d date, yr_l integer, yr_p integer, yr_s integer)
RETURNS VOID AS
$$
DECLARE 
      yr integer;    -- dilwsh metavlitis
BEGIN

    yr = EXTRACT(YEAR FROM entry_d); -- pairnw mono to etos apo thn hmerominia eggrafhs tou foithth
	
    INSERT INTO "LabStaff" (amka, email, name, father_name, surname, labworks, level)   -- eisagwgh data sto LabStaff
	SELECT CAST(create_amka(yr_l,n1.id) AS integer), create_email('l',n1.id,yr_l), name, random_male_names(), adapt_surname(surname,n1.sex),floor(random() * 10 + 1), random_level(n)
    from random_names(n) n1 natural join random_surnames(n) s;
	
	
	INSERT INTO "Professor" (amka, email, name, father_name, surname, rank, "labJoins") -- -- eisagwgh data sto Professor
	SELECT CAST(create_amka(yr_p,n1.id) AS INTEGER), create_email('p',n1.id,yr_p), name, random_male_names(), adapt_surname(surname,n1.sex), random_rank(n), floor(random() * 10 + 1)
    from random_names(n) n1 natural join random_surnames(n) s;
	
	
	INSERT INTO "Student" (amka, email, name, father_name, surname, entry_date, am)  -- eisagwgh data sto Student
	SELECT CAST(create_amka(yr_s,n1.id) AS INTEGER), create_email('s',n1.id,yr_s), name, random_male_names(), adapt_surname(surname,n1.sex), entry_d, create_am(yr,n1.id)
	FROM random_names(n) n1 natural join random_surnames(n) s;
	
end;
$$
LANGUAGE 'plpgsql' VOLATILE; 

select insert_data(2,'2050-01-01',2011,2012,2013)


-- prosarmogh epwnumou se arseniko/thulhko

CREATE OR REPLACE FUNCTION adapt_surname(surname character(50),
sex character(1)) RETURNS character(50) AS
$$
DECLARE
result character(50);
BEGIN
result = surname;
IF right(surname,2)<>'ΗΣ' THEN
RAISE NOTICE 'Cannot handle this surname';
ELSIF sex='F' THEN
result = left(surname,-1);
ELSIF sex<>'M' THEN
RAISE NOTICE 'Wrong sex parameter';
END IF;
RETURN result;
END;
$$
LANGUAGE 'plpgsql' IMMUTABLE;


--- dhmiourgia arithmou mhtrwou gia Foithtes


CREATE OR REPLACE FUNCTION create_am(year integer, num integer)
RETURNS character(10) AS
$$
BEGIN
RETURN concat(year::character(4),lpad(num::text,6,'0'));
END;
$$
LANGUAGE 'plpgsql' IMMUTABLE;



-- dimiourgia amka

CREATE OR REPLACE FUNCTION create_amka(year integer, num integer)
RETURNS character(10) AS
$$
BEGIN
	 RETURN concat(year::character(4),lpad(num::text,6,'0'));
END;
$$
LANGUAGE 'plpgsql' IMMUTABLE;

SELECT create_amka(2018,3)


-- eisagwgh email

CREATE OR REPLACE FUNCTION create_email(t character(1), num integer, year integer)
RETURNS character(30) AS
$$
BEGIN
RETURN concat(t,create_amka(year,num),'@isc.tuc.gr');
END;
$$
LANGUAGE 'plpgsql' IMMUTABLE;

select create_email('s', 4, 2024)




--returns a random number between two numbers l and h

CREATE OR REPLACE FUNCTION random_between(low INT ,high INT) 
   RETURNS INT AS
   $$
BEGIN
   RETURN floor(random()* (high-low + 1) + low);
END;
$$ 
language 'plpgsql' STRICT;




-- paragei tuxaia to level tou LabStaff

create or replace function random_level(n integer)
RETURNS level_type AS
$$
BEGIN
     
	 RETURN ('[0:3]={A,B,C,D}'::level_type[])[trunc(random()*4)] ;

END;
$$
LANGUAGE 'plpgsql' VOLATILE;


select random_level(4)




-- paragei tuxaia antrika onomata gia to father_name

CREATE OR REPLACE FUNCTION random_male_names()
RETURNS TABLE (name character(30)) AS
$$
BEGIN
RETURN QUERY
   
   SELECT nam.name
FROM (SELECT "Name".name, "Name".sex
FROM "Name"
	  where "Name".sex = 'M'
ORDER BY random() LIMIT 1 ) as nam;
END;
$$
LANGUAGE 'plpgsql' VOLATILE;

SELECT random_male_names()



-- epistrefei n tuxaia onomata

CREATE OR REPLACE FUNCTION random_names(n integer)
RETURNS TABLE(name character(30),sex character(1), id integer) AS
$$
BEGIN
RETURN QUERY
SELECT nam.name, nam.sex, row_number() OVER ()::integer
FROM (SELECT "Name".name, "Name".sex
FROM "Name"
ORDER BY random() LIMIT n) as nam;
END;
$$
LANGUAGE 'plpgsql' VOLATILE;



-- paragei tuxaia th bathmida tou Professor

create or replace function random_rank(n integer)
RETURNS rank_type AS
$$
BEGIN
     
	 RETURN ('[0:3]={full,associate,assistant,lecturer}'::rank_type[])[trunc(random()*4)] ;

END;
$$
LANGUAGE 'plpgsql' VOLATILE;


select random_rank(4)



-- epistrefei n tuxaia epwnuma me katalhksh -HS

CREATE OR REPLACE FUNCTION random_surnames(n integer)
RETURNS TABLE(surname character(50), id integer) AS
$$
BEGIN
RETURN QUERY
SELECT snam.surname, row_number() OVER ()::integer
FROM (SELECT "Surname".surname
FROM "Surname"
WHERE right("Surname".surname,2)='ΗΣ'
ORDER BY random() LIMIT n) as snam;
END;
$$
LANGUAGE 'plpgsql' VOLATILE;

----------------------------------------------------------------------------------
/* 1.2 */
CREATE OR REPLACE FUNCTION insert_grade_1_2()
RETURNS VOID AS
$$
BEGIN



UPDATE "Register" r
SET lab_grade = random_between(0,10)
WHERE amka is not null AND lab_grade is null AND register_status<> 'rejected' AND r.course_code IN (SELECT a.course_code        --ola ta ergastiriaka tou trexontos eksaminou approved,proposed status
FROM "Semester" s,
	(SELECT c.course_code, r.serial_number                                             --ola ta ergastiriaka ma8imata
	FROM "Course" c, "Register" r
	WHERE c.course_code = r.course_code AND c.lab_hours>0) as a
WHERE s.semester_id = a.serial_number AND s.semester_status='present' AND register_status<> 'rejected'
);

UPDATE "Register" r
SET exam_grade = random_between(0,10)
WHERE amka is not null AND exam_grade is null AND register_status<> 'rejected' AND r.course_code IN (SELECT a.course_code     --ola ta mathimata tou trexontos eksaminou approved,proposed status
FROM "Semester" s,
	(SELECT c.course_code, r.serial_number                                             --ola ta  ma8imata
	FROM "Course" c, "Register" r
	WHERE c.course_code = r.course_code ) as a
WHERE s.semester_id = a.serial_number AND s.semester_status='present' AND register_status<> 'rejected'
);

UPDATE "Register" r                                    --final grades gia mh ergastiriaka mathimata
SET final_grade = exam_grade
WHERE r.amka is not null AND final_grade is null AND r.course_code NOT IN(
												SELECT c.course_code                                 --ola ta ergastiriaka ma8imata
												FROM "Course" c, "Register" r
												WHERE c.course_code = r.course_code AND c.lab_hours>0);
												
UPDATE "Register" r                                    --final grades gia ergastiriaka mathimata
SET final_grade = (exam_percentage * exam_grade) + ((1-exam_percentage)*lab_grade)
FROM (SELECT * FROM "CourseRun" ) AS cr
WHERE r.amka is not null AND final_grade is null AND r.exam_grade > cr.exam_min AND r.lab_grade > cr.lab_min AND r.course_code IN(
																									SELECT c.course_code                                 --ola ta ergastiriaka ma8imata
																									FROM "Course" c, "Register" r
																									WHERE c.course_code = r.course_code AND c.lab_hours>0);


END;
$$
LANGUAGE 'plpgsql' VOLATILE;

SELECT insert_grade_1_2();

-------------------------------------------------------------------------------
/* 1.3 */
CREATE OR REPLACE FUNCTION insert_thesisGrade_1_3()
RETURNS VOID AS
$$
BEGIN


UPDATE "Diploma" d
SET thesis_grade = random_between(5,10)
WHERE d.thesis_grade is null AND d.amka IN (
								SELECT s.amka                    --students 5o etos kai panw
								FROM "Student" s, "Diploma" d
								WHERE s.amka = d.amka AND (extract(year from CURRENT_DATE) >= extract(year from s.entry_date) + 5));
								
END;
$$
LANGUAGE 'plpgsql' VOLATILE;

SELECT insert_thesisGrade_1_3();

-----------------------------------------------------------------------
/* 1.4 */
CREATE OR REPLACE FUNCTION MO_Courses_Grades()
RETURNS TABLE (amka integer, course_grade double precision) AS
$$
BEGIN
RETURN QUERY

SELECT a.amka, SUM(a.weight*a.final_grade)/SUM(a.weight) as course_grade  --mesos oros ma8imaton
FROM(
	SELECT s.amka, pass.course_code, pass.final_grade, pass.weight     --perasmenoi va8moi gia tous foithtes pou 8a apofoitisoun
	FROM returnStudent_2_8() s,
		(SELECT r.amka, c.course_code, r.final_grade, c.weight
		FROM ("Register" r JOIN "Course" c USING (course_code))
		WHERE register_status='pass') AS pass
	WHERE s.amka = pass.amka) AS a
GROUP BY a.amka
ORDER BY course_grade DESC LIMIT 50;

END;
$$
LANGUAGE 'plpgsql' VOLATILE;


CREATE OR REPLACE FUNCTION graduation_1_4(GradDate date)
RETURNS VOID AS
$$
BEGIN

UPDATE "Diploma" d                                         --insert va8mous diplomatos
SET diploma_grade = MO.course_grade*0.8 + d.thesis_grade*0.2, graduation_date = GradDate
FROM MO_Courses_Grades() MO
WHERE d.amka IN (SELECT MO.amka) AND d.diploma_grade is null;

END;
$$
LANGUAGE  'plpgsql' VOLATILE;

SELECT graduation_1_4('2018-04-01');



