-- Hospital Management System - Billing Calculation Procedures
-- This script creates comprehensive billing procedures for automatic bill generation and payment processing

USE hospital_management_system;

-- Procedure to generate comprehensive bill for a patient
DELIMITER //
CREATE PROCEDURE GeneratePatientBill(
    IN p_patient_id INT,
    IN p_start_date DATE,
    IN p_end_date DATE,
    IN p_insurance_coverage_percent DECIMAL(5,2),
    IN p_tax_rate DECIMAL(5,4),
    IN p_created_by INT,
    OUT p_bill_id INT,
    OUT p_result_message VARCHAR(500)
)
BEGIN
    DECLARE v_patient_exists INT DEFAULT 0;
    DECLARE v_total_treatments DECIMAL(12,2) DEFAULT 0;
    DECLARE v_total_medications DECIMAL(12,2) DEFAULT 0;
    DECLARE v_total_rooms DECIMAL(12,2) DEFAULT 0;
    DECLARE v_subtotal DECIMAL(12,2) DEFAULT 0;
    DECLARE v_insurance_coverage DECIMAL(12,2) DEFAULT 0;
    DECLARE v_tax_amount DECIMAL(12,2) DEFAULT 0;
    DECLARE v_item_id INT DEFAULT 0;
    DECLARE v_temp_message VARCHAR(500) DEFAULT '';
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        GET DIAGNOSTICS CONDITION 1
            p_result_message = MESSAGE_TEXT;
        SET p_bill_id = -1;
    END;
    
    START TRANSACTION;
    
    -- Validate patient exists
    SELECT COUNT(*) INTO v_patient_exists 
    FROM Patients 
    WHERE patient_id = p_patient_id AND status = 'Active';
    
    IF v_patient_exists = 0 THEN
        SET p_result_message = 'Patient not found or inactive';
        SET p_bill_id = -1;
        ROLLBACK;
    END IF;
    
    -- Calculate total treatment costs
    SELECT COALESCE(SUM(cost), 0) INTO v_total_treatments
    FROM Treatments
    WHERE patient_id = p_patient_id
      AND DATE(treatment_date) BETWEEN p_start_date AND p_end_date
      AND status = 'Completed';
    
    -- Calculate total medication costs
    SELECT COALESCE(SUM(m.unit_price * p.quantity_dispensed), 0) INTO v_total_medications
    FROM Prescriptions p
    JOIN Medications m ON p.medication_id = m.medication_id
    WHERE p.patient_id = p_patient_id
      AND DATE(p.prescription_date) BETWEEN p_start_date AND p_end_date
      AND p.quantity_dispensed > 0;
    
    -- Calculate subtotal
    SET v_subtotal = v_total_treatments + v_total_medications;
    
    -- Calculate insurance coverage
    SET v_insurance_coverage = v_subtotal * (COALESCE(p_insurance_coverage_percent, 0) / 100);
    
    -- Calculate tax on patient responsibility
    SET v_tax_amount = (v_subtotal - v_insurance_coverage) * COALESCE(p_tax_rate, 0);
    
    -- Create the bill
    CALL CreateBill(
        p_patient_id, v_subtotal, v_insurance_coverage, 0, p_tax_rate, 30,
        NULL, CONCAT('Comprehensive bill for services from ', p_start_date, ' to ', p_end_date),
        p_created_by, p_bill_id, p_result_message
    );
    
    IF p_bill_id > 0 THEN
        -- Add treatment items to bill
        INSERT INTO Bill_Items (bill_id, service_type, service_description, quantity, unit_price, total_price, service_date, service_provider_id, department_id, treatment_id)
        SELECT 
            p_bill_id, 'Treatment', t.treatment_name, 1, t.cost, t.cost, 
            DATE(t.treatment_date), t.staff_id, ms.department_id, t.treatment_id
        FROM Treatments t
        JOIN Medical_Staff ms ON t.staff_id = ms.staff_id
        WHERE t.patient_id = p_patient_id
          AND DATE(t.treatment_date) BETWEEN p_start_date AND p_end_date
          AND t.status = 'Completed';
        
        -- Add medication items to bill
        INSERT INTO Bill_Items (bill_id, service_type, service_description, quantity, unit_price, total_price, service_date, service_provider_id, prescription_id)
        SELECT 
            p_bill_id, 'Medication', m.medication_name, pr.quantity_dispensed, 
            m.unit_price, (m.unit_price * pr.quantity_dispensed), 
            DATE(pr.prescription_date), pr.staff_id, pr.prescription_id
        FROM Prescriptions pr
        JOIN Medications m ON pr.medication_id = m.medication_id
        WHERE pr.patient_id = p_patient_id
          AND DATE(pr.prescription_date) BETWEEN p_start_date AND p_end_date
          AND pr.quantity_dispensed > 0;
        
        SET p_result_message = CONCAT('Bill generated successfully. Total: $', v_subtotal, ', Insurance: $', v_insurance_coverage);
    END IF;
    
    COMMIT;
