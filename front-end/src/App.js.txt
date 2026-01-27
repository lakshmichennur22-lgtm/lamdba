import React, { useEffect, useState } from "react";
import { getStudents, addStudent } from "./api";

function App() {
  const [students, setStudents] = useState([]);
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");

  useEffect(() => {
    loadStudents();
  }, []);

  async function loadStudents() {
    const data = await getStudents();
    setStudents(data);
  }

  async function handleSubmit(e) {
    e.preventDefault();
    await addStudent({ name, email });
    setName("");
    setEmail("");
    loadStudents();
  }

  return (
    <div style={{ padding: "40px" }}>
      <h2>Student Management</h2>

      <form onSubmit={handleSubmit}>
        <input
          placeholder="Name"
          value={name}
          onChange={e => setName(e.target.value)}
          required
        />
        <input
          placeholder="Email"
          value={email}
          onChange={e => setEmail(e.target.value)}
          required
        />
        <button>Add</button>
      </form>

      <ul>
        {students.map(s => (
          <li key={s.id}>{s.name} - {s.email}</li>
        ))}
      </ul>
    </div>
  );
}

export default App;
