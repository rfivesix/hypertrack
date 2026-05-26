import re

def fix_file(filepath):
    with open(filepath, "r", encoding="utf-8") as f:
        content = f.read()
    
    # We will replace all <sub> tags and surrounding formatting
    # Regex 1: *Letter*<sub>*Subscript*</sub> or *Letter*<sub>Subscript</sub>
    # e.g., *M*<sub>*t*</sub> or *V*<sub>ref</sub>
    # We want to replace these with *Letter_Subscript*
    # We can match: \*([A-Za-z]+)\*<sub>\*?([A-Za-z0-9,|+-]+)\*?<\/sub>
    # And replace with: *\1_\2*
    pattern = r'\*([A-Za-z]+)\*<sub>\*?([A-Za-z0-9,|+-]+)\*?</sub>'
    content = re.sub(pattern, r'*\1_\2*', content)
    
    # Regex 2: Letter<sub>Subscript</sub> without first *
    # e.g., R<sub>t</sub> or M<sub>qual</sub>
    # We want to replace these with *Letter_Subscript* or Letter_Subscript
    # Let's match: ([A-Za-z])<sub>\*?([A-Za-z0-9,|+-]+)\*?<\/sub>
    # And replace with: \1_\2
    pattern2 = r'([A-Za-z0-9])<sub>\*?([A-Za-z0-9,|+-]+)\*?</sub>'
    content = re.sub(pattern2, r'\1_\2', content)
    
    with open(filepath, "w", encoding="utf-8") as f:
        f.write(content)
    print(f"Successfully processed {filepath}")

if __name__ == "__main__":
    fix_file("/Users/richardgeorgschotte/Projekte/train-libre/documentation/features/bayesian_tdee_estimator.md")
    fix_file("/Users/richardgeorgschotte/Projekte/train-libre/documentation/features/sleep_scoring_engine.md")
