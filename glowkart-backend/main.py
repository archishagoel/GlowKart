# main.py
# Run this with: uvicorn main:app --reload

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from passlib.context import CryptContext
import psycopg2
import psycopg2.extras
import os
from dotenv import load_dotenv

load_dotenv()
DATABASE_URL = os.getenv("DATABASE_URL")

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# CryptContext handles hashing and verifying passwords securely.
# We never store or compare plain-text passwords — only their hash.
pwd_context = CryptContext(schemes=["sha256_crypt"], deprecated="auto")


def get_connection():
    return psycopg2.connect(DATABASE_URL)


@app.get("/")
def read_root():
    return {"message": "GlowKart API is running"}


# ============================================
# AUTH: Signup and Login
# ============================================

class SignupRequest(BaseModel):
    name: str
    email: str
    password: str


class LoginRequest(BaseModel):
    email: str
    password: str


@app.post("/auth/signup")
def signup(req: SignupRequest):
    conn = get_connection()
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

    # Check if this email is already registered
    cur.execute("SELECT user_id FROM users WHERE email = %s;", (req.email,))
    existing = cur.fetchone()
    if existing:
        cur.close()
        conn.close()
        raise HTTPException(status_code=400, detail="An account with this email already exists")

    hashed_password = pwd_context.hash(req.password)

    cur.execute("""
        INSERT INTO users (name, email, password)
        VALUES (%s, %s, %s)
        RETURNING user_id, name, email;
    """, (req.name, req.email, hashed_password))
    new_user = cur.fetchone()

    # Every user gets an empty skin profile and cart created automatically at signup,
    # since both tables require a user_id to exist first (foreign key).
    cur.execute("INSERT INTO skin_profiles (user_id, skin_type, allergens) VALUES (%s, 'normal', '');", (new_user["user_id"],))
    cur.execute("INSERT INTO carts (user_id) VALUES (%s);", (new_user["user_id"],))

    conn.commit()
    cur.close()
    conn.close()

    return new_user


@app.post("/auth/login")
def login(req: LoginRequest):
    conn = get_connection()
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

    cur.execute("SELECT user_id, name, email, password FROM users WHERE email = %s;", (req.email,))
    user = cur.fetchone()
    cur.close()
    conn.close()

    # Same error message whether the email doesn't exist or the password is wrong —
    # this is a real security practice, so an attacker can't tell which one failed.
    if user is None or not pwd_context.verify(req.password, user["password"]):
        raise HTTPException(status_code=401, detail="Invalid email or password")

    return {"user_id": user["user_id"], "name": user["name"], "email": user["email"]}


@app.get("/products")
def get_products():
    conn = get_connection()
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
    cur.execute("SELECT product_id, name, description, price, stock FROM products;")
    products = cur.fetchall()
    cur.close()
    conn.close()
    return products


# ============================================
# IMPORTANT: this route MUST be declared before /products/{product_id}.
# FastAPI/Starlette checks routes in the order they're defined — if the
# dynamic {product_id} route came first, a request to /products/recommended
# would get caught by it, trying (and failing) to convert "recommended"
# into an integer. Declaring literal/specific paths before dynamic ones
# is a general rule worth remembering for any framework like this.
# ============================================
@app.get("/products/recommended")
def get_recommended_products(allergens: str = ""):
    allergen_list = [a.strip().lower() for a in allergens.split(",") if a.strip()]

    conn = get_connection()
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

    if not allergen_list:
        cur.execute("SELECT product_id, name, price FROM products ORDER BY product_id;")
    else:
        cur.execute("""
            SELECT DISTINCT p.product_id, p.name, p.price
            FROM products p
            WHERE p.product_id NOT IN (
                SELECT pi.product_id
                FROM product_ingredients pi
                JOIN ingredients i ON pi.ingredient_id = i.ingredient_id
                WHERE LOWER(i.ingredient_name) = ANY(%s)
            )
            ORDER BY p.product_id;
        """, (allergen_list,))

    products = cur.fetchall()
    cur.close()
    conn.close()
    return products


