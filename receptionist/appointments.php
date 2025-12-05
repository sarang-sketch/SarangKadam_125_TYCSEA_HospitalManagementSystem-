<?php
/**
 * Appointment List
 * Hospital Management System
 */

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/auth_check.php';
require_once __DIR__ . '/../includes/functions.php';

requireRole(['admin', 'receptionist', 'doctor']);

$pageTitle = 'Appointments';
$pdo = getConnection();

// Handle status update
if (isset($_GET['update_status']) && isset($_GET['id'])) {
    $id = (int)$_GET['id'];
    $status = sanitize($_GET['update_status']);
    if (in_array($status, ['pending', 'completed', 'cancelled'])) {
        $stmt = $pdo->prepare("UPDATE appointments SET status = ? WHERE id = ?");
        $stmt->execute([$status, $id]);
        setFlashMessage('success', 'Appointment status updated.');
    }
    header('Location: appointments.php');
    exit;
}

// Handle delete
if (isset($_GET['delete']) && is_numeric($_GET['delete'])) {
    $stmt = $pdo->prepare("DELETE FROM appointments WHERE id = ?");
    $stmt->execute([$_GET['delete']]);
    setFlashMessage('success', 'Appointment deleted.');
    header('Location: appointments.php');
    exit;
}

// Get filters
$search = sanitize($_GET['search'] ?? '');
$dateFilter = sanitize($_GET['date'] ?? '');
$statusFilter = sanitize($_GET['status'] ?? '');
$doctorFilter = (int)($_GET['doctor'] ?? 0);
$page = max(1, (int)($_GET['page'] ?? 1));
$perPage = 20;

// Build query
$where = [];
$params = [];

if ($search) {
    $where[] = "(p.name LIKE ? OR p.patient_code LIKE ?)";
    $params[] = "%$search%";
    $params[] = "%$search%";
}

if ($dateFilter) {
    $where[] = "a.appointment_date = ?";
    $params[] = $dateFilter;
}

if ($statusFilter) {
    $where[] = "a.status = ?";
    $params[] = $statusFilter;
}

if ($doctorFilter) {
    $where[] = "a.doctor_id = ?";
    $params[] = $doctorFilter;
}

// If doctor, show only their appointments
if (isDoctor()) {
    $where[] = "a.doctor_id = ?";
    $params[] = getCurrentUserId();
}

$whereClause = $where ? 'WHERE ' . implode(' AND ', $where) : '';

// Get total count
$stmt = $pdo->prepare("SELECT COUNT(*) as count FROM appointments a JOIN patients p ON a.patient_id = p.id $whereClause");
$stmt->execute($params);
$totalItems = $stmt->fetch()['count'];
$pagination = getPagination($totalItems, $page, $perPage);

// Get appointments
$sql = "SELECT a.*, p.name as patient_name, p.patient_code, u.name as doctor_name 
        FROM appointments a 
        JOIN patients p ON a.patient_id = p.id 
        JOIN users u ON a.doctor_id = u.id 
        $whereClause 
        ORDER BY a.appointment_date DESC, a.appointment_time DESC 
        LIMIT {$pagination['per_page']} OFFSET {$pagination['offset']}";
$stmt = $pdo->prepare($sql);
$stmt->execute($params);
$appointments = $stmt->fetchAll();

// Get doctors for filter
$doctors = $pdo->query("SELECT id, name FROM users WHERE role = 'doctor' ORDER BY name")->fetchAll();

include __DIR__ . '/../includes/header.php';
?>

<div class="page-header d-flex justify-content-between align-items-center">
    <h1><i class="fas fa-calendar-check me-2"></i>Appointments</h1>
    <?php if (in_array(getCurrentUserRole(), ['admin', 'receptionist'])): ?>
        <a href="appointment_form.php" class="btn btn-primary">
            <i class="fas fa-plus me-2"></i>Book Appointment
        </a>
    <?php endif; ?>
</div>

