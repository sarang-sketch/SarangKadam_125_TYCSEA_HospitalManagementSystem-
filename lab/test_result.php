<?php
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/auth_check.php';
require_once __DIR__ . '/../includes/functions.php';
requireRole(['lab']);

$pdo = getConnection();
if (!isset($_GET['id'])) { header('Location: tests.php'); exit; }

$stmt = $pdo->prepare("SELECT lt.*, p.name as patient_name, p.patient_code, u.name as doctor_name FROM lab_tests lt JOIN patients p ON lt.patient_id = p.id JOIN users u ON lt.doctor_id = u.id WHERE lt.id = ?");
$stmt->execute([$_GET['id']]);
$test = $stmt->fetch();
if (!$test) { header('Location: tests.php'); exit; }

$errors = [];
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $status = sanitize($_POST['status'] ?? '');
    $result = sanitize($_POST['result'] ?? '');
    
    $reportFile = $test['report_file'];
    if (isset($_FILES['report_file']) && $_FILES['report_file']['error'] === UPLOAD_ERR_OK) {
        $allowed = ['application/pdf'];
        if (in_array($_FILES['report_file']['type'], $allowed) && $_FILES['report_file']['size'] <= 5242880) {
            $filename = 'report_' . $test['id'] . '_' . time() . '.pdf';
            $uploadPath = __DIR__ . '/../uploads/lab_reports/' . $filename;
            if (move_uploaded_file($_FILES['report_file']['tmp_name'], $uploadPath)) {
                $reportFile = $filename;
            }
        } else {
            $errors[] = 'Invalid file. Only PDF up to 5MB allowed.';
        }
    }
    
    if (empty($errors)) {
        $resultDate = ($status === 'completed') ? date('Y-m-d') : null;
        $stmt = $pdo->prepare("UPDATE lab_tests SET status = ?, result = ?, report_file = ?, result_date = ? WHERE id = ?");
        $stmt->execute([$status, $result, $reportFile, $resultDate, $test['id']]);
        setFlashMessage('success', 'Test updated.');
        header('Location: tests.php');
        exit;
    }
}

$pageTitle = 'Update Test Result';
include __DIR__ . '/../includes/header.php';
?>

<div class="page-header"><h1><i class="fas fa-flask me-2"></i>Update Test Result</h1></div>

<div class="card mb-4">
    <div class="card-body">
        <div class="row">
            <div class="col-md-3"><label class="text-muted small">Patient</label><p class="mb-0 fw-bold"><?= htmlspecialchars($test['patient_name']) ?></p></div>
            <div class="col-md-3"><label class="text-muted small">Test</label><p class="mb-0"><?= htmlspecialchars($test['test_name']) ?></p></div>
            <div class="col-md-3"><label class="text-muted small">Requested By</label><p class="mb-0"><?= htmlspecialchars($test['doctor_name']) ?></p></div>
            <div class="col-md-3"><label class="text-muted small">Requested Date</label><p class="mb-0"><?= formatDate($test['requested_date']) ?></p></div>
        </div>
    </div>
</div>

<div class="card">
    <div class="card-body">
        <?php displayValidationErrors($errors); ?>
        <form method="POST" enctype="multipart/form-data">
            <div class="row">
                <div class="col-md-6 mb-3">
                    <label class="form-label">Status</label>
                    <select class="form-select" name="status">
                        <option value="requested" <?= $test['status'] === 'requested' ? 'selected' : '' ?>>Requested</option>
                        <option value="in-progress" <?= $test['status'] === 'in-progress' ? 'selected' : '' ?>>In Progress</option>
                        <option value="completed" <?= $test['status'] === 'completed' ? 'selected' : '' ?>>Completed</option>
                    </select>
                </div>
                <div class="col-md-6 mb-3">
                    <label class="form-label">Upload Report (PDF, max 5MB)</label>
                    <input type="file" class="form-control" name="report_file" accept=".pdf">
                    <?php if ($test['report_file']): ?>
                        <small class="text-muted">Current: <a href="/hospital_management/uploads/lab_reports/<?= $test['report_file'] ?>" target="_blank"><?= $test['report_file'] ?></a></small>
                    <?php endif; ?>
                </div>
            </div>
            <div class="mb-3">
                <label class="form-label">Result (Text)</label>
                <textarea class="form-control" name="result" rows="5"><?= htmlspecialchars($test['result']) ?></textarea>
            </div>
            <button type="submit" class="btn btn-primary"><i class="fas fa-save me-2"></i>Update</button>
            <a href="tests.php" class="btn btn-outline-secondary ms-2">Cancel</a>
        </form>
    </div>
</div>

<?php include __DIR__ . '/../includes/footer.php'; ?>
