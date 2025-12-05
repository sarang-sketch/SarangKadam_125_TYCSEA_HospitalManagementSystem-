# 🏥 Hospital Management System - Database Diagrams

## 📋 Project Information

| Field | Details |
|-------|---------|
| **Student Name** | Sarang Kadam |
| **Roll No** | 125 |
| **Class** | TY CSE (A) |
| **Project Title** | Hospital Management System |
| **Subject** | Database Management System |

---

## 📊 Entity Relationship Diagram (ERD)

### Complete ER Diagram

```mermaid
erDiagram
    PATIENTS ||--o{ APPOINTMENTS : "schedules"
    PATIENTS ||--o{ MEDICAL_RECORDS : "has"
    PATIENTS ||--o{ PRESCRIPTIONS : "receives"
    PATIENTS ||--o{ BILLING : "billed_to"
    
    MEDICAL_STAFF ||--o{ APPOINTMENTS : "attends"
    MEDICAL_STAFF ||--o{ MEDICAL_RECORDS : "creates"
    MEDICAL_STAFF ||--o{ PRESCRIPTIONS : "prescribes"
    MEDICAL_STAFF ||--o{ TREATMENTS : "performs"
    MEDICAL_STAFF }o--|| DEPARTMENTS : "belongs_to"
    
    DEPARTMENTS ||--o{ ROOMS : "contains"
    DEPARTMENTS ||--|| MEDICAL_STAFF : "headed_by"
    
    ROOMS ||--o{ APPOINTMENTS : "used_for"
    
    PRESCRIPTIONS }o--|| MEDICATIONS : "includes"
    PRESCRIPTIONS ||--o{ BILL_ITEMS : "charged_in"
    
    MEDICATIONS ||--o{ MEDICATION_STOCK_LOG : "tracks"
    MEDICATIONS ||--o{ MEDICATION_ALERTS : "generates"
    
    BILLING ||--o{ BILL_ITEMS : "contains"
    BILLING ||--o{ PAYMENTS : "paid_via"
    
    TREATMENTS ||--o{ BILL_ITEMS : "charged_in"
    MEDICAL_RECORDS ||--o{ TREATMENTS : "includes"

    PATIENTS {
        int patient_id PK
        varchar first_name
        varchar last_name
        date date_of_birth
        enum gender
        varchar phone
        varchar email
        text address
        varchar emergency_contact_name
        varchar emergency_contact_phone
        varchar insurance_provider
        varchar insurance_policy_number
        timestamp registration_date
        enum status
    }

    MEDICAL_STAFF {
        int staff_id PK
        varchar first_name
        varchar last_name
        enum role
        varchar specialization
        int department_id FK
        varchar phone
        varchar email
        date hire_date
        varchar license_number
        date license_expiry_date
        decimal salary
        enum status
    }

    DEPARTMENTS {
        int department_id PK
        varchar department_name
        int department_head_id FK
        varchar location
        varchar phone
        text description
        timestamp created_date
    }

    ROOMS {
        int room_id PK
        varchar room_number
        enum room_type
        int department_id FK
        int capacity
        int current_occupancy
        decimal daily_rate
        enum status
        text equipment_list
        date last_maintenance_date
    }

    APPOINTMENTS {
        int appointment_id PK
        int patient_id FK
        int staff_id FK
        date appointment_date
        time appointment_time
        int duration_minutes
        varchar purpose
        enum status
        text notes
        int room_id FK
        int created_by FK
    }

    MEDICAL_RECORDS {
        int record_id PK
        int patient_id FK
        int staff_id FK
        timestamp visit_date
        text diagnosis
        text symptoms
        text treatment_plan
        json vital_signs
        boolean follow_up_required
        date follow_up_date
        enum record_type
        varchar chief_complaint
    }

    TREATMENTS {
        int treatment_id PK
        int record_id FK
        int staff_id FK
        int room_id FK
        varchar treatment_name
        text description
        timestamp treatment_date
        int duration_minutes
        decimal cost
        enum status
        text outcome
    }

    MEDICATIONS {
        int medication_id PK
        varchar medication_name
        varchar generic_name
        varchar brand_name
        varchar manufacturer
        enum dosage_form
        varchar strength
        decimal unit_price
        int stock_quantity
        int minimum_stock_level
        date expiry_date
        varchar batch_number
        varchar supplier
        boolean prescription_required
        boolean controlled_substance
    }

    PRESCRIPTIONS {
        int prescription_id PK
        int patient_id FK
        int staff_id FK
        int medication_id FK
        varchar dosage
        varchar frequency
        int duration_days
        int quantity_prescribed
        int quantity_dispensed
        enum status
        text instructions
        int refills_allowed
        enum route_of_administration
    }

    BILLING {
        int bill_id PK
        int patient_id FK
        timestamp bill_date
        decimal total_amount
        decimal insurance_coverage
        decimal patient_responsibility
        decimal discount_amount
        decimal tax_amount
        decimal final_amount
        enum payment_status
        date due_date
        varchar insurance_claim_number
    }

    BILL_ITEMS {
        int item_id PK
        int bill_id FK
        enum service_type
        varchar service_code
        varchar service_description
        int quantity
        decimal unit_price
        decimal total_price
        date service_date
        int service_provider_id FK
    }

    PAYMENTS {
        int payment_id PK
        int bill_id FK
        timestamp payment_date
        decimal amount_paid
        enum payment_method
        varchar transaction_reference
        enum payment_status
        decimal refund_amount
        int received_by FK
    }

    MEDICATION_ALERTS {
        int alert_id PK
        int medication_id FK
        enum alert_type
        text alert_message
        timestamp alert_date
        boolean acknowledged
    }

    MEDICATION_STOCK_LOG {
        int log_id PK
        int medication_id FK
        int quantity_change
        int previous_stock
        int new_stock
        varchar reason
        timestamp change_date
    }
```

