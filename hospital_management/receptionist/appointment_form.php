<?php
/**
 * Appointment Booking Form
 * Hospital Management System
 */

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/auth_check.php';
require_once __DIR__ . '/../includes/functions.php';

requireRole(['admin', 'receptionist']);

$pdo = getConnection();
$errors = [];
$appointment = [
    'id' => '',
    'patient_id' => '',
    'doctor_id' => '',
    'appointment_date' => date('Y-m-d'),
    'appointment_time' => '',
    'department' => '',
    'status' => 'pending'
];

$isEdit = false;

// Load existing appointment for edit
if (isset($_GET['id']) && is_numeric($_GET['id'])) {
    $stmt = $pdo->prepare("SELECT * FROM appointments WHERE id = ?");
    $stmt->execute([$_GET['id']]);
    $existing = $stmt->fetch();
    if ($existing) {
        $appointment = $existing;
        $isEdit = true;
    }
}

$pageTitle = $isEdit ? 'Edit Appointment' : 'Book Appointment';

// Handle form submission
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $appointment['patient_id'] = (int)($_POST['patient_id'] ?? 0);
    $appointment['doctor_id'] = (int)($_POST['doctor_id'] ?? 0);
    $appointment['appointment_date'] = sanitize($_POST['appointment_date'] ?? '');
    $appointment['appointment_time'] = sanitize($_POST['appointment_time'] ?? '');
    $appointment['department'] = sanitize($_POST['department'] ?? '');
    
    if (!$appointment['patient_id']) $errors[] = 'Please select a patient.';
    if (!$appointment['doctor_id']) $errors[] = 'Please select a doctor.';
    if (empty($appointment['appointment_date'])) $errors[] = 'Date is required.';
    if (empty($appointment['appointment_time'])) $errors[] = 'Time is required.';
    
    if (!$isEdit && $appointment['appointment_date'] < date('Y-m-d')) {
        $errors[] = 'Cannot book appointments in the past.';
    }
    
    if (empty($errors)) {
        try {
            if ($isEdit) {
                $stmt = $pdo->prepare("UPDATE appointments SET patient_id = ?, doctor_id = ?, appointment_date = ?, appointment_time = ?, department = ? WHERE id = ?");
                $stmt->execute([$appointment['patient_id'], $appointment['doctor_id'], $appointment['appointment_date'], $appointment['appointment_time'], $appointment['department'], $appointment['id']]);
                setFlashMessage('success', 'Appointment updated.');
            } else {
                $stmt = $pdo->prepare("INSERT INTO appointments (patient_id, doctor_id, appointment_date, appointment_time, department) VALUES (?, ?, ?, ?, ?)");
                $stmt->execute([$appointment['patient_id'], $appointment['doctor_id'], $appointment['appointment_date'], $appointment['appointment_time'], $appointment['department']]);
                setFlashMessage('success', 'Appointment booked successfully.');
            }
            header('Location: appointments.php');
            exit;
        } catch (PDOException $e) {
            error_log("Appointment save error: " . $e->getMessage());
            $errors[] = 'An error occurred. Please try again.';
        }
    }
}

// Get patients and doctors
$patients = $pdo->query("SELECT id, patient_code, name FROM patients ORDER BY name")->fetchAll();
$doctors = $pdo->query("SELECT id, name, department FROM users WHERE role = 'doctor' ORDER BY name")->fetchAll();

include __DIR__ . '/../includes/header.php';
?>

<div class="page-header">
    <h1><i class="fas fa-calendar-plus me-2"></i><?= $pageTitle ?></h1>
</div>

<div class="card">
    <div class="card-body">
        <?php displayValidationErrors($errors); ?>
        
        <form method="POST" class="needs-validation" novalidate>
            <div class="row">
                <div class="col-md-6 mb-3">
                    <label for="patient_id" class="form-label">Patient <span class="text-danger">*</span></label>
                    <select class="form-select" id="patient_id" name="patient_id" required>
                        <option value="">Select Patient</option>
                        <?php foreach ($patients as $p): ?>
                            <option value="<?= $p['id'] ?>" <?= $appointment['patient_id'] == $p['id'] ? 'selected' : '' ?>>
                                <?= htmlspecialchars($p['patient_code'] . ' - ' . $p['name']) ?>
                            </option>
                        <?php endforeach; ?>
                    </select>
                </div>
                
                <div class="col-md-6 mb-3">
                    <label for="department" class="form-label">Department</label>
                    <select class="form-select" id="department" name="department">
                        <option value="">Select Department</option>
                        <option value="General Medicine" <?= $appointment['department'] === 'General Medicine' ? 'selected' : '' ?>>General Medicine</option>
                        <option value="Cardiology" <?= $appointment['department'] === 'Cardiology' ? 'selected' : '' ?>>Cardiology</option>
                        <option value="Orthopedics" <?= $appointment['department'] === 'Orthopedics' ? 'selected' : '' ?>>Orthopedics</option>
                        <option value="Pediatrics" <?= $appointment['department'] === 'Pediatrics' ? 'selected' : '' ?>>Pediatrics</option>
                        <option value="Gynecology" <?= $appointment['department'] === 'Gynecology' ? 'selected' : '' ?>>Gynecology</option>
                        <option value="Dermatology" <?= $appointment['department'] === 'Dermatology' ? 'selected' : '' ?>>Dermatology</option>
                        <option value="ENT" <?= $appointment['department'] === 'ENT' ? 'selected' : '' ?>>ENT</option>
                        <option value="Neurology" <?= $appointment['department'] === 'Neurology' ? 'selected' : '' ?>>Neurology</option>
                    </select>
                </div>
            </div>
            
            <div class="row">
                <div class="col-md-4 mb-3">
                    <label for="doctor_id" class="form-label">Doctor <span class="text-danger">*</span></label>
                    <select class="form-select" id="doctor_id" name="doctor_id" required>
                        <option value="">Select Doctor</option>
                        <?php foreach ($doctors as $d): ?>
                            <option value="<?= $d['id'] ?>" <?= $appointment['doctor_id'] == $d['id'] ? 'selected' : '' ?>>
                                <?= htmlspecialchars($d['name']) ?> (<?= htmlspecialchars($d['department']) ?>)
                            </option>
                        <?php endforeach; ?>
                    </select>
                </div>
                
                <div class="col-md-4 mb-3">
                    <label for="appointment_date" class="form-label">Date <span class="text-danger">*</span></label>
                    <input type="date" class="form-control" id="appointment_date" name="appointment_date" value="<?= htmlspecialchars($appointment['appointment_date']) ?>" min="<?= date('Y-m-d') ?>" required>
                </div>
                
                <div class="col-md-4 mb-3">
                    <label for="appointment_time" class="form-label">Time <span class="text-danger">*</span></label>
                    <input type="time" class="form-control" id="appointment_time" name="appointment_time" value="<?= htmlspecialchars($appointment['appointment_time']) ?>" required>
                </div>
            </div>
            
            <div class="mt-4">
                <button type="submit" class="btn btn-primary">
                    <i class="fas fa-save me-2"></i><?= $isEdit ? 'Update' : 'Book' ?> Appointment
                </button>
                <a href="appointments.php" class="btn btn-outline-secondary ms-2">
                    <i class="fas fa-times me-2"></i>Cancel
                </a>
            </div>
        </form>
    </div>
</div>

<?php include __DIR__ . '/../includes/footer.php'; ?>
