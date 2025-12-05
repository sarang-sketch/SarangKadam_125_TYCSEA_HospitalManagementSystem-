<?php
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/auth_check.php';
require_once __DIR__ . '/../includes/functions.php';
requireRole(['admin', 'receptionist', 'doctor', 'nurse']);

$pdo = getConnection();
if (!isset($_GET['id'])) { header('Location: bills.php'); exit; }

$stmt = $pdo->prepare("SELECT b.*, p.name as patient_name, p.patient_code, p.phone, p.address FROM bills b JOIN patients p ON b.patient_id = p.id WHERE b.id = ?");
$stmt->execute([$_GET['id']]);
$bill = $stmt->fetch();
if (!$bill) { header('Location: bills.php'); exit; }

$stmt = $pdo->prepare("SELECT * FROM bill_items WHERE bill_id = ?");
$stmt->execute([$bill['id']]);
$items = $stmt->fetchAll();

$pageTitle = 'Invoice #' . $bill['id'];
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?= $pageTitle ?> - HMS</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
        @media print { .no-print { display: none !important; } }
        .invoice-header { border-bottom: 2px solid #0d6efd; padding-bottom: 20px; margin-bottom: 20px; }
    </style>
</head>
<body class="bg-light">
    <div class="container py-4">
        <div class="no-print mb-3">
            <button onclick="window.print()" class="btn btn-primary"><i class="fas fa-print me-2"></i>Print</button>
            <a href="bills.php" class="btn btn-outline-secondary">Back</a>
        </div>
        
        <div class="card">
            <div class="card-body p-5">
                <div class="invoice-header">
                    <div class="row">
                        <div class="col-6">
                            <h2 class="text-primary mb-0">Hospital Management System</h2>
                            <p class="text-muted mb-0">123 Medical Center Drive<br>City, State 12345<br>Phone: (123) 456-7890</p>
                        </div>
                        <div class="col-6 text-end">
                            <h3>INVOICE</h3>
                            <p class="mb-0"><strong>Invoice #:</strong> <?= $bill['id'] ?><br>
                            <strong>Date:</strong> <?= formatDate($bill['created_at']) ?><br>
                            <strong>Status:</strong> <span class="badge bg-<?= getStatusBadge($bill['status']) ?>"><?= ucfirst($bill['status']) ?></span></p>
                        </div>
                    </div>
                </div>
                
                <div class="row mb-4">
                    <div class="col-6">
                        <h5>Bill To:</h5>
                        <p class="mb-0">
                            <strong><?= htmlspecialchars($bill['patient_name']) ?></strong><br>
                            Patient ID: <?= htmlspecialchars($bill['patient_code']) ?><br>
                            <?php if ($bill['phone']): ?>Phone: <?= htmlspecialchars($bill['phone']) ?><br><?php endif; ?>
                            <?php if ($bill['address']): ?><?= htmlspecialchars($bill['address']) ?><?php endif; ?>
                        </p>
                    </div>
                </div>
                
                <table class="table table-bordered">
                    <thead class="table-light">
                        <tr>
                            <th>#</th>
                            <th>Description</th>
                            <th class="text-end">Amount</th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php foreach ($items as $i => $item): ?>
                            <tr>
                                <td><?= $i + 1 ?></td>
                                <td><?= htmlspecialchars($item['description']) ?></td>
                                <td class="text-end"><?= formatCurrency($item['amount']) ?></td>
                            </tr>
                        <?php endforeach; ?>
                    </tbody>
                    <tfoot>
                        <tr>
                            <td colspan="2" class="text-end"><strong>Subtotal:</strong></td>
                            <td class="text-end"><?= formatCurrency($bill['total_amount']) ?></td>
                        </tr>
                        <tr>
                            <td colspan="2" class="text-end"><strong>Tax:</strong></td>
                            <td class="text-end"><?= formatCurrency($bill['tax_amount']) ?></td>
                        </tr>
                        <tr class="table-primary">
                            <td colspan="2" class="text-end"><strong>Total:</strong></td>
                            <td class="text-end"><strong><?= formatCurrency($bill['total_amount'] + $bill['tax_amount']) ?></strong></td>
                        </tr>
                    </tfoot>
                </table>
                
                <div class="mt-5 pt-4 border-top">
                    <div class="row">
                        <div class="col-6">
                            <p class="text-muted small">Thank you for choosing our hospital.</p>
                        </div>
                        <div class="col-6 text-end">
                            <p class="text-muted small">Generated on <?= date('d M Y H:i') ?></p>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.2/css/all.min.css" rel="stylesheet">
</body>
</html>
