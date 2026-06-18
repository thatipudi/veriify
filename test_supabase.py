import psycopg2
import os
from dotenv import load_dotenv

load_dotenv()

url = os.getenv("DATABASE_URL")
if not url:
    print("❌ DATABASE_URL not set in .env — add your Supabase connection string first.")
    raise SystemExit(1)

try:
    conn = psycopg2.connect(
        url,
        connect_timeout=10,
        sslmode="require",  # Supabase requires SSL
    )
    cur = conn.cursor()
    cur.execute("SELECT version();")
    print("✅ Supabase connected:", cur.fetchone()[0])
    cur.close()
    conn.close()
except Exception as e:
    print(f"❌ Connection failed: {e}")
