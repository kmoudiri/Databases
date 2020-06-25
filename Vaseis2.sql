/*2.1 A*/
CREATE OR REPLACE FUNCTION return_prof_2_1(lCode integer)
RETURNS TABLE (name character(30), surname character (30), email character(30)) AS
$$
BEGIN
    RETURN QUERY
    SELECT p.name, p.surname, p.email
    FROM "Professor" p , "Lab" l
    WHERE p.amka = l.profdirects and l.lab_code = lCode;
END;
$$
LANGUAGE  'plpgsql' VOLATILE;


SELECT return_prof_2_1(3);

----------------------------------------------------------------------
/*2.1 B*/
CREATE OR REPLACE FUNCTION return_prof2_2_1B(cCode char (7), academic_yr int, academic_s semester_season_type)
RETURNS TABLE (name character(30), surname character (30), email character(30)) AS
$$
BEGIN
    RETURN QUERY

	SELECT b.name, b.surname, b.email                                                          --analoga to mathima, pairnw ton kathigiti
	FROM(
		SELECT p.name, p.surname, p.email, a.academic_year, a.academic_season, a.course_code    --kathigites, mathimata, eksamino
		FROM "Professor" p, 
			(SELECT *
			FROM "CourseRun" c, "Semester" s
			WHERE c.semesterrunsin = s.semester_id) AS a
		WHERE p.amka = a.amka_prof1 OR p.amka = a.amka_prof2) AS b
	WHERE b.course_code=cCode AND b.academic_year = academic_yr AND b.academic_season = academic_s;
		
END;
$$
LANGUAGE  'plpgsql' VOLATILE;


SELECT return_prof2_2_1B('ΠΛΗ 101', 2018, 'winter');

---------------------------------------------------------------------------------
/*2.2*/
CREATE OR REPLACE FUNCTION return_grades_2_2(cCode character(7), academic_yr int, academic_s semester_season_type, category character(11))
RETURNS TABLE (name character(30), surname character (30), am character(10), grade numeric) AS
$$
BEGIN
    RETURN QUERY
	
	SELECT w.name, w.surname, w.am, w.final_grade   --an dwthei final grade, epistrefei to final_grade
	FROM(
	SELECT b.name, b.surname, b.am, b.final_grade, b.lab_grade , b.exam_grade  --analoga me to mathima kai to etos pairnw va8mologia
	FROM(
	SELECT *							--join semester, student, register
	FROM "Semester" s2, (               --dialegw foitites kai pernw tin va8mologia gia mathimata p dn einai rejected 
		SELECT *
		FROM "Student" s ,"Register" r 
		WHERE s.amka=r.amka ) AS a
	WHERE s2.semester_id = a.serial_number AND a.register_status IN ('approved', 'pass', 'fail')) AS b
	
	WHERE b.course_code = cCode AND b.academic_year = academic_yr ) as w
	WHERE category='final_grade'
	
	UNION
	
	SELECT w.name, w.surname, w.am, w.lab_grade   --an dwthei lab grade, epistrefei to lab_grade
	FROM(
	SELECT b.name, b.surname, b.am, b.final_grade, b.lab_grade , b.exam_grade
	FROM(
	SELECT *
	FROM "Semester" s2, (
		SELECT *
		FROM "Student" s ,"Register" r 
		WHERE s.amka=r.amka ) AS a
	WHERE s2.semester_id = a.serial_number AND a.register_status IN ('approved', 'pass', 'fail')) AS b
	
	WHERE b.course_code = cCode AND b.academic_year = academic_yr ) as w
	WHERE category='lab_grade'
	
	UNION
	
	SELECT w.name, w.surname, w.am, w.exam_grade  --an dwthei exam grade, epistrefei to exam_grade
	FROM(
	SELECT b.name, b.surname, b.am, b.final_grade, b.lab_grade , b.exam_grade
	FROM(
	SELECT *
	FROM "Semester" s2, (
		SELECT *
		FROM "Student" s ,"Register" r 
		WHERE s.amka=r.amka ) AS a
	WHERE s2.semester_id = a.serial_number AND a.register_status IN ('approved', 'pass', 'fail')) AS b
	
	WHERE b.course_code = cCode AND b.academic_year = academic_yr ) as w
	WHERE category='exam_grade'	;
		
END;
$$
LANGUAGE  'plpgsql' VOLATILE;


SELECT return_grades_2_2('ΕΝΕ 401', 2016, 'winter', 'final_grade');

