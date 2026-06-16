-- Create Banners table
CREATE TABLE IF NOT EXISTS public.banners (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(255) NOT NULL,
    subtitle VARCHAR(255),
    image_url TEXT,
    gradient_start VARCHAR(7),
    gradient_end VARCHAR(7),
    icon_name VARCHAR(50),
    target_route TEXT,
    sort_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS Policies
ALTER TABLE public.banners ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public read access on active banners" 
    ON public.banners FOR SELECT 
    USING (is_active = true);

CREATE POLICY "Allow admin full access on banners" 
    ON public.banners FOR ALL 
    USING (
        auth.uid() IN (
            SELECT id FROM public.profiles WHERE role = 'admin'
        )
    );

-- Insert dummy data
INSERT INTO public.banners (title, subtitle, gradient_start, gradient_end, icon_name, target_route, sort_order)
VALUES 
    ('Bộ sưu tập Hè 2026', 'Giảm đến 40%', '#667EEA', '#764BA2', 'fitness_center', '/products', 1),
    ('Nike & Adidas', 'Thương hiệu hàng đầu', '#FF6B6B', '#EE5A24', 'sports_gymnastics', '/products', 2),
    ('Thực phẩm bổ sung', 'Tăng cơ, giảm mỡ', '#11998E', '#38EF7D', 'local_pharmacy_outlined', '/products', 3)
ON CONFLICT DO NOTHING;
