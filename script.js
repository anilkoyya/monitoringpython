document.addEventListener('DOMContentLoaded', async () => {
    // Fetch employee data
    try {
        const response = await fetch('/api/employee', {
            headers: { 'Authorization': `Bearer ${localStorage.getItem('token')}` }
        });
        const employee = await response.json();
        document.getElementById('employeeName').textContent = employee.name;
        document.getElementById('leaveBalance').textContent = employee.leaveBalance;
    } catch (error) {
        console.error('Error fetching employee data:', error);
        alert('Please log in again.');
        window.location.href = '/login.html';
    }

    // Calculate estimated shares
    const leaveDaysInput = document.getElementById('leaveDays');
    const estimatedSharesSpan = document.getElementById('estimatedShares');
    leaveDaysInput.addEventListener('input', () => {
        const leaveDays = parseInt(leaveDaysInput.value) || 0;
        const encashValue = leaveDays * 100; // $100 per leave day
        const shares = Math.floor(encashValue / 50); // $50 per share
        estimatedSharesSpan.textContent = shares;
    });

    // Handle form submission
    document.getElementById('encashForm').addEventListener('submit', async (e) => {
        e.preventDefault();
        const leaveDays = parseInt(leaveDaysInput.value);
        if (leaveDays <= 0) {
            alert('Please enter a valid number of leave days.');
            return;
        }

        try {
            const response = await fetch('/api/encash', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${localStorage.getItem('token')}`
                },
                body: JSON.stringify({ leaveDays })
            });
            const result = await response.json();
            if (response.ok) {
                alert(`Request submitted! You will receive ${result.shares} shares upon approval.`);
                window.location.reload();
            } else {
                alert(result.message || 'Error submitting request.');
            }
        } catch (error) {
            console.error('Error submitting encashment request:', error);
            alert('An error occurred. Please try again.');
        }
    });
});
