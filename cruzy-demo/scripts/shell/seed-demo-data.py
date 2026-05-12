"""
Cruzy Demo — Bulk Data Seeder
Creates realistic demo data across all custom objects.
Usage: python3 scripts/shell/seed-demo-data.py
"""
import json, urllib.request, urllib.error, subprocess, random, sys
from datetime import date, timedelta

# ── Auth ──────────────────────────────────────────────────────────────────────
raw = subprocess.run(
    ["/usr/local/bin/sf", "org", "display", "--target-org", "cruzy-demo", "--verbose", "--json"],
    capture_output=True, text=True
)
org = json.loads(raw.stdout)["result"]
BASE = org["instanceUrl"] + "/services/data/v62.0"
HEADERS = {"Authorization": f"Bearer {org['accessToken']}", "Content-Type": "application/json"}

def post(path, payload):
    req = urllib.request.Request(f"{BASE}{path}", data=json.dumps(payload).encode(), method="POST", headers=HEADERS)
    try:
        resp = urllib.request.urlopen(req)
        return json.loads(resp.read().decode())
    except urllib.error.HTTPError as e:
        body = e.read().decode()
        print(f"  ERROR {e.code} on {path}: {body[:200]}")
        return None

def patch(path, payload):
    req = urllib.request.Request(f"{BASE}{path}", data=json.dumps(payload).encode(), method="PATCH", headers=HEADERS)
    try:
        urllib.request.urlopen(req)
        return True
    except urllib.error.HTTPError as e:
        print(f"  ERROR PATCH {path}: {e.read().decode()[:200]}")
        return False

def bulk_post(path, records, label):
    created = []
    for i, r in enumerate(records):
        result = post(path, r)
        if result and result.get("success"):
            created.append(result["id"])
        if (i+1) % 10 == 0:
            print(f"  {label}: {i+1}/{len(records)}")
    print(f"  ✓ {label}: {len(created)}/{len(records)} created")
    return created

def days_from_now(n):
    return (date.today() + timedelta(days=n)).isoformat()

def random_date(start_days, end_days):
    n = random.randint(start_days, end_days)
    return days_from_now(n)

# ── Existing contacts ─────────────────────────────────────────────────────────
CONTACT_IDS = [
    "003JX00000z81TgYAI",  # Scott Marshfield
    "003JX00000z81TiYAI",  # Jennifer Henderson
    "003JX00000z81TkYAI",  # Marcus Kowalski
    "003JX00000z81TlYAI",  # Linda Tran
    "003JX00000z81TmYAI",  # Robert Delgado
    "003JX00000z81TnYAI",  # Danielle Fontaine
    "003JX00000z81ToYAI",  # Theo Okafor
    "003JX00000z81TpYAI",  # Patricia Whitmore
    "003JX00000z81TqYAI",  # Raj Patel
    "003JX00000z81TrYAI",  # Mai Nguyen
    "003JX00000z81TsYAI",  # Carlos Rivera
    "003JX00000z81TtYAI",  # Beth Castellano
    "003JX00000z81TuYAI",  # Tony Drummond
    "003JX00000z81TvYAI",  # Shonda Leake
    "003JX00000z81TwYAI",  # Greg Sorensen
    "003JX00000z81TyYAI",  # Melissa Yates
    "003JX00000z81TzYAI",  # James Blackwell
    "003JX00000z81U0YAI",  # Tamara Pruitt
    "003JX00000z81U1YAI",  # Devon Hargrove
    "003JX00000z81U2YAI",  # Willie Tillman
]

