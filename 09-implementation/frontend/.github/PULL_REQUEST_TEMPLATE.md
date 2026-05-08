## Mô tả

Mô tả ngắn gọn thay đổi UI/UX/feature trong PR này.

## Loại thay đổi

- [ ] Bug fix (non-breaking)
- [ ] Feature mới (non-breaking)
- [ ] Breaking change (vd thay đổi API contract)
- [ ] Refactor (không thay đổi UI)
- [ ] Performance improvement
- [ ] Docs only

## Screens affected

Liệt kê screens thay đổi:
- `lib/features/student/...`
- `lib/features/admin/...`

## Why

Link issue / user feedback: Closes #...

## What changed

- Bullet các thay đổi chính
- Bullet...

## Screenshots

⚠️ **BẮT BUỘC** với UI changes — kèm 4 viewport (nếu responsive) + light/dark mode:

| Light mode | Dark mode |
|------------|-----------|
| ![light](url) | ![dark](url) |

| Desktop 1440 | Tablet 768 | Mobile 380 |
|--------------|------------|------------|
| ... | ... | ... |

## Test

Cách verify đã test:
- [ ] `flutter analyze` không error
- [ ] `flutter run -d chrome` smoke test pass
- [ ] `flutter build web --release` build OK
- [ ] Test 4 viewport (1440 / 1024 / 768 / 567)
- [ ] Test light + dark mode
- [ ] Test 4 actor flow nếu impacted (SV/GV/BCN/Admin)

## Build deploy URL (nếu đã deploy preview)

`https://<hash>.ptit-contest-app.pages.dev`

## Checklist

- [ ] Code style OK (`flutter analyze`)
- [ ] Sử dụng theme tokens (KHÔNG hardcode hex/size/radius)
- [ ] CHANGELOG.md updated `[Unreleased]` section
- [ ] README.md updated nếu thêm screen mới
- [ ] A11y check — Semantics labels, touch ≥44dp, contrast WCAG AA
