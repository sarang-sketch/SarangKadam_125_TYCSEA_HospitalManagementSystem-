-- Hospital Management System - Management Reporting Queries
-- This script contains comprehensive reporting queries for hospital management and analytics

USE hospital_management_system;

-- 1. Monthly Financial Report
DELIMITER //
CREATE PROCEDURE GenerateMonthlyFinancialReport(
    IN p_year INT,
    IN p_month INT
)
BEGIN
    DECLARE v_start_date DATE;
    DECLARE v_end_date DATE;
    
    SET v_start_date = DATE(CONCAT(p_year, '-', LPAD(p_month, 2, '0'), '-01'));
    SET v_end_date = LAST_DAY(v_start_date);
    
    -- Revenue Summary
    SELECT 'REVENUE SUMMARY' AS report_section;
    SELECT 
        SUM(b.total_amount) AS total_billed,
        SUM(b.insurance_coverage) AS insurance_payments,
        SUM(b.discount_amount) AS total_discounts,
        SUM(b.final_amount) AS patient_responsibility,
        SUM(CASE WHEN b.payment_status = 'Paid' THEN b.final_amount ELSE 0 END) AS total_collected,
        SUM(CASE WHEN b.payment_status IN ('Pending', 'Partial') THEN b.final_amount ELSE 0 END) AS outstanding_balance,
        ROUND(SUM(CASE WHEN b.payment_status = 'Paid' THEN b.final_amount ELSE 0 END) / SUM(b.final_amount) * 100, 2) AS collection_rate_percent
    FROM Billing b
    WHERE DATE(b.bill_date) BETWEEN v_start_date AND v_end_date;
    
    -- Department Revenue
    SELECT 'DEPARTMENT REVENUE' AS report_section;
    SELECT 
        d.department_name,
        COUNT(DISTINCT bi.bill_id) AS bills_generated,
        SUM(bi.total_price) AS department_revenue,
        ROUND(SUM(bi.total_price) / (SELECT SUM(total_price) FROM Bill_Items bi2 JOIN Billing b2 ON bi2.bill_id = b2.bill_id WHERE DATE(b2.bill_date) BETWEEN v_start_date AND v_end_date) * 100, 2) AS revenue_percentage
    FROM Bill_Items bi
    JOIN Billing b ON bi.bill_id = b.bill_id
    JOIN Departments d ON bi.department_id = d.department_id
    WHERE DATE(b.bill_date) BETWEEN v_start_date AND v_end_date
    GROUP BY d.department_id, d.department_name
    ORDER BY department_revenue DESC;
    
    -- Service Type Analysis
    SELECT 'SERVICE TYPE ANALYSIS' AS report_section;
    SELECT 
        bi.service_type,
        COUNT(*) AS service_count,
        SUM(bi.total_price) AS total_revenue,
        AVG(bi.total_price) AS avg_service_price,
        ROUND(SUM(bi.total_price) / (SELECT SUM(total_price) FROM Bill_Items bi2 JOIN Billing b2 ON bi2.bill_id = b2.bill_id WHERE DATE(b2.bill_date) BETWEEN v_start_date AND v_end_date) * 100, 2) AS revenue_percentage
    FROM Bill_Items bi
    JOIN Billing b ON bi.bill_id = b.bill_id
    WHERE DATE(b.bill_date) BETWEEN v_start_date AND v_end_date
    GROUP BY bi.service_type
    ORDER BY total_revenue DESC;
END//
DELIMITER ;

