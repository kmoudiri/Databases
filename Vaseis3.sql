/* 3.1 */
CREATE TRIGGER update_semester_3_1 
BEFORE INSERT ON "Semester"
FOR EACH ROW
EXECUTE PROCEDURE insert_semester();


CREATE OR REPLACE FUNCTION insert_semester()
   RETURNS TRIGGER AS
   $$
   BEGIN
   IF (NOT EXISTS(select * from "Semester" where (NEW.start_date>=start_date AND NEW.start_date<=end_date) OR (NEW.end_date>=start_date AND NEW.end_date<=end_date))) THEN
   
   IF ( ( (SELECT start_date FROM "Semester" WHERE semester_status = 'present' ) > NEW.end_date AND NEW.semester_status = 'past') 
   OR ( (SELECT end_date FROM "Semester" WHERE semester_status = 'present' ) < NEW.start_date AND NEW.semester_status = 'future') ) THEN
   return new;
   ELSE
      RAISE EXCEPTION 'ERROR SEMESTER STATUS';
   END IF;
   ELSE
   raise exception 'ERROR DATE';
   END IF;
END;
$$
LANGUAGE 'plpgsql' VOLATILE;

/*
INSERT INTO "Semester" (semester_id,academic_year,academic_season,start_date,end_date,semester_status)
VALUES
 (33,2020,'winter','2050-09-5','2051-01-01','past');


INSERT INTO "Semester" (semester_id,academic_year,academic_season,start_date,end_date,semester_status)
VALUES
 (30,2020,'winter','2020-09-5','2021-01-01','future'); */
 
 ---------------------------------------------------------------------------------------------
 /* 3.2 */
CREATE TRIGGER insert_final_grade_3_2
BEFORE INSERT OR UPDATE
ON "Semester"
FOR EACH ROW
EXECUTE PROCEDURE Students_grades();

CREATE OR REPLACE FUNCTION Students_grades()
RETURNS TRIGGER AS
$$
BEGIN



IF(	
	SELECT semester_status
	FROM "Semester"
	WHERE semester_status='present' AND NEW.semester_status='past') IS NOT NULL THEN
	
UPDATE "Register" r                                    --final grades gia mh ergastiriaka mathimata
SET final_grade = exam_grade
WHERE r.amka is not null AND final_grade is null AND r.course_code NOT IN(
												SELECT c.course_code                                 --ola ta ergastiriaka ma8imata
												FROM "Course" c, "Register" r
												WHERE c.course_code = r.course_code AND c.lab_hours>0);
												
UPDATE "Register" r                                    --final grades gia ergastiriaka mathimata
SET final_grade = (exam_percentage * exam_grade) + ((1-exam_percentage)*lab_grade)
FROM (SELECT * FROM "CourseRun" ) AS cr
WHERE r.amka is not null  AND r.exam_grade > cr.exam_min AND r.lab_grade > cr.lab_min AND r.course_code IN(
																									SELECT c.course_code                                 --ola ta ergastiriaka ma8imata
																									FROM "Course" c, "Register" r
																									WHERE c.course_code = r.course_code AND c.lab_hours>0);
UPDATE "Register" r                                    --final grades gia ergastiriaka mathimata
SET final_grade = 0                                   --kovoume osous den exoun prosvasimo va8mo
FROM (SELECT * FROM "CourseRun" ) AS cr
WHERE r.amka is not null  AND (r.exam_grade < cr.exam_min OR r.lab_grade < cr.lab_min) AND r.course_code IN(
																									SELECT c.course_code                                 --ola ta ergastiriaka ma8imata
																									FROM "Course" c, "Register" r
																									WHERE c.course_code = r.course_code AND c.lab_hours>0);
END IF;

UPDATE "Register" r
SET register_status = 'pass'
WHERE final_grade>=5;

UPDATE "Register" r
SET register_status = 'fail'
WHERE final_grade<5;

RETURN NEW;
END;
$$

LANGUAGE 'plpgsql' VOLATILE;

---------------------------------------------------------------
/* 3.3 */
CREATE TRIGGER register_3_3
BEFORE INSERT OR UPDATE
ON "Register"
FOR EACH ROW
EXECUTE PROCEDURE check_stud_reg();

CREATE OR REPLACE FUNCTION check_stud_reg()
RETURNS TRIGGER AS
$$
BEGIN

IF ((OLD.register_status = 'proposed' OR OLD.register_status = 'requested') AND NEW.register_status = 'approved') IS NOT NULL THEN

-- elegxoume an uparxei proapaitoumeno
IF  ( SELECT main FROM "Course_depends" WHERE  dependent = OLD.course_code AND mode = 'required' ) IS NOT NULL THEN 
	--elegxoume an exei perasei to proapaitoumeno
	IF ( SELECT register_status FROM "Register" WHERE amka = OLD.amka AND course_code = ( SELECT main FROM "Course_depends" WHERE  dependent = OLD.course_code AND mode = 'required') )!= 'pass'
								  OR  ( SELECT register_status FROM "Register" WHERE amka = OLD.amka AND course_code = ( SELECT main FROM "Course_depends" WHERE  dependent = OLD.course_code AND mode = 'required')) IS NULL THEN
									NEW.register_status = 'rejected';
									RETURN NEW;
	END IF;
END IF;

--max units = 35
IF (SELECT SUM(units) FROM "Register" r JOIN "Course" c  USING (course_code)
					WHERE amka=OLD.amka AND serial_number=OLD.serial_number) > 35 THEN
	NEW.register_status = 'rejected';
	RETURN NEW;
END IF;	

--max number of courses = 8
IF (SELECT count(*) FROM "Register"
					WHERE amka=OLD.amka AND serial_number=OLD.serial_number) > 8 THEN
	NEW.register_status = 'rejected';
	RETURN NEW;
END IF;						



END IF;
RETURN NEW;


END;
$$

LANGUAGE 'plpgsql' VOLATILE;

