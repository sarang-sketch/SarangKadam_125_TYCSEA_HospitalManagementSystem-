# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-12-05

### Added
- Initial release of Hospital Management System
- Multi-role authentication (Admin, Doctor, Nurse, Receptionist, Lab Tech, Pharmacist)
- Patient management with registration, search, and profile view
- Appointment booking and management system
- IPD (Inpatient) management with admission and discharge
- Prescription creation with multiple medicines
- Lab test request and result management
- Billing system with itemized invoices
- Pharmacy inventory management
- Ward and bed management
- Role-based dashboards for all user types
- Responsive Bootstrap 5 UI
- MySQL database with sample data
- Secure authentication with password hashing
- SQL injection prevention with prepared statements

### Security
- Implemented bcrypt password hashing
- Added prepared statements for all database queries
- XSS prevention with output escaping
- Session-based authentication
- Role-based access control on all pages

## [Unreleased]

### Planned
- Patient portal for self-service
- Email notifications for appointments
- SMS integration
- Report generation (PDF/Excel)
- Activity logging for admin
- Dark mode theme
- Multi-language support
