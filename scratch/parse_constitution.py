
import re
import json

def parse_constitution(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Pattern for Articles: ### 1. Sovereignty of the people
    article_pattern = re.compile(r'### (\d+[A-Z]?)\. (.*?)\n(.*?)(?=\n### |\Z)', re.DOTALL)
    
    # Pattern for Objectives: ### I. Implementation of objectives
    objective_pattern = re.compile(r'### ([IVXLC]+)\. (.*?)\n(.*?)(?=\n### |\Z)', re.DOTALL)

    articles = []
    for match in article_pattern.finditer(content):
        articles.append({
            "number": match.group(1),
            "title": match.group(2).strip(),
            "official_text": match.group(3).strip(),
            "type": "article"
        })

    objectives = []
    for match in objective_pattern.finditer(content):
        objectives.append({
            "id": match.group(1),
            "title": match.group(2).strip(),
            "official_text": match.group(3).strip(),
            "type": "objective"
        })

    return {
        "title": "Constitution of the Republic of Uganda",
        "objectives": objectives,
        "articles": articles
    }

if __name__ == "__main__":
    file_path = r'C:\Users\ashel\.gemini\antigravity\brain\aeb9c016-a091-4703-bf2e-6d2ff8b5820e\.system_generated\steps\51\content.md'
    data = parse_constitution(file_path)
    with open('constitution.json', 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=4)
    print(f"Extracted {len(data['articles'])} articles and {len(data['objectives'])} objectives.")
