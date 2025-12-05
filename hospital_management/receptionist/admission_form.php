<?php
/**
 * Admission Form
 * Hospital Management System
 */

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/auth_check.php';
require_once __DIR__ . '/../includes/functions.php';

requireRole(['admin', 'receptionist']);

$pdo = getConnection();
$errors = [];
$admission = [
    'id' => '', 'patient_id' => '', 'doctor_id' => '', 'ward_id' => '',
    'bed_number' => '', 'diagnosis' => '', 'notes' => ''
];
$isEdit = false;

if (isset($_GET['id']) && is_numeric($_GET['id'])) {
    $stmt = $pdo->prepare("SELECT * FROM admissions WHERE id = ?");
    $stmt->execute([$_GET['id']]);
    $existing = $stmt->fetch();
    if ($existing) { $admission = $existing; $isEdit = true; }
}

$pageTitle = $isEdit ? 'Edit Admission' : 'New Admission';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $admission['patient_id'] = (int)($_POST['patient_id'] ?? 0);
    $admission['doctor_id'] = (int)($_POST['doctor_id'] ?? 0);
    $admission['ward_id'] = (int)($_POST['ward_id'] ?? 0);
    $admission['bed_number'] = sanitize($_POST['bed_number'] ?? '');
    $admission['diagnosis'] = sanitize($_POST['diagnosis'] ?? '');
    $admission['notes'] = sanitize($_POST['notes'] ?? '');
    
    if (!$admission['patient_id']) $errors[] = 'Please select a patient.';
    if (!$admission['doctor_id']) $errors[] = 'Please select a doctor.';
    if (!$admission['ward_id']) $errors[] = 'Please select a ward.';
    if (empty($admission['bed_number'])) $errors[] = 'Bed number is required.';
    
    if (empty($errors)) {
        try {
            if ($isEdit) {
                $stmt = $pdo->prepare("UPDATE admissions SET patient_id = ?, doctor_id = ?, ward_id = ?, bed_number = ?, diagnosis = ?, notes = ? WHERE id = ?");
                $stmt->execute([$admission['patient_id'], $admission['doctor_id'], $admission['ward_id'], $admission['bed_number'], $admission['diagnosis'], $admission['notes'], $admission['id']]);
                setFlashMessage('success', 'Admission updated.');
            } else {
                $stmt = $pdo->prepare("INSERT INTO admissions (patient_id, doctor_id, ward_id, bed_number, admission_date, diagnosis, notes) VALUES (?, ?, ?, ?, NOW(), ?, ?)");
                $stmt->execute([$admission['patient_id'], $admission['doctor_id'], $admission['ward_id'], $admission['bed_number'], $admission['diagnosis'], $admission['notes']]);
                setFlashMessage('success', 'Patient admitted successfully.');
            }
            header('Location: admissions.php');
            exit;
        } catch (PDOException $e) {
            error_log("Admission save error: " . $e->getMessage());
            $errors[] = 'An error occurred.';
        }
    }
}

$patients = $pdo->query("SELECT id, patient_code, name FROM patients ORDER BY name")->fetchAll();
$doctors = $pdo->query("SELECT id, name FROM users WHERE role = 'doctor' ORDER BY name")->fetchAll();
$wards = $pdo->query("SELECT * FROM wards ORDER BY ward_name")->fetchAll();

include __DIR__ . '/../includes/header.php';
?>

<div class="page-header"><h1><i class="fas fa-procedures me-2"></i><?= $pageTitle ?></h1></div>

<div class="card">
    <div class="card-body">
        <?php displayValidationErrors($errors); ?>
        <form method="POST">
            <div class="row">
                <div class="col-md-6 mb-3">
                    <label class="form-label">Patient <span class="text-danger">*</span></label>
                    <select class="form-select" name="patient_id" required>
                        <option value="">Select Patient</option>
                        <?php foreach ($patients as $p): ?>
                            <option value="<?= $p['id'] ?>" <?= $admission['patient_id'] == $p['id'] ? 'selected' : '' ?>><?= htmlspecialchars($p['patient_code'] . ' - ' . $p['name']) ?></option>
                        <?php endforeach; ?>
                    </select>
                </div>
                <div class="col-md-6 mb-3">
                    <label class="form-label">Doctor <span class="text-danger">*</span></label>
                    <select class="form-select" name="doctor_id" required>
                        <option value="">Select Doctor</option>
                        <?php foreach ($doctors as $d): ?>
                            <option value="<?= $d['id'] ?>" <?= $admission['doctor_id'] == $d['id'] ? 'selected' : '' ?>><?= htmlspecialchars($d['name']) ?></option>
                        <?php endforeach; ?>
                    </select>
                </div>
            </div>
            <div class="row">
                <div class="col-md-6 mb-3">
                    <label class="form-label">Ward <span class="text-danger">*</span></label>
                    <select class="form-select" name="ward_id" required>
                        <option value="">Select Ward</option>
                        <?php foreach ($wards as $w): ?>
                            <option value="<?= $w['id'] ?>" <?= $admission['ward_id'] == $w['id'] ? 'selected' : '' ?>><?= htmlspecialchars($w['ward_name']) ?> (<?= $w['total_beds'] ?> beds)</option>
                        <?php endforeach; ?>
                    </select>
                </div>
                <div class="col-md-6 mb-3">
                    <label class="form-label">Bed Number <span class="text-danger">*</span></label>
                    <input type="text" class="form-control" name="bed_number" value="<?= htmlspecialchars($admission['bed_number']) ?>" required>
                </div>
            </div>
            <div class="mb-3">
                <label class="form-label">Diagnosis</label>
                <textarea class="form-control" name="diagnosis" rows="2"><?= htmlspecialchars($admission['diagnosis']) ?></textarea>
            </div>
            <div class="mb-3">
                <label class="form-label">Notes</label>
                <textarea class="form-control" name="notes" rows="2"><?= htmlspecialchars($admission['notes']) ?></textarea>
            </div>
            <button type="submit" class="btn btn-primary"><i class="fas fa-save me-2"></i><?= $isEdit ? 'Update' : 'Admit Patient' ?></button>
            <a href="admissions.php" class="btn btn-outline-secondary ms-2">Cancel</a>
        </form>
    </div>
</div>

<?php include __DIR__ . '/../includes/footer.php'; ?>
