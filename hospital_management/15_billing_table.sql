-- Hospital Management System - Billing Table
-- This script creates the Billing table with comprehensive insurance support and payment tracking

USE hospital_management_system;

-- Create Billing table with insurance support
CREATE TABLE Billing (
    bill_id INT PRIMARY KEY AUTO_INCREMENT,
    patient_id INT NOT NULL,
    bill_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    total_amount DECIMAL(12,2) NOT NULL,
    insurance_coverage DECIMAL(12,2) DEFAULT 0,
    insurance_deductible DECIMAL(12,2) DEFAULT 0,
    insurance_copay DECIMAL(12,2) DEFAULT 0,
    patient_responsibility DECIMAL(12,2) NOT NULL,
    discount_amount DECIMAL(12,2) DEFAULT 0,
    tax_amount DECIMAL(12,2) DEFAULT 0,
    final_amount DECIMAL(12,2) NOT NULL,
    payment_status ENUM('Pending', 'Partial', 'Paid', 'Overdue', 'Cancelled', 'Refunded') DEFAULT 'Pending',
    due_date DATE,
    insurance_claim_number VARCHAR(100),
    insurance_approval_date DATE,
    insurance_denial_reason TEXT,
    billing_address TEXT,
    billing_notes TEXT,
    created_by INT,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- Foreign key constraints
    FOREIGN KEY (patient_id) REFERENCES Patients(patient_id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (created_by) REFERENCES Medical_Staff(staff_id) ON DELETE SET NULL ON UPDATE CASCADE,
    
    -- Constraints for data validation
    CONSTRAINT chk_billing_total_amount CHECK (total_amount >= 0),
    CONSTRAINT chk_billing_insurance_coverage CHECK (insurance_coverage >= 0),
    CONSTRAINT chk_billing_patient_responsibility CHECK (patient_responsibility >= 0),
    CONSTRAINT chk_billing_discount CHECK (discount_amount >= 0),
    CONSTRAINT chk_billing_tax CHECK (tax_amount >= 0),
    CONSTRAINT chk_billing_final_amount CHECK (final_amount >= 0),
    CONSTRAINT chk_billing_due_date CHECK (due_date IS NULL OR due_date >= DATE(bill_date))
);

-- Create indexes for performance
CREATE INDEX idx_billing_patient ON Billing(patient_id, bill_date DESC);
CREATE INDEX idx_billing_status ON Billing(payment_status);
CREATE INDEX idx_billing_due_date ON Billing(due_date);
CREATE INDEX idx_billing_insurance_claim ON Billing(insurance_claim_number);
CREATE INDEX idx_billing_date ON Billing(bill_date);

-- Create a trigger to automatically calculate final amount
DELIMITER //
CREATE TRIGGER trg_billing_calculate_final_amount
BEFORE INSERT ON Billing
FOR EACH ROW
BEGIN
    -- Calculate patient responsibility if not provided
    IF NEW.patient_responsibility = 0 THEN
        SET NEW.patient_responsibility = GREATEST(
            NEW.total_amount - NEW.insurance_coverage - NEW.discount_amount, 
            0
        );
    END IF;
    
    -- Calculate final amount (patient responsibility + tax - any additional discounts)
    SET NEW.final_amount = NEW.patient_responsibility + NEW.tax_amount;
    
    -- Set due date if not provided (30 days from bill date)
    IF NEW.due_date IS NULL THEN
        SET NEW.due_date = DATE_ADD(DATE(NEW.bill_date), INTERVAL 30 DAY);
    END IF;
END//
DELIMITER ;

-- Create trigger for updates
DELIMITER //
CREATE TRIGGER trg_billing_update_final_amount
BEFORE UPDATE ON Billing
FOR EACH ROW
BEGIN
    -- Recalculate patient responsibility if amounts changed
    IF NEW.total_amount != OLD.total_amount OR 
       NEW.insurance_coverage != OLD.insurance_coverage OR 
       NEW.discount_amount != OLD.discount_amount THEN
        SET NEW.patient_responsibility = GREATEST(
            NEW.total_amount - NEW.insurance_coverage - NEW.discount_amount, 
            0
        );
    END IF;
    
    -- Recalculate final amount
    SET NEW.final_amount = NEW.patient_responsibility + NEW.tax_amount;
END//
DELIMITER ;

-- Create a procedure to create a new bill
DELIMITER //
CREATE PROCEDURE CreateBill(
    IN p_patient_id INT,
    IN p_total_amount DECIMAL(12,2),
    IN p_insurance_coverage DECIMAL(12,2),
    IN p_discount_amount DECIMAL(12,2),
    IN p_tax_rate DECIMAL(5,4),
    IN p_due_days INT,
    IN p_insurance_claim_number VARCHAR(100),
    IN p_billing_notes TEXT,
    IN p_created_by INT,
    OUT p_bill_id INT,
    OUT p_result_message VARCHAR(500)
)
BEGIN
    DECLARE v_patient_exists INT DEFAULT 0;
    DECLARE v_tax_amount DECIMAL(12,2) DEFAULT 0;
    DECLARE v_due_date DATE;
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
    
    -- Calculate tax amount
    SET v_tax_amount = (p_total_amount - COALESCE(p_discount_amount, 0)) * COALESCE(p_tax_rate, 0);
    
    -- Calculate due date
    SET v_due_date = DATE_ADD(CURDATE(), INTERVAL COALESCE(p_due_days, 30) DAY);
    
    -- Insert the bill
    INSERT INTO Billing (
        patient_id, total_amount, insurance_coverage, discount_amount, 
        tax_amount, due_date, insurance_claim_number, billing_notes, created_by
    ) VALUES (
        p_patient_id, p_total_amount, COALESCE(p_insurance_coverage, 0), 
        COALESCE(p_discount_amount, 0), v_tax_amount, v_due_date, 
        p_insurance_claim_number, p_billing_notes, p_created_by
    );
    
    SET p_bill_id = LAST_INSERT_ID();
    SET p_result_message = 'Bill created successfully';
    
    COMMIT;
END//
DELIMITER ;

-- Create a procedure to update insurance information
DELIMITER //
CREATE PROCEDURE UpdateInsuranceInformation(
    IN p_bill_id INT,
    IN p_insurance_coverage DECIMAL(12,2),
    IN p_insurance_deductible DECIMAL(12,2),
    IN p_insurance_copay DECIMAL(12,2),
    IN p_insurance_claim_number VARCHAR(100),
    IN p_insurance_approval_date DATE,
    IN p_insurance_denial_reason TEXT,
    OUT p_result_message VARCHAR(500)
)
BEGIN
    DECLARE v_bill_exists INT DEFAULT 0;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        GET DIAGNOSTICS CONDITION 1
            p_result_message = MESSAGE_TEXT;
    END;
    
    START TRANSACTION;
    
    -- Check if bill exists
    SELECT COUNT(*) INTO v_bill_exists 
    FROM Billing 
    WHERE bill_id = p_bill_id;
    
    IF v_bill_exists = 0 THEN
        SET p_result_message = 'Bill not found';
        ROLLBACK;
    END IF;
    
    -- Update insurance information
    UPDATE Billing 
    SET insurance_coverage = COALESCE(p_insurance_coverage, insurance_coverage),
        insurance_deductible = COALESCE(p_insurance_deductible, insurance_deductible),
        insurance_copay = COALESCE(p_insurance_copay, insurance_copay),
        insurance_claim_number = COALESCE(p_insurance_claim_number, insurance_claim_number),
        insurance_approval_date = COALESCE(p_insurance_approval_date, insurance_approval_date),
        insurance_denial_reason = COALESCE(p_insurance_denial_reason, insurance_denial_reason),
        updated_date = CURRENT_TIMESTAMP
    WHERE bill_id = p_bill_id;
    
    SET p_result_message = 'Insurance information updated successfully';
    
    COMMIT;
END//
DELIMITER ;

-- Create a procedure to apply discount
DELIMITER //
CREATE PROCEDURE ApplyDiscount(
    IN p_bill_id INT,
    IN p_discount_amount DECIMAL(12,2),
    IN p_discount_reason VARCHAR(200),
    OUT p_result_message VARCHAR(500)
)
BEGIN
    DECLARE v_bill_exists INT DEFAULT 0;
    DECLARE v_current_total DECIMAL(12,2) DEFAULT 0;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        GET DIAGNOSTICS CONDITION 1
            p_result_message = MESSAGE_TEXT;
    END;
    
    START TRANSACTION;
    
    -- Check if bill exists and get current total
    SELECT COUNT(*), MAX(total_amount) INTO v_bill_exists, v_current_total
    FROM Billing 
    WHERE bill_id = p_bill_id;
    
    IF v_bill_exists = 0 THEN
        SET p_result_message = 'Bill not found';
        ROLLBACK;
    END IF;
    
    -- Validate discount amount
    IF p_discount_amount > v_current_total THEN
        SET p_result_message = 'Discount amount cannot exceed total bill amount';
        ROLLBACK;
    END IF;
    
    -- Apply discount
    UPDATE Billing 
    SET discount_amount = p_discount_amount,
        billing_notes = CONCAT(
            COALESCE(billing_notes, ''), 
            '\nDiscount Applied: $', p_discount_amount, 
            ' - Reason: ', COALESCE(p_discount_reason, 'Not specified')
        ),
        updated_date = CURRENT_TIMESTAMP
    WHERE bill_id = p_bill_id;
    
    SET p_result_message = CONCAT('Discount of $', p_discount_amount, ' applied successfully');
    
    COMMIT;
END//
DELIMITER ;

-- Create a view for billing summary with patient information
CREATE VIEW Billing_Summary AS
SELECT 
    b.bill_id,
    b.bill_date,
    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
    p.insurance_provider,
    p.insurance_policy_number,
    b.total_amount,
    b.insurance_coverage,
    b.discount_amount,
    b.tax_amount,
    b.patient_responsibility,
    b.final_amount,
    b.payment_status,
    b.due_date,
    DATEDIFF(b.due_date, CURDATE()) AS days_until_due,
    CASE 
        WHEN b.payment_status = 'Paid' THEN 0
        WHEN b.due_date < CURDATE() AND b.payment_status != 'Paid' THEN b.final_amount
        ELSE 0
    END AS overdue_amount,
    b.insurance_claim_number,
    b.insurance_approval_date,
    CONCAT(staff.first_name, ' ', staff.last_name) AS created_by_name
FROM Billing b
JOIN Patients p ON b.patient_id = p.patient_id
LEFT JOIN Medical_Staff staff ON b.created_by = staff.staff_id
ORDER BY b.bill_date DESC;

-- Create a view for overdue bills
CREATE VIEW Overdue_Bills AS
SELECT 
    b.bill_id,
    b.bill_date,
    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
    p.phone AS patient_phone,
    p.email AS patient_email,
    b.final_amount AS overdue_amount,
    b.due_date,
    DATEDIFF(CURDATE(), b.due_date) AS days_overdue,
    b.payment_status,
    b.insurance_claim_number
FROM Billing b
JOIN Patients p ON b.patient_id = p.patient_id
WHERE b.due_date < CURDATE() 
  AND b.payment_status IN ('Pending', 'Partial')
  AND p.status = 'Active'
ORDER BY b.due_date ASC;

-- Create a function to calculate total outstanding balance for a patient
DELIMITER //
CREATE FUNCTION GetPatientOutstandingBalance(p_patient_id INT)
RETURNS DECIMAL(12,2)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_outstanding_balance DECIMAL(12,2) DEFAULT 0;
    
    SELECT COALESCE(SUM(final_amount), 0) INTO v_outstanding_balance
    FROM Billing
    WHERE patient_id = p_patient_id
      AND payment_status IN ('Pending', 'Partial', 'Overdue');
    
    RETURN v_outstanding_balance;
END//
DELIMITER ;

-- Display table structure
DESCRIBE Billing;

-- Show created views, procedures, and functions
SHOW CREATE VIEW Billing_Summary;
SHOW CREATE VIEW Overdue_Bills;
SHOW PROCEDURE STATUS WHERE Name IN ('CreateBill', 'UpdateInsuranceInformation', 'ApplyDiscount');
SHOW FUNCTION STATUS WHERE Name = 'GetPatientOutstandingBalance';

-- Confirmation message
SELECT 'Billing table created successfully with comprehensive insurance support!' AS Status;