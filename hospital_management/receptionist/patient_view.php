<?php
/**
 * Patient Profile View
 * Hospital Management System
 */

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/auth_check.php';
require_once __DIR__ . '/../includes/functions.php';

requireRole(['admin', 'receptionist', 'doctor', 'nurse', 'lab']);

$pdo = getConnection();

// Get patient
if (!isset($_GET['id']) || !is_numeric($_GET['id'])) {
    header('Location: patients.php');
    exit;
}

$stmt = $pdo->prepare("SELECT * FROM patients WHERE id = ?");
$stmt->execute([$_GET['id']]);
$patient = $stmt->fetch();

if (!$patient) {
    setFlashMessage('danger', 'Patient not found.');
    header('Location: patients.php');
    exit;
}

$pageTitle = 'Patient: ' . $patient['name'];

// Get appointments
$stmt = $pdo->prepare("
    SELECT a.*, u.name as doctor_name 
    FROM appointments a 
    JOIN users u ON a.doctor_id = u.id 
    WHERE a.patient_id = ? 
    ORDER BY a.appointment_date DESC, a.appointment_time DESC 
    LIMIT 10
");
$stmt->execute([$patient['id']]);
$appointments = $stmt->fetchAll();

// Get admissions
$stmt = $pdo->prepare("
    SELECT ad.*, u.name as doctor_name, w.ward_name 
    FROM admissions ad 
    JOIN users u ON ad.doctor_id = u.id 
    JOIN wards w ON ad.ward_id = w.id 
    WHERE ad.patient_id = ? 
    ORDER BY ad.admission_date DESC 
    LIMIT 10
");
$stmt->execute([$patient['id']]);
$admissions = $stmt->fetchAll();

// Get prescriptions
$stmt = $pdo->prepare("
    SELECT p.*, u.name as doctor_name 
    FROM prescriptions p 
    JOIN users u ON p.doctor_id = u.id 
    WHERE p.patient_id = ? 
    ORDER BY p.visit_date DESC 
    LIMIT 10
");
$stmt->execute([$patient['id']]);
$prescriptions = $stmt->fetchAll();

// Get lab tests
$stmt = $pdo->prepare("
    SELECT lt.*, u.name as doctor_name 
    FROM lab_tests lt 
    JOIN users u ON lt.doctor_id = u.id 
    WHERE lt.patient_id = ? 
    ORDER BY lt.requested_date DESC 
    LIMIT 10
");
$stmt->execute([$patient['id']]);
$labTests = $stmt->fetchAll();

// Get bills
$stmt = $pdo->prepare("SELECT * FROM bills WHERE patient_id = ? ORDER BY created_at DESC LIMIT 10");
$stmt->execute([$patient['id']]);
$bills = $stmt->fetchAll();

include __DIR__ . '/../includes/header.php';
?>

<div class="page-header d-flex justify-content-between align-items-center">
    <h1><i class="fas fa-user me-2"></i><?= htmlspecialchars($patient['name']) ?></h1>
    <div>
        <?php if (in_array(getCurrentUserRole(), ['admin', 'receptionist'])): ?>
            <a href="patient_form.php?id=<?= $patient['id'] ?>" class="btn btn-primary">
                <i class="fas fa-edit me-2"></i>Edit
            </a>
        <?php endif; ?>
        <a href="patients.php" class="btn btn-outline-secondary">
            <i class="fas fa-arrow-left me-2"></i>Back
        </a>
    </div>
</div>

<!-- Patient Info Card -->
<div class="card mb-4">
    <div class="card-body">
        <div class="row">
            <div class="col-md-3 mb-3">
                <label class="text-muted small">Patient ID</label>
                <p class="mb-0 fw-bold"><?= htmlspecialchars($patient['patient_code']) ?></p>
            </div>
            <div class="col-md-3 mb-3">
                <label class="text-muted small">Age / Gender</label>
                <p class="mb-0"><?= $patient['age'] ?> years / <?= ucfirst($patient['gender']) ?></p>
            </div>
            <div class="col-md-3 mb-3">
                <label class="text-muted small">Blood Group</label>
                <p class="mb-0"><span class="badge bg-danger"><?= htmlspecialchars($patient['blood_group'] ?? 'N/A') ?></span></p>
            </div>
            <div class="col-md-3 mb-3">
                <label class="text-muted small">Phone</label>
                <p class="mb-0"><?= htmlspecialchars($patient['phone']) ?></p>
            </div>
            <div class="col-md-6 mb-3">
                <label class="text-muted small">Address</label>
                <p class="mb-0"><?= htmlspecialchars($patient['address'] ?? 'N/A') ?></p>
            </div>
            <div class="col-md-3 mb-3">
                <label class="text-muted small">Emergency Contact</label>
                <p class="mb-0"><?= htmlspecialchars($patient['emergency_contact'] ?? 'N/A') ?></p>
            </div>
            <div class="col-md-3 mb-3">
                <label class="text-muted small">Registered</label>
                <p class="mb-0"><?= formatDate($patient['created_at']) ?></p>
            </div>
            <?php if ($patient['medical_history']): ?>
                <div class="col-12">
                    <label class="text-muted small">Medical History</label>
                    <p class="mb-0"><?= nl2br(htmlspecialchars($patient['medical_history'])) ?></p>
                </div>
            <?php endif; ?>
        </div>
    </div>
</div>

<!-- Tabs -->
<ul class="nav nav-tabs" id="patientTabs" role="tablist">
    <li class="nav-item"><a class="nav-link active" data-bs-toggle="tab" href="#appointments">Appointments (<?= count($appointments) ?>)</a></li>
    <li class="nav-item"><a class="nav-link" data-bs-toggle="tab" href="#admissions">Admissions (<?= count($admissions) ?>)</a></li>
    <li class="nav-item"><a class="nav-link" data-bs-toggle="tab" href="#prescriptions">Prescriptions (<?= count($prescriptions) ?>)</a></li>
    <li class="nav-item"><a class="nav-link" data-bs-toggle="tab" href="#labtests">Lab Tests (<?= count($labTests) ?>)</a></li>
    <li class="nav-item"><a class="nav-link" data-bs-toggle="tab" href="#bills">Bills (<?= count($bills) ?>)</a></li>
</ul>

<div class="tab-content bg-white border border-top-0 rounded-bottom p-3">
    <!-- Appointments Tab -->
    <div class="tab-pane fade show active" id="appointments">
        <table class="table table-sm">
            <thead><tr><th>Date</th><th>Time</th><th>Doctor</th><th>Department</th><th>Status</th></tr></thead>
            <tbody>
                <?php if (empty($appointments)): ?>
                    <tr><td colspan="5" class="text-muted text-center">No appointments</td></tr>
                <?php else: ?>
                    <?php foreach ($appointments as $apt): ?>
                        <tr>
                            <td><?= formatDate($apt['appointment_date']) ?></td>
                            <td><?= formatTime($apt['appointment_time']) ?></td>
                            <td><?= htmlspecialchars($apt['doctor_name']) ?></td>
                            <td><?= htmlspecialchars($apt['department']) ?></td>
                            <td><span class="badge bg-<?= getStatusBadge($apt['status']) ?>"><?= ucfirst($apt['status']) ?></span></td>
                        </tr>
                    <?php endforeach; ?>
                <?php endif; ?>
            </tbody>
        </table>
    </div>
    
    <!-- Admissions Tab -->
    <div class="tab-pane fade" id="admissions">
        <table class="table table-sm">
            <thead><tr><th>Admitted</th><th>Ward</th><th>Bed</th><th>Doctor</th><th>Status</th><th>Discharged</th></tr></thead>
            <tbody>
                <?php if (empty($admissions)): ?>
                    <tr><td colspan="6" class="text-muted text-center">No admissions</td></tr>
                <?php else: ?>
                    <?php foreach ($admissions as $adm): ?>
                        <tr>
                            <td><?= formatDateTime($adm['admission_date']) ?></td>
                            <td><?= htmlspecialchars($adm['ward_name']) ?></td>
                            <td><?= htmlspecialchars($adm['bed_number']) ?></td>
                            <td><?= htmlspecialchars($adm['doctor_name']) ?></td>
                            <td><span class="badge bg-<?= getStatusBadge($adm['status']) ?>"><?= ucfirst($adm['status']) ?></span></td>
                            <td><?= $adm['discharge_date'] ? formatDateTime($adm['discharge_date']) : '-' ?></td>
                        </tr>
                    <?php endforeach; ?>
                <?php endif; ?>
            </tbody>
        </table>
    </div>
    
    <!-- Prescriptions Tab -->
    <div class="tab-pane fade" id="prescriptions">
        <table class="table table-sm">
            <thead><tr><th>Date</th><th>Doctor</th><th>Diagnosis</th><th>Status</th><th>Action</th></tr></thead>
            <tbody>
                <?php if (empty($prescriptions)): ?>
                    <tr><td colspan="5" class="text-muted text-center">No prescriptions</td></tr>
                <?php else: ?>
                    <?php foreach ($prescriptions as $presc): ?>
                        <tr>
                            <td><?= formatDate($presc['visit_date']) ?></td>
                            <td><?= htmlspecialchars($presc['doctor_name']) ?></td>
                            <td><?= htmlspecialchars(substr($presc['diagnosis'] ?? '', 0, 50)) ?>...</td>
                            <td><span class="badge bg-<?= getStatusBadge($presc['status']) ?>"><?= ucfirst($presc['status']) ?></span></td>
                            <td><a href="/hospital_management/doctor/prescription_view.php?id=<?= $presc['id'] ?>" class="btn btn-sm btn-outline-info">View</a></td>
                        </tr>
                    <?php endforeach; ?>
                <?php endif; ?>
            </tbody>
        </table>
    </div>
    
    <!-- Lab Tests Tab -->
    <div class="tab-pane fade" id="labtests">
        <table class="table table-sm">
            <thead><tr><th>Requested</th><th>Test</th><th>Doctor</th><th>Status</th><th>Result Date</th></tr></thead>
            <tbody>
                <?php if (empty($labTests)): ?>
                    <tr><td colspan="5" class="text-muted text-center">No lab tests</td></tr>
                <?php else: ?>
                    <?php foreach ($labTests as $test): ?>
                        <tr>
                            <td><?= formatDate($test['requested_date']) ?></td>
                            <td><?= htmlspecialchars($test['test_name']) ?></td>
                            <td><?= htmlspecialchars($test['doctor_name']) ?></td>
                            <td><span class="badge bg-<?= getStatusBadge($test['status']) ?>"><?= ucfirst($test['status']) ?></span></td>
                            <td><?= $test['result_date'] ? formatDate($test['result_date']) : '-' ?></td>
                        </tr>
                    <?php endforeach; ?>
                <?php endif; ?>
            </tbody>
        </table>
    </div>
    
    <!-- Bills Tab -->
    <div class="tab-pane fade" id="bills">
        <table class="table table-sm">
            <thead><tr><th>Date</th><th>Amount</th><th>Tax</th><th>Total</th><th>Status</th><th>Action</th></tr></thead>
            <tbody>
                <?php if (empty($bills)): ?>
                    <tr><td colspan="6" class="text-muted text-center">No bills</td></tr>
                <?php else: ?>
                    <?php foreach ($bills as $bill): ?>
                        <tr>
                            <td><?= formatDate($bill['created_at']) ?></td>
                            <td><?= formatCurrency($bill['total_amount']) ?></td>
                            <td><?= formatCurrency($bill['tax_amount']) ?></td>
                            <td><strong><?= formatCurrency($bill['total_amount'] + $bill['tax_amount']) ?></strong></td>
                            <td><span class="badge bg-<?= getStatusBadge($bill['status']) ?>"><?= ucfirst($bill['status']) ?></span></td>
                            <td><a href="/hospital_management/billing/invoice.php?id=<?= $bill['id'] ?>" class="btn btn-sm btn-outline-info">View</a></td>
                        </tr>
                    <?php endforeach; ?>
                <?php endif; ?>
            </tbody>
        </table>
    </div>
</div>

<?php include __DIR__ . '/../includes/footer.php'; ?>
