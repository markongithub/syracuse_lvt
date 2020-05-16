#!/bin/sh

INPUT_FILE=${1:-Parcel_Data_April_2018.csv}
OUTPUT_FILE=${2:-syracuse_lvt_output.csv}

cat << EOF | sqlite3 ./syr_properties_TEMP.db

.headers on
.mode csv
.import ${INPUT_FILE} properties

ALTER TABLE properties ADD city_current_tax_estimated INTEGER;
-- I think this is how much city tax a property is supposed to pay? This is not
-- my day job.
UPDATE properties SET city_current_tax_estimated=ROUND(CityTaxabl * 9.2645 / 1000, 2);

-- city_taxable_land represents the assessed land value reduced by the same
-- proportion we currently reduce the taxable property value. So for properties
-- that currently pay $0.00, it's $0.00. For properties that get a 15%
-- reduction, it's reduced by 15%.
ALTER TABLE properties ADD city_taxable_land INTEGER;
UPDATE properties SET city_taxable_land=ROUND(AssessedLa * CityTaxabl / (1.0 * AssessedVa), 2);

-- city_lvt_with_exemptions shows what the LVT would be if we used roughly the
-- same exemptions we use today. So, e.g. SUNY Upstate would still pay $0.00.
ALTER TABLE properties ADD city_lvt_with_exemptions INTEGER;

-- We divide the current estimated total tax revenue by the amount of taxable
-- land value to figure out the tax rate. We don't store this in a variable
-- right now - I just got the answer and hardcoded it here.
-- SELECT SUM(city_current_tax_estimated) / SUM(city_taxable_land) FROM properties;
-- returns 0.0464058433922323
UPDATE properties SET city_lvt_with_exemptions=ROUND(city_taxable_land * 0.0464058433, 2);

-- city_lvt_pure is, like the name suggests, a land value tax levied on ALL land
-- value, including the ones that pay no property tax today or get a reduced
-- rate due to veteran status.
ALTER TABLE properties ADD city_lvt_pure INTEGER;

-- We divide the current estimated total tax revenue by the amount of total
-- land value to figure out the tax rate. We don't store this in a variable
-- right now - I just got the answer and hardcoded it here.
-- SELECT SUM(city_current_tax_estimated) / SUM(AssessedLa) FROM properties;
-- returns 0.0266735132433914
UPDATE properties SET city_lvt_pure=ROUND(AssessedLa * 0.0266735132, 2);

.output ${OUTPUT_FILE}
SELECT
  FullName,
  WARD,
  -- tax_break is the rate at which a property is tax-exempt. For the veteran
  -- exemption it's 0.15. For churches etc that pay no tax it's 1.0.
  AssessedVa,(1-(CityTaxabl/(1.0 * AssessedVa))) AS tax_break,
  city_current_tax_estimated,
  AssessedLa,
  city_taxable_land,
  city_lvt_pure,
  -- tax_hike_from_lvt_pure is how much the property's taxes would go up
  -- (or down, if it's negative) under the pure LVT.
  (city_lvt_pure-city_current_tax_estimated) AS tax_hike_from_lvt_pure,
  city_lvt_with_exemptions,
  -- tax_hike_from_lvt_pure is how much the property's taxes would go up
  -- (or down, if it's negative) under the compromised LVT calculated above.
  ROUND((city_lvt_with_exemptions-city_current_tax_estimated),2) AS tax_hike_from_lvt_with_exemptions
FROM properties
-- Why are there 370 empty rows?
WHERE FullName != " "
  AND LandUse = "Single Family"
-- I think this is more interesting than pure LVT because all pure LVT tells you
-- is "properties that pay no tax should pay tax".
ORDER BY tax_hike_from_lvt_with_exemptions;

EOF

