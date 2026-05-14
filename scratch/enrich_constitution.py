
import json

def get_simple_summary(article_number, title, text):
    # Mapping of critical articles to Simple English summaries
    summaries = {
        "1": "All power belongs to the people of Uganda.",
        "2": "The Constitution is the highest law. No other law can go against it.",
        "3": "It is illegal to take over the government by force. All citizens must defend the constitution.",
        "4": "The government must teach everyone about the Constitution.",
        "5": "Uganda is one united country and a Republic.",
        "6": "English is the official language, and Swahili is the second official language.",
        "7": "Uganda does not have a state religion.",
        "8": "The national flag, coat of arms, and anthem are official symbols of Uganda.",
        "9": "If you were a citizen when this Constitution started, you remain a citizen.",
        "10": "You are a citizen by birth if one of your parents or grandparents was from a local Ugandan community in 1926.",
        "11": "Abandoned children found in Uganda are presumed to be citizens.",
        "17": "Every citizen has duties like paying taxes, defending the country, and respecting others' rights.",
        "20": "Human rights are natural; they are not given by the government. Everyone must respect them.",
        "21": "Everyone is equal before the law. No discrimination based on tribe, sex, religion, or money.",
        "22": "No one should be killed intentionally, except by a court sentence for a serious crime.",
        "23": "You cannot be arrested without a good reason. If arrested, you must be taken to court within 48 hours.",
        "24": "No one should be tortured or treated cruelly.",
        "25": "Slavery and forced labor are prohibited.",
        "26": "Everyone has a right to own property. The government can only take it for public use and must pay fairly and quickly.",
        "27": "You have a right to privacy in your home and your messages.",
        "28": "Everyone is entitled to a fair and speedy trial. You are innocent until proven guilty.",
        "29": "You have freedom of speech, freedom of religion, and the right to join any group or party.",
        "30": "Everyone has a right to education.",
        "31": "Men and women have equal rights in marriage. Same-sex marriage is prohibited.",
        "33": "Women must be treated equally to men and given opportunities to succeed.",
        "34": "Children have a right to be cared for, to get an education, and to be protected from hard work.",
        "40": "Every worker has a right to fair pay, safe conditions, and to join a union.",
        "41": "Citizens have a right to get information from the government, unless it hurts national security.",
        "59": "Every citizen aged 18 and above has the right to vote.",
        "102": "To be President, you must be a citizen by birth, between 35 and 75 years old (Note: age limits were amended).",
    }
    return summaries.get(article_number, f"This article explains the laws regarding {title.lower()}.")

def get_keywords(article_number, title, text):
    # Basic keyword extraction logic
    common_keywords = ["Uganda", "Constitution", "Law", "Rights"]
    title_words = [w.strip(",.()").lower() for w in title.split() if len(w) > 3]
    return list(set(common_keywords + title_words))

def enrich():
    with open('constitution.json', 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    enriched_articles = []
    for art in data['articles']:
        art['simple_summary'] = get_simple_summary(art['number'], art['title'], art['official_text'])
        art['keywords'] = get_keywords(art['number'], art['title'], art['official_text'])
        art['chapter'] = "Unknown" # Ideally we'd map these
        enriched_articles.append(art)
        
    data['articles'] = enriched_articles
    
    with open('assets/data/constitution_enriched.json', 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=4)
    print(f"Enriched {len(enriched_articles)} articles.")

if __name__ == "__main__":
    enrich()
