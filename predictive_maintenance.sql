-- ================================
-- PREDICTIVE MAINTENANCE ANALYSIS
-- ================================

SELECT *
FROM predictive_maintenance;

-- =======================
-- Basic Failure Overview
-- =======================

-- Failures by product type
SELECT type,
COUNT(*) AS failures
FROM predictive_maintenance
WHERE target = 1
GROUP BY type
ORDER BY failures DESC;

-- Average tool wear by failure status
SELECT target, 
ROUND(AVG(tool_wear),2) AS avg_tool_wear
FROM predictive_maintenance
GROUP BY target;

-- =========================
-- Wear and Failure Signals
-- =========================

-- Rotational speed vs failure 
SELECT target,
CAST(AVG(rotational_speed) AS INT) AS avg_speed
FROM predictive_maintenance
GROUP BY target;

-- Failure type by product type
SELECT type,
failure_type,
COUNT (*) AS total
FROM predictive_maintenance
WHERE failure_type != 'No Failure'
GROUP BY type, failure_type
ORDER BY type, total DESC;

-- Which failure type has highest tool wear?
SELECT failure_type,
ROUND(AVG(tool_wear),2) AS avg_tool_wear
FROM predictive_maintenance
WHERE failure_type != 'No Failure'
GROUP BY failure_type
ORDER BY avg_tool_wear DESC;

-- Which product type has highest average tool wear during failure?
SELECT type,
ROUND(AVG(tool_wear),2) AS avg_tool_wear
FROM predictive_maintenance
WHERE target = 1
GROUP BY type
ORDER BY avg_tool_wear DESC;

-- Failure probability by product type
SELECT type, 
COUNT(*) AS total_rows,
SUM(target) AS failures,
ROUND((SUM(target)*100 / COUNT(*)), 2) AS failure_percent
FROM predictive_maintenance
GROUP BY type
ORDER BY failure_percent DESC;

-- ==============
-- Load Analysis
-- ==============

-- Compare torque and speed together by target
SELECT target,
ROUND(AVG(torque),2) AS avg_torque,
CAST(AVG(rotational_speed) AS INT) AS avg_speed
FROM predictive_maintenance
GROUP BY target;

-- Compare failure type and average tool wear by product type 
SELECT type,
failure_type,
ROUND(AVG(tool_wear), 2) AS avg_tool_wear
FROM predictive_maintenance
WHERE failure_type != 'No Failure'
GROUP BY type, failure_type
ORDER BY type, avg_tool_wear DESC;

-- Compare delta + torque together by failure type
SELECT failure_type,
ROUND(AVG(process_temperature - air_temperature),2) AS avg_temp_delta,
ROUND(AVG(torque),2) AS avg_torque
FROM predictive_maintenance
GROUP BY failure_type
ORDER BY avg_torque DESC;

-- Failure percent by torque bands and product type
SELECT type,
CASE 
WHEN torque < 40 THEN 'Low'
WHEN torque BETWEEN 40 AND 50 THEN 'Medium'
ELSE 'High'
END AS torque_band,
COUNT(*) AS total_machines,
SUM(target) AS failures,
ROUND((SUM(target) * 100 / COUNT(*)), 2) AS fail_percent
FROM predictive_maintenance
GROUP BY type, torque_band
ORDER BY type, fail_percent DESC;

-- ===============
-- Power Analysis
-- ===============

-- Failure percentage by power bands
SELECT type,
CASE 
WHEN (torque * rotational_speed / 9.5488) < 6500 THEN 'Low'
WHEN (torque * rotational_speed / 9.5488) BETWEEN 6500 AND 7500 THEN 'Medium'
ELSE 'High'
END AS power_band,
COUNT(*) AS total_machines,
SUM(target) AS failures,
ROUND(SUM(target)*100.0/COUNT(*),2) AS fail_percent
FROM predictive_maintenance
GROUP BY type, power_band
ORDER BY type, fail_percent;

-- Compare power band + product type + failure type
SELECT  type,
CASE 
WHEN (torque * rotational_speed / 9.5488) < 6500 THEN 'Low'
WHEN (torque * rotational_speed / 9.5488) BETWEEN 6500 AND 7500 THEN 'Medium'
ELSE 'High'
END AS power_band,
failure_type,
COUNT(*) AS failures
FROM predictive_maintenance
WHERE target = 1
GROUP BY type, power_band, failure_type
ORDER BY type, power_band, failures DESC;

-- ======================================
-- Preventive Maintenance Identification
-- ======================================

-- Identify non-failed machines with unusually high tool wear compared to failed machines, indicating preventive maintenance risk.
SELECT type, product_ID, tool_wear,
ROUND(torque * rotational_speed / 9.5488, 2) AS power
FROM predictive_maintenance
WHERE target = 0 
AND tool_wear > 
(
SELECT AVG(tool_wear) 
FROM predictive_maintenance 
WHERE target = 1
)
AND(torque * rotational_speed / 9.5488) > 7500
AND tool_wear > 150
ORDER BY type, tool_wear DESC;
