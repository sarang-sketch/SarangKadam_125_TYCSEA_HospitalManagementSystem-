<?php
/**
 * User Add/Edit Form
 * Hospital Management System
 */

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/auth_check.php';
require_once __DIR__ . '/../includes/functions.php';

requireRole(['admin']);

$pdo = getConnection();
$errors = [];
$user = [
    'id' => '',
    'name' => '',
    'email' => '',
    'role' => '',
    'phone' => '',
    'department' => ''
];

$isEdit = false;

// Load existing user for edit
if (isset($_GET['id']) && is_numeric($_GET['id'])) {
    $stmt = $pdo->prepare("SELECT * FROM users WHERE id = ?");
    $stmt->execute([$_GET['id']]);
    $existingUser = $stmt->fetch();
    
    if ($existingUser) {
        $user = $existingUser;
        $isEdit = true;
    }
}

$pageTitle = $isEdit ? 'Edit User' : 'Add User';

// Handle form submission
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $user['name'] = sanitize($_POST['name'] ?? '');
    $user['email'] = sanitize($_POST['email'] ?? '');
    $user['role'] = sanitize($_POST['role'] ?? '');
    $user['phone'] = sanitize($_POST['phone'] ?? '');
    $user['department'] = sanitize($_POST['department'] ?? '');
    $password = $_POST['password'] ?? '';
    $confirmPassword = $_POST['confirm_password'] ?? '';
    
    // Validation
    if (empty($user['name'])) {
        $errors[] = 'Name is required.';
    }
    
    if (empty($user['email'])) {
        $errors[] = 'Email is required.';
    } elseif (!isValidEmail($user['email'])) {
        $errors[] = 'Invalid email format.';
    } else {
        // Check unique email
        $stmt = $pdo->prepare("SELECT id FROM users WHERE email = ? AND id != ?");
        $stmt->execute([$user['email'], $user['id'] ?: 0]);
        if ($stmt->fetch()) {
            $errors[] = 'Email already exists.';
        }
    }
    
    if (empty($user['role'])) {
        $errors[] = 'Role is required.';
    }
    
    if (!$isEdit && empty($password)) {
        $errors[] = 'Password is required for new users.';
    }
    
    if ($password && strlen($password) < 8) {
        $errors[] = 'Password must be at least 8 characters.';
    }
    
    if ($password && $password !== $confirmPassword) {
        $errors[] = 'Passwords do not match.';
    }
    
    if ($user['phone'] && !isValidPhone($user['phone'])) {
        $errors[] = 'Invalid phone number format.';
    }
    
    // Save if no errors
    if (empty($errors)) {
        try {
            if ($isEdit) {
                if ($password) {
                    $stmt = $pdo->prepare("UPDATE users SET name = ?, email = ?, password_hash = ?, role = ?, phone = ?, department = ? WHERE id = ?");
                    $stmt->execute([
                        $user['name'],
                        $user['email'],
                        password_hash($password, PASSWORD_DEFAULT),
                        $user['role'],
                        $user['phone'],
                        $user['department'],
                        $user['id']
                    ]);
                } else {
                    $stmt = $pdo->prepare("UPDATE users SET name = ?, email = ?, role = ?, phone = ?, department = ? WHERE id = ?");
                    $stmt->execute([
                        $user['name'],
                        $user['email'],
                        $user['role'],
                        $user['phone'],
                        $user['department'],
                        $user['id']
                    ]);
                }
                setFlashMessage('success', 'User updated successfully.');
            } else {
                $stmt = $pdo->prepare("INSERT INTO users (name, email, password_hash, role, phone, department) VALUES (?, ?, ?, ?, ?, ?)");
                $stmt->execute([
                    $user['name'],
                    $user['email'],
                    password_hash($password, PASSWORD_DEFAULT),
                    $user['role'],
                    $user['phone'],
                    $user['department']
                ]);
                setFlashMessage('success', 'User created successfully.');
            }
            header('Location: users.php');
            exit;
        } catch (PDOException $e) {
            error_log("User save error: " . $e->getMessage());
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
                <div class="col-md-6 mb-3">
                    <label for="name" class="form-label">Full Name <span class="text-danger">*</span></label>
                    <input type="text" class="form-control" id="name" name="name" value="<?= htmlspecialchars($user['name']) ?>" required>
                </div>
                
                <div class="col-md-6 mb-3">
                    <label for="email" class="form-label">Email Address <span class="text-danger">*</span></label>
                    <input type="email" class="form-control" id="email" name="email" value="<?= htmlspecialchars($user['email']) ?>" required>
                </div>
            </div>
            
            <div class="row">
                <div class="col-md-6 mb-3">
                    <label for="password" class="form-label">
                        Password <?= $isEdit ? '' : '<span class="text-danger">*</span>' ?>
                    </label>
                    <input type="password" class="form-control" id="password" name="password" <?= $isEdit ? '' : 'required' ?>>
                    <?php if ($isEdit): ?>
                        <small class="text-muted">Leave blank to keep current password</small>
                    <?php endif; ?>
                </div>
                
                <div class="col-md-6 mb-3">
                    <label for="confirm_password" class="form-label">Confirm Password</label>
                    <input type="password" class="form-control" id="confirm_password" name="confirm_password">
                </div>
            </div>
            
            <div class="row">
                <div class="col-md-4 mb-3">
                    <label for="role" class="form-label">Role <span class="text-danger">*</span></label>
                    <select class="form-select" id="role" name="role" required>
                        <option value="">Select Role</option>
                        <option value="admin" <?= $user['role'] === 'admin' ? 'selected' : '' ?>>Administrator</option>
                        <option value="doctor" <?= $user['role'] === 'doctor' ? 'selected' : '' ?>>Doctor</option>
                        <option value="nurse" <?= $user['role'] === 'nurse' ? 'selected' : '' ?>>Nurse</option>
                        <option value="receptionist" <?= $user['role'] === 'receptionist' ? 'selected' : '' ?>>Receptionist</option>
                        <option value="lab" <?= $user['role'] === 'lab' ? 'selected' : '' ?>>Lab Technician</option>
                        <option value="pharmacist" <?= $user['role'] === 'pharmacist' ? 'selected' : '' ?>>Pharmacist</option>
                    </select>
                </div>
                
                <div class="col-md-4 mb-3">
                    <label for="department" class="form-label">Department</label>
                    <input type="text" class="form-control" id="department" name="department" value="<?= htmlspecialchars($user['department']) ?>">
                </div>
                
                <div class="col-md-4 mb-3">
                    <label for="phone" class="form-label">Phone Number</label>
                    <input type="tel" class="form-control" id="phone" name="phone" value="<?= htmlspecialchars($user['phone']) ?>">
                </div>
            </div>
            
            <div class="mt-4">
                <button type="submit" class="btn btn-primary">
                    <i class="fas fa-save me-2"></i><?= $isEdit ? 'Update' : 'Create' ?> User
                </button>
                <a href="users.php" class="btn btn-outline-secondary ms-2">
                    <i class="fas fa-times me-2"></i>Cancel
                </a>
            </div>
        </form>
    </div>
</div>

<?php include __DIR__ . '/../includes/footer.php'; ?>
