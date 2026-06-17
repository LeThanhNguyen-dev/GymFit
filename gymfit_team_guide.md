# 🏋️ GymFit E-Commerce — Team Development Guide

> **Dự án**: GymFit — Ứng dụng bán đồ tập gym (Flutter + Supabase)
> **Số thành viên**: 5 người
> **Thời gian dự kiến**: 14 ngày
> **Ngày bắt đầu**: ___/___/2026

---

## 📋 Mục lục

1. [Tổng quan dự án](#1-tổng-quan-dự-án)
2. [Tech Stack](#2-tech-stack)
3. [Folder Structure](#3-folder-structure)
4. [Database Schema](#4-database-schema)
5. [Shared Conventions & Coding Rules](#5-shared-conventions--coding-rules)
6. [Branch Strategy](#6-branch-strategy)
7. [Người 1 — Leader / Core / Auth / User](#7-người-1--leader--core--auth--user)
8. [Người 2 — Product Catalog / Home / Search](#8-người-2--product-catalog--home--search)
9. [Người 3 — Cart / Wishlist / Voucher](#9-người-3--cart--wishlist--voucher)
10. [Người 4 — Checkout / Order / Payment / Shipping](#10-người-4--checkout--order--payment--shipping)
11. [Người 5 — Review / Support / Admin / Dashboard / AI](#11-người-5--review--support--admin--dashboard--ai)
12. [Timeline 14 ngày](#12-timeline-14-ngày)
13. [Quy tắc chống Conflict khi Merge](#13-quy-tắc-chống-conflict-khi-merge)
14. [Checklist trước khi Merge](#14-checklist-trước-khi-merge)

---

## 1. Tổng quan dự án

GymFit là ứng dụng e-commerce bán đồ tập gym, hỗ trợ:
- Đăng ký / Đăng nhập / Quản lý profile
- Duyệt sản phẩm theo danh mục, thương hiệu
- Giỏ hàng, wishlist, voucher
- Checkout, thanh toán COD / Mock Momo / VNPay
- Quản lý đơn hàng, tracking shipping
- Đánh giá sản phẩm, hỗ trợ khách hàng
- Admin dashboard, quản lý tồn kho
- AI Recommendation

---

## 2. Tech Stack

| Layer | Công nghệ |
|-------|-----------|
| **Framework** | Flutter 3.x (Dart) |
| **State Management** | Riverpod (flutter_riverpod + riverpod_annotation) |
| **Routing** | GoRouter (go_router) |
| **Backend** | Supabase (Auth, Database, Storage, Realtime) |
| **Database** | PostgreSQL (via Supabase) |
| **Image Storage** | Supabase Storage |
| **Local Cache** | shared_preferences / hive |
| **HTTP Client** | supabase_flutter (built-in) |
| **Image Picker** | image_picker |
| **Image Carousel** | carousel_slider |
| **Rating** | flutter_rating_bar |
| **Icons** | iconsax_flutter hoặc phosphor_flutter |
| **Fonts** | Google Fonts (Inter / Poppins) |

### pubspec.yaml dependencies (tham khảo)

```yaml
dependencies:
  flutter:
    sdk: flutter
  supabase_flutter: ^2.5.0
  flutter_riverpod: ^2.5.0
  riverpod_annotation: ^2.3.0
  go_router: ^14.0.0
  shared_preferences: ^2.2.0
  image_picker: ^1.0.0
  carousel_slider: ^4.2.1
  flutter_rating_bar: ^4.0.1
  cached_network_image: ^3.3.0
  intl: ^0.19.0
  uuid: ^4.3.0
  google_fonts: ^6.1.0
  shimmer: ^3.0.0
  flutter_svg: ^2.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  riverpod_generator: ^2.4.0
  build_runner: ^2.4.0
  json_serializable: ^6.7.0
```

---

## 3. Folder Structure

```
lib/
├── main.dart
├── app.dart
│
├── core/
│   ├── config/
│   │   ├── supabase_config.dart        # Supabase init
│   │   ├── app_config.dart             # App-wide constants
│   │   └── env.dart                    # Environment variables
│   ├── router/
│   │   ├── app_router.dart             # GoRouter config
│   │   ├── route_names.dart            # Route name constants
│   │   └── router_notifier.dart        # Auth state → router redirect
│   ├── theme/
│   │   ├── app_theme.dart              # ThemeData
│   │   ├── app_colors.dart             # Color constants
│   │   ├── app_text_styles.dart        # TextStyle constants
│   │   └── app_spacing.dart            # Spacing/padding constants
│   ├── utils/
│   │   ├── extensions.dart             # Dart extensions
│   │   ├── validators.dart             # Form validators
│   │   ├── formatters.dart             # Currency, date formatters
│   │   └── helpers.dart                # General helpers
│   └── errors/
│       ├── app_exception.dart          # Custom exception classes
│       ├── error_handler.dart          # Global error handler
│       └── failure.dart                # Failure model
│
├── shared/
│   ├── widgets/
│   │   ├── app_button.dart
│   │   ├── app_text_field.dart
│   │   ├── app_loading.dart
│   │   ├── app_error_widget.dart
│   │   ├── app_snackbar.dart
│   │   ├── app_image.dart
│   │   ├── app_card.dart
│   │   ├── app_badge.dart
│   │   ├── app_bottom_sheet.dart
│   │   ├── app_dialog.dart
│   │   ├── app_empty_state.dart
│   │   ├── price_text.dart
│   │   ├── rating_stars.dart
│   │   └── shimmer_loading.dart
│   ├── models/
│   │   ├── api_response.dart           # Generic response wrapper
│   │   └── pagination.dart             # Pagination model
│   └── providers/
│       ├── supabase_provider.dart      # Supabase client provider
│       └── connectivity_provider.dart
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   └── auth_repository.dart
│   │   ├── models/
│   │   │   └── user_model.dart
│   │   ├── providers/
│   │   │   └── auth_provider.dart
│   │   └── screens/
│   │       ├── login_screen.dart
│   │       ├── register_screen.dart
│   │       ├── forgot_password_screen.dart
│   │       └── reset_password_screen.dart
│   │
│   ├── user/
│   │   ├── data/
│   │   │   ├── profile_repository.dart
│   │   │   └── address_repository.dart
│   │   ├── models/
│   │   │   ├── profile_model.dart
│   │   │   └── address_model.dart
│   │   ├── providers/
│   │   │   ├── profile_provider.dart
│   │   │   └── address_provider.dart
│   │   └── screens/
│   │       ├── profile_screen.dart
│   │       ├── edit_profile_screen.dart
│   │       └── address_list_screen.dart
│   │
│   ├── products/
│   │   ├── data/
│   │   │   ├── product_repository.dart      # ⭐ SHARED REPO
│   │   │   ├── category_repository.dart     # ⭐ SHARED REPO
│   │   │   └── brand_repository.dart        # ⭐ SHARED REPO
│   │   ├── models/
│   │   │   ├── product_model.dart           # ⭐ SHARED MODEL
│   │   │   ├── category_model.dart          # ⭐ SHARED MODEL
│   │   │   ├── brand_model.dart             # ⭐ SHARED MODEL
│   │   │   ├── product_image_model.dart     # ⭐ SHARED MODEL
│   │   │   └── product_variant_model.dart   # ⭐ SHARED MODEL
│   │   ├── providers/
│   │   │   ├── product_provider.dart
│   │   │   ├── category_provider.dart
│   │   │   ├── brand_provider.dart
│   │   │   └── search_provider.dart
│   │   └── screens/
│   │       ├── home_screen.dart
│   │       ├── product_list_screen.dart
│   │       ├── product_detail_screen.dart
│   │       └── search_screen.dart
│   │
│   ├── cart/
│   │   ├── data/
│   │   │   └── cart_repository.dart
│   │   ├── models/
│   │   │   └── cart_item_model.dart
│   │   ├── providers/
│   │   │   └── cart_provider.dart
│   │   └── screens/
│   │       └── cart_screen.dart
│   │
│   ├── wishlist/
│   │   ├── data/
│   │   │   └── wishlist_repository.dart
│   │   ├── models/
│   │   │   └── wishlist_item_model.dart
│   │   ├── providers/
│   │   │   └── wishlist_provider.dart
│   │   └── screens/
│   │       └── wishlist_screen.dart
│   │
│   ├── voucher/
│   │   ├── data/
│   │   │   └── voucher_repository.dart
│   │   ├── models/
│   │   │   └── voucher_model.dart
│   │   ├── providers/
│   │   │   └── voucher_provider.dart
│   │   └── screens/
│   │       └── voucher_list_screen.dart
│   │
│   ├── checkout/
│   │   ├── data/
│   │   │   └── checkout_repository.dart
│   │   ├── models/
│   │   │   └── checkout_model.dart
│   │   ├── providers/
│   │   │   └── checkout_provider.dart
│   │   └── screens/
│   │       └── checkout_screen.dart
│   │
│   ├── orders/
│   │   ├── data/
│   │   │   └── order_repository.dart
│   │   ├── models/
│   │   │   ├── order_model.dart
│   │   │   ├── order_item_model.dart
│   │   │   └── order_status_history_model.dart
│   │   ├── providers/
│   │   │   └── order_provider.dart
│   │   └── screens/
│   │       ├── order_history_screen.dart
│   │       └── order_detail_screen.dart
│   │
│   ├── payments/
│   │   ├── data/
│   │   │   └── payment_repository.dart
│   │   ├── models/
│   │   │   └── payment_model.dart
│   │   ├── providers/
│   │   │   └── payment_provider.dart
│   │   └── screens/
│   │       ├── payment_screen.dart
│   │       └── payment_status_screen.dart
│   │
│   ├── shipping/
│   │   ├── data/
│   │   │   └── shipping_repository.dart
│   │   ├── models/
│   │   │   └── shipping_tracking_model.dart
│   │   ├── providers/
│   │   │   └── shipping_provider.dart
│   │   └── screens/
│   │       └── shipping_tracking_screen.dart
│   │
│   ├── reviews/
│   │   ├── data/
│   │   │   └── review_repository.dart
│   │   ├── models/
│   │   │   ├── review_model.dart
│   │   │   └── review_image_model.dart
│   │   ├── providers/
│   │   │   └── review_provider.dart
│   │   └── screens/
│   │       └── review_form_screen.dart
│   │
│   ├── support/
│   │   ├── data/
│   │   │   └── support_repository.dart
│   │   ├── models/
│   │   │   └── support_ticket_model.dart
│   │   ├── providers/
│   │   │   └── support_provider.dart
│   │   └── screens/
│   │       ├── support_list_screen.dart
│   │       └── support_detail_screen.dart
│   │
│   └── admin/
│       ├── data/
│       │   ├── admin_order_repository.dart
│       │   └── inventory_repository.dart
│       ├── models/
│       │   └── inventory_log_model.dart
│       ├── providers/
│       │   ├── admin_provider.dart
│       │   └── dashboard_provider.dart
│       └── screens/
│           ├── admin_dashboard_screen.dart
│           ├── manage_products_screen.dart
│           ├── manage_categories_screen.dart
│           ├── manage_brands_screen.dart
│           ├── manage_vouchers_screen.dart
│           ├── manage_orders_screen.dart
│           └── inventory_screen.dart
```

---

## 4. Database Schema

> [!IMPORTANT]
> Tất cả các bảng đều dùng **UUID** cho primary key và có `created_at`, `updated_at` mặc định.
> RLS (Row Level Security) phải được bật cho mọi bảng.

### 4.1 Bảng `profiles` (Người 1)

```sql
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL,
  phone TEXT,
  avatar_url TEXT,
  role TEXT DEFAULT 'customer' CHECK (role IN ('customer', 'admin')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own profile"
  ON profiles FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE USING (auth.uid() = id);

-- Trigger auto-create profile on signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (id, full_name)
  VALUES (NEW.id, COALESCE(NEW.raw_user_meta_data->>'full_name', ''));
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();
```

### 4.2 Bảng `addresses` (Người 1)

```sql
CREATE TABLE addresses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL,
  phone TEXT NOT NULL,
  address_line TEXT NOT NULL,
  ward TEXT,
  district TEXT,
  city TEXT NOT NULL,
  is_default BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS
ALTER TABLE addresses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own addresses"
  ON addresses FOR ALL USING (auth.uid() = user_id);
```

### 4.3 Bảng `categories` (Người 2)

```sql
CREATE TABLE categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  slug TEXT NOT NULL UNIQUE,
  image_url TEXT,
  description TEXT,
  sort_order INT DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS: Public read, admin write
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view active categories"
  ON categories FOR SELECT USING (is_active = TRUE);

CREATE POLICY "Admin can manage categories"
  ON categories FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );
```

### 4.4 Bảng `brands` (Người 2)

```sql
CREATE TABLE brands (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  slug TEXT NOT NULL UNIQUE,
  logo_url TEXT,
  description TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE brands ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view active brands"
  ON brands FOR SELECT USING (is_active = TRUE);

CREATE POLICY "Admin can manage brands"
  ON brands FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );
```

### 4.5 Bảng `products` (Người 2)

```sql
CREATE TABLE products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  slug TEXT NOT NULL UNIQUE,
  description TEXT,
  category_id UUID REFERENCES categories(id),
  brand_id UUID REFERENCES brands(id),
  base_price DECIMAL(12,2) NOT NULL DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE,
  is_featured BOOLEAN DEFAULT FALSE,
  avg_rating DECIMAL(2,1) DEFAULT 0,
  total_reviews INT DEFAULT 0,
  total_sold INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE products ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view active products"
  ON products FOR SELECT USING (is_active = TRUE);

CREATE POLICY "Admin can manage products"
  ON products FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );
```

### 4.6 Bảng `product_images` (Người 2)

```sql
CREATE TABLE product_images (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  image_url TEXT NOT NULL,
  sort_order INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE product_images ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view product images"
  ON product_images FOR SELECT USING (TRUE);

CREATE POLICY "Admin can manage product images"
  ON product_images FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );
```

### 4.7 Bảng `product_variants` (Người 2)

```sql
CREATE TABLE product_variants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  sku TEXT UNIQUE,
  size TEXT,
  color TEXT,
  price DECIMAL(12,2) NOT NULL,
  stock INT NOT NULL DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE product_variants ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view active variants"
  ON product_variants FOR SELECT USING (is_active = TRUE);

CREATE POLICY "Admin can manage variants"
  ON product_variants FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );
```

### 4.8 Bảng `cart_items` (Người 3)

```sql
CREATE TABLE cart_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  variant_id UUID NOT NULL REFERENCES product_variants(id) ON DELETE CASCADE,
  quantity INT NOT NULL DEFAULT 1 CHECK (quantity > 0),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, variant_id)
);

ALTER TABLE cart_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own cart"
  ON cart_items FOR ALL USING (auth.uid() = user_id);
```

### 4.9 Bảng `wishlist_items` (Người 3)

```sql
CREATE TABLE wishlist_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, product_id)
);

ALTER TABLE wishlist_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own wishlist"
  ON wishlist_items FOR ALL USING (auth.uid() = user_id);
```

### 4.10 Bảng `vouchers` (Người 3)

```sql
CREATE TABLE vouchers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code TEXT NOT NULL UNIQUE,
  description TEXT,
  discount_type TEXT NOT NULL CHECK (discount_type IN ('percentage', 'fixed')),
  discount_value DECIMAL(12,2) NOT NULL,
  min_order_amount DECIMAL(12,2) DEFAULT 0,
  max_discount_amount DECIMAL(12,2),
  usage_limit INT,
  used_count INT DEFAULT 0,
  start_date TIMESTAMPTZ NOT NULL,
  end_date TIMESTAMPTZ NOT NULL,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE vouchers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view active vouchers"
  ON vouchers FOR SELECT USING (
    is_active = TRUE AND start_date <= NOW() AND end_date >= NOW()
  );

CREATE POLICY "Admin can manage vouchers"
  ON vouchers FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );
```

### 4.11 Bảng `orders` (Người 4)

```sql
CREATE TABLE orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id),
  address_id UUID REFERENCES addresses(id),
  voucher_id UUID REFERENCES vouchers(id),
  voucher_code TEXT,
  subtotal DECIMAL(12,2) NOT NULL DEFAULT 0,
  discount_amount DECIMAL(12,2) DEFAULT 0,
  shipping_fee DECIMAL(12,2) DEFAULT 0,
  total_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'confirmed', 'processing', 'shipping', 'delivered', 'cancelled', 'returned')),
  note TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users view own orders"
  ON orders FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users create orders"
  ON orders FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admin can manage all orders"
  ON orders FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );
```

### 4.12 Bảng `order_items` (Người 4)

```sql
CREATE TABLE order_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES products(id),
  variant_id UUID NOT NULL REFERENCES product_variants(id),
  product_name TEXT NOT NULL,
  variant_info TEXT,
  price DECIMAL(12,2) NOT NULL,
  quantity INT NOT NULL,
  subtotal DECIMAL(12,2) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users view own order items"
  ON order_items FOR SELECT USING (
    EXISTS (SELECT 1 FROM orders WHERE orders.id = order_items.order_id AND orders.user_id = auth.uid())
  );

CREATE POLICY "Users create order items"
  ON order_items FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM orders WHERE orders.id = order_items.order_id AND orders.user_id = auth.uid())
  );

CREATE POLICY "Admin manage order items"
  ON order_items FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );
```

### 4.13 Bảng `payments` (Người 4)

```sql
CREATE TABLE payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id),
  payment_method TEXT NOT NULL CHECK (payment_method IN ('cod', 'momo', 'vnpay')),
  amount DECIMAL(12,2) NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'processing', 'completed', 'failed', 'refunded')),
  transaction_id TEXT,
  paid_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE payments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users view own payments"
  ON payments FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users create payments"
  ON payments FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admin manage payments"
  ON payments FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );
```

### 4.14 Bảng `shipping_tracking` (Người 4)

```sql
CREATE TABLE shipping_tracking (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  status TEXT NOT NULL CHECK (status IN ('preparing', 'picked_up', 'in_transit', 'out_for_delivery', 'delivered')),
  location TEXT,
  note TEXT,
  estimated_delivery TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE shipping_tracking ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users view own shipping"
  ON shipping_tracking FOR SELECT USING (
    EXISTS (SELECT 1 FROM orders WHERE orders.id = shipping_tracking.order_id AND orders.user_id = auth.uid())
  );

CREATE POLICY "Admin manage shipping"
  ON shipping_tracking FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );
```

### 4.15 Bảng `order_status_history` (Người 4)

```sql
CREATE TABLE order_status_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  from_status TEXT,
  to_status TEXT NOT NULL,
  changed_by UUID REFERENCES profiles(id),
  note TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE order_status_history ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users view own order history"
  ON order_status_history FOR SELECT USING (
    EXISTS (SELECT 1 FROM orders WHERE orders.id = order_status_history.order_id AND orders.user_id = auth.uid())
  );

CREATE POLICY "Admin manage order history"
  ON order_status_history FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );
```

### 4.16 Bảng `reviews` (Người 5)

```sql
CREATE TABLE reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id),
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  order_id UUID REFERENCES orders(id),
  rating INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
  comment TEXT,
  is_verified_purchase BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, product_id, order_id)
);

ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view reviews"
  ON reviews FOR SELECT USING (TRUE);

CREATE POLICY "Users create own reviews"
  ON reviews FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users update own reviews"
  ON reviews FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Admin manage reviews"
  ON reviews FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );
```

### 4.17 Bảng `review_images` (Người 5)

```sql
CREATE TABLE review_images (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  review_id UUID NOT NULL REFERENCES reviews(id) ON DELETE CASCADE,
  image_url TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE review_images ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view review images"
  ON review_images FOR SELECT USING (TRUE);

CREATE POLICY "Users create own review images"
  ON review_images FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM reviews WHERE reviews.id = review_images.review_id AND reviews.user_id = auth.uid())
  );
```

### 4.18 Bảng `support_tickets` (Người 5)

```sql
CREATE TABLE support_tickets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id),
  order_id UUID REFERENCES orders(id),
  subject TEXT NOT NULL,
  description TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'open'
    CHECK (status IN ('open', 'in_progress', 'resolved', 'closed')),
  priority TEXT DEFAULT 'normal'
    CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
  admin_reply TEXT,
  replied_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE support_tickets ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own tickets"
  ON support_tickets FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users create tickets"
  ON support_tickets FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admin manage all tickets"
  ON support_tickets FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );
```

### 4.19 Bảng `inventory_logs` (Người 5)

```sql
CREATE TABLE inventory_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  variant_id UUID NOT NULL REFERENCES product_variants(id) ON DELETE CASCADE,
  change_type TEXT NOT NULL CHECK (change_type IN ('import', 'export', 'adjustment', 'order', 'return')),
  quantity_change INT NOT NULL,
  quantity_before INT NOT NULL,
  quantity_after INT NOT NULL,
  note TEXT,
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE inventory_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admin manage inventory logs"
  ON inventory_logs FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );
```

### 4.20 Bảng `ai_recommendation_logs` (Người 5)

```sql
CREATE TABLE ai_recommendation_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id),
  source_product_id UUID REFERENCES products(id),
  recommended_product_ids UUID[] NOT NULL,
  recommendation_type TEXT NOT NULL CHECK (recommendation_type IN ('similar', 'also_bought', 'trending', 'personalized')),
  score DECIMAL(5,4),
  clicked_product_id UUID REFERENCES products(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE ai_recommendation_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users view own recommendations"
  ON ai_recommendation_logs FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "System insert recommendations"
  ON ai_recommendation_logs FOR INSERT WITH CHECK (auth.uid() = user_id);
```

### 4.21 Views

```sql
-- View: User order summary (Người 4)
CREATE OR REPLACE VIEW v_user_order_summary AS
SELECT
  o.user_id,
  COUNT(o.id) AS total_orders,
  SUM(CASE WHEN o.status = 'delivered' THEN 1 ELSE 0 END) AS delivered_orders,
  SUM(CASE WHEN o.status = 'cancelled' THEN 1 ELSE 0 END) AS cancelled_orders,
  SUM(CASE WHEN o.status = 'pending' THEN 1 ELSE 0 END) AS pending_orders,
  COALESCE(SUM(CASE WHEN o.status = 'delivered' THEN o.total_amount ELSE 0 END), 0) AS total_spent
FROM orders o
GROUP BY o.user_id;

-- View: Low stock variants (Người 5)
CREATE OR REPLACE VIEW v_low_stock_variants AS
SELECT
  pv.id AS variant_id,
  p.id AS product_id,
  p.name AS product_name,
  pv.sku,
  pv.size,
  pv.color,
  pv.stock,
  pv.price
FROM product_variants pv
JOIN products p ON p.id = pv.product_id
WHERE pv.stock <= 10 AND pv.is_active = TRUE AND p.is_active = TRUE
ORDER BY pv.stock ASC;

-- View: Revenue by category (Người 5)
CREATE OR REPLACE VIEW v_revenue_by_category AS
SELECT
  c.id AS category_id,
  c.name AS category_name,
  COUNT(DISTINCT o.id) AS total_orders,
  SUM(oi.subtotal) AS total_revenue,
  SUM(oi.quantity) AS total_items_sold
FROM order_items oi
JOIN products p ON p.id = oi.product_id
JOIN categories c ON c.id = p.category_id
JOIN orders o ON o.id = oi.order_id
WHERE o.status = 'delivered'
GROUP BY c.id, c.name
ORDER BY total_revenue DESC;
```

### 4.22 Supabase Storage Buckets

```sql
-- Tạo storage buckets
INSERT INTO storage.buckets (id, name, public) VALUES ('avatars', 'avatars', true);
INSERT INTO storage.buckets (id, name, public) VALUES ('products', 'products', true);
INSERT INTO storage.buckets (id, name, public) VALUES ('reviews', 'reviews', true);
INSERT INTO storage.buckets (id, name, public) VALUES ('categories', 'categories', true);
INSERT INTO storage.buckets (id, name, public) VALUES ('brands', 'brands', true);

-- Storage policies
CREATE POLICY "Avatar upload" ON storage.objects FOR INSERT WITH CHECK (
  bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Avatar public read" ON storage.objects FOR SELECT USING (
  bucket_id = 'avatars'
);

CREATE POLICY "Product images admin only" ON storage.objects FOR INSERT WITH CHECK (
  bucket_id = 'products' AND EXISTS (
    SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'
  )
);

CREATE POLICY "Product images public read" ON storage.objects FOR SELECT USING (
  bucket_id = 'products'
);

CREATE POLICY "Review images upload" ON storage.objects FOR INSERT WITH CHECK (
  bucket_id = 'reviews' AND auth.uid() IS NOT NULL
);

CREATE POLICY "Review images public read" ON storage.objects FOR SELECT USING (
  bucket_id = 'reviews'
);
```

---

## 5. Shared Conventions & Coding Rules

### 5.1 Model Pattern (Mọi người phải tuân thủ)

```dart
import 'package:json_annotation/json_annotation.dart';

part 'example_model.g.dart';

@JsonSerializable()
class ExampleModel {
  final String id;
  final String name;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const ExampleModel({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ExampleModel.fromJson(Map<String, dynamic> json) =>
      _$ExampleModelFromJson(json);

  Map<String, dynamic> toJson() => _$ExampleModelToJson(this);

  ExampleModel copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExampleModel(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
```

### 5.2 Repository Pattern

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

class ExampleRepository {
  final SupabaseClient _client;

  ExampleRepository(this._client);

  // Table name constant
  static const String _table = 'examples';

  Future<List<ExampleModel>> getAll() async {
    final response = await _client
        .from(_table)
        .select()
        .order('created_at', ascending: false);
    return response.map((json) => ExampleModel.fromJson(json)).toList();
  }

  Future<ExampleModel> getById(String id) async {
    final response = await _client
        .from(_table)
        .select()
        .eq('id', id)
        .single();
    return ExampleModel.fromJson(response);
  }

  Future<ExampleModel> create(Map<String, dynamic> data) async {
    final response = await _client
        .from(_table)
        .insert(data)
        .select()
        .single();
    return ExampleModel.fromJson(response);
  }

  Future<ExampleModel> update(String id, Map<String, dynamic> data) async {
    final response = await _client
        .from(_table)
        .update(data)
        .eq('id', id)
        .select()
        .single();
    return ExampleModel.fromJson(response);
  }

  Future<void> delete(String id) async {
    await _client.from(_table).delete().eq('id', id);
  }
}
```

### 5.3 Provider Pattern (Riverpod)

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Repository provider
final exampleRepositoryProvider = Provider<ExampleRepository>((ref) {
  final client = Supabase.instance.client;
  return ExampleRepository(client);
});

// State provider (async)
final exampleListProvider = FutureProvider.autoDispose<List<ExampleModel>>((ref) async {
  final repo = ref.watch(exampleRepositoryProvider);
  return repo.getAll();
});

// State notifier for mutable state
final exampleStateProvider = StateNotifierProvider<ExampleNotifier, AsyncValue<List<ExampleModel>>>((ref) {
  return ExampleNotifier(ref.watch(exampleRepositoryProvider));
});

class ExampleNotifier extends StateNotifier<AsyncValue<List<ExampleModel>>> {
  final ExampleRepository _repo;

  ExampleNotifier(this._repo) : super(const AsyncValue.loading()) {
    loadData();
  }

  Future<void> loadData() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.getAll());
  }
}
```

### 5.4 Screen Pattern

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ExampleScreen extends ConsumerWidget {
  const ExampleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(exampleListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Example')),
      body: dataAsync.when(
        loading: () => const AppLoading(),
        error: (error, stack) => AppErrorWidget(
          message: error.toString(),
          onRetry: () => ref.invalidate(exampleListProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const AppEmptyState(message: 'Không có dữ liệu');
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) => _buildItem(items[index]),
          );
        },
      ),
    );
  }
}
```

### 5.5 Error Handling

```dart
// core/errors/app_exception.dart
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException(this.message, {this.code, this.originalError});

  @override
  String toString() => 'AppException: $message (code: $code)';
}

class AuthException extends AppException {
  const AuthException(super.message, {super.code, super.originalError});
}

class NetworkException extends AppException {
  const NetworkException(super.message, {super.code, super.originalError});
}

class ServerException extends AppException {
  const ServerException(super.message, {super.code, super.originalError});
}
```

### 5.6 Naming Conventions

| Loại | Convention | Ví dụ |
|------|-----------|-------|
| File | snake_case | `product_model.dart` |
| Class | PascalCase | `ProductModel` |
| Variable | camelCase | `productName` |
| Constant | camelCase | `defaultPageSize` |
| Enum | PascalCase + camelCase | `OrderStatus.pending` |
| Provider | camelCase + Provider | `productListProvider` |
| Repository | PascalCase + Repository | `ProductRepository` |
| Screen | PascalCase + Screen | `ProductDetailScreen` |

---

## 6. Branch Strategy

```
main
├── develop
│   ├── feature/core-auth-user          ← Người 1
│   ├── feature/product-catalog         ← Người 2
│   ├── feature/cart-wishlist-voucher   ← Người 3
│   ├── feature/order-payment-shipping  ← Người 4
│   └── feature/admin-review-support    ← Người 5
```

**Quy trình:**
1. Người 1 setup xong `develop` branch → push
2. Tất cả pull `develop` rồi tạo branch riêng
3. Mỗi người chỉ commit vào branch của mình
4. Merge vào `develop` theo thứ tự: **Người 1 → 2 → 3 → 4 → 5**
5. Sau mỗi lần merge, tất cả rebase branch của mình từ `develop`

---

## 7. Người 1 — Leader / Core / Auth / User

### 📌 Vai trò
Setup toàn bộ project, core infrastructure, authentication và quản lý user.

### 📌 Branch: `feature/core-auth-user`

### 📌 Bảng phụ trách: `profiles`, `addresses`

### 📌 Files phụ trách

```
lib/main.dart
lib/app.dart
lib/core/**
lib/shared/**
lib/features/auth/**
lib/features/user/**
```

> [!CAUTION]
> Người 1 là người DUY NHẤT được sửa `core/`, `shared/`, `main.dart`, `app.dart`, `pubspec.yaml`. Các người khác nếu cần thêm dependency hoặc widget dùng chung phải báo Người 1.

---

### 🤖 PROMPT CHO AI — Task 1.1: Core Setup

```
Tôi đang phát triển ứng dụng Flutter e-commerce tên "GymFit" sử dụng Supabase.
Hãy giúp tôi setup core project với các yêu cầu:

1. **Supabase Config** (`lib/core/config/supabase_config.dart`):
   - Khởi tạo Supabase client với URL và Anon Key
   - Tạo class `SupabaseConfig` với static method `initialize()`
   - Hỗ trợ đọc config từ biến môi trường

2. **App Config** (`lib/core/config/app_config.dart`):
   - Tên app: GymFit
   - Default page size: 20
   - Max image size: 5MB
   - Supported image formats: jpg, png, webp
   - Currency: VND
   - Locale: vi_VN

3. **Theme** (`lib/core/theme/`):
   - Tạo `app_colors.dart` với color palette cho app gym/fitness:
     * Primary: Dark blue/navy (#1A1A2E hoặc tương tự)
     * Secondary: Accent orange/coral
     * Background: Dark theme
     * Surface, error, success colors
   - Tạo `app_text_styles.dart` dùng Google Fonts (Inter hoặc Poppins)
   - Tạo `app_spacing.dart` với spacing constants (4, 8, 12, 16, 20, 24, 32)
   - Tạo `app_theme.dart` kết hợp tất cả thành ThemeData (cả light + dark)

4. **GoRouter** (`lib/core/router/`):
   - Tạo `route_names.dart` với tất cả route names:
     * splash, login, register, forgotPassword, resetPassword
     * home, productList, productDetail
     * cart, wishlist, checkout
     * orderHistory, orderDetail
     * profile, editProfile, addressList
     * admin (nested routes)
   - Tạo `app_router.dart`:
     * ShellRoute cho bottom navigation (Home, Cart, Wishlist, Profile)
     * Auth guard: redirect to login nếu chưa đăng nhập
     * Admin guard: redirect nếu không phải admin
   - Tạo `router_notifier.dart` để listen auth state changes

5. **Riverpod Providers** (`lib/shared/providers/`):
   - `supabase_provider.dart`: Provider cho SupabaseClient
   - `connectivity_provider.dart`: kiểm tra kết nối mạng

6. **Common Widgets** (`lib/shared/widgets/`):
   - `app_button.dart`: Primary, secondary, outline, text button variants. Có loading state.
   - `app_text_field.dart`: Custom TextField với label, hint, prefix/suffix icon, validation.
   - `app_loading.dart`: Loading indicator (shimmer hoặc circular).
   - `app_error_widget.dart`: Error display với retry button.
   - `app_snackbar.dart`: Success, error, info snackbar.
   - `app_image.dart`: Cached network image với placeholder và error.
   - `app_card.dart`: Styled card container.
   - `app_empty_state.dart`: Empty state với icon và message.
   - `app_dialog.dart`: Confirm dialog.
   - `app_bottom_sheet.dart`: Styled bottom sheet.
   - `price_text.dart`: Format giá VND (ví dụ: 1.500.000₫).
   - `rating_stars.dart`: Hiển thị rating sao.
   - `shimmer_loading.dart`: Shimmer placeholder loading.

7. **Error Handling** (`lib/core/errors/`):
   - `app_exception.dart`: Custom exception classes (AppException, AuthException, NetworkException, ServerException)
   - `error_handler.dart`: Global error handler, convert Supabase errors thành AppException
   - `failure.dart`: Failure model cho error state

8. **Utils** (`lib/core/utils/`):
   - `validators.dart`: Email, password, phone validators
   - `formatters.dart`: Currency (VND), date formatters
   - `extensions.dart`: String, DateTime, BuildContext extensions
   - `helpers.dart`: Debounce, image compression helpers

9. **main.dart & app.dart**:
   - Khởi tạo Supabase, WidgetsFlutterBinding
   - Wrap app với ProviderScope
   - MaterialApp.router với GoRouter
   - Apply theme

Tech stack:
- flutter_riverpod cho state management
- go_router cho navigation
- supabase_flutter cho backend
- google_fonts cho typography
- cached_network_image cho image caching
- shimmer cho loading effects

Hãy viết code đầy đủ, có comment tiếng Việt giải thích. Code phải production-ready.
```

---

### 🤖 PROMPT CHO AI — Task 1.2: Authentication

```
Tiếp tục project GymFit Flutter + Supabase.
Hãy tạo module Authentication hoàn chỉnh:

**Folder**: `lib/features/auth/`

**1. Model** (`models/user_model.dart`):
- UserModel mapping với bảng `profiles`:
  * id (UUID), fullName, phone, avatarUrl, role, createdAt, updatedAt
- Sử dụng json_serializable
- Có factory fromJson, toJson, copyWith

**2. Repository** (`data/auth_repository.dart`):
- `signUp(email, password, fullName)`: Đăng ký + auto tạo profile
- `signIn(email, password)`: Đăng nhập
- `signOut()`: Đăng xuất
- `forgotPassword(email)`: Gửi email reset password
- `resetPassword(newPassword)`: Đổi mật khẩu mới
- `getCurrentUser()`: Lấy user hiện tại
- `onAuthStateChange()`: Stream<AuthState> để listen auth changes
- Error handling: catch AuthException từ Supabase, convert thành AppException

**3. Providers** (`providers/auth_provider.dart`):
- `authRepositoryProvider`: Provider<AuthRepository>
- `authStateProvider`: StreamProvider<AuthState> listen auth changes
- `currentUserProvider`: FutureProvider<UserModel?> lấy user hiện tại
- `authNotifierProvider`: StateNotifierProvider cho login/register state

**4. Screens**:
- `login_screen.dart`:
  * Form với email + password
  * Validate input
  * Nút "Đăng nhập"
  * Link "Quên mật khẩu?"
  * Link "Chưa có tài khoản? Đăng ký"
  * Loading state khi đang xử lý
  * Error handling + show snackbar
  * UI đẹp theo theme đã setup

- `register_screen.dart`:
  * Form: fullName, email, password, confirmPassword
  * Validate: tên tối thiểu 2 ký tự, email hợp lệ, password >= 6 ký tự, password khớp
  * Nút "Đăng ký"
  * Link "Đã có tài khoản? Đăng nhập"
  * Loading + error handling

- `forgot_password_screen.dart`:
  * Form chỉ có email
  * Nút "Gửi link đặt lại mật khẩu"
  * Hiển thị thông báo thành công

- `reset_password_screen.dart`:
  * Form: mật khẩu mới + xác nhận mật khẩu
  * Validate + submit

**Lưu ý**:
- Sử dụng AppTextField, AppButton từ shared/widgets
- Sử dụng GoRouter để navigate
- Handle auth state changes trong router_notifier để auto redirect
- UI phải responsive, đẹp, có animation nhẹ
- Dùng ref.watch / ref.read đúng cách với Riverpod
```

---

### 🤖 PROMPT CHO AI — Task 1.3: User Profile & Address

```
Tiếp tục project GymFit Flutter + Supabase.
Tạo module User hoàn chỉnh:

**Folder**: `lib/features/user/`

**1. Models**:
- `profile_model.dart`: Mapping bảng profiles
  * id, fullName, phone, avatarUrl, role, createdAt, updatedAt
  * fromJson, toJson, copyWith

- `address_model.dart`: Mapping bảng addresses
  * id, userId, fullName, phone, addressLine, ward, district, city, isDefault, createdAt, updatedAt
  * fromJson, toJson, copyWith
  * getter `fullAddress` trả về chuỗi đầy đủ

**2. Repositories**:
- `profile_repository.dart`:
  * `getProfile(userId)`: Lấy profile
  * `updateProfile(userId, data)`: Cập nhật profile (fullName, phone)
  * `uploadAvatar(userId, file)`: Upload avatar lên Supabase Storage bucket 'avatars', trả về URL
  * `updateAvatarUrl(userId, url)`: Cập nhật avatar_url trong profiles

- `address_repository.dart`:
  * `getAddresses(userId)`: Lấy danh sách địa chỉ
  * `getDefaultAddress(userId)`: Lấy địa chỉ mặc định
  * `createAddress(data)`: Thêm địa chỉ mới
  * `updateAddress(id, data)`: Sửa địa chỉ
  * `deleteAddress(id)`: Xóa địa chỉ
  * `setDefaultAddress(userId, addressId)`: Set mặc định (reset tất cả rồi set 1 cái)

**3. Providers**:
- `profile_provider.dart`:
  * `profileProvider`: FutureProvider load profile
  * `profileNotifierProvider`: StateNotifier cho update profile
  * `avatarUploadProvider`: StateProvider cho avatar upload state

- `address_provider.dart`:
  * `addressListProvider`: FutureProvider load addresses
  * `defaultAddressProvider`: FutureProvider load default address
  * `addressNotifierProvider`: StateNotifier cho CRUD address

**4. Screens**:
- `profile_screen.dart`:
  * Hiển thị avatar (CircleAvatar), tên, email, phone
  * Nút "Chỉnh sửa hồ sơ"
  * Nút "Địa chỉ của tôi"
  * Nút "Đơn hàng của tôi" (navigate to order history)
  * Nút "Đăng xuất"
  * Nếu là admin → hiện thêm nút "Quản trị"

- `edit_profile_screen.dart`:
  * Avatar có nút camera để chọn ảnh từ gallery
  * Upload ảnh lên Supabase Storage
  * Form: fullName, phone
  * Nút lưu
  * Loading state

- `address_list_screen.dart`:
  * Danh sách địa chỉ dạng card
  * Mỗi card hiện: tên, SĐT, địa chỉ, badge "Mặc định" nếu isDefault
  * Swipe để xóa hoặc icon delete
  * Nút edit mỗi address
  * FAB thêm địa chỉ mới
  * Bottom sheet / dialog form thêm/sửa địa chỉ
  * Nút "Đặt làm mặc định"

**Lưu ý**:
- Dùng image_picker để chọn ảnh
- Avatar upload lên bucket 'avatars' với path: '{userId}/{timestamp}.jpg'
- Dùng CachedNetworkImage cho avatar
- Sử dụng shared widgets (AppButton, AppTextField, AppCard, etc.)
```

---

## 8. Người 2 — Product Catalog / Home / Search

### 📌 Vai trò
Xây dựng toàn bộ product models/repositories (dùng chung cho cả team) và UI trang chủ, chi tiết sản phẩm, tìm kiếm.

### 📌 Branch: `feature/product-catalog`

### 📌 Bảng phụ trách: `categories`, `brands`, `products`, `product_images`, `product_variants`

### 📌 Files phụ trách

```
lib/features/products/**
```

> [!IMPORTANT]
> **Người 2 phải viết model và repository CHUẨN** vì Người 3, 4, 5 sẽ import và sử dụng lại. Đặc biệt:
> - `ProductModel` phải có relation với `ProductVariantModel`, `ProductImageModel`, `CategoryModel`, `BrandModel`
> - `ProductRepository` phải có các method mà Người 3 (cart), Người 4 (order), Người 5 (admin, review) cần dùng
> - Code phải clean, có comment, dễ extend

---

### 🤖 PROMPT CHO AI — Task 2.1: Product Models & Repositories (SHARED)

```
Tôi đang phát triển ứng dụng Flutter e-commerce "GymFit" với Supabase.
Hãy tạo các models và repositories cho Product module.

**QUAN TRỌNG**: Các models và repos này sẽ được CHIA SẺ cho nhiều module khác (cart, order, admin, review) nên phải viết chuẩn, dễ sử dụng.

**Folder**: `lib/features/products/`

**1. Models** (tất cả dùng json_serializable):

- `category_model.dart`:
  * id, name, slug, imageUrl, description, sortOrder, isActive, createdAt, updatedAt
  * fromJson, toJson, copyWith

- `brand_model.dart`:
  * id, name, slug, logoUrl, description, isActive, createdAt, updatedAt
  * fromJson, toJson, copyWith

- `product_image_model.dart`:
  * id, productId, imageUrl, sortOrder, createdAt
  * fromJson, toJson

- `product_variant_model.dart`:
  * id, productId, sku, size, color, price, stock, isActive, createdAt, updatedAt
  * fromJson, toJson, copyWith
  * getter `displayName` → "Size: M - Màu: Đen"
  * getter `isInStock` → stock > 0
  * getter `formattedPrice` → "1.500.000₫"

- `product_model.dart`:
  * id, name, slug, description
  * categoryId, brandId
  * basePrice, isActive, isFeatured
  * avgRating, totalReviews, totalSold
  * createdAt, updatedAt
  * **Relations** (nullable, populated khi join):
    - category (CategoryModel?)
    - brand (BrandModel?)
    - images (List<ProductImageModel>?)
    - variants (List<ProductVariantModel>?)
  * fromJson, toJson, copyWith
  * getter `mainImage` → images?.firstOrNull?.imageUrl
  * getter `priceRange` → "500.000₫ - 1.200.000₫" (tính từ variants)
  * getter `minPrice` → giá thấp nhất trong variants
  * getter `maxPrice` → giá cao nhất trong variants
  * getter `totalStock` → tổng stock tất cả variants
  * getter `formattedBasePrice` → "1.500.000₫"

**2. Repositories**:

- `category_repository.dart`:
  * `getAll()`: Lấy tất cả categories active, order by sort_order
  * `getById(id)`: Lấy 1 category
  * `create(data)`: Admin tạo category mới
  * `update(id, data)`: Admin cập nhật
  * `delete(id)`: Admin xóa (soft delete: is_active = false)

- `brand_repository.dart`:
  * `getAll()`: Lấy tất cả brands active
  * `getById(id)`: Lấy 1 brand
  * `create(data)`: Admin tạo
  * `update(id, data)`: Admin cập nhật
  * `delete(id)`: Admin xóa (soft delete)

- `product_repository.dart`:
  * `getProducts({int page, int pageSize, String? categoryId, String? brandId, double? minPrice, double? maxPrice, String? sortBy, bool? ascending, String? search})`:
    - Query products kèm join category, brand
    - Hỗ trợ filter theo category, brand, price range
    - Hỗ trợ sort theo: price, rating, newest, sold
    - Hỗ trợ search theo name
    - Phân trang
  * `getProductById(id)`: Lấy chi tiết sản phẩm kèm images, variants, category, brand
  * `getFeaturedProducts({int limit})`: Sản phẩm nổi bật
  * `getBestSellers({int limit})`: Sản phẩm bán chạy (order by total_sold)
  * `getNewArrivals({int limit})`: Sản phẩm mới (order by created_at)
  * `getRelatedProducts(productId, categoryId, {int limit})`: Sản phẩm liên quan cùng category
  * `getProductsByIds(List<String> ids)`: Lấy nhiều sản phẩm theo list ID (cho cart, order)
  * `searchProducts(query)`: Full-text search
  * **Admin methods**:
    - `createProduct(data)`: Tạo product mới
    - `updateProduct(id, data)`: Cập nhật product
    - `deleteProduct(id)`: Soft delete
    - `addProductImage(productId, imageUrl, sortOrder)`: Thêm ảnh
    - `removeProductImage(imageId)`: Xóa ảnh
    - `createVariant(data)`: Tạo variant
    - `updateVariant(id, data)`: Cập nhật variant
    - `deleteVariant(id)`: Soft delete variant
    - `updateStock(variantId, newStock)`: Cập nhật tồn kho
    - `updateProductRating(productId, avgRating, totalReviews)`: Cập nhật rating (gọi từ review module)

**Lưu ý query Supabase**:
- Dùng `.select('*, category:categories(*), brand:brands(*), images:product_images(*), variants:product_variants(*)')` cho product detail
- Dùng `.select('*, category:categories(id, name), brand:brands(id, name)')` cho product list (lightweight)
- Pagination: dùng `.range(from, to)`
- Sort: dùng `.order(column, ascending: bool)`
- Filter: dùng `.eq()`, `.gte()`, `.lte()`, `.ilike()` cho search

Viết code đầy đủ, có comment tiếng Việt. Đảm bảo error handling chuẩn.
```

---

### 🤖 PROMPT CHO AI — Task 2.2: Providers

```
Tiếp tục module Product cho GymFit.
Tạo các Riverpod providers:

**Folder**: `lib/features/products/providers/`

**1. `product_provider.dart`**:
- `productRepositoryProvider`: Provider<ProductRepository>
- `featuredProductsProvider`: FutureProvider lấy featured products (limit 10)
- `bestSellersProvider`: FutureProvider lấy best sellers (limit 10)
- `newArrivalsProvider`: FutureProvider lấy new arrivals (limit 10)
- `productDetailProvider(String id)`: FutureProvider.family lấy chi tiết sản phẩm
- `relatedProductsProvider({productId, categoryId})`: FutureProvider lấy related products
- `productListProvider`: StateNotifierProvider cho danh sách sản phẩm có filter/sort/pagination

**2. `category_provider.dart`**:
- `categoryRepositoryProvider`: Provider<CategoryRepository>
- `categoryListProvider`: FutureProvider lấy tất cả categories
- `selectedCategoryProvider`: StateProvider<String?> category đang chọn

**3. `brand_provider.dart`**:
- `brandRepositoryProvider`: Provider<BrandRepository>
- `brandListProvider`: FutureProvider lấy tất cả brands
- `selectedBrandProvider`: StateProvider<String?> brand đang chọn

**4. `search_provider.dart`**:
- `searchQueryProvider`: StateProvider<String> query tìm kiếm
- `searchResultsProvider`: FutureProvider tìm kiếm sản phẩm
- `searchFiltersProvider`: StateNotifierProvider cho bộ lọc (category, brand, price range, sort)

**ProductListNotifier** cần có:
- `loadProducts()`: Load trang đầu
- `loadMore()`: Load thêm (pagination)
- `applyFilter(FilterModel)`: Áp dụng bộ lọc
- `clearFilter()`: Xóa bộ lọc
- `changeSort(SortType)`: Đổi sắp xếp
- State chứa: products, isLoading, hasMore, currentPage, currentFilter

Sử dụng Riverpod 2.x syntax. Dùng autoDispose khi thích hợp.
```

---

### 🤖 PROMPT CHO AI — Task 2.3: Home Screen

```
Tiếp tục module Product cho GymFit.
Tạo Home Screen:

**File**: `lib/features/products/screens/home_screen.dart`

**Layout** (ScrollView):
1. **App Bar**: Logo "GymFit" bên trái, icon giỏ hàng (có badge số lượng) + icon thông báo bên phải
2. **Search Bar**: Thanh tìm kiếm (tap → navigate to search screen). Rounded, có icon search.
3. **Banner Carousel**: Slider 3-4 banner quảng cáo (có thể dùng placeholder images). Auto-scroll, có dot indicators.
4. **Category Section**:
   - Tiêu đề "Danh mục"
   - Horizontal scroll grid 2 rows × n columns
   - Mỗi item: icon/image tròn + tên category bên dưới
5. **Featured Products**:
   - Tiêu đề "Sản phẩm nổi bật" + "Xem tất cả"
   - Horizontal scroll list product cards
6. **Brand Section**:
   - Tiêu đề "Thương hiệu"
   - Horizontal scroll: logo brand cards
7. **Best Sellers**:
   - Tiêu đề "Bán chạy nhất" + "Xem tất cả"
   - Grid 2 columns product cards
8. **New Arrivals**:
   - Tiêu đề "Hàng mới về" + "Xem tất cả"
   - Horizontal scroll list

**Product Card Widget** (tái sử dụng):
- Ảnh sản phẩm (rounded corners, aspect ratio 1:1)
- Tên sản phẩm (max 2 lines)
- Giá (formatted VND, nếu có range thì hiện range)
- Rating stars + số reviews
- Badge "Mới" hoặc "Nổi bật" nếu có
- Nút heart (wishlist toggle)
- Card có shadow, rounded corners, hover/tap effect

**Shimmer Loading**: Khi đang load, hiện shimmer placeholder giống layout thật.

Dùng RefreshIndicator cho pull-to-refresh.
Dùng các shared widgets đã có.
Navigate bằng GoRouter.
UI đẹp, modern, theo theme đã setup.
```

---

### 🤖 PROMPT CHO AI — Task 2.4: Product Detail & List & Search Screens

```
Tiếp tục module Product cho GymFit.
Tạo các màn hình:

**1. Product List Screen** (`product_list_screen.dart`):
- Nhận tham số: categoryId?, brandId?, searchQuery?
- AppBar hiện tên category/brand hoặc "Tất cả sản phẩm"
- Filter bar (ngang): Danh mục | Thương hiệu | Giá | Sắp xếp
  * Tap mỗi filter → hiện bottom sheet chọn
  * Chip hiện active filters, có nút X để xóa
- Grid 2 columns product cards
- Infinite scroll (load more khi cuộn gần cuối)
- Pull to refresh
- Empty state khi không có kết quả
- Shimmer loading

**2. Product Detail Screen** (`product_detail_screen.dart`):
- **Image Carousel**: Slider ảnh sản phẩm, full width, có dot indicator, tap để zoom
- **Info Section**:
  * Tên sản phẩm (heading)
  * Rating: stars + "(123 đánh giá)" + "Đã bán 456"
  * Giá: hiện giá theo variant đang chọn
- **Variant Selector**:
  * Chọn Size: chip/button list (S, M, L, XL, ...)
  * Chọn Màu: color chips
  * Hiện stock còn lại: "Còn 15 sản phẩm"
  * Giá thay đổi theo variant chọn
- **Description**: Mô tả sản phẩm (expandable)
- **Brand & Category**: Hiện tên brand, tên category
- **Reviews Section**:
  * Rating tổng quan: avg rating lớn + distribution bars
  * 3 review mới nhất (preview)
  * Nút "Xem tất cả đánh giá"
- **Related Products**: Horizontal scroll product cards
- **Bottom Bar** (fixed):
  * Nút chat/support icon
  * Nút "Thêm vào giỏ" (outline)
  * Nút "Mua ngay" (filled)
  * Disable nếu hết hàng

**3. Search Screen** (`search_screen.dart`):
- Auto-focus search field
- Search history (local storage)
- Gợi ý tìm kiếm khi gõ (debounce 300ms)
- Kết quả tìm kiếm dạng list hoặc grid (toggle)
- Filter + sort giống product list
- Nút xóa lịch sử tìm kiếm

Tất cả screens dùng Riverpod providers đã tạo.
Navigate bằng GoRouter.
Dùng shared widgets.
UI premium, animations mượt.
```

---

## 9. Người 3 — Cart / Wishlist / Voucher

### 📌 Vai trò
Xây dựng module giỏ hàng, danh sách yêu thích, và mã giảm giá.

### 📌 Branch: `feature/cart-wishlist-voucher`

### 📌 Bảng phụ trách: `cart_items`, `wishlist_items`, `vouchers`

### 📌 Files phụ trách

```
lib/features/cart/**
lib/features/wishlist/**
lib/features/voucher/**
```

> [!WARNING]
> **Người 3 KHÔNG tự query bảng products/variants.** Luôn import và sử dụng `ProductRepository`, `ProductModel`, `ProductVariantModel` từ `lib/features/products/` do Người 2 viết.

---

### 🤖 PROMPT CHO AI — Task 3.1: Cart Module

```
Tôi đang phát triển module Cart cho app GymFit (Flutter + Supabase + Riverpod).

**QUAN TRỌNG**: Module này sử dụng ProductModel, ProductVariantModel, ProductRepository
từ `lib/features/products/` (đã được viết sẵn). KHÔNG tự query bảng products/product_variants.

**Folder**: `lib/features/cart/`

**1. Model** (`models/cart_item_model.dart`):
```dart
@JsonSerializable()
class CartItemModel {
  final String id;
  final String userId;
  final String productId;
  final String variantId;
  final int quantity;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Relations (populated khi join)
  final ProductModel? product;
  final ProductVariantModel? variant;

  // Getters
  double get itemTotal => (variant?.price ?? 0) * quantity;
  String get formattedTotal => formatCurrency(itemTotal);
  bool get isInStock => (variant?.stock ?? 0) >= quantity;
}
```

**2. Repository** (`data/cart_repository.dart`):
- `getCartItems(userId)`:
  * Query cart_items join products và product_variants
  * Select: `*, product:products(*, category:categories(id, name), brand:brands(id, name), images:product_images(*)), variant:product_variants(*)`
  * Return List<CartItemModel> có đầy đủ product info

- `addToCart(userId, productId, variantId, quantity)`:
  * Upsert: nếu đã có variant này trong cart → tăng quantity
  * Nếu chưa có → insert mới
  * Kiểm tra stock trước khi thêm

- `updateQuantity(cartItemId, newQuantity)`:
  * Validate: newQuantity > 0 và <= stock
  * Update quantity

- `removeItem(cartItemId)`:
  * Delete cart item

- `clearCart(userId)`:
  * Delete tất cả cart items của user (sau khi checkout thành công)

- `getCartCount(userId)`:
  * Count số items trong cart (hiện badge)

- `checkStockAvailability(userId)`:
  * Kiểm tra tất cả items trong cart còn đủ stock không
  * Return danh sách items hết hàng hoặc không đủ số lượng

**3. Providers** (`providers/cart_provider.dart`):
- `cartRepositoryProvider`: Provider<CartRepository>
- `cartItemsProvider`: StateNotifierProvider<CartNotifier, AsyncValue<List<CartItemModel>>>
- `cartCountProvider`: Provider<int> số lượng items
- `cartTotalProvider`: Provider<double> tổng tiền
- `cartSummaryProvider`: Provider<CartSummary> tóm tắt (subtotal, itemCount)

**CartNotifier methods**:
- `loadCart()`: Load cart items
- `addToCart(productId, variantId, quantity)`: Thêm vào giỏ
- `updateQuantity(cartItemId, quantity)`: Cập nhật số lượng
- `removeItem(cartItemId)`: Xóa item
- `clearCart()`: Xóa hết (sau checkout)
- `checkStock()`: Kiểm tra stock

**4. Screen** (`screens/cart_screen.dart`):
- **Empty State**: Giỏ hàng trống + nút "Tiếp tục mua sắm"
- **Cart Item List**:
  * Ảnh sản phẩm (nhỏ, vuông)
  * Tên sản phẩm
  * Variant info (Size: M, Màu: Đen)
  * Giá đơn vị
  * Quantity selector: nút (-) [số lượng] nút (+)
  * Thành tiền
  * Nút xóa (icon delete hoặc swipe)
  * Cảnh báo nếu hết hàng hoặc stock không đủ
- **Cart Summary** (bottom section):
  * Tổng số lượng: "3 sản phẩm"
  * Tạm tính: 2.500.000₫
  * Nút "Áp mã giảm giá" → navigate to voucher screen
  * Nếu đã áp voucher: hiện voucher code + discount amount + nút xóa
  * Tổng cộng: 2.200.000₫
  * Nút "Thanh toán" (full width, primary color)
    - Disable nếu cart rỗng hoặc có item hết hàng
    - Khi tap: checkStock → nếu OK → navigate to checkout (truyền cart data + voucher data)

**Lưu ý**:
- Quantity selector: min = 1, max = stock
- Real-time update tổng tiền khi thay đổi quantity
- Pull to refresh
- Shimmer loading
```

---

### 🤖 PROMPT CHO AI — Task 3.2: Wishlist Module

```
Tiếp tục module Wishlist cho GymFit.

**Folder**: `lib/features/wishlist/`

**1. Model** (`models/wishlist_item_model.dart`):
- id, userId, productId, createdAt
- product (ProductModel?) — populated khi join
- fromJson, toJson

**2. Repository** (`data/wishlist_repository.dart`):
- `getWishlistItems(userId)`: Query join products (kèm images, category, brand)
- `addToWishlist(userId, productId)`: Insert, handle duplicate
- `removeFromWishlist(userId, productId)`: Delete
- `isInWishlist(userId, productId)`: Check exists
- `getWishlistCount(userId)`: Count

**3. Providers** (`providers/wishlist_provider.dart`):
- `wishlistRepositoryProvider`
- `wishlistItemsProvider`: StateNotifierProvider
- `isInWishlistProvider(productId)`: Provider.family<bool, String> — dùng ở product card
- `wishlistCountProvider`

**WishlistNotifier methods**:
- `loadWishlist()`
- `toggleWishlist(productId)`: Thêm nếu chưa có, xóa nếu đã có
- `removeFromWishlist(productId)`

**4. Screen** (`screens/wishlist_screen.dart`):
- AppBar: "Yêu thích" + badge count
- Grid 2 columns product cards (giống product list)
- Mỗi card có nút heart (filled) — tap để xóa khỏi wishlist
- Nút "Thêm vào giỏ" trên mỗi card
- Empty state: "Chưa có sản phẩm yêu thích"
- Pull to refresh, shimmer loading

**Tích hợp**: Nút heart trên Product Card (home, product list, product detail) phải gọi `toggleWishlist` từ wishlist provider. Người 2 sẽ import wishlist provider vào product card widget.
```

---

### 🤖 PROMPT CHO AI — Task 3.3: Voucher Module

```
Tiếp tục module Voucher cho GymFit.

**Folder**: `lib/features/voucher/`

**1. Model** (`models/voucher_model.dart`):
```dart
@JsonSerializable()
class VoucherModel {
  final String id;
  final String code;
  final String? description;
  final String discountType; // 'percentage' | 'fixed'
  final double discountValue;
  final double minOrderAmount;
  final double? maxDiscountAmount;
  final int? usageLimit;
  final int usedCount;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Getters
  bool get isValid => isActive && DateTime.now().isAfter(startDate) && DateTime.now().isBefore(endDate);
  bool get isUsageLimitReached => usageLimit != null && usedCount >= usageLimit!;
  bool get canUse => isValid && !isUsageLimitReached;

  String get discountDisplay {
    if (discountType == 'percentage') return '${discountValue.toInt()}%';
    return formatCurrency(discountValue);
  }

  double calculateDiscount(double orderAmount) {
    if (!canUse || orderAmount < minOrderAmount) return 0;
    double discount;
    if (discountType == 'percentage') {
      discount = orderAmount * (discountValue / 100);
    } else {
      discount = discountValue;
    }
    if (maxDiscountAmount != null && discount > maxDiscountAmount!) {
      discount = maxDiscountAmount!;
    }
    return discount;
  }
}
```

**2. Repository** (`data/voucher_repository.dart`):
- `getAvailableVouchers()`: Lấy vouchers đang active + trong thời hạn
- `getVoucherByCode(code)`: Tìm voucher theo code
- `validateVoucher(code, orderAmount)`: Validate + return discount amount
- `incrementUsedCount(voucherId)`: Tăng used_count sau khi dùng

**3. Providers** (`providers/voucher_provider.dart`):
- `voucherRepositoryProvider`
- `availableVouchersProvider`: FutureProvider lấy danh sách vouchers
- `appliedVoucherProvider`: StateProvider<VoucherModel?> — voucher đang áp dụng
- `discountAmountProvider`: Provider<double> — số tiền giảm

**4. Screen** (`screens/voucher_list_screen.dart`):
- Nhận param `orderAmount` từ cart screen
- Ô nhập mã voucher + nút "Áp dụng"
  * Validate code → hiện kết quả
- Danh sách vouchers khả dụng:
  * Card mỗi voucher:
    - Icon/badge giảm giá
    - Code: "GYMFIT20"
    - Mô tả: "Giảm 20% tối đa 200.000₫"
    - Điều kiện: "Đơn tối thiểu 500.000₫"
    - Thời hạn: "HSD: 30/06/2026"
    - Nút "Áp dụng"
    - Disable + thông báo nếu không đủ điều kiện
- Khi áp dụng thành công → pop về cart screen với voucher data

**Data truyền sang Người 4 (Checkout)**:
Khi navigate từ Cart → Checkout, truyền object chứa:
```dart
class CheckoutData {
  final List<CartItemModel> cartItems;
  final VoucherModel? voucher;
  final double subtotal;
  final double discountAmount;
  final double total;
}
```

**Lưu ý**: Người 4 sẽ nhận `CheckoutData` này để tạo order.
```

---

## 10. Người 4 — Checkout / Order / Payment / Shipping

### 📌 Vai trò
Xây dựng checkout flow, quản lý đơn hàng, thanh toán, và tracking shipping.

### 📌 Branch: `feature/order-payment-shipping`

### 📌 Bảng phụ trách: `orders`, `order_items`, `payments`, `shipping_tracking`, `order_status_history`

### 📌 View phụ trách: `v_user_order_summary`

### 📌 Files phụ trách

```
lib/features/checkout/**
lib/features/orders/**
lib/features/payments/**
lib/features/shipping/**
```

> [!WARNING]
> **Người 4 KHÔNG tự query bảng products, cart_items, vouchers.** Nhận data từ Người 3 thông qua `CheckoutData` object khi navigate. Dùng `ProductRepository` từ Người 2 nếu cần query product info.

---

### 🤖 PROMPT CHO AI — Task 4.1: Checkout Module

```
Tôi đang phát triển module Checkout cho app GymFit (Flutter + Supabase + Riverpod).

**Context**: Module này NHẬN dữ liệu từ Cart module (Người 3):
```dart
class CheckoutData {
  final List<CartItemModel> cartItems; // Danh sách sản phẩm trong giỏ
  final VoucherModel? voucher;          // Voucher đã áp dụng (nullable)
  final double subtotal;                // Tạm tính
  final double discountAmount;          // Số tiền giảm
  final double total;                   // Tổng cộng (chưa tính phí ship)
}
```

**Folder**: `lib/features/checkout/`

**1. Model** (`models/checkout_model.dart`):
- CheckoutData class (như trên)
- CheckoutState: giữ trạng thái checkout (selectedAddress, paymentMethod, note, shippingFee)

**2. Repository** (`data/checkout_repository.dart`):
- `createOrder(CheckoutRequest)`:
  * Insert vào bảng `orders` với:
    - user_id, address_id, voucher_id, voucher_code
    - subtotal, discount_amount, shipping_fee, total_amount
    - status: 'pending'
    - note
  * Insert vào bảng `order_items` (batch insert):
    - order_id, product_id, variant_id
    - product_name (snapshot tên lúc đặt), variant_info
    - price, quantity, subtotal
  * Insert vào `order_status_history`:
    - from_status: null, to_status: 'pending'
  * Update `vouchers.used_count` += 1 (nếu có voucher)
  * Update `product_variants.stock` -= quantity (cho mỗi item)
  * Clear cart (delete cart_items của user)
  * Tất cả trong 1 transaction (hoặc gọi lần lượt, handle rollback)

- `calculateShippingFee(addressId)`: Mock tính phí ship (30.000₫ default)

**3. Providers** (`providers/checkout_provider.dart`):
- `checkoutRepositoryProvider`
- `checkoutDataProvider`: StateProvider<CheckoutData?> — nhận từ cart
- `selectedAddressProvider`: StateProvider<AddressModel?> — địa chỉ giao hàng
- `paymentMethodProvider`: StateProvider<String> — 'cod' | 'momo' | 'vnpay'
- `shippingFeeProvider`: Provider<double>
- `orderNoteProvider`: StateProvider<String>
- `checkoutTotalProvider`: Provider<double> — total + shippingFee - discount
- `createOrderProvider`: FutureProvider để gọi createOrder

**4. Screen** (`screens/checkout_screen.dart`):
- **Shipping Address Section**:
  * Hiện địa chỉ mặc định (nếu có)
  * Nút "Thay đổi" → navigate to address selection
  * Nếu chưa có → nút "Thêm địa chỉ"
- **Order Items Section**:
  * List items đã chọn (ảnh, tên, variant, qty, price) — read-only
- **Voucher Section**:
  * Hiện voucher đã áp (nếu có): code + discount amount
  * Nếu chưa áp → nút "Chọn mã giảm giá"
- **Payment Method Section**:
  * Radio buttons: COD, Momo, VNPay
  * Icon + tên phương thức
- **Order Note**:
  * TextField nhập ghi chú (optional)
- **Order Summary** (card):
  * Tạm tính: xxx₫
  * Giảm giá: -xxx₫
  * Phí vận chuyển: xxx₫
  * **Tổng cộng: xxx₫** (bold, lớn)
- **Bottom Bar**:
  * Tổng cộng: xxx₫
  * Nút "Đặt hàng" (primary, full width)
  * Disable nếu chưa chọn địa chỉ
  * Loading state khi đang xử lý

**Flow sau khi đặt hàng thành công**:
1. Tạo order + order items
2. Giảm stock
3. Clear cart
4. Tăng voucher used_count
5. Navigate to payment screen (nếu Momo/VNPay) hoặc order success screen (nếu COD)
6. Hiện dialog/screen "Đặt hàng thành công!"
```

---

### 🤖 PROMPT CHO AI — Task 4.2: Order Module

```
Tiếp tục module Order cho GymFit.

**Folder**: `lib/features/orders/`

**1. Models**:
- `order_model.dart`:
  * id, userId, addressId, voucherId, voucherCode
  * subtotal, discountAmount, shippingFee, totalAmount
  * status (enum OrderStatus: pending, confirmed, processing, shipping, delivered, cancelled, returned)
  * note, createdAt, updatedAt
  * Relations: address (AddressModel?), items (List<OrderItemModel>?), payment (PaymentModel?)
  * getter `statusText` → "Chờ xác nhận", "Đang giao", ...
  * getter `statusColor` → Color theo status

- `order_item_model.dart`:
  * id, orderId, productId, variantId
  * productName, variantInfo, price, quantity, subtotal
  * createdAt

- `order_status_history_model.dart`:
  * id, orderId, fromStatus, toStatus, changedBy, note, createdAt

**2. Repository** (`data/order_repository.dart`):
- `getOrders(userId, {String? status, int page, int pageSize})`:
  * Query orders kèm order_items
  * Filter by status nếu có
  * Order by created_at DESC
  * Phân trang

- `getOrderById(orderId)`:
  * Query order kèm order_items, payment, shipping_tracking, status_history

- `cancelOrder(orderId, userId)`:
  * Update status → 'cancelled'
  * Insert order_status_history
  * Hoàn lại stock (tăng product_variants.stock)
  * Chỉ cho phép cancel khi status là 'pending' hoặc 'confirmed'

- `getOrderStatusHistory(orderId)`: Lấy lịch sử trạng thái

- `getOrderSummary(userId)`: Query v_user_order_summary

**Admin methods**:
- `getAllOrders({status, page, pageSize})`: Lấy tất cả đơn (admin)
- `updateOrderStatus(orderId, newStatus, adminId, note?)`:
  * Update order.status
  * Insert order_status_history
  * Nếu status = 'shipping' → tạo shipping_tracking entry

**3. Providers** (`providers/order_provider.dart`):
- `orderRepositoryProvider`
- `orderListProvider`: StateNotifierProvider (support filter by status)
- `orderDetailProvider(orderId)`: FutureProvider.family
- `orderStatusHistoryProvider(orderId)`: FutureProvider.family
- `orderSummaryProvider`: FutureProvider

**4. Screens**:
- `order_history_screen.dart`:
  * Tab bar filter: Tất cả | Chờ xác nhận | Đang xử lý | Đang giao | Đã giao | Đã hủy
  * List orders:
    - Order ID (short), ngày đặt
    - Sản phẩm đầu tiên (ảnh + tên) + "và X sản phẩm khác"
    - Tổng tiền
    - Badge trạng thái (có màu)
    - Nút "Xem chi tiết"
    - Nút "Hủy đơn" (chỉ hiện khi pending/confirmed)
  * Empty state, shimmer, pagination

- `order_detail_screen.dart`:
  * **Status Timeline**: Visual timeline hiện trạng thái đơn hàng
    - Mỗi step: icon + tên trạng thái + thời gian
    - Step hiện tại highlighted
  * **Shipping Info**: Địa chỉ giao hàng
  * **Order Items**: List sản phẩm (ảnh, tên, variant, qty, price)
  * **Payment Info**: Phương thức thanh toán, trạng thái
  * **Order Summary**: Subtotal, discount, shipping, total
  * **Actions**:
    - Nút "Hủy đơn" (nếu pending/confirmed)
    - Nút "Mua lại" → thêm tất cả items vào cart
    - Nút "Đánh giá" (nếu delivered) → navigate to review
    - Nút "Liên hệ hỗ trợ" → navigate to support
  * **Tracking Button**: "Theo dõi đơn hàng" → navigate to shipping tracking
```

---

### 🤖 PROMPT CHO AI — Task 4.3: Payment Module

```
Tiếp tục module Payment cho GymFit.

**Folder**: `lib/features/payments/`

**1. Model** (`models/payment_model.dart`):
- id, orderId, userId
- paymentMethod ('cod' | 'momo' | 'vnpay')
- amount, status ('pending' | 'processing' | 'completed' | 'failed' | 'refunded')
- transactionId, paidAt
- createdAt, updatedAt
- getter `methodDisplay` → "Thanh toán khi nhận hàng", "Ví Momo", "VNPay"
- getter `statusDisplay` → "Chờ thanh toán", "Thành công", ...

**2. Repository** (`data/payment_repository.dart`):
- `createPayment(orderId, userId, method, amount)`: Tạo payment record
- `updatePaymentStatus(paymentId, status, {transactionId})`: Cập nhật trạng thái
- `getPaymentByOrderId(orderId)`: Lấy payment của order
- `getPaymentHistory(userId)`: Lấy lịch sử thanh toán
- `mockMomoPayment(paymentId, amount)`:
  * Simulate: delay 2 giây → random success/fail (90% success)
  * Update payment status
  * Return result
- `mockVnPayPayment(paymentId, amount)`:
  * Tương tự Momo mock

**3. Providers** (`providers/payment_provider.dart`):
- `paymentRepositoryProvider`
- `paymentProvider(orderId)`: FutureProvider.family
- `paymentProcessingProvider`: StateNotifierProvider cho payment flow
- `paymentHistoryProvider`: FutureProvider

**4. Screens**:
- `payment_screen.dart`:
  * Nhận orderId + paymentMethod
  * **COD**: Hiện thông tin đơn hàng + "Bạn sẽ thanh toán khi nhận hàng" + icon COD
  * **Momo**: Hiện mock UI giống app Momo (màu hồng, logo Momo)
    - Hiện số tiền
    - Nút "Xác nhận thanh toán"
    - Loading animation khi đang xử lý
  * **VNPay**: Hiện mock UI giống VNPay (logo, form)
    - Chọn ngân hàng (list ngân hàng mock)
    - Nút "Thanh toán"

- `payment_status_screen.dart`:
  * **Success**: Icon check lớn (animated), "Thanh toán thành công!"
    - Hiện order ID, amount, method, thời gian
    - Nút "Xem đơn hàng"
    - Nút "Tiếp tục mua sắm"
  * **Failed**: Icon X (animated), "Thanh toán thất bại"
    - Lý do (mock)
    - Nút "Thử lại"
    - Nút "Chọn phương thức khác"
  * Animation: Lottie hoặc custom animation
```

---

### 🤖 PROMPT CHO AI — Task 4.4: Shipping Module

```
Tiếp tục module Shipping cho GymFit.

**Folder**: `lib/features/shipping/`

**1. Model** (`models/shipping_tracking_model.dart`):
- id, orderId
- status ('preparing' | 'picked_up' | 'in_transit' | 'out_for_delivery' | 'delivered')
- location, note
- estimatedDelivery
- createdAt
- getter `statusDisplay` → "Đang chuẩn bị", "Đang vận chuyển", ...
- getter `statusIcon` → IconData theo status

**2. Repository** (`data/shipping_repository.dart`):
- `getTrackingByOrderId(orderId)`: Lấy tất cả tracking events, order by created_at
- `getLatestTracking(orderId)`: Lấy tracking mới nhất
- `createTrackingEvent(orderId, status, {location, note, estimatedDelivery})`: Admin tạo event mới

**3. Providers** (`providers/shipping_provider.dart`):
- `shippingRepositoryProvider`
- `shippingTrackingProvider(orderId)`: FutureProvider.family

**4. Screen** (`screens/shipping_tracking_screen.dart`):
- Nhận orderId
- **Header**: Order ID + trạng thái hiện tại (badge)
- **Estimated Delivery**: "Dự kiến giao: 15/06/2026"
- **Tracking Timeline** (vertical):
  * Mỗi event:
    - Dot indicator (active = filled, future = outline)
    - Status text (bold)
    - Location (nếu có)
    - Note (nếu có)
    - Timestamp
  * Dòng nối giữa các events
  * Event mới nhất ở trên
- **Order Info Card**: Tóm tắt đơn hàng (items, total)
- UI: Clean, step-by-step timeline, dễ đọc

**Admin: Update Order Status** (trong admin module nhưng Người 4 viết logic):
- Khi admin update order status → tự động tạo order_status_history entry
- Khi status = 'shipping' → tự tạo shipping_tracking event 'preparing'
- Khi status = 'delivered' → tự tạo shipping_tracking event 'delivered'
```

---

## 11. Người 5 — Review / Support / Admin / Dashboard / AI

### 📌 Vai trò
Xây dựng module đánh giá, hỗ trợ khách hàng, admin dashboard, quản lý tồn kho, và AI recommendation.

### 📌 Branch: `feature/admin-review-support`

### 📌 Bảng phụ trách: `reviews`, `review_images`, `support_tickets`, `inventory_logs`, `ai_recommendation_logs`

### 📌 Views phụ trách: `v_low_stock_variants`, `v_revenue_by_category`

### 📌 Files phụ trách

```
lib/features/reviews/**
lib/features/support/**
lib/features/admin/**
```

> [!WARNING]
> **Admin CRUD product phải dùng `ProductRepository`, `CategoryRepository`, `BrandRepository` từ Người 2.** KHÔNG tự viết lại query products. Import và sử dụng trực tiếp.

---

### 🤖 PROMPT CHO AI — Task 5.1: Review Module

```
Tôi đang phát triển module Review cho app GymFit (Flutter + Supabase + Riverpod).

**Folder**: `lib/features/reviews/`

**1. Models**:
- `review_model.dart`:
  * id, userId, productId, orderId
  * rating (1-5), comment
  * isVerifiedPurchase
  * createdAt, updatedAt
  * Relations: user (ProfileModel?), images (List<ReviewImageModel>?)
  * fromJson, toJson

- `review_image_model.dart`:
  * id, reviewId, imageUrl, createdAt
  * fromJson, toJson

**2. Repository** (`data/review_repository.dart`):
- `getProductReviews(productId, {int page, int pageSize, String? sortBy})`:
  * Query reviews kèm join profiles (lấy tên, avatar reviewer)
  * Kèm review_images
  * Sort by: newest, highest, lowest
  * Phân trang

- `createReview(userId, productId, orderId, rating, comment)`:
  * Insert review
  * Set isVerifiedPurchase = true nếu user đã mua sản phẩm (kiểm tra orders)
  * Sau khi tạo → cập nhật products.avg_rating và products.total_reviews:
    ```sql
    UPDATE products SET
      avg_rating = (SELECT AVG(rating) FROM reviews WHERE product_id = $1),
      total_reviews = (SELECT COUNT(*) FROM reviews WHERE product_id = $1)
    WHERE id = $1;
    ```
    (Hoặc gọi ProductRepository.updateProductRating)

- `uploadReviewImages(reviewId, List<File> images)`:
  * Upload lên Supabase Storage bucket 'reviews'
  * Path: 'reviews/{reviewId}/{timestamp}.jpg'
  * Insert vào review_images
  * Return List<String> URLs

- `getReviewSummary(productId)`:
  * Return: avgRating, totalReviews, distribution (1-5 star counts)

- `canUserReview(userId, productId)`:
  * Check: user đã mua + đã nhận hàng (delivered) + chưa review product này
  * Return bool

- `getUserReviews(userId)`: Lấy reviews của user

**3. Providers** (`providers/review_provider.dart`):
- `reviewRepositoryProvider`
- `productReviewsProvider(productId)`: FutureProvider.family — danh sách reviews
- `reviewSummaryProvider(productId)`: FutureProvider.family — tóm tắt rating
- `canReviewProvider({userId, productId})`: FutureProvider — check quyền review
- `createReviewProvider`: StateNotifierProvider — cho form tạo review

**4. Screens/Widgets**:
- **Review List Widget** (embed trong Product Detail Screen):
  * Rating summary:
    - Số lớn avg rating (ví dụ: 4.5)
    - 5 thanh progress bar cho 1-5 sao
    - Tổng số reviews
  * List reviews:
    - Avatar + tên reviewer
    - Rating stars
    - Badge "Đã mua hàng" (nếu verified)
    - Comment text
    - Review images (horizontal scroll, tap to zoom)
    - Thời gian
  * Nút "Viết đánh giá" (nếu canReview)
  * "Xem thêm" pagination

- `review_form_screen.dart`:
  * Hiện product info (ảnh, tên)
  * Rating selector: 5 sao interactive (tap để chọn)
  * TextField comment (multiline, max 500 ký tự)
  * Image picker: Nút thêm ảnh (tối đa 5 ảnh)
    - Grid preview ảnh đã chọn
    - Nút X xóa từng ảnh
  * Nút "Gửi đánh giá"
  * Loading state
  * Validation: rating required, comment optional
```

---

### 🤖 PROMPT CHO AI — Task 5.2: Support Module

```
Tiếp tục module Support cho GymFit.

**Folder**: `lib/features/support/`

**1. Model** (`models/support_ticket_model.dart`):
- id, userId, orderId
- subject, description
- status ('open' | 'in_progress' | 'resolved' | 'closed')
- priority ('low' | 'normal' | 'high' | 'urgent')
- adminReply, repliedAt
- createdAt, updatedAt
- getter `statusDisplay`, `statusColor`, `priorityDisplay`, `priorityColor`
- fromJson, toJson, copyWith

**2. Repository** (`data/support_repository.dart`):
- `getTickets(userId)`: Lấy tickets của user, order by created_at DESC
- `getTicketById(ticketId)`: Chi tiết ticket
- `createTicket(userId, {orderId?, subject, description, priority})`: Tạo ticket
- `getAdminTickets({status?, priority?})`: Admin lấy tất cả tickets
- `adminReplyTicket(ticketId, reply, newStatus)`: Admin trả lời + update status

**3. Providers** (`providers/support_provider.dart`):
- `supportRepositoryProvider`
- `userTicketsProvider`: FutureProvider — tickets của user
- `ticketDetailProvider(ticketId)`: FutureProvider.family
- `adminTicketsProvider`: StateNotifierProvider — admin filter tickets
- `createTicketProvider`: StateNotifierProvider

**4. Screens**:
- `support_list_screen.dart`:
  * List tickets:
    - Subject (bold)
    - Order ID (nếu có)
    - Status badge (có màu)
    - Priority badge
    - Thời gian tạo
    - Preview description (1 line)
  * FAB tạo ticket mới
  * Filter by status (tabs hoặc dropdown)
  * Empty state

- `support_detail_screen.dart`:
  * Ticket info: subject, status, priority, thời gian
  * Order info (nếu liên quan đến order)
  * Mô tả chi tiết
  * Admin reply section:
    - Nếu chưa reply: "Đang chờ phản hồi..."
    - Nếu đã reply: hiện reply + thời gian reply
  * Timeline: tạo → in_progress → resolved

- **Create Ticket Screen/Bottom Sheet**:
  * Dropdown chọn order liên quan (optional)
  * TextField subject
  * TextField description (multiline)
  * Dropdown priority
  * Nút "Gửi yêu cầu hỗ trợ"
```

---

### 🤖 PROMPT CHO AI — Task 5.3: Admin Dashboard

```
Tiếp tục module Admin cho GymFit.

**QUAN TRỌNG**: CRUD product/category/brand phải dùng repositories từ `lib/features/products/` (Người 2 viết). KHÔNG viết lại.

**Folder**: `lib/features/admin/`

**1. Models**:
- `inventory_log_model.dart`:
  * id, variantId, changeType, quantityChange, quantityBefore, quantityAfter, note, createdBy, createdAt
  * fromJson, toJson

**2. Repositories**:
- `admin_order_repository.dart`:
  * Sử dụng OrderRepository (Người 4) cho admin order management
  * `getDashboardStats()`: Query tổng hợp:
    - Tổng đơn hàng hôm nay
    - Tổng doanh thu hôm nay
    - Tổng đơn chờ xử lý
    - Tổng sản phẩm active

- `inventory_repository.dart`:
  * `getLowStockVariants()`: Query view v_low_stock_variants
  * `getInventoryLogs(variantId)`: Lấy lịch sử tồn kho
  * `createInventoryLog(variantId, changeType, quantityChange, note)`:
    - Lấy stock hiện tại
    - Tính stock mới
    - Insert log
    - Update product_variants.stock
  * `getRevenueByCategory()`: Query view v_revenue_by_category

**3. Providers** (`providers/`):
- `admin_provider.dart`:
  * `isAdminProvider`: Provider<bool> check role
  * `adminGuardProvider`: redirect nếu không phải admin

- `dashboard_provider.dart`:
  * `dashboardStatsProvider`: FutureProvider — load stats
  * `lowStockProvider`: FutureProvider — cảnh báo tồn kho thấp
  * `revenueByCategoryProvider`: FutureProvider — doanh thu theo danh mục
  * `recentOrdersProvider`: FutureProvider — 10 đơn mới nhất

**4. Screens**:

- `admin_dashboard_screen.dart`:
  * **Stats Cards** (grid 2x2):
    - 📦 Đơn hàng hôm nay: XX
    - 💰 Doanh thu hôm nay: XX₫
    - ⏳ Đơn chờ xử lý: XX
    - 📊 Tổng sản phẩm: XX
  * **Revenue Chart**: Bar chart doanh thu theo danh mục (đơn giản, dùng Container + width)
  * **Low Stock Warning**: List variants sắp hết hàng (stock ≤ 10)
    - Tên sản phẩm, variant info, stock còn lại
    - Highlight đỏ nếu stock ≤ 5
  * **Recent Orders**: 10 đơn mới nhất
    - Order ID, customer, total, status, thời gian
    - Tap → order detail
  * **Quick Actions**: Grid nút:
    - Quản lý sản phẩm
    - Quản lý danh mục
    - Quản lý thương hiệu
    - Quản lý đơn hàng
    - Quản lý voucher
    - Tồn kho

- `manage_products_screen.dart`:
  * Sử dụng ProductRepository (Người 2) để CRUD
  * List products (admin view — cả active + inactive)
  * Search + filter
  * Nút thêm product mới → form:
    - Tên, mô tả, category (dropdown), brand (dropdown)
    - Base price
    - Ảnh (multiple upload)
    - Variants (dynamic form: size, color, price, stock)
    - Toggle active/featured
  * Edit product → pre-fill form
  * Delete (soft delete)

- `manage_categories_screen.dart`:
  * Sử dụng CategoryRepository (Người 2)
  * CRUD categories
  * List + search
  * Form: name, slug (auto generate), image upload, description, sort_order

- `manage_brands_screen.dart`:
  * Sử dụng BrandRepository (Người 2)
  * CRUD brands
  * List + search
  * Form: name, slug, logo upload, description

- `manage_vouchers_screen.dart`:
  * Sử dụng VoucherRepository (Người 3)
  * List vouchers (all, cả expired)
  * Form: code, description, discount_type (dropdown), discount_value, min_order, max_discount, usage_limit, start/end date, is_active

- `manage_orders_screen.dart`:
  * List tất cả orders (admin)
  * Filter by status (tabs)
  * Tap → order detail (admin view)
  * **Update order status**: Dropdown chọn status mới
    - Khi update → tạo order_status_history
    - Khi chuyển 'shipping' → tạo shipping_tracking event
  * Nút bulk update (optional)

- `inventory_screen.dart`:
  * List product variants + stock
  * Highlight low stock (đỏ ≤ 5, vàng ≤ 10)
  * Nút "Nhập hàng" → dialog:
    - Chọn variant
    - Nhập số lượng
    - Ghi chú
    - Submit → createInventoryLog
  * Xem lịch sử nhập/xuất kho mỗi variant
```

---

### 🤖 PROMPT CHO AI — Task 5.4: AI Recommendation

```
Tiếp tục module AI Recommendation cho GymFit.

**Context**: Đây là module đơn giản, không dùng AI thật mà dùng logic-based recommendation.

**Tích hợp vào**: `lib/features/products/` hoặc `lib/features/admin/`

**1. Logic Recommendation**:

**Similar Products** (hiện ở Product Detail):
- Sản phẩm cùng category
- Sản phẩm cùng brand
- Sản phẩm cùng tầm giá (±30%)
- Exclude sản phẩm đang xem
- Ưu tiên sản phẩm rating cao, bán chạy

**Also Bought** (hiện ở Cart):
- Lấy order_items của các đơn chứa sản phẩm đang xem
- Tìm sản phẩm khác trong cùng đơn
- Sort by frequency

**Personalized** (hiện ở Home):
- Dựa trên lịch sử mua (categories đã mua nhiều nhất)
- Dựa trên wishlist
- Sản phẩm trending (bán nhiều trong 7 ngày gần)

**2. Repository** (`data/ai_recommendation_repository.dart`):
```dart
class AIRecommendationRepository {
  // Sản phẩm tương tự
  Future<List<ProductModel>> getSimilarProducts(String productId, {int limit = 10});

  // Người mua cũng mua
  Future<List<ProductModel>> getAlsoBoughtProducts(String productId, {int limit = 10});

  // Đề xuất cá nhân hóa
  Future<List<ProductModel>> getPersonalizedRecommendations(String userId, {int limit = 10});

  // Trending products
  Future<List<ProductModel>> getTrendingProducts({int limit = 10, int days = 7});

  // Log recommendation (để phân tích sau)
  Future<void> logRecommendation(String userId, String? sourceProductId,
      List<String> recommendedIds, String type, {String? clickedProductId});
}
```

**3. Providers**:
- `similarProductsProvider(productId)`: FutureProvider.family
- `alsoBoughtProvider(productId)`: FutureProvider.family
- `personalizedProvider`: FutureProvider — cho home screen

**4. UI Widgets**:
- **"Sản phẩm tương tự"** section trong product detail (horizontal scroll)
- **"Có thể bạn cũng thích"** section trong home screen (horizontal scroll)
- **"Người mua cũng mua"** section trong cart screen (horizontal scroll)

**Log**: Mỗi khi user tap vào sản phẩm recommended → log vào ai_recommendation_logs
```

---

## 12. Timeline 14 ngày

### Ngày 1-2: Setup & Models

| Người | Task | Output |
|-------|------|--------|
| **1** | Setup Flutter project, core config, theme, router, shared widgets | Project chạy được, có theme, router hoạt động |
| **2** | Tạo product models + repositories | Models + repos ready cho team dùng |
| **3** | Tạo cart/wishlist/voucher models + repos | Models + repos ready |
| **4** | Tạo order/payment/shipping models + repos | Models + repos ready |
| **5** | Tạo review/support/inventory models + repos | Models + repos ready |

### Ngày 3-4: Auth & Base UI

| Người | Task |
|-------|------|
| **1** | Auth (login, register, forgot password) + User profile |
| **2** | Home screen + product list screen |
| **3** | Cart screen + wishlist screen |
| **4** | Order history screen + order detail screen |
| **5** | Review form + support screens |

### Ngày 5-7: Feature Completion

| Người | Task |
|-------|------|
| **1** | Address management + merge test với develop |
| **2** | Product detail + search + filter/sort |
| **3** | Voucher module + cart summary |
| **4** | Checkout screen + payment screens |
| **5** | Admin dashboard + manage products |

### Ngày 8-10: Integration & Flow

| Mọi người | Task |
|-----------|------|
| **Team** | Merge tất cả vào develop (theo thứ tự 1→2→3→4→5) |
| **Team** | Nối flow: Home → Product → Cart → Checkout → Payment → Order |
| **1** | Fix conflicts, đảm bảo router hoạt động đúng |
| **2** | Fix product queries, đảm bảo data đúng |
| **3** | Truyền CheckoutData sang Người 4 |
| **4** | Nhận data, test full checkout flow |
| **5** | Tích hợp review vào product detail |

### Ngày 11-12: Admin & Polish

| Người | Task |
|-------|------|
| **1** | Polish auth flow, fix bugs |
| **2** | Polish UI, optimize queries |
| **3** | Polish cart/voucher UX |
| **4** | Shipping tracking, admin order update |
| **5** | Admin full CRUD, dashboard stats, AI recommendations |

### Ngày 13-14: Final

| Mọi người | Task |
|-----------|------|
| **Team** | Final merge vào develop |
| **Team** | Bug fixes |
| **1** | Seed data (tạo dữ liệu mẫu) |
| **Team** | Polish UI, animations |
| **1** | Build APK |
| **Team** | Test end-to-end |

---

## 13. Quy tắc chống Conflict khi Merge

### 🔴 TUYỆT ĐỐI KHÔNG ĐƯỢC

| Người | KHÔNG được sửa |
|-------|---------------|
| **2, 3, 4, 5** | `core/`, `shared/`, `main.dart`, `app.dart`, `pubspec.yaml` |
| **1, 3, 4, 5** | `features/products/models/`, `features/products/data/` |
| **1, 2, 4, 5** | `features/cart/`, `features/wishlist/`, `features/voucher/` |
| **1, 2, 3, 5** | `features/checkout/`, `features/orders/`, `features/payments/`, `features/shipping/` |
| **1, 2, 3, 4** | `features/reviews/`, `features/support/`, `features/admin/` |

### 🟢 CÁCH LÀM ĐÚNG

- **Cần thêm dependency vào pubspec.yaml?** → Báo Người 1
- **Cần thêm shared widget?** → Báo Người 1
- **Cần thêm route?** → Báo Người 1 route name + screen path
- **Cần query product?** → Import repo Người 2, KHÔNG tự viết
- **Cần truyền data giữa modules?** → Định nghĩa interface/model rõ ràng, thống nhất qua team chat

### 📋 Thứ tự Merge

```
1. Người 1 merge feature/core-auth-user → develop
2. Tất cả pull develop, rebase branch
3. Người 2 merge feature/product-catalog → develop
4. Tất cả pull develop, rebase branch
5. Người 3 merge feature/cart-wishlist-voucher → develop
6. Tất cả pull develop, rebase branch
7. Người 4 merge feature/order-payment-shipping → develop
8. Tất cả pull develop, rebase branch
9. Người 5 merge feature/admin-review-support → develop
10. Final test trên develop
11. Merge develop → main
12. Build APK
```

---

## 14. Checklist trước khi Merge

Mỗi người PHẢI hoàn thành checklist này trước khi merge:

- [ ] Code chạy không lỗi (`flutter analyze` clean)
- [ ] Không import file của người khác (trừ shared repos cho phép)
- [ ] Tất cả models có `fromJson`, `toJson`, `copyWith`
- [ ] Tất cả repos có error handling
- [ ] Tất cả screens có loading, error, empty states
- [ ] Dùng đúng shared widgets (AppButton, AppTextField, etc.)
- [ ] Dùng đúng theme colors và text styles
- [ ] Navigate bằng GoRouter với đúng route names
- [ ] Riverpod providers đặt tên đúng convention
- [ ] Không hardcode strings (dùng constants)
- [ ] Code có comment tiếng Việt giải thích logic phức tạp
- [ ] Pull latest develop và rebase trước khi tạo PR

---

## 📎 Phụ lục: Seed Data Script

```sql
-- Run sau khi tất cả merge xong, dùng để test

-- Categories
INSERT INTO categories (name, slug, sort_order) VALUES
('Quần áo tập', 'quan-ao-tap', 1),
('Giày tập', 'giay-tap', 2),
('Phụ kiện', 'phu-kien', 3),
('Thực phẩm bổ sung', 'thuc-pham-bo-sung', 4),
('Thiết bị tập', 'thiet-bi-tap', 5),
('Bao tay & Đai lưng', 'bao-tay-dai-lung', 6);

-- Brands
INSERT INTO brands (name, slug) VALUES
('Nike', 'nike'),
('Adidas', 'adidas'),
('Under Armour', 'under-armour'),
('Gymshark', 'gymshark'),
('MyProtein', 'myprotein'),
('MuscleTech', 'muscletech');

-- Sample products (thêm sau khi có category_id và brand_id)
-- INSERT INTO products ...

-- Sample vouchers
INSERT INTO vouchers (code, description, discount_type, discount_value, min_order_amount, max_discount_amount, usage_limit, start_date, end_date) VALUES
('GYMFIT10', 'Giảm 10% cho đơn đầu tiên', 'percentage', 10, 200000, 100000, 1000, NOW(), NOW() + INTERVAL '30 days'),
('SALE50K', 'Giảm 50.000₫', 'fixed', 50000, 300000, NULL, 500, NOW(), NOW() + INTERVAL '15 days'),
('FREESHIP', 'Giảm 30.000₫ phí ship', 'fixed', 30000, 0, NULL, NULL, NOW(), NOW() + INTERVAL '60 days');

-- Admin user (set role sau khi user đăng ký)
-- UPDATE profiles SET role = 'admin' WHERE id = 'admin-user-uuid';
```

---

> [!TIP]
> **Mẹo sử dụng AI Prompt**: Copy prompt cho task tương ứng, paste vào AI tool (Cursor, Copilot, ChatGPT, etc.). Nếu AI hỏi thêm context, share file code đã có (models, repos, providers) để AI hiểu structure. Làm từng task một, test chạy rồi mới sang task tiếp theo.

---

**📧 Liên hệ Leader (Người 1)** khi:
- Cần thêm package vào pubspec.yaml
- Cần thêm shared widget
- Cần thêm route mới
- Gặp conflict khi merge
- Không chắc nên đặt file ở đâu
- Cần thay đổi database schema