END//
DELIMITER ;

-- Procedure to calculate and add room charges for a patient stay
DELIMITER //
CREATE PROCEDURE CalculateRoomCharges(
    IN p_patient_id INT,
    IN p_room_id INT,
    IN p_admission_date DATE,
    IN p_discharge_date DATE,
    OUT p_total_room_charges DECIMAL(12,2),
    OUT p_result_message VARCHAR(500)
)
BEGIN
    DECLARE v_daily_rate DECIMAL(8,2) DEFAULT 0;
    DECLARE v_room_number VARCHAR(10) DEFAULT '';
    DECLARE v_room_type VARCHAR(20) DEFAULT '';
    DECLARE v_days_count INT DEFAULT 0;
    
    -- Get room details
    SELECT daily_rate, room_number, room_type
    INTO v_daily_rate, v_room_number, v_room_type
    FROM Rooms
    WHERE room_id = p_room_id;
    
    IF v_daily_rate IS NULL THEN
        SET p_result_message = 'Room not found';
        SET p_total_room_charges = 0;
    ELSE
        -- Calculate number of days (minimum 1 day)
        SET v_days_count = GREATEST(DATEDIFF(p_discharge_date, p_admission_date), 1);
        
        -- Calculate total charges
        SET p_total_room_charges = v_daily_rate * v_days_count;
        
        SET p_result_message = CONCAT(
            'Room charges calculated: ', v_room_type, ' Room ', v_room_number, 
            ' for ', v_days_count, ' days at $', v_daily_rate, '/day = $', p_total_room_charges
        );
    END IF;
END//
DELIMITER ;

-- Procedure to apply insurance coverage and calculate patient responsibility
DELIMITER //
CREATE PROCEDURE ApplyInsuranceCoverage(
    IN p_bill_id INT,
    IN p_coverage_percentage DECIMAL(5,2),
    IN p_deductible DECIMAL(12,2),
    IN p_copay DECIMAL(12,2),
    IN p_max_coverage DECIMAL(12,2),
    OUT p_result_message VARCHAR(500)
)
BEGIN
    DECLARE v_bill_total DECIMAL(12,2) DEFAULT 0;
    DECLARE v_calculated_coverage DECIMAL(12,2) DEFAULT 0;
    DECLARE v_final_coverage DECIMAL(12,2) DEFAULT 0;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        GET DIAGNOSTICS CONDITION 1
            p_result_message = MESSAGE_TEXT;
    END;
    
    START TRANSACTION;
    
    -- Get current bill total
    SELECT total_amount INTO v_bill_total
    FROM Billing
    WHERE bill_id = p_bill_id;
    
    IF v_bill_total IS NULL THEN
        SET p_result_message = 'Bill not found';
        ROLLBACK;
    END IF;
    
    -- Calculate insurance coverage
    -- First apply deductible
    SET v_calculated_coverage = GREATEST(v_bill_total - COALESCE(p_deductible, 0), 0);
    
    -- Then apply coverage percentage
    SET v_calculated_coverage = v_calculated_coverage * (COALESCE(p_coverage_percentage, 0) / 100);
    
    -- Apply maximum coverage limit if specified
    IF p_max_coverage IS NOT NULL AND p_max_coverage > 0 THEN
        SET v_calculated_coverage = LEAST(v_calculated_coverage, p_max_coverage);
    END IF;
    
    -- Final coverage is calculated coverage minus copay
    SET v_final_coverage = GREATEST(v_calculated_coverage - COALESCE(p_copay, 0), 0);
    
    -- Update bill with insurance information
    UPDATE Billing
    SET insurance_coverage = v_final_coverage,
        insurance_deductible = COALESCE(p_deductible, 0),
        insurance_copay = COALESCE(p_copay, 0),
        updated_date = CURRENT_TIMESTAMP
    WHERE bill_id = p_bill_id;
    
    SET p_result_message = CONCAT(
        'Insurance applied: Coverage $', v_final_coverage, 
        ', Deductible $', COALESCE(p_deductible, 0),
        ', Copay $', COALESCE(p_copay, 0)
    );
    
    COMMIT;
