"""
Cruzy Demo — Bookings + Payments + Add-Ons Seeder
Run this to fill in the booking-side data.
"""
import json, urllib.request, urllib.error, subprocess, random
from datetime import date, timedelta

raw = subprocess.run(
    ["/usr/local/bin/sf", "org", "display", "--target-org", "cruzy-demo", "--verbose", "--json"],
    capture_output=True, text=True
)
org = json.loads(raw.stdout)["result"]
BASE = org["instanceUrl"] + "/services/data/v62.0"
HEADERS = {"Authorization": f"Bearer {org['accessToken']}", "Content-Type": "application/json"}

def get(path):
    req = urllib.request.Request(f"{BASE}{path}", headers=HEADERS)
    return json.loads(urllib.request.urlopen(req).read().decode())

def post(path, payload):
    req = urllib.request.Request(f"{BASE}{path}", data=json.dumps(payload).encode(), method="POST", headers=HEADERS)
    try:
        resp = urllib.request.urlopen(req)
        return json.loads(resp.read().decode())
    except urllib.error.HTTPError as e:
        body = e.read().decode()
        print(f"  ERR {e.code}: {body[:180]}")
        return None

def bulk_post(path, records, label):
    created = []
    for i, r in enumerate(records):
        res = post(path, r)
        if res and res.get("success"):
            created.append(res["id"])
        if (i + 1) % 20 == 0:
            print(f"  {label}: {i+1}/{len(records)}")
    print(f"  ✓ {label}: {len(created)}/{len(records)}")
    return created

def days_from_now(n):
    return (date.today() + timedelta(days=n)).isoformat()

SHIPS = [
    "Carnival Celebration", "Carnival Elation", "Carnival Glory",
    "Carnival Horizon", "Carnival Jubilee", "Carnival Magic",
    "Carnival Radiance", "Carnival Sunshine", "Carnival Valor", "Carnival Vista",
]
ITINERARIES = [
    "Bahamas 5-Night", "Caribbean 7-Night", "Mexico 4-Night",
    "Bermuda 8-Night", "Alaska 7-Night", "Western Caribbean 6-Night",
    "Eastern Caribbean 7-Night", "Southern Caribbean 10-Night",
]
PORTS = ["Miami, FL", "Port Canaveral, FL", "Galveston, TX", "Long Beach, CA", "Baltimore, MD", "New York, NY"]
CABIN_CATS = ["Interior", "Ocean View", "Balcony", "Suite", "Premium Suite"]
ADDON_TYPES = ["Shore Excursion", "Drink Package", "Dining Package", "Wi-Fi Package", "Photo Package", "Spa Package"]
QUOTE_TYPES = ["Reward", "Reward - Referral", "Member", "Cruzy+ Member", "B2C Direct"]
PAYMENT_NOTES = ["Deposit", "Final Payment", "Partial Payment", "Stripe charge", "Balance payment"]

print("=" * 60)
print("CRUZY BOOKING DATA SEEDER")
print("=" * 60)

# ── Fetch all contacts ────────────────────────────────────────────────────────
print("\nFetching contacts...")
result = get("/query/?q=SELECT+Id,Name+FROM+Contact+LIMIT+200")
contacts = result["records"]
print(f"  Found {len(contacts)} contacts")

# ── Build booking names set to avoid duplicates ───────────────────────────────
existing = get("/query/?q=SELECT+Name+FROM+Booking__c")
used_names = {r["Name"] for r in existing["records"]}

def unique_name(prefix):
    n = f"{prefix}-{random.randint(10000,99999)}"
    while n in used_names:
        n = f"{prefix}-{random.randint(10000,99999)}"
    used_names.add(n)
    return n

# ── Create bookings ───────────────────────────────────────────────────────────
print("\n[1] Creating bookings...")
bookings = []
for contact in contacts:
    num_bookings = random.randint(1, 4)
    for _ in range(num_bookings):
        status = random.choices(
            ["Booking", "Booking", "Quote", "Completed", "Cancelled"],
            weights=[30, 20, 25, 20, 5]
        )[0]
        total = round(random.uniform(800, 9500), 2)
        balance = 0 if status in ("Completed", "Cancelled") else round(total * random.uniform(0, 0.75), 2)
        dep_days = random.randint(-200, 400)
        prefix = "BK-" + "".join(c for c in contact["Name"].split()[0][:3].upper())
        bookings.append({
            "Name": unique_name(prefix),
            "Contact__c": contact["Id"],
            "Status__c": status,
            "Ship__c": random.choice(SHIPS),
            "Itinerary__c": random.choice(ITINERARIES),
            "Departure_Port__c": random.choice(PORTS),
            "Departure_Date__c": (date.today() + timedelta(days=dep_days)).isoformat(),
            "Cabin_Category__c": random.choice(CABIN_CATS),
            "PAX_Count__c": random.randint(1, 6),
            "Original_Cruise_Total__c": total,
            "Current_Balance_Due__c": balance,
            "Quote_Type__c": random.choice(QUOTE_TYPES),
        })
    if len(bookings) >= 120:
        break

booking_ids = bulk_post("/sobjects/Booking__c", bookings, "Bookings")

# ── Booking Payments ──────────────────────────────────────────────────────────
print("\n[2] Creating booking payments...")
payments = []
for bid in booking_ids:
    for _ in range(random.randint(1, 3)):
        payments.append({
            "Booking__c": bid,
            "Amount__c": round(random.uniform(150, 2500), 2),
            "Payment_Date__c": (date.today() - timedelta(days=random.randint(1, 500))).isoformat(),
            "Note__c": random.choice(PAYMENT_NOTES),
        })
bulk_post("/sobjects/Booking_Payment__c", payments, "Booking Payments")

# ── Add-Ons ───────────────────────────────────────────────────────────────────
print("\n[3] Creating add-ons...")
addons = []
sample_bids = random.sample(booking_ids, min(80, len(booking_ids)))
for bid in sample_bids:
    for _ in range(random.randint(1, 3)):
        addons.append({
            "Booking__c": bid,
            "Add_On_Type__c": random.choice(ADDON_TYPES),
            "Amount__c": round(random.uniform(20, 400), 2),
        })
bulk_post("/sobjects/Add_On__c", addons, "Add-Ons")

print("\n" + "=" * 60)
print("DONE")
print("=" * 60)
