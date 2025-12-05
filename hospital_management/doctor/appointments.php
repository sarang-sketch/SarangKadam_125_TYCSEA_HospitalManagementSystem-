<?php
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/auth_check.php';
require_once __DIR__ . '/../includes/functions.php';
requireRole(['doctor']);

$pageTitle = 'My Appointments';
$pdo = getConnection();
$doctorId = getCurrentUserId();

if (isset($_GET['update_status']) && isset($_GET['id'])) {
    $status = sanitize($_GET['update_status']);
    if (in_array($status, ['pending', 'completed', 'cancelled'])) {
        $stmt = $pdo->prepare("UPDATE appointments SET status = ? WHERE id = ? AND doctor_id = ?");
        $stmt->execute([$status, (int)$_GET['id'], $doctorId]);
        setFlashMessage('success', 'Status updated.');
    }
    header('Location: appointments.php');
    exit;
}

$dateFilter = sanitize($_GET['date'] ?? date('Y-m-d'));
$stmt = $pdo->prepare("
    SELECT a.*, p.name as patient_name, p.patient_code, p.age, p.gender 
    FROM appointments a JOIN patients p ON a.patient_id = p.id 
    WHERE a.doctor_id = ? AND a.appointment_date = ?
    ORDER BY a.appointment_time
");
$stmt->execute([$doctorId, $dateFilter]);
$appointments = $stmt->fetchAll();

include __DIR__ . '/../includes/header.php';
?>

<div class="page-header"><h1><i class="fas fa-calendar-check me-2"></i>My Appointments</h1></div>

<div class="card mb-4">
    <div class="card-body">
        <form method="GET" class="row g-3">
            <div class="col-md-4">
                <input type="date" class="form-control" name="date" value="<?= htmlspecialchars($dateFilter) ?>">
            </div>
            <div class="col-md-2">
                <button type="submit" class="btn btn-outline-primary w-100">Filter</button>
            </div>
        </form>
    </div>
</div>

<div class="card">
    <div class="card-body p-0">
        <table class="table table-hover mb-0">
            <thead><tr><th>Time</th><th>Patient</th><th>Age/Gender</th><th>Status</th><th>Actions</th></tr></thead>
            <tbody>
                <?php if (empty($appointments)): ?>
                    <tr><td colspan="5" class="text-center text-muted py-4">No appointments</td></tr>
                <?php else: ?>
                    <?php foreach ($appointments as $apt): ?>
                        <tr>
                            <td><?= formatTime($apt['appointment_time']) ?></td>
                            <td><strong><?= htmlspecialchars($apt['patient_name']) ?></strong><br><small><?= $apt['patient_code'] ?></small></td>
                            <td><?= $apt['age'] ?>y / <?= ucfirst($apt['gender']) ?></td>
                            <td><span class="badge bg-<?= getStatusBadge($apt['status']) ?>"><?= ucfirst($apt['status']) ?></span></td>
                            <td class="action-btns">
                                <?php if ($apt['status'] === 'pending'): ?>
                                    <a href="?update_status=completed&id=<?= $apt['id'] ?>" class="btn btn-sm btn-outline-success"><i class="fas fa-check"></i></a>
                                <?php endif; ?>
                                <a href="prescription_form.php?patient_id=<?= $apt['patient_id'] ?>" class="btn btn-sm btn-outline-primary"><i class="fas fa-prescription"></i></a>
                                <a href="lab_request.php?patient_id=<?= $apt['patient_id'] ?>" class="btn btn-sm btn-outline-info"><i class="fas fa-flask"></i></a>
                            </td>
                        </tr>
                    <?php endforeach; ?>
                <?php endif; ?>
            </tbody>
        </table>
    </div>
</div>

<?php include __DIR__ . '/../includes/footer.php'; ?>
