-- ============================================
-- QUERY 1: Skin-safe product recommendations
-- "Show all products EXCEPT those containing an ingredient
--  this user has flagged as an allergen."
-- ============================================

-- Try this for user_id = 1 (Aisha, allergic to sulfate & alcohol)
SELECT DISTINCT p.product_id, p.name, p.price
FROM products p
WHERE p.product_id NOT IN (
    -- subquery: find all product_ids that contain a "bad" ingredient for this user
    SELECT pi.product_id
    FROM product_ingredients pi
    JOIN ingredients i ON pi.ingredient_id = i.ingredient_id
    JOIN skin_profiles sp ON sp.user_id = 1   -- <-- change this user_id to test other users
    WHERE i.ingredient_name = ANY (string_to_array(sp.allergens, ','))
    -- string_to_array turns 'sulfate,alcohol' into an array ['sulfate','alcohol']
    -- ANY(...) checks if the ingredient_name matches any value in that array
);

-- The subquery finds every product that contains at least one ingredient
--  matching the user's allergen list. The outer query then selects every
--  product NOT in that set — so the user only sees products safe for them.


-- ============================================
-- QUERY 2: Bottle-return cashback lookup
-- "Find all verified, not-yet-applied bottle returns for a user,
--  and calculate the total cashback they're entitled to on their next order."
-- ============================================

-- Try this for user_id = 1 (Aisha, who has 1 verified return worth ₹20)
SELECT
    br.return_id,
    br.cashback_value,
    br.status
FROM bottle_returns br
WHERE br.user_id = 1          -- <-- change this to test other users
  AND br.status = 'verified'; -- only verified, not yet applied

-- Total cashback available to apply on their next order:
SELECT COALESCE(SUM(cashback_value), 0) AS total_cashback_available
FROM bottle_returns
WHERE user_id = 1
  AND status = 'verified';

-- When a user places a new order, the backend runs this SUM query first.
--  If it returns a non-zero amount, that value is subtracted from the order
--  total, and every matching bottle_returns row gets its status updated
--  from 'verified' to 'applied' — so it can never be double-counted on
--  a future order.


-- ============================================
-- QUERY 3 (for the analytics page):
-- Top-selling products by total quantity ordered
-- ============================================
SELECT
    p.name,
    SUM(oi.quantity) AS total_units_sold,
    SUM(oi.quantity * oi.price_at_purchase) AS total_revenue
FROM order_items oi
JOIN products p ON p.product_id = oi.product_id
GROUP BY p.name
ORDER BY total_units_sold DESC;