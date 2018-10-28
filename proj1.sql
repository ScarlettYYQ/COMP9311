-- COMP9311 18s1 Project 1
--
-- MyMyUNSW Solution Template


-- Q1:

create or replace view HDstudent20 as
select student
from (select student,count(course) as countcourse
from Course_enrolments
where mark>=85
group by student) as HDcourse
where countcourse > 20
;
create or replace view HDstudentID as
select id
from Students s,HDstudent20 h
where s.id = h.student and s.stype = 'intl'
;
create or replace view Q1(unswid, name) as
select unswid,name
from People ,HDstudentID
where People.id = HDstudentID.id
;



-- Q2:

create or replace view Meetingroom as
select id
from Room_types
where description = 'Meeting Room'
;
create or replace view CSBuilding as
select id
from Buildings
where name = 'Computer Science Building'
;
create or replace view Q2(unswid, name) as
select unswid,longname
from Rooms,Meetingroom,CSBuilding
where Rooms.building = CSBuilding.id and Rooms.rtype = Meetingroom.id and capacity >= 20
;

-- Q3:

create or replace view CourseStefan as
select course
from(select id
from People
where name = 'Stefan Bilek') as StudentStefan,Course_enrolments
where Course_enrolments.student = StudentStefan.id
;
create or replace view Q3(unswid, name) as
select unswid,name
from (select staff
from Course_staff,CourseStefan
where Course_staff.course = CourseStefan.course) as StaffStefan,People
where People.id = StaffStefan.staff
;

-- Q4:

create or replace view Comp3331ID as
select Courses.id as id
from Courses,(select id
from Subjects
where code='COMP3331') as COMP3331
where Courses.subject = COMP3331.id
;
create or replace view Comp3231ID as
select Courses.id as id
from Courses,(select id
from Subjects
where code='COMP3231') as COMP3231
where Courses.subject = COMP3231.id
;
create or replace view Comp3331student as
select student
from Course_enrolments,Comp3331ID
where Course_enrolments.course = Comp3331ID.id
;
create or replace view Q4(unswid, name) as
select unswid, name
from People,Comp3331student
where People.id= Comp3331student.student and not exists(select student
from Course_enrolments,Comp3231ID
where Course_enrolments.course = Comp3231ID.id and People.id= Course_enrolments.student)
;

-- Q5:

create or replace view SelectedprogramQ5a as
select partOf
from Stream_enrolments, (select id
from Streams
where name = 'Chemistry') as StreamsC
where Stream_enrolments.stream = StreamsC.id
;
create or replace view Selectedsemester as
select id
from Semesters
where year = 2011 and term = 'S1'
;
create or replace view Q5a(num) as
select count(distinct student)
from Program_enrolments p,SelectedprogramQ5a sp,Selectedsemester ss,(select id
from Students
where stype = 'local') as Local
where p.id = sp.partOf and p.semester = ss.id and p.student = Local.id
;

--Q5:

create or replace view SelectedprogramQ5b as
select Programs.id as id
from Programs, (select id
from OrgUnits
where longname = 'School of Computer Science and Engineering') as OrgUnitC
where Programs.OfferedBy = OrgUnitC.id
;
create or replace view Selectedsemester as
select id
from Semesters
where year = 2011 and term = 'S1'
;
create or replace view Q5b(num) as
select count(distinct student)
from Program_enrolments p,SelectedprogramQ5b sp,Selectedsemester ss,(select id
from Students
where stype = 'intl') as Intl
where p.program = sp.id and p.semester = ss.id and p.student = Intl.id
;

-- Q6:

create or replace function Q6(text) returns text as
$$
select code||' '||name||' '||uoc
from Subjects
where Subjects.code = $1
$$ language sql
;

-- Q7:

create or replace view StudentSum as
select count(student) as allstudent,program
from Program_enrolments
group by program
;
create or replace view StudentIntlSum as
select count(student) as intlstudent,program
from Program_enrolments,(select id
from students
where stype = 'intl') as IntlStudent
where Program_enrolments.student = IntlStudent.id
group by program
;
create or replace view Q7(code, name) as
select code,name
from Programs,(select s.program
from StudentSum s,StudentIntlSum i
where s.program = i.program and (i.intlStudent*1.0) / (s.allstudent*1.0) > 0.5) as Percent
where Programs.id = Percent.program
;

-- Q8:
create or replace view ExceptExtreme as
select count(mark) as effectivevalue,course
from Course_enrolments
group by course
;
create or replace view Ave as
select avg(mark) as averagemark ,Course_enrolments.course
from Course_enrolments,ExceptExtreme
where Course_enrolments.course=ExceptExtreme.course and ExceptExtreme.effectivevalue>=15
group by Course_enrolments.course
;
create or replace view Maxnum(averagemark) as
select MAX(a.averagemark)
from Ave as a
;
create or replace view Max as
select course
from Ave,Maxnum
where Ave.averagemark = Maxnum.averagemark
;
create or replace view Q8(code, name, semester) as
select Subjects.code,Subjects.name,Semesters.name
from Subjects,Semesters,Max,Courses
where Courses.id=Max.course and Courses.subject=Subjects.id and Courses.semester= Semesters.id
;

