create view [plot_data] as
select a.state, strftime('%Y-%m', a.submission_date) as Month, sum(a.new_case) as new_case, sum(a.new_death) as new_death, b.total_vac, f.tot_cases, f.tot_death, b.population, cast(b.total_vac as float)/cast(b.population as float) as vac_pop, cast(f.tot_cases as float)/cast(b.population as float) as cases_pop, cast(f.tot_death as float)/cast(b.population as float) as death_pop from Cases a
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

select * from plot_data
where Month = '2021-10' and population is not NULL and vac_pop != 0 and vac_pop>0.5

----------------------------------------------
----------------------------------------------
select month, MMWRweek, Weekdate, Agegroup, Vaccinatedwithoutcome, Unvaccinatedwithoutcome from Rates
where Agegroup != 'all_ages_adj' and Vaccineproduct = 'all_types' and outcome = 'case'