import json

names = [
    ("Ahmed", "Mohamed"), ("Mahmoud", "Ali"), ("Youssef", "Hassan"), ("Omar", "Ibrahim"),
    ("Khaled", "Abdullah"), ("Tarek", "Saeed"), ("Mostafa", "Gamal"), ("Ramy", "Fouad"),
    ("Samer", "Nabil"), ("Wael", "Tawfik"), ("Karim", "Magdy"), ("Hussein", "Kamal"),
    ("Samir", "Adel"), ("Hesham", "Salah"), ("Amr", "Farouk"), ("Maged", "Mansour"),
    ("Walid", "Galal")
]

def main():
    path = 'assets/data/providers.json'
    with open(path, 'r', encoding='utf-8') as f:
        providers = json.load(f)
        
    for i, p in enumerate(providers):
        first, last = names[i % len(names)]
        p['first_name'] = first
        p['last_name'] = last
        
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(providers, f, ensure_ascii=False, indent=4)
        
    print("Names updated to English!")

if __name__ == '__main__':
    main()