# ── Reference data ────────────────────────────────────────────────────────────
SHIPS = [
    "Carnival Celebration", "Carnival Elation", "Carnival Glory",
    "Carnival Horizon", "Carnival Jubilee", "Carnival Magic",
    "Carnival Radiance", "Carnival Sunshine", "Carnival Valor", "Carnival Vista",
]
ITINERARIES = [
    "Bahamas 5-Night", "Caribbean 7-Night", "Mexico 4-Night",
    "Bermuda 8-Night", "Alaska 7-Night", "Mediterranean 12-Night",
    "Western Caribbean 6-Night", "Eastern Caribbean 7-Night",
]
PORTS = ["Miami, FL", "Port Canaveral, FL", "Galveston, TX", "Long Beach, CA", "Baltimore, MD", "New York, NY"]
# PCC__c is a Contact lookup — use real Contact IDs as agent reps
PCCS = [
    "003JX00000z81TgYAI",  # Scott Marshfield
    "003JX00000z81TiYAI",  # Jennifer Henderson
    "003JX00000z81TkYAI",  # Marcus Kowalski
    "003JX00000z81TlYAI",  # Linda Tran
    "003JX00000z81TmYAI",  # Robert Delgado
    "003JX00000z81TnYAI",  # Danielle Fontaine
]
CABIN_CATS = ["Interior", "Ocean View", "Balcony", "Suite", "Extended Balcony"]
BOOKING_STATUSES = ["Booking", "Booking", "Booking", "Quote", "Quote", "Completed"]
VIFP_LEVELS = ["Red", "Gold", "Platinum", "Diamond", "Diamond Plus"]
ADDON_TYPES = ["Shore Excursion", "Drink Package", "Specialty Dining", "Wi-Fi Package", "Photo Package", "Spa Package"]
# max length 10
REWARD_LOCATIONS = ["OBC", "Free", "Upgrade", "Dining", "Excursion"]
PARTNERS = ["Carnival", "VIFP Program", "Cruzy Plus", "Travel Agent Partner"]

print("=" * 60)
print("CRUZY DEMO DATA SEEDER")
print("=" * 60)

# ── 1. Update Contacts with VIFP levels, PCCs, flags ─────────────────────────
print("\n[1] Updating Contact fields...")
vifp_dist = ["Red"] * 6 + ["Gold"] * 6 + ["Platinum"] * 4 + ["Diamond"] * 3 + ["Diamond Plus"] * 1
contact_updates = [
    {
        "VIFP_Level__c": vifp_dist[i % len(vifp_dist)],
        "Customer_Source__c": random.choice(["Web", "Phone", "Referral", "Travel Agent", "Walk-In"]),
        "Cruzy_Plus_Pitched__c": random.random() > 0.3,
        "Cruzy_Plus_Enrolled__c": random.random() > 0.5,
    }
    for i, _ in enumerate(CONTACT_IDS)
]
updated = 0
for cid, upd in zip(CONTACT_IDS, contact_updates):
    if patch(f"/sobjects/Contact/{cid}", upd):
        updated += 1
print(f"  ✓ Updated {updated}/{len(CONTACT_IDS)} contacts")

# ── 2. New Contacts (20 more) ─────────────────────────────────────────────────
print("\n[2] Creating new contacts...")
new_contacts_data = [
    ("Anna",     "Petrov",     "Gold"),
    ("Marcus",   "Webb",       "Platinum"),
    ("Claire",   "Dupont",     "Diamond"),
    ("Hector",   "Reyes",      "Red"),
    ("Sasha",    "Kim",        "Gold"),
    ("Brianna",  "Foster",     "Platinum"),
    ("Darius",   "Osei",       "Red"),
    ("Ingrid",   "Larsen",     "Gold"),
    ("Felix",    "Montoya",    "Diamond"),
    ("Nadia",    "Volkov",     "Red"),
    ("Jerome",   "Banks",      "Platinum"),
    ("Priya",    "Sharma",     "Diamond Plus"),
    ("Owen",     "Fletcher",   "Gold"),
    ("Tanya",    "Moore",      "Red"),
    ("Rafael",   "Cruz",       "Platinum"),
    ("Simone",   "Dubois",     "Diamond"),
    ("Kevin",    "Park",       "Red"),
    ("Yasmin",   "Al-Hassan",  "Gold"),
    ("Bradley",  "Nguyen",     "Platinum"),
    ("Chloe",    "Washington", "Red"),
]
new_contact_records = []
for i, (first, last, vifp) in enumerate(new_contacts_data):
    new_contact_records.append({
        "FirstName": first,
        "LastName": last,
        "Email": f"{first.lower()}.{last.lower()}@demo.cruzy.com",
        "Phone": f"555-{random.randint(100,999)}-{random.randint(1000,9999)}",
        "VIFP_Level__c": vifp,
        "Customer_Source__c": random.choice(["Web", "Phone", "Referral", "Travel Agent"]),
        "Cruzy_Plus_Pitched__c": random.random() > 0.3,
        "Cruzy_Plus_Enrolled__c": random.random() > 0.5,
    })
