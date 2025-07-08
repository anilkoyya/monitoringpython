// src/components/Dashboard.js
import React, { useState, useEffect } from 'react';
import axios from 'axios';
import './Dashboard.css';

const Dashboard = ({ user }) => {
  const [leaveBalance, setLeaveBalance] = useState(0);
  const [sharePrice, setSharePrice] = useState(0);
  const [leavesToEncash, setLeavesToEncash] = useState(0);
  const [error, setError] = useState('');

  useEffect(() => {
    // Fetch leave balance and share price from backend
    axios.get('/api/employee/leave-balance', { headers: { Authorization: `Bearer ${user.token}` } })
      .then(res => setLeaveBalance(res.data.balance))
      .catch(err => setError('Failed to fetch leave balance'));
    axios.get('/api/shares/price')
      .then(res => setSharePrice(res.data.price))
      .catch(err => setError('Failed to fetch share price'));
  }, [user.token]);

  const handleEncash = () => {
    if (leavesToEncash <= 0 || leavesToEncash > leaveBalance) {
      setError('Invalid leave amount');
      return;
    }
    axios.post('/api/encash', { leaves: leavesToEncash }, { headers: { Authorization: `Bearer ${user.token}` } })
      .then(res => alert('Encashment request submitted!'))
      .catch(err => setError('Encashment failed'));
  };

  return (
    <div className="dashboard">
      <h2>Welcome, {user.name}</h2>
      <div>
        <p>Available Leave Balance: {leaveBalance} days</p>
        <p>Current Share Price: ${sharePrice}</p>
        <p>Estimated Shares: {(leavesToEncash * sharePrice).toFixed(2)}</p>
        <input
          type="number"
          value={leavesToEncash}
          onChange={(e) => setLeavesToEncash(e.target.value)}
          placeholder="Enter leaves to encash"
        />
        <button onClick={handleEncash}>Encash Leaves</button>
        {error && <p className="error">{error}</p>}
      </div>
    </div>
  );
};

export default Dashboard;
