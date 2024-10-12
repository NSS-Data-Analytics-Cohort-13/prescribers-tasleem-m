--q1 Which prescriber had the highest total number of claims (totaled over all drugs)?
SELECT npi, pscrbe.nppes_provider_last_org_name, pscrbe.nppes_provider_first_name, pscrbe.specialty_description, SUM (pscrpt.total_claim_count) AS total_claims
FROM prescription AS pscrpt
INNER JOIN prescriber AS pscrbe
USING (npi)
GROUP BY npi, pscrbe.nppes_provider_last_org_name, pscrbe.nppes_provider_first_name, pscrbe.specialty_description
ORDER BY total_claims DESC
LIMIT 1
--answer: Pendley, Bruce

--q2 a. Which specialty had the most total number of claims (totaled over all drugs)?
SELECT pscrbe.specialty_description, SUM (pscrpt.total_claim_count) AS total_claims
FROM prescription AS pscrpt
INNER JOIN prescriber AS pscrbe
USING (npi)
GROUP BY pscrbe.specialty_description
ORDER BY total_claims DESC
LIMIT 1
--answer: Family Practice

--b. Which specialty had the most total number of claims for opioids?
SELECT pscrbe.specialty_description, SUM (pscrpt.total_claim_count) AS total_claims
FROM prescription AS pscrpt
INNER JOIN prescriber AS pscrbe
USING (npi)
INNER JOIN drug AS d
USING (drug_name)
WHERE d.opioid_drug_flag = 'Y'
GROUP BY pscrbe.specialty_description
ORDER BY total_claims DESC
LIMIT 1
--answer: Nurse Practitioner

--c. Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?
SELECT pscrbe.specialty_description, SUM (pscrpt.total_claim_count) AS total_claims
FROM prescription AS pscrpt
RIGHT JOIN prescriber AS pscrbe
USING (npi)
GROUP BY pscrbe.specialty_description
ORDER BY total_claims DESC
LIMIT 15

--d. For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?
SELECT pscrbe.specialty_description, 
	ROUND (AVG(CASE WHEN d.opioid_drug_flag = 'Y' THEN pscrpt.total_claim_count 
					WHEN d.opioid_drug_flag = 'N' THEN pscrpt.total_claim_count
					END), 2) AS total
FROM prescription AS pscrpt
INNER JOIN prescriber AS pscrbe
USING (npi)
INNER JOIN drug AS d
USING (drug_name)
GROUP BY pscrbe.specialty_description
ORDER BY total DESC

--q3 a. Which drug (generic_name) had the highest total drug cost?
SELECT d.generic_name, SUM (pscrpt.total_drug_cost)::MONEY AS total_cost
FROM prescription AS pscrpt
INNER JOIN drug AS d
USING (drug_name)
GROUP BY d.generic_name
ORDER BY total_cost DESC
--answer: INSULIN

--b. Which drug (generic_name) has the hightest total cost per day? 
SELECT d.generic_name, ROUND(SUM (pscrpt.total_drug_cost)/ SUM (pscrpt.total_day_supply), 2) AS total_cost_per_day
FROM prescription AS pscrpt
INNER JOIN drug AS d
USING (drug_name)
GROUP BY d.generic_name
ORDER BY total_cost_per_day DESC
--answer:C1 ESTERASE INHIBITOR

--q4 a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs. 
SELECT drug_name,
	CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		 WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		 ELSE 'neither' END AS drug_type
FROM drug

--b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics.
SELECT SUM (CASE WHEN opioid_drug_flag = 'Y'
			 THEN pscrpt.total_drug_cost END) ::MONEY AS o_total,
		SUM (CASE WHEN antibiotic_drug_flag = 'Y'
			 THEN pscrpt.total_drug_cost END) ::MONEY AS a_total
FROM drug AS d
INNER JOIN prescription AS pscrpt
USING (drug_name)
--answer: opioids

