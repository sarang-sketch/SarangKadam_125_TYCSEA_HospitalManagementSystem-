/**
 * Hospital Management System - Main JavaScript
 */

document.addEventListener('DOMContentLoaded', function() {
    // Initialize tooltips
    var tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
    tooltipTriggerList.map(function(tooltipTriggerEl) {
        return new bootstrap.Tooltip(tooltipTriggerEl);
    });

    // Initialize popovers
    var popoverTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="popover"]'));
    popoverTriggerList.map(function(popoverTriggerEl) {
        return new bootstrap.Popover(popoverTriggerEl);
    });

    // Auto-hide alerts after 5 seconds
    var alerts = document.querySelectorAll('.alert-dismissible');
    alerts.forEach(function(alert) {
        setTimeout(function() {
            var bsAlert = new bootstrap.Alert(alert);
            bsAlert.close();
        }, 5000);
    });

    // Confirm delete actions
    document.querySelectorAll('.btn-delete, .delete-confirm').forEach(function(btn) {
        btn.addEventListener('click', function(e) {
            if (!confirm('Are you sure you want to delete this item?')) {
                e.preventDefault();
            }
        });
    });

    // Form validation
    var forms = document.querySelectorAll('.needs-validation');
    forms.forEach(function(form) {
        form.addEventListener('submit', function(event) {
            if (!form.checkValidity()) {
                event.preventDefault();
                event.stopPropagation();
            }
            form.classList.add('was-validated');
        });
    });

    // Dynamic medicine items for prescriptions
    var addMedicineBtn = document.getElementById('addMedicine');
    if (addMedicineBtn) {
        addMedicineBtn.addEventListener('click', function() {
            var container = document.getElementById('medicineItems');
            var index = container.children.length;
            var template = `
                <div class="row mb-3 medicine-item">
                    <div class="col-md-3">
                        <input type="text" class="form-control" name="medicines[${index}][name]" placeholder="Medicine Name" required>
                    </div>
                    <div class="col-md-2">
                        <input type="text" class="form-control" name="medicines[${index}][dosage]" placeholder="Dosage">
                    </div>
                    <div class="col-md-2">
                        <input type="text" class="form-control" name="medicines[${index}][frequency]" placeholder="Frequency">
                    </div>
                    <div class="col-md-2">
                        <input type="text" class="form-control" name="medicines[${index}][duration]" placeholder="Duration">
                    </div>
                    <div class="col-md-3">
                        <button type="button" class="btn btn-danger btn-sm remove-medicine">
                            <i class="fas fa-trash"></i> Remove
                        </button>
                    </div>
                </div>
            `;
            container.insertAdjacentHTML('beforeend', template);
        });

        // Remove medicine item
        document.addEventListener('click', function(e) {
            if (e.target.classList.contains('remove-medicine') || e.target.closest('.remove-medicine')) {
                var item = e.target.closest('.medicine-item');
                if (item) item.remove();
            }
        });
    }

    // Dynamic bill items
    var addBillItemBtn = document.getElementById('addBillItem');
    if (addBillItemBtn) {
        addBillItemBtn.addEventListener('click', function() {
            var container = document.getElementById('billItems');
            var index = container.children.length;
            var template = `
                <div class="row mb-3 bill-item">
                    <div class="col-md-8">
                        <input type="text" class="form-control" name="items[${index}][description]" placeholder="Description" required>
                    </div>
                    <div class="col-md-3">
                        <input type="number" step="0.01" class="form-control item-amount" name="items[${index}][amount]" placeholder="Amount" required>
                    </div>
                    <div class="col-md-1">
                        <button type="button" class="btn btn-danger btn-sm remove-bill-item">
                            <i class="fas fa-trash"></i>
                        </button>
                    </div>
                </div>
            `;
            container.insertAdjacentHTML('beforeend', template);
            updateBillTotal();
        });

        // Remove bill item
        document.addEventListener('click', function(e) {
            if (e.target.classList.contains('remove-bill-item') || e.target.closest('.remove-bill-item')) {
                var item = e.target.closest('.bill-item');
                if (item) {
                    item.remove();
                    updateBillTotal();
                }
            }
        });

        // Update total on amount change
        document.addEventListener('input', function(e) {
            if (e.target.classList.contains('item-amount')) {
                updateBillTotal();
            }
        });
    }

    // Calculate bill total
    function updateBillTotal() {
        var amounts = document.querySelectorAll('.item-amount');
        var subtotal = 0;
        amounts.forEach(function(input) {
            subtotal += parseFloat(input.value) || 0;
        });
        
        var taxRate = parseFloat(document.getElementById('taxRate')?.value) || 5;
        var tax = subtotal * (taxRate / 100);
        var total = subtotal + tax;
        
        var subtotalEl = document.getElementById('subtotal');
        var taxEl = document.getElementById('taxAmount');
        var totalEl = document.getElementById('totalAmount');
        
        if (subtotalEl) subtotalEl.textContent = '$' + subtotal.toFixed(2);
        if (taxEl) taxEl.textContent = '$' + tax.toFixed(2);
        if (totalEl) totalEl.textContent = '$' + total.toFixed(2);
    }

    // Print functionality
    document.querySelectorAll('.btn-print').forEach(function(btn) {
        btn.addEventListener('click', function() {
            window.print();
        });
    });

    // Search filter for tables
    var searchInput = document.getElementById('tableSearch');
    if (searchInput) {
        searchInput.addEventListener('keyup', function() {
            var filter = this.value.toLowerCase();
            var table = document.querySelector('.table tbody');
            var rows = table.querySelectorAll('tr');
            
            rows.forEach(function(row) {
                var text = row.textContent.toLowerCase();
                row.style.display = text.includes(filter) ? '' : 'none';
            });
        });
    }

    // Date picker defaults
    var dateInputs = document.querySelectorAll('input[type="date"]');
    dateInputs.forEach(function(input) {
        if (!input.value && input.dataset.default === 'today') {
            input.value = new Date().toISOString().split('T')[0];
        }
    });

    // Load doctors by department
    var departmentSelect = document.getElementById('department');
    if (departmentSelect) {
        departmentSelect.addEventListener('change', function() {
            var department = this.value;
            var doctorSelect = document.getElementById('doctor_id');
            
            if (doctorSelect && department) {
                fetch('/hospital_management/api/doctors.php?department=' + encodeURIComponent(department))
                    .then(response => response.json())
                    .then(data => {
                        doctorSelect.innerHTML = '<option value="">Select Doctor</option>';
                        data.forEach(function(doctor) {
                            doctorSelect.innerHTML += `<option value="${doctor.id}">${doctor.name}</option>`;
                        });
                    })
                    .catch(error => console.error('Error:', error));
            }
        });
    }
});