---

## 🔗 Relationship Cardinality Summary

| Parent Entity | Child Entity | Relationship | Cardinality |
|---------------|--------------|--------------|-------------|
| PATIENTS | APPOINTMENTS | Patient schedules appointments | 1:N |
| PATIENTS | MEDICAL_RECORDS | Patient has medical records | 1:N |
| PATIENTS | PRESCRIPTIONS | Patient receives prescriptions | 1:N |
| PATIENTS | BILLING | Patient receives bills | 1:N |
| MEDICAL_STAFF | APPOINTMENTS | Staff attends appointments | 1:N |
| MEDICAL_STAFF | MEDICAL_RECORDS | Staff creates records | 1:N |
| MEDICAL_STAFF | PRESCRIPTIONS | Staff prescribes medications | 1:N |
| MEDICAL_STAFF | TREATMENTS | Staff performs treatments | 1:N |
| DEPARTMENTS | MEDICAL_STAFF | Department has staff | 1:N |
| DEPARTMENTS | ROOMS | Department contains rooms | 1:N |
| ROOMS | APPOINTMENTS | Room used for appointments | 1:N |
| MEDICATIONS | PRESCRIPTIONS | Medication in prescriptions | 1:N |
| BILLING | BILL_ITEMS | Bill contains items | 1:N |
| BILLING | PAYMENTS | Bill has payments | 1:N |
| MEDICAL_RECORDS | TREATMENTS | Record includes treatments | 1:N |

---

## 📐 Relational Schema Diagram

