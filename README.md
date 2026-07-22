# GlowKart 💄

A full-stack beauty e-commerce platform with **skin-safe product recommendations** and **bottle-return cashback** — built as a final-year BTech project to demonstrate end-to-end software development from schema design to cloud deployment.

🌐 **Live demo:** https://glow-kart.vercel.app

---

## What makes GlowKart different from a generic e-commerce clone

Most beauty e-commerce projects are basic CRUD apps. GlowKart has two features that required real design decisions:

1. **Skin-type matching** — users set their allergen list (e.g. sulfate, alcohol, fragrance). The platform filters products in real time, showing only items whose ingredient list contains none of the user's flagged allergens. This required a many-to-many `product_ingredients` junction table and a multi-JOIN exclusion query.

2. **Bottle-return cashback** — users who return empty bottles get a cashback discount automatically applied on their next order. The cashback logic runs as a single transaction: check verified returns → sum cashback → create order → reduce stock → mark returns as `applied`. Returns can never be double-counted across orders.

---

## Tech stack

| Layer | Technology |
|---|---|
| Frontend | HTML, CSS, JavaScript (vanilla) |
| Backend | Python, FastAPI |
| Database | PostgreSQL (Supabase) |
| Deployment | Vercel (frontend), Render (backend) |

---

## Database schema (3NF)

9 tables, normalised to Third Normal Form:

```
users           — name, email, hashed password
skin_profiles   — skin type + allergen list (1:1 with users)
categories      — product categories
products        — name, description, price, stock, category
ingredients     — ingredient master list
product_ingredients — M:N junction: products ↔ ingredients
carts / cart_items  — active cart per user
orders / order_items — placed orders with price-at-purchase snapshot
bottle_returns  — return submissions with status: pending → verified → applied
```

**Key design decisions:**
- `price_at_purchase` stored separately on `order_items` — product prices can change, but past orders must always reflect what the customer actually paid
- `bottle_returns.status` follows a state machine (pending → verified → applied) — prevents cashback from being claimed more than once
- `product_ingredients` many-to-many junction enables the allergen exclusion query without any denormalisation

---

## Core API endpoints

```
GET  /products                        — all products
GET  /products/recommended?allergens= — skin-safe filtered products
GET  /products/{id}                   — product detail with ingredients
GET  /ingredients                     — full ingredient list
POST /auth/signup                     — register new user
POST /auth/login                      — login with hashed password check
GET  /skin-profile/{user_id}          — fetch saved allergen profile
PUT  /skin-profile                    — save allergen profile to DB
POST /orders                          — place order with cashback logic
```

---

## Features

- 🔍 **Live allergen filtering** — tick any ingredients to avoid, products refresh instantly
- 🧴 **Product detail modal** — shows full ingredient list with flagged allergens highlighted
- 🛒 **Cart drawer** — add/remove items, adjust quantity
- ♻️ **Bottle-return cashback** — automatically applied at checkout, verified against DB
- 👤 **Auth** — signup/login with hashed passwords (sha256_crypt), skin profile saved per user
- 📊 **19 products** across 4 categories (Skincare, Haircare, Makeup, Bath & Body)

---

## Running locally

**Prerequisites:** Python 3.10+, PostgreSQL

```bash
# Clone the repo
git clone https://github.com/archishagoel/GlowKart.git
cd GlowKart/glowkart-backend

# Create virtual environment
python -m venv venv
venv\Scripts\activate  # Windows

# Install dependencies
pip install -r requirements.txt

# Create .env file
echo DATABASE_URL=postgresql://postgres:PASSWORD@localhost:5432/glowkart > .env

# Run schema and seed data
# (open pgAdmin, run glowkart_schema.sql → seed_data.sql → extra_seed_data.sql)

# Start the server
uvicorn main:app --reload
```

Open `glowkart-frontend/index.html` in your browser.

---

## Project structure

```
GlowKart/
├── glowkart-backend/
│   ├── main.py              # FastAPI app — all endpoints
│   ├── requirements.txt
│   └── .gitignore
├── glowkart-frontend/
│   └── index.html           # Single-page frontend
├── schema.sql               # CREATE TABLE statements (3NF)
├── seed_data.sql            # Base sample data
└── extra_seed_data.sql      # Additional products and ingredients
```

---

## What I learned building this

- Designing a relational schema from business rules, not from code
- Why route ordering matters in FastAPI (specific routes before dynamic ones)
- Transactional integrity — `conn.commit()` and why all-or-nothing matters for orders
- Debugging dependency issues (bcrypt 72-byte limit → switched to sha256_crypt)
- CORS, environment variables, and the difference between local and deployed environments
- Connecting a Python backend to a cloud PostgreSQL instance (Supabase session pooler)
