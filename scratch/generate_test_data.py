import os
import csv

# Student Data Preparation (36 unique students)
students_data = [
    ["Aditya","Wibowo","081234560001","male","01-02-2014","15-07-2025","Jl. Semeru No. 71, Kota Malang","Jl. Semeru No. 71, Kota Malang","agus.wibowo@gmail.com","Agus","Wibowo","089533220000","male"],
    ["Bella","Setiawan","081234560002","female","05-04-2018","15-07-2025","Jl. Semeru No. 27, Kota Malang","Jl. Semeru No. 27, Kota Malang","dewi.setiawan@gmail.com","Dewi","Setiawan","089533220001","female"],
    ["Cakra","Nugroho","081234560003","male","18-12-2014","15-07-2025","Jl. Veteran No. 109, Kota Malang","Jl. Veteran No. 109, Kota Malang","chandra.nugroho@gmail.com","Chandra","Nugroho","089533220002","male"],
    ["Della","Suryono","081234560004","female","03-01-2019","15-07-2025","Jl. Soekarno Hatta No. 60, Kota Malang","Jl. Soekarno Hatta No. 60, Kota Malang","fitri.suryono@gmail.com","Fitri","Suryono","089533220003","female"],
    ["Erlangga","Pratama","081234560005","male","01-10-2015","15-07-2025","Jl. Danau Toba No. 51, Kota Malang","Jl. Danau Toba No. 51, Kota Malang","eko.pratama@gmail.com","Eko","Pratama","089533220004","male"],
    ["Fitri","Saputra","081234560006","female","23-11-2014","15-07-2025","Jl. Danau Toba No. 108, Kota Malang","Jl. Danau Toba No. 108, Kota Malang","hesti.saputra@gmail.com","Hesti","Saputra","089533220005","female"],
    ["Gilang","Kusuma","081234560007","male","19-08-2018","15-07-2025","Jl. Borobudur No. 2, Kota Malang","Jl. Borobudur No. 2, Kota Malang","gunawan.kusuma@gmail.com","Gunawan","Kusuma","089533220006","male"],
    ["Hana","Laksana","081234560011","female","14-12-2018","15-07-2025","Jl. Gajayana No. 72, Kota Malang","Jl. Gajayana No. 72, Kota Malang","kartika.laksana@gmail.com","Kartika","Laksana","089533220007","female"],
    ["Ilham","Budiman","081234560012","male","25-04-2018","15-07-2025","Jl. Gajayana No. 27, Kota Malang","Jl. Gajayana No. 27, Kota Malang","iwan.budiman@gmail.com","Iwan","Budiman","089533220008","male"],
    ["Jasmine","Harahap","081234560013","female","04-07-2019","15-07-2025","Jl. Gajayana No. 89, Kota Malang","Jl. Gajayana No. 89, Kota Malang","rina.harahap@gmail.com","Rina","Harahap","089533220009","female"],
    ["Kevin","Siregar","081234560014","male","26-05-2015","15-07-2025","Jl. Ijen No. 118, Kota Malang","Jl. Ijen No. 118, Kota Malang","kurniawan.siregar@gmail.com","Kurniawan","Siregar","089533220010","male"],
    ["Laras","Tanjung","081234560015","female","13-02-2015","15-07-2025","Jl. Veteran No. 142, Kota Malang","Jl. Veteran No. 142, Kota Malang","sri.tanjung@gmail.com","Sri","Tanjung","089533220011","female"],
    ["Muhammad","Lubis","081234560016","male","20-11-2017","15-07-2025","Jl. Jakarta No. 93, Kota Malang","Jl. Jakarta No. 93, Kota Malang","mulyadi.lubis@gmail.com","Mulyadi","Lubis","089533220012","male"],
    ["Nadia","Nasution","081234560017","female","23-04-2015","15-07-2025","Jl. Veteran No. 12, Kota Malang","Jl. Veteran No. 12, Kota Malang","niken.nasution@gmail.com","Niken","Nasution","089533220013","female"],
    ["Ovan","Ginting","081234560018","male","25-04-2014","15-07-2025","Jl. Borobudur No. 21, Kota Malang","Jl. Borobudur No. 21, Kota Malang","rudi.ginting@gmail.com","Rudi","Ginting","089533220014","male"],
    ["Putri","Simanjuntak","081234560019","female","13-02-2018","15-07-2025","Jl. Borobudur No. 117, Kota Malang","Jl. Borobudur No. 117, Kota Malang","ratna.simanjuntak@gmail.com","Ratna","Simanjuntak","089533220015","female"],
    ["Rafi","Pane","081234560020","male","06-06-2014","15-07-2025","Jl. Gajayana No. 91, Kota Malang","Jl. Gajayana No. 91, Kota Malang","taufik.pane@gmail.com","Taufik","Pane","089533220016","male"],
    ["Rania","Siahaan","081234560021","female","09-11-2018","15-07-2025","Jl. Semeru No. 19, Kota Malang","Jl. Semeru No. 19, Kota Malang","endah.siahaan@gmail.com","Endah","Siahaan","089533220017","female"],
    ["Tegar","Sinaga","081234560022","male","06-11-2015","15-07-2025","Jl. Danau Toba No. 63, Kota Malang","Jl. Danau Toba No. 63, Kota Malang", "wawan.sinaga@gmail.com","Wawan","Sinaga","089533220018","male"],
    ["Tiara","Sitorus","081234560023","female","13-08-2018","15-07-2025","Jl. Borobudur No. 143, Kota Malang","Jl. Borobudur No. 143, Kota Malang","maya.sitorus@gmail.com","Maya","Sitorus","089533220019","female"],
    ["Valen","Manurung","081234560024","male","11-11-2018","15-07-2025","Jl. Jakarta No. 15, Kota Malang","Jl. Jakarta No. 15, Kota Malang","zainal.manurung@gmail.com","Zainal","Manurung","089533220020","male"],
    ["Viona","Tambunan","081234560025","female","26-01-2018","15-07-2025","Jl. Gajayana No. 103, Kota Malang","Jl. Gajayana No. 103, Kota Malang","ayu.tambunan@gmail.com","Ayu","Tambunan","089533220021","female"],
    ["Yuda","Tampubolon","081234560026","male","07-02-2017","15-07-2025","Jl. Ki Ageng Gribig No. 81, Kota Malang","Jl. Ki Ageng Gribig No. 81, Kota Malang","heri.tampubolon@gmail.com","Heri","Tampubolon","089533220022","male"],
    ["Yasmin","Sitompul","081234560027","female","16-11-2018","15-07-2025","Jl. Bendungan Sigura-gura No. 118, Kota Malang","Jl. Bendungan Sigura-gura No. 118, Kota Malang","amalia.sitompul@gmail.com","Amalia","Sitompul","089533220023","female"],
    ["Aldo","Marpaung","081234560028","male","05-05-2018","15-07-2025","Jl. Soekarno Hatta No. 144, Kota Malang","Jl. Soekarno Hatta No. 144, Kota Malang","guntur.marpaung@gmail.com","Guntur","Marpaung","089533220024","male"],
    ["Amelia","Pangaribuan","081234560029","female","24-05-2015","15-07-2025","Jl. Ki Ageng Gribig No. 110, Kota Malang","Jl. Ki Ageng Gribig No. 110, Kota Malang","zahra.pangaribuan@gmail.com","Zahra","Pangaribuan","089533220025","female"],
    ["Dika","Simatupang","081234560030","male","12-07-2015","15-07-2025","Jl. Soekarno Hatta No. 36, Kota Malang","Jl. Soekarno Hatta No. 36, Kota Malang","surya.simatupang@gmail.com","Surya","Simatupang","089533220026","male"],
    ["Erika","Hutagalung","081234560031","female","03-08-2015","15-07-2025","Jl. Surabaya No. 13, Kota Malang","Jl. Surabaya No. 13, Kota Malang","dian.hutagalung@gmail.com","Dian","Hutagalung","089533220027","female"],
    ["Genta","Rambe","081234560032","male","21-03-2019","15-07-2025","Jl. Dinoyo No. 109, Kota Malang","Jl. Dinoyo No. 109, Kota Malang","arif.rambe@gmail.com","Arif","Rambe","089533220028","male"],
    ["Geby","Ritonga","081234560033","female","13-02-2015","15-07-2025","Jl. Bendungan Sigura-gura No. 120, Kota Malang","Jl. Bendungan Sigura-gura No. 120, Kota Malang","tika.ritonga@gmail.com","Tika","Ritonga","089533220029","female"],
    ["Iqbal","Situmorang","081234560034","male","18-05-2015","15-07-2025","Jl. Jakarta No. 3, Kota Malang","Jl. Jakarta No. 3, Kota Malang","agus.situmorang@gmail.com","Agus","Situmorang","089533220030","male"],
    ["Julia","Silaban","081234560035","female","04-12-2014","15-07-2025","Jl. Kawi No. 138, Kota Malang","Jl. Kawi No. 138, Kota Malang","dewi.silaban@gmail.com","Dewi","Silaban","089533220031","female"],
    ["Kiki","Pohan","081234560036","male","11-11-2017","15-07-2025","Jl. Veteran No. 76, Kota Malang","Jl. Veteran No. 76, Kota Malang","chandra.pohan@gmail.com","Chandra","Pohan","089533220032","male"],
    ["Niken","Harianja","081234560037","female","15-03-2016","15-07-2025","Jl. Ijen No. 68, Kota Malang","Jl. Ijen No. 68, Kota Malang","fitri.harianja@gmail.com","Fitri","Harianja","089533220033","female"],
    ["Tyo","Banjarnahor","081234560038","male","17-03-2015","15-07-2025","Jl. Veteran No. 77, Kota Malang","Jl. Veteran No. 77, Kota Malang","eko.banjarnahor@gmail.com","Eko","Banjarnahor","089533220034","male"],
    ["Zidny","Ilman","081234560039","male","10-10-2018","15-07-2025","Jl. Ijen No. 1, Kota Malang","Jl. Ijen No. 1, Kota Malang","zidny.ilman@gmail.com","Zidny","Ilman","089533220035","male"]
]

