// frontend/src/pages/LoginPage.jsx
import React from "react";
import Login from "../components/Login";

function LoginPage() {
  return (
    <div className="app">
      <div className="main-container">
        <div className="card">
          <h2>로그인</h2>
          <Login />
        </div>
      </div>
    </div>
  );
}

export default LoginPage;