-- 2. Staff Performance Report
DELIMITER //
CREATE PROCEDURE GenerateStaffPerformanceReport(
    IN p_start_date DATE,
    IN p_end_date DATE,
    IN p_department_id INT
)
BEGIN
    -- Staff Productivity
    SELECT 'STAFF PRODUCTIVITY' AS report_section;
    SELECT 
        CONCAT(ms.first_name, ' ', ms.last_name) AS staff_name,
        ms.role,
        d.department_name,
        COUNT(DISTINCT a.appointment_id) AS appointments_handled,
        COUNT(DISTINCT mr.record_id) AS medical_records_created,
        COUNT(DISTINCT t.treatment_id) AS treatments_performed,
        COUNT(DISTINCT pr.prescription_id) AS prescriptions_written,
        COALESCE(SUM(t.cost), 0) AS total_treatment_revenue
    FROM Medical_Staff ms
    JOIN Departments d ON ms.department_id = d.department_id
    LEFT JOIN Appointments a ON ms.staff_id = a.staff_id 
        AND a.appointment_date BETWEEN p_start_date AND p_end_date
        AND a.status = 'Completed'
    LEFT JOIN Medical_Records mr ON ms.staff_id = mr.staff_id 
        AND DATE(mr.visit_date) BETWEEN p_start_date AND p_end_date
    LEFT JOIN Treatments t ON ms.staff_id = t.staff_id 
        AND DATE(t.treatment_date) BETWEEN p_start_date AND p_end_date
        AND t.status = 'Completed'
    LEFT JOIN Prescriptions pr ON ms.staff_id = pr.staff_id 
        AND DATE(pr.prescription_date) BETWEEN p_start_date AND p_end_date
    WHERE ms.status = 'Active'
      AND (p_department_id IS NULL OR ms.department_id = p_department_id)
    GROUP BY ms.staff_id, ms.first_name, ms.last_name, ms.role, d.department_name
    ORDER BY appointments_handled DESC, total_treatment_revenue DESC;
    
    -- Department Summary
    SELECT 'DEPARTMENT SUMMARY' AS report_section;
    SELECT 
        d.department_name,
        COUNT(DISTINCT ms.staff_id) AS active_staff,
        COUNT(DISTINCT a.appointment_id) AS total_appointments,
        COUNT(DISTINCT t.treatment_id) AS total_treatments,
        COALESCE(SUM(t.cost), 0) AS department_revenue
    FROM Departments d
    LEFT JOIN Medical_Staff ms ON d.department_id = ms.department_id AND ms.status = 'Active'
    LEFT JOIN Appointments a ON ms.staff_id = a.staff_id 
        AND a.appointment_date BETWEEN p_start_date AND p_end_date
    LEFT JOIN Treatments t ON ms.staff_id = t.staff_id 
        AND DATE(t.treatment_date) BETWEEN p_start_date AND p_end_date
        AND t.status = 'Completed'
    WHERE (p_department_id IS NULL OR d.department_id = p_department_id)
    GROUP BY d.department_id, d.department_name
    ORDER BY department_revenue DESC;
END//
DELIMITER ;

-- 3. Patient Demographics and Utilization Report
DELIMITER //
CREATE PROCEDURE GeneratePatientUtilizationReport()
BEGIN
    -- Patient Demographics
    SELECT 'PATIENT DEMOGRAPHICS' AS report_section;
    SELECT 
        CASE 
            WHEN TIMESTAMPDIFF(YEAR, date_of_birth, CURDATE()) < 18 THEN 'Under 18'
            WHEN TIMESTAMPDIFF(YEAR, date_of_birth, CURDATE()) BETWEEN 18 AND 35 THEN '18-35'
            WHEN TIMESTAMPDIFF(YEAR, date_of_birth, CURDATE()) BETWEEN 36 AND 50 THEN '36-50'
            WHEN TIMESTAMPDIFF(YEAR, date_of_birth, CURDATE()) BETWEEN 51 AND 65 THEN '51-65'
            ELSE 'Over 65'
        END AS age_group,
        gender,
        COUNT(*) AS patient_count,
        ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM Patients WHERE status = 'Active'), 2) AS percentage
    FROM Patients
    WHERE status = 'Active'
    GROUP BY age_group, gender
    ORDER BY age_group, gender;
    
    -- Insurance Provider Analysis
    SELECT 'INSURANCE PROVIDER ANALYSIS' AS report_section;
    SELECT 
        COALESCE(insurance_provider, 'Self-Pay') AS insurance_provider,
        COUNT(*) AS patient_count,
        ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM Patients WHERE status = 'Active'), 2) AS percentage,
        AVG(GetPatientOutstandingBalance(patient_id)) AS avg_outstanding_balance
    FROM Patients
    WHERE status = 'Active'
    GROUP BY insurance_provider
    ORDER BY patient_count DESC;
    
    -- Most Common Diagnoses
    SELECT 'MOST COMMON DIAGNOSES' AS report_section;
    SELECT 
        diagnosis,
        COUNT(*) AS diagnosis_count,
        COUNT(DISTINCT patient_id) AS unique_patients
    FROM Medical_Records
    WHERE diagnosis IS NOT NULL 
      AND diagnosis != ''
      AND visit_date >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
    GROUP BY diagnosis
    ORDER BY diagnosis_count DESC
    LIMIT 10;
