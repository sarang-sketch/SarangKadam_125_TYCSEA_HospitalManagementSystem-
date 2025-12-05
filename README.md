# 🏥 Hospital Management System

<div align="center">

![Hospital Management System](https://img.shields.io/badge/Hospital-Management%20System-blue?style=for-the-badge&logo=data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNCAyNCI+PHBhdGggZmlsbD0id2hpdGUiIGQ9Ik0xOSAzSDVjLTEuMSAwLTIgLjktMiAydjE0YzAgMS4xLjkgMiAyIDJoMTRjMS4xIDAgMi0uOSAyLTJWNWMwLTEuMS0uOS0yLTItMnptLTIgMTBoLTR2NGgtMnYtNEg3di0yaDRWN2gydjRoNHYyeiIvPjwvc3ZnPg==)
![PHP](https://img.shields.io/badge/PHP-8.0+-777BB4?style=for-the-badge&logo=php&logoColor=white)
![MySQL](https://img.shields.io/badge/MySQL-5.7+-4479A1?style=for-the-badge&logo=mysql&logoColor=white)
![Bootstrap](https://img.shields.io/badge/Bootstrap-5.3-7952B3?style=for-the-badge&logo=bootstrap&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)

**A comprehensive web-based Hospital Management System built with PHP and MySQL**

[Features](#-features) • [Installation](#-installation) • [Database Design](#-database-design) • [ER Diagram](#-er-diagram) • [Documentation](#-documentation)

</div>

---

## 📋 Project Information

| Field | Details |
|:------|:--------|
| **Student Name** | Sarang Kadam |
| **Roll No** | 125 |
| **Class** | TY CSE (A) |
| **Project Title** | Hospital Management System |
| **Subject** | Database Management System |
| **GitHub** | [Repository Link](https://github.com/sarang-sketch/SarangKadam_125_TYCSEA_HospitalManagementSystem) |

---

## 🎯 Project Overview

The Hospital Management System (HMS) is a comprehensive web-based application designed to streamline hospital operations. Built using PHP and MySQL, it provides role-based access control for different hospital staff members and manages all aspects of hospital administration.

### Key Features

- 👥 **Patient Records Management** - Complete patient registration and history
- 📅 **Appointment Scheduling** - Book, reschedule, and manage appointments
- 🏥 **IPD/Admission Management** - Ward allocation and discharge management
- 💊 **Prescription & Pharmacy** - Digital prescriptions and inventory tracking
- 🔬 **Laboratory Tests** - Test requests and result management
- 💰 **Billing & Invoicing** - Itemized billing with tax calculation
- 🛏️ **Ward & Bed Management** - Real-time bed availability tracking

---

## ✨ Features

### 👤 Role-Based Access Control

| Role | Access & Permissions |
|:-----|:---------------------|
| **Admin** | Full system access, user & ward management |
| **Doctor** | Appointments, prescriptions, lab requests |
| **Nurse** | Patient care, admission notes |
| **Receptionist** | Patient registration, appointments, billing |
| **Lab Technician** | Test results, report uploads |
| **Pharmacist** | Prescription dispensing, inventory |

### 🔒 Security Features

- 🔐 Password hashing using bcrypt
- 🛡️ SQL injection prevention (prepared statements)
- 🔒 XSS protection (output escaping)
- 🔑 Session-based authentication
- 👮 Role-based access control

---

## 🛠️ Technology Stack

| Component | Technology |
|:----------|:-----------|
| **Backend** | PHP 8.0+ |
| **Database** | MySQL 5.7+ / MariaDB |
| **Frontend** | HTML5, CSS3, JavaScript |
| **UI Framework** | Bootstrap 5.3 |
| **Icons** | Font Awesome 6 |
| **Server** | Apache (XAMPP/WAMP/LAMP) |

---

## 📊 Database Design

### Database Tables (11 Tables)

| # | Table Name | Description | Primary Key |
|:-:|:-----------|:------------|:-----------:|
| 1 | `users` | System users with roles | id |
| 2 | `patients` | Patient records | id |
| 3 | `wards` | Hospital wards | id |
| 4 | `appointments` | Scheduled appointments | id |
| 5 | `admissions` | IPD admissions | id |
| 6 | `prescriptions` | Doctor prescriptions | id |
| 7 | `prescription_items` | Medicines in prescriptions | id |
| 8 | `lab_tests` | Lab test requests & results | id |
| 9 | `bills` | Patient bills | id |
| 10 | `bill_items` | Itemized charges | id |
| 11 | `medicines` | Pharmacy inventory | id |

---

## 📐 ER Diagram

### Complete Entity Relationship Diagram

```mermaid
erDiagram
    USERS ||--o{ APPOINTMENTS : "doctor_attends"
    USERS ||--o{ ADMISSIONS : "doctor_manages"
    USERS ||--o{ PRESCRIPTIONS : "doctor_writes"
    USERS ||--o{ LAB_TESTS : "doctor_requests"
    
    PATIENTS ||--o{ APPOINTMENTS : "schedules"
    PATIENTS ||--o{ ADMISSIONS : "admitted_as"
    PATIENTS ||--o{ PRESCRIPTIONS : "receives"
    PATIENTS ||--o{ LAB_TESTS : "undergoes"
    PATIENTS ||--o{ BILLS : "billed_to"
    
    WARDS ||--o{ ADMISSIONS : "contains"
    
    PRESCRIPTIONS ||--o{ PRESCRIPTION_ITEMS : "includes"
    
    BILLS ||--o{ BILL_ITEMS : "contains"
    ADMISSIONS ||--o| BILLS : "generates"

    USERS {
        int id PK
        varchar name
        varchar email UK
        varchar password_hash
        enum role
        varchar phone
        varchar department
        timestamp created_at
    }
    
    PATIENTS {
        int id PK
        varchar patient_code UK
        varchar name
        int age
        enum gender
        varchar blood_group
        varchar phone
        text address
        varchar emergency_contact
        text medical_history
        timestamp created_at
    }
    
    WARDS {
        int id PK
        varchar ward_name
        int total_beds
        timestamp created_at
    }
    
    APPOINTMENTS {
        int id PK
        int patient_id FK
        int doctor_id FK
        date appointment_date
        time appointment_time
        varchar department
        enum status
        timestamp created_at
    }
    
    ADMISSIONS {
        int id PK
        int patient_id FK
        int doctor_id FK
        int ward_id FK
        varchar bed_number
        datetime admission_date
        datetime discharge_date
        text diagnosis
        text notes
        enum status
    }
    
    PRESCRIPTIONS {
        int id PK
        int patient_id FK
        int doctor_id FK
        date visit_date
        text symptoms
        text diagnosis
        text advice
        enum status
        timestamp created_at
    }
    
    PRESCRIPTION_ITEMS {
        int id PK
        int prescription_id FK
        varchar medicine_name
        varchar dosage
        varchar frequency
        varchar duration
    }
    
    LAB_TESTS {
        int id PK
        int patient_id FK
        int doctor_id FK
        varchar test_name
        date requested_date
        date result_date
        text result
        varchar report_file
        enum status
    }
    
    BILLS {
        int id PK
        int patient_id FK
        int admission_id FK
        decimal total_amount
        decimal tax_amount
        enum status
        timestamp created_at
    }
    
    BILL_ITEMS {
        int id PK
        int bill_id FK
        varchar description
        decimal amount
    }
    
    MEDICINES {
        int id PK
        varchar name
        varchar batch_no
        int quantity
        date expiry_date
        decimal purchase_price
        decimal selling_price
        timestamp created_at
    }
```

---

## 🔗 Entity Relationships

| Parent Entity | Child Entity | Relationship | Description |
|:--------------|:-------------|:-------------|:------------|
| `USERS` | `APPOINTMENTS` | 1:N | One doctor has many appointments |
| `USERS` | `ADMISSIONS` | 1:N | One doctor manages many admissions |
| `USERS` | `PRESCRIPTIONS` | 1:N | One doctor writes many prescriptions |
| `USERS` | `LAB_TESTS` | 1:N | One doctor requests many lab tests |
| `PATIENTS` | `APPOINTMENTS` | 1:N | One patient has many appointments |
| `PATIENTS` | `ADMISSIONS` | 1:N | One patient can have many admissions |
| `PATIENTS` | `PRESCRIPTIONS` | 1:N | One patient receives many prescriptions |
| `PATIENTS` | `LAB_TESTS` | 1:N | One patient undergoes many lab tests |
| `PATIENTS` | `BILLS` | 1:N | One patient has many bills |
| `WARDS` | `ADMISSIONS` | 1:N | One ward contains many admissions |
| `PRESCRIPTIONS` | `PRESCRIPTION_ITEMS` | 1:N | One prescription has many items |
| `BILLS` | `BILL_ITEMS` | 1:N | One bill has many items |
| `ADMISSIONS` | `BILLS` | 1:1 | One admission generates one bill |

---

## 📐 Relational Schema Diagram

```mermaid
classDiagram
    direction TB
    
    class users {
        +id : INT [PK]
        +name : VARCHAR(100)
        +email : VARCHAR(100) [UK]
        +password_hash : VARCHAR(255)
        +role : ENUM
        +phone : VARCHAR(20)
        +department : VARCHAR(50)
        +created_at : TIMESTAMP
    }

    class patients {
        +id : INT [PK]
        +patient_code : VARCHAR(20) [UK]
        +name : VARCHAR(100)
        +age : INT
        +gender : ENUM
        +blood_group : VARCHAR(5)
        +phone : VARCHAR(20)
        +address : TEXT
        +emergency_contact : VARCHAR(100)
        +medical_history : TEXT
        +created_at : TIMESTAMP
    }

    class wards {
        +id : INT [PK]
        +ward_name : VARCHAR(50)
        +total_beds : INT
        +created_at : TIMESTAMP
    }

    class appointments {
        +id : INT [PK]
        +patient_id : INT [FK]
        +doctor_id : INT [FK]
        +appointment_date : DATE
        +appointment_time : TIME
        +department : VARCHAR(50)
        +status : ENUM
        +created_at : TIMESTAMP
    }

    class admissions {
        +id : INT [PK]
        +patient_id : INT [FK]
        +doctor_id : INT [FK]
        +ward_id : INT [FK]
        +bed_number : VARCHAR(10)
        +admission_date : DATETIME
        +discharge_date : DATETIME
        +diagnosis : TEXT
        +notes : TEXT
        +status : ENUM
    }

    class prescriptions {
        +id : INT [PK]
        +patient_id : INT [FK]
        +doctor_id : INT [FK]
        +visit_date : DATE
        +symptoms : TEXT
        +diagnosis : TEXT
        +advice : TEXT
        +status : ENUM
        +created_at : TIMESTAMP
    }

    class prescription_items {
        +id : INT [PK]
        +prescription_id : INT [FK]
        +medicine_name : VARCHAR(100)
        +dosage : VARCHAR(50)
        +frequency : VARCHAR(50)
        +duration : VARCHAR(50)
    }

    class lab_tests {
        +id : INT [PK]
        +patient_id : INT [FK]
        +doctor_id : INT [FK]
        +test_name : VARCHAR(100)
        +requested_date : DATE
        +result_date : DATE
        +result : TEXT
        +report_file : VARCHAR(255)
        +status : ENUM
    }

    class bills {
        +id : INT [PK]
        +patient_id : INT [FK]
        +admission_id : INT [FK]
        +total_amount : DECIMAL
        +tax_amount : DECIMAL
        +status : ENUM
        +created_at : TIMESTAMP
    }

    class bill_items {
        +id : INT [PK]
        +bill_id : INT [FK]
        +description : VARCHAR(255)
        +amount : DECIMAL
    }

    class medicines {
        +id : INT [PK]
        +name : VARCHAR(100)
        +batch_no : VARCHAR(50)
        +quantity : INT
        +expiry_date : DATE
        +purchase_price : DECIMAL
        +selling_price : DECIMAL
        +created_at : TIMESTAMP
    }

    users "1" --> "*" appointments : doctor_id
    users "1" --> "*" admissions : doctor_id
    users "1" --> "*" prescriptions : doctor_id
    users "1" --> "*" lab_tests : doctor_id
    patients "1" --> "*" appointments : patient_id
    patients "1" --> "*" admissions : patient_id
    patients "1" --> "*" prescriptions : patient_id
    patients "1" --> "*" lab_tests : patient_id
    patients "1" --> "*" bills : patient_id
    wards "1" --> "*" admissions : ward_id
    prescriptions "1" --> "*" prescription_items : prescription_id
    bills "1" --> "*" bill_items : bill_id
    admissions "1" --> "0..1" bills : admission_id
```

---

## 🔄 Data Flow Diagram

### Level 0 - Context Diagram

```mermaid
flowchart TB
    subgraph External["External Entities"]
        P[("👤 Patient")]
        D[("👨‍⚕️ Doctor")]
        N[("👩‍⚕️ Nurse")]
        R[("💁 Receptionist")]
        L[("🔬 Lab Tech")]
        PH[("💊 Pharmacist")]
        A[("👨‍💼 Admin")]
    end
    
    subgraph HMS["🏥 Hospital Management System"]
        PM["Patient\nManagement"]
        AM["Appointment\nManagement"]
        ADM["Admission\nManagement"]
        PRE["Prescription\nManagement"]
        LAB["Lab Test\nManagement"]
        BIL["Billing\nManagement"]
        INV["Inventory\nManagement"]
        USR["User\nManagement"]
    end
    
    P -->|"Registration"| PM
    P -->|"Book Appointment"| AM
    R -->|"Register Patient"| PM
    R -->|"Schedule"| AM
    R -->|"Generate Bill"| BIL
    D -->|"View Appointments"| AM
    D -->|"Write Prescription"| PRE
    D -->|"Request Tests"| LAB
    D -->|"Admit Patient"| ADM
    N -->|"Update Notes"| ADM
    L -->|"Enter Results"| LAB
    PH -->|"Dispense Medicine"| PRE
    PH -->|"Update Stock"| INV
    A -->|"Manage Users"| USR
    A -->|"Manage Wards"| ADM
```

---

## 📏 Normalization

### Normalization Status

| Normal Form | Status | Description |
|:------------|:------:|:------------|
| **1NF** | ✅ | All tables have primary keys, atomic values, no repeating groups |
| **2NF** | ✅ | All non-key attributes fully depend on primary key |
| **3NF** | ✅ | No transitive dependencies exist |
| **BCNF** | ✅ | Every determinant is a candidate key |

### Functional Dependencies

| Table | Functional Dependencies |
|:------|:------------------------|
| `users` | id → name, email, password_hash, role, phone, department |
| `patients` | id → patient_code, name, age, gender, blood_group, phone, address |
| `appointments` | id → patient_id, doctor_id, appointment_date, appointment_time, status |
| `admissions` | id → patient_id, doctor_id, ward_id, bed_number, dates, diagnosis |
| `prescriptions` | id → patient_id, doctor_id, visit_date, symptoms, diagnosis |
| `prescription_items` | id → prescription_id, medicine_name, dosage, frequency, duration |
| `lab_tests` | id → patient_id, doctor_id, test_name, dates, result, status |
| `bills` | id → patient_id, admission_id, total_amount, tax_amount, status |
| `bill_items` | id → bill_id, description, amount |
| `wards` | id → ward_name, total_beds |
| `medicines` | id → name, batch_no, quantity, expiry_date, prices |

---


## 📁 Project Structure

```
SarangKadam_125_TYCSEA_HospitalManagementSystem/
│
├── 📁 hospital_management/          # PHP Web Application
│   ├── 📁 admin/                    # Admin module
│   │   ├── index.php               # Admin dashboard
│   │   ├── users.php               # User management
│   │   ├── user_form.php           # Add/Edit user
│   │   └── wards.php               # Ward management
│   ├── 📁 auth/                     # Authentication
│   │   ├── login.php               # Login page
│   │   └── logout.php              # Logout handler
│   ├── 📁 billing/                  # Billing module
│   │   ├── bills.php               # Bills list
│   │   ├── bill_form.php           # Create bill
│   │   └── invoice.php             # Print invoice
│   ├── 📁 config/                   # Configuration
│   │   └── database.php            # DB connection
│   ├── 📁 doctor/                   # Doctor module
│   │   ├── index.php               # Doctor dashboard
│   │   ├── appointments.php        # View appointments
│   │   ├── prescriptions.php       # Prescriptions list
│   │   ├── prescription_form.php   # Create prescription
│   │   └── lab_requests.php        # Request lab tests
│   ├── 📁 includes/                 # Shared components
│   │   ├── header.php              # Page header
│   │   ├── footer.php              # Page footer
│   │   ├── sidebar.php             # Navigation sidebar
│   │   ├── auth_check.php          # Auth middleware
│   │   └── functions.php           # Helper functions
│   ├── 📁 lab/                      # Lab module
│   │   ├── index.php               # Lab dashboard
│   │   ├── tests.php               # Test requests
│   │   └── test_result.php         # Enter results
│   ├── 📁 nurse/                    # Nurse module
│   │   ├── index.php               # Nurse dashboard
│   │   └── patient_care.php        # Patient care notes
│   ├── 📁 pharmacist/               # Pharmacy module
│   │   ├── index.php               # Pharmacy dashboard
│   │   ├── prescriptions.php       # Pending prescriptions
│   │   ├── inventory.php           # Medicine inventory
│   │   └── medicine_form.php       # Add/Edit medicine
│   ├── 📁 receptionist/             # Reception module
│   │   ├── index.php               # Reception dashboard
│   │   ├── patients.php            # Patient list
│   │   ├── patient_form.php        # Register patient
│   │   ├── appointments.php        # Appointments list
│   │   ├── appointment_form.php    # Book appointment
│   │   ├── admissions.php          # Admissions list
│   │   └── admission_form.php      # Admit patient
│   ├── 📁 assets/                   # Static assets
│   │   ├── css/style.css           # Custom styles
│   │   └── js/main.js              # Custom scripts
│   ├── 📁 uploads/                  # File uploads
│   │   └── lab_reports/            # Lab report PDFs
│   ├── db.sql                       # Database schema
│   └── index.php                    # Entry point
│
├── 📁 docs/                         # Documentation
│   ├── DATABASE_DIAGRAMS.md        # Detailed ER diagrams
│   └── README_PROFESSIONAL.md      # Extended documentation
│
├── 📄 SQL Scripts (01-26)           # Modular SQL files
│   ├── 01_database_init.sql        # Database initialization
│   ├── 02_patients_table.sql       # Patients table
│   ├── 03_departments_staff.sql    # Departments & Staff
│   ├── ...                         # More SQL scripts
│   └── 26_comprehensive_test.sql   # System tests
│
├── db.sql                           # Combined database schema
├── README.md                        # This file
├── LICENSE                          # MIT License
├── CONTRIBUTING.md                  # Contribution guidelines
├── SECURITY.md                      # Security policy
└── CHANGELOG.md                     # Version history
```

---

## 🚀 Installation

### Prerequisites

- ✅ XAMPP/WAMP/LAMP with PHP 8.0+
- ✅ MySQL 5.7+ or MariaDB
- ✅ Web browser (Chrome, Firefox, Edge)

### Step-by-Step Setup

#### 1️⃣ Clone the Repository
```bash
git clone https://github.com/sarang-sketch/SarangKadam_125_TYCSEA_HospitalManagementSystem.git
```

#### 2️⃣ Copy to Web Server
```bash
# For XAMPP (Windows)
xcopy hospital_management C:\xampp\htdocs\hospital_management\ /E /I

# For Linux
cp -r hospital_management /var/www/html/
```

#### 3️⃣ Create Database
1. Open phpMyAdmin: `http://localhost/phpmyadmin`
2. Create new database: `hospital_management`
3. Import `hospital_management/db.sql` file

#### 4️⃣ Configure Database Connection
Edit `hospital_management/config/database.php`:
```php
define('DB_HOST', 'localhost');
define('DB_USER', 'root');
define('DB_PASS', '');
define('DB_NAME', 'hospital_management');
```

#### 5️⃣ Access the Application
```
http://localhost/hospital_management
```

---

## 🔐 Default Login Credentials

| Role | Email | Password |
|:-----|:------|:---------|
| **Admin** | admin@hospital.com | Admin@123 |
| **Doctor** | doctor1@hospital.com | Admin@123 |
| **Doctor** | doctor2@hospital.com | Admin@123 |
| **Nurse** | nurse@hospital.com | Admin@123 |
| **Receptionist** | reception@hospital.com | Admin@123 |
| **Lab Tech** | lab@hospital.com | Admin@123 |
| **Pharmacist** | pharmacy@hospital.com | Admin@123 |

---

## 📝 SQL Query Examples

### Patient Registration
```sql
INSERT INTO patients (patient_code, name, age, gender, blood_group, phone, address)
VALUES ('PT202500001', 'John Doe', 35, 'male', 'A+', '9876543210', '123 Main St');
```

### Book Appointment
```sql
INSERT INTO appointments (patient_id, doctor_id, appointment_date, appointment_time, department)
VALUES (1, 2, '2025-12-10', '10:00:00', 'Cardiology');
```

### View Today's Appointments
```sql
SELECT a.*, p.name as patient_name, u.name as doctor_name
FROM appointments a
JOIN patients p ON a.patient_id = p.id
JOIN users u ON a.doctor_id = u.id
WHERE a.appointment_date = CURDATE()
ORDER BY a.appointment_time;
```

### Generate Bill
```sql
INSERT INTO bills (patient_id, admission_id, total_amount, tax_amount, status)
VALUES (1, 1, 5000.00, 250.00, 'unpaid');
```

### Check Medicine Stock
```sql
SELECT name, quantity, expiry_date 
FROM medicines 
WHERE quantity < 50 OR expiry_date < DATE_ADD(CURDATE(), INTERVAL 30 DAY)
ORDER BY quantity ASC;
```

---

## 📚 Documentation

| Document | Description |
|:---------|:------------|
| [docs/DATABASE_DIAGRAMS.md](docs/DATABASE_DIAGRAMS.md) | Detailed ER diagrams and schema |
| [docs/README_PROFESSIONAL.md](docs/README_PROFESSIONAL.md) | Extended documentation |
| [CONTRIBUTING.md](CONTRIBUTING.md) | How to contribute |
| [SECURITY.md](SECURITY.md) | Security policy |
| [CHANGELOG.md](CHANGELOG.md) | Version history |

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👨‍💻 Author

<div align="center">

**Sarang Kadam**

| Field | Details |
|:------|:--------|
| Roll No | 125 |
| Class | TY CSE (A) |
| Subject | Database Management System |
| GitHub | [@sarang-sketch](https://github.com/sarang-sketch) |

</div>

---

<div align="center">

**⭐ Star this repository if you found it helpful!**

[![GitHub stars](https://img.shields.io/github/stars/sarang-sketch/SarangKadam_125_TYCSEA_HospitalManagementSystem?style=social)](https://github.com/sarang-sketch/SarangKadam_125_TYCSEA_HospitalManagementSystem/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/sarang-sketch/SarangKadam_125_TYCSEA_HospitalManagementSystem?style=social)](https://github.com/sarang-sketch/SarangKadam_125_TYCSEA_HospitalManagementSystem/network/members)

Made with ❤️ for DBMS Project

</div>
