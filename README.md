# 🏥 Hospital Management System

[![PHP Version](https://img.shields.io/badge/PHP-8.0%2B-777BB4?logo=php)](https://php.net)
[![MySQL](https://img.shields.io/badge/MySQL-5.7%2B-4479A1?logo=mysql&logoColor=white)](https://mysql.com)
[![Bootstrap](https://img.shields.io/badge/Bootstrap-5.3-7952B3?logo=bootstrap&logoColor=white)](https://getbootstrap.com)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

A complete, production-ready Hospital Management System built with PHP and MySQL. Features role-based access control, patient management, appointments, prescriptions, lab tests, billing, and pharmacy inventory.

![HMS Dashboard](https://via.placeholder.com/800x400/0d6efd/ffffff?text=Hospital+Management+System)

## ✨ Features

### 👥 Multi-Role Authentication
- **Admin** - Full system access, user & ward management
- **Doctor** - Appointments, prescriptions, lab requests
- **Nurse** - Patient care, admission notes
- **Receptionist** - Patient registration, appointments, billing
- **Lab Technician** - Test results, report uploads
- **Pharmacist** - Prescription dispensing, inventory

### 📋 Core Modules
- **Patient Management** - Registration, search, medical history
- **Appointment Booking** - Schedule, reschedule, cancel
- **IPD Management** - Admissions, ward/bed allocation, discharge
- **Prescriptions** - Create, print, track dispensing
- **Lab Tests** - Request, results entry, PDF uploads
- **Billing** - Itemized bills, tax calculation, printable invoices
- **Pharmacy** - Medicine inventory, stock alerts, expiry tracking

### 🔒 Security Features
- Password hashing (bcrypt)
- SQL injection prevention (prepared statements)
- XSS protection (output escaping)
- Session-based authentication
- Role-based access control

## 🚀 Quick Start

### Prerequisites
- [XAMPP](https://www.apachefriends.org/) (Apache + MySQL + PHP 8+)
- Web browser (Chrome, Firefox, Edge)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/hospital-management-system.git
   ```

2. **Copy to XAMPP**
   ```bash
   # Windows
   copy hospital-management-system C:\xampp\htdocs\hospital_management
   
   # Mac/Linux
   cp -r hospital-management-system /opt/lampp/htdocs/hospital_management
   ```

3. **Start XAMPP**
   - Open XAMPP Control Panel
   - Start Apache and MySQL

4. **Import Database**
   - Open http://localhost/phpmyadmin
   - Click "Import" tab
   - Select `hospital_management/db.sql`
   - Click "Go"

5. **Configure Database** (if needed)
   
   Edit `config/database.php`:
   ```php
   define('DB_HOST', 'localhost');
   define('DB_USER', 'root');
   define('DB_PASS', '');  // Your MySQL password
   define('DB_NAME', 'hospital_management');
   ```

6. **Access the System**
   
   Open http://localhost/hospital_management

## 🔑 Default Login Credentials

| Role | Email | Password |
|------|-------|----------|
| Admin | admin@hospital.com | Admin@123 |
| Doctor | doctor1@hospital.com | Admin@123 |
| Doctor | doctor2@hospital.com | Admin@123 |
| Nurse | nurse@hospital.com | Admin@123 |
| Receptionist | reception@hospital.com | Admin@123 |
| Lab Technician | lab@hospital.com | Admin@123 |
| Pharmacist | pharmacy@hospital.com | Admin@123 |

> ⚠️ **Important:** Change default passwords after first login!

## 📁 Project Structure

```
hospital_management/
├── admin/              # Admin dashboard & management
├── doctor/             # Doctor module
├── nurse/              # Nurse module
├── receptionist/       # Patient, appointment, admission
├── lab/                # Lab test management
├── pharmacist/         # Pharmacy & inventory
├── billing/            # Bills & invoices
├── auth/               # Login, logout
├── config/             # Database configuration
├── includes/           # Shared components (header, footer, functions)
├── assets/
│   ├── css/           # Custom styles
│   ├── js/            # Custom JavaScript
│   └── img/           # Images
├── uploads/
│   └── lab_reports/   # Uploaded PDF reports
├── db.sql             # Database schema + sample data
├── index.php          # Entry point
└── README.md
```

## 🗄️ Database Schema

The system uses 11 interconnected tables:

- `users` - System users with roles
- `patients` - Patient records
- `appointments` - Scheduled appointments
- `admissions` - IPD admissions
- `wards` - Hospital wards
- `prescriptions` - Doctor prescriptions
- `prescription_items` - Medicines in prescriptions
- `lab_tests` - Lab test requests & results
- `bills` - Patient bills
- `bill_items` - Itemized charges
- `medicines` - Pharmacy inventory

## 📸 Screenshots

<details>
<summary>Click to view screenshots</summary>

### Login Page
![Login](https://via.placeholder.com/600x400/f8f9fa/212529?text=Login+Page)

### Admin Dashboard
![Admin Dashboard](https://via.placeholder.com/600x400/f8f9fa/212529?text=Admin+Dashboard)

### Patient Management
![Patients](https://via.placeholder.com/600x400/f8f9fa/212529?text=Patient+Management)

### Appointment Booking
![Appointments](https://via.placeholder.com/600x400/f8f9fa/212529?text=Appointments)

</details>

## 🛠️ Tech Stack

- **Backend:** PHP 8+
- **Database:** MySQL 5.7+ / MariaDB
- **Frontend:** HTML5, CSS3, JavaScript
- **UI Framework:** Bootstrap 5.3
- **Icons:** Font Awesome 6
- **Server:** Apache (XAMPP/LAMP/WAMP)

## 🤝 Contributing

Contributions are welcome! Please read our [Contributing Guide](CONTRIBUTING.md) for details.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add: AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Bootstrap](https://getbootstrap.com/) - UI Framework
- [Font Awesome](https://fontawesome.com/) - Icons
- [XAMPP](https://www.apachefriends.org/) - Development Environment

## 📧 Support

If you have any questions or need help, please:
- Open an [Issue](../../issues)
- Check existing issues for solutions

---

<p align="center">
  Made with ❤️ for healthcare
</p>