END//
DELIMITER ;

-- 4. Room Utilization and Occupancy Report
DELIMITER //
CREATE PROCEDURE GenerateRoomUtilizationReport(
    IN p_start_date DATE,
    IN p_end_date DATE
)
BEGIN
    -- Room Occupancy Summary
    SELECT 'ROOM OCCUPANCY SUMMARY' AS report_section;
    SELECT 
        r.room_type,
        COUNT(*) AS total_rooms,
        SUM(r.capacity) AS total_capacity,
        AVG(r.current_occupancy) AS avg_occupancy,
        ROUND(AVG(r.current_occupancy) / AVG(r.capacity) * 100, 2) AS avg_occupancy_rate,
        SUM(CASE WHEN r.status = 'Available' THEN 1 ELSE 0 END) AS available_rooms,
        SUM(CASE WHEN r.status = 'Occupied' THEN 1 ELSE 0 END) AS occupied_rooms,
        SUM(CASE WHEN r.status = 'Maintenance' THEN 1 ELSE 0 END) AS maintenance_rooms
    FROM Rooms r
    GROUP BY r.room_type
    ORDER BY r.room_type;
    
    -- Department Room Utilization
    SELECT 'DEPARTMENT ROOM UTILIZATION' AS report_section;
    SELECT 
        d.department_name,
        COUNT(r.room_id) AS total_rooms,
        SUM(r.capacity) AS total_capacity,
        SUM(r.current_occupancy) AS current_occupancy,
        ROUND(SUM(r.current_occupancy) / SUM(r.capacity) * 100, 2) AS occupancy_rate,
        SUM(r.daily_rate * r.current_occupancy) AS daily_revenue_potential
    FROM Departments d
    LEFT JOIN Rooms r ON d.department_id = r.department_id
    GROUP BY d.department_id, d.department_name
    HAVING total_rooms > 0
    ORDER BY occupancy_rate DESC;
    
    -- Room Revenue Analysis
    SELECT 'ROOM REVENUE ANALYSIS' AS report_section;
    SELECT 
        r.room_number,
        r.room_type,
        r.daily_rate,
        r.current_occupancy,
        r.capacity,
        (r.daily_rate * r.current_occupancy) AS current_daily_revenue,
        (r.daily_rate * r.capacity) AS max_daily_revenue,
        d.department_name
    FROM Rooms r
    LEFT JOIN Departments d ON r.department_id = d.department_id
    WHERE r.daily_rate > 0
    ORDER BY current_daily_revenue DESC;
END//
DELIMITER ;

