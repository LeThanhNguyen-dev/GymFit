## Goal
- Build Register Shop + Store Owner (Shop Management) feature on GymFit Flutter app

## Constraints & Preferences
- Mobile-first Android (web không ưu tiên)
- Dùng Riverpod state management, GoRouter navigation, Supabase backend
- Shop category field đã bỏ — user chỉ làm gym/fitness
- Image upload qua Supabase Storage bucket `shop-documents`
- CCCD number validate 9 hoặc 12 số
- Không cho submit nếu đang có đơn `pending`
- Storeowner role + shop management has 5 tabs (bottom navigation)

## Progress
### Done
- ✅ **Merge `feature/infrastructure-setup` into `develop`**: resolved merge conflicts, fixed 8 post-merge errors
  - `CardTheme` → `CardThemeData` (Material 3)
  - `DialogTheme` → `DialogThemeData` (Material 3)
  - Removed duplicate `light` getter in `app_theme.dart`
  - Added `fullAddress` getter + `copyWith` to `AddressModel`
  - Added `createAddress`, `updateAddress`, `deleteAddress`, `setDefaultAddress` to `AddressRepository`
  - Fixed `setDefaultAddress` to scope by `userId`
  - Removed unused imports in `address_screen.dart`
- Thêm `ShopRegistrationStatus` + `BusinessType` enum vào `database_enums.dart`
- Thêm `shopRegistrationsTable` constant vào `app_constants.dart`
- Tạo `ShopRegistrationModel` (full `fromJson`/`toJson`, `statusDisplay`, `businessTypeDisplay`)
- Tạo `ShopRegistrationRepository` (submit, update, getStatus, listAll, approve, reject + image upload)
- Tạo Riverpod providers: `shopRegistrationRepositoryProvider`, `myShopRegistrationProvider`, `allShopRegistrationsProvider`, `shopRegistrationsByStatusProvider`
- Build Register Shop multi-step screen (4 steps) với custom stepper, form validation, image picker, date picker, re-submit
- Cập nhật Profile page: `_ShopRegistrationSection` xử lý 4 trạng thái (none → Đăng ký, pending → badge, approved → card, rejected → lý do + Đăng ký lại)
- Build admin screens: `AdminShopRegistrationsScreen` (3 tabs) + `AdminShopDetailScreen` (approve/reject, full-screen CCCD)
- Đăng ký routes: `/register-shop`, `/admin/shop-registrations`, `/admin/shop-registrations/:id`
- Thêm mục "Shops" vào admin NavigationRail (index 3)
- Fix vòng lặp loading profile: `ref.read` + `autoDispose`
- Fix button không hiện: bắt lỗi `getRegistrationStatus` → trả về `null`
- Bỏ `shopCategory` khỏi model, repository, form, admin detail
- Fix PostgrestException `product_variants_1.images does not exist`: xoá `images` khỏi select query ở `cart_repository.dart`
- **Fix button step 1 không bấm được**: `_canProceed()` gọi validate trong build → chuyển thành `_handleNext()` callback, thêm SnackBar nếu thiếu ảnh CCCD
- **Fix Image.file crash trên web**: thêm `kIsWeb` check, dùng `Image.network(file.path)` cho web
- **Fix "Unsupported operation: Namespace"**: đổi state từ `File?` → `XFile?`, upload qua `Uint8List` bytes, repository dùng `uploadBinary()`
- **Tạo migration SQL**: `20260617_create_shop_registrations.sql` (table + RLS + storage bucket `shop-documents`)
- **Fix RLS permissions**: qua nhiều lần thử (public.users không tồn tại → SECURITY DEFINER function → auth.jwt() → RPC functions → cuối cùng **DISABLE RLS** tạm thời)
- **Thêm storeowner role**: route names (`store*Path`), store shell (bottom nav 5 tabs), router redirect (`/store/dashboard`), profile link "Quản lý Shop"
- **Build Store Owner screens**:
  - `store_shell.dart`: BottomNavigationBar với 5 tabs
  - Tab 1 — Dashboard (`dashboard_screen.dart`): period toggle (today/week/month), stats grid, revenue line chart 7 ngày, top 5 products bar chart, quick actions
  - Tab 2 — Sản phẩm (`StoreProductListScreen` + `StoreProductFormScreen`): search, filter tabs, sort, product card with 3-dot menu, FAB "+ Thêm sản phẩm", multi-step form (5 steps: básico → ảnh → phân loại/variant matrix → vận chuyển → review)
  - Tab 3 — Đơn hàng (`StoreOrderListScreen` + `StoreOrderDetailScreen`): 6 filter tabs, search, order card, detail với timeline trạng thái + action buttons (Xác nhận/Từ chối)
  - Tab 4 — Tài chính (`FinanceScreen`): balance overview header, 4 tabs (Tổng quan/Rút tiền/Lịch sử/Ngân hàng)
  - Tab 5 — Cài đặt (`SettingsScreen`): shop info form, policies text editor, notification toggles, review management
