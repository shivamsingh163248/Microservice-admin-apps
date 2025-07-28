// Determine the backend URL based on environment
// When running in Docker, frontend and backend communicate through Docker network
// When accessed from browser, use the exposed port
const API_BASE_URL = window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1' ? 
    'http://localhost:5000' : 
    `http://${window.location.hostname}:5000`;

// Helper function to get auth headers
function getAuthHeaders() {
    const token = localStorage.getItem('authToken');
    return token ? { 'Authorization': `Bearer ${token}` } : {};
}

// Helper function to handle API calls with authentication
async function authenticatedFetch(url, options = {}) {
    const headers = {
        'Content-Type': 'application/json',
        ...getAuthHeaders(),
        ...options.headers
    };
    
    const response = await fetch(url, { ...options, headers });
    
    if (response.status === 401) {
        // Token expired or invalid
        localStorage.removeItem('authToken');
        localStorage.removeItem('username');
        localStorage.removeItem('userType');
        window.location.href = 'index.html';
        return null;
    }
    
    return response;
}

// User login
document.getElementById('userLoginForm')?.addEventListener('submit', async (e) => {
    e.preventDefault();
    const username = document.getElementById("userUsername").value;
    const password = document.getElementById("userPassword").value;
    
    try {
        const res = await fetch(`${API_BASE_URL}/login`, {
            method: "POST",
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify({username, password})
        });
        const data = await res.json();
        
        if (res.ok) {
            // Store authentication data
            localStorage.setItem("authToken", data.token);
            localStorage.setItem("username", data.username);
            localStorage.setItem("userType", "user");
            alert(data.message);
            // Redirect to user dashboard
            window.location.href = "user-dashboard.html";
        } else {
            alert(data.message);
        }
    } catch (error) {
        alert("Error connecting to server. Please try again.");
        console.error('Login error:', error);
    }
});

// Admin login
document.getElementById('adminLoginForm')?.addEventListener('submit', async (e) => {
    e.preventDefault();
    const username = document.getElementById("adminUser").value;
    const password = document.getElementById("adminPass").value;
    
    try {
        const res = await fetch(`${API_BASE_URL}/admin-login`, {
            method: "POST",
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify({username, password})
        });
        const data = await res.json();
        
        if (res.ok) {
            // Store admin authentication data
            localStorage.setItem("authToken", data.token);
            localStorage.setItem("username", data.username);
            localStorage.setItem("userType", "admin");
            window.location.href = "admin.html";
        } else {
            alert(data.message);
        }
    } catch (error) {
        alert("Error connecting to server. Please try again.");
        console.error('Admin login error:', error);
    }
});

// User registration
document.getElementById('registerForm')?.addEventListener('submit', async (e) => {
    e.preventDefault();
    const username = document.getElementById("regUser").value;
    const password = document.getElementById("regPass").value;
    
    if (!username || !password) {
        alert("Please fill in all fields");
        return;
    }
    
    try {
        const res = await fetch(`${API_BASE_URL}/register`, {
            method: "POST",
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify({username, password})
        });
        const data = await res.json();
        
        alert(data.message);
        
        if (res.ok) {
            // Clear form on successful registration
            document.getElementById("regUser").value = '';
            document.getElementById("regPass").value = '';
            // Optionally redirect to login
            setTimeout(() => {
                window.location.href = "index.html";
            }, 1500);
        }
    } catch (error) {
        alert("Error connecting to server. Please try again.");
        console.error('Registration error:', error);
    }
});

// Global logout function
async function logout() {
    const token = localStorage.getItem('authToken');
    if (token) {
        try {
            await fetch(`${API_BASE_URL}/logout`, {
                method: 'POST',
                headers: {
                    'Authorization': `Bearer ${token}`,
                    'Content-Type': 'application/json'
                }
            });
        } catch (error) {
            console.error('Logout error:', error);
        }
    }
    
    // Clear all authentication data
    localStorage.removeItem('authToken');
    localStorage.removeItem('username');
    localStorage.removeItem('userType');
    alert('Logged out successfully');
    window.location.href = 'index.html';
}

// Session verification function
async function verifySession() {
    const token = localStorage.getItem('authToken');
    if (!token) {
        return false;
    }
    
    try {
        const response = await fetch(`${API_BASE_URL}/verify-session`, {
            headers: {
                'Authorization': `Bearer ${token}`
            }
        });
        
        if (response.ok) {
            const data = await response.json();
            return data.valid;
        } else {
            localStorage.removeItem('authToken');
            localStorage.removeItem('username');
            localStorage.removeItem('userType');
            return false;
        }
    } catch (error) {
        console.error('Session verification error:', error);
        return false;
    }
}
