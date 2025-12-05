-- Hospital Management System - Common Operational Queries
-- This script contains frequently used queries for daily hospital operations

USE hospital_management_system;

-- Create procedures for common operational queries

-- 1. Patient lookup and registration queries
DELIMITER //
CREATE PROCEDURE SearchPatients(
    IN p_search_term VARCHAR(100)
)
BEGIN
    SELECT 
        patient_id,
        CONCAT(first_name, ' ', last_name) AS patient_name,
        date_of_birth,
        TIMESTAMPDIFF(YEAR, date_of_birth, CURDATE()) AS age,
        gender,
        phone,
        email,
        insurance_provider,
        status
    FROM Patients
    WHERE (first_name LIKE CONCAT('%', p_search_term, '%')
       OR last_name LIKE CONCAT('%', p_search_term, '%')
       OR phone LIKE CONCAT('%', p_search_term, '%')
       OR email LIKE CONCAT('%', p_search_term, '%'))
      AND status = 'Active'
    ORDER BY last_name, first_name;
END//
DELIMITER ;

-- 2. Today's appointments for a department
DELIMITER //
CREATE PROCEDURE GetTodaysAppointments(
    IN p_department_id INT
)
BEGIN
    SELECT 
        a.appointment_id,
        a.appointment_time,
        ADDTIME(a.appointment_time, SEC_TO_TIME(a.duration_minutes * 60)) AS end_time,
        CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
        p.phone AS patient_phone,
        CONCAT(ms.first_name, ' ', ms.last_name) AS doctor_name,
        a.purpose,
        a.status,
        r.room_number
    FROM Appointments a
    JOIN Patients p ON a.patient_id = p.patient_id
    JOIN Medical_Staff ms ON a.staff_id = ms.staff_id
    LEFT JOIN Rooms r ON a.room_id = r.room_id
    WHERE a.appointment_date = CURDATE()
      AND (p_department_id IS NULL OR ms.department_id = p_department_id)
      AND a.status IN ('Scheduled', 'Rescheduled')
    ORDER BY a.appointment_time;
END//
DELIMITER ;

-- 3. Available rooms by type
DELIMITER //
CREATE PROCEDURE GetAvailableRooms(
    IN p_room_type VARCHAR(20),
    IN p_department_id INT
)
BEGIN
    SELECT 
        r.room_id,
        r.room_number,
        r.room_type,
        r.capacity,
        r.current_occupancy,
        (r.capacity - r.current_occupancy) AS available_beds,
        r.daily_rate,
        d.department_name
    FROM Rooms r
    LEFT JOIN Departments d ON r.department_id = d.department_id
    WHERE r.status IN ('Available', 'Occupied')
      AND r.current_occupancy < r.capacity
      AND (p_room_type IS NULL OR r.room_type = p_room_type)
      AND (p_department_id IS NULL OR r.department_id = p_department_id)
    ORDER BY r.room_type, r.room_number;
END//
DELIMITER ;

-- 4. Patient's current medications
DELIMITER //
CREATE PROCEDURE GetPatientCurrentMedications(
    IN p_patient_id INT
)
BEGIN
    SELECT 
        pr.prescription_id,
        m.medication_name,
        m.generic_name,
        pr.dosage,
        pr.frequency,
        pr.start_date,
        pr.end_date,
        pr.refills_remaining,
        pr.indication,
        pr.instructions,
        CONCAT(ms.first_name, ' ', ms.last_name) AS prescriber
    FROM Prescriptions pr
    JOIN Medications m ON pr.medication_id = m.medication_id
    JOIN Medical_Staff ms ON pr.staff_id = ms.staff_id
    WHERE pr.patient_id = p_patient_id
      AND pr.status = 'Active'
      AND pr.end_date >= CURDATE()
    ORDER BY pr.prescription_date DESC;
END//
DELIMITER ;

-- 5. Staff schedule for today
DELIMITER //
CREATE PROCEDURE GetStaffScheduleToday(
    IN p_staff_id INT
)
BEGIN
    SELECT 
        a.appointment_time,
        ADDTIME(a.appointment_time, SEC_TO_TIME(a.duration_minutes * 60)) AS end_time,
        CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
        a.purpose,
        a.status,
        r.room_number,
        a.notes
    FROM Appointments a
    JOIN Patients p ON a.patient_id = p.patient_id
    LEFT JOIN Rooms r ON a.room_id = r.room_id
    WHERE a.staff_id = p_staff_id
      AND a.appointment_date = CURDATE()
      AND a.status IN ('Scheduled', 'Rescheduled', 'Completed')
    ORDER BY a.appointment_time;
