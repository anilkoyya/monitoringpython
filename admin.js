document.addEventListener('DOMContentLoaded', async () => {
    try {
        const response = await fetch('/api/encashments', {
            headers: { 'Authorization': `Bearer ${localStorage.getItem('token')}` }
        });
        const requests = await response.json();
        const tableBody = document.getElementById('requestsTable');

        requests.forEach(req => {
            const row = document.createElement('tr');
            row.innerHTML = `
                <td>${req.employeeId.name} (${req.employeeId.email})</td>
                <td>${req.leaveDays}</td>
                <td>${req.shares}</td>
                <td>
                    <button class="btn btn-success btn-sm" onclick="updateRequest('${req._id}', 'approved')">Approve</button>
                    <button class="btn btn-danger btn-sm" onclick="updateRequest('${req._id}', 'rejected')">Reject</button>
                </td>
            `;
            tableBody.appendChild(row);
        });
    } catch (error) {
        console.error('Error fetching requests:', error);
        alert('Please log in as admin.');
        window.location.href = '/login.html';
    }
});

async function updateRequest(id, status) {
    try {
        const response = await fetch(`/api/encashment/${id}`, {
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${localStorage.getItem('token')}`
            },
            body: JSON.stringify({ status })
        });
        const result = await response.json();
        if (response.ok) {
            alert(`Request ${status} successfully`);
            window.location.reload();
        } else {
            alert(result.message || 'Error updating request');
        }
    } catch (error) {
        console.error('Error updating request:', error);
        alert('An error occurred. Please try again.');
    }
}