- **Cập nhật auth**: `fetchProfile()` fallback đọc role từ auth metadata; `_checkCurrentUser` fallback tương tự
- **Đặt tên lại store screen classes**: `StoreProductListScreen`, `StoreProductFormScreen`, `StoreOrderListScreen`, `StoreOrderDetailScreen` — tránh conflict với product/order feature screens
- **Clean warnings**: xoá unused imports, fix `?.` không cần thiết trên store screens
- ✅ **Merge `feature/infrastructure-setup`**: resolve conflicts, fix 8 post-merge errors (CardTheme, DialogTheme, duplicate `light`, address model/repository methods, unused imports)

### In Progress
- (none — chờ user test)

### Blocked
- RLS trên `shop_registrations` bị **DISABLE** tạm thời — cần enable lại với policy đúng trước deploy
- Admin approve/reject chưa update `sellerStatus` + `role` của user trong `users` table

## Key Decisions
- Dùng `FutureProvider.autoDispose` + `ref.read` cho `myShopRegistrationProvider` — tránh re-run vô hạn
- `getRegistrationStatus` wrap try-catch trả về `null` — app vẫn hoạt động nếu table chưa tồn tại
- Bỏ `shopCategory` hoàn toàn — business model chỉ gym/fitness
- **Disable RLS** trên `shop_registrations` để dev — sẽ enable lại sau với SECURITY DEFINER RPC
- Store owner dùng bottom navigation thay vì NavigationRail (mobile-first)
- State image lưu `XFile?` thay `File?` — cross-platform (web + mobile)
- Upload image dùng `Uint8List` bytes + `uploadBinary()` — tránh dart:io trên web
- Store screen classes prefix `Store*` để tránh conflict import với feature screens cùng tên

## Next Steps
- Enable RLS lại đúng cách: tạo `SECURITY DEFINER` RPC cho admin queries, giữ `auth.uid() = user_id` cho user thường
- ✅ Khi admin approve → đã update `role = 'storeowner'` và `seller_status = 'approved'` trong `profiles` table
- Kết nối store screens với real Supabase data (hiện đang dùng mock data)
- Test full flow: register → admin approve → user login as storeowner → see store dashboard

## Critical Context
- `flutter analyze lib/` — 0 errors, warnings chỉ từ pre-existing files
- **RLS bị DISABLE** trên `shop_registrations` — cần fix trước deploy
- `public.users` table không tồn tại trong Supabase project hiện tại
- `is_admin()` function tồn tại sẵn (dùng bởi nhiều table khác) — không drop được
- `ShopRegistrationModel` là const class → hot reload không hiệu quả khi sửa field, cần hot restart
- Admin redirect hoạt động dựa trên `auth.appMetadata['role']` — cần set qua Supabase Dashboard
- Store owner redirect hoạt động dựa trên `role == 'storeowner'` hoặc `sellerStatus == 'approved'`
- Store screen classes dùng prefix `Store*` để tránh conflict import với `ProductListScreen` (products feature) và `OrderDetailScreen` (orders feature)

## Relevant Files
- `lib/features/register_shop/data/models/shop_registration_model.dart`: model chính
- `lib/features/register_shop/data/repositories/shop_registration_repository.dart`: API + upload (dùng Uint8List)
- `lib/features/register_shop/providers/shop_registration_providers.dart`: Riverpod providers
- `lib/features/register_shop/presentation/screens/register_shop_screen.dart`: multi-step form (XFile + _handleNext)
- `lib/features/profile/presentation/screens/profile_screen.dart`: _ShopRegistrationSection + "Quản lý Shop" link
- `lib/features/admin/shop_registrations/presentation/screens/admin_shop_registrations_screen.dart`: admin list
- `lib/features/admin/shop_registrations/presentation/screens/admin_shop_detail_screen.dart`: admin detail + approve/reject (dùng invalidate + pop thay go)
- `lib/features/store/presentation/screens/store_shell.dart`: bottom nav 5 tabs
- `lib/features/store/presentation/screens/store_dashboard/dashboard_screen.dart`: dashboard stats + charts
- `lib/features/store/presentation/screens/store_products/product_list_screen.dart`: StoreProductListScreen
- `lib/features/store/presentation/screens/store_products/product_form_screen.dart`: StoreProductFormScreen
- `lib/features/store/presentation/screens/store_orders/order_list_screen.dart`: StoreOrderListScreen
- `lib/features/store/presentation/screens/store_orders/order_detail_screen.dart`: StoreOrderDetailScreen
- `lib/features/store/presentation/screens/store_finance/finance_screen.dart`: FinanceScreen
- `lib/features/store/presentation/screens/store_settings/settings_screen.dart`: SettingsScreen
- `lib/features/auth/providers/auth_providers.dart`: fallback role từ auth metadata
- `lib/features/auth/data/repositories/auth_repository.dart`: fetchProfile fallback
- `lib/core/router/route_names.dart`: thêm store routes
- `lib/core/router/app_router.dart`: storeowner redirect + store shell routes (aliased imports)
- `supabase/migrations/20260617_create_shop_registrations.sql`: table + storage + RLS (hiện đã disable)
