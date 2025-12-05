<?php
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/auth_check.php';
require_once __DIR__ . '/../includes/functions.php';
requireRole(['doctor']);

$pageTitle = 'Request Lab Test';
$pdo = getConnection();
$doctorId = getCurrentUserId();
$errors = [];

$patientId = (int)($_GET['patient_id'] ?? 0);

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $patientId = (int)($_POST['patient_id'] ?? 0);
    $testName = sanitize($_POST['test_name'] ?? '');
    
    if (!$patientId) $errors[] = 'Please select a patient.';
    if (empty($testName)) $errors[] = 'Test name is required.';
    
    if (empty($errors)) {
        $stmt = $pdo->prepare("INSERT INTO lab_tests (patient_id, doctor_id, test_name, requested_date) VALUES (?, ?, ?, CURDATE())");
        $stmt->execute([$patientId, $doctorId, $testName]);
        setFlashMessage('success', 'Lab test requested.');
        header('Location: lab_requests.php');
        exit;
    }
}

$patients = $pdo->query("SELECT id, patient_code, name FROM patients ORDER BY name")->fetchAll();
include __DIR__ . '/../includes/header.php';
?>

<div class="page-header"><h1><i class="fas fa-flask me-2"></i>Request Lab Test</h1></div>

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
                            <option value="<?= $p['id'] ?>" <?= $patientId == $p['id'] ? 'selected' : '' ?>><?= htmlspecialchars($p['patient_code'] . ' - ' . $p['name']) ?></option>
                        <?php endforeach; ?>
                    </select>
                </div>
                <div class="col-md-6 mb-3">
                    <label class="form-label">Test Name <span class="text-danger">*</span></label>
                    <select class="form-select" name="test_name" required>
                        <option value="">Select Test</option>
                        <option value="Complete Blood Count">Complete Blood Count (CBC)</option>
                        <option value="Lipid Profile">Lipid Profile</option>
                        <option value="Blood Glucose Fasting">Blood Glucose Fasting</option>
                        <option value="HbA1c">HbA1c</option>
                        <option value="Liver Function Test">Liver Function Test (LFT)</option>
                        <option value="Kidney Function Test">Kidney Function Test (KFT)</option>
                        <option value="Thyroid Profile">Thyroid Profile</option>
                        <option value="Urine Analysis">Urine Analysis</option>
                        <option value="ECG">ECG</option>
                        <option value="X-Ray">X-Ray</option>
                        <option value="Cardiac Enzymes">Cardiac Enzymes</option>
                    </select>
                </div>
            </div>
            <button type="submit" class="btn btn-primary"><i class="fas fa-paper-plane me-2"></i>Request Test</button>
            <a href="lab_requests.php" class="btn btn-outline-secondary ms-2">Cancel</a>
        </form>
    </div>
</div>

<?php include __DIR__ . '/../includes/footer.php'; ?>
