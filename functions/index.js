const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp(); // Initialize Firebase Admin
const db = admin.firestore();

// Cloud Function to add a book
exports.addBook = functions.https.onCall(async (data, context) => {
  try {
    // Extract book data from client
    const { title, author, year } = data;

    // Validate required fields
    if (!title || !author || !year) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Missing title, author, or year"
      );
    }

    // Add book to Firestore
    const docRef = await db.collection("books").add({
      title,
      author,
      year,
      timestamp: admin.firestore.FieldValue.serverTimestamp()
    });

    // Return success message
    return {
      message: `Book '${title}' added successfully`,
      id: docRef.id
    };

  } catch (error) {
    console.error("Error adding book:", error);
    throw new functions.https.HttpsError("internal", error.message);
  }
});
exports.sendSecurityPin = functions.https.onCall(async (data, context) => {
  const admin = require("firebase-admin");
  const nodemailer = require("nodemailer");

  // Email + PIN from Flutter
  const email = data.email;
  const pin = data.pin;

  if (!email || !pin) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Email or PIN missing."
    );
  }

  // Gmail SMTP Transporter
  const transporter = nodemailer.createTransport({
    service: "gmail",
    auth: {
      user: "pt9413387@gmail.com",       // PUT YOUR EMAIL
      pass: "your-app-password",         // APP PASSWORD, not normal password
    },
  });

  try {
    await transporter.sendMail({
      from: "KitabCorner Admin <yourgmail@gmail.com>",
      to: email,
      subject: "Your Admin Security PIN",
      text: `Your Admin PIN is: ${pin}`,
      html: `
        <h2>KitabCorner Admin Access</h2>
        <p>Your security PIN is:</p>
        <h1>${pin}</h1>
        <p>Use this PIN to log into the Admin Panel.</p>
      `,
    });

    return { success: true };
  } catch (error) {
    console.error("Email error:", error);
    throw new functions.https.HttpsError("internal", "Failed to send email");
  }
});
