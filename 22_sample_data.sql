-- Hospital Management System - Sample Data Insertion
-- This script populates the database with realistic sample data for testing and demonstration

USE hospital_management_system;

-- Insert sample departments
INSERT INTO Departments (department_name, location, phone, description) VALUES
('Emergency Medicine', 'Building A, Floor 1', '555-0100', 'Emergency and trauma care'),
('Cardiology', 'Building B, Floor 3', '555-0101', 'Heart and cardiovascular care'),
('Pediatrics', 'Building C, Floor 2', '555-0102', 'Children healthcare services'),
('Orthopedics', 'Building A, Floor 4', '555-0103', 'Bone and joint care'),
('Neurology', 'Building B, Floor 5', '555-0104', 'Brain and nervous system care'),
('Oncology', 'Building D, Floor 2', '555-0105', 'Cancer treatment and care'),
('Pharmacy', 'Building A, Floor 1', '555-0106', 'Medication dispensing and management');

-- Insert sample medical staff
INSERT INTO Medical_Staff (first_name, last_name, role, specialization, department_id, phone, email, hire_date, license_number, license_expiry_date, salary) VALUES
('Dr. Sarah', 'Johnson', 'Doctor', 'Emergency Medicine', 1, '555-1001', 'sarah.johnson@hospital.com', '2020-01-15', 'MD001', '2025-01-15', 180000.00),
('Dr. Michael', 'Chen', 'Doctor', 'Cardiologist', 2, '555-1002', 'michael.chen@hospital.com', '2019-03-20', 'MD002', '2024-03-20', 220000.00),
('Dr. Emily', 'Rodriguez', 'Doctor', 'Pediatrician', 3, '555-1003', 'emily.rodriguez@hospital.com', '2021-06-10', 'MD003', '2026-06-10', 190000.00),
('Dr. James', 'Wilson', 'Doctor', 'Orthopedic Surgeon', 4, '555-1004', 'james.wilson@hospital.com', '2018-09-05', 'MD004', '2023-09-05', 250000.00),
('Dr. Lisa', 'Thompson', 'Doctor', 'Neurologist', 5, '555-1005', 'lisa.thompson@hospital.com', '2020-11-12', 'MD005', '2025-11-12', 210000.00),
('Nurse Mary', 'Davis', 'Nurse', 'Emergency Nursing', 1, '555-2001', 'mary.davis@hospital.com', '2021-02-01', 'RN001', '2024-02-01', 75000.00),
('Nurse John', 'Miller', 'Nurse', 'Cardiac Care', 2, '555-2002', 'john.miller@hospital.com', '2020-08-15', 'RN002', '2023-08-15', 78000.00),
('Nurse Jennifer', 'Brown', 'Nurse', 'Pediatric Care', 3, '555-2003', 'jennifer.brown@hospital.com', '2022-01-10', 'RN003', '2025-01-10', 72000.00),
('Tech Robert', 'Garcia', 'Technician', 'Radiology', 4, '555-3001', 'robert.garcia@hospital.com', '2021-05-20', 'RT001', '2024-05-20', 55000.00),
('Admin Susan', 'Lee', 'Administrator', 'Hospital Administration', 1, '555-4001', 'susan.lee@hospital.com', '2019-12-01', 'ADM001', '2024-12-01', 65000.00);

-- Update department heads
UPDATE Departments SET department_head_id = 1 WHERE department_id = 1; -- Dr. Sarah Johnson for Emergency
UPDATE Departments SET department_head_id = 2 WHERE department_id = 2; -- Dr. Michael Chen for Cardiology
UPDATE Departments SET department_head_id = 3 WHERE department_id = 3; -- Dr. Emily Rodriguez for Pediatrics

-- Insert sample rooms
INSERT INTO Rooms (room_number, room_type, department_id, capacity, daily_rate) VALUES
('ER-101', 'Emergency', 1, 1, 500.00),
('ER-102', 'Emergency', 1, 1, 500.00),
('ICU-201', 'ICU', 2, 1, 800.00),
('ICU-202', 'ICU', 2, 1, 800.00),
('PED-301', 'Private', 3, 1, 300.00),
('PED-302', 'General', 3, 2, 200.00),
('OR-401', 'Operating', 4, 1, 1200.00),
('OR-402', 'Operating', 4, 1, 1200.00),
('GEN-501', 'General', 5, 2, 150.00),
('GEN-502', 'General', 5, 2, 150.00),
('PRIV-601', 'Private', 2, 1, 400.00),
('PRIV-602', 'Private', 3, 1, 350.00);

