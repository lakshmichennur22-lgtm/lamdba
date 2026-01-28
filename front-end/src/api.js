const API_URL = process.env.REACT_APP_API_BASE;

console.log("API_URL =", API_URL);   // 👈 PASTE HERE

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