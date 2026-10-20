# NU Report — ระบบแจ้งปัญหา

แอป Flutter สำหรับแจ้งปัญหาพร้อมรูปภาพ ติดตามสถานะ และให้เจ้าหน้าที่จัดการ/สรุปผลรายเดือน ข้อมูลเก็บในเครื่องด้วย SQLite

## วิธีรัน

1. `flutter pub get`
2. `flutter run` (Android emulator หรือเครื่องจริง) — ครั้งแรกแอปจะสร้างฐานข้อมูลและใส่ข้อมูลตัวอย่างเอง
3. ถ่ายรูปต้องใช้เครื่องจริง หรือ emulator ที่เปิดกล้องไว้ (ถ้าไม่มีกล้อง ให้เลือกจากคลังรูปแทน)

ทดสอบ: `flutter test`

### รันบนเว็บ (สำหรับทดสอบเร็วๆ)

`flutter run -d chrome` — บนเว็บใช้ SQLite แบบ WebAssembly (`sqflite_common_ffi_web`) เก็บข้อมูลใน IndexedDB ของเบราว์เซอร์
ถ้าลบ `web/sqlite3.wasm` หรือ `web/sqflite_sw.js` ไป ให้รัน `dart run sqflite_common_ffi_web:setup` ใหม่
ตอนนำเสนอควรใช้มือถือ/emulator เพราะเว็บถ่ายรูปด้วยกล้องไม่ได้

## บัญชีทดสอบ

| ชื่อผู้ใช้ | รหัสผ่าน | สิทธิ์ |
|---|---|---|
| admin | admin123 | เจ้าหน้าที่ |
| user | user123 | ผู้แจ้ง |

ไม่มีคีย์ API หรือรหัสผ่านจริงใน repository

## Package ที่ใช้

| package | ใช้ทำอะไร |
|---|---|
| sqflite, path | ฐานข้อมูล SQLite ในเครื่อง |
| provider | แชร์สถานะผู้ใช้และรายการ report ระหว่างหน้าจอ |
| image_picker, path_provider | ถ่าย/เลือกรูป และเก็บไฟล์รูปถาวร |
| crypto | hash รหัสผ่าน (SHA-256) |
| fl_chart | กราฟสรุปผล |
| share_plus | ส่งออกไฟล์ CSV |
| intl | รูปแบบวันที่ภาษาไทย |

การแบ่งงานอยู่ที่ [docs/ส่วนของแต่ละคน.md](docs/ส่วนของแต่ละคน.md)