----------------------------------------------------------------------------
/* 2.3 */
CREATE OR REPLACE FUNCTION get_courses(prof_rank rank_type)
RETURNS TABLE (name character(30), surname character(30), sector_code integer) AS
$$
BEGIN
	
	RETURN QUERY

	SELECT w.name, w.surname, w.sector_code                               --join me to Semester gia na parw to trexon eksamino
	FROM "Semester" s, (
		SELECT b.name, b.surname, b.sector_code, c.semesterrunsin         --pairnw gia kathe kathigiti se poio eksamino didaskei
		FROM "CourseRun" c, (
			SELECT a.name, a.surname, a.amka, a.sector_code               --pairnw olous tous kathigites sugkekrimenis vathmidas
			FROM (
				SELECT l.name, l.surname, l.amka, r.sector_code, l.rank   --join Professor me Lab gia na parw ton tomea kathe kathigiti
				FROM   "Professor" l, "Lab"  r
				WHERE l."labJoins" = r.lab_code 
			) as a
			WHERE  a.rank = prof_rank) AS b
		WHERE c.amka_prof1= b.amka OR  c.amka_prof2=b.amka) AS w
	WHERE s.semester_id = w.semesterrunsin AND s.semester_status='present';
	
END;
$$
LANGUAGE  'plpgsql' VOLATILE;

SELECT get_courses('lecturer');

----------------------------------------------------------------------------------
/* 2.4 */
CREATE OR REPLACE FUNCTION courses_run24()
RETURNS TABLE(course_code character(7), course_title character(100), endiksi text ) AS 
$$
BEGIN	
RETURN QUERY
SELECT  w.course_code, c.course_title, w.endiksi
FROM "Course" c, (
	select  r.course_code, 'NAI' as endiksi  --nai gia ola ta mathimata me semester_status='present'
	from "Semester" s, "CourseRun" r
	where s.semester_id = r.semesterrunsin AND s.semester_status='present'
	 
	union
	
	select  r.course_code, 'OXI' as endiksi   -- oxi: gia ola ta mathimata tou earinou pou den exoun semester_status='present'
	from "Semester" s, "CourseRun" r 
	where s.semester_id = r.semesterrunsin AND s.academic_season='spring' AND r.course_code NOT IN (
				select r.course_code              --ola ta mathimata tou trexontos eksaminou
				from "Semester" s, "CourseRun" r
				where s.semester_id = r.semesterrunsin AND s.semester_status='present' )
	) AS w
WHERE c.course_code = w.course_code;

END;
$$
LANGUAGE 'plpgsql' VOLATILE;

SELECT courses_run24();

-------------------------------------------------------
/* 2.5 */
CREATE OR REPLACE FUNCTION get_courses_notpass2_5(st_amka integer)
RETURNS TABLE (course_code character(7), course_title character(100), amka integer) AS
$$
BEGIN
RETURN QUERY

SELECT DISTINCT c.course_code, c.course_title, r.amka   --pairnw ola ta upoxreotika sugkekrimenou foititi(amka) pou dn vriskontai sta perasmena tou
FROM "Course" c, "Register" r 
WHERE c.course_code = r.course_code AND obligatory AND r.register_status <> 'pass' AND r.amka=st_amka AND c.course_code NOT IN(
				SELECT c.course_code       --ola ta perasmena upoxreotika sugkekrimenou foititi(amka)
				FROM "Course" c, "Register" r 
				WHERE c.course_code = r.course_code AND obligatory AND r.register_status = 'pass' AND r.amka=st_amka);

END;
$$

LANGUAGE 'plpgsql' VOLATILE;

SELECT get_courses_notpass2_5(22);

-----------------------------------------------------------------
/* 2.6 */
CREATE OR REPLACE FUNCTION get_sector_mostDiploma2_6()
RETURNS TABLE (count bigint, sector_code integer) AS
$$
BEGIN
RETURN QUERY

SELECT b.count, b.sector_code
FROM(

SELECT count(*) as count, a.sector_code 
FROM "Diploma" d, (                  --apo tous supervisors pairnw to sector kathe diplwmatikis
				SELECT l.amka, r.sector_code   --sector kathigiti
				FROM   "Professor" l, "Lab"  r
				WHERE l."labJoins" = r.lab_code ) AS a
WHERE d.amka_super= a.amka
GROUP BY a.sector_code) AS b

WHERE b.count >= ALL (SELECT count(*) as count
					FROM "Diploma" d, (   --apo tous supervisors pairnw to sector kathe diplwmatikis
						SELECT l.amka, r.sector_code  --sector kathigiti
						FROM   "Professor" l, "Lab"  r
						WHERE l."labJoins" = r.lab_code ) AS a
					WHERE d.amka_super= a.amka
					GROUP BY a.sector_code);
					
