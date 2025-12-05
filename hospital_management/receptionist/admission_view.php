<?php
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/auth_check.php';
require_once __DIR__ . '/../includes/functions.php';
requireRole(['admin', 'receptionist', 'doctor', 'nurse']);

$pdo = getConnection();
if (!isset($_GET['id'])) { header('Location: admissions.php'); exit; }

$stmt = $pdo->prepare("SELECT ad.*, p.name as patient_name, p.patient_code, p.age, p.gender, p.blood_group, p.phone, w.ward_name, u.name as doctor_name FROM admissions ad JOIN patients p ON ad.patient_id = p.id JOIN wards w ON ad.ward_id = w.id JOIN users u ON ad.doctor_id = u.id WHERE ad.id = ?");
$stmt->execute([$_GET['id']]);
$admission = $stmt->fetch();
if (!$admission) { header('Location: admissions.php'); exit; }

$pageTitle = 'Admission Details';
include __DIR__ . '/../includes/header.php';
?>

<div class="page-header d-flex justify-content-between align-items-center">
    <h1><i class="fas fa-procedures me-2"></i>Admission Details</h1>
    <a href="admissions.php" class="btn btn-outline-secondary">Back</a>
</div>

<div class="card">
    <div class="card-body">
        <div class="row mb-4">
            <div class="col-md-3"><label class="text-muted small">Patient</label><p class="mb-0 fw-bold"><?= htmlspecialchars($admission['patient_name']) ?></p><small><?= $admission['patient_code'] ?></small></div>
            <div class="col-md-2"><label class="text-muted small">Age/Gender</label><p class="mb-0"><?= $admission['age'] ?>y / <?= ucfirst($admission['gender']) ?></p></div>
            <div class="col-md-2"><label class="text-muted small">Blood Group</label><p class="mb-0"><span class="badge bg-danger"><?= $admission['blood_group'] ?: 'N/A' ?></span></p></div>
            <div class="col-md-2"><label class="text-muted small">Phone</label><p class="mb-0"><?= htmlspecialchars($admission['phone']) ?></p></div>
            <div class="col-md-3"><label class="text-muted small">Status</label><p class="mb-0"><span class="badge bg-<?= getStatusBadge($admission['status']) ?>"><?= ucfirst($admission['status']) ?></span></p></div>
        </div>
        <hr>
        <div class="row mb-4">
            <div class="col-md-3"><label class="text-muted small">Ward</label><p class="mb-0"><?= htmlspecialchars($admission['ward_name']) ?></p></div>
            <div class="col-md-2"><label class="text-muted small">Bed</label><p class="mb-0"><?= htmlspecialchars($admission['bed_number']) ?></p></div>
            <div class="col-md-3"><label class="text-muted small">Doctor</label><p class="mb-0"><?= htmlspecialchars($admission['doctor_name']) ?></p></div>
            <div class="col-md-2"><label class="text-muted small">Admitted</label><p class="mb-0"><?= formatDateTime($admission['admission_date']) ?></p></div>
            <div class="col-md-2"><label class="text-muted small">Discharged</label><p class="mb-0"><?= $admission['discharge_date'] ? formatDateTime($admission['discharge_date']) : '-' ?></p></div>
        </div>
        <hr>
        <div class="row">
            <div class="col-md-6"><label class="text-muted small">Diagnosis</label><p><?= nl2br(htmlspecialchars($admission['diagnosis'] ?: 'N/A')) ?></p></div>
            <div class="col-md-6"><label class="text-muted small">Notes</label><p><?= nl2br(htmlspecialchars($admission['notes'] ?: 'N/A')) ?></p></div>
        </div>
    </div>
</div>

<?php include __DIR__ . '/../includes/footer.php'; ?>
