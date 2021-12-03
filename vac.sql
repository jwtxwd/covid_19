
select a.Recip_State as ID, sum(a.Series_Complete_Yes) as vac, b.population, round(cast(sum(a.Series_Complete_Yes) as float)/cast(b.population as float), 4) as vac_pct from Vaccination a
join geo_states b on a.Recip_State = b.abv
where date = '2021-01-31' 
group by Recip_State

select * from Vaccination
where Recip_State = 'TX' and date = '2021-09-26' 

select a.state, a.Month, sum(b.Series_Complete_Yes) as total_vac, c.population, d.new_case from(
SELECT recip_state as state, max(date) as max_date, strftime('%Y-%m', Date) as Month from Vaccination a 
where Month is NOT NULL
group by recip_state, Month
) a
join vaccination b on a.state=b.recip_state and a.max_date = b.date
join geo_states c on a.state = c.abv
group by a.state,a.Month

select a.state, strftime('%Y-%m', a.submission_date) as Month, sum(a.new_case) as new_case, sum(a.new_death) as new_death, b.total_vac, f.tot_cases, f.tot_death, b.population from Cases a
left join(
select a.state, a.Month, sum(b.Series_Complete_Yes) as total_vac, c.population from(
SELECT recip_state as state, max(date) as max_date, strftime('%Y-%m', Date) as Month from Vaccination a 
where Month is NOT NULL
group by recip_state, Month
) a
join vaccination b on a.state=b.recip_state and a.max_date = b.date
left join geo_states c on a.state = c.abv
group by a.state,a.Month
) b on a.state = b.state and strftime('%Y-%m', a.submission_date) = b.month
join (
select b.state, b.month, c.tot_cases, c.tot_death from cases c
join (
select a.state, strftime('%Y-%m', a.submission_date) as Month, max(a.submission_date) as max_date from Cases a
where strftime('%Y-%m', a.submission_date) is not null
group by a.state, strftime('%Y-%m', a.submission_date)
) b on c.submission_date = b.max_date and c.state = b.state
order by b.state, b.month
) f on a.state = f.state and strftime('%Y-%m', a.submission_date) = f.month
where strftime('%Y-%m', submission_date) is not null
group by a.state, strftime('%Y-%m', submission_date)


select b.state, b.month, c.tot_cases, c.tot_death from cases c
join (
select a.state, strftime('%Y-%m', a.submission_date) as Month, max(a.submission_date) as max_date from Cases a
where strftime('%Y-%m', a.submission_date) is not null
group by a.state, strftime('%Y-%m', a.submission_date)
) b on c.submission_date = b.max_date and c.state = b.state
order by b.state, b.month