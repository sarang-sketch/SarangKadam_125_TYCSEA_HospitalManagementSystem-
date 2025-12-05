-- Hospital Management System Database Schema
-- MySQL Database with InnoDB Engine

-- Create database
CREATE DATABASE IF NOT EXISTS hospital_management;
USE hospital_management;

-- Drop tables if exist (for clean install)
DROP TABLE IF EXISTS bill_items;
DROP TABLE IF EXISTS bills;
DROP TABLE IF EXISTS prescription_items;
DROP TABLE IF EXISTS prescriptions;
DROP TABLE IF EXISTS lab_tests;
DROP TABLE IF EXISTS admissions;
DROP TABLE IF EXISTS appointments;
DROP TABLE IF EXISTS medicines;
DROP TABLE IF EXISTS wards;
DROP TABLE IF EXISTS patients;
DROP TABLE IF EXISTS users;

-- Users table
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role ENUM('admin', 'doctor', 'nurse', 'receptionist', 'lab', 'pharmacist', 'patient') NOT NULL,
    phone VARCHAR(20),
    department VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_role (role),
    INDEX idx_email (email)
) ENGINE=InnoDB;

-- Patients table
CREATE TABLE patients (
    id INT AUTO_INCREMENT PRIMARY KEY,
    patient_code VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    age INT NOT NULL,
    gender ENUM('male', 'female', 'other') NOT NULL,
    blood_group VARCHAR(5),
    phone VARCHAR(20) NOT NULL,
    address TEXT,
    emergency_contact VARCHAR(100),
    medical_history TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_patient_code (patient_code),
    INDEX idx_phone (phone),
    INDEX idx_name (name)
) ENGINE=InnoDB;