-- Insert sample patients
INSERT INTO Patients (first_name, last_name, date_of_birth, gender, phone, email, address, emergency_contact_name, emergency_contact_phone, insurance_provider, insurance_policy_number) VALUES
('John', 'Smith', '1985-03-15', 'Male', '555-0001', 'john.smith@email.com', '123 Main St, City, State 12345', 'Jane Smith', '555-0002', 'Blue Cross', 'BC123456789'),
('Maria', 'Garcia', '1990-07-22', 'Female', '555-0003', 'maria.garcia@email.com', '456 Oak Ave, City, State 12345', 'Carlos Garcia', '555-0004', 'Aetna', 'AET987654321'),
('Robert', 'Johnson', '1978-11-08', 'Male', '555-0005', 'robert.johnson@email.com', '789 Pine St, City, State 12345', 'Linda Johnson', '555-0006', 'Cigna', 'CIG456789123'),
('Emily', 'Davis', '1995-02-14', 'Female', '555-0007', 'emily.davis@email.com', '321 Elm St, City, State 12345', 'Michael Davis', '555-0008', 'UnitedHealth', 'UH789123456'),
('David', 'Wilson', '1982-09-30', 'Male', '555-0009', 'david.wilson@email.com', '654 Maple Ave, City, State 12345', 'Sarah Wilson', '555-0010', 'Blue Cross', 'BC234567890'),
('Lisa', 'Anderson', '1988-12-05', 'Female', '555-0011', 'lisa.anderson@email.com', '987 Cedar St, City, State 12345', 'Mark Anderson', '555-0012', 'Aetna', 'AET345678901'),
('James', 'Taylor', '1975-06-18', 'Male', '555-0013', 'james.taylor@email.com', '147 Birch Ave, City, State 12345', 'Nancy Taylor', '555-0014', 'Medicare', 'MED456789012'),
('Jennifer', 'Martinez', '1992-04-25', 'Female', '555-0015', 'jennifer.martinez@email.com', '258 Spruce St, City, State 12345', 'Antonio Martinez', '555-0016', 'Medicaid', 'MCD567890123'),
('Christopher', 'Brown', '1980-01-12', 'Male', '555-0017', 'christopher.brown@email.com', '369 Willow Ave, City, State 12345', 'Michelle Brown', '555-0018', 'Cigna', 'CIG678901234'),
('Amanda', 'Jones', '1987-08-03', 'Female', '555-0019', 'amanda.jones@email.com', '741 Poplar St, City, State 12345', 'Kevin Jones', '555-0020', 'UnitedHealth', 'UH890123457');