-- 5. Medication and Pharmacy Report
DELIMITER //
CREATE PROCEDURE GeneratePharmacyReport(
    IN p_start_date DATE,
    IN p_end_date DATE
)
BEGIN
    -- Top Prescribed Medications
    SELECT 'TOP PRESCRIBED MEDICATIONS' AS report_section;
    SELECT 
        m.medication_name,
        m.generic_name,
        COUNT(pr.prescription_id) AS prescription_count,
        SUM(pr.quantity_dispensed) AS total_quantity_dispensed,
        SUM(pr.quantity_dispensed * m.unit_price) AS total_revenue,
        AVG(pr.quantity_dispensed) AS avg_quantity_per_prescription
    FROM Prescriptions pr
    JOIN Medications m ON pr.medication_id = m.medication_id
    WHERE DATE(pr.prescription_date) BETWEEN p_start_date AND p_end_date
      AND pr.quantity_dispensed > 0
    GROUP BY m.medication_id, m.medication_name, m.generic_name
    ORDER BY prescription_count DESC
    LIMIT 15;
    
    -- Inventory Status
    SELECT 'INVENTORY STATUS' AS report_section;
    SELECT 
        'Total Medications' AS metric,
        COUNT(*) AS value,
        NULL AS additional_info
    FROM Medications
    UNION ALL
    SELECT 
        'Low Stock Items',
        COUNT(*),
        CONCAT('Below minimum level')
    FROM Medications
    WHERE stock_quantity <= minimum_stock_level
    UNION ALL
    SELECT 
        'Expired Items',
        COUNT(*),
        CONCAT('Past expiry date')
    FROM Medications
    WHERE expiry_date <= CURDATE() AND stock_quantity > 0
    UNION ALL
    SELECT 
        'Total Inventory Value',
        NULL,
        CONCAT('$', FORMAT(SUM(stock_quantity * unit_price), 2))
    FROM Medications;
    
    -- Prescription Patterns by Department
    SELECT 'PRESCRIPTION PATTERNS BY DEPARTMENT' AS report_section;
    SELECT 
        d.department_name,
        COUNT(pr.prescription_id) AS prescriptions_written,
        COUNT(DISTINCT pr.medication_id) AS unique_medications,
        SUM(pr.quantity_dispensed * m.unit_price) AS department_pharmacy_revenue
    FROM Prescriptions pr
    JOIN Medical_Staff ms ON pr.staff_id = ms.staff_id
    JOIN Departments d ON ms.department_id = d.department_id
    JOIN Medications m ON pr.medication_id = m.medication_id
    WHERE DATE(pr.prescription_date) BETWEEN p_start_date AND p_end_date
      AND pr.quantity_dispensed > 0
    GROUP BY d.department_id, d.department_name
    ORDER BY prescriptions_written DESC;
END//
DELIMITER ;

-- 6. Executive Dashboard Summary
DELIMITER //
CREATE PROCEDURE GenerateExecutiveDashboard()
BEGIN
    -- Key Performance Indicators
    SELECT 'KEY PERFORMANCE INDICATORS' AS report_section;
    SELECT 
        'Total Active Patients' AS metric,
        COUNT(*) AS value,
        'Current active patient count' AS description
    FROM Patients WHERE status = 'Active'
    UNION ALL
    SELECT 
        'Today\'s Appointments',
        COUNT(*),
        'Scheduled appointments for today'
    FROM Appointments WHERE appointment_date = CURDATE() AND status IN ('Scheduled', 'Rescheduled')
    UNION ALL
    SELECT 
        'Current Room Occupancy Rate',
        ROUND(SUM(current_occupancy) / SUM(capacity) * 100, 1),
        'Percentage of beds occupied'
    FROM Rooms
    UNION ALL
    SELECT 
        'Outstanding Bills',
        COUNT(*),
        'Bills with pending/partial payment'
    FROM Billing WHERE payment_status IN ('Pending', 'Partial', 'Overdue')
    UNION ALL
    SELECT 
        'Low Stock Medications',
        COUNT(*),
        'Medications below minimum stock level'
    FROM Medications WHERE stock_quantity <= minimum_stock_level;
    
    -- Monthly Trends (Last 6 Months)
    SELECT 'MONTHLY TRENDS (LAST 6 MONTHS)' AS report_section;
    SELECT 
        DATE_FORMAT(bill_date, '%Y-%m') AS month,
        COUNT(DISTINCT bill_id) AS bills_generated,
        SUM(total_amount) AS total_billed,
        SUM(CASE WHEN payment_status = 'Paid' THEN final_amount ELSE 0 END) AS total_collected,
        ROUND(SUM(CASE WHEN payment_status = 'Paid' THEN final_amount ELSE 0 END) / SUM(final_amount) * 100, 2) AS collection_rate
    FROM Billing
    WHERE bill_date >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
    GROUP BY DATE_FORMAT(bill_date, '%Y-%m')
    ORDER BY month DESC;
    
    -- Department Performance Summary
    SELECT 'DEPARTMENT PERFORMANCE SUMMARY' AS report_section;
    SELECT 
        d.department_name,
        COUNT(DISTINCT ms.staff_id) AS active_staff,
        COUNT(DISTINCT CASE WHEN a.appointment_date = CURDATE() THEN a.appointment_id END) AS todays_appointments,
        COALESCE(SUM(CASE WHEN r.room_id IS NOT NULL THEN r.current_occupancy ELSE 0 END), 0) AS current_occupancy,
        COALESCE(SUM(CASE WHEN r.room_id IS NOT NULL THEN r.capacity ELSE 0 END), 0) AS total_capacity
    FROM Departments d
    LEFT JOIN Medical_Staff ms ON d.department_id = ms.department_id AND ms.status = 'Active'
    LEFT JOIN Appointments a ON ms.staff_id = a.staff_id
    LEFT JOIN Rooms r ON d.department_id = r.department_id
    WHERE d.department_id <= 6  -- Exclude pharmacy from this summary
    GROUP BY d.department_id, d.department_name
    ORDER BY d.department_name;