-- Wards table
CREATE TABLE wards (
    id INT AUTO_INCREMENT PRIMARY KEY,
    ward_name VARCHAR(50) NOT NULL,
    total_beds INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Appointments table
CREATE TABLE appointments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT NOT NULL,
    doctor_id INT NOT NULL,
    appointment_date DATE NOT NULL,
    appointment_time TIME NOT NULL,
    department VARCHAR(50),
    status ENUM('pending', 'completed', 'cancelled') DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (patient_id) REFERENCES patients(id) ON DELETE CASCADE,
    FOREIGN KEY (doctor_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_date (appointment_date),
    INDEX idx_doctor_date (doctor_id, appointment_date)
) ENGINE=InnoDB;

-- Admissions table
CREATE TABLE admissions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT NOT NULL,
    doctor_id INT NOT NULL,
    ward_id INT NOT NULL,
    bed_number VARCHAR(10) NOT NULL,
    admission_date DATETIME NOT NULL,
    discharge_date DATETIME,
    diagnosis TEXT,
    notes TEXT,
    status ENUM('admitted', 'discharged') DEFAULT 'admitted',
    FOREIGN KEY (patient_id) REFERENCES patients(id) ON DELETE CASCADE,
    FOREIGN KEY (doctor_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (ward_id) REFERENCES wards(id) ON DELETE CASCADE,
    INDEX idx_status (status),
    INDEX idx_patient (patient_id)
) ENGINE=InnoDB;

-- Prescriptions table
CREATE TABLE prescriptions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT NOT NULL,
    doctor_id INT NOT NULL,
    visit_date DATE NOT NULL,
    symptoms TEXT,
    diagnosis TEXT,
    advice TEXT,
    status ENUM('pending', 'dispensed') DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (patient_id) REFERENCES patients(id) ON DELETE CASCADE,
    FOREIGN KEY (doctor_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_status (status),
    INDEX idx_patient (patient_id)
) ENGINE=InnoDB;

-- Prescription items table
CREATE TABLE prescription_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    prescription_id INT NOT NULL,
    medicine_name VARCHAR(100) NOT NULL,
    dosage VARCHAR(50),
    frequency VARCHAR(50),
    duration VARCHAR(50),
    FOREIGN KEY (prescription_id) REFERENCES prescriptions(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Lab tests table
CREATE TABLE lab_tests (
    id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT NOT NULL,
    doctor_id INT NOT NULL,
    test_name VARCHAR(100) NOT NULL,
    requested_date DATE NOT NULL,
    result_date DATE,
    result TEXT,
    report_file VARCHAR(255),
    status ENUM('requested', 'in-progress', 'completed') DEFAULT 'requested',
    FOREIGN KEY (patient_id) REFERENCES patients(id) ON DELETE CASCADE,
    FOREIGN KEY (doctor_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_status (status)
) ENGINE=InnoDB;

-- Bills table
CREATE TABLE bills (
    id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT NOT NULL,
    admission_id INT,
    total_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
    tax_amount DECIMAL(10,2) DEFAULT 0,
    status ENUM('paid', 'unpaid') DEFAULT 'unpaid',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (patient_id) REFERENCES patients(id) ON DELETE CASCADE,
    FOREIGN KEY (admission_id) REFERENCES admissions(id) ON DELETE SET NULL,
    INDEX idx_status (status),
    INDEX idx_patient (patient_id)
) ENGINE=InnoDB;

-- Bill items table
CREATE TABLE bill_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    bill_id INT NOT NULL,
    description VARCHAR(255) NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (bill_id) REFERENCES bills(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Medicines table
CREATE TABLE medicines (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    batch_no VARCHAR(50),
    quantity INT NOT NULL DEFAULT 0,
    expiry_date DATE,
    purchase_price DECIMAL(10,2),
    selling_price DECIMAL(10,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_name (name),
    INDEX idx_expiry (expiry_date)
) ENGINE=InnoDB;


-- =============================================
-- SAMPLE DATA
-- =============================================

-- Insert Users (password is 'Admin@123' for all users - hashed with bcrypt)
-- Password hash for 'Admin@123': $2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi
INSERT INTO users (name, email, password_hash, role, phone, department) VALUES
('System Admin', 'admin@hospital.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'admin', '1234567890', 'Administration'),
('Dr. John Smith', 'doctor1@hospital.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'doctor', '1234567891', 'Cardiology'),
('Dr. Sarah Johnson', 'doctor2@hospital.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'doctor', '1234567892', 'General Medicine'),
('Nurse Mary Wilson', 'nurse@hospital.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'nurse', '1234567893', 'General Ward'),
('Reception Staff', 'reception@hospital.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'receptionist', '1234567894', 'Front Desk'),
('Lab Tech Mike', 'lab@hospital.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'lab', '1234567895', 'Laboratory'),
('Pharmacist Jane', 'pharmacy@hospital.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'pharmacist', '1234567896', 'Pharmacy');

-- Insert Wards
INSERT INTO wards (ward_name, total_beds) VALUES
('General Ward', 20),
('ICU', 10),
('Pediatric Ward', 15),
('Maternity Ward', 12),
('Emergency Ward', 8);

-- Insert Sample Patients
INSERT INTO patients (patient_code, name, age, gender, blood_group, phone, address, emergency_contact, medical_history) VALUES
('PT202500001', 'Robert Brown', 45, 'male', 'A+', '9876543210', '123 Main St, City', 'Wife: 9876543211', 'Hypertension, Diabetes Type 2'),
('PT202500002', 'Emily Davis', 32, 'female', 'B+', '9876543212', '456 Oak Ave, Town', 'Husband: 9876543213', 'No significant history'),
('PT202500003', 'Michael Wilson', 58, 'male', 'O+', '9876543214', '789 Pine Rd, Village', 'Son: 9876543215', 'Heart disease, Previous bypass surgery'),
('PT202500004', 'Jennifer Taylor', 28, 'female', 'AB-', '9876543216', '321 Elm St, City', 'Mother: 9876543217', 'Asthma'),
('PT202500005', 'David Anderson', 65, 'male', 'A-', '9876543218', '654 Maple Dr, Town', 'Daughter: 9876543219', 'Arthritis, High cholesterol'),
('PT202500006', 'Lisa Martinez', 41, 'female', 'B-', '9876543220', '987 Cedar Ln, City', 'Sister: 9876543221', 'Migraine'),
('PT202500007', 'James Thomas', 52, 'male', 'O-', '9876543222', '147 Birch Way, Village', 'Wife: 9876543223', 'Diabetes Type 1'),
('PT202500008', 'Patricia Garcia', 36, 'female', 'A+', '9876543224', '258 Spruce Ct, Town', 'Husband: 9876543225', 'Thyroid disorder'),
('PT202500009', 'Christopher Lee', 48, 'male', 'B+', '9876543226', '369 Willow Pl, City', 'Brother: 9876543227', 'Back pain, Sciatica'),
('PT202500010', 'Amanda White', 29, 'female', 'AB+', '9876543228', '741 Ash Blvd, Town', 'Father: 9876543229', 'Allergies');

-- Insert Sample Appointments (for today and upcoming days)
INSERT INTO appointments (patient_id, doctor_id, appointment_date, appointment_time, department, status) VALUES
(1, 2, CURDATE(), '09:00:00', 'Cardiology', 'pending'),
(2, 3, CURDATE(), '09:30:00', 'General Medicine', 'pending'),
(3, 2, CURDATE(), '10:00:00', 'Cardiology', 'pending'),
(4, 3, CURDATE(), '10:30:00', 'General Medicine', 'completed'),
(5, 2, CURDATE(), '11:00:00', 'Cardiology', 'pending'),
(6, 3, DATE_ADD(CURDATE(), INTERVAL 1 DAY), '09:00:00', 'General Medicine', 'pending'),
(7, 2, DATE_ADD(CURDATE(), INTERVAL 1 DAY), '09:30:00', 'Cardiology', 'pending'),
(8, 3, DATE_ADD(CURDATE(), INTERVAL 2 DAY), '10:00:00', 'General Medicine', 'pending');

-- Insert Sample Admissions
INSERT INTO admissions (patient_id, doctor_id, ward_id, bed_number, admission_date, diagnosis, notes, status) VALUES
(3, 2, 2, 'ICU-01', DATE_SUB(NOW(), INTERVAL 2 DAY), 'Chest pain, suspected cardiac event', 'Patient stable, monitoring vitals', 'admitted'),
(5, 3, 1, 'GW-05', DATE_SUB(NOW(), INTERVAL 1 DAY), 'Severe joint pain', 'Started on pain management', 'admitted'),
(7, 2, 1, 'GW-08', DATE_SUB(NOW(), INTERVAL 3 DAY), 'Diabetic ketoacidosis', 'Blood sugar stabilizing', 'admitted');

-- Insert Sample Prescriptions
INSERT INTO prescriptions (patient_id, doctor_id, visit_date, symptoms, diagnosis, advice, status) VALUES
(1, 2, CURDATE(), 'Chest discomfort, shortness of breath', 'Mild angina', 'Rest, avoid strenuous activity, follow up in 1 week', 'pending'),
(2, 3, DATE_SUB(CURDATE(), INTERVAL 1 DAY), 'Fever, body ache, cough', 'Viral infection', 'Rest, plenty of fluids, paracetamol for fever', 'dispensed'),
(4, 3, DATE_SUB(CURDATE(), INTERVAL 2 DAY), 'Wheezing, difficulty breathing', 'Asthma exacerbation', 'Use inhaler as prescribed, avoid triggers', 'dispensed');

-- Insert Prescription Items
INSERT INTO prescription_items (prescription_id, medicine_name, dosage, frequency, duration) VALUES
(1, 'Aspirin', '75mg', 'Once daily', '30 days'),
(1, 'Atorvastatin', '10mg', 'Once daily at night', '30 days'),
(1, 'Metoprolol', '25mg', 'Twice daily', '30 days'),
(2, 'Paracetamol', '500mg', 'Three times daily', '5 days'),
(2, 'Cetirizine', '10mg', 'Once daily', '5 days'),
(3, 'Salbutamol Inhaler', '100mcg', 'As needed', '30 days'),
(3, 'Montelukast', '10mg', 'Once daily at night', '30 days');

-- Insert Sample Lab Tests
INSERT INTO lab_tests (patient_id, doctor_id, test_name, requested_date, result_date, result, status) VALUES
(1, 2, 'Complete Blood Count', DATE_SUB(CURDATE(), INTERVAL 1 DAY), CURDATE(), 'WBC: 7500, RBC: 4.8M, Hemoglobin: 14.2, Platelets: 250000', 'completed'),
(1, 2, 'Lipid Profile', DATE_SUB(CURDATE(), INTERVAL 1 DAY), NULL, NULL, 'requested'),
(3, 2, 'Cardiac Enzymes', DATE_SUB(CURDATE(), INTERVAL 2 DAY), DATE_SUB(CURDATE(), INTERVAL 1 DAY), 'Troponin: 0.02, CK-MB: 3.5 - Within normal limits', 'completed'),
(3, 2, 'ECG', DATE_SUB(CURDATE(), INTERVAL 2 DAY), NULL, NULL, 'in-progress'),
(7, 2, 'Blood Glucose Fasting', CURDATE(), NULL, NULL, 'requested'),
(7, 2, 'HbA1c', CURDATE(), NULL, NULL, 'requested');

-- Insert Sample Bills
INSERT INTO bills (patient_id, admission_id, total_amount, tax_amount, status) VALUES
(2, NULL, 550.00, 27.50, 'paid'),
(4, NULL, 350.00, 17.50, 'paid'),
(3, 1, 15000.00, 750.00, 'unpaid'),
(5, 2, 5500.00, 275.00, 'unpaid');

-- Insert Bill Items
INSERT INTO bill_items (bill_id, description, amount) VALUES
(1, 'Consultation Fee - General Medicine', 300.00),
(1, 'Medicines', 250.00),
(2, 'Consultation Fee - General Medicine', 300.00),
(2, 'Nebulization', 50.00),
(3, 'ICU Charges (2 days)', 10000.00),
(3, 'Consultation Fee - Cardiology', 500.00),
(3, 'Cardiac Enzymes Test', 1500.00),
(3, 'ECG', 500.00),
(3, 'Medicines', 2500.00),
(4, 'General Ward (1 day)', 2000.00),
(4, 'Consultation Fee', 500.00),
(4, 'Medicines', 3000.00);

-- Insert Sample Medicines
INSERT INTO medicines (name, batch_no, quantity, expiry_date, purchase_price, selling_price) VALUES
('Paracetamol 500mg', 'PCM2024001', 500, '2026-12-31', 1.50, 3.00),
('Aspirin 75mg', 'ASP2024001', 300, '2026-06-30', 2.00, 4.00),
('Atorvastatin 10mg', 'ATV2024001', 200, '2026-09-30', 5.00, 10.00),
('Metoprolol 25mg', 'MTP2024001', 150, '2026-08-31', 3.00, 6.00),
('Cetirizine 10mg', 'CTZ2024001', 400, '2026-11-30', 1.00, 2.50),
('Amoxicillin 500mg', 'AMX2024001', 250, '2025-12-31', 4.00, 8.00),
('Omeprazole 20mg', 'OMP2024001', 350, '2026-10-31', 2.50, 5.00),
('Metformin 500mg', 'MTF2024001', 400, '2026-07-31', 1.50, 3.50),
('Salbutamol Inhaler', 'SLB2024001', 50, '2026-05-31', 80.00, 150.00),
('Montelukast 10mg', 'MNT2024001', 180, '2026-04-30', 6.00, 12.00),
('Ibuprofen 400mg', 'IBU2024001', 300, '2026-03-31', 2.00, 4.50),
('Diclofenac 50mg', 'DCF2024001', 200, '2026-02-28', 2.50, 5.00);
