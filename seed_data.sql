
-- ---- USERS ----
INSERT INTO users (name, email, password) VALUES
('Aisha Rao', 'aisha@example.com', 'hashed_pw_1'),
('Priya Menon', 'priya@example.com', 'hashed_pw_2'),
('Kavya Reddy', 'kavya@example.com', 'hashed_pw_3');

-- ---- SKIN PROFILES ----
-- Note: user_id 1,2,3 correspond to the order they were inserted above
INSERT INTO skin_profiles (user_id, skin_type, allergens) VALUES
(1, 'oily', 'sulfate,alcohol'),
(2, 'dry', 'paraben'),
(3, 'sensitive', 'fragrance,sulfate');

-- ---- CATEGORIES ----
INSERT INTO categories (category_name) VALUES
('Skincare'),
('Haircare'),
('Makeup');

-- ---- PRODUCTS ----
INSERT INTO products (name, description, price, stock, category_id) VALUES
('Gentle Foaming Cleanser', 'Sulfate-free daily cleanser', 349.00, 100, 1),
('Hydrating Night Cream', 'Deep moisture for dry skin', 599.00, 60, 1),
('Anti-Frizz Hair Serum', 'Smooths and controls frizz', 449.00, 80, 2),
('Matte Liquid Lipstick', 'Long-wear matte finish', 299.00, 120, 3),
('Alcohol-Free Toner', 'Balances oily skin', 399.00, 90, 1);

-- ---- INGREDIENTS ----
INSERT INTO ingredients (ingredient_name) VALUES
('sulfate'),
('alcohol'),
('paraben'),
('fragrance'),
('aloe vera'),
('hyaluronic acid'),
('glycerin');

-- ---- PRODUCT_INGREDIENTS ----
-- Product 1: Gentle Foaming Cleanser -> aloe vera, glycerin (no allergens)
INSERT INTO product_ingredients (product_id, ingredient_id) VALUES
(1, 5), (1, 7);

-- Product 2: Hydrating Night Cream -> hyaluronic acid, glycerin (no allergens)
INSERT INTO product_ingredients (product_id, ingredient_id) VALUES
(2, 6), (2, 7);

-- Product 3: Anti-Frizz Hair Serum -> alcohol, fragrance (contains allergens!)
INSERT INTO product_ingredients (product_id, ingredient_id) VALUES
(3, 2), (3, 4);

-- Product 4: Matte Liquid Lipstick -> fragrance (contains allergen for some users)
INSERT INTO product_ingredients (product_id, ingredient_id) VALUES
(4, 4);

-- Product 5: Alcohol-Free Toner -> aloe vera only (safe for everyone)
INSERT INTO product_ingredients (product_id, ingredient_id) VALUES
(5, 5);

-- ---- CARTS ----
INSERT INTO carts (user_id) VALUES (1), (2), (3);

-- ---- CART_ITEMS ----
INSERT INTO cart_items (cart_id, product_id, quantity) VALUES
(1, 5, 1),  -- Aisha has the toner in her cart
(2, 2, 2);  -- Priya has 2 night creams in her cart

-- ---- ORDERS ----
INSERT INTO orders (user_id, status, total_amount, cashback_applied) VALUES
(1, 'delivered', 349.00, 0),
(2, 'delivered', 1198.00, 0);

-- ---- ORDER_ITEMS ----
INSERT INTO order_items (order_id, product_id, quantity, price_at_purchase) VALUES
(1, 1, 1, 349.00),   -- Aisha bought the cleanser
(2, 2, 2, 599.00);   -- Priya bought 2 night creams

-- ---- BOTTLE_RETURNS ----
-- Aisha returned the empty cleanser bottle from her order, already verified
-- (this will be used to test the cashback-on-next-order logic)
INSERT INTO bottle_returns (user_id, order_item_id, status, cashback_value) VALUES
(1, 1, 'verified', 20.00);