--q5 a. How many CBSAs are in Tennessee?
--SELECT COUNT (cbsa) AS cnt_TN_cbsa
--FROM cbsa
--WHERE cbsaname LIKE '%TN%'

SELECT COUNT (*)
FROM cbsa AS c
INNER JOIN fips_county AS f
USING (fipscounty)
WHERE f.state = 'TN'

--b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.
SELECT c.cbsaname, SUM (pop.population) AS total_pop
FROM cbsa AS c
INNER JOIN population AS pop
USING (fipscounty)
GROUP BY c.cbsaname
ORDER BY total_pop DESC

-- (
-- SELECT cbsaname, SUM(population) AS total_population, 'largest' as flag
-- FROM cbsa 
-- INNER JOIN population
-- USING(fipscounty)
-- GROUP BY cbsaname
-- ORDER BY total_population DESC
-- limit 1
-- )
-- UNION
-- (
-- SELECT cbsaname, SUM(population) AS total_population, 'smallest' as flag
-- FROM cbsa 
-- INNER JOIN population
-- USING(fipscounty)
-- GROUP BY cbsaname
-- ORDER BY total_population 
-- limit 1
-- ) order by total_population desc
--answer: largest, Nashville-Davidson--Murfreesboro--Franklin,TN
		--smallest, Morristown, TN

--c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.
SELECT f.county, SUM (pop.population) AS total_pop
FROM fips_county AS f
LEFT JOIN cbsa AS c
USING (fipscounty)
INNER JOIN population AS pop
USING (fipscounty)
WHERE c.cbsa IS NULL
GROUP BY f.county
ORDER BY total_pop DESC
--answer: SEVIER, 95523

--q6 a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.
SELECT drug_name, total_claim_count
FROM prescription
WHERE total_claim_count >= 3000

--b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.
SELECT drug_name, pscrpt.total_claim_count, d.opioid_drug_flag
FROM prescription AS pscrpt
INNER JOIN drug AS d
USING (drug_name)
WHERE pscrpt.total_claim_count >= 3000

--c. Add another column to your answer from the previous part which gives the prescriber first and last name associated with each row.
SELECT drug_name, pscrpt.total_claim_count, d.opioid_drug_flag, pscrbe.nppes_provider_last_org_name, pscrbe.nppes_provider_first_name
FROM prescription AS pscrpt
INNER JOIN drug AS d
USING (drug_name)
INNER JOIN prescriber AS pscrbe
USING (npi)
WHERE pscrpt.total_claim_count >= 3000

--q7 a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Management) in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). 
SELECT npi, drug_name
FROM prescriber AS pscrbe
CROSS JOIN drug AS d
WHERE pscrbe.specialty_description = 'Pain Management'
	AND pscrbe.nppes_provider_city = 'NASHVILLE'
	AND d.opioid_drug_flag = 'Y'
ORDER BY npi, drug_name
--b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).
SELECT pscrbe.npi, d.drug_name, SUM (pscrpt.total_claim_count) AS total_claims
FROM prescriber AS pscrbe
CROSS JOIN drug AS d
LEFT JOIN prescription AS pscrpt
USING (drug_name)
WHERE pscrbe.specialty_description = 'Pain Management'
	AND pscrbe.nppes_provider_city = 'NASHVILLE'
	AND d.opioid_drug_flag = 'Y'
GROUP BY pscrbe.npi, d.drug_name

--c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0.
SELECT pscrbe.npi, d.drug_name, COALESCE (SUM (pscrpt.total_claim_count), 0) AS total_claims
FROM prescriber AS pscrbe
CROSS JOIN drug AS d
LEFT JOIN prescription AS pscrpt
USING (drug_name)
WHERE pscrbe.specialty_description = 'Pain Management'
	AND pscrbe.nppes_provider_city = 'NASHVILLE'
	AND d.opioid_drug_flag = 'Y'
GROUP BY pscrbe.npi, d.drug_name