# GymFit Build & Release Guide

Để tiến hành build ứng dụng phục vụ quá trình test (QA) hoặc release lên store, vui lòng sử dụng các lệnh dưới đây. Lưu ý: Do các biến môi trường đã được yêu cầu cung cấp động qua `--dart-define`, bạn phải đính kèm các tham số này mỗi khi build.

## Build APK cho Android (Split per ABI)

Việc chia nhỏ APK theo từng kiến trúc chip (`armeabi-v7a`, `arm64-v8a`, `x86_64`) sẽ giúp giảm đáng kể dung lượng ứng dụng khi tải về.

```bash
flutter build apk --split-per-abi \
  --dart-define=SUPABASE_URL="https://your_project.supabase.co" \
  --dart-define=SUPABASE_ANON_KEY="your_anon_key_here"
```

Sau khi chạy xong, file APK sẽ nằm ở:
`build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk`
`build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`
`build/app/outputs/flutter-apk/app-x86_64-release.apk`

## Build App Bundle (AAB) cho Google Play Store

Khi đã sẵn sàng phát hành chính thức:

```bash
flutter build appbundle \
  --dart-define=SUPABASE_URL="https://your_project.supabase.co" \
  --dart-define=SUPABASE_ANON_KEY="your_anon_key_here"
```

## Chạy thử máy ảo (Debug)

Trong quá trình dev, nếu muốn test tính năng cần kết nối db thực (không dùng mock):

```bash
flutter run \
  --dart-define=SUPABASE_URL="https://your_project.supabase.co" \
  --dart-define=SUPABASE_ANON_KEY="your_anon_key_here"
```
