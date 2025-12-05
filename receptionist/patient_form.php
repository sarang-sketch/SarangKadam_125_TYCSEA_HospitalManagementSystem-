<?php
/**
 * Patient Add/Edit Form
 * Hospital Management System
 */

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/auth_check.php';
require_once __DIR__ . '/../includes/functions.php';

requireRole(['admin', 'receptionist']);

$pdo = getConnection();
$errors = [];
$patient = [
    'id' => '',
    'patient_code' => '',
    'name' => '',
    'age' => '',
    'gender' => '',
    'blood_group' => '',
    'phone' => '',
    'address' => '',
    'emergency_contact' => '',
    'medical_history' => ''
];

$isEdit = false;

// Load existing patient for edit
if (isset($_GET['id']) && is_numeric($_GET['id'])) {
    $stmt = $pdo->prepare("SELECT * FROM patients WHERE id = ?");
    $stmt->execute([$_GET['id']]);
    $existingPatient = $stmt->fetch();
    
    if ($existingPatient) {
        $patient = $existingPatient;
        $isEdit = true;
    }
}

$pageTitle = $isEdit ? 'Edit Patient' : 'Register Patient';

// Handle form submission
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $patient['name'] = sanitize($_POST['name'] ?? '');
    $patient['age'] = (int)($_POST['age'] ?? 0);
    $patient['gender'] = sanitize($_POST['gender'] ?? '');
    $patient['blood_group'] = sanitize($_POST['blood_group'] ?? '');
    $patient['phone'] = sanitize($_POST['phone'] ?? '');
    $patient['address'] = sanitize($_POST['address'] ?? '');
    $patient['emergency_contact'] = sanitize($_POST['emergency_contact'] ?? '');
    $patient['medical_history'] = sanitize($_POST['medical_history'] ?? '');
    
    // Validation
    if (empty($patient['name'])) {
        $errors[] = 'Name is required.';
    }
    
    if ($patient['age'] < 0 || $patient['age'] > 150) {
        $errors[] = 'Please enter a valid age.';
    }
    
    if (empty($patient['gender'])) {
        $errors[] = 'Gender is required.';
    }
    
    if (empty($patient['phone'])) {
        $errors[] = 'Phone number is required.';
    } elseif (!isValidPhone($patient['phone'])) {
        $errors[] = 'Invalid phone number format.';
    }
    
    // Save if no errors
    if (empty($errors)) {
        try {
            if ($isEdit) {
                $stmt = $pdo->prepare("UPDATE patients SET name = ?, age = ?, gender = ?, blood_group = ?, phone = ?, address = ?, emergency_contact = ?, medical_history = ? WHERE id = ?");
                $stmt->execute([
                    $patient['name'],
                    $patient['age'],
                    $patient['gender'],
                    $patient['blood_group'],
                    $patient['phone'],
                    $patient['address'],
                    $patient['emergency_contact'],
                    $patient['medical_history'],
                    $patient['id']
                ]);
                setFlashMessage('success', 'Patient updated successfully.');
            } else {
                $patientCode = generatePatientCode($pdo);
                $stmt = $pdo->prepare("INSERT INTO patients (patient_code, name, age, gender, blood_group, phone, address, emergency_contact, medical_history) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)");
                $stmt->execute([
                    $patientCode,
                    $patient['name'],
                    $patient['age'],
                    $patient['gender'],
                    $patient['blood_group'],
                    $patient['phone'],
                    $patient['address'],
                    $patient['emergency_contact'],
                    $patient['medical_history']
                ]);
                setFlashMessage('success', 'Patient registered successfully. ID: ' . $patientCode);
            }
            header('Location: patients.php');
            exit;
        } catch (PDOException $e) {
            error_log("Patient save error: " . $e->getMessage());
            $errors[] = 'An error occurred. Please try again.';
        }
    }
}

include __DIR__ . '/../includes/header.php';
?>

