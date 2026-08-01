# Perfect Optical - Real-Time Eyewear Inventory & Warehouse Portal

A state-of-the-art Flutter web & mobile application for optical store managers and warehouse staff. Features **Supabase Realtime** cross-device synchronization, **Supabase Storage Bucket** image uploads, persistent offline local database storage, automatic background catch-up sync, and live animated top notification banners.

---

## 🌟 Key Features

### ⚡ 1. Real-Time Supabase Synchronization
- **Multi-Device Live Sync**: Any action taken on Phone/Device A instantly broadcasts to all other connected devices without manual page reloads or refreshes.
- **Supabase Realtime Engine**: Subscribed to Postgres `products` changes (`INSERT`, `UPDATE`, `DELETE`) and Realtime `inventory_action` broadcast streams.
- **Supported Live Sync Operations**:
  - 🆕 **New Products**: Add new eyewear frames with live cross-device notification.
  - ✏️ **Edited Products**: Update frame names, brands, vendors, or box numbers.
  - 🗑️ **Deleted Products**: Remove items from shared inventory in real-time.
  - 📦 **Stock Changes**: Increment/decrement stock quantity with instant counter updates.
  - 🏷️ **Price Changes**: Adjust prices with real-time currency updates.
  - 🗂️ **Category Updates**: Modify frame style categories (Rimless, Cat Eye, Plastic, Metal, Half Frame, Sunglass).
  - 🖼️ **Product Images**: Upload new photos and sync public CDN image URLs live.

### 🖼️ 2. Supabase Storage Bucket Uploads
- Direct file and cropped image uploads to public Supabase Storage bucket (`eyewear-images`).
- Automatic public CDN URL generation (`https://jrrwucqoeqdpjqpyojzw.supabase.co/storage/v1/object/public/eyewear-images/...`).
- Integrated device file picker and interactive image crop/rotate editor.

### 🔔 3. In-App Real-Time Notification Toasts
- Floating glassmorphic top toast overlay (`SyncNotificationOverlay`) auto-dismissing after 3.2 seconds.
- Displays live event notifications:
  - `"New frame synced"`
  - `"Stock updated"`
  - `"Price updated"`
  - `"Category updated"`
  - `"Image updated"`
  - `"Inventory updated"`
  - `"Product deleted"`

### 💾 4. Persistent Offline Local Database & Background Catch-Up
- **100% Offline Capability**: Application continues functioning seamlessly offline using local disk storage (`SharedPreferences`).
- **Conflict-Free Change Queue**: Offline modifications are tagged with `isPendingSync: true`.
- **Automatic Background Sync**: As soon as internet connectivity returns, the background engine automatically flushes pending local modifications to Supabase and pulls missed cloud updates with **zero user interaction**.

---

## 📁 Project Architecture & Structure

