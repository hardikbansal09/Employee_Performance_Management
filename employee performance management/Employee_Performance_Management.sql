CREATE DATABASE  Employee_Performance_Management;


-- Permanent tables
create table Employees(
EmployeeID int not null,
Name varchar(50),
Department varchar(50),
Role varchar(50),
JoinDate date not null,
Salary int not null
);

create table Attendance(
EmployeeID int not null,
Date date not null,
CheckInTime time,
CheckOutTime time 
);

create table PerformanceReviews(
EmployeeID int not null,
ReviewDate date not null,
FeedbackScore decimal,
Reviewer varchar(40) 
);


create table Tasks(
TaskID int not null,
EmployeeID int not null,
AssignedDate date not null,
Deadline date not null,
Status varchar(50)
);

-- Temporary table for the storage of the data
create table TempTasks(
TaskID int not null,
EmployeeID int not null,
AssignedDate date not null,
Deadline date not null,
Status varchar(50)
);

-- insert the data from temporary to permanet table
INSERT INTO Tasks (TaskID, EmployeeID, AssignedDate, Deadline, Status)
SELECT 
	TaskID,
    EmployeeID,
	STR_TO_DATE(AssignedDate, '%Y-%m-%d'),    
    STR_TO_DATE(Deadline, '%Y-%m-%d'),
    Status
FROM TempTasks;

-- Retrieve all employees from the IT department.
select * from employees
where Department= 'IT';

-- Find the average salary of employees in each department
select Department,avg(Salary)
from employees
group by Department;

-- Calculate the total number of attendance entries for each employee.
select EmployeeID, count(*)
from attendance
group by EmployeeID;

-- Count the total number of tasks assigned to each employee
select EmployeeId, count(*)
from tasks
group by EmployeeID;

-- Find the top 5 employees with the highest average feedback score
select EmployeeID,avg(FeedbackScore) as AvgScore
from performancereviews
group by EmployeeID
order by AvgScore desc limit 5;

-- Calculate the total working hours for each employee
select EmployeeID, abs(sum(time_to_sec(timediff(CheckOutTime, CheckInTime))/3600)) as totalhours
from attendance
group by EmployeeID;

-- Identify employees who have more than 5 overdue tasks
select EmployeeID, count(*) as overdues
from tasks
where Status='Overdue'
group by EmployeeID
having overdues > 5;

-- Find the names of employees who have the highest total tasks completed.
select e.Name,count(t.TaskID) as TaskCompeted
from employees as e
join tasks as t
on e.EmployeeID=t.EmployeeID
where t.Status='Completed'
group by e.Name
order by TaskCompeted desc;

-- Determine the department with the highest average performance score.
select employees.Department,avg(performancereviews.FeedbackScore) as average_performance
from employees join performancereviews 
on employees.EmployeeID=performancereviews.EmployeeID
group by employees.Department
order by average_performance desc;

-- Identify employees with the most overtime hours in the last 3 months.
SELECT EmployeeID, 
       SUM(TIME_TO_SEC(TIMEDIFF(CheckOutTime, CheckInTime))/3600 - 8) AS OvertimeHours 
FROM Attendance 
WHERE Date >= CURDATE() - INTERVAL 3 MONTH 
      AND TIME_TO_SEC(TIMEDIFF(CheckOutTime, CheckInTime))/3600 > 8 
GROUP BY EmployeeID 
ORDER BY OvertimeHours DESC;

-- Investigate the correlation between salary and performance score.
SELECT e.Salary, 
       (0.5 * AVG(p.FeedbackScore) + 0.3 * COUNT(t.TaskID) + 0.2 * COUNT(a.Date)) AS PerformanceScore 
FROM Employees e 
LEFT JOIN PerformanceReviews p ON e.EmployeeID = p.EmployeeID 
LEFT JOIN Tasks t ON e.EmployeeID = t.EmployeeID 
LEFT JOIN Attendance a ON e.EmployeeID = a.EmployeeID 
GROUP BY e.Salary;

-- Calculate a performance score for each employee using:
-- Weighted feedback score (50%)
-- Total tasks completed (30%)
-- Attendance rate (20%)
WITH AttendanceRate AS (
    SELECT EmployeeID, 
           COUNT(DISTINCT Date)*100.0/(SELECT COUNT(DISTINCT Date) FROM Attendance) AS AttendancePercent 
    FROM Attendance 
    GROUP BY EmployeeID
),
TaskCompletion AS (
    SELECT EmployeeID, COUNT(*) AS CompletedTasks 
    FROM Tasks 
    WHERE Status = 'Completed' 
    GROUP BY EmployeeID
),
AvgFeedback AS (
    SELECT EmployeeID, AVG(FeedbackScore) AS AvgScore 
    FROM PerformanceReviews 
    GROUP BY EmployeeID
)
SELECT e.Name, 
       (0.5 * a.AvgScore + 0.3 * t.CompletedTasks + 0.2 * ar.AttendancePercent) AS PerformanceScore 
FROM Employees e
LEFT JOIN AvgFeedback a ON e.EmployeeID = a.EmployeeID
LEFT JOIN TaskCompletion t ON e.EmployeeID = t.EmployeeID
LEFT JOIN AttendanceRate ar ON e.EmployeeID = ar.EmployeeID
ORDER BY PerformanceScore DESC;
