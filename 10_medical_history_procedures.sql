-- Hospital Management System - Medical History Query Procedures
-- This script creates stored procedures for chronological medical history and staff accountability

USE hospital_management_system;

-- Procedure to get complete chronological medical history for a patient
DELIMITER //
CREATE PROCEDURE GetPatientMedicalHistory(
    IN p_patient_id INT,
    IN p_start_date DATE,
    IN p_end_date DATE,
    IN p_record_type VARCHAR(50)
)
BEGIN
    SELECT 
        mr.record_id,
        mr.visit_date,
        mr.record_type,
        mr.chief_complaint,
        mr.symptoms,
        mr.diagnosis,
        mr.treatment_plan,
        mr.medications_prescribed,
        mr.allergies,
        mr.physical_examination,
        mr.lab_results,
        mr.imaging_results,
        mr.procedure_notes,
        mr.follow_up_required,
        mr.follow_up_date,
        CONCAT(ms.first_name, ' ', ms.last_name) AS attending_physician,
        ms.specialization,
        ms.role,
        d.department_name,
        -- Extract key vital signs
        JSON_UNQUOTE(JSON_EXTRACT(mr.vital_signs, '$.temperature')) AS temperature,
        JSON_UNQUOTE(JSON_EXTRACT(mr.vital_signs, '$.blood_pressure_systolic')) AS bp_systolic,
        JSON_UNQUOTE(JSON_EXTRACT(mr.vital_signs, '$.blood_pressure_diastolic')) AS bp_diastolic,
        JSON_UNQUOTE(JSON_EXTRACT(mr.vital_signs, '$.heart_rate')) AS heart_rate,
        JSON_UNQUOTE(JSON_EXTRACT(mr.vital_signs, '$.respiratory_rate')) AS respiratory_rate,
        JSON_UNQUOTE(JSON_EXTRACT(mr.vital_signs, '$.oxygen_saturation')) AS oxygen_saturation
    FROM Medical_Records mr
    JOIN Medical_Staff ms ON mr.staff_id = ms.staff_id
    LEFT JOIN Departments d ON ms.department_id = d.department_id
    WHERE mr.patient_id = p_patient_id
      AND (p_start_date IS NULL OR DATE(mr.visit_date) >= p_start_date)
      AND (p_end_date IS NULL OR DATE(mr.visit_date) <= p_end_date)
      AND (p_record_type IS NULL OR mr.record_type = p_record_type)
    ORDER BY mr.visit_date DESC, mr.created_date DESC;
END//
DELIMITER ;

-- Procedure to get patient treatment summary with costs
DELIMITER //
CREATE PROCEDURE GetPatientTreatmentSummary(
    IN p_patient_id INT,
    IN p_start_date DATE,
    IN p_end_date DATE
)
BEGIN
    SELECT 
        t.treatment_id,
        t.treatment_date,
        t.treatment_name,
        t.treatment_code,
        t.cost,
        t.status,
        t.priority,
        t.duration_minutes,
        t.notes,
        t.complications,
        CONCAT(ms.first_name, ' ', ms.last_name) AS attending_physician,
        ms.specialization,
        r.room_number,
        r.room_type,
        -- Calculate total cost including room charges
        CASE 
            WHEN t.duration_minutes IS NOT NULL AND r.daily_rate IS NOT NULL THEN
                t.cost + (r.daily_rate * (t.duration_minutes / 1440.0))
            ELSE t.cost
        END AS total_cost
    FROM Treatments t
    JOIN Medical_Staff ms ON t.staff_id = ms.staff_id
    LEFT JOIN Rooms r ON t.room_id = r.room_id
    WHERE t.patient_id = p_patient_id
      AND (p_start_date IS NULL OR DATE(t.treatment_date) >= p_start_date)
      AND (p_end_date IS NULL OR DATE(t.treatment_date) <= p_end_date)
    ORDER BY t.treatment_date DESC;
END//
DELIMITER ;