<!-- Filters -->
<div class="card mb-4">
    <div class="card-body">
        <form method="GET" class="row g-3">
            <div class="col-md-3">
                <input type="text" class="form-control" name="search" placeholder="Search patient..." value="<?= htmlspecialchars($search) ?>">
            </div>
            <div class="col-md-2">
                <input type="date" class="form-control" name="date" value="<?= htmlspecialchars($dateFilter) ?>">
            </div>
            <div class="col-md-2">
                <select class="form-select" name="status">
                    <option value="">All Status</option>
                    <option value="pending" <?= $statusFilter === 'pending' ? 'selected' : '' ?>>Pending</option>
                    <option value="completed" <?= $statusFilter === 'completed' ? 'selected' : '' ?>>Completed</option>
                    <option value="cancelled" <?= $statusFilter === 'cancelled' ? 'selected' : '' ?>>Cancelled</option>
                </select>
            </div>
            <?php if (!isDoctor()): ?>
            <div class="col-md-2">
                <select class="form-select" name="doctor">
                    <option value="">All Doctors</option>
                    <?php foreach ($doctors as $doc): ?>
                        <option value="<?= $doc['id'] ?>" <?= $doctorFilter == $doc['id'] ? 'selected' : '' ?>><?= htmlspecialchars($doc['name']) ?></option>
                    <?php endforeach; ?>
                </select>
            </div>
            <?php endif; ?>
            <div class="col-md-1">
                <button type="submit" class="btn btn-outline-primary w-100"><i class="fas fa-filter"></i></button>
            </div>
            <div class="col-md-1">
                <a href="appointments.php" class="btn btn-outline-secondary w-100"><i class="fas fa-times"></i></a>
            </div>
        </form>
    </div>
</div>

<!-- Appointments Table -->
<div class="card">
    <div class="card-body p-0">
        <div class="table-responsive">
            <table class="table table-hover mb-0">
                <thead>
                    <tr>
                        <th>Patient</th>
                        <th>Doctor</th>
                        <th>Date</th>
                        <th>Time</th>
                        <th>Department</th>
                        <th>Status</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
                    <?php if (empty($appointments)): ?>
                        <tr><td colspan="7" class="text-center text-muted py-4">No appointments found</td></tr>
                    <?php else: ?>
                        <?php foreach ($appointments as $apt): ?>
                            <tr>
                                <td>
                                    <strong><?= htmlspecialchars($apt['patient_name']) ?></strong><br>
                                    <small class="text-muted"><?= htmlspecialchars($apt['patient_code']) ?></small>
                                </td>
                                <td><?= htmlspecialchars($apt['doctor_name']) ?></td>
                                <td><?= formatDate($apt['appointment_date']) ?></td>
                                <td><?= formatTime($apt['appointment_time']) ?></td>
                                <td><?= htmlspecialchars($apt['department']) ?></td>
                                <td>
                                    <span class="badge bg-<?= getStatusBadge($apt['status']) ?>">
                                        <?= ucfirst($apt['status']) ?>
                                    </span>
                                </td>
                                <td class="action-btns">
                                    <?php if ($apt['status'] === 'pending'): ?>
                                        <a href="?update_status=completed&id=<?= $apt['id'] ?>" class="btn btn-sm btn-outline-success" title="Complete">
                                            <i class="fas fa-check"></i>
                                        </a>
                                        <a href="?update_status=cancelled&id=<?= $apt['id'] ?>" class="btn btn-sm btn-outline-warning" title="Cancel">
                                            <i class="fas fa-ban"></i>
                                        </a>
                                    <?php endif; ?>
                                    <?php if (in_array(getCurrentUserRole(), ['admin', 'receptionist'])): ?>
                                        <a href="appointment_form.php?id=<?= $apt['id'] ?>" class="btn btn-sm btn-outline-primary" title="Edit">
                                            <i class="fas fa-edit"></i>
                                        </a>
                                        <a href="?delete=<?= $apt['id'] ?>" class="btn btn-sm btn-outline-danger delete-confirm" title="Delete">
                                            <i class="fas fa-trash"></i>
                                        </a>
                                    <?php endif; ?>
                                </td>
                            </tr>
                        <?php endforeach; ?>
                    <?php endif; ?>
                </tbody>
            </table>
        </div>
    </div>
</div>

<?php 
$baseUrl = "appointments.php?" . http_build_query(array_filter(['search' => $search, 'date' => $dateFilter, 'status' => $statusFilter, 'doctor' => $doctorFilter]));
renderPagination($pagination, $baseUrl);
include __DIR__ . '/../includes/footer.php'; 
?>
