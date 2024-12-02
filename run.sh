# Set colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Ensure script stops on any error
set -e

# Check for required commands and install virtualenv if needed
command -v python3 >/dev/null 2>&1 || { echo >&2 "Python3 is required but not installed.  Aborting."; exit 1; }
command -v virtualenv >/dev/null 2>&1 || { python3 -m pip install --user virtualenv; }
command -v mysql >/dev/null 2>&1 || { echo >&2 "MySQL is required but not installed.  Aborting."; exit 1; }

# Project Structure Creation Function
createStructure() {
    echo -e "${YELLOW}🏗️ Creating Project Directory Structure${NC}"

    # Create subdirectories
    mkdir -p {src,templates,static,uploads} || { echo "Error creating directories"; exit 1; }

    # Create necessary files
    touch .env app.py .gitignore

    # Create app structure files
    touch src/PDFcontroller.py
    touch src/PDFmodel.py
    touch src/db.py
    touch templates/{index.html,summary.html}
}

gitignore() {
    echo -e "${YELLOW}♠︎ Generating .gitignore file${NC}"
    cat > .gitignore << EOL
.vscode
__pycache__
*.pyc
.venv
.env
logs/
EOL
}

# Environment File Creation
creatEnv() {
    echo -e "${YELLOW}🔐 Generating .env file${NC}"
    cat > .env << EOL
# Database Configuration
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=
DB_NAME=breakitDown

# Flask Configuration
FLASK_APP=app.py
FLASK_ENV=development
SECRET_KEY=$(openssl rand -hex 32)

# Upload Configuration
UPLOAD_FOLDER=./uploads
MAX_CONTENT_LENGTH=16777216  # 16MB

# Logging
LOG_LEVEL=INFO
LOG_FILE=./logs/app.log
EOL
}

# Main Application File Creation
createApp() {
    echo -e "${YELLOW}🚀 Creating main application file${NC}"
    cat > app.py << EOL
from flask import Flask
from dotenv import load_dotenv
import os

# Load environment variables
load_dotenv()

def create_app():
    app = Flask(__name__, template_folder='templates')
    
    # Configuration from .env
    app.config['SECRET_KEY'] = os.getenv('SECRET_KEY')
    app.config['UPLOAD_FOLDER'] = os.getenv('UPLOAD_FOLDER')
    
    # Import and register blueprints
    from src.PDFcontroller import PDFroutes
    app.register_blueprint(PDFroutes)

    return app

if __name__ == '__main__':
    app = create_app()
    app.run(debug=True)
EOL
}

connectDB() {
    echo -e "${YELLOW}💾 Creating database configuration${NC}"
    cat > src/db.py << EOL
import mysql.connector
from mysql.connector import Error
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

class DatabaseConnection:
    @classmethod
    def get_connection(cls):
        try:
            connection = mysql.connector.connect(
                host=os.getenv('DB_HOST', 'localhost'),
                user=os.getenv('DB_USER'),
                password=os.getenv('DB_PASSWORD'),
                database=os.getenv('DB_NAME')
            )
            return connection
        except Error as e:
            print(f"Error connecting to MySQL database: {e}")
            return None

    @classmethod
    def test_connection(cls):
        try:
            connection = cls.get_connection()
            if connection:
                cursor = connection.cursor()
                cursor.execute("SELECT 1")
                cursor.fetchone()
                print("✅ Database connection successful!")
                cursor.close()
                connection.close()
                return True
        except Error as e:
            print(f"❌ Database connection failed: {e}")
            return False

    @classmethod
    def create_tables(cls):
        try:
            connection = cls.get_connection()
            if connection:
                cursor = connection.cursor()
                cursor.execute("SHOW TABLES LIKE 'pdfs'")
                result = cursor.fetchone()
                if not result: 
                
                    # Create PDF Summaries Table
                    create_table_query = """
                    CREATE TABLE IF NOT EXISTS pdfs (
                        id INT AUTO_INCREMENT PRIMARY KEY,
                        filename VARCHAR(255) NOT NULL,
                        summary TEXT,
                        extracted_text LONGTEXT,
                        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                    ) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
                    """
                    
                    cursor.execute(create_table_query)
                    connection.commit()
                    print("✅ Tables created successfully!")
                
                cursor.close()
                connection.close()
                return True
        except Error as e:
            print(f"❌ Error creating tables: {e}")
            return False
EOL
}