header = ["first_name","last_name","mobile","gender","dob","admission_date","current_address","permanent_address","guardian_email","guardian_first_name","guardian_last_name","guardian_mobile","guardian_gender"]

fees_header = ["admission_number", "student_name", "fee_group", "fee_type", "due_date", "amount", "status"]

# 12 Classes (3 levels x 4 majors)
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
    except Exception as e:
        # Fallback to current directory if C:\ is not accessible
        base_dir = os.path.join(os.getcwd(), "Data_Test_SMK100")
        os.makedirs(base_dir, exist_ok=True)

student_dir = os.path.join(base_dir, "Siswa_Data")
fees_dir = os.path.join(base_dir, "Fees_Data")

os.makedirs(student_dir, exist_ok=True)
os.makedirs(fees_dir, exist_ok=True)

for i, class_name in enumerate(classes):
    # Take 3 students for each class
    start_index = i * 3
    end_index = start_index + 3
    class_students = students_data[start_index:end_index]
    
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
        admission_num = s[2][-4:] # Dummy admission number
        full_name = f"{s[0]} {s[1]}"
        fees_data.append([admission_num, full_name, "SPP Bulanan", "Juli 2025", "10-07-2025", "500000", "Belum Lunas"])
        
    with open(fees_file_path, mode='w', newline='') as file:
        writer = csv.writer(file)
        writer.writerow(fees_header)
        writer.writerows(fees_data)

print(f"Generated 12 student files and 12 fee files in: {base_dir}")
