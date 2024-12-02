import PyPDF4
import re
from collections import Counter
from src.db import DatabaseConnection
import os

class PDFModel:
    @staticmethod
    def extract_text_from_pdf(file_path):
        try:
            with open(file_path, 'rb') as file:  # Ensure file is opened in binary mode
                reader = PyPDF4.PdfReader(file)
                text = ""
                for page in reader.pages:
                    text += page.extract_text()
                return text
        except FileNotFoundError:
            print(f"Error: File not found at {file_path}")
            return None
        except Exception as e:  # Catch other potential PDF reading errors
            print(f"Error extracting text from PDF: {e}")
            return None


    @staticmethod
    def generate_summary(text, num_sentences=3):  # Parameter for summary length
        if text is None or not text.strip():  # Handle cases with no extracted text
            return "No text extracted from PDF."
        
        # 1. Sentence Tokenization (Improved Regex)
        sentences = re.split(r'(?<!\w\.\w.)(?<![A-Z][a-z]\.)(?<=\.|\?)\s', text)

        # 2. Word Tokenization and Cleaning (Improved Regex and Stop Words)
        words = re.findall(r'\b\w+\b', text.lower())
        stop_words = set(...) # Your existing stop words

        filtered_words = [word for word in words if word not in stop_words]

        # 3. Word Frequency
        word_freq = Counter(filtered_words)

        # 4. Sentence Scoring (Handling Edge Cases)
        sentence_scores = {}
        for sentence in sentences:
            for word in re.findall(r'\b\w+\b', sentence.lower()):
                if word in word_freq:
                    sentence_scores[sentence] = sentence_scores.get(sentence, 0) + word_freq[word]

        # 5. Summary Generation (Handle Empty Scores)
        if sentence_scores:
            summary_sentences = sorted(sentence_scores, key=sentence_scores.get, reverse=True)[:num_sentences]
        else:  # Fallback if no sentences are scored.
            summary_sentences = sentences[:min(num_sentences, len(sentences))]

        summary = ' '.join(summary_sentences)
        return summary


    @staticmethod
    def save_summary_to_db(filename, summary):
        connection = DatabaseConnection.get_connection()
        if connection:
            try:
                cursor = connection.cursor()
                query = "INSERT INTO pdfs (filename, summary, extracted_text) VALUES (%s, %s)"
                cursor.execute(query, (filename, summary, extracted_text))
                connection.commit()
                return True
            except Error as e:
                print(f"Database save error: {e}")
                return False
            finally:
                cursor.close()
                connection.close()
        return False