END;
$$


LANGUAGE 'plpgsql' VOLATILE;

SELECT get_sector_mostDiploma2_6();

------------------------------------------------------------------
/* 2.7 */
CREATE OR REPLACE FUNCTION get_percPass2_7(academic_yr integer, academic_s semester_season_type)
RETURNS TABLE (course_code character(7), percentage numeric) AS
$$
BEGIN
RETURN QUERY


SELECT  Z.course_code, (Z.pass::decimal / (Z.pass + Z.fail)) * 100 as pososto  
FROM(

	SELECT *
	FROM(
	
	SELECT b.course_code, count(*) AS pass                 --posoi perasan ena mathima
	FROM(
		SELECT *                                           --pairnw tis va8mologies olwn twn mathimatwn gia sugkekrimeno eksamino
		FROM(
			SELECT *                                       --JOIN Register, Semester kai pairnw tis grammes pou exoyn final grade
			FROM "Register" r, "Semester" s
			WHERE r.serial_number = s.semester_id AND final_grade <> 11 ) AS a
		WHERE academic_year=academic_yr AND academic_season=academic_s) AS b
	WHERE b.final_grade>=5
	GROUP BY b.course_code) AS W

	 JOIN(


	SELECT b.course_code, count(*)  AS fail                --posoi kopikan se ena mathima
	FROM(
		SELECT *                                           --pairnw tis va8mologies olwn twn mathimatwn gia sugkekrimeno eksamino
		FROM(
			SELECT *                                       --JOIN Register, Semester kai pairnw tis grammes pou exoyn final grade
			FROM "Register" r, "Semester" s
			WHERE r.serial_number = s.semester_id AND final_grade <> 11 ) AS a
		WHERE academic_year=academic_yr AND academic_season=academic_s) AS b
	WHERE b.final_grade<5
	GROUP BY b.course_code) AS Q
	
	USING (course_code)) AS Z;
	

END;
$$
LANGUAGE 'plpgsql' VOLATILE; 

SELECT get_percPass2_7(2017, 'winter');

--------------------------------------------------------------------------
/* 2.8 */
CREATE OR REPLACE FUNCTION returnStudent_2_8()
RETURNS TABLE( am character(10)) AS
$$
BEGIN
RETURN QUERY



SELECT w.am                                                       --students pou exoyn tis proupo8eseis apofoitisis                 
FROM(
	(SELECT  r.amka, SUM(c.units), count(*) as  passed                           --posa epilogis exei perasei ka8e foititis
	FROM "Register" r, "Course" c
	WHERE r.course_code=c.course_code AND r.register_status='pass' AND c.obligatory='false'
	GROUP BY r.amka) as a

	INNER JOIN 

	(SELECT s.amka, s.am, g.min_courses, g.min_units            --return graduation rules for every student
	FROM "Student" s, "Graduation_rules" g
	WHERE extract(year from s.entry_date)= g.year_rules) as b
	
	using(amka)) AS w
WHERE w.passed>=w.min_courses AND w.sum>=w.min_units AND w.amka NOT IN(
					SELECT  d.amka                      --return all students have graduate
					FROM "Diploma" d, "Student" s
					WHERE d.amka=s.amka AND d.diploma_num<> 0
					);
					
END;
$$

LANGUAGE 'plpgsql' VOLATILE;

SELECT returnStudent_2_8();

--------------------------------------------------------------------
/* 2.9 */
CREATE OR REPLACE FUNCTION labstaff_hours_2_9()
RETURNS TABLE (amka integer, surname character(30), name character(30), hours bigint) AS

$$
BEGIN
RETURN QUERY


SELECT w.amka, w.surname, w.name, SUM(w.lab_hours) as hours   
FROM(
	SELECT *
	FROM "Course" c,
	
	(SELECT  q.course_code, q.amka, q.surname, q.name   --ergastiriako proswpiko to trexon eksamino
	FROM "Semester" s,
		(SELECT cr.course_code, l.amka, l.surname, l.name, cr.serial_number  --mathimata gia ka8e atomo ergastiriou
		FROM "CourseRun" cr , "LabStaff" l
		WHERE cr.labuses=l.labworks) as q
	WHERE s.semester_id= q.serial_number AND semester_status='present') as a
	
	WHERE c.course_code= a.course_code) as w
GROUP BY w.amka, w.surname, w.name;

END;
$$


LANGUAGE 'plpgsql' VOLATILE;

SELECT labstaff_hours_2_9();

