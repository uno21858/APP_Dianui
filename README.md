# DIANUI App

A mobile nutrition and wellness application developed with Flutter.

---

## 📋 Overview

**DIANUI App** is a comprehensive mobile solution designed to improve users' quality of life by promoting healthy habits, providing access to wellness resources, and enabling direct connection with nutrition professionals. The app is developed as part of a social service project in collaboration with **Fundación DIANUI A.C.**, aiming to positively impact community health through an intuitive, gamified, and evidence-based experience.

---

## 🚀 Key Features

- **Personalized Nutrition Tracking:**  
  Register and monitor nutritional progress, weight, daily habits, and health goals.

- **Healthy Recipes:**  
  Catalog of personalized recipes, with the ability to add, edit, and view healthy recipes, including images, ingredients, and detailed steps.

- **Nutritionist Consultations:**  
  Appointment scheduling, professional nutritionist profiles, availability, and direct contact for personalized consultations.

- **Wellness Blog:**  
  Articles and tips on health, nutrition, and wellness, written by experts and the community.

- **Tips & Advice:**  
  Space to share and discover practical tips for a healthy lifestyle.

- **Emergency Mode:**  
  Quick access to information and useful resources in urgent medical situations.

- **Gamification:**  
  21-day challenges and rewards to motivate the adoption of healthy habits.

---

## 🛠️ Technologies & Architecture

- **Flutter & Dart:**  
  Cross-platform development (Android, iOS, Web, Desktop) with a single codebase.
- **Firebase:**  
  - User authentication (Email/Google)
  - Firestore as a real-time database
  - Image and file storage
  - Push notifications (in development)
- **Provider:**  
  Efficient state management for the app.
- **Modular Architecture:**  
  Clear separation by modules: authentication, recipes, blog, profile, consultations, etc.
- **CI/CD & GitHub:**  
  Version control, continuous integration, and automated deployment.

---

## 📱 Folder Structure

```
lib/
  core/           # Constants, services, and global providers
  models/         # Data models (user, recipe, blog, nutritionist, etc.)
  screens/        # Screens organized by functionality
    add_stuff/    # Forms to add content (recipes, blogs, tips)
    auth/         # Authentication and registration
    categories/   # Main categories (tracking, tips, etc.)
    chat/         # Chat and messaging (in development)
    details/      # Details for recipes, blogs, nutritionists
    main/         # Home, profile, main navigation
    nutriologo/   # Features exclusive to nutritionists
    settings/     # Settings and profile editing
  widgets/        # Reusable components (AppBar, buttons, etc.)
assets/           # Images, icons, and static resources
```

---

## 👤 Roles & Permissions

- **General User:**  
  Access to recipes, blog, tips, tracking, and emergency mode.
- **Nutritionist:**  
  Additional access to manage patients, publish recipes and articles, customize professional profile, and consult agenda.

---

## 📝 Installation & Running

1. **Clone the repository:**
   ```sh
   git clone https://github.com/your-username/APP_Dianui.git
   cd DianuiAPP
   ```

2. **Install dependencies:**
   ```sh
   flutter pub get
   ```

3. **Configure Firebase:**  
   Download and place the `google-services.json` (Android) and/or `GoogleService-Info.plist` (iOS) files in the corresponding folders.

4. **Run the app:**
   ```sh
   flutter run
   ```

> For more details on installing Flutter, see the [official documentation](https://docs.flutter.dev/get-started/install).

---

## 📖 Resources & Visual Guide

- [PDF with the expected app interface](https://github.com/uno21858/Dianui/blob/7a50749bdf6c9d9940e5529da205c35156908619/DIANUI%20TE%20VE%CC%81%20%20DIANUI%20911.pdf)

---

## 🤝 Credits & Contributors

- Project developed in collaboration with **Fundación DIANUI A.C.**
- Development team:  
  - [Lorenzo Orrante Román] (Flutter Developer)
  - [Erick Alberto Sánchez] (Flutter Developer)
  - [Galo Arechiga] (Flutter Developer)
  - [Daniel Hernández] (Flutter Developer)

---

## 🏆 License

This project is open source under the MIT license.

---

Thank you for your interest in DIANUI App!