END//
DELIMITER ;

-- Procedure to generate monthly billing summary for all patients
DELIMITER //
CREATE PROCEDURE GenerateMonthlyBillingSummary(
    IN p_year INT,
    IN p_month INT
)
BEGIN
    DECLARE v_start_date DATE;
    DECLARE v_end_date DATE;
    
    SET v_start_date = DATE(CONCAT(p_year, '-', LPAD(p_month, 2, '0'), '-01'));
    SET v_end_date = LAST_DAY(v_start_date);
    
    -- Overall summary
    SELECT 
        'Monthly Billing Summary' AS report_section,
        COUNT(DISTINCT b.bill_id) AS total_bills,
        COUNT(DISTINCT b.patient_id) AS unique_patients,
        SUM(b.total_amount) AS total_billed,
        SUM(b.insurance_coverage) AS total_insurance_coverage,
        SUM(b.discount_amount) AS total_discounts,
        SUM(b.final_amount) AS total_patient_responsibility,
        SUM(CASE WHEN b.payment_status = 'Paid' THEN b.final_amount ELSE 0 END) AS total_collected,
        SUM(CASE WHEN b.payment_status IN ('Pending', 'Partial') THEN b.final_amount ELSE 0 END) AS total_outstanding
    FROM Billing b
    WHERE DATE(b.bill_date) BETWEEN v_start_date AND v_end_date;
    
    -- Payment method breakdown
    SELECT 
        'Payment Method Breakdown' AS report_section,
        p.payment_method,
        COUNT(*) AS transaction_count,
        SUM(p.amount_paid - p.refund_amount) AS net_collected
    FROM Payments p
    JOIN Billing b ON p.bill_id = b.bill_id
    WHERE DATE(p.payment_date) BETWEEN v_start_date AND v_end_date
      AND p.payment_status = 'Completed'
    GROUP BY p.payment_method
    ORDER BY net_collected DESC;
    
    -- Service type revenue breakdown
    SELECT 
        'Service Revenue Breakdown' AS report_section,
        bi.service_type,
        COUNT(*) AS item_count,
        SUM(bi.total_price) AS total_revenue,
        AVG(bi.total_price) AS avg_item_value
    FROM Bill_Items bi
    JOIN Billing b ON bi.bill_id = b.bill_id
    WHERE DATE(b.bill_date) BETWEEN v_start_date AND v_end_date
    GROUP BY bi.service_type
    ORDER BY total_revenue DESC;
    
    -- Top revenue generating departments
    SELECT 
        'Department Revenue' AS report_section,
        d.department_name,
        COUNT(bi.item_id) AS services_provided,
        SUM(bi.total_price) AS department_revenue
    FROM Bill_Items bi
    JOIN Billing b ON bi.bill_id = b.bill_id
    JOIN Departments d ON bi.department_id = d.department_id
    WHERE DATE(b.bill_date) BETWEEN v_start_date AND v_end_date
    GROUP BY d.department_id, d.department_name
    ORDER BY department_revenue DESC;
END//
DELIMITER ;

