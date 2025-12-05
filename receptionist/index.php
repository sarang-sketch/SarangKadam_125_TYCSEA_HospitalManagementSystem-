<?php
/**
 * Receptionist Dashboard
 * Hospital Management System
 */

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/auth_check.php';
require_once __DIR__ . '/../includes/functions.php';

requireRole(['receptionist']);

$pageTitle = 'Receptionist Dashboard';
$pdo = getConnection();

// Stats
$stmt = $pdo->prepare("SELECT COUNT(*) as count FROM appointments WHERE appointment_date = CURDATE()");
$stmt->execute();
$todayAppointments = $stmt->fetch()['count'];

$stmt = $pdo->query("SELECT COUNT(*) as count FROM patients");
$totalPatients = $stmt->fetch()['count'];

$stmt = $pdo->query("SELECT COUNT(*) as count FROM admissions WHERE status = 'admitted'");
$admittedPatients = $stmt->fetch()['count'];

// Today's appointments
$stmt = $pdo->query("
    SELECT a.*, p.name as patient_name, p.patient_code, u.name as doctor_name 
    FROM appointments a 
    JOIN patients p ON a.patient_id = p.id 
    JOIN users u ON a.doctor_id = u.id 
    WHERE a.appointment_date = CURDATE()
    ORDER BY a.appointment_time
    LIMIT 10
");
$appointments = $stmt->fetchAll();

include __DIR__ . '/../includes/header.php';
?>

<div class="page-header">
    <h1><i class="fas fa-tachometer-alt me-2"></i>Receptionist Dashboard</h1>
</div>

<div class="row mb-4">
    <div class="col-md-4 mb-3">
        <div class="stat-card bg-primary">
            <i class="fas fa-calendar-check stat-icon"></i>
            <h3><?= $todayAppointments ?></h3>
            <p>Today's Appointments</p>
        </div>
    </div>
    <div class="col-md-4 mb-3">
        <div class="stat-card bg-success">
            <i class="fas fa-users stat-icon"></i>
            <h3><?= $totalPatients ?></h3>
            <p>Total Patients</p>
        </div>
    </div>
    <div class="col-md-4 mb-3">
        <div class="stat-card bg-info">
            <i class="fas fa-procedures stat-icon"></i>
            <h3><?= $admittedPatients ?></h3>
            <p>Admitted Patients</p>
        </div>
    </div>
</div>

<div class="row mb-4">
    <div class="col-md-6">
        <a href="patient_form.php" class="btn btn-lg btn-primary w-100 py-3 mb-3">
            <i class="fas fa-user-plus me-2"></i>Register New Patient
        </a>
    </div>
    <div class="col-md-6">
        <a href="appointment_form.php" class="btn btn-lg btn-success w-100 py-3 mb-3">
            <i class="fas fa-calendar-plus me-2"></i>Book Appointment
        </a>
    </div>
</div>

<div class="card">
    <div class="card-header bg-white">
        <h5 class="mb-0"><i class="fas fa-calendar-day me-2"></i>Today's Appointments</h5>
    </div>
    <div class="card-body p-0">
        <table class="table table-hover mb-0">
            <thead><tr><th>Time</th><th>Patient</th><th>Doctor</th><th>Status</th></tr></thead>
            <tbody>
                <?php if (empty($appointments)): ?>
                    <tr><td colspan="4" class="text-center text-muted py-3">No appointments today</td></tr>
                <?php else: ?>
                    <?php foreach ($appointments as $apt): ?>
                        <tr>
                            <td><?= formatTime($apt['appointment_time']) ?></td>
                            <td><?= htmlspecialchars($apt['patient_name']) ?></td>
                            <td><?= htmlspecialchars($apt['doctor_name']) ?></td>
                            <td><span class="badge bg-<?= getStatusBadge($apt['status']) ?>"><?= ucfirst($apt['status']) ?></span></td>
                        </tr>
                    <?php endforeach; ?>
                <?php endif; ?>
            </tbody>
        </table>
    </div>
</div>

<?php include __DIR__ . '/../includes/footer.php'; ?>