END//
DELIMITER ;

-- Create management reporting views
CREATE VIEW Monthly_Revenue_Trend AS
SELECT 
    DATE_FORMAT(bill_date, '%Y-%m') AS month,
    COUNT(bill_id) AS total_bills,
    SUM(total_amount) AS total_billed,
    SUM(insurance_coverage) AS insurance_payments,
    SUM(final_amount) AS patient_responsibility,
    SUM(CASE WHEN payment_status = 'Paid' THEN final_amount ELSE 0 END) AS collected_amount,
    ROUND(SUM(CASE WHEN payment_status = 'Paid' THEN final_amount ELSE 0 END) / SUM(final_amount) * 100, 2) AS collection_rate
FROM Billing
WHERE bill_date >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
GROUP BY DATE_FORMAT(bill_date, '%Y-%m')
ORDER BY month DESC;

CREATE VIEW Department_Performance_Summary AS
SELECT 
    d.department_name,
    COUNT(DISTINCT ms.staff_id) AS total_staff,
    COUNT(DISTINCT CASE WHEN ms.status = 'Active' THEN ms.staff_id END) AS active_staff,
    COUNT(DISTINCT r.room_id) AS total_rooms,
    COALESCE(SUM(r.capacity), 0) AS total_bed_capacity,
    COALESCE(SUM(r.current_occupancy), 0) AS current_occupancy,
    CASE 
        WHEN SUM(r.capacity) > 0 THEN ROUND(SUM(r.current_occupancy) / SUM(r.capacity) * 100, 2)
        ELSE 0 
    END AS occupancy_rate
FROM Departments d
LEFT JOIN Medical_Staff ms ON d.department_id = ms.department_id
LEFT JOIN Rooms r ON d.department_id = r.department_id
GROUP BY d.department_id, d.department_name
ORDER BY d.department_name;

-- Show created procedures and views
SHOW PROCEDURE STATUS WHERE Db = 'hospital_management_system' 
AND Name IN ('GenerateMonthlyFinancialReport', 'GenerateStaffPerformanceReport', 
             'GeneratePatientUtilizationReport', 'GenerateRoomUtilizationReport',
             'GeneratePharmacyReport', 'GenerateExecutiveDashboard');

SHOW CREATE VIEW Monthly_Revenue_Trend;
SHOW CREATE VIEW Department_Performance_Summary;

-- Confirmation message
SELECT 'Management reporting queries and procedures created successfully!' AS Status;