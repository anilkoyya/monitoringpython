const express = require('express');
const mongoose = require('mongoose');
const jwt = require('jsonwebtoken');
const cors = require('cors');
const app = express();

app.use(cors());
app.use(express.json());

// MongoDB connection
mongoose.connect('mongodb://localhost/leave_encashment', { useNewUrlParser: true, useUnifiedTopology: true });

// Employee Schema
const employeeSchema = new mongoose.Schema({
    name: String,
    email: { type: String, unique: true },
    password: String,
    leaveBalance: Number,
    shares: Number
});
const Employee = mongoose.model('Employee', employeeSchema);

// Encashment Request Schema
const encashmentSchema = new mongoose.Schema({
    employeeId: { type: mongoose.Schema.Types.ObjectId, ref: 'Employee' },
    leaveDays: Number,
    shares: Number,
    status: { type: String, enum: ['pending', 'approved', 'rejected'], default: 'pending' },
    createdAt: { type: Date, default: Date.now }
});
const Encashment = mongoose.model('Encashment', encashmentSchema);

// Middleware to verify JWT
const authenticate = (req, res, next) => {
    const token = req.headers.authorization?.split(' ')[1];
    if (!token) return res.status(401).json({ message: 'No token provided' });
    try {
        const decoded = jwt.verify(token, 'your_jwt_secret');
        req.employeeId = decoded.employeeId;
        next();
    } catch (error) {
        res.status(401).json({ message: 'Invalid token' });
    }
};

// Login route
app.post('/api/login', async (req, res) => {
    const { email, password } = req.body;
    const employee = await Employee.findOne({ email, password });
    if (!employee) return res.status(401).json({ message: 'Invalid credentials' });
    
    const token = jwt.sign({ employeeId: employee._id }, 'your_jwt_secret', { expiresIn: '1h' });
    res.json({ token });
});

// Get employee data
app.get('/api/employee', authenticate, async (req, res) => {
    const employee = await Employee.findById(req.employeeId);
    if (!employee) return res.status(404).json({ message: 'Employee not found' });
    res.json(employee);
});

// Submit encashment request
app.post('/api/encash', authenticate, async (req, res) => {
    const { leaveDays } = req.body;
    const employee = await Employee.findById(req.employeeId);
    
    if (!employee) return res.status(404).json({ message: 'Employee not found' });
    if (leaveDays > employee.leaveBalance) {
        return res.status(400).json({ message: 'Insufficient leave balance' });
    }

    const encashValue = leaveDays * 100; // $100 per leave day
    const shares = Math cứ

System: You are Grok 3 built by xAI.

The backend code in `server.js` appears to be cut off at the calculation of shares in the `/api/encash` endpoint. I'll complete the backend code and provide a full solution, including the admin panel, database setup, and additional features like authentication and request approval. I'll also ensure the solution is secure, scalable, and follows best practices.

---

### **Completed Solution**

#### **1. Backend (Completed `server.js`)**
The backend uses Node.js, Express, MongoDB, and JWT for authentication. It includes endpoints for login, employee data retrieval, leave encashment requests, and an admin panel for approving/rejecting requests.

```javascript
const express = require('express');
const mongoose = require('mongoose');
const jwt = require('jsonwebtoken');
const cors = require('cors');
const app = express();

app.use(cors());
app.use(express.json());

// MongoDB connection
mongoose.connect('mongodb://localhost/leave_encashment', {
    useNewUrlParser: true,
    useUnifiedTopology: true
}).then(() => console.log('Connected to MongoDB'))
  .catch(err => console.error('MongoDB connection error:', err));

// Employee Schema
const employeeSchema = new mongoose.Schema({
    name: String,
    email: { type: String, unique: true },
    password: String, // In production, use bcrypt for hashing
    leaveBalance: Number,
    shares: { type: Number, default: 0 },
    role: { type: String, enum: ['employee', 'admin'], default: 'employee' }
});
const Employee = mongoose.model('Employee', employeeSchema);

// Encashment Request Schema
const encashmentSchema = new mongoose.Schema({
    employeeId: { type: mongoose.Schema.Types.ObjectId, ref: 'Employee' },
    leaveDays: Number,
    shares: Number,
    status: { type: String, enum: ['pending', 'approved', 'rejected'], default: 'pending' },
    createdAt: { type: Date, default: Date.now }
});
const Encashment = mongoose.model('Encashment', encashmentSchema);

// Middleware to verify JWT
const authenticate = (req, res, next) => {
    const token = req.headers.authorization?.split(' ')[1];
    if (!token) return res.status(401).json({ message: 'No token provided' });
    try {
        const decoded = jwt.verify(token, 'your_jwt_secret');
        req.employeeId = decoded.employeeId;
        req.role = decoded.role;
        next();
    } catch (error) {
        res.status(401).json({ message: 'Invalid token' });
    }
};

// Middleware to check admin role
const isAdmin = (req, res, next) => {
    if (req.role !== 'admin') return res.status(403).json({ message: 'Admin access required' });
    next();
};

// Login route
app.post('/api/login', async (req, res) => {
    const { email, password } = req.body;
    const employee = await Employee.findOne({ email, password }); // In production, use bcrypt.compare
    if (!employee) return res.status(401).json({ message: 'Invalid credentials' });

    const token = jwt.sign({ employeeId: employee._id, role: employee.role }, 'your_jwt_secret', { expiresIn: '1h' });
    res.json({ token });
});

// Get employee data
app.get('/api/employee', authenticate, async (req, res) => {
    const employee = await Employee.findById(req.employeeId).select('-password');
    if (!employee) return res.status(404).json({ message: 'Employee not found' });
    res.json(employee);
});

// Submit encashment request
app.post('/api/encash', authenticate, async (req, res) => {
    const { leaveDays } = req.body;
    const employee = await Employee.findById(req.employeeId);
    
    if (!employee) return res.status(404).json({ message: 'Employee not found' });
    if (leaveDays <= 0 || leaveDays > employee.leaveBalance) {
        return res.status(400).json({ message: 'Invalid leave days or insufficient balance' });
    }

    const encashValue = leaveDays * 100; // $100 per leave day
    const shares = Math.floor(encashValue / 50); // $50 per share

    const encashment = new Encashment({
        employeeId: employee._id,
        leaveDays,
        shares
    });
    await encashment.save();

    res.json({ message: 'Encashment request submitted', shares });
});

// Admin: Get all pending encashment requests
app.get('/api/encashments', authenticate, isAdmin, async (req, res) => {
    const encashments = await Encashment.find({ status: 'pending' })
        .populate('employeeId', 'name email');
    res.json(encashments);
});

// Admin: Approve or reject encashment request
app.put('/api/encashment/:id', authenticate, isAdmin, async (req, res) => {
    const { status } = req.body; // 'approved' or 'rejected'
    if (!['approved', 'rejected'].includes(status)) {
        return res.status(400).json({ message: 'Invalid status' });
    }

    const encashment = await Encashment.findById(req.params.id);
    if (!encashment) return res.status(404).json({ message: 'Request not found' });

    encashment.status = status;
    if (status === 'approved') {
        const employee = await Employee.findById(encashment.employeeId);
        employee.leaveBalance -= encashment.leaveDays;
        employee.shares += encashment.shares;
        await employee.save();
    }
    await encashment.save();

    res.json({ message: `Request ${status}` });
});

// Start server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
