import os

def check_unmatched_dollars_global():
    features_dir = "/Users/richardgeorgschotte/Projekte/train-libre/documentation/features"
    for filename in os.listdir(features_dir):
        if filename.endswith(".md"):
            filepath = os.path.join(features_dir, filename)
            with open(filepath, "r", encoding="utf-8") as f:
                content = f.read()
                
            # Parse content char by char
            in_inline = False
            in_block = False
            i = 0
            n = len(content)
            errors = []
            
            while i < n:
                if content[i] == '$':
                    # Check for escaped dollar \$
                    if i > 0 and content[i-1] == '\\':
                        i += 1
                        continue
                    
                    # Check for double dollar $$
                    if i + 1 < n and content[i+1] == '$':
                        if in_inline:
                            errors.append(f"Found $$ at index {i} while inside inline math!")
                        in_block = not in_block
                        i += 2
                        continue
                    else:
                        if in_block:
                            errors.append(f"Found $ at index {i} while inside block math!")
                        in_inline = not in_inline
                        i += 1
                        continue
                i += 1
            
            print(f"{filename}: global state - in_inline={in_inline}, in_block={in_block}, errors={len(errors)}")
            for err in errors:
                print(f"  Error: {err}")

if __name__ == "__main__":
    check_unmatched_dollars_global()
