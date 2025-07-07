// Run this script once to seed the database
const mongoose = require('mongoose');
mongoose.connect('mongodb://localhost/leave_encashment', { useNewUrlParser: true, useUnifiedTopology: true });

const Employee = mongoose.model('Employee', new mongoose.Schema({
    name: String,
    email: { type: String, unique: true },
    password: String,
    leaveBalance: Number,
    shares: Number,
    role: String
}));

async function seed() {
    await Employee.deleteMany({});
    await Employee.insertMany([
        { name: 'John Doe', email: 'john@example.com', password: 'password123', leaveBalance: 20, shares: 0, role: 'employee' },
        { name: 'Admin User', email: 'admin@example.com', password: 'admin123', leaveBalance: 0, shares: 0, role: 'admin' }
    ]);
    console.log('Database seeded');
    mongoose.connection.close();
}
seed();