-- Procedure to process bulk payments (for insurance payments)
DELIMITER //
CREATE PROCEDURE ProcessBulkInsurancePayment(
    IN p_insurance_provider VARCHAR(100),
    IN p_payment_amount DECIMAL(12,2),
    IN p_transaction_reference VARCHAR(100),
    IN p_processed_by INT,
    OUT p_bills_processed INT,
    OUT p_result_message VARCHAR(500)
)
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_bill_id INT;
    DECLARE v_outstanding_amount DECIMAL(12,2);
    DECLARE v_payment_amount DECIMAL(12,2);
    DECLARE v_remaining_payment DECIMAL(12,2);
    DECLARE v_payment_id INT;
    DECLARE v_temp_message VARCHAR(500);
    
    -- Cursor for bills with outstanding insurance coverage
    DECLARE bill_cursor CURSOR FOR
        SELECT b.bill_id, (b.insurance_coverage - COALESCE(paid.total_paid, 0)) AS outstanding
        FROM Billing b
        JOIN Patients p ON b.patient_id = p.patient_id
        LEFT JOIN (
            SELECT bill_id, SUM(amount_paid - refund_amount) AS total_paid
            FROM Payments 
            WHERE payment_method = 'Insurance' AND payment_status = 'Completed'
            GROUP BY bill_id
        ) paid ON b.bill_id = paid.bill_id
        WHERE p.insurance_provider = p_insurance_provider
          AND b.insurance_coverage > COALESCE(paid.total_paid, 0)
          AND b.payment_status IN ('Pending', 'Partial')
        ORDER BY b.bill_date ASC;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        GET DIAGNOSTICS CONDITION 1
            p_result_message = MESSAGE_TEXT;
        SET p_bills_processed = -1;
    END;
    
    START TRANSACTION;
    
    SET v_remaining_payment = p_payment_amount;
    SET p_bills_processed = 0;
    
    OPEN bill_cursor;
    
    read_loop: LOOP
        FETCH bill_cursor INTO v_bill_id, v_outstanding_amount;
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        -- Calculate payment amount for this bill
        SET v_payment_amount = LEAST(v_outstanding_amount, v_remaining_payment);
        
        IF v_payment_amount > 0 THEN
            -- Process payment for this bill
            CALL ProcessPayment(
                v_bill_id, v_payment_amount, 'Insurance', p_transaction_reference,
                NULL, NULL, NULL, p_insurance_provider, NULL,
                CONCAT('Bulk insurance payment - ', p_insurance_provider),
                p_processed_by, v_payment_id, v_temp_message
            );
            
            IF v_payment_id > 0 THEN
                SET p_bills_processed = p_bills_processed + 1;
                SET v_remaining_payment = v_remaining_payment - v_payment_amount;
                
                -- If no remaining payment, exit loop
                IF v_remaining_payment <= 0 THEN
                    LEAVE read_loop;
                END IF;
            END IF;
        END IF;
    END LOOP;
    
    CLOSE bill_cursor;
    
    SET p_result_message = CONCAT(
        'Bulk payment processed: $', (p_payment_amount - v_remaining_payment), 
        ' applied to ', p_bills_processed, ' bills. Remaining: $', v_remaining_payment
    );
    
    COMMIT;
END//
DELIMITER ;

-- Create a view for billing analytics
CREATE VIEW Billing_Analytics AS
SELECT 
    DATE_FORMAT(b.bill_date, '%Y-%m') AS billing_month,
    COUNT(b.bill_id) AS total_bills,
    SUM(b.total_amount) AS total_billed,
    SUM(b.insurance_coverage) AS total_insurance,
    SUM(b.discount_amount) AS total_discounts,
    SUM(b.final_amount) AS total_patient_responsibility,
    SUM(CASE WHEN b.payment_status = 'Paid' THEN b.final_amount ELSE 0 END) AS total_collected,
    SUM(CASE WHEN b.payment_status IN ('Pending', 'Partial') THEN b.final_amount ELSE 0 END) AS total_outstanding,
    ROUND(SUM(CASE WHEN b.payment_status = 'Paid' THEN b.final_amount ELSE 0 END) / SUM(b.final_amount) * 100, 2) AS collection_rate_percent
FROM Billing b
GROUP BY DATE_FORMAT(b.bill_date, '%Y-%m')
ORDER BY billing_month DESC;

-- Show created procedures and views
SHOW PROCEDURE STATUS WHERE Db = 'hospital_management_system' 
AND Name IN ('GeneratePatientBill', 'CalculateRoomCharges', 'ApplyInsuranceCoverage', 
             'GenerateMonthlyBillingSummary', 'ProcessBulkInsurancePayment');

SHOW CREATE VIEW Billing_Analytics;

-- Confirmation message
SELECT 'Billing calculation procedures created successfully!' AS Status;