```mermaid
classDiagram
    direction TB
    
    class Patients {
        +patient_id : INT [PK]
        +first_name : VARCHAR(50)
        +last_name : VARCHAR(50)
        +date_of_birth : DATE
        +gender : ENUM
        +phone : VARCHAR(15)
        +email : VARCHAR(100) [UK]
        +address : TEXT
        +emergency_contact_name : VARCHAR(100)
        +emergency_contact_phone : VARCHAR(15)
        +insurance_provider : VARCHAR(100)
        +insurance_policy_number : VARCHAR(50)
        +registration_date : TIMESTAMP
        +status : ENUM
    }

    class Medical_Staff {
        +staff_id : INT [PK]
        +first_name : VARCHAR(50)
        +last_name : VARCHAR(50)
        +role : ENUM
        +specialization : VARCHAR(100)
        +department_id : INT [FK]
        +phone : VARCHAR(15)
        +email : VARCHAR(100) [UK]
        +hire_date : DATE
        +license_number : VARCHAR(50) [UK]
        +license_expiry_date : DATE
        +salary : DECIMAL(10,2)
        +status : ENUM
    }

    class Departments {
        +department_id : INT [PK]
        +department_name : VARCHAR(100) [UK]
        +department_head_id : INT [FK]
        +location : VARCHAR(100)
        +phone : VARCHAR(15)
        +description : TEXT
        +created_date : TIMESTAMP
    }

    class Rooms {
        +room_id : INT [PK]
        +room_number : VARCHAR(10) [UK]
        +room_type : ENUM
        +department_id : INT [FK]
        +capacity : INT
        +current_occupancy : INT
        +daily_rate : DECIMAL(8,2)
        +status : ENUM
        +equipment_list : TEXT
        +last_maintenance_date : DATE
    }

    class Appointments {
        +appointment_id : INT [PK]
        +patient_id : INT [FK]
        +staff_id : INT [FK]
        +appointment_date : DATE
        +appointment_time : TIME
        +duration_minutes : INT
        +purpose : VARCHAR(200)
        +status : ENUM
        +notes : TEXT
        +room_id : INT [FK]
        +created_by : INT [FK]
    }

    class Medical_Records {
        +record_id : INT [PK]
        +patient_id : INT [FK]
        +staff_id : INT [FK]
        +visit_date : TIMESTAMP
        +diagnosis : TEXT
        +symptoms : TEXT
        +treatment_plan : TEXT
        +vital_signs : JSON
        +follow_up_required : BOOLEAN
        +follow_up_date : DATE
        +record_type : ENUM
        +chief_complaint : VARCHAR(500)
    }

    class Treatments {
        +treatment_id : INT [PK]
        +record_id : INT [FK]
        +staff_id : INT [FK]
        +room_id : INT [FK]
        +treatment_name : VARCHAR(200)
        +description : TEXT
        +treatment_date : TIMESTAMP
        +duration_minutes : INT
        +cost : DECIMAL(10,2)
        +status : ENUM
        +outcome : TEXT
    }

    class Medications {
        +medication_id : INT [PK]
        +medication_name : VARCHAR(200)
        +generic_name : VARCHAR(200)
        +brand_name : VARCHAR(200)
        +manufacturer : VARCHAR(100)
        +dosage_form : ENUM
        +strength : VARCHAR(50)
        +unit_price : DECIMAL(8,2)
        +stock_quantity : INT
        +minimum_stock_level : INT
        +expiry_date : DATE
        +batch_number : VARCHAR(50)
        +supplier : VARCHAR(100)
    }

    class Prescriptions {
        +prescription_id : INT [PK]
        +patient_id : INT [FK]
        +staff_id : INT [FK]
        +medication_id : INT [FK]
        +dosage : VARCHAR(100)
        +frequency : VARCHAR(100)
        +duration_days : INT
        +quantity_prescribed : INT
        +quantity_dispensed : INT
        +status : ENUM
        +instructions : TEXT
        +refills_allowed : INT
    }

    class Billing {
        +bill_id : INT [PK]
        +patient_id : INT [FK]
        +bill_date : TIMESTAMP
        +total_amount : DECIMAL(12,2)
        +insurance_coverage : DECIMAL(12,2)
        +patient_responsibility : DECIMAL(12,2)
        +discount_amount : DECIMAL(12,2)
        +tax_amount : DECIMAL(12,2)
        +final_amount : DECIMAL(12,2)
        +payment_status : ENUM
        +due_date : DATE
    }

    class Bill_Items {
        +item_id : INT [PK]
        +bill_id : INT [FK]
        +service_type : ENUM
        +service_code : VARCHAR(50)
        +service_description : VARCHAR(200)
        +quantity : INT
        +unit_price : DECIMAL(10,2)
        +total_price : DECIMAL(10,2)
        +service_date : DATE
    }

    class Payments {
        +payment_id : INT [PK]
        +bill_id : INT [FK]
        +payment_date : TIMESTAMP
        +amount_paid : DECIMAL(12,2)
        +payment_method : ENUM
        +transaction_reference : VARCHAR(100)
        +payment_status : ENUM
        +refund_amount : DECIMAL(12,2)
    }

    Departments "1" --> "*" Medical_Staff : employs
    Departments "1" --> "*" Rooms : contains
    Patients "1" --> "*" Appointments : schedules
    Medical_Staff "1" --> "*" Appointments : attends
    Rooms "1" --> "*" Appointments : hosts
    Patients "1" --> "*" Medical_Records : has
    Medical_Staff "1" --> "*" Medical_Records : creates
    Medical_Records "1" --> "*" Treatments : includes
    Patients "1" --> "*" Prescriptions : receives
    Medical_Staff "1" --> "*" Prescriptions : writes
    Medications "1" --> "*" Prescriptions : prescribed_in
    Patients "1" --> "*" Billing : billed_to
    Billing "1" --> "*" Bill_Items : contains
    Billing "1" --> "*" Payments : paid_via
```

---