new_contact_ids = bulk_post("/sobjects/Contact", new_contact_records, "New Contacts")
ALL_CONTACTS = CONTACT_IDS + new_contact_ids

# ── 3. Bookings (50 new) ──────────────────────────────────────────────────────
print("\n[3] Creating bookings...")
booking_names_used = set()
def unique_booking_name(prefix):
    n = f"{prefix}-{random.randint(10000,99999)}"
    while n in booking_names_used:
        n = f"{prefix}-{random.randint(10000,99999)}"
    booking_names_used.add(n)
    return n

bookings = []
for i, contact_id in enumerate(ALL_CONTACTS):
    num_bookings = random.randint(1, 4)
    for j in range(num_bookings):
        status = random.choices(
            ["Booking", "Quote", "Completed", "Cancelled"],
            weights=[35, 30, 30, 5]
        )[0]
        total = round(random.uniform(800, 8500), 2)
        balance = 0 if status in ("Completed", "Cancelled") else round(total * random.uniform(0, 0.7), 2)
        dep_days = random.randint(-180, 365)
        initials = "".join([w[0].upper() for w in contact_id[-4:] if w.isalpha()])[:2] or "XX"
        bookings.append({
            "Name": unique_booking_name(f"BK-{initials}"),
            "Contact__c": contact_id,
            "Status__c": status,
            "Ship__c": random.choice(SHIPS),
            "Itinerary__c": random.choice(ITINERARIES),
            "Departure_Port__c": random.choice(PORTS),
            "Departure_Date__c": random_date(dep_days, dep_days + 1),
            "Cabin_Category__c": random.choice(CABIN_CATS),
            "PAX_Count__c": random.randint(1, 6),
            "Original_Cruise_Total__c": total,
            "Current_Balance_Due__c": balance,
            "Quote_Type__c": random.choice(["Reward", "Reward - Referral", "Member", "Cruzy+ Member", "B2C Direct"]),
        })
        if len(bookings) >= 80:
            break
    if len(bookings) >= 80:
        break

booking_ids = bulk_post("/sobjects/Booking__c", bookings, "Bookings")

# ── 4. Booking Payments ───────────────────────────────────────────────────────
print("\n[4] Creating booking payments...")
payments = []
for bid in booking_ids:
    num_pmts = random.randint(1, 3)
    for _ in range(num_pmts):
        payments.append({
            "Booking__c": bid,
            "Amount__c": round(random.uniform(200, 2000), 2),
            "Payment_Date__c": random_date(-365, -1),
            "Note__c": random.choice(["Deposit", "Final Payment", "Partial Payment", "Stripe charge", "Balance payment"]),
        })
        if len(payments) >= 120:
            break
    if len(payments) >= 120:
        break
bulk_post("/sobjects/Booking_Payment__c", payments, "Booking Payments")

# ── 5. Add-Ons ────────────────────────────────────────────────────────────────
print("\n[5] Creating add-ons...")
addons = []
for bid in random.sample(booking_ids, min(60, len(booking_ids))):
    num_addons = random.randint(1, 3)
    for _ in range(num_addons):
        addons.append({
            "Booking__c": bid,
            "Add_On_Type__c": random.choice(ADDON_TYPES),
            "Amount__c": round(random.uniform(25, 350), 2),
        })
bulk_post("/sobjects/Add_On__c", addons, "Add-Ons")