-- Procedure for medical staff accountability tracking
DELIMITER //
CREATE PROCEDURE GetStaffAccountabilityReport(
    IN p_staff_id INT,
    IN p_start_date DATE,
    IN p_end_date DATE
)
BEGIN
    -- Medical Records handled by staff
    SELECT 
        'Medical Records' AS activity_type,
        mr.record_id AS activity_id,
        mr.visit_date AS activity_date,
        mr.record_type,
        CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
        mr.diagnosis,
        mr.chief_complaint,
        NULL AS cost,
        NULL AS status
    FROM Medical_Records mr
    JOIN Patients p ON mr.patient_id = p.patient_id
    WHERE mr.staff_id = p_staff_id
      AND (p_start_date IS NULL OR DATE(mr.visit_date) >= p_start_date)
      AND (p_end_date IS NULL OR DATE(mr.visit_date) <= p_end_date)
    
    UNION ALL
    
    -- Treatments performed by staff
    SELECT 
        'Treatment' AS activity_type,
        t.treatment_id AS activity_id,
        t.treatment_date AS activity_date,
        t.treatment_name AS record_type,
        CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
        t.treatment_name AS diagnosis,
        t.notes AS chief_complaint,
        t.cost,
        t.status
    FROM Treatments t
    JOIN Patients p ON t.patient_id = p.patient_id
    WHERE t.staff_id = p_staff_id
      AND (p_start_date IS NULL OR DATE(t.treatment_date) >= p_start_date)
      AND (p_end_date IS NULL OR DATE(t.treatment_date) <= p_end_date)
    
    UNION ALL
    
    -- Appointments handled by staff
    SELECT 
        'Appointment' AS activity_type,
        a.appointment_id AS activity_id,
        TIMESTAMP(a.appointment_date, a.appointment_time) AS activity_date,
        a.purpose AS record_type,
        CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
        a.purpose AS diagnosis,
        a.notes AS chief_complaint,
        NULL AS cost,
        a.status
    FROM Appointments a
    JOIN Patients p ON a.patient_id = p.patient_id
    WHERE a.staff_id = p_staff_id
      AND (p_start_date IS NULL OR a.appointment_date >= p_start_date)
      AND (p_end_date IS NULL OR a.appointment_date <= p_end_date)
    
    ORDER BY activity_date DESC;
END//
DELIMITER ;

-- Procedure to get patient allergies and medication history
DELIMITER //
CREATE PROCEDURE GetPatientAllergiesAndMedications(
    IN p_patient_id INT
)
BEGIN
    -- Get latest allergies from medical records
    SELECT DISTINCT
        'Allergy' AS type,
        mr.allergies AS details,
        mr.visit_date AS recorded_date,
        CONCAT(ms.first_name, ' ', ms.last_name) AS recorded_by
    FROM Medical_Records mr
    JOIN Medical_Staff ms ON mr.staff_id = ms.staff_id
    WHERE mr.patient_id = p_patient_id
      AND mr.allergies IS NOT NULL
      AND mr.allergies != ''
    
    UNION ALL
    
    -- Get medication history from medical records
    SELECT DISTINCT
        'Medication History' AS type,
        mr.medications_prescribed AS details,
        mr.visit_date AS recorded_date,
        CONCAT(ms.first_name, ' ', ms.last_name) AS recorded_by
    FROM Medical_Records mr
    JOIN Medical_Staff ms ON mr.staff_id = ms.staff_id
    WHERE mr.patient_id = p_patient_id
      AND mr.medications_prescribed IS NOT NULL
      AND mr.medications_prescribed != ''
    
    ORDER BY recorded_date DESC;
END//
DELIMITER ;

-- Procedure to get follow-up appointments needed
DELIMITER //
CREATE PROCEDURE GetFollowUpRequired(
    IN p_department_id INT,
    IN p_staff_id INT,
    IN p_date_range_days INT
)
BEGIN
    DECLARE v_end_date DATE;
    SET v_end_date = DATE_ADD(CURDATE(), INTERVAL COALESCE(p_date_range_days, 30) DAY);
    
    SELECT 
        mr.record_id,
        mr.patient_id,
        CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
        p.phone AS patient_phone,
        p.email AS patient_email,
        mr.visit_date AS last_visit,
        mr.follow_up_date,
        mr.diagnosis,
        mr.record_type,
        CONCAT(ms.first_name, ' ', ms.last_name) AS attending_physician,
        ms.specialization,
        d.department_name,
        DATEDIFF(mr.follow_up_date, CURDATE()) AS days_until_followup
    FROM Medical_Records mr
    JOIN Patients p ON mr.patient_id = p.patient_id
    JOIN Medical_Staff ms ON mr.staff_id = ms.staff_id
    LEFT JOIN Departments d ON ms.department_id = d.department_id
    WHERE mr.follow_up_required = TRUE
      AND mr.follow_up_date BETWEEN CURDATE() AND v_end_date
      AND (p_department_id IS NULL OR ms.department_id = p_department_id)
      AND (p_staff_id IS NULL OR mr.staff_id = p_staff_id)
      AND p.status = 'Active'
    ORDER BY mr.follow_up_date ASC;
