-- ============================================
-- GlowKart Additional Seed Data
-- Adds more products, ingredients, and a new category.
-- Uses ON CONFLICT and subqueries by name instead of hardcoded IDs,
-- so this is safe to run even if some rows already exist.
-- ============================================

-- ---- NEW CATEGORY ----
INSERT INTO categories (category_name) VALUES ('Bath & Body')
ON CONFLICT (category_name) DO NOTHING;

-- ---- MORE INGREDIENTS ----
INSERT INTO ingredients (ingredient_name) VALUES
('retinol'),
('salicylic acid'),
('niacinamide'),
('essential oils'),
('silicone'),
('mineral oil'),
('shea butter')
ON CONFLICT (ingredient_name) DO NOTHING;

-- ---- MORE PRODUCTS ----
INSERT INTO products (name, description, price, stock, category_id) VALUES
('Vitamin C Brightening Serum', 'Evens tone and adds glow', 649.00, 70,
    (SELECT category_id FROM categories WHERE category_name = 'Skincare')),
('Niacinamide 10% Serum', 'Minimizes pores, controls oil', 499.00, 85,
    (SELECT category_id FROM categories WHERE category_name = 'Skincare')),
('Salicylic Acid Acne Gel', 'Spot treatment for breakouts', 379.00, 65,
    (SELECT category_id FROM categories WHERE category_name = 'Skincare')),
('Retinol Night Serum', 'Anti-aging overnight treatment', 799.00, 40,
    (SELECT category_id FROM categories WHERE category_name = 'Skincare')),
('Mineral SPF 50 Sunscreen', 'Lightweight daily sun protection', 549.00, 110,
    (SELECT category_id FROM categories WHERE category_name = 'Skincare')),
('Silk Shine Hair Oil', 'Adds shine, reduces frizz', 349.00, 75,
    (SELECT category_id FROM categories WHERE category_name = 'Haircare')),
('Sulfate-Free Shampoo', 'Gentle daily cleansing shampoo', 429.00, 95,
    (SELECT category_id FROM categories WHERE category_name = 'Haircare')),
('Deep Conditioning Hair Mask', 'Weekly intensive repair mask', 599.00, 50,
    (SELECT category_id FROM categories WHERE category_name = 'Haircare')),
('Matte Compact Powder', 'Oil-control finishing powder', 349.00, 100,
    (SELECT category_id FROM categories WHERE category_name = 'Makeup')),
('Tinted Lip Balm', 'Sheer color with hydration', 249.00, 130,
    (SELECT category_id FROM categories WHERE category_name = 'Makeup')),
('Waterproof Mascara', 'Long-wear volumizing formula', 399.00, 90,
    (SELECT category_id FROM categories WHERE category_name = 'Makeup')),
('Shea Butter Body Lotion', 'Rich daily moisturizer', 449.00, 80,
    (SELECT category_id FROM categories WHERE category_name = 'Bath & Body')),
('Aromatherapy Body Wash', 'Essential-oil scented cleanser', 349.00, 90,
    (SELECT category_id FROM categories WHERE category_name = 'Bath & Body')),
('Exfoliating Body Scrub', 'Smooths and softens skin', 399.00, 70,
    (SELECT category_id FROM categories WHERE category_name = 'Bath & Body'));

-- ---- PRODUCT_INGREDIENTS for the new products ----
-- Vitamin C Serum: hyaluronic acid, glycerin (safe)
INSERT INTO product_ingredients (product_id, ingredient_id)
SELECT p.product_id, i.ingredient_id FROM products p, ingredients i
WHERE p.name = 'Vitamin C Brightening Serum' AND i.ingredient_name IN ('hyaluronic acid', 'glycerin');

-- Niacinamide Serum: niacinamide, glycerin (safe)
INSERT INTO product_ingredients (product_id, ingredient_id)
SELECT p.product_id, i.ingredient_id FROM products p, ingredients i
WHERE p.name = 'Niacinamide 10% Serum' AND i.ingredient_name IN ('niacinamide', 'glycerin');

-- Salicylic Acid Gel: salicylic acid, alcohol (contains allergen)
INSERT INTO product_ingredients (product_id, ingredient_id)
SELECT p.product_id, i.ingredient_id FROM products p, ingredients i
WHERE p.name = 'Salicylic Acid Acne Gel' AND i.ingredient_name IN ('salicylic acid', 'alcohol');