END//
DELIMITER ;

-- 6. Pending lab results or follow-ups
DELIMITER //
CREATE PROCEDURE GetPendingFollowUps(
    IN p_days_ahead INT
)
BEGIN
    DECLARE v_end_date DATE;
    SET v_end_date = DATE_ADD(CURDATE(), INTERVAL COALESCE(p_days_ahead, 7) DAY);
    
    SELECT 
        mr.record_id,
        CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
        p.phone AS patient_phone,
        mr.follow_up_date,
        mr.diagnosis,
        mr.visit_date AS last_visit,
        CONCAT(ms.first_name, ' ', ms.last_name) AS doctor_name,
        DATEDIFF(mr.follow_up_date, CURDATE()) AS days_until_followup
    FROM Medical_Records mr
    JOIN Patients p ON mr.patient_id = p.patient_id
    JOIN Medical_Staff ms ON mr.staff_id = ms.staff_id
    WHERE mr.follow_up_required = TRUE
      AND mr.follow_up_date BETWEEN CURDATE() AND v_end_date
      AND p.status = 'Active'
    ORDER BY mr.follow_up_date;
END//
DELIMITER ;

-- 7. Emergency department dashboard
DELIMITER //
CREATE PROCEDURE GetEmergencyDashboard()
BEGIN
    -- Current ER patients
    SELECT 'Current ER Patients' AS section;
    SELECT 
        CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
        a.appointment_time AS arrival_time,
        a.purpose AS chief_complaint,
        r.room_number,
        CONCAT(ms.first_name, ' ', ms.last_name) AS attending_physician
    FROM Appointments a
    JOIN Patients p ON a.patient_id = p.patient_id
    JOIN Medical_Staff ms ON a.staff_id = ms.staff_id
    LEFT JOIN Rooms r ON a.room_id = r.room_id
    WHERE a.appointment_date = CURDATE()
      AND ms.department_id = 1  -- Emergency department
      AND a.status IN ('Scheduled', 'In Progress')
    ORDER BY a.appointment_time;
    
    -- Available ER rooms
    SELECT 'Available ER Rooms' AS section;
    SELECT 
        room_number,
        capacity,
        current_occupancy,
        status
    FROM Rooms
    WHERE room_type = 'Emergency'
      AND status IN ('Available', 'Occupied')
      AND current_occupancy < capacity;
END//
DELIMITER ;

-- 8. Billing and payment queries
DELIMITER //
CREATE PROCEDURE GetUnpaidBills(
    IN p_days_overdue INT
)
BEGIN
    DECLARE v_cutoff_date DATE;
    SET v_cutoff_date = DATE_SUB(CURDATE(), INTERVAL COALESCE(p_days_overdue, 30) DAY);
    
    SELECT 
        b.bill_id,
        CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
        p.phone AS patient_phone,
        b.bill_date,
        b.final_amount,
        b.due_date,
        DATEDIFF(CURDATE(), b.due_date) AS days_overdue,
        b.payment_status,
        COALESCE(payments.total_paid, 0) AS amount_paid,
        (b.final_amount - COALESCE(payments.total_paid, 0)) AS balance_due
    FROM Billing b
    JOIN Patients p ON b.patient_id = p.patient_id
    LEFT JOIN (
        SELECT bill_id, SUM(amount_paid - refund_amount) AS total_paid
        FROM Payments 
        WHERE payment_status = 'Completed'
        GROUP BY bill_id
    ) payments ON b.bill_id = payments.bill_id
    WHERE b.payment_status IN ('Pending', 'Partial', 'Overdue')
      AND b.due_date <= v_cutoff_date
    ORDER BY b.due_date ASC;
END//
DELIMITER ;

