<?php
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/auth_check.php';
require_once __DIR__ . '/../includes/functions.php';
requireRole(['nurse', 'doctor']);

$pdo = getConnection();
if (!isset($_GET['id'])) { header('Location: index.php'); exit; }

$stmt = $pdo->prepare("SELECT ad.*, p.name as patient_name, p.patient_code, p.age, p.gender, p.blood_group, w.ward_name, u.name as doctor_name FROM admissions ad JOIN patients p ON ad.patient_id = p.id JOIN wards w ON ad.ward_id = w.id JOIN users u ON ad.doctor_id = u.id WHERE ad.id = ?");
$stmt->execute([$_GET['id']]);
$admission = $stmt->fetch();
if (!$admission) { header('Location: index.php'); exit; }

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $notes = sanitize($_POST['notes'] ?? '');
    $stmt = $pdo->prepare("UPDATE admissions SET notes = ? WHERE id = ?");
    $stmt->execute([$notes, $admission['id']]);
    setFlashMessage('success', 'Notes updated.');
    header('Location: patient_care.php?id=' . $admission['id']);
    exit;
}

$pageTitle = 'Patient Care';
include __DIR__ . '/../includes/header.php';
?>

<div class="page-header"><h1><i class="fas fa-notes-medical me-2"></i>Patient Care</h1></div>

<div class="card mb-4">
    <div class="card-body">
        <div class="row">
            <div class="col-md-3"><label class="text-muted small">Patient</label><p class="mb-0 fw-bold"><?= htmlspecialchars($admission['patient_name']) ?> (<?= $admission['patient_code'] ?>)</p></div>
            <div class="col-md-2"><label class="text-muted small">Age/Gender</label><p class="mb-0"><?= $admission['age'] ?>y / <?= ucfirst($admission['gender']) ?></p></div>
            <div class="col-md-2"><label class="text-muted small">Blood Group</label><p class="mb-0"><span class="badge bg-danger"><?= $admission['blood_group'] ?: 'N/A' ?></span></p></div>
            <div class="col-md-2"><label class="text-muted small">Ward/Bed</label><p class="mb-0"><?= htmlspecialchars($admission['ward_name']) ?> - <?= $admission['bed_number'] ?></p></div>
            <div class="col-md-3"><label class="text-muted small">Doctor</label><p class="mb-0"><?= htmlspecialchars($admission['doctor_name']) ?></p></div>
        </div>
    </div>
</div>

<div class="card">
    <div class="card-header bg-white"><h5 class="mb-0">Care Notes</h5></div>
    <div class="card-body">
        <form method="POST">
            <div class="mb-3">
                <label class="form-label">Diagnosis</label>
                <p><?= nl2br(htmlspecialchars($admission['diagnosis'] ?: 'N/A')) ?></p>
            </div>
            <div class="mb-3">
                <label class="form-label">Notes / Observations</label>
                <textarea class="form-control" name="notes" rows="5"><?= htmlspecialchars($admission['notes']) ?></textarea>
                <small class="text-muted">Add observations, vitals, medication given, etc.</small>
            </div>
            <button type="submit" class="btn btn-primary"><i class="fas fa-save me-2"></i>Update Notes</button>
            <a href="index.php" class="btn btn-outline-secondary ms-2">Back</a>
        </form>
    </div>
</div>

<?php include __DIR__ . '/../includes/footer.php'; ?>
