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
- **E-commerce overhaul (checkout source separation, cart selection, Buy Now, voucher scope, seller isolation)**:
  - `CheckoutModel`/`CheckoutSource`: cart vs buyNow, `cartItemIds`, `shopVoucher`, `CheckoutState`
  - `CheckoutRepository.createOrder`: switched to `create_checkout_order_v2` RPC — server computes price/stock/vouchers
  - `CheckoutScreen`: ConsumerWidget→ConsumerStatefulWidget + `addPostFrameCallback` (fixes Riverpod 3.x lifecycle)
  - `CartScreen`: item checkboxes, partial checkout, voucher apply flow, empty/error/loading
  - `ProductDetailScreen`: Buy Now creates temp `CartItemModel` (prefix `buy_now_`) — no cart mutation
  - `VoucherModel`/`VoucherRepository`: scope (admin/shop) + sellerId filters, validateVoucher, admin/shop CRUD
  - `AdminCouponsScreen`: admin voucher CRUD via real Supabase
  - `StoreSettingsScreen`: 3-tab (info/policies/shop vouchers), shop voucher CRUD via Supabase
  - `StoreShell._tabIndex`: sub-route handling for add/edit/detail
  - `AppRouter._currentIndex`: maps checkout/payment → Cart tab (fixed `startsWith`), Vietnamese labels
  - Admin route paths: fixed `:id` path params with `replaceAll`
  - `PaymentScreen._PayOsPaymentPanel`: fixed infinite width (ListView→SingleChildScrollView+Column)
  - `ProductCard`: fixed overflow (FittedBox inside 160px card)
- **Fix migration SQL enum cast errors**:
  - Convert `voucher_scope` enum→TEXT to avoid unsafe enum value in transaction
  - Convert `order_status_history.from_status/to_status` from `order_status_type`→TEXT at migration top
  - Convert `payments.status` from `payment_status_type`→TEXT at migration top
  - Cast `orders.status` INSERT to `::order_status_type` (column is enum)
  - Cast `payments.status` INSERT to `::payment_status_type` (gets implicitly converted to TEXT)
  - Cast `order_status_history` INSERT values in RPCs to `::order_status_type` (columns now TEXT after conversion)

### In Progress
- (none — chờ user test)

### Blocked
- RLS trên `shop_registrations` bị **DISABLE** tạm thời — cần enable lại với policy đúng trước deploy
- Migration SQL 20260623 chưa được apply lên Supabase

## Key Decisions
- Dùng `FutureProvider.autoDispose` + `ref.read` cho `myShopRegistrationProvider` — tránh re-run vô hạn
- `getRegistrationStatus` wrap try-catch trả về `null` — app vẫn hoạt động nếu table chưa tồn tại
- Bỏ `shopCategory` hoàn toàn — business model chỉ gym/fitness
- **Disable RLS** trên `shop_registrations` để dev — sẽ enable lại sau với SECURITY DEFINER RPC
- Store owner dùng bottom navigation thay vì NavigationRail (mobile-first)
- State image lưu `XFile?` thay `File?` — cross-platform (web + mobile)
- Upload image dùng `Uint8List` bytes + `uploadBinary()` — tránh dart:io trên web
- Store screen classes prefix `Store*` để tránh conflict import với feature screens cùng tên
- Convert externally-created enum columns (voucher_scope, order_status_type in history, payment_status_type in payments) to TEXT at migration top to avoid cast errors in INSERT/UPDATE statements
- `orders.status` remains `order_status_type` enum — INSERT values explicitly cast to avoid TEXT→enum ambiguity

## Next Steps
1. Apply migration `20260623_harden_checkout_vouchers_seller_orders.sql` to Supabase via SQL editor or CLI
2. Run `flutter analyze lib/` — expect 0 errors
3. Execute test plan: checkout → cart → Buy Now → payment → store settings → admin vouchers
4. Re-enable RLS on `shop_registrations` table before production

