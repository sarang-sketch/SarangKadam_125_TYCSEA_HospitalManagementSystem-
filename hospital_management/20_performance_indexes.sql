-- Hospital Management System - Performance Indexes
-- This script creates additional performance indexes for optimal query performance

USE hospital_management_system;

-- Additional performance indexes (most basic indexes were created with tables)

-- Composite indexes for common query patterns
CREATE INDEX idx_patient_name_dob ON Patients(last_name, first_name, date_of_birth);
CREATE INDEX idx_patient_insurance ON Patients(insurance_provider, insurance_policy_number);

-- Staff performance indexes
CREATE INDEX idx_staff_role_dept ON Medical_Staff(role, department_id, status);
CREATE INDEX idx_staff_license_expiry_active ON Medical_Staff(license_expiry_date, status) WHERE status = 'Active';

-- Appointment optimization indexes
CREATE INDEX idx_appointment_patient_date ON Appointments(patient_id, appointment_date, status);
CREATE INDEX idx_appointment_staff_date_status ON Appointments(staff_id, appointment_date, status);

-- Medical records performance indexes
CREATE INDEX idx_medical_record_date_type ON Medical_Records(visit_date, record_type);
CREATE INDEX idx_medical_record_patient_type ON Medical_Records(patient_id, record_type, visit_date DESC);

-- Treatment optimization
CREATE INDEX idx_treatment_patient_status ON Treatments(patient_id, status, treatment_date DESC);
CREATE INDEX idx_treatment_staff_date ON Treatments(staff_id, treatment_date, status);
CREATE INDEX idx_treatment_cost_date ON Treatments(treatment_date, cost) WHERE status = 'Completed';

-- Medication and prescription indexes
CREATE INDEX idx_medication_expiry_stock ON Medications(expiry_date, stock_quantity) WHERE stock_quantity > 0;
CREATE INDEX idx_prescription_patient_status ON Prescriptions(patient_id, status, prescription_date DESC);
CREATE INDEX idx_prescription_medication_date ON Prescriptions(medication_id, prescription_date, status);

-- Billing performance indexes
CREATE INDEX idx_billing_patient_status_date ON Billing(patient_id, payment_status, bill_date DESC);
CREATE INDEX idx_billing_insurance_claim ON Billing(insurance_claim_number, payment_status);
CREATE INDEX idx_billing_overdue ON Billing(due_date, payment_status) WHERE payment_status IN ('Pending', 'Partial');

-- Bill items optimization
CREATE INDEX idx_bill_items_service_date ON Bill_Items(service_type, service_date, total_price);
CREATE INDEX idx_bill_items_provider_date ON Bill_Items(service_provider_id, service_date);

-- Payment performance indexes
CREATE INDEX idx_payments_method_date ON Payments(payment_method, payment_date, payment_status);
CREATE INDEX idx_payments_amount_date ON Payments(payment_date, amount_paid) WHERE payment_status = 'Completed';

-- Room utilization indexes
CREATE INDEX idx_room_type_status ON Rooms(room_type, status, current_occupancy);
CREATE INDEX idx_room_dept_availability ON Rooms(department_id, status, capacity, current_occupancy);

-- Alert and notification indexes
CREATE INDEX idx_medication_alerts_unack ON Medication_Alerts(alert_type, acknowledged, alert_date) WHERE acknowledged = FALSE;

-- Full-text search indexes for text fields (if supported)
-- Note: These may need to be adjusted based on MySQL version and configuration
-- ALTER TABLE Patients ADD FULLTEXT(first_name, last_name);
-- ALTER TABLE Medical_Records ADD FULLTEXT(diagnosis, symptoms);
-- ALTER TABLE Treatments ADD FULLTEXT(treatment_name, notes);

-- Create a procedure to analyze index usage
DELIMITER //
CREATE PROCEDURE AnalyzeIndexUsage()
BEGIN
    -- Show index statistics
    SELECT 
        TABLE_NAME,
        INDEX_NAME,
        NON_UNIQUE,
        COLUMN_NAME,
        CARDINALITY,
        INDEX_TYPE
    FROM INFORMATION_SCHEMA.STATISTICS 
    WHERE TABLE_SCHEMA = 'hospital_management_system'
      AND INDEX_NAME != 'PRIMARY'
    ORDER BY TABLE_NAME, INDEX_NAME, SEQ_IN_INDEX;
END//
DELIMITER ;

-- Create a view for index summary
CREATE VIEW Index_Summary AS
SELECT 
    TABLE_NAME,
    COUNT(DISTINCT INDEX_NAME) AS total_indexes,
    COUNT(CASE WHEN NON_UNIQUE = 0 THEN 1 END) AS unique_indexes,
    COUNT(CASE WHEN NON_UNIQUE = 1 THEN 1 END) AS non_unique_indexes,
    GROUP_CONCAT(DISTINCT INDEX_TYPE) AS index_types
FROM INFORMATION_SCHEMA.STATISTICS 
WHERE TABLE_SCHEMA = 'hospital_management_system'
  AND INDEX_NAME != 'PRIMARY'
GROUP BY TABLE_NAME
ORDER BY TABLE_NAME;

-- Show index summary
SELECT 'Database Index Summary:' AS info;
SELECT * FROM Index_Summary;

-- Show total index count
SELECT 
    'Total Performance Indexes Created' AS metric,
    COUNT(DISTINCT CONCAT(TABLE_NAME, '.', INDEX_NAME)) AS count
FROM INFORMATION_SCHEMA.STATISTICS 
WHERE TABLE_SCHEMA = 'hospital_management_system'
  AND INDEX_NAME != 'PRIMARY';

-- Confirmation message
SELECT 'Performance indexes created successfully for optimal query performance!' AS Status;