createModels() {
    echo -e "${YELLOW}🚀 Creating models file${NC}"
    cat > src/PDFmodel.py << EOL
import PyPDF4
import re
from collections import Counter
from src.db import DatabaseConnection
import os

class PDFModel:
    @staticmethod
    def extract_text_from_pdf(file_path):
        try:
            with open(file_path, 'rb') as file: 
                reader = PyPDF4.PdfReader(file)
                text = ""
                for page in reader.pages:
                    text += page.extract_text()
                return text
        except FileNotFoundError:
            print(f"Error: File not found at {file_path}")
            return None
        except Exception as e:  
            print(f"Error extracting text from PDF: {e}")
            return None


    @staticmethod
    def generate_summary(text, num_sentences=3):  
        if text is None or not text.strip():  
            return "No text extracted from PDF."
        
        # 1. Sentence Tokenization (Improved Regex)
        sentences = re.split(r'(?<!\w\.\w.)(?<![A-Z][a-z]\.)(?<=\.|\?)\s', text)

        # 2. Word Tokenization and Cleaning (Improved Regex and Stop Words)
        words = re.findall(r'\b\w+\b', text.lower())
        stop_words = set(...) 

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
EOL
}

createControllers() {
    echo -e "${YELLOW}🚀 Creating controllers file${NC}"
    cat > src/PDFcontroller.py << EOL
from flask import Blueprint, render_template, request, redirect, url_for
from werkzeug.utils import secure_filename
import os
from src.PDFmodel import PDFModel

PDFroutes = Blueprint('PDFroutes', __name__)

@PDFroutes.route('/', methods=['GET'])
def index():
    return render_template('index.html')

@PDFroutes.route('/upload', methods=['POST'])
def upload_pdf():
    if 'file' not in request.files:
        return redirect(url_for('PDFroutes.index'))
    
    file = request.files['file']
    if file.filename == '':
        return redirect(url_for('PDFroutes.index'))
    
    if file and file.filename.lower().endswith('.pdf'):
        filename = secure_filename(file.filename)
        filepath = os.path.join('uploads', filename)
        file.save(filepath)
        
        # Extract text and generate summary
        text = PDFModel.extract_text_from_pdf(filepath)
        if text:
            summary = PDFModel.generate_summary(text)
            
            # Save summary to database
            PDFModel.save_summary_to_db(filename, summary, text)
            
            return render_template('summary.html', summary=summary, filename=filename)
    
    return redirect(url_for('PDFroutes.index'))
EOL
}

createIndex() {
    echo -e "${YELLOW}🚀 Creating index template${NC}"
    cat > templates/index.html << EOL
<!DOCTYPE html>
<html>
<head>
    <title>PDF Summary Generator</title>
</head>
<body>
    <h1>Upload PDF File</h1>
    <form action="/upload" method="post" enctype="multipart/form-data">
        <input type="file" name="file" accept=".pdf">
        <input type="submit" value="Upload and Summarize">
    </form>
</body>
</html>
EOL
}

createSummary() {
    echo -e "${YELLOW}🚀 Creating summary template${NC}"
    cat > templates/summary.html << EOL
<!DOCTYPE html>
<html>
<head>
    <title>PDF Summary</title>
</head>
<body>
    <h1>Summary for {{ filename }}</h1>
    <p>{{ summary }}</p>
    <a href="/">Upload Another PDF</a>
</body>
</html>
EOL
}

setProject() {
    createStructure
    creatEnv 
    createApp
    connectDB
    createModels
    createControllers
    createIndex
    createSummary
    gitignore

    echo -e "${GREEN}✨ Project structure created successfully!${NC}"
}

main() {
    echo -e "${YELLOW}🔧 PDF Summary Application Initialization${NC}"
    
    command -v python3 >/dev/null 2>&1 || { echo >&2 "Python3 is required but not installed.  Aborting."; exit 1; }
    command -v mysql >/dev/null 2>&1 || { echo >&2 "MySQL is required but not installed.  Aborting."; exit 1; }

    setProject

    python3 -m venv .venv
    source .venv/bin/activate
    pip install --upgrade pip setuptools wheel
    pip install mysql.connector flask pypdf4
   
    source .env
    chmod 600 .env
    chmod 700 uploads

    echo -e "${GREEN}🎉 Project is ready! Run 'source .venv/bin/activate' to start.${NC}"
}

main

createDBtables() {
    echo -e "${YELLOW}💾 Creating breakitDown table${NC}"

    source .env
    
    mysql -u root -p "$DB_PASSWORD" <<EOF
CREATE DATABASE IF NOT EXISTS breakitDown;

USE breakitDown;

CREATE TABLE IF NOT EXISTS pdfs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    filename VARCHAR(255) NOT NULL,
    summary TEXT,
    extracted_text LONGTEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
EOF

    if [ $? -eq 0 ]; then  
        echo "✅ MySQL tables setup successfully!"
    else
        echo "❌ Error setting up MySQL tables. Please check your .env file and MySQL connection."
        exit 1 
    fi
}

createDBtables
.venv/bin/python3 -m pip install --upgrade pip
.venv/bin/python3 -m pip install --use-pep517 python-dotenv