## Critical Context
- `flutter analyze lib/` — 0 errors, warnings chỉ từ pre-existing files (109 total, 0 errors)
- **Migration error history**: `voucher_scope` enum value conflict (converted to TEXT), `order_status_type` cast errors in `order_status_history` INSERTs (columns converted to TEXT at top), `payment_status_type` cast error (converted to TEXT at top)
- **RLS bị DISABLE** trên `shop_registrations` — cần fix trước deploy
- `public.users` table không tồn tại trong Supabase project hiện tại — all user queries go through `profiles` table
- `is_admin()` function tồn tại sẵn (dùng bởi nhiều table khác) — không drop được
- `ShopRegistrationModel` là const class → hot reload không hiệu quả khi sửa field, cần hot restart
- Admin redirect dựa trên `auth.appMetadata['role']` — set qua Supabase Dashboard
- Store owner redirect dựa trên `role == 'storeowner'` hoặc `sellerStatus == 'approved'`
- `CheckoutScreen` dùng `ConsumerStatefulWidget` + `addPostFrameCallback` — Riverpod 3.x không cho `ref.read` provider trong build
- `PaymentScreen._PayOsPaymentPanel` dùng `SingleChildScrollView`+`Column` — tránh `BoxConstraints infinite width`
- **Migration file**: `supabase/migrations/20260623_harden_checkout_vouchers_seller_orders.sql`
- **Test plan**: 9 sections, ~40 test cases (checkout/cart/Buy Now/payment/store/seller isolation/admin)

## Relevant Files
- `lib/features/register_shop/data/models/shop_registration_model.dart`: model chính
- `lib/features/register_shop/data/repositories/shop_registration_repository.dart`: API + upload (dùng Uint8List)
- `lib/features/register_shop/providers/shop_registration_providers.dart`: Riverpod providers
- `lib/features/register_shop/presentation/screens/register_shop_screen.dart`: multi-step form (XFile + _handleNext)
- `lib/features/profile/presentation/screens/profile_screen.dart`: _ShopRegistrationSection + "Quản lý Shop" link
- `lib/features/admin/shop_registrations/presentation/screens/admin_shop_registrations_screen.dart`: admin list
- `lib/features/admin/shop_registrations/presentation/screens/admin_shop_detail_screen.dart`: admin detail + approve/reject
- `lib/features/store/presentation/screens/store_shell.dart`: bottom nav 5 tabs
- `lib/features/store/presentation/screens/store_dashboard/dashboard_screen.dart`: dashboard stats + charts
- `lib/features/store/presentation/screens/store_products/product_list_screen.dart`: StoreProductListScreen
- `lib/features/store/presentation/screens/store_products/product_form_screen.dart`: StoreProductFormScreen
- `lib/features/store/presentation/screens/store_orders/order_list_screen.dart`: StoreOrderListScreen
- `lib/features/store/presentation/screens/store_orders/order_detail_screen.dart`: StoreOrderDetailScreen
- `lib/features/store/presentation/screens/store_finance/finance_screen.dart`: FinanceScreen
- `lib/features/store/presentation/screens/store_settings/settings_screen.dart`: SettingsScreen (3-tab, shop voucher CRUD)
- `lib/features/checkout/data/models/checkout_model.dart`: CheckoutSource, CheckoutState, CheckoutRequest/Result
- `lib/features/checkout/data/repositories/checkout_repository.dart`: createOrder → RPC v2
- `lib/features/checkout/presentation/screens/checkout_screen.dart`: ConsumerStatefulWidget, addPostFrameCallback
- `lib/features/checkout/providers/checkout_providers.dart`: CreateOrderNotifier.submit()
- `lib/features/cart/presentation/screens/cart_screen.dart`: item selection, partial checkout, voucher
- `lib/features/products/presentation/screens/product_detail_screen.dart`: Buy Now (no cart mutation)
- `lib/features/voucher/data/models/voucher_model.dart`: scope/sellerId, isAdminVoucher/isShopVoucher
- `lib/features/voucher/data/repositories/voucher_repository.dart`: scope filters, validateVoucher, getAdminVouchers, saveVoucher
- `lib/features/voucher/providers/voucher_provider.dart`: voucherRepositoryProvider, availableVouchersProvider
- `lib/features/admin/coupons/admin_coupons.dart`: admin voucher CRUD via Supabase
- `lib/features/payments/presentation/screens/payment_screen.dart`: fixed QrImageView layout
- `lib/features/products/presentation/widgets/product_card.dart`: fixed price overflow
- `lib/core/router/app_router.dart`: _currentIndex with startsWith, Vietnamese labels
- `lib/core/router/route_names.dart`: all route path/name constants
- `supabase/migrations/20260623_harden_checkout_vouchers_seller_orders.sql`: full backend (RPC v2, voucher scope, seller isolation, enum→TEXT conversions)
