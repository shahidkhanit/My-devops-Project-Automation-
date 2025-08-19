import React, { useState, useEffect } from 'react';
import axios from 'axios';
import './App.css';

function App() {
  const [users, setUsers] = useState([]);
  const [metrics, setMetrics] = useState({});
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchUsers();
    fetchMetrics();
  }, []);

  const fetchUsers = async () => {
    try {
      const response = await axios.get('/api/users');
      setUsers(response.data);
    } catch (error) {
      console.error('Error fetching users:', error);
    }
  };

  const fetchMetrics = async () => {
    try {
      const response = await axios.get('/api/metrics');
      setMetrics(response.data);
      setLoading(false);
    } catch (error) {
      console.error('Error fetching metrics:', error);
      setLoading(false);
    }
  };

  return (
    <div className="App">
      <header className="App-header">
        <h1>Monitoring Dashboard</h1>
        
        {loading ? (
          <p>Loading...</p>
        ) : (
          <div>
            <div className="metrics-section">
              <h2>System Metrics</h2>
              <div className="metrics-grid">
                <div className="metric-card">
                  <h3>Active Users</h3>
                  <p>{metrics.activeUsers || 0}</p>
                </div>
                <div className="metric-card">
                  <h3>Response Time</h3>
                  <p>{metrics.responseTime || 0}ms</p>
                </div>
                <div className="metric-card">
                  <h3>Cache Hit Rate</h3>
                  <p>{metrics.cacheHitRate || 0}%</p>
                </div>
              </div>
            </div>

            <div className="users-section">
              <h2>Users ({users.length})</h2>
              <div className="users-list">
                {users.map(user => (
                  <div key={user.id} className="user-card">
                    <h4>{user.name}</h4>
                    <p>{user.email}</p>
                  </div>
                ))}
              </div>
            </div>
          </div>
        )}
      </header>
    </div>
  );
}

export default App;