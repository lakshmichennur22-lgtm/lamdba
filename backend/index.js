const mysql = require("mysql2/promise");

const dbConfig = {
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME
};

exports.handler = async (event) => {
  const connection = await mysql.createConnection(dbConfig);

  try {
    // Create table if not exists
    await connection.execute(`
      CREATE TABLE IF NOT EXISTS students (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(100),
        email VARCHAR(100)
      )
    `);

    if (event.httpMethod === "GET") {
      const [rows] = await connection.execute("SELECT * FROM students");
      return response(200, rows);
    }

    if (event.httpMethod === "POST") {
      const body = JSON.parse(event.body);
      await connection.execute(
        "INSERT INTO students (name, email) VALUES (?, ?)",
        [body.name, body.email]
      );
      return response(200, { message: "Student added" });
    }

    return response(400, { message: "Invalid request" });

  } catch (err) {
    console.error(err);
    return response(500, { error: err.message });
  } finally {
    await connection.end();
  }
};

function response(statusCode, body) {
  return {
    statusCode,
    headers: {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Headers": "Content-Type",
      "Access-Control-Allow-Methods": "GET,POST,OPTIONS"
    },
    body: JSON.stringify(body)
  };
}