@app.get("/products/{product_id}")
def get_product_by_id(product_id: int):
    conn = get_connection()
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

    cur.execute("SELECT * FROM products WHERE product_id = %s;", (product_id,))
    product = cur.fetchone()

    if product is None:
        cur.close()
        conn.close()
        raise HTTPException(status_code=404, detail="Product not found")

    # Also fetch this product's ingredients, via the product_ingredients junction table —
    # this is what powers the detail view's ingredient list.
    cur.execute("""
        SELECT i.ingredient_name
        FROM product_ingredients pi
        JOIN ingredients i ON pi.ingredient_id = i.ingredient_id
        WHERE pi.product_id = %s
        ORDER BY i.ingredient_name;
    """, (product_id,))
    ingredient_rows = cur.fetchall()
    product["ingredients"] = [row["ingredient_name"] for row in ingredient_rows]

    cur.close()
    conn.close()
    return product


@app.get("/ingredients")
def get_ingredients():
    conn = get_connection()
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
    cur.execute("SELECT ingredient_id, ingredient_name FROM ingredients ORDER BY ingredient_name;")
    ingredients = cur.fetchall()
    cur.close()
    conn.close()
    return ingredients


# ============================================
# Save a logged-in user's skin type + allergens
# ============================================
@app.get("/skin-profile/{user_id}")
def get_skin_profile(user_id: int):
    conn = get_connection()
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
    cur.execute("SELECT skin_type, allergens FROM skin_profiles WHERE user_id = %s;", (user_id,))
    profile = cur.fetchone()
    cur.close()
    conn.close()
    if profile is None:
        raise HTTPException(status_code=404, detail="Profile not found")
    allergens = [a.strip() for a in profile["allergens"].split(",") if a.strip()]
    return {"skin_type": profile["skin_type"], "allergens": allergens}


# Class must be defined BEFORE the route that uses it
class SkinProfileRequest(BaseModel):
    user_id: int
    skin_type: str
    allergens: list[str]


@app.put("/skin-profile")
def update_skin_profile(req: SkinProfileRequest):
    conn = get_connection()
    cur = conn.cursor()
    allergens_str = ",".join(req.allergens)
    cur.execute("""
        UPDATE skin_profiles
        SET skin_type = %s, allergens = %s
        WHERE user_id = %s;
    """, (req.skin_type, allergens_str, req.user_id))
    conn.commit()
    cur.close()
    conn.close()
    return {"status": "updated"}


class OrderItemRequest(BaseModel):
    product_id: int
    quantity: int


class OrderRequest(BaseModel):
    user_id: int
    items: list[OrderItemRequest]


@app.post("/orders")
def place_order(order: OrderRequest):
    conn = get_connection()
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

    subtotal = 0
    item_prices = []

    for item in order.items:
        cur.execute("SELECT price, stock FROM products WHERE product_id = %s;", (item.product_id,))
        product = cur.fetchone()

        if product is None:
            cur.close()
            conn.close()
            raise HTTPException(status_code=404, detail=f"Product {item.product_id} not found")

        if product["stock"] < item.quantity:
            cur.close()
            conn.close()
            raise HTTPException(status_code=400, detail=f"Not enough stock for product {item.product_id}")

        line_total = product["price"] * item.quantity
        subtotal += line_total
        item_prices.append((item.product_id, item.quantity, product["price"]))

    cur.execute("""
        SELECT return_id, cashback_value
        FROM bottle_returns
        WHERE user_id = %s AND status = 'verified';
    """, (order.user_id,))
    returns = cur.fetchall()

    total_cashback = sum(r["cashback_value"] for r in returns)
    final_total = max(subtotal - total_cashback, 0)

    cur.execute("""
        INSERT INTO orders (user_id, status, total_amount, cashback_applied)
        VALUES (%s, 'placed', %s, %s)
        RETURNING order_id;
    """, (order.user_id, final_total, total_cashback))
    new_order_id = cur.fetchone()["order_id"]

    for product_id, quantity, price in item_prices:
        cur.execute("""
            INSERT INTO order_items (order_id, product_id, quantity, price_at_purchase)
            VALUES (%s, %s, %s, %s);
        """, (new_order_id, product_id, quantity, price))

        cur.execute("""
            UPDATE products SET stock = stock - %s WHERE product_id = %s;
        """, (quantity, product_id))

    for r in returns:
        cur.execute("""
            UPDATE bottle_returns SET status = 'applied' WHERE return_id = %s;
        """, (r["return_id"],))

    conn.commit()
    cur.close()
    conn.close()

    return {
        "order_id": new_order_id,
        "subtotal": subtotal,
        "cashback_applied": total_cashback,
        "final_total": final_total
    }