--Q9
create or replace view HeadOfSchool as
select Affiliations.staff,OrgUnits.longname,Affiliations.starting
from Affiliations,staff_roles,OrgUnits,OrgUnit_types
where OrgUnit_types.name='School' and OrgUnit_types.id=OrgUnits.utype
and staff_roles.name='Head of School' and Affiliations.role = staff_roles.id
and Affiliations.orgUnit=OrgUnits.id and Affiliations.ending is NULL
and Affiliations.isPrimary is true
;
create or replace view Num_subjects as
select HeadOfSchool.staff,count(distinct Subjects.code) as num_subject
from HeadOfSchool,Course_staff,Courses,Subjects
where HeadOfSchool.staff= Course_staff.staff
and Course_staff.course=Courses.id
and Courses.subject= Subjects.id
group by HeadOfSchool.staff
;
create or replace view Q9(name, school, email, starting, num_subjects) as
select People.name,HeadOfSchool.longname,People.email,HeadOfSchool.starting,Num_subjects.num_subject
from HeadOfSchool,Num_subjects,People
where HeadOfSchool.staff= People.id
and Num_subjects.staff = HeadOfSchool.staff
;

--Q10
create or replace view COMP93 as
select id,code,name
from Subjects
where code like 'COMP93%'
;
create or replace view In2003_2012S1 as
select id,year,term
from Semesters
where (year<=2012 and year>=2003 and term='S1')
;
create or replace view In2003_2012S2 as
select id,year,term
from Semesters
where (year<=2012 and year>=2003 and term='S2')
;
create or replace view RightsubjectS1 as
select code,name,subject,count(Courses.id)
from Courses,COMP93,In2003_2012S1
where subject=COMP93.id
and semester=In2003_2012S1.id
group by subject,code,name
having count(Courses.id)=10
;
create or replace view RightsubjectS2 as
select code,name,subject,count(Courses.id)
from Courses,COMP93,In2003_2012S2
where subject=COMP93.id
and semester=In2003_2012S2.id
group by subject,code,name
having count(Courses.id)=10
;
create or replace view Rightsubject as
select RightsubjectS1.code,RightsubjectS1.subject
from RightsubjectS1 join RightsubjectS2 on RightsubjectS1.code=RightsubjectS2.code
;
create or replace view TotalmarkS1 as
select code,Rightsubject.subject,Courses.id,count(mark) as marktotal,Courses.semester
from Rightsubject,Courses,Course_enrolments,In2003_2012S1
where Rightsubject.subject=Courses.subject
and Courses.id=Course_enrolments.course
and mark>=0
and Courses.semester=In2003_2012S1.id
group by code,Rightsubject.subject,Courses.id,Courses.semester
order by code asc
;
create or replace view HDmarkS1 as
select code,Rightsubject.subject,Courses.id,count(mark) as markhd,Courses.semester
from Rightsubject,Courses,Course_enrolments,In2003_2012S1
where Rightsubject.subject=Courses.subject
and Courses.id=Course_enrolments.course
and mark>=85
and Courses.semester=In2003_2012S1.id
group by code,Rightsubject.subject,Courses.id,Courses.semester
order by code asc
;
create or replace view TotalandHDS1 as
select TotalmarkS1.code,TotalmarkS1.subject,TotalmarkS1.marktotal,(case when HDmarkS1.markhd is null then 0 else HDmarkS1.markhd end) as markhd,TotalmarkS1.semester,TotalmarkS1.id
from TotalmarkS1 left join HDmarkS1 on HDmarkS1.id=TotalmarkS1.id
;
create or replace view TotalmarkS2 as
select code,Rightsubject.subject,Courses.id,count(mark) as marktotal,Courses.semester
from Rightsubject,Courses,Course_enrolments,In2003_2012S2
where Rightsubject.subject=Courses.subject
and Courses.id=Course_enrolments.course
and mark>=0
and Courses.semester=In2003_2012S2.id
group by code,Rightsubject.subject,Courses.id,Courses.semester
order by code asc
;
create or replace view HDmarkS2 as
select code,Rightsubject.subject,Courses.id,count(mark) as markhd,Courses.semester
from Rightsubject,Courses,Course_enrolments,In2003_2012S2
where Rightsubject.subject=Courses.subject
and Courses.id=Course_enrolments.course
and mark>=85
and Courses.semester=In2003_2012S2.id
group by code,Rightsubject.subject,Courses.id,Courses.semester
order by code asc
;
create or replace view TotalandHDS2 as
select TotalmarkS2.code,TotalmarkS2.subject,TotalmarkS2.marktotal,(case when HDmarkS2.markhd is null then 0 else HDmarkS2.markhd end) as markhd,TotalmarkS2.semester,TotalmarkS2.id
from TotalmarkS2 left join HDmarkS2 on HDmarkS2.id=TotalmarkS2.id
;
create or replace view S1_HD_rate as
select TotalandHDS1.code,TotalandHDS1.subject,to_char(year % 100,'FM00') as year, (markhd*1.0 / marktotal*1.0) as hd_rate,TotalandHDS1.id
from TotalandHDS1 join Semesters on TotalandHDS1.semester=Semesters.id
;
create or replace view S2_HD_rate as
select TotalandHDS2.code,TotalandHDS2.subject,to_char(year % 100,'FM00') as year, (markhd*1.0 / marktotal*1.0) as hd_rate,TotalandHDS2.id
from TotalandHDS2 join Semesters on TotalandHDS2.semester=Semesters.id
;
create or replace view Q10(code, name, year, s1_HD_rate, s2_HD_rate) as
select S1_HD_rate.code,Subjects.name,S1_HD_rate.year,S1_HD_rate.hd_rate::numeric (4,2) as s1_hd_rate,S2_HD_rate.hd_rate::numeric (4,2) as s2_hd_rate
from S1_HD_rate,S2_HD_rate,Subjects
where S1_HD_rate.code=S2_HD_rate.code
and S1_HD_rate.year=S2_HD_rate.year
and S1_HD_rate.subject=Subjects.id
order by S1_HD_rate.code
;