END//
DELIMITER ;

-- Procedure to get comprehensive patient summary
DELIMITER //
CREATE PROCEDURE GetPatientSummary(
    IN p_patient_id INT
)
BEGIN
    -- Patient basic information
    SELECT 
        p.patient_id,
        CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
        p.date_of_birth,
        TIMESTAMPDIFF(YEAR, p.date_of_birth, CURDATE()) AS age,
        p.gender,
        p.phone,
        p.email,
        p.address,
        p.emergency_contact_name,
        p.emergency_contact_phone,
        p.insurance_provider,
        p.insurance_policy_number,
        p.registration_date,
        p.status
    FROM Patients p
    WHERE p.patient_id = p_patient_id;
    
    -- Latest vital signs
    SELECT 
        'Latest Vital Signs' AS section,
        mr.visit_date,
        JSON_UNQUOTE(JSON_EXTRACT(mr.vital_signs, '$.temperature')) AS temperature,
        JSON_UNQUOTE(JSON_EXTRACT(mr.vital_signs, '$.blood_pressure_systolic')) AS bp_systolic,
        JSON_UNQUOTE(JSON_EXTRACT(mr.vital_signs, '$.blood_pressure_diastolic')) AS bp_diastolic,
        JSON_UNQUOTE(JSON_EXTRACT(mr.vital_signs, '$.heart_rate')) AS heart_rate,
        JSON_UNQUOTE(JSON_EXTRACT(mr.vital_signs, '$.respiratory_rate')) AS respiratory_rate,
        JSON_UNQUOTE(JSON_EXTRACT(mr.vital_signs, '$.oxygen_saturation')) AS oxygen_saturation,
        JSON_UNQUOTE(JSON_EXTRACT(mr.vital_signs, '$.weight')) AS weight,
        JSON_UNQUOTE(JSON_EXTRACT(mr.vital_signs, '$.height')) AS height
    FROM Medical_Records mr
    WHERE mr.patient_id = p_patient_id
      AND mr.vital_signs IS NOT NULL
    ORDER BY mr.visit_date DESC
    LIMIT 1;
    
    -- Recent diagnoses (last 6 months)
    SELECT 
        'Recent Diagnoses' AS section,
        mr.visit_date,
        mr.diagnosis,
        mr.record_type,
        CONCAT(ms.first_name, ' ', ms.last_name) AS physician
    FROM Medical_Records mr
    JOIN Medical_Staff ms ON mr.staff_id = ms.staff_id
    WHERE mr.patient_id = p_patient_id
      AND mr.diagnosis IS NOT NULL
      AND mr.visit_date >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
    ORDER BY mr.visit_date DESC
    LIMIT 5;
    
    -- Active follow-ups
    SELECT 
        'Active Follow-ups' AS section,
        mr.follow_up_date,
        mr.diagnosis,
        mr.visit_date AS original_visit,
        CONCAT(ms.first_name, ' ', ms.last_name) AS physician
    FROM Medical_Records mr
    JOIN Medical_Staff ms ON mr.staff_id = ms.staff_id
    WHERE mr.patient_id = p_patient_id
      AND mr.follow_up_required = TRUE
      AND mr.follow_up_date >= CURDATE()
    ORDER BY mr.follow_up_date ASC;
END//
DELIMITER ;

-- Show created procedures
SHOW PROCEDURE STATUS WHERE Db = 'hospital_management_system' 
AND Name IN ('GetPatientMedicalHistory', 'GetPatientTreatmentSummary', 'GetStaffAccountabilityReport', 
             'GetPatientAllergiesAndMedications', 'GetFollowUpRequired', 'GetPatientSummary');

-- Confirmation message
SELECT 'Medical history query procedures created successfully!' AS Status;