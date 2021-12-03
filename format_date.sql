select min(STRFTIME('%Y-%m-%d', submission_date)) from Cases
order by STRFTIME('%Y-%m-%d', submission_date)
select min(submission_date) from Cases
select 
case length(submission_date)
when 8 THEN substr(submission_date, 5, 4) || '-' || '0' || substr(submission_date, 1,1) || '-' || '0' || substr(submission_date, 3,1)
when 10 THEN substr(submission_date, 7, 4) || '-' || substr(submission_date, 1,2) || '-' || substr(submission_date, 4,2) 
when 9 THEN
case instr(submission_date, '/')
when 2 then substr(submission_date, 6, 4) || '-' || '0' || substr(submission_date, 1,1) || '-' || substr(submission_date, 3,2)
when 3 then substr(submission_date, 6, 4) || '-' || substr(submission_date, 1,2) || '-' || '0' || substr(submission_date, 2,1)
END
else submission_date
end ab
from Cases

update cases 
set submission_date = case length(submission_date)
when 8 THEN substr(submission_date, 5, 4) || '-' || '0' || substr(submission_date, 1,1) || '-' || '0' || substr(submission_date, 3,1)
when 10 THEN substr(submission_date, 7, 4) || '-' || substr(submission_date, 1,2) || '-' || substr(submission_date, 4,2) 
when 9 THEN
case instr(submission_date, '/')
when 2 then substr(submission_date, 6, 4) || '-' || '0' || substr(submission_date, 1,1) || '-' || substr(submission_date, 3,2)
when 3 then substr(submission_date, 6, 4) || '-' || substr(submission_date, 1,2) || '-' || '0' || substr(submission_date, 2,1)
END
else submission_date
end 

update Vaccination
set date = case length(date)
when 8 THEN substr(date, 5, 4) || '-' || '0' || substr(date, 1,1) || '-' || '0' || substr(date, 3,1)
when 10 THEN substr(date, 7, 4) || '-' || substr(date, 1,2) || '-' || substr(date, 4,2) 
when 9 THEN
case instr(date, '/')
when 2 then substr(date, 6, 4) || '-' || '0' || substr(date, 1,1) || '-' || substr(date, 3,2)
when 3 then substr(date, 6, 4) || '-' || substr(date, 1,2) || '-' || '0' || substr(date, 2,1)
END
else date
end 