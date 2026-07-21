-- ============================================
-- 1. USERS
-- ============================================
CREATE TABLE users (
    user_id     SERIAL PRIMARY KEY,          -- auto-incrementing unique ID
    name        VARCHAR(100) NOT NULL,
    email       VARCHAR(150) NOT NULL UNIQUE, -- UNIQUE = no two users can share an email
    password    VARCHAR(255) NOT NULL,        -- will store a HASHED password, never plain text
    created_at  TIMESTAMP DEFAULT NOW()       -- auto-fills with current time when a row is inserted
);

-- ============================================
-- 2. SKIN PROFILE (1:1 with users)
-- One user has exactly one skin profile.
-- We give it its own table (instead of cramming into `users`)
-- because it's a distinct concept and keeps `users` clean.
-- ============================================
CREATE TABLE skin_profiles (
    skin_profile_id  SERIAL PRIMARY KEY,
    user_id          INTEGER NOT NULL UNIQUE REFERENCES users(user_id) ON DELETE CASCADE,
    -- UNIQUE here is what enforces the "1:1" rule — a user_id can only appear once in this table
    skin_type        VARCHAR(20) CHECK (skin_type IN ('oily','dry','combination','sensitive','normal')),
    allergens         TEXT  -- comma-separated ingredient names the user wants to avoid, e.g. 'sulfate,paraben'
);

-- ============================================
-- 3. CATEGORY
-- ============================================
CREATE TABLE categories (
    category_id    SERIAL PRIMARY KEY,
    category_name  VARCHAR(100) NOT NULL UNIQUE
);

-- ============================================
-- 4. PRODUCT
-- ============================================
CREATE TABLE products (
    product_id    SERIAL PRIMARY KEY,
    name          VARCHAR(150) NOT NULL,
    description   TEXT,
    price         NUMERIC(10,2) NOT NULL CHECK (price >= 0),
    stock         INTEGER NOT NULL DEFAULT 0 CHECK (stock >= 0),
    category_id   INTEGER REFERENCES categories(category_id),
    created_at    TIMESTAMP DEFAULT NOW()
);

-- ============================================
-- 5. INGREDIENT
-- ============================================
CREATE TABLE ingredients (
    ingredient_id    SERIAL PRIMARY KEY,
    ingredient_name  VARCHAR(100) NOT NULL UNIQUE
);

-- ============================================
-- 6. PRODUCT_INGREDIENTS (junction table)
-- Products <-> Ingredients is Many-to-Many:
--   one product has many ingredients,
--   one ingredient appears in many products.
-- A junction table is how you represent M:N in a relational DB —
-- it just holds pairs of (product_id, ingredient_id).
-- ============================================
CREATE TABLE product_ingredients (
    product_id     INTEGER NOT NULL REFERENCES products(product_id) ON DELETE CASCADE,
    ingredient_id  INTEGER NOT NULL REFERENCES ingredients(ingredient_id) ON DELETE CASCADE,
    PRIMARY KEY (product_id, ingredient_id)  -- combination must be unique (no duplicate pairs)
);

-- ============================================
-- 7. CART + CART_ITEMS
-- A user has one active cart; a cart holds many items.
-- ============================================
CREATE TABLE carts (
    cart_id   SERIAL PRIMARY KEY,
    user_id   INTEGER NOT NULL UNIQUE REFERENCES users(user_id) ON DELETE CASCADE
);

CREATE TABLE cart_items (
    cart_item_id  SERIAL PRIMARY KEY,
    cart_id       INTEGER NOT NULL REFERENCES carts(cart_id) ON DELETE CASCADE,
    product_id    INTEGER NOT NULL REFERENCES products(product_id),
    quantity      INTEGER NOT NULL CHECK (quantity > 0),
    UNIQUE (cart_id, product_id)  -- same product can't appear twice as separate rows in one cart
);

-- ============================================
-- 8. ORDERS + ORDER_ITEMS
-- ============================================
CREATE TABLE orders (
    order_id         SERIAL PRIMARY KEY,
    user_id          INTEGER NOT NULL REFERENCES users(user_id),
    order_date       TIMESTAMP DEFAULT NOW(),
    status           VARCHAR(20) DEFAULT 'placed' CHECK (status IN ('placed','shipped','delivered','cancelled')),
    total_amount     NUMERIC(10,2) NOT NULL CHECK (total_amount >= 0),
    cashback_applied NUMERIC(10,2) DEFAULT 0 CHECK (cashback_applied >= 0)
    -- ^ this is the discount deducted because of verified bottle returns at checkout time
);

CREATE TABLE order_items (
    order_item_id     SERIAL PRIMARY KEY,
    order_id          INTEGER NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id        INTEGER NOT NULL REFERENCES products(product_id),
    quantity          INTEGER NOT NULL CHECK (quantity > 0),
    price_at_purchase NUMERIC(10,2) NOT NULL
    -- ^ IMPORTANT: we store the price AT THE TIME of purchase separately from products.price,
    -- because products.price can change later — but past orders should always reflect
    -- what the customer actually paid. This is a classic real-world DB design decision.
);

-- ============================================
-- 9. BOTTLE_RETURNS
-- Each return references the specific order_item whose bottle is being returned,
-- so we always know exactly which product/order it came from.
-- ============================================
CREATE TABLE bottle_returns (
    return_id        SERIAL PRIMARY KEY,
    user_id          INTEGER NOT NULL REFERENCES users(user_id),
    order_item_id    INTEGER NOT NULL REFERENCES order_items(order_item_id),
    status           VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending','verified','applied')),
    cashback_value   NUMERIC(10,2) NOT NULL DEFAULT 20.00,  -- flat cashback per bottle, adjust as needed
    submitted_at     TIMESTAMP DEFAULT NOW()
);