-- 9. Medication inventory alerts
DELIMITER //
CREATE PROCEDURE GetInventoryAlerts()
BEGIN
    -- Low stock medications
    SELECT 'Low Stock Medications' AS alert_type;
    SELECT 
        medication_name,
        stock_quantity,
        minimum_stock_level,
        (minimum_stock_level - stock_quantity) AS shortage,
        supplier,
        unit_price,
        (minimum_stock_level - stock_quantity) * unit_price AS reorder_cost
    FROM Medications
    WHERE stock_quantity <= minimum_stock_level
    ORDER BY stock_quantity ASC;
    
    -- Expiring medications
    SELECT 'Expiring Medications (Next 30 Days)' AS alert_type;
    SELECT 
        medication_name,
        batch_number,
        expiry_date,
        stock_quantity,
        DATEDIFF(expiry_date, CURDATE()) AS days_until_expiry,
        (stock_quantity * unit_price) AS potential_loss
    FROM Medications
    WHERE expiry_date BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 30 DAY)
      AND stock_quantity > 0
    ORDER BY expiry_date ASC;
END//
DELIMITER ;

-- 10. Daily census report
DELIMITER //
CREATE PROCEDURE GetDailyCensusReport()
BEGIN
    SELECT 
        d.department_name,
        COUNT(DISTINCT r.room_id) AS total_rooms,
        SUM(r.capacity) AS total_capacity,
        SUM(r.current_occupancy) AS current_occupancy,
        ROUND((SUM(r.current_occupancy) / SUM(r.capacity)) * 100, 1) AS occupancy_rate,
        COUNT(CASE WHEN a.appointment_date = CURDATE() THEN 1 END) AS todays_appointments
    FROM Departments d
    LEFT JOIN Rooms r ON d.department_id = r.department_id
    LEFT JOIN Medical_Staff ms ON d.department_id = ms.department_id
    LEFT JOIN Appointments a ON ms.staff_id = a.staff_id AND a.appointment_date = CURDATE()
    WHERE d.department_id IN (1,2,3,4,5,6)  -- Exclude pharmacy
    GROUP BY d.department_id, d.department_name
    ORDER BY d.department_name;
END//
DELIMITER ;

-- Create views for common queries
CREATE VIEW Todays_Appointments AS
SELECT 
    a.appointment_id,
    a.appointment_time,
    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
    p.phone AS patient_phone,
    CONCAT(ms.first_name, ' ', ms.last_name) AS doctor_name,
    d.department_name,
    a.purpose,
    a.status,
    r.room_number
FROM Appointments a
JOIN Patients p ON a.patient_id = p.patient_id
JOIN Medical_Staff ms ON a.staff_id = ms.staff_id
JOIN Departments d ON ms.department_id = d.department_id
LEFT JOIN Rooms r ON a.room_id = r.room_id
WHERE a.appointment_date = CURDATE()
ORDER BY a.appointment_time;

CREATE VIEW Active_Patients_Summary AS
SELECT 
    p.patient_id,
    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
    p.date_of_birth,
    TIMESTAMPDIFF(YEAR, p.date_of_birth, CURDATE()) AS age,
    p.gender,
    p.phone,
    p.insurance_provider,
    COUNT(DISTINCT a.appointment_id) AS total_appointments,
    COUNT(DISTINCT mr.record_id) AS total_records,
    MAX(mr.visit_date) AS last_visit,
    GetPatientOutstandingBalance(p.patient_id) AS outstanding_balance
FROM Patients p
LEFT JOIN Appointments a ON p.patient_id = a.patient_id
LEFT JOIN Medical_Records mr ON p.patient_id = mr.patient_id
WHERE p.status = 'Active'
GROUP BY p.patient_id
ORDER BY p.last_name, p.first_name;

-- Show created procedures and views
SHOW PROCEDURE STATUS WHERE Db = 'hospital_management_system' 
AND Name IN ('SearchPatients', 'GetTodaysAppointments', 'GetAvailableRooms', 
             'GetPatientCurrentMedications', 'GetStaffScheduleToday', 'GetPendingFollowUps',
             'GetEmergencyDashboard', 'GetUnpaidBills', 'GetInventoryAlerts', 'GetDailyCensusReport');

SHOW CREATE VIEW Todays_Appointments;
SHOW CREATE VIEW Active_Patients_Summary;

-- Confirmation message
SELECT 'Common operational queries and procedures created successfully!' AS Status;