import os
import csv
import random

# More extensive name pool for ~1300 unique students
first_names = [
    "Aditya", "Bella", "Cakra", "Della", "Erlangga", "Fitri", "Gilang", "Hana", "Ilham", "Jasmine", 
    "Kevin", "Laras", "Muhammad", "Nadia", "Ovan", "Putri", "Rafi", "Rania", "Tegar", "Tiara", 
    "Valen", "Viona", "Yuda", "Yasmin", "Aldo", "Amelia", "Dika", "Erika", "Genta", "Geby", 
    "Iqbal", "Julia", "Kiki", "Niken", "Tyo", "Zidny", "Budi", "Siti", "Agus", "Dewi", 
    "Eko", "Lestari", "Bambang", "Wahyu", "Sri", "Joko", "Andi", "Linda", "Ratna", "Sari",
    "Hendra", "Maya", "Rina", "Dedi", "Ani", "Surya", "Indah", "Rizky", "Putu", "Made",
    "Nyoman", "Ketut", "Ahmad", "Nur", "Siska", "Fajar", "Bintang", "Gusti", "Putra", "Dewi",
    "Bagio", "Slamet", "Kusumo", "Wati", "Sari", "Agung", "Prabowo", "Sandi", "Anies", "Ganjar"
]
last_names = [
    "Wibowo", "Setiawan", "Nugroho", "Suryono", "Pratama", "Saputra", "Kusuma", "Laksana", "Budiman", "Harahap", 
    "Siregar", "Tanjung", "Lubis", "Nasution", "Ginting", "Simanjuntak", "Pane", "Siahaan", "Sinaga", "Sitorus", 
    "Manurung", "Tambunan", "Tampubolon", "Sitompul", "Marpaung", "Pangaribuan", "Simatupang", "Hutagalung", "Rambe", "Ritonga", 
    "Situmorang", "Silaban", "Pohan", "Harianja", "Banjarnahor", "Ilman", "Susilo", "Mulyadi", "Wijaya", "Santoso", 
    "Hidayat", "Saputro", "Utomo", "Wardani", "Rahayu", "Gunawan", "Permana", "Kurniawan", "Sholeh", "Maulana",
    "Irawan", "Fauzi", "Hakim", "Zulkarnain", "Sulaiman", "Mansur", "Hadi", "Sucipto", "Mursalin", "Hartono"
]

def generate_unique_students(count, seen_mobiles):
    students = []
    while len(students) < count:
        fn = random.choice(first_names)
        ln = random.choice(last_names)
        # Random shuffle to make it more unique
        if random.random() > 0.5:
            fn, ln = ln, fn
            
        # Add a random middle Initial or number if pool is small
        if len(students) > 500:
             fn = f"{fn} {random.choice('ABCDEFGHIJKLMNOPQRSTUVWXYZ')}"
             
        mobile = f"0812{random.randint(10000000, 99999999)}"
        if mobile in seen_mobiles:
            continue
        seen_mobiles.add(mobile)
        
        gender = "male" if random.random() > 0.5 else "female"
        dob = f"{random.randint(1,28):02d}-{random.randint(1,12):02d}-{random.randint(2014, 2019)}"
        adm_date = "15-07-2025"
        addr = f"Jl. {random.choice(last_names)} No. {random.randint(1,200)}, Kota Malang"
        g_email = f"{fn.replace(' ','').lower()}.{ln.lower()}{random.randint(1,99)}@gmail.com"
        g_fn = random.choice(first_names)
        g_ln = ln
        g_mobile = f"0895{random.randint(10000000, 99999999)}"
        g_gender = "male" if random.random() > 0.5 else "female"
        
        students.append([fn, ln, mobile, gender, dob, adm_date, addr, addr, g_email, g_fn, g_ln, g_mobile, g_gender])
    return students

# Setup
header = ["first_name","last_name","mobile","gender","dob","admission_date","current_address","permanent_address","guardian_email","guardian_first_name","guardian_last_name","guardian_mobile","guardian_gender"]
fees_header = ["admission_number", "student_name", "fee_group", "fee_type", "due_date", "amount", "status"]

majors = ["ELIN", "METRO", "TKJ", "RPL"]
grades = ["X", "XI", "XII"]
sections = ["A", "B", "C"]

base_dir = r"C:\Data_Test_SMK100"
student_dir = os.path.join(base_dir, "Siswa_Complete_36_per_Kelas")
fees_dir = os.path.join(base_dir, "Fees_Complete_36_per_Kelas")

os.makedirs(student_dir, exist_ok=True)
os.makedirs(fees_dir, exist_ok=True)

seen_mobiles = set()

for grade in grades:
    for major in majors:
        if major == "RPL":
            # User said RPL is done, but for completeness and better structure, 
            # we can skip it or generate it to a different subfolder if needed.
            # I will skip it to respect the "kecuali yang rpl" part.
            continue
            
        for section in sections:
            class_name = f"{grade} {major} {section}"
            students = generate_unique_students(36, seen_mobiles)
            
            # Save Student CSV
            file_name = f"Siswa_{class_name.replace(' ', '_')}.csv"
            file_path = os.path.join(student_dir, file_name)
            with open(file_path, mode='w', newline='') as file:
                writer = csv.writer(file)
                writer.writerow(header)
                writer.writerows(students)
                
            # Save Fees CSV
            fees_file_name = f"Fees_{class_name.replace(' ', '_')}.csv"
            fees_file_path = os.path.join(fees_dir, fees_file_name)
            fees_data = []
            for s in students:
                admission_num = f"2025{random.randint(10000, 99999)}"
                full_name = f"{s[0]} {s[1]}"
                fees_data.append([admission_num, full_name, "SPP Bulanan", "Juli 2025", "10-07-2025", "500000", "Belum Lunas"])
                
            with open(fees_file_path, mode='w', newline='') as file:
                writer = csv.writer(file)
                writer.writerow(fees_header)
                writer.writerows(fees_data)

print(f"Data generation complete for ELIN, METRO, and TKJ (X, XI, XII) in {base_dir}")
