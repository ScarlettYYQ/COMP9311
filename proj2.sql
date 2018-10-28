--Q1:

drop type if exists RoomRecord cascade;
create type RoomRecord as (valid_room_number integer, bigger_room_number integer);
create or replace function Q1(course_id integer)
    returns RoomRecord
as $$
declare
    roomid RoomRecord;
    count1 integer;
    count2 integer;
    roomcount1 integer;
    roomcount2 integer;
begin
    if ($1 in (select id from Courses)) then
        count1 := (select count(student) from Course_enrolments where course=$1);
        count2 :=(select count(student) from Course_enrolment_waitlist where course=$1);
        roomcount1 :=(select count(id) from Rooms where capacity>count1);
        roomcount2 :=(select count(id) from Rooms where capacity > count1+count2);
        roomid.valid_room_number := roomcount1;
        roomid.bigger_room_number := roomcount2;
        return roomid;
    else
        raise exception 'INVALID COURSEID';
    end if;
end;
$$ language plpgsql;


--Q2:
drop type if exists TeachingRecord cascade;
create type TeachingRecord as (cid integer, term char(4), code char(8), name text, uoc integer, average_mark integer, highest_mark integer, median_mark integer, totalEnrols integer);
create or replace view SemesterResult as
select Courses.id as id,lower(to_char(year % 100,'FM00')||term) as year
from Semesters,Courses
where Courses.semester=Semesters.id
;
create or replace function Q2(staff_id integer)
	returns setof TeachingRecord
as $$
declare
teachR TeachingRecord;
t record;
begin
if $1 in (select id from staff) then
for t in (select Course_staff.course as course from Course_staff,Course_enrolments where Course_staff.course=Course_enrolments.course and Course_staff.staff=$1 group by Course_staff.course having count(Course_enrolments.mark)>0 order by Course_staff.course asc)
loop
    teachR.cid=t.course;
    teachR.term=(select year from SemesterResult where SemesterResult.id=t.course);
    teachR.code=(select code from Courses,Subjects where Courses.subject=Subjects.id and Courses.id=t.course);
    teachR.name=(select name from Courses,Subjects where Courses.subject=Subjects.id and Courses.id=t.course);
    teachR.uoc=(select (case when uoc is null then null else uoc end)from Courses,Subjects where Courses.subject=Subjects.id and Courses.id=t.course);
    teachR.average_mark=(select round(avg(mark)) from Course_enrolments where course_enrolments.course=t.course and mark is not null group by course_enrolments.course);
    teachR.highest_mark=(select max(mark) from Course_enrolments where course_enrolments.course=t.course group by course_enrolments.course);
    teachR.totalEnrols=(select count(mark)from Course_enrolments where course_enrolments.course=t.course and mark is not null group by course_enrolments.course);
    teachR.median_mark=(select * from Median(t.course,teachR.totalEnrols));
    return next teachR;
end loop;
else
    raise exception 'INVALID STAFFID';
end if;
end;
$$ language plpgsql;

create or replace function Median(course integer,totalEnrols integer)
returns integer
as $$
declare
i record;
rank integer :=1;
median integer :=0;
temp_median integer :=0;
begin
for i in (select mark from Course_enrolments where course_enrolments.course=$1 and mark is not null order by course_enrolments.mark asc)
loop
    if $2 % 2 = 0 then
        if rank=$2/2 then
            temp_median := temp_median+i.mark;
        end if;
        if rank = $2/2+1 then
            median=round((temp_median+i.mark)/2);
        end if;
    else
        if rank=(($2+1)/2) then
            median=i.mark;
        end if;
    end if;
    rank:=rank+1;
end loop;
return median;
end;
$$ language plpgsql;


--Q3:

drop type if exists CourseRecord cascade;
create type CourseRecord as (unswid integer, student_name text, course_records text);

create or replace function Q3(org_id integer, num_courses integer, min_score integer)
  returns setof CourseRecord
as $$
declare
i record;
courseR CourseRecord;
num integer;
c record;
courserecordtemp text :='';
begin
if $1 not in (select owner from orgunit_groups) TeachingRecord then
    raise exception 'INVALID ORGID';
else
    
    for i in with sub_org as (select orgunit_groups.member from orgunit_groups where orgunit_groups.owner=$1)
            select distinct temptable.unswid as unswid 
            from (select people.unswid from orgunits join orgunit_groups on orgunits.id=orgunit_groups.member join subjects on orgunits.id=subjects.offeredby 
                join courses on subjects.id=courses.subject join course_enrolments on courses.id=course_enrolments.course join people on course_enrolments.student=people.id join sub_org on orgunits.id=sub_org.member
                where orgunit_groups.owner=$1 group by people.unswid having count(distinct courses.id)>$2 order by people.unswid asc) as temptable 

                ,(select people.unswid,course_enrolments.mark from orgunits join orgunit_groups on orgunits.id=orgunit_groups.member join subjects on orgunits.id=subjects.offeredby 
                join courses on subjects.id=courses.subject join course_enrolments on courses.id=course_enrolments.course join people on course_enrolments.student=people.id join sub_org on orgunits.id=sub_org.member
                where orgunit_groups.owner=$1 and course_enrolments.mark>=$3) as temptable2 
             where temptable.unswid=temptable2.unswid
            group by temptable.unswid
            having count(temptable2.mark)>0
    loop
        num=0;
        courserecordtemp:='';
        courseR.unswid=i.unswid;
        courseR.student_name=(select name from people where people.unswid=i.unswid);
        for c in with sub_org as (select orgunit_groups.member from orgunit_groups where orgunit_groups.owner=$1)
                (select(code||', '||subject_name||', '||semester_name||', '||orgunit_name||', '||(case when mark is null then 'null' else concat(mark) end)) as record 
                    from (select code,subjects.name as subject_name ,semesters.name as semester_name,orgunits.name as orgunit_name,course_enrolments.mark 
                    from orgunits join orgunit_groups on orgunits.id=orgunit_groups.member join subjects on orgunits.id=subjects.offeredby join courses on subjects.id=courses.subject
                    join course_enrolments on courses.id=course_enrolments.course join people on course_enrolments.student=people.id join semesters on courses.semester= semesters.id join sub_org on orgunits.id=sub_org.member
                    where orgunit_groups.owner=$1  and people.unswid=i.unswid order by case when course_enrolments.mark is null then -1 else course_enrolments.mark end desc,courses.id) as temptable3)
        loop
        num=num+1;
        if num <= 5 then 
        courserecordtemp:=courserecordtemp||c.record||E'\n';
        end if;
        end loop;
        courseR.course_records=courserecordtemp;
        return next courseR;
    end loop;
end if;
end;
$$ language plpgsql;

















