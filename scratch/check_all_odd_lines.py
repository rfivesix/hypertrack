import os

def check_all_odd_lines():
    features_dir = "/Users/richardgeorgschotte/Projekte/train-libre/documentation/features"
    for filename in os.listdir(features_dir):
        if filename.endswith(".md"):
            filepath = os.path.join(features_dir, filename)
            with open(filepath, "r", encoding="utf-8") as f:
                for line_num, line in enumerate(f, 1):
                    line_clean = line.replace("\\$", "")
                    dollar_count = line_clean.count("$")
                    if dollar_count % 2 != 0:
                        print(f"ODD COUNT: {filename}:{line_num} count={dollar_count} | {line.strip()}")

if __name__ == "__main__":
    check_all_odd_lines()