-- Insert sample medications
INSERT INTO Medications (medication_name, generic_name, brand_name, manufacturer, dosage_form, strength, unit_price, stock_quantity, minimum_stock_level, expiry_date, batch_number, supplier) VALUES
('Aspirin 81mg', 'Acetylsalicylic Acid', 'Bayer Low Dose', 'Bayer', 'Tablet', '81mg', 0.15, 5000, 500, '2025-12-31', 'ASP001', 'PharmaCorp'),
('Ibuprofen 200mg', 'Ibuprofen', 'Advil', 'Pfizer', 'Tablet', '200mg', 0.25, 3000, 300, '2025-06-30', 'IBU001', 'MediSupply'),
('Acetaminophen 500mg', 'Acetaminophen', 'Tylenol', 'J&J', 'Tablet', '500mg', 0.20, 4000, 400, '2025-09-15', 'ACE001', 'HealthCorp'),
('Amoxicillin 250mg', 'Amoxicillin', 'Amoxil', 'GSK', 'Capsule', '250mg', 2.50, 1000, 100, '2025-03-20', 'AMX001', 'AntibioticCorp'),
('Lisinopril 10mg', 'Lisinopril', 'Prinivil', 'Merck', 'Tablet', '10mg', 0.80, 2000, 200, '2025-11-10', 'LIS001', 'CardioMeds'),
('Metformin 500mg', 'Metformin HCl', 'Glucophage', 'Bristol-Myers', 'Tablet', '500mg', 1.25, 1500, 150, '2025-08-25', 'MET001', 'DiabetesMeds'),
('Atorvastatin 20mg', 'Atorvastatin', 'Lipitor', 'Pfizer', 'Tablet', '20mg', 3.50, 800, 80, '2025-05-15', 'ATO001', 'CholesterolMeds'),
('Omeprazole 20mg', 'Omeprazole', 'Prilosec', 'AstraZeneca', 'Capsule', '20mg', 1.75, 1200, 120, '2025-07-30', 'OME001', 'GastroMeds'),
('Hydrochlorothiazide 25mg', 'HCTZ', 'Microzide', 'Capsugel', 'Tablet', '25mg', 0.60, 1800, 180, '2025-10-20', 'HCT001', 'DiureticMeds'),
('Prednisone 10mg', 'Prednisone', 'Deltasone', 'Pfizer', 'Tablet', '10mg', 0.90, 600, 60, '2025-04-10', 'PRE001', 'SteroidMeds');

-- Insert sample appointments
INSERT INTO Appointments (patient_id, staff_id, appointment_date, appointment_time, duration_minutes, purpose, room_id, created_by) VALUES
(1, 1, DATE_ADD(CURDATE(), INTERVAL 1 DAY), '09:00:00', 30, 'Annual checkup', 5, 10),
(2, 2, DATE_ADD(CURDATE(), INTERVAL 1 DAY), '10:00:00', 45, 'Cardiac consultation', 11, 10),
(3, 3, DATE_ADD(CURDATE(), INTERVAL 2 DAY), '14:00:00', 30, 'Pediatric checkup', 6, 10),
(4, 4, DATE_ADD(CURDATE(), INTERVAL 3 DAY), '11:00:00', 60, 'Orthopedic consultation', 7, 10),
(5, 5, DATE_ADD(CURDATE(), INTERVAL 2 DAY), '15:30:00', 45, 'Neurological assessment', 9, 10),
(6, 1, DATE_ADD(CURDATE(), INTERVAL 4 DAY), '08:30:00', 30, 'Follow-up visit', 1, 10),
(7, 2, DATE_ADD(CURDATE(), INTERVAL 5 DAY), '13:00:00', 30, 'Blood pressure check', 11, 10),
(8, 3, DATE_ADD(CURDATE(), INTERVAL 3 DAY), '16:00:00', 30, 'Vaccination', 12, 10),
(9, 4, DATE_ADD(CURDATE(), INTERVAL 6 DAY), '10:30:00', 90, 'Pre-surgery consultation', 7, 10),
(10, 5, DATE_ADD(CURDATE(), INTERVAL 4 DAY), '14:30:00', 45, 'Headache evaluation', 9, 10);

