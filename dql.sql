-- 5、查询没学过“谌燕”老师课的同学的学号、姓名；

select sno,sname from student stu where stu.sno not in (
select distinct sno from sc left join course on sc.cno = course.cno
left join teacher on course.tno = teacher.tno and teacher.tname='谌燕');


-- 6、查询学过“c001”并且也学过编号“c002”课程的同学的学号、姓名；

select distinct stu.sno,stu.sname from student stu
    inner join sc on stu.sno = sc.sno and sc.cno = 'c001'
inner join sc scc on sc.sno = scc.sno and scc.cno = 'c002';


-- 20、统计列印各科成绩,各分数段人数:课程ID,课程名称,[100-85],[85-70],[70-60],[ <60]

select course.cname,
       sum(case when sc.score between 85 and 100 then 1 else 0 end) as "[100-85]",
       sum(case when sc.score between 70 and 85 then 1 else 0 end) as "[85-70]",
       sum(case when sc.score between 60 and 70 then 1 else 0 end) as "[70-60]",
       sum(case when sc.score between 0 and 60 then 1 else 0 end) as "[60-0]"
from sc join course on sc.cno = course.cno
group by sc.cno,course.cname;


-- 21、查询各科成绩前三名的记录:(不考虑成绩并列情况)

SELECT * FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY cno ORDER BY score DESC) as rn
    FROM sc
) t WHERE rn <= 3;

-- 44、查询两门以上不及格课程的同学的学号及其平均成绩

select sc.sno,avg(sc.score)
from sc
where sc.sno in 
(select sc.sno from sc where sc.score < 60 group by sc.sno having count(1) >= 2)
group by sc.sno;
