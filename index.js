const functions = require("firebase-functions");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");

admin.initializeApp();

// Replace with your email credentials
const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: "your-email@gmail.com", // Your email
    pass: "your-email-password-or-app-password", // Your app password (not your regular password)
  },
});

exports.sendReminderEmail = functions.firestore
  .document("donors_wisher/{docId}")
  .onCreate(async (snapshot, context) => {
    const data = snapshot.data();

    if (!data || !data.email || !data.name || !data.registrationDate) {
      console.error("Missing required fields in the document.");
      return null;
    }

    const recipientEmail = data.email;
    const recipientName = data.name;
    const registrationDate = new Date(data.registrationDate);
    const testDate = new Date(registrationDate);
    testDate.setDate(testDate.getDate() + 3);

    const emailSubject =
      "Reminder: Required Documents and Preparation for Blood Donation Test";
    const emailBody = `
      Dear ${recipientName},

      Thank you for your willingness to donate blood and help save lives! As part of the process, we request you to kindly bring the following documents with you:

      - Aadhar Card (or any valid government ID proof)
      - Blood Type Proof (if available)

      Additionally, we request you to come prepared for all the necessary tests to ensure you are eligible for blood donation.

      **Details of the Test:**
      - **Date:** ${testDate.toDateString()}
      - **Time:** Between 10:00 AM and 4:00 PM
      - **Location:** [Insert location details]

      Your commitment and generosity make a significant difference, and we truly appreciate your participation in this noble cause.

      If you have any questions or need further assistance, please do not hesitate to contact us at [Insert Contact Information].

      Looking forward to seeing you there!

      Warm regards,
      [Your Name]
      [Your Designation]
      [Your Organization]
      [Your Contact Information]
    `;

    try {
      await transporter.sendMail({
        from: '"Blood Quest" <your-email@gmail.com>',
        to: recipientEmail,
        subject: emailSubject,
        text: emailBody,
      });

      console.log(`Email sent to ${recipientEmail}`);
    } catch (error) {
      console.error("Error sending email:", error);
    }

    return null;
  });