-- Insert sample medical records
INSERT INTO Medical_Records (patient_id, staff_id, record_type, chief_complaint, symptoms, diagnosis, treatment_plan, vital_signs, follow_up_required, follow_up_date) VALUES
(1, 1, 'Consultation', 'Annual physical exam', 'No acute symptoms', 'Healthy adult male', 'Continue current lifestyle, annual follow-up', '{"temperature": 98.6, "blood_pressure_systolic": 120, "blood_pressure_diastolic": 80, "heart_rate": 72, "respiratory_rate": 16, "oxygen_saturation": 98}', TRUE, DATE_ADD(CURDATE(), INTERVAL 365 DAY)),
(2, 2, 'Consultation', 'Chest pain', 'Intermittent chest discomfort, shortness of breath', 'Possible angina', 'ECG, stress test, cardiac enzymes', '{"temperature": 98.4, "blood_pressure_systolic": 140, "blood_pressure_diastolic": 90, "heart_rate": 88, "respiratory_rate": 18, "oxygen_saturation": 97}', TRUE, DATE_ADD(CURDATE(), INTERVAL 14 DAY)),
(3, 3, 'Consultation', 'Well-child visit', 'Normal growth and development', 'Healthy child', 'Routine vaccinations, next visit in 6 months', '{"temperature": 98.2, "blood_pressure_systolic": 95, "blood_pressure_diastolic": 60, "heart_rate": 100, "respiratory_rate": 20, "oxygen_saturation": 99, "weight": 45, "height": 140}', TRUE, DATE_ADD(CURDATE(), INTERVAL 180 DAY)),
(4, 4, 'Consultation', 'Knee pain', 'Right knee pain after jogging', 'Possible meniscus tear', 'MRI, physical therapy referral', '{"temperature": 98.8, "blood_pressure_systolic": 125, "blood_pressure_diastolic": 82, "heart_rate": 76, "respiratory_rate": 16, "oxygen_saturation": 98}', TRUE, DATE_ADD(CURDATE(), INTERVAL 21 DAY)),
(5, 5, 'Consultation', 'Headaches', 'Frequent headaches, sensitivity to light', 'Migraine headaches', 'Preventive medication, lifestyle modifications', '{"temperature": 98.5, "blood_pressure_systolic": 118, "blood_pressure_diastolic": 75, "heart_rate": 68, "respiratory_rate": 14, "oxygen_saturation": 99}', TRUE, DATE_ADD(CURDATE(), INTERVAL 30 DAY));

-- Insert sample treatments
INSERT INTO Treatments (patient_id, staff_id, treatment_name, treatment_date, duration_minutes, cost, room_id, status, notes) VALUES
(1, 1, 'Annual Physical Examination', CURDATE(), 45, 250.00, 5, 'Completed', 'Comprehensive physical exam completed'),
(2, 2, 'Electrocardiogram (ECG)', CURDATE(), 30, 150.00, 11, 'Completed', 'ECG shows normal sinus rhythm'),
(3, 3, 'Pediatric Vaccination', CURDATE(), 15, 75.00, 12, 'Completed', 'MMR vaccine administered'),
(4, 4, 'Knee X-Ray', CURDATE(), 20, 200.00, 7, 'Completed', 'X-ray shows no fractures'),
(5, 5, 'Neurological Assessment', CURDATE(), 60, 300.00, 9, 'Completed', 'Comprehensive neurological exam');

-- Insert sample prescriptions
INSERT INTO Prescriptions (patient_id, staff_id, medication_id, dosage, frequency, duration_days, quantity_prescribed, refills_allowed, indication, instructions) VALUES
(1, 1, 1, '81mg', 'Once daily', 90, 90, 3, 'Cardiovascular protection', 'Take with food'),
(2, 2, 5, '10mg', 'Once daily', 30, 30, 5, 'Hypertension', 'Take in the morning'),
(3, 3, 3, '160mg', 'As needed', 10, 20, 0, 'Fever/pain', 'Do not exceed 4 doses per day'),
(4, 4, 2, '400mg', 'Three times daily', 7, 21, 1, 'Inflammation', 'Take with food'),
(5, 5, 10, '10mg', 'Once daily', 14, 14, 0, 'Migraine prevention', 'Take with breakfast');

-- Dispense some medications
UPDATE Prescriptions SET quantity_dispensed = quantity_prescribed WHERE prescription_id IN (1, 2, 3);
UPDATE Prescriptions SET quantity_dispensed = 10 WHERE prescription_id = 4;
UPDATE Prescriptions SET quantity_dispensed = 7 WHERE prescription_id = 5;

-- Update medication stock after dispensing
UPDATE Medications SET stock_quantity = stock_quantity - 90 WHERE medication_id = 1;
UPDATE Medications SET stock_quantity = stock_quantity - 30 WHERE medication_id = 5;
UPDATE Medications SET stock_quantity = stock_quantity - 20 WHERE medication_id = 3;
UPDATE Medications SET stock_quantity = stock_quantity - 10 WHERE medication_id = 2;
UPDATE Medications SET stock_quantity = stock_quantity - 7 WHERE medication_id = 10;

