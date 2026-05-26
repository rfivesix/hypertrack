import os

def find_any_single_dollar():
    features_dir = "/Users/richardgeorgschotte/Projekte/train-libre/documentation/features"
    count = 0
    for filename in os.listdir(features_dir):
        if filename.endswith(".md"):
            filepath = os.path.join(features_dir, filename)
            with open(filepath, "r") as f:
                for line_num, line in enumerate(f, 1):
                    # Replace double dollars first to not false match
                    line_clean = line.replace("$$", "")
                    if "$" in line_clean and "\\$" not in line_clean:
                        print(f"FOUND SINGLE $: {filename}:{line_num} | {line.strip()}")
                        count += 1
    print(f"Total single dollar signs found: {count}")

if __name__ == "__main__":
    find_any_single_dollar()