# ── 6. Memberships ────────────────────────────────────────────────────────────
print("\n[6] Creating memberships...")
memberships = []
for contact_id in random.sample(ALL_CONTACTS, min(30, len(ALL_CONTACTS))):
    status = random.choices(
        ["Active", "Active", "Active", "Inactive", "On Hold", "Cancelled"],
        weights=[40, 20, 10, 15, 10, 5]
    )[0]
    enroll = random_date(-730, -30)
    biennial = random.random() > 0.7
    exp_days = 730 if biennial else 365
    memberships.append({
        "Contact__c": contact_id,
        "Status__c": status,
        "Enroll_Date__c": enroll,
        "Expiration_Date__c": random_date(30, 400),
        "Next_Billing_Date__c": random_date(10, 200),
        "Auto_Renewal__c": random.random() > 0.3,
        "Biennial__c": biennial,
        "Partner__c": random.choice(PARTNERS),
        "Paid_Through__c": random_date(-30, 365),
    })
membership_ids = bulk_post("/sobjects/Membership__c", memberships, "Memberships")

# ── 7. Membership Payments ────────────────────────────────────────────────────
print("\n[7] Creating membership payments...")
mbr_payments = []
years = [2022, 2023, 2024, 2025, 2026]
for mid in membership_ids:
    for year in random.sample(years, random.randint(1, 3)):
        mbr_payments.append({
            "Membership__c": mid,
            "Amount_Paid__c": round(random.choice([99, 129, 149, 199, 249]), 2),
            "Date_Paid__c": f"{year}-{random.randint(1,12):02d}-{random.randint(1,28):02d}",
            "Renewal_Year__c": str(year),
        })
bulk_post("/sobjects/Membership_Payment__c", mbr_payments, "Membership Payments")

# ── 8. Rewards ────────────────────────────────────────────────────────────────
print("\n[8] Creating rewards...")
rewards = []
for contact_id in random.sample(ALL_CONTACTS, min(28, len(ALL_CONTACTS))):
    num_rewards = random.randint(1, 3)
    for _ in range(num_rewards):
        status = random.choices(
            ["Active", "Active", "Used", "Expired"],
            weights=[40, 20, 25, 15]
        )[0]
        issue = random_date(-365, -30)
        rewards.append({
            "Contact__c": contact_id,
            "Status__c": status,
            "Reward_Number__c": f"RWD-{random.randint(100000, 999999)}",
            "Reward_Location__c": random.choice(REWARD_LOCATIONS),
            "Issue_Date__c": issue,
            "Book_By_Date__c": random_date(10, 180),
            "Expiration_Date__c": random_date(15, 365),
            "Partner__c": random.choice(PARTNERS),
        })
reward_ids = bulk_post("/sobjects/Reward__c", rewards, "Rewards")

# ── 9. Saved Cards ────────────────────────────────────────────────────────────
print("\n[9] Creating saved cards...")
cards = []
brands = [("Visa", "4"), ("Mastercard", "5"), ("Amex", "3"), ("Discover", "6")]
for contact_id in random.sample(ALL_CONTACTS, min(35, len(ALL_CONTACTS))):
    num_cards = random.randint(1, 3)
    for j in range(num_cards):
        brand, prefix = random.choice(brands)
        last4 = f"{random.randint(1000,9999)}"
        cards.append({
            "Contact__c": contact_id,
            "Card_Brand__c": brand,
            "Last_Four__c": last4,
            "Expiry_Month__c": str(random.randint(1, 12)),
            "Expiry_Year__c": str(random.randint(2025, 2029)),
            "Cardholder_Name__c": "Demo Cardholder",
            "Is_Default__c": j == 0,
            "Stripe_Payment_Method_Id__c": f"pm_demo_{random.randint(100000000, 999999999)}",
        })
bulk_post("/sobjects/Saved_Card__c", cards, "Saved Cards")

# ── Done ──────────────────────────────────────────────────────────────────────
print("\n" + "=" * 60)
print("SEED COMPLETE")
print("=" * 60)