-- Retinol Night Serum: retinol, hyaluronic acid (safe unless allergic to retinol specifically)
INSERT INTO product_ingredients (product_id, ingredient_id)
SELECT p.product_id, i.ingredient_id FROM products p, ingredients i
WHERE p.name = 'Retinol Night Serum' AND i.ingredient_name IN ('retinol', 'hyaluronic acid');

-- Mineral Sunscreen: mineral oil, aloe vera (contains allergen for mineral-oil-sensitive users)
INSERT INTO product_ingredients (product_id, ingredient_id)
SELECT p.product_id, i.ingredient_id FROM products p, ingredients i
WHERE p.name = 'Mineral SPF 50 Sunscreen' AND i.ingredient_name IN ('mineral oil', 'aloe vera');

-- Silk Shine Hair Oil: silicone, fragrance (contains allergens)
INSERT INTO product_ingredients (product_id, ingredient_id)
SELECT p.product_id, i.ingredient_id FROM products p, ingredients i
WHERE p.name = 'Silk Shine Hair Oil' AND i.ingredient_name IN ('silicone', 'fragrance');

-- Sulfate-Free Shampoo: aloe vera, glycerin (safe, ironically sulfate-free by name too)
INSERT INTO product_ingredients (product_id, ingredient_id)
SELECT p.product_id, i.ingredient_id FROM products p, ingredients i
WHERE p.name = 'Sulfate-Free Shampoo' AND i.ingredient_name IN ('aloe vera', 'glycerin');

-- Deep Conditioning Hair Mask: shea butter, silicone (contains allergen)
INSERT INTO product_ingredients (product_id, ingredient_id)
SELECT p.product_id, i.ingredient_id FROM products p, ingredients i
WHERE p.name = 'Deep Conditioning Hair Mask' AND i.ingredient_name IN ('shea butter', 'silicone');

-- Matte Compact Powder: mineral oil, silicone (contains allergens)
INSERT INTO product_ingredients (product_id, ingredient_id)
SELECT p.product_id, i.ingredient_id FROM products p, ingredients i
WHERE p.name = 'Matte Compact Powder' AND i.ingredient_name IN ('mineral oil', 'silicone');

-- Tinted Lip Balm: shea butter, glycerin (safe)
INSERT INTO product_ingredients (product_id, ingredient_id)
SELECT p.product_id, i.ingredient_id FROM products p, ingredients i
WHERE p.name = 'Tinted Lip Balm' AND i.ingredient_name IN ('shea butter', 'glycerin');

-- Waterproof Mascara: silicone, fragrance (contains allergens)
INSERT INTO product_ingredients (product_id, ingredient_id)
SELECT p.product_id, i.ingredient_id FROM products p, ingredients i
WHERE p.name = 'Waterproof Mascara' AND i.ingredient_name IN ('silicone', 'fragrance');

-- Shea Butter Body Lotion: shea butter, glycerin (safe)
INSERT INTO product_ingredients (product_id, ingredient_id)
SELECT p.product_id, i.ingredient_id FROM products p, ingredients i
WHERE p.name = 'Shea Butter Body Lotion' AND i.ingredient_name IN ('shea butter', 'glycerin');

-- Aromatherapy Body Wash: essential oils, fragrance (contains allergens)
INSERT INTO product_ingredients (product_id, ingredient_id)
SELECT p.product_id, i.ingredient_id FROM products p, ingredients i
WHERE p.name = 'Aromatherapy Body Wash' AND i.ingredient_name IN ('essential oils', 'fragrance');

-- Exfoliating Body Scrub: aloe vera, glycerin (safe)
INSERT INTO product_ingredients (product_id, ingredient_id)
SELECT p.product_id, i.ingredient_id FROM products p, ingredients i
WHERE p.name = 'Exfoliating Body Scrub' AND i.ingredient_name IN ('aloe vera', 'glycerin');

-- ============================================
-- 19 products across 4 categories,
-- 14 ingredients, and a realistic spread of allergen conflicts
-- to actually see filtering do something meaningful.
-- ============================================