```
lib/
├── main.dart                       # App entry point, Supabase & Local DB init, Toast overlay
├── models/
│   ├── frame_item.dart             # FrameItem model with JSON & Supabase map serializers
│   └── sync_status.dart            # SyncStatus enum (synced, syncing, offline, pendingChanges)
├── services/
│   ├── supabase_sync_service.dart  # Supabase Realtime channel, broadcast & storage engine
│   ├── local_database_service.dart # Local SharedPreferences database & cloud reconciliation
│   ├── auth_service.dart           # Authentication session manager
│   └── image_cache_service.dart    # Network image caching utility
├── widgets/
│   ├── sync_notification_toast.dart# Floating glassmorphism animated top toast overlay
│   ├── sync_status_indicator.dart # Live sync status pill indicator & manual sync sheet
│   ├── product_card_widget.dart   # Interactive product card with glasses custom painter
│   ├── category_arc_selector.dart # Curved arc category selector
│   ├── frame_detail_drawer_widget.dart # Bottom drawer for frame details & quick edits
│   ├── image_crop_rotate_editor_modal.dart # Image crop, rotate & position modal
│   ├── add_frame_modal.dart       # Quick add frame modal dialog
│   ├── header_widget.dart          # Header with portal title & notification badge
│   ├── search_bar_widget.dart      # Real-time search & sort filter bar
│   ├── floating_bottom_nav.dart    # Floating tab navigation bar
│   ├── empty_inventory_widget.dart # Empty state illustration & search suggestions
│   ├── custom_glasses_painter.dart # Custom Canvas painter for eyewear placeholder
│   └── shimmer_loading.dart        # Skeleton loading animation
└── screens/
    ├── home_screen.dart            # Main dashboard, tab routing & reactive inventory view
    ├── catalog_screen.dart         # Grid & list catalog viewer
    ├── inventory_hub_screen.dart   # Warehouse metrics, stock stats & portal controls
    ├── add_frame_screen.dart       # Full studio form to add new frames with device picker
    ├── edit_frame_screen.dart      # Form to edit existing frame details & stock count
    ├── splash_screen.dart          # Animated brand splash screen
    ├── login_screen.dart           # Portal authentication screen
    ├── sync_loading_screen.dart    # Initial cloud synchronization progress screen
    ├── profile_screen.dart         # User profile & portal settings screen
    └── help_support_screen.dart    # Documentation & support screen
```

---

## ⚙️ Supabase Database & Storage Setup

### Database Table: `public.products`
```sql
CREATE TABLE public.products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT,
  name TEXT,
  brand TEXT,
  category TEXT,
  price NUMERIC,
  price_symbol TEXT DEFAULT '₹',
  color TEXT,
  image_path TEXT,
  rating NUMERIC DEFAULT 4.8,
  reviews INTEGER DEFAULT 250,
  stock_count INTEGER DEFAULT 12,
  box_number TEXT DEFAULT 'BOX-01',
  vendor TEXT DEFAULT 'Perfect Optical Direct',
  is_pending_sync BOOLEAN DEFAULT false,
  is_deleted BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);
```

### Storage Bucket: `eyewear-images`
```sql
INSERT INTO storage.buckets (id, name, public) 
VALUES ('eyewear-images', 'eyewear-images', true) 
ON CONFLICT (id) DO NOTHING;

-- Public RLS Policies
CREATE POLICY "Public Read Eyewear Images" ON storage.objects FOR SELECT USING (bucket_id = 'eyewear-images');
CREATE POLICY "Public Upload Eyewear Images" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'eyewear-images');
CREATE POLICY "Public Update Eyewear Images" ON storage.objects FOR UPDATE USING (bucket_id = 'eyewear-images');
CREATE POLICY "Public Delete Eyewear Images" ON storage.objects FOR DELETE USING (bucket_id = 'eyewear-images');
```

---

## 🚀 Getting Started

### Prerequisites
- **Flutter SDK**: `^3.22.0` (Dart `^3.4.0`)
- **Web Browser / Desktop / Mobile Emulator**

### Installation & Execution

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/david-8837/perfect-optical-inventory-app.git
   cd perfect-optical-inventory-app
   ```

2. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run the App**:
   ```bash
   # Run in Chrome Web Browser
   flutter run -d chrome

   # Run on connected Desktop / Mobile device
   flutter run
   ```

4. **Verify Static Code Analysis**:
   ```bash
   flutter analyze
   ```

---

## 🧪 Real-Time Verification Flow

1. **Multi-Device Test**: Open the application in two separate browser windows (or devices).
2. **Add a Frame**: Click `+ Add Eyewear` in Window 1, upload a photo or pick a sample photo, and submit.
3. **Verify Sync**: Window 2 automatically receives the update, updates its local database, adds the new frame to the inventory grid, and displays the top toast notification `"New frame synced"`.
4. **Offline Test**: In the cloud sync indicator at the top right, toggle `Network Online Mode` OFF. Add or edit frames. Changes persist locally. Toggle `Network Online Mode` ON to observe instant background catch-up sync.

---

## 📜 License
This project is proprietary software for **Perfect Optical Eyewear Portal**. All rights reserved.
