# TaskFlow — แอปจัดการงานที่ต้องทำ

## ชื่อโจทย์
โจทย์ที่ 3: แอปจัดการงานที่ต้องทำ (To-do List)  
สร้างแอป To-do List สำหรับติดตามงานประจำวัน

---

## ชื่อผู้จัดทำ
- **ชื่อ-สกุล:** นาย ทวีชัย ทิใจ  
- **รหัสนักศึกษา:** 67543210029-4  
- **วิชา:** ENGSE608 Mobile Devices Application Design and Development

---

## รายละเอียดฟังก์ชัน
- **CRUD งาน** — เพิ่ม แก้ไข ลบ ดูรายละเอียดงาน
- **ค้นหางาน** — ค้นหาจากชื่อหรือรายละเอียด
- **กรองตามสถานะ** — รอดำเนินการ / กำลังทำ / เสร็จแล้ว
- **Dashboard** — แสดงสถิติรวม Donut Chart และ Bar Chart ตามหมวดหมู่
- **Progress Bar** — แสดงความคืบหน้า 0-100% ของแต่ละงาน
- **จัดการหมวดหมู่** — เพิ่ม/ลบหมวดหมู่ได้เอง
- **จัดการสถานะ** — เพิ่ม/แก้ไข/ลบสถานะพร้อมเลือกสีได้เอง
- **เรียงลำดับ** — เรียงตามวันครบกำหนด / วันสร้าง / ชื่อ
- **Multi-select** — กดค้างเพื่อเลือกลบหลายรายการ
- **Validation** — ป้องกันการกรอกข้อมูลไม่ครบ
- **SnackBar** — แจ้งเตือนเมื่อเพิ่ม/ลบ/บันทึกสำเร็จ
- **Dialog** — ยืนยันก่อนลบทุกครั้ง

---

## โครงสร้างฐานข้อมูล / ER
```
categories (id PK, name)
     |
     | 1 ──── N
     |
tasks (id PK, title, description,
       category_id FK, due_date,
       status, progress, created_at)

status_configs (id PK, key_name, label, color_value)
```

---

## Package ที่ใช้

| Package | Version | หน้าที่ |
|---|---|---|
| provider | ^6.1.1 | State Management (ChangeNotifier) |
| sqflite | ^2.3.0 | SQLite Local Database |
| path | ^1.8.3 | จัดการ path ของฐานข้อมูล |
| intl | ^0.20.0 | จัดรูปแบบวันที่ |
| flutter_localizations | SDK | รองรับภาษาไทย |

---

## วิธีรันโปรเจกต์
```bash
# 1. Clone โปรเจกต์
git clone https://github.com/Saihakuto/TaskMaster-Pro.git
cd taskflow

# 2. ติดตั้ง dependencies
flutter pub get

# 3. รันแอป
flutter run

# 4. Build APK
flutter build apk --release
```

ไฟล์ APK อยู่ที่ `build/app/outputs/flutter-apk/app-release.apk`

---

## Screenshots

| Dashboard | รายการงาน | เพิ่มงาน | รายละเอียด |
|---|---|---|---|
|<img width="308" height="660" alt="Image" src="https://github.com/user-attachments/assets/d3c09a08-c0d6-4f67-bdaf-6c856dcb043a" />|<img width="306" height="659" alt="Image" src="https://github.com/user-attachments/assets/1f7e4df4-9eda-4d9a-b5aa-e2daf0083abe" />|<img width="306" height="648" alt="Image" src="https://github.com/user-attachments/assets/bddfb4f7-19fc-4df9-904a-6fb99297aac9" />|<img width="306" height="649" alt="Image" src="https://github.com/user-attachments/assets/c4266049-c894-44f3-b960-6b871a35d7cb" />| 