-- Insert sample bills
INSERT INTO Billing (patient_id, total_amount, insurance_coverage, discount_amount, tax_amount, due_date, created_by) VALUES
(1, 325.00, 260.00, 0.00, 5.20, DATE_ADD(CURDATE(), INTERVAL 30 DAY), 10),
(2, 450.00, 360.00, 0.00, 7.20, DATE_ADD(CURDATE(), INTERVAL 30 DAY), 10),
(3, 155.00, 124.00, 0.00, 2.48, DATE_ADD(CURDATE(), INTERVAL 30 DAY), 10),
(4, 600.00, 480.00, 50.00, 5.60, DATE_ADD(CURDATE(), INTERVAL 30 DAY), 10),
(5, 390.00, 312.00, 0.00, 6.24, DATE_ADD(CURDATE(), INTERVAL 30 DAY), 10);

-- Insert sample bill items
INSERT INTO Bill_Items (bill_id, service_type, service_description, quantity, unit_price, total_price, service_date, service_provider_id, treatment_id) VALUES
(1, 'Treatment', 'Annual Physical Examination', 1, 250.00, 250.00, CURDATE(), 1, 1),
(1, 'Medication', 'Aspirin 81mg (90 tablets)', 90, 0.15, 13.50, CURDATE(), 1, NULL),
(2, 'Treatment', 'Electrocardiogram (ECG)', 1, 150.00, 150.00, CURDATE(), 2, 2),
(2, 'Medication', 'Lisinopril 10mg (30 tablets)', 30, 0.80, 24.00, CURDATE(), 2, NULL),
(3, 'Treatment', 'Pediatric Vaccination', 1, 75.00, 75.00, CURDATE(), 3, 3),
(3, 'Medication', 'Acetaminophen 500mg (20 tablets)', 20, 0.20, 4.00, CURDATE(), 3, NULL),
(4, 'Treatment', 'Knee X-Ray', 1, 200.00, 200.00, CURDATE(), 4, 4),
(4, 'Medication', 'Ibuprofen 200mg (10 tablets)', 10, 0.25, 2.50, CURDATE(), 4, NULL),
(5, 'Treatment', 'Neurological Assessment', 1, 300.00, 300.00, CURDATE(), 5, 5),
(5, 'Medication', 'Prednisone 10mg (7 tablets)', 7, 0.90, 6.30, CURDATE(), 5, NULL);

-- Insert sample payments
INSERT INTO Payments (bill_id, amount_paid, payment_method, transaction_reference, received_by) VALUES
(1, 70.20, 'Credit Card', 'CC123456789', 10),
(2, 97.20, 'Insurance', 'INS987654321', 10),
(3, 33.48, 'Cash', 'CASH001', 10),
(4, 75.60, 'Debit Card', 'DC456789123', 10),
(5, 84.24, 'Check', 'CHK789123456', 10);

-- Generate some alerts
CALL GenerateLowStockAlerts();
CALL GenerateExpiryAlerts(60);

-- Show sample data summary
SELECT 'Sample Data Insertion Complete!' AS Status;

SELECT 'Data Summary:' AS info;
SELECT 'Departments' AS table_name, COUNT(*) AS record_count FROM Departments
UNION ALL SELECT 'Medical Staff', COUNT(*) FROM Medical_Staff
UNION ALL SELECT 'Rooms', COUNT(*) FROM Rooms
UNION ALL SELECT 'Patients', COUNT(*) FROM Patients
UNION ALL SELECT 'Medications', COUNT(*) FROM Medications
UNION ALL SELECT 'Appointments', COUNT(*) FROM Appointments
UNION ALL SELECT 'Medical Records', COUNT(*) FROM Medical_Records
UNION ALL SELECT 'Treatments', COUNT(*) FROM Treatments
UNION ALL SELECT 'Prescriptions', COUNT(*) FROM Prescriptions
UNION ALL SELECT 'Bills', COUNT(*) FROM Billing
UNION ALL SELECT 'Bill Items', COUNT(*) FROM Bill_Items
UNION ALL SELECT 'Payments', COUNT(*) FROM Payments
UNION ALL SELECT 'Medication Alerts', COUNT(*) FROM Medication_Alerts;