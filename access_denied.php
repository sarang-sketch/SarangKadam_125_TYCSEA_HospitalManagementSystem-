<?php
/**
 * Access Denied Page
 * Hospital Management System
 */

require_once __DIR__ . '/includes/auth_check.php';
$pageTitle = 'Access Denied';
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?= $pageTitle ?> - HMS</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.2/css/all.min.css" rel="stylesheet">
    <link href="/hospital_management/assets/css/style.css" rel="stylesheet">
</head>
<body class="login-page">
    <div class="login-card text-center">
        <div class="mb-4">
            <i class="fas fa-exclamation-triangle text-danger" style="font-size: 5rem;"></i>
        </div>
        <h2 class="text-danger mb-3">Access Denied</h2>
        <p class="text-muted mb-4">
            You do not have permission to access this page. 
            Please contact your administrator if you believe this is an error.
        </p>
        <div class="d-grid gap-2">
            <a href="<?= getDashboardUrl() ?>" class="btn btn-primary">
                <i class="fas fa-home me-2"></i>Go to Dashboard
            </a>
            <a href="/hospital_management/auth/logout.php" class="btn btn-outline-secondary">
                <i class="fas fa-sign-out-alt me-2"></i>Logout
            </a>
        </div>
    </div>
    
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
