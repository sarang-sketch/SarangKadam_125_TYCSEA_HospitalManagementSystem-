<?php
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/auth_check.php';
require_once __DIR__ . '/../includes/functions.php';
requireRole(['doctor']);

$pageTitle = 'Create Prescription';
$pdo = getConnection();
$doctorId = getCurrentUserId();
$errors = [];

$prescription = ['patient_id' => (int)($_GET['patient_id'] ?? 0), 'symptoms' => '', 'diagnosis' => '', 'advice' => ''];

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $prescription['patient_id'] = (int)($_POST['patient_id'] ?? 0);
    $prescription['symptoms'] = sanitize($_POST['symptoms'] ?? '');
    $prescription['diagnosis'] = sanitize($_POST['diagnosis'] ?? '');
    $prescription['advice'] = sanitize($_POST['advice'] ?? '');
    $medicines = $_POST['medicines'] ?? [];
    
    if (!$prescription['patient_id']) $errors[] = 'Please select a patient.';
    if (empty($prescription['diagnosis'])) $errors[] = 'Diagnosis is required.';
    
    if (empty($errors)) {
        try {
            $pdo->beginTransaction();
            $stmt = $pdo->prepare("INSERT INTO prescriptions (patient_id, doctor_id, visit_date, symptoms, diagnosis, advice) VALUES (?, ?, CURDATE(), ?, ?, ?)");
            $stmt->execute([$prescription['patient_id'], $doctorId, $prescription['symptoms'], $prescription['diagnosis'], $prescription['advice']]);
            $prescriptionId = $pdo->lastInsertId();
            
            $stmt = $pdo->prepare("INSERT INTO prescription_items (prescription_id, medicine_name, dosage, frequency, duration) VALUES (?, ?, ?, ?, ?)");
            foreach ($medicines as $med) {
                if (!empty($med['name'])) {
                    $stmt->execute([$prescriptionId, sanitize($med['name']), sanitize($med['dosage'] ?? ''), sanitize($med['frequency'] ?? ''), sanitize($med['duration'] ?? '')]);
                }
            }
            $pdo->commit();
            setFlashMessage('success', 'Prescription created.');
            header('Location: prescriptions.php');
            exit;
        } catch (PDOException $e) {
            $pdo->rollBack();
            $errors[] = 'Error saving prescription.';
        }
    }
}

$patients = $pdo->query("SELECT id, patient_code, name FROM patients ORDER BY name")->fetchAll();
include __DIR__ . '/../includes/header.php';
?>

<div class="page-header"><h1><i class="fas fa-prescription me-2"></i>Create Prescription</h1></div>

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
                            <option value="<?= $p['id'] ?>" <?= $prescription['patient_id'] == $p['id'] ? 'selected' : '' ?>><?= htmlspecialchars($p['patient_code'] . ' - ' . $p['name']) ?></option>
                        <?php endforeach; ?>
                    </select>
                </div>
            </div>
            <div class="mb-3">
                <label class="form-label">Symptoms</label>
                <textarea class="form-control" name="symptoms" rows="2"><?= htmlspecialchars($prescription['symptoms']) ?></textarea>
            </div>
            <div class="mb-3">
                <label class="form-label">Diagnosis <span class="text-danger">*</span></label>
                <textarea class="form-control" name="diagnosis" rows="2" required><?= htmlspecialchars($prescription['diagnosis']) ?></textarea>
            </div>
            <div class="mb-3">
                <label class="form-label">Advice</label>
                <textarea class="form-control" name="advice" rows="2"><?= htmlspecialchars($prescription['advice']) ?></textarea>
            </div>
            
            <h5 class="mt-4 mb-3">Medicines</h5>
            <div id="medicineItems">
                <div class="row mb-3 medicine-item">
                    <div class="col-md-3"><input type="text" class="form-control" name="medicines[0][name]" placeholder="Medicine Name"></div>
                    <div class="col-md-2"><input type="text" class="form-control" name="medicines[0][dosage]" placeholder="Dosage"></div>
                    <div class="col-md-2"><input type="text" class="form-control" name="medicines[0][frequency]" placeholder="Frequency"></div>
                    <div class="col-md-2"><input type="text" class="form-control" name="medicines[0][duration]" placeholder="Duration"></div>
                    <div class="col-md-3"><button type="button" class="btn btn-danger btn-sm remove-medicine"><i class="fas fa-trash"></i></button></div>
                </div>
            </div>
            <button type="button" class="btn btn-outline-secondary btn-sm mb-4" id="addMedicine"><i class="fas fa-plus me-1"></i>Add Medicine</button>
            
            <div class="mt-4">
                <button type="submit" class="btn btn-primary"><i class="fas fa-save me-2"></i>Save Prescription</button>
                <a href="prescriptions.php" class="btn btn-outline-secondary ms-2">Cancel</a>
            </div>
        </form>
    </div>
</div>

<?php include __DIR__ . '/../includes/footer.php'; ?>
