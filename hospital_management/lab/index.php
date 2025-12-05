<?php
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/auth_check.php';
require_once __DIR__ . '/../includes/functions.php';
requireRole(['lab']);

$pageTitle = 'Lab Dashboard';
$pdo = getConnection();

$stmt = $pdo->query("SELECT COUNT(*) as count FROM lab_tests WHERE status = 'requested'");
$pendingTests = $stmt->fetch()['count'];

$stmt = $pdo->query("SELECT COUNT(*) as count FROM lab_tests WHERE status = 'in-progress'");
$inProgressTests = $stmt->fetch()['count'];

$stmt = $pdo->query("SELECT COUNT(*) as count FROM lab_tests WHERE status = 'completed' AND result_date = CURDATE()");
$completedToday = $stmt->fetch()['count'];

$stmt = $pdo->query("
    SELECT lt.*, p.name as patient_name, p.patient_code, u.name as doctor_name 
    FROM lab_tests lt JOIN patients p ON lt.patient_id = p.id JOIN users u ON lt.doctor_id = u.id 
    WHERE lt.status IN ('requested', 'in-progress') ORDER BY lt.requested_date LIMIT 10
");
$tests = $stmt->fetchAll();

include __DIR__ . '/../includes/header.php';
?>

<div class="page-header"><h1><i class="fas fa-tachometer-alt me-2"></i>Lab Dashboard</h1></div>

<div class="row mb-4">
    <div class="col-md-4 mb-3">
        <div class="stat-card bg-warning">
            <i class="fas fa-clock stat-icon"></i>
            <h3><?= $pendingTests ?></h3>
            <p>Pending Tests</p>
        </div>
    </div>
    <div class="col-md-4 mb-3">
        <div class="stat-card bg-info">
            <i class="fas fa-spinner stat-icon"></i>
            <h3><?= $inProgressTests ?></h3>
            <p>In Progress</p>
        </div>
    </div>
    <div class="col-md-4 mb-3">
        <div class="stat-card bg-success">
            <i class="fas fa-check-circle stat-icon"></i>
            <h3><?= $completedToday ?></h3>
            <p>Completed Today</p>
        </div>
    </div>
</div>

<div class="card">
    <div class="card-header bg-white d-flex justify-content-between align-items-center">
        <h5 class="mb-0"><i class="fas fa-flask me-2"></i>Pending Tests</h5>
        <a href="tests.php" class="btn btn-sm btn-outline-primary">View All</a>
    </div>
    <div class="card-body p-0">
        <table class="table table-hover mb-0">
            <thead><tr><th>Requested</th><th>Patient</th><th>Test</th><th>Doctor</th><th>Status</th><th>Actions</th></tr></thead>
            <tbody>
                <?php foreach ($tests as $test): ?>
                    <tr>
                        <td><?= formatDate($test['requested_date']) ?></td>
                        <td><strong><?= htmlspecialchars($test['patient_name']) ?></strong></td>
                        <td><?= htmlspecialchars($test['test_name']) ?></td>
                        <td><?= htmlspecialchars($test['doctor_name']) ?></td>
                        <td><span class="badge bg-<?= getStatusBadge($test['status']) ?>"><?= ucfirst($test['status']) ?></span></td>
                        <td><a href="test_result.php?id=<?= $test['id'] ?>" class="btn btn-sm btn-outline-primary"><i class="fas fa-edit"></i></a></td>
                    </tr>
                <?php endforeach; ?>
            </tbody>
        </table>
    </div>
</div>

<?php include __DIR__ . '/../includes/footer.php'; ?>
