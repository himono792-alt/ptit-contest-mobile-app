# Frontend tests

Test pyramid bước đầu cho Flutter app (bổ sung 2026-06-16).

## Chạy

```bash
cd frontend
flutter pub get
flutter test
```

## Cấu trúc

| File | Loại | Bao phủ |
|------|------|---------|
| `models/contest_model_test.dart` | unit | `ContestSummary.fromJson` / `ContestListResponse.fromJson` — field parsing + default `entries_count` + optional null. |
| `models/result_model_test.dart` | unit | `MyResultModel.fromJson` — parse `final_score` string→double, null khi chưa có kết quả. |
| `widgets/pill_test.dart` | unit + widget | `Pill.status()` map status→PillKind (success/warn/danger/neutral) + render label. |
| `widgets/empty_view_test.dart` | widget | `EmptyView` render title/subtitle/action + toggle `decoratedIcon`. |
| `widget_test.dart` | smoke | placeholder. |

## Ghi chú

- Widget test bọc trong `MaterialApp` cơ bản: các token màu `context.*` (app_colors.dart)
  chỉ cần `Theme.of(context)` để lấy brightness nên render được với theme mặc định.
- Chưa có **golden test** (cần chạy `flutter test --update-goldens` lần đầu để sinh ảnh
  baseline) và **integration test** (luồng login→nộp bài). Đây là bước tiếp theo của pyramid.
