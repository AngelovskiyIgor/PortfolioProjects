---------------------------------------------------------------------------------------------------------------------
------ Gray Water Project
------ Analyzing potential of using gray water in agriculture
---------------------------------------------------------------------------------------------------------------------

/* Data: 
* annual freashwater withdrawals by country, 
* annual agriculture water withdrowal by country as a share of total withrawal
* annual municipal water withdrawal by country as a share of total withrawal

** source: https://ourworldindata.org/water-use-stress

--- Important disclaimer ---
*** for this analysis we used estimate of 75 % - gray water as a share in municapal water waithrowal
***Gray water is the relatively clean waste water from baths, sinks, washing machines, and other kitchen appliances.

*/

---------------------------------------------------------------------------------------------------------------------
------ Data exploration

Select *
From GrayWaterProject..[annual-freshwater-withdrawals]

Select *
From GrayWaterProject..[agricultural]

Select *
From GrayWaterProject..[municipal]

---------------------------------------------------------------------------------------------------------------------
------ Data cleaning

-- Let's change the names of the columns and delete those which we don't need

sp_rename '[annual-freshwater-withdrawals].["Annual freshwater withdrawals]', 'annual_withdrawal', 'COLUMN';

alter table [annual-freshwater-withdrawals]
drop column Code, [ total (billion cubic meters)"]

sp_rename '[agricultural].["Annual freshwater withdrawals]', 'agricultural_percent', 'COLUMN';

alter table [agricultural]
drop column Code, [ agriculture (% of total freshwater withdrawal)"]

sp_rename '[municipal].["Annual freshwater withdrawals]', 'municipal_percent', 'COLUMN';

alter table [municipal]
drop column Code, [ domestic (% of total freshwater withdrawal)"]


---------------------------------------------------------------------------------------------------------------------
------ Data analysis

-- Data in the tables are not presented for each year. To get more complete picture we need to select a particular year
-- This year should correspond to the highest number of observations in each table

-- Let's find this year

select year, count(year) as obs_count
from GrayWaterProject..[annual-freshwater-withdrawals]
group by year
order by obs_count desc

-- Year 2017 has the highest number of observations in [annual-freshwater-withdrawals]

select year, count(year) as obs_count
from GrayWaterProject..[agricultural]
group by year
order by obs_count desc

-- Year 2017 has the highest number of observations in [agricultural]

select year, count(year) as obs_count
from GrayWaterProject..[municipal]
group by year
order by obs_count desc

-- Year 2017 has the highest number of observations in [municipal]

-- We deided to use the data for 2017 for further analysis because it has the highest number of observations in all 3 tables

-- Let's create a table that will have information on annual freshwater withdrawal, agricultural withdrawal (%), and municipal withdrawal (%)

select c.entity, c.year, c.annual_withdrawal, c.agricultural_percent, d.municipal_percent
INTO water_withdrawals
from (
select a.entity, a.year, a.annual_withdrawal, b.agricultural_percent
from GrayWaterProject..[annual-freshwater-withdrawals] as a
JOIN GrayWaterProject..agricultural as b
ON a.entity = b.entity
where a.year = 2017 and b.year = 2017) as c
JOIN GrayWaterProject..municipal as d
ON c.entity = d.entity
where c.year = 2017 and d.year = 2017

-- Checking for changes

select *
from GrayWaterProject..water_withdrawals

-- To perform further calculations we need to change data types of annual_withdrawals, agricultural_percent, and municipal_precent

ALTER TABLE GrayWaterProject..water_withdrawals
ALTER COLUMN annual_withdrawal numeric(30)
ALTER TABLE GrayWaterProject..water_withdrawals
ALTER COLUMN agricultural_percent numeric(30)
ALTER TABLE GrayWaterProject..water_withdrawals
ALTER COLUMN municipal_percent numeric(30)

-- let's add columns with absolute values:

ALTER TABLE GrayWaterProject..water_withdrawals
ADD agricultural_mcub numeric(30), municipal_mcub numeric(30), gray_mcub numeric(30), gray_vs_agri_perc numeric(30)

-- Checking for changes

select *
from GrayWaterProject..water_withdrawals

-- Let's calculate water withdrawals in m3

UPDATE GrayWaterProject..water_withdrawals
set agricultural_mcub = (agricultural_percent * annual_withdrawal /100)

UPDATE GrayWaterProject..water_withdrawals
set municipal_mcub = (annual_withdrawal * municipal_percent / 100)

UPDATE GrayWaterProject..water_withdrawals
set gray_mcub = (municipal_mcub * 0.75)


-- Let's calculate how gray water could potentially cover agriculture water withdrawal (in %)

UPDATE GrayWaterProject..water_withdrawals
set gray_vs_agri_perc = case
when agricultural_mcub = 0 then 0
when agricultural_mcub <> 0 then (gray_mcub / agricultural_mcub)*100
end

-- Checking for changes

select *
from GrayWaterProject..water_withdrawals

-- What countries have the highest potential of using gray water in agriculture

select *
from GrayWaterProject..water_withdrawals
order by gray_vs_agri_perc desc

-- What countries have the highest potential of using gray water in agriculture + where usage of water in agriculture >= 10%

select *
from GrayWaterProject..water_withdrawals
where agricultural_percent >= 10
order by gray_vs_agri_perc desc