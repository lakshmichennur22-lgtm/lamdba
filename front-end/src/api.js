const API_URL = process.env.REACT_APP_API_BASE;

export async function getStudents() {
  const res = await fetch(`${API_URL}/students`);
  return res.json();
}

export async function addStudent(student) {
  const res = await fetch(`${API_URL}/students`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(student)
  });
  return res.json();
}
