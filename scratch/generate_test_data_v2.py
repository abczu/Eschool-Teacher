import os
import csv
import random

# Base data provided by user
base_first_names = ["Aditya", "Bella", "Cakra", "Della", "Erlangga", "Fitri", "Gilang", "Hana", "Ilham", "Jasmine", "Kevin", "Laras", "Muhammad", "Nadia", "Ovan", "Putri", "Rafi", "Rania", "Tegar", "Tiara", "Valen", "Viona", "Yuda", "Yasmin", "Aldo", "Amelia", "Dika", "Erika", "Genta", "Geby", "Iqbal", "Julia", "Kiki", "Niken", "Tyo", "Zidny"]
base_last_names = ["Wibowo", "Setiawan", "Nugroho", "Suryono", "Pratama", "Saputra", "Kusuma", "Laksana", "Budiman", "Harahap", "Siregar", "Tanjung", "Lubis", "Nasution", "Ginting", "Simanjuntak", "Pane", "Siahaan", "Sinaga", "Sitorus", "Manurung", "Tambunan", "Tampubolon", "Sitompul", "Marpaung", "Pangaribuan", "Simatupang", "Hutagalung", "Rambe", "Ritonga", "Situmorang", "Silaban", "Pohan", "Harianja", "Banjarnahor", "Ilman"]

# Extra names to ensure we can reach 432+ unique combinations
extra_first = ["Budi", "Siti", "Agus", "Dewi", "Eko", "Lestari", "Bambang", "Wahyu", "Sri", "Joko", "Andi", "Linda", "Ratna", "Sari", "Hendra", "Maya", "Bambang", "Rina", "Dedi", "Ani", "Surya", "Indah", "Rizky", "Putu", "Made", "Nyoman", "Ketut"]
extra_last = ["Susilo", "Mulyadi", "Wijaya", "Santoso", "Hidayat", "Saputro", "Utomo", "Wardani", "Rahayu", "Gunawan", "Permana", "Kurniawan", "Sholeh", "Maulana", "Irawan", "Fauzi", "Hakim"]

all_first = list(set(base_first_names + extra_first))
all_last = list(set(base_last_names + extra_last))

def generate_unique_students(count):
    students = []
    seen_mobiles = set()
    
    # Pre-populate with user's specific samples if possible
    # (Actually it's easier to just generate from the pools to ensure uniqueness easily)
    
    while len(students) < count:
        fn = random.choice(all_first)
        ln = random.choice(all_last)
        mobile = f"0812{random.randint(10000000, 99999999)}"
        if mobile in seen_mobiles:
            continue
        seen_mobiles.add(mobile)
        
        gender = "male" if random.random() > 0.5 else "female"
        dob = f"{random.randint(1,28):02d}-{random.randint(1,12):02d}-{random.randint(2014, 2019)}"
        adm_date = "15-07-2025"
        addr = f"Jl. {random.choice(all_last)} No. {random.randint(1,200)}, Kota Malang"
        g_email = f"{fn.lower()}.{ln.lower()}{random.randint(1,99)}@gmail.com"
        g_fn = random.choice(all_first)
        g_ln = ln
        g_mobile = f"0895{random.randint(10000000, 99999999)}"
        g_gender = "male" if random.random() > 0.5 else "female"
        
        students.append([fn, ln, mobile, gender, dob, adm_date, addr, addr, g_email, g_fn, g_ln, g_mobile, g_gender])
    return students

header = ["first_name","last_name","mobile","gender","dob","admission_date","current_address","permanent_address","guardian_email","guardian_first_name","guardian_last_name","guardian_mobile","guardian_gender"]
fees_header = ["admission_number", "student_name", "fee_group", "fee_type", "due_date", "amount", "status"]

classes = [
    "X RPL 1", "X RPL 2", "X RPL 3",
    "XI RPL 1", "XI RPL 2", "XI RPL 3",
    "XII RPL 1", "XII RPL 2", "XII RPL 3",
    "X TKJ 1", "X TKJ 2", "X TKJ 3"
]

base_dir = r"C:\Data_Test_SMK100"
if not os.path.exists(base_dir):
    try:
        os.makedirs(base_dir)
    except:
        base_dir = os.path.join(os.getcwd(), "Data_Test_SMK100")
        os.makedirs(base_dir, exist_ok=True)

student_dir = os.path.join(base_dir, "Siswa_Data_36_per_Kelas")
fees_dir = os.path.join(base_dir, "Fees_Data_36_per_Kelas")

os.makedirs(student_dir, exist_ok=True)
os.makedirs(fees_dir, exist_ok=True)

for i, class_name in enumerate(classes):
    # Each class gets 36 unique students
    class_students = generate_unique_students(36)
    
    # Generate Student CSV
    file_name = f"Siswa_{class_name.replace(' ', '_')}.csv"
    file_path = os.path.join(student_dir, file_name)
    with open(file_path, mode='w', newline='') as file:
        writer = csv.writer(file)
        writer.writerow(header)
        writer.writerows(class_students)
        
    # Generate Fees CSV
    fees_file_name = f"Fees_{class_name.replace(' ', '_')}.csv"
    fees_file_path = os.path.join(fees_dir, fees_file_name)
    fees_data = []
    for s in class_students:
        admission_num = f"2025{random.randint(1000, 9999)}"
        full_name = f"{s[0]} {s[1]}"
        fees_data.append([admission_num, full_name, "SPP Bulanan", "Juli 2025", "10-07-2025", "500000", "Belum Lunas"])
        
    with open(fees_file_path, mode='w', newline='') as file:
        writer = csv.writer(file)
        writer.writerow(fees_header)
        writer.writerows(fees_data)

print(f"Generated 12 classes with 36 students each in: {base_dir}")