<div class="page-header">
    <h1><i class="fas fa-user-<?= $isEdit ? 'edit' : 'plus' ?> me-2"></i><?= $pageTitle ?></h1>
</div>

<div class="card">
    <div class="card-body">
        <?php displayValidationErrors($errors); ?>
        
        <form method="POST" class="needs-validation" novalidate>
            <div class="row">
                <?php if ($isEdit): ?>
                    <div class="col-md-4 mb-3">
                        <label class="form-label">Patient ID</label>
                        <input type="text" class="form-control" value="<?= htmlspecialchars($patient['patient_code']) ?>" readonly>
                    </div>
                <?php endif; ?>
                
                <div class="col-md-<?= $isEdit ? '4' : '6' ?> mb-3">
                    <label for="name" class="form-label">Full Name <span class="text-danger">*</span></label>
                    <input type="text" class="form-control" id="name" name="name" value="<?= htmlspecialchars($patient['name']) ?>" required>
                </div>
                
                <div class="col-md-<?= $isEdit ? '4' : '6' ?> mb-3">
                    <label for="phone" class="form-label">Phone Number <span class="text-danger">*</span></label>
                    <input type="tel" class="form-control" id="phone" name="phone" value="<?= htmlspecialchars($patient['phone']) ?>" required>
                </div>
            </div>
            
            <div class="row">
                <div class="col-md-3 mb-3">
                    <label for="age" class="form-label">Age <span class="text-danger">*</span></label>
                    <input type="number" class="form-control" id="age" name="age" min="0" max="150" value="<?= $patient['age'] ?>" required>
                </div>
                
                <div class="col-md-3 mb-3">
                    <label for="gender" class="form-label">Gender <span class="text-danger">*</span></label>
                    <select class="form-select" id="gender" name="gender" required>
                        <option value="">Select Gender</option>
                        <option value="male" <?= $patient['gender'] === 'male' ? 'selected' : '' ?>>Male</option>
                        <option value="female" <?= $patient['gender'] === 'female' ? 'selected' : '' ?>>Female</option>
                        <option value="other" <?= $patient['gender'] === 'other' ? 'selected' : '' ?>>Other</option>
                    </select>
                </div>
                
                <div class="col-md-3 mb-3">
                    <label for="blood_group" class="form-label">Blood Group</label>
                    <select class="form-select" id="blood_group" name="blood_group">
                        <option value="">Select Blood Group</option>
                        <?php foreach (['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'] as $bg): ?>
                            <option value="<?= $bg ?>" <?= $patient['blood_group'] === $bg ? 'selected' : '' ?>><?= $bg ?></option>
                        <?php endforeach; ?>
                    </select>
                </div>
                
                <div class="col-md-3 mb-3">
                    <label for="emergency_contact" class="form-label">Emergency Contact</label>
                    <input type="text" class="form-control" id="emergency_contact" name="emergency_contact" value="<?= htmlspecialchars($patient['emergency_contact']) ?>">
                </div>
            </div>
            
            <div class="mb-3">
                <label for="address" class="form-label">Address</label>
                <textarea class="form-control" id="address" name="address" rows="2"><?= htmlspecialchars($patient['address']) ?></textarea>
            </div>
            
            <div class="mb-3">
                <label for="medical_history" class="form-label">Medical History</label>
                <textarea class="form-control" id="medical_history" name="medical_history" rows="3" placeholder="Previous conditions, allergies, surgeries, etc."><?= htmlspecialchars($patient['medical_history']) ?></textarea>
            </div>
            
            <div class="mt-4">
                <button type="submit" class="btn btn-primary">
                    <i class="fas fa-save me-2"></i><?= $isEdit ? 'Update' : 'Register' ?> Patient
                </button>
                <a href="patients.php" class="btn btn-outline-secondary ms-2">
                    <i class="fas fa-times me-2"></i>Cancel
                </a>
            </div>
        </form>
    </div>
</div>

<?php include __DIR__ . '/../includes/footer.php'; ?>
