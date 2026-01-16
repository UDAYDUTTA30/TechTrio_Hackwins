# Panchakarma Management Software 🩺🌿

## Overview
Panchakarma is a core Ayurvedic therapy system focused on detoxification, rejuvenation, and chronic disease management. Despite its growing global adoption, most Panchakarma centers still rely on manual scheduling, paper-based records, and verbal patient instructions, leading to inefficiencies and inconsistent care.

The **Panchakarma Management Software** is a cloud-based, patient-centric platform that digitizes therapy scheduling, patient communication, progress tracking, and feedback analysis while preserving traditional Panchakarma authenticity.

---

## Problem Statement
The lack of dedicated digital management systems in Panchakarma centers results in:
- Inefficient manual scheduling and documentation  
- Inconsistent therapy quality across centers  
- Limited patient engagement and follow-up  
- No structured tracking of therapy outcomes  

This project aims to bridge the gap using modern cloud and AI technologies.

---

## Objectives
- Automate Panchakarma therapy scheduling
- Provide pre- and post-procedure notifications
- Enable real-time therapy progress tracking
- Collect and analyze patient feedback
- Improve operational efficiency and patient trust

---

## Key Features

### 1. Automated Therapy Scheduling
- Role-based scheduling for doctors, therapists, and patients
- Session creation, modification, and rescheduling
- Calendar and list-based session views

### 2. Pre & Post Procedure Notifications
- Automated reminders and precaution alerts
- Multiple channels: in-app, push notifications, email
- Therapy-specific customized messages

### 3. Real-Time Therapy Tracking
- Session status updates (scheduled / completed)
- Patient recovery milestones
- Practitioner overview dashboard

### 4. Patient Feedback & Monitoring
- Post-session feedback forms
- Symptom reporting and improvement rating
- Continuous refinement of therapy plans

### 5. AI-Assisted Insights
- Sentiment and trend analysis of patient feedback
- Early detection of negative recovery patterns
- Support for practitioner decision-making

---

## System Architecture (High Level)

Frontend (Flutter App)  
→ Firebase Authentication  
→ Firestore Database  
→ Cloud Functions (Business Logic & Automation)  
→ Google AI APIs (Feedback Analysis)  

---

## Tech Stack

### Frontend
- **Flutter** – Android 

### Backend & Cloud
- **Firebase Authentication** – Secure user login and role management
- **Cloud Firestore** – Real-time NoSQL database
- **Cloud Functions** – Serverless backend logic
- **Firebase Cloud Messaging (FCM)** – Notifications and alerts

### AI 
- Google Gemini API– Feedback